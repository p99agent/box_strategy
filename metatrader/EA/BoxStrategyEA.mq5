//+------------------------------------------------------------------+
//|                                              BoxStrategyEA.mq5  |
//|                                   Box Strategy EA - Phase 2 MVP |
//|                               Based on EA_SPECIFICATION.md v1.6 |
//+------------------------------------------------------------------+
#property copyright "Box Strategy EA"
#property link      "https://github.com/p99agent/box_strategy"
#property version   "1.41"
#property description "Box Strategy Scalping EA - Phase 2 MVP v1.4.1"
#property description "EUR/USD | 10:00-12:00 ET | 9 pips box | 3 pips target"
#property description "v1.4.1: Fix bias timing + Dynamic box stacking"

//+------------------------------------------------------------------+
//| Includes                                                          |
//+------------------------------------------------------------------+
#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>
#include <Trade\OrderInfo.mqh>

//+------------------------------------------------------------------+
//| MVP CONSTRAINTS (v1.6 - LOCKED)                                   |
//| These values match the instructor's exact configuration           |
//+------------------------------------------------------------------+
#define MVP_SYMBOL          "EURUSD"
#define BOX_HEIGHT_PIPS     9           // Fixed for MVP
#define BOX_DURATION_BARS   60          // 60 one-minute bars
#define MAX_BOXES           4
#define MAX_STOP_PIPS       (BOX_HEIGHT_PIPS * MAX_BOXES)  // = 36
#define TAKE_PROFIT_PIPS    3
#define SESSION_START_ET    10          // 10:00 Eastern Time
#define SESSION_END_ET      12          // 12:00 Eastern Time
#define MAX_CLICKS          16          // 4 boxes × 4 clicks
#define CLICKS_PER_BOX      4
#define RISK_PER_CLICK      0.0025      // 0.25%

// Global variable keys for persistence
#define GV_CLICKS_USED      "BoxEA_ClicksUsed"
#define GV_SESSION_DATE     "BoxEA_SessionDate"
#define GV_START_EQUITY     "BoxEA_StartEquity"
#define GV_EJECTION         "BoxEA_Ejection"
#define GV_CAMPAIGN_DIR     "BoxEA_CampaignDirection"
#define GV_CAMPAIGN_ENTRY   "BoxEA_CampaignEntry"

// Visual object names
#define BOX_OBJ_PREFIX      "BoxEA_Box_"
#define ENTRY_LINE_PREFIX   "BoxEA_Entry_"

//+------------------------------------------------------------------+
//| Enums (v1.3 + v1.4)                                               |
//+------------------------------------------------------------------+
enum ENUM_CLICK_MODE {
    CLICK_MODE_SESSION,   // SESSION: Fixed budget (16/day max)
    CLICK_MODE_RECYCLE    // RECYCLE: Reset when flat + profit
};

enum ENUM_BIAS {
    BIAS_BULLISH,         // Bullish: HH + HL structure
    BIAS_BEARISH,         // Bearish: LH + LL structure
    BIAS_RANGING          // Ranging: Mixed or ADR exhausted
};

//+------------------------------------------------------------------+
//| Input Parameters                                                  |
//+------------------------------------------------------------------+
input group "=== Timezone Settings ==="
input int      InpBrokerGMTOffset = 2;    // Broker GMT Offset (FTMO: 2 winter, 3 summer)
input int      InpTargetGMTOffset = -5;   // Target GMT Offset (Eastern: -5 winter, -4 summer)

input group "=== Risk Settings ==="
input double   InpRiskPercent = 0.25;     // Risk per click (%)
input int      InpMagicNumber = 20231223; // EA Magic Number

input group "=== Display Settings ==="
input bool     InpShowPanel = true;       // Show info panel on chart
input bool     InpShowBoxes = true;       // Show box visualization on chart
input color    InpBoxColor = clrDodgerBlue; // Box border color
input color    InpBuyColor = clrLime;     // Buy arrow color
input color    InpSellColor = clrRed;     // Sell arrow color

input group "=== Safety Settings ==="
input bool     InpStrictMVP = true;       // Block trading on non-EURUSD (MVP mode)

input group "=== Click Mode (v1.3) ==="
input ENUM_CLICK_MODE InpClickMode = CLICK_MODE_RECYCLE;  // Click budget mode

input group "=== Bias Detection (v1.4) ==="
input bool     InpUseBias = true;         // Enable bias filtering
input int      InpADRPeriod = 20;         // ADR calculation period (days)
input double   InpADRThreshold = 0.80;    // ADR exhaustion threshold (80%)

input group "=== Box Stacking (v1.4) ==="
input bool     InpDynamicBoxes = true;    // Enable dynamic box stacking

//+------------------------------------------------------------------+
//| Global Variables                                                  |
//+------------------------------------------------------------------+
CTrade         trade;
CPositionInfo  posInfo;

// Session tracking (PERSISTENT - loaded from GlobalVariables)
int            g_sessionClicksUsed = 0;
int            g_currentBox = 1;
double         g_sessionStartEquity = 0;
datetime       g_lastSessionDate = 0;
bool           g_tradingEnabled = true;
bool           g_ejectionTriggered = false;

// Campaign tracking (for proper drawdown calculation)
int            g_campaignDirection = 0;  // 1 = long, -1 = short, 0 = none
double         g_campaignEntryPrice = 0; // Weighted average entry
double         g_campaignLots = 0;       // Total lots in campaign

// Box edge tracking
double         g_lastBoxTop = 0;
double         g_lastBoxBottom = 0;
datetime       g_lastBoxTime = 0;
int            g_boxStackCount = 1;      // v1.4: How many times box has stacked
bool           g_boxInitialized = false; // v1.4: Flag to track if box edges are initialized

// THROTTLE: Prevent rapid-fire entries
datetime       g_lastTradeBar = 0;
datetime       g_lastLogTime = 0;

// Statistics
int            g_totalTrades = 0;
int            g_winningTrades = 0;
int            g_losingTrades = 0;
double         g_totalPipsGained = 0;
double         g_totalPipsLost = 0;
double         g_sessionPnL = 0;
int            g_openPositionsCount = 0;

// v1.4: Bias state (cached, updated once per D1 bar)
ENUM_BIAS      g_currentBias = BIAS_RANGING;
datetime       g_lastBiasUpdate = 0;
double         g_adrPips = 0;
double         g_adrUsedPips = 0;
double         g_adrRemainingPips = 0;
double         g_adrRatio = 0;
bool           g_adrExhausted = false;

// v1.4: Hourly range (cached, updated once per H1 bar)
double         g_hourlyHigh = 0;
double         g_hourlyLow = 0;
datetime       g_lastHourlyUpdate = 0;

//+------------------------------------------------------------------+
//| Helper Functions - SPEC-001: Pip Size                            |
//+------------------------------------------------------------------+
double GetPipSize()
{
    int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
    double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
    
    if (digits == 3 || digits == 5)
        return point * 10;
    else
        return point;
}

//+------------------------------------------------------------------+
//| SPEC-002: Session Time Filter                                     |
//+------------------------------------------------------------------+
int NormalizeHour(int hour)
{
    while (hour < 0) hour += 24;
    return hour % 24;
}

int GetBrokerSessionStart()
{
    int offset = InpBrokerGMTOffset - InpTargetGMTOffset;
    return NormalizeHour(SESSION_START_ET + offset);
}

int GetBrokerSessionEnd()
{
    int offset = InpBrokerGMTOffset - InpTargetGMTOffset;
    return NormalizeHour(SESSION_END_ET + offset);
}

bool IsInSession()
{
    MqlDateTime time;
    TimeToStruct(TimeCurrent(), time);
    int current_hour = time.hour;
    
    int start = GetBrokerSessionStart();
    int end = GetBrokerSessionEnd();
    
    if (start < end)
        return (current_hour >= start && current_hour < end);
    else
        return (current_hour >= start || current_hour < end);
}

bool IsNewSession()
{
    MqlDateTime time;
    TimeToStruct(TimeCurrent(), time);
    datetime today = StringToTime(StringFormat("%04d.%02d.%02d", time.year, time.mon, time.day));
    
    if (today != g_lastSessionDate)
    {
        g_lastSessionDate = today;
        return true;
    }
    return false;
}

//+------------------------------------------------------------------+
//| Persistence Functions                                             |
//+------------------------------------------------------------------+
void SaveStateToGlobalVariables()
{
    GlobalVariableSet(GV_CLICKS_USED, (double)g_sessionClicksUsed);
    GlobalVariableSet(GV_SESSION_DATE, (double)g_lastSessionDate);
    GlobalVariableSet(GV_START_EQUITY, g_sessionStartEquity);
    GlobalVariableSet(GV_EJECTION, g_ejectionTriggered ? 1.0 : 0.0);
    GlobalVariableSet(GV_CAMPAIGN_DIR, (double)g_campaignDirection);
    GlobalVariableSet(GV_CAMPAIGN_ENTRY, g_campaignEntryPrice);
}

void LoadStateFromGlobalVariables()
{
    if (GlobalVariableCheck(GV_CLICKS_USED))
        g_sessionClicksUsed = (int)GlobalVariableGet(GV_CLICKS_USED);
    
    if (GlobalVariableCheck(GV_SESSION_DATE))
        g_lastSessionDate = (datetime)GlobalVariableGet(GV_SESSION_DATE);
    
    if (GlobalVariableCheck(GV_START_EQUITY))
        g_sessionStartEquity = GlobalVariableGet(GV_START_EQUITY);
    
    if (GlobalVariableCheck(GV_EJECTION))
        g_ejectionTriggered = (GlobalVariableGet(GV_EJECTION) > 0.5);
    
    if (GlobalVariableCheck(GV_CAMPAIGN_DIR))
        g_campaignDirection = (int)GlobalVariableGet(GV_CAMPAIGN_DIR);
    
    if (GlobalVariableCheck(GV_CAMPAIGN_ENTRY))
        g_campaignEntryPrice = GlobalVariableGet(GV_CAMPAIGN_ENTRY);
    
    Print("State loaded: Clicks=", g_sessionClicksUsed, " Ejection=", g_ejectionTriggered);
}

void ResetSessionCounters()
{
    g_sessionClicksUsed = 0;
    g_currentBox = 1;
    g_sessionStartEquity = AccountInfoDouble(ACCOUNT_EQUITY);
    g_tradingEnabled = true;
    g_ejectionTriggered = false;
    g_campaignDirection = 0;
    g_campaignEntryPrice = 0;
    g_campaignLots = 0;
    g_lastTradeBar = 0;
    g_sessionPnL = 0;
    g_openPositionsCount = 0;
    
    // v1.4: Reset box stacking state
    g_boxStackCount = 1;
    g_boxInitialized = false;
    g_lastBoxTop = 0;
    g_lastBoxBottom = 0;
    
    // v1.4: Reset bias cache to force recalculation
    g_lastBiasUpdate = 0;
    g_lastHourlyUpdate = 0;
    
    SaveStateToGlobalVariables();
    
    Print("=== NEW SESSION STARTED ===");
    Print("Session Start Equity: ", g_sessionStartEquity);
    Print("Broker Session Hours: ", GetBrokerSessionStart(), ":00 - ", GetBrokerSessionEnd(), ":00");
    Print("Click Mode: ", (InpClickMode == CLICK_MODE_RECYCLE ? "RECYCLE" : "SESSION"));
    Print("Bias Detection: ", (InpUseBias ? "ON" : "OFF"));
    Print("Dynamic Boxes: ", (InpDynamicBoxes ? "ON" : "OFF"));
}

//+------------------------------------------------------------------+
//| v1.3: Click Recycle Logic                                         |
//+------------------------------------------------------------------+
void CheckClickRecycle()
{
    if (InpClickMode != CLICK_MODE_RECYCLE)
        return;
    
    double current_equity = AccountInfoDouble(ACCOUNT_EQUITY);
    g_sessionPnL = current_equity - g_sessionStartEquity;
    
    if (g_sessionPnL >= 0)
    {
        int old_clicks = g_sessionClicksUsed;
        g_sessionClicksUsed = 0;
        g_currentBox = 1;
        
        // v1.4: Also reset box for new campaign
        g_boxInitialized = false;
        g_boxStackCount = 1;
        
        SaveStateToGlobalVariables();
        
        Print("=== CLICK RECYCLE TRIGGERED ===");
        Print("Session P/L: +", DoubleToString(g_sessionPnL, 2));
        Print("Clicks reset: ", old_clicks, " -> 0");
        Print("Ready for new campaign!");
    }
    else
    {
        Print("Session P/L is negative (", DoubleToString(g_sessionPnL, 2), "), clicks NOT reset");
    }
}

//+------------------------------------------------------------------+
//| SPEC-003: Position Sizing Calculator                              |
//+------------------------------------------------------------------+
double CalculateLotSize()
{
    double pip_size = GetPipSize();
    double tick_value = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
    double tick_size = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
    double pip_value = (tick_value / tick_size) * pip_size;
    
    double equity = AccountInfoDouble(ACCOUNT_EQUITY);
    double risk_amount = equity * (InpRiskPercent / 100.0);
    double risk_per_lot = MAX_STOP_PIPS * pip_value;
    double lot_size = risk_amount / risk_per_lot;
    
    double volume_step = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
    double volume_min = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
    double volume_max = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
    
    lot_size = MathFloor(lot_size / volume_step) * volume_step;
    lot_size = MathMax(volume_min, MathMin(lot_size, volume_max));
    
    return lot_size;
}

//+------------------------------------------------------------------+
//| v1.4: Bias Detection (SPEC-009)                                   |
//+------------------------------------------------------------------+
void ClearBiasState()
{
    // Clear stale state on early return (Reviewer feedback #1)
    g_adrPips = 0;
    g_adrUsedPips = 0;
    g_adrRemainingPips = 0;
    g_adrRatio = 0;
    g_adrExhausted = false;
}

void UpdateDailyBias()
{
    if (!InpUseBias) return;
    
    // v1.4.1 FIX: Guard against invalid ADR period (divide-by-zero)
    if (InpADRPeriod < 1)
    {
        g_currentBias = BIAS_RANGING;
        return;
    }
    
    // Only update once per D1 bar
    datetime current_d1 = iTime(_Symbol, PERIOD_D1, 0);
    if (current_d1 == g_lastBiasUpdate) return;
    
    // GUARD: Ensure sufficient history
    int bars = Bars(_Symbol, PERIOD_D1);
    if (bars < InpADRPeriod + 2)
    {
        Print("WARNING: Insufficient D1 bars (", bars, ") for bias detection");
        ClearBiasState();
        g_currentBias = BIAS_RANGING;
        return;
    }
    
    // Daily structure: compare today vs yesterday
    double today_high = iHigh(_Symbol, PERIOD_D1, 0);
    double today_low = iLow(_Symbol, PERIOD_D1, 0);
    double yesterday_high = iHigh(_Symbol, PERIOD_D1, 1);
    double yesterday_low = iLow(_Symbol, PERIOD_D1, 1);
    
    ENUM_BIAS structure;
    if (today_high > yesterday_high && today_low > yesterday_low)
        structure = BIAS_BULLISH;
    else if (today_high < yesterday_high && today_low < yesterday_low)
        structure = BIAS_BEARISH;
    else
        structure = BIAS_RANGING;
    
    // Calculate ADR
    double pip_size = GetPipSize();
    double total_range = 0;
    for (int i = 1; i <= InpADRPeriod; i++)
    {
        total_range += iHigh(_Symbol, PERIOD_D1, i) - iLow(_Symbol, PERIOD_D1, i);
    }
    g_adrPips = (total_range / InpADRPeriod) / pip_size;
    
    // GUARD: Avoid divide-by-zero
    if (g_adrPips <= 0)
    {
        ClearBiasState();
        g_currentBias = BIAS_RANGING;
        return;
    }
    
    // Today's usage
    g_adrUsedPips = (today_high - today_low) / pip_size;
    g_adrRatio = g_adrUsedPips / g_adrPips;
    g_adrRemainingPips = g_adrPips - g_adrUsedPips;
    
    // Check exhaustion (>threshold% or <9 pips remaining)
    g_adrExhausted = (g_adrRatio > InpADRThreshold) || (g_adrRemainingPips < BOX_HEIGHT_PIPS);
    
    // Final bias: structure unless exhausted
    g_currentBias = g_adrExhausted ? BIAS_RANGING : structure;
    
    // v1.4.1 FIX: Set timestamp AFTER successful calculation
    // This ensures retry if early guards return
    g_lastBiasUpdate = current_d1;
    
    Print("Daily Bias: ", EnumToString(g_currentBias), 
          " | ADR: ", DoubleToString(g_adrPips, 1), " pips",
          " | Used: ", DoubleToString(g_adrRatio * 100, 1), "%",
          " | Remaining: ", DoubleToString(g_adrRemainingPips, 1), " pips");
}

//+------------------------------------------------------------------+
//| v1.4: Hourly Range                                                |
//+------------------------------------------------------------------+
void UpdateHourlyRange()
{
    datetime current_h1 = iTime(_Symbol, PERIOD_H1, 0);
    if (current_h1 == g_lastHourlyUpdate) return;
    g_lastHourlyUpdate = current_h1;
    
    // Use completed bars (shift 1-4)
    g_hourlyHigh = iHigh(_Symbol, PERIOD_H1, 1);
    g_hourlyLow = iLow(_Symbol, PERIOD_H1, 1);
    
    for (int i = 2; i <= 4; i++)
    {
        double h = iHigh(_Symbol, PERIOD_H1, i);
        double l = iLow(_Symbol, PERIOD_H1, i);
        if (h > g_hourlyHigh) g_hourlyHigh = h;
        if (l < g_hourlyLow) g_hourlyLow = l;
    }
}

//+------------------------------------------------------------------+
//| SPEC-004: Box Counter - Price-based drawdown                      |
//+------------------------------------------------------------------+
void UpdateCampaignTracking()
{
    double total_lots = 0;
    double weighted_sum = 0;
    int direction = 0;
    int positions_count = 0;
    
    for (int i = PositionsTotal() - 1; i >= 0; i--)
    {
        if (posInfo.SelectByIndex(i))
        {
            if (posInfo.Symbol() == _Symbol && posInfo.Magic() == InpMagicNumber)
            {
                double lots = posInfo.Volume();
                double entry = posInfo.PriceOpen();
                
                total_lots += lots;
                weighted_sum += entry * lots;
                positions_count++;
                
                if (posInfo.PositionType() == POSITION_TYPE_BUY)
                    direction = 1;
                else
                    direction = -1;
            }
        }
    }
    
    bool just_went_flat = (g_openPositionsCount > 0 && positions_count == 0);
    g_openPositionsCount = positions_count;
    
    if (total_lots > 0)
    {
        g_campaignLots = total_lots;
        g_campaignEntryPrice = weighted_sum / total_lots;
        g_campaignDirection = direction;
    }
    else
    {
        g_campaignLots = 0;
        g_campaignEntryPrice = 0;
        g_campaignDirection = 0;
        
        if (just_went_flat)
        {
            CheckClickRecycle();
            // v1.4: Reset box initialization when going flat
            g_boxInitialized = false;
        }
    }
}

double GetCurrentDrawdownPips()
{
    // v1.4.1 FIX: Removed UpdateCampaignTracking() call to avoid side effects in getter
    // Caller (OnTick) is responsible for calling UpdateCampaignTracking() first
    if (g_campaignDirection == 0 || g_campaignLots == 0)
        return 0;
    
    double pip_size = GetPipSize();
    double current_price;
    
    if (g_campaignDirection == 1)
    {
        current_price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
        double price_diff = g_campaignEntryPrice - current_price;
        if (price_diff < 0) return 0;
        return price_diff / pip_size;
    }
    else
    {
        current_price = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
        double price_diff = current_price - g_campaignEntryPrice;
        if (price_diff < 0) return 0;
        return price_diff / pip_size;
    }
}

int CalculateCurrentBox()
{
    double drawdown_pips = GetCurrentDrawdownPips();
    int current_box = (int)MathFloor(drawdown_pips / BOX_HEIGHT_PIPS) + 1;
    return MathMin(current_box, MAX_BOXES + 1);
}

void UpdateBoxLevel()
{
    int new_box = CalculateCurrentBox();
    
    if (new_box != g_currentBox)
    {
        g_currentBox = new_box;
        Print("Box Level Changed: Now in Box ", g_currentBox);
        
        if (g_currentBox == MAX_BOXES)
        {
            Alert("WARNING: Entering Box 4 - Last defense zone!");
        }
        else if (g_currentBox > MAX_BOXES)
        {
            TriggerEjection();
        }
    }
}

//+------------------------------------------------------------------+
//| SPEC-005: Click Counter                                           |
//+------------------------------------------------------------------+
bool HasClicksRemaining()
{
    return (g_sessionClicksUsed < MAX_CLICKS);
}

bool HasClicksInCurrentBox()
{
    int clicks_allowed_so_far = g_currentBox * CLICKS_PER_BOX;
    return (g_sessionClicksUsed < clicks_allowed_so_far);
}

int GetClicksUsedInCurrentBox()
{
    int clicks_before_this_box = (g_currentBox - 1) * CLICKS_PER_BOX;
    return MathMax(0, g_sessionClicksUsed - clicks_before_this_box);
}

void UseClick()
{
    g_sessionClicksUsed++;
    SaveStateToGlobalVariables();
    Print("Click used. Total: ", g_sessionClicksUsed, "/", MAX_CLICKS, 
          " | Box ", g_currentBox, ": ", GetClicksUsedInCurrentBox(), "/", CLICKS_PER_BOX);
}

//+------------------------------------------------------------------+
//| v1.4: Dynamic Box Stacking (SPEC-006 Enhanced)                    |
//+------------------------------------------------------------------+
void InitializeBoxEdges()
{
    // Called at session start or when going flat
    double pip_size = GetPipSize();
    double box_height = BOX_HEIGHT_PIPS * pip_size;
    
    // Get recent range
    double recent_high = iHigh(_Symbol, PERIOD_M1, iHighest(_Symbol, PERIOD_M1, MODE_HIGH, BOX_DURATION_BARS, 0));
    double recent_low = iLow(_Symbol, PERIOD_M1, iLowest(_Symbol, PERIOD_M1, MODE_LOW, BOX_DURATION_BARS, 0));
    double current_price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    
    // Reviewer feedback #2: Ensure current price starts inside the box
    // Find the box level that contains current price
    int box_level = (int)MathFloor((recent_high - current_price) / box_height);
    box_level = MathMax(0, box_level);  // Ensure non-negative
    
    g_lastBoxTop = recent_high - (box_level * box_height);
    g_lastBoxBottom = g_lastBoxTop - box_height;
    
    // Ensure current price is inside the box
    if (current_price > g_lastBoxTop)
    {
        g_lastBoxTop = current_price + (box_height / 2);
        g_lastBoxBottom = g_lastBoxTop - box_height;
    }
    else if (current_price < g_lastBoxBottom)
    {
        g_lastBoxBottom = current_price - (box_height / 2);
        g_lastBoxTop = g_lastBoxBottom + box_height;
    }
    
    g_boxStackCount = 1;
    g_boxInitialized = true;
    g_lastBoxTime = TimeCurrent();
    
    Print("Box initialized: ", DoubleToString(g_lastBoxBottom, 5), " - ", DoubleToString(g_lastBoxTop, 5));
}

void UpdateDynamicBoxStack()
{
    if (!InpDynamicBoxes) return;
    if (!g_boxInitialized) return;
    
    double pip_size = GetPipSize();
    double box_height = BOX_HEIGHT_PIPS * pip_size;
    double tolerance = 2 * pip_size;  // Whipsaw protection
    double current_price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    
    double break_up_level = g_lastBoxTop + tolerance;
    double break_down_level = g_lastBoxBottom - tolerance;
    
    // Check for break above box top (with tolerance)
    if (current_price > break_up_level)
    {
        // v1.4.1 FIX: Use MathFloor+1 instead of MathCeil+1 to avoid skipping boxes
        int boxes_to_add = (int)MathFloor((current_price - g_lastBoxTop) / box_height) + 1;
        boxes_to_add = MathMax(1, boxes_to_add);
        
        double old_top = g_lastBoxTop;
        g_lastBoxBottom = g_lastBoxTop + ((boxes_to_add - 1) * box_height);
        g_lastBoxTop = g_lastBoxBottom + box_height;
        g_boxStackCount += boxes_to_add;
        
        Print("Box stacked UP x", boxes_to_add, ": ", DoubleToString(old_top, 5), " -> ", 
              DoubleToString(g_lastBoxBottom, 5), " - ", DoubleToString(g_lastBoxTop, 5));
    }
    // Check for break below box bottom (with tolerance)
    else if (current_price < break_down_level)
    {
        // v1.4.1 FIX: Use MathFloor+1 instead of MathCeil+1 to avoid skipping boxes
        int boxes_to_add = (int)MathFloor((g_lastBoxBottom - current_price) / box_height) + 1;
        boxes_to_add = MathMax(1, boxes_to_add);
        
        double old_bottom = g_lastBoxBottom;
        g_lastBoxTop = g_lastBoxBottom - ((boxes_to_add - 1) * box_height);
        g_lastBoxBottom = g_lastBoxTop - box_height;
        g_boxStackCount += boxes_to_add;
        
        Print("Box stacked DOWN x", boxes_to_add, ": ", DoubleToString(old_bottom, 5), " -> ", 
              DoubleToString(g_lastBoxBottom, 5), " - ", DoubleToString(g_lastBoxTop, 5));
    }
}

bool IsPriceAtBoxTop()
{
    double pip_size = GetPipSize();
    double tolerance = 2 * pip_size;
    double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    
    return (bid >= g_lastBoxTop - tolerance && bid <= g_lastBoxTop + tolerance);
}

bool IsPriceAtBoxBottom()
{
    double pip_size = GetPipSize();
    double tolerance = 2 * pip_size;
    double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    
    return (bid >= g_lastBoxBottom - tolerance && bid <= g_lastBoxBottom + tolerance);
}

//+------------------------------------------------------------------+
//| v1.4: Entry Signal with Bias Filtering (SPEC-006 + SPEC-009)      |
//+------------------------------------------------------------------+
int GetEntrySignal()
{
    // v1.4: Campaign-aware entry (Reviewer feedback #2)
    // When in a campaign: only allow adds in same direction
    if (g_campaignDirection != 0)
    {
        if (g_campaignDirection == 1 && IsPriceAtBoxBottom())
            return 1;  // Add to long campaign
        
        if (g_campaignDirection == -1 && IsPriceAtBoxTop())
            return -1;  // Add to short campaign
        
        return 0;  // No opposite direction trades in active campaign
    }
    
    // FLAT: Use bias to decide new campaign direction
    if (IsPriceAtBoxBottom())
    {
        if (!InpUseBias)
            return 1;  // No bias filtering - always allow
        
        // Bullish or Ranging: can start long campaign
        if (g_currentBias == BIAS_BULLISH || g_currentBias == BIAS_RANGING)
            return 1;
        
        // Bearish: don't buy against trend
        return 0;
    }
    
    if (IsPriceAtBoxTop())
    {
        if (!InpUseBias)
            return -1;  // No bias filtering - always allow
        
        // Bearish or Ranging: can start short campaign
        if (g_currentBias == BIAS_BEARISH || g_currentBias == BIAS_RANGING)
            return -1;
        
        // Bullish: don't sell against trend
        return 0;
    }
    
    return 0;
}

//+------------------------------------------------------------------+
//| Throttle and Trade Gates                                          |
//+------------------------------------------------------------------+
bool IsNewBar()
{
    datetime current_bar = iTime(_Symbol, PERIOD_M1, 0);
    return (current_bar != g_lastTradeBar);
}

void MarkBarAsTraded()
{
    g_lastTradeBar = iTime(_Symbol, PERIOD_M1, 0);
}

void LogBlockedTrade(string reason)
{
    if (TimeCurrent() - g_lastLogTime >= 30)
    {
        Print(reason);
        g_lastLogTime = TimeCurrent();
    }
}

bool CanOpenNewTrade()
{
    if (InpStrictMVP && _Symbol != MVP_SYMBOL)
    {
        static bool warned = false;
        if (!warned)
        {
            Print("BLOCKED: EA is in strict MVP mode (EUR/USD only). Current symbol: ", _Symbol);
            warned = true;
        }
        return false;
    }
    
    if (!g_tradingEnabled) return false;
    if (!IsInSession()) return false;
    if (g_ejectionTriggered) return false;
    if (!IsNewBar()) return false;
    
    if (!HasClicksRemaining())
    {
        LogBlockedTrade("Max clicks reached: " + IntegerToString(g_sessionClicksUsed));
        return false;
    }
    
    if (!HasClicksInCurrentBox())
    {
        LogBlockedTrade("Max clicks in Box " + IntegerToString(g_currentBox) + " reached: " + IntegerToString(GetClicksUsedInCurrentBox()));
        return false;
    }
    
    if (g_currentBox > MAX_BOXES) return false;
    
    return true;
}

bool OpenBuyTrade()
{
    if (!CanOpenNewTrade()) return false;
    
    double lot_size = CalculateLotSize();
    double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    double pip_size = GetPipSize();
    
    double tp = ask + (TAKE_PROFIT_PIPS * pip_size);
    double sl = ask - (MAX_STOP_PIPS * pip_size);
    
    trade.SetExpertMagicNumber(InpMagicNumber);
    
    if (trade.Buy(lot_size, _Symbol, ask, sl, tp, "BoxEA Buy"))
    {
        UseClick();
        MarkBarAsTraded();
        g_totalTrades++;
        Print("BUY opened: ", lot_size, " lots @ ", ask, " SL: ", sl, " TP: ", tp);
        UpdateCampaignTracking();
        DrawEntryLine(ask, true);
        return true;
    }
    else
    {
        Print("BUY failed: ", trade.ResultRetcode(), " - ", trade.ResultRetcodeDescription());
        return false;
    }
}

bool OpenSellTrade()
{
    if (!CanOpenNewTrade()) return false;
    
    double lot_size = CalculateLotSize();
    double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    double pip_size = GetPipSize();
    
    double tp = bid - (TAKE_PROFIT_PIPS * pip_size);
    double sl = bid + (MAX_STOP_PIPS * pip_size);
    
    trade.SetExpertMagicNumber(InpMagicNumber);
    
    if (trade.Sell(lot_size, _Symbol, bid, sl, tp, "BoxEA Sell"))
    {
        UseClick();
        MarkBarAsTraded();
        g_totalTrades++;
        Print("SELL opened: ", lot_size, " lots @ ", bid, " SL: ", sl, " TP: ", tp);
        UpdateCampaignTracking();
        DrawEntryLine(bid, false);
        return true;
    }
    else
    {
        Print("SELL failed: ", trade.ResultRetcode(), " - ", trade.ResultRetcodeDescription());
        return false;
    }
}

//+------------------------------------------------------------------+
//| SPEC-007 & SPEC-008: Exit Logic                                   |
//+------------------------------------------------------------------+
void TriggerEjection()
{
    if (g_ejectionTriggered) return;
    
    g_ejectionTriggered = true;
    g_tradingEnabled = false;
    SaveStateToGlobalVariables();
    
    Alert("!!! EJECTION TRIGGERED - Closing all positions !!!");
    Print("Ejection at Box ", g_currentBox, " - Drawdown exceeded ", MAX_STOP_PIPS, " pips");
    
    CloseAllPositions();
}

void CloseAllPositions()
{
    for (int i = PositionsTotal() - 1; i >= 0; i--)
    {
        if (posInfo.SelectByIndex(i))
        {
            if (posInfo.Symbol() == _Symbol && posInfo.Magic() == InpMagicNumber)
            {
                trade.PositionClose(posInfo.Ticket());
                Print("Closed position: ", posInfo.Ticket());
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Visual Box Indicator                                              |
//+------------------------------------------------------------------+
void DrawBoxOnChart()
{
    if (!InpShowBoxes) return;
    
    string box_name = BOX_OBJ_PREFIX + "Current";
    ObjectDelete(0, box_name);
    
    datetime start_time = iTime(_Symbol, PERIOD_M1, BOX_DURATION_BARS);
    datetime end_time = TimeCurrent() + 300;
    
    if (ObjectCreate(0, box_name, OBJ_RECTANGLE, 0, start_time, g_lastBoxTop, end_time, g_lastBoxBottom))
    {
        ObjectSetInteger(0, box_name, OBJPROP_COLOR, InpBoxColor);
        ObjectSetInteger(0, box_name, OBJPROP_STYLE, STYLE_SOLID);
        ObjectSetInteger(0, box_name, OBJPROP_WIDTH, 2);
        ObjectSetInteger(0, box_name, OBJPROP_FILL, false);
        ObjectSetInteger(0, box_name, OBJPROP_BACK, true);
        ObjectSetInteger(0, box_name, OBJPROP_SELECTABLE, false);
    }
    
    string top_name = BOX_OBJ_PREFIX + "Top";
    ObjectDelete(0, top_name);
    if (ObjectCreate(0, top_name, OBJ_HLINE, 0, 0, g_lastBoxTop))
    {
        ObjectSetInteger(0, top_name, OBJPROP_COLOR, InpSellColor);
        ObjectSetInteger(0, top_name, OBJPROP_STYLE, STYLE_DOT);
        ObjectSetInteger(0, top_name, OBJPROP_WIDTH, 1);
        ObjectSetString(0, top_name, OBJPROP_TEXT, "Box Top (Sell Zone)");
    }
    
    string bottom_name = BOX_OBJ_PREFIX + "Bottom";
    ObjectDelete(0, bottom_name);
    if (ObjectCreate(0, bottom_name, OBJ_HLINE, 0, 0, g_lastBoxBottom))
    {
        ObjectSetInteger(0, bottom_name, OBJPROP_COLOR, InpBuyColor);
        ObjectSetInteger(0, bottom_name, OBJPROP_STYLE, STYLE_DOT);
        ObjectSetInteger(0, bottom_name, OBJPROP_WIDTH, 1);
        ObjectSetString(0, bottom_name, OBJPROP_TEXT, "Box Bottom (Buy Zone)");
    }
}

void DrawEntryLine(double price, bool isBuy)
{
    static int entry_count = 0;
    entry_count++;
    
    string line_name = ENTRY_LINE_PREFIX + IntegerToString(entry_count);
    
    if (ObjectCreate(0, line_name, OBJ_HLINE, 0, 0, price))
    {
        ObjectSetInteger(0, line_name, OBJPROP_COLOR, isBuy ? InpBuyColor : InpSellColor);
        ObjectSetInteger(0, line_name, OBJPROP_STYLE, STYLE_DASH);
        ObjectSetInteger(0, line_name, OBJPROP_WIDTH, 1);
        ObjectSetString(0, line_name, OBJPROP_TEXT, isBuy ? "BUY Entry" : "SELL Entry");
    }
}

void CleanupChartObjects()
{
    int total = ObjectsTotal(0);
    for (int i = total - 1; i >= 0; i--)
    {
        string name = ObjectName(0, i);
        if (StringFind(name, "BoxEA_") >= 0)
        {
            ObjectDelete(0, name);
        }
    }
}

//+------------------------------------------------------------------+
//| Display Panel (v1.4 Enhanced)                                     |
//+------------------------------------------------------------------+
void UpdateInfoPanel()
{
    if (!InpShowPanel) return;
    
    string session_status = IsInSession() ? "ACTIVE" : "CLOSED";
    string trading_status = g_tradingEnabled ? "ENABLED" : "DISABLED";
    string campaign_str = (g_campaignDirection == 1) ? "LONG" : 
                          (g_campaignDirection == -1) ? "SHORT" : "NONE";
    string click_mode_str = (InpClickMode == CLICK_MODE_RECYCLE) ? "RECYCLE" : "SESSION";
    string bias_str = (g_currentBias == BIAS_BULLISH) ? "BULLISH ^" :
                      (g_currentBias == BIAS_BEARISH) ? "BEARISH v" : "RANGING -";
    
    double current_pnl = AccountInfoDouble(ACCOUNT_EQUITY) - g_sessionStartEquity;
    
    string panel = "";
    panel += "=== BOX STRATEGY EA v1.4 ===\n";
    panel += "Symbol: " + _Symbol + " | Mode: " + click_mode_str + "\n";
    panel += "----------------------------------------\n";
    
    // v1.4: Bias info
    if (InpUseBias)
    {
        panel += "Bias: " + bias_str;
        if (g_adrPips > 0)
            panel += " (ADR: " + DoubleToString(g_adrRatio * 100, 0) + "% | " + 
                     DoubleToString(g_adrRemainingPips, 1) + " left)\n";
        else
            panel += "\n";
    }
    
    panel += "Session: " + session_status + " (" + IntegerToString(GetBrokerSessionStart()) + ":00-" + IntegerToString(GetBrokerSessionEnd()) + ":00)\n";
    panel += "----------------------------------------\n";
    panel += "Current Box: " + IntegerToString(g_currentBox) + " / " + IntegerToString(MAX_BOXES) + "\n";
    panel += "Clicks: " + IntegerToString(g_sessionClicksUsed) + "/" + IntegerToString(MAX_CLICKS) + 
             " (Box " + IntegerToString(g_currentBox) + ": " + IntegerToString(GetClicksUsedInCurrentBox()) + "/" + IntegerToString(CLICKS_PER_BOX) + ")\n";
    panel += "----------------------------------------\n";
    panel += "Campaign: " + campaign_str + " (" + IntegerToString(g_openPositionsCount) + " pos)\n";
    panel += "Drawdown: " + DoubleToString(GetCurrentDrawdownPips(), 1) + " pips\n";
    panel += "----------------------------------------\n";
    panel += "Session P/L: " + (current_pnl >= 0 ? "+" : "") + DoubleToString(current_pnl, 2) + "\n";
    panel += "Trades: " + IntegerToString(g_totalTrades) + " | W: " + IntegerToString(g_winningTrades) + " L: " + IntegerToString(g_losingTrades) + "\n";
    panel += "----------------------------------------\n";
    
    // v1.4: Box stacking info
    string box_mode = InpDynamicBoxes ? "[Dynamic x" + IntegerToString(g_boxStackCount) + "]" : "[Static]";
    panel += "Box " + box_mode + ": " + DoubleToString(g_lastBoxBottom, 5) + " - " + DoubleToString(g_lastBoxTop, 5) + "\n";
    panel += "Lot: " + DoubleToString(CalculateLotSize(), 2) + "\n";
    
    Comment(panel);
}

//+------------------------------------------------------------------+
//| Detect proper filling mode for broker                             |
//+------------------------------------------------------------------+
ENUM_ORDER_TYPE_FILLING GetFillingMode()
{
    uint filling = (uint)SymbolInfoInteger(_Symbol, SYMBOL_FILLING_MODE);
    
    if ((filling & SYMBOL_FILLING_IOC) == SYMBOL_FILLING_IOC)
        return ORDER_FILLING_IOC;
    
    if ((filling & SYMBOL_FILLING_FOK) == SYMBOL_FILLING_FOK)
        return ORDER_FILLING_FOK;
    
    return ORDER_FILLING_RETURN;
}

//+------------------------------------------------------------------+
//| Expert initialization function                                    |
//+------------------------------------------------------------------+
int OnInit()
{
    Print("==============================================");
    Print("Box Strategy EA v1.4.1 - Phase 2 MVP");
    Print("==============================================");
    
    if (_Symbol != MVP_SYMBOL)
    {
        if (InpStrictMVP)
        {
            Print("ERROR: This EA is locked to ", MVP_SYMBOL, " in strict MVP mode");
            Print("Current symbol: ", _Symbol);
            return(INIT_FAILED);
        }
        else
        {
            Print("WARNING: This EA is optimized for ", MVP_SYMBOL);
        }
    }
    
    if (Period() != PERIOD_M1)
    {
        Print("WARNING: This EA is optimized for M1 timeframe");
    }
    
    trade.SetExpertMagicNumber(InpMagicNumber);
    trade.SetDeviationInPoints(10);
    trade.SetTypeFilling(GetFillingMode());
    
    // v1.4.1 FIX: Validate InpADRPeriod to prevent divide-by-zero
    if (InpUseBias && InpADRPeriod < 1)
    {
        Print("WARNING: InpADRPeriod must be >= 1, bias detection disabled");
        // Can't modify input, so we'll handle in UpdateDailyBias
    }
    
    LoadStateFromGlobalVariables();
    
    if (IsNewSession())
    {
        ResetSessionCounters();
    }
    else
    {
        Print("Resuming session. Clicks used: ", g_sessionClicksUsed);
        
        // v1.3 FIX: Startup recycle check
        if (InpClickMode == CLICK_MODE_RECYCLE && g_sessionClicksUsed > 0)
        {
            UpdateCampaignTracking();
            if (g_openPositionsCount == 0 && g_sessionClicksUsed > 0)
            {
                double current_pnl = AccountInfoDouble(ACCOUNT_EQUITY) - g_sessionStartEquity;
                if (current_pnl >= 0)
                {
                    Print("Startup recycle: Flat + profitable, resetting clicks");
                    g_sessionClicksUsed = 0;
                    g_currentBox = 1;
                    g_boxInitialized = false;
                    SaveStateToGlobalVariables();
                }
            }
        }
    }
    
    // v1.4: Initialize bias
    if (InpUseBias)
    {
        UpdateDailyBias();
    }
    
    // v1.4: Initialize hourly range
    UpdateHourlyRange();
    
    Print("Broker Session: ", GetBrokerSessionStart(), ":00 - ", GetBrokerSessionEnd(), ":00");
    Print("Lot Size: ", CalculateLotSize());
    Print("Pip Size: ", GetPipSize());
    Print("Filling Mode: ", EnumToString(GetFillingMode()));
    Print("Click Mode: ", (InpClickMode == CLICK_MODE_RECYCLE ? "RECYCLE" : "SESSION"));
    Print("Bias Detection: ", (InpUseBias ? "ON" : "OFF"));
    Print("Dynamic Boxes: ", (InpDynamicBoxes ? "ON" : "OFF"));
    Print("==============================================");
    
    return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                  |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    SaveStateToGlobalVariables();
    CleanupChartObjects();
    Comment("");
    Print("Box Strategy EA stopped. State saved. Reason: ", reason);
}

//+------------------------------------------------------------------+
//| Expert tick function                                              |
//+------------------------------------------------------------------+
void OnTick()
{
    // 1. Session check
    if (IsNewSession())
    {
        ResetSessionCounters();
    }
    
    // 2. v1.4: Update bias (once per D1 bar)
    if (InpUseBias)
    {
        UpdateDailyBias();
    }
    
    // 3. v1.4: Update hourly range (once per H1 bar)
    UpdateHourlyRange();
    
    // 4. Update campaign tracking
    UpdateCampaignTracking();
    
    // 5. v1.4: Initialize box if needed (Reviewer feedback #3)
    if (!g_boxInitialized)
    {
        InitializeBoxEdges();
    }
    
    // 6. v1.4: Dynamic box stacking (if enabled)
    if (InpDynamicBoxes)
    {
        UpdateDynamicBoxStack();
    }
    
    // 7. Update box level and ejection check
    UpdateBoxLevel();
    if (g_currentBox > MAX_BOXES && !g_ejectionTriggered)
    {
        TriggerEjection();
    }
    
    // 8. Update visual (on new bars only to reduce overhead)
    static datetime last_visual_update = 0;
    datetime current_bar = iTime(_Symbol, PERIOD_M1, 0);
    if (current_bar != last_visual_update)
    {
        DrawBoxOnChart();
        last_visual_update = current_bar;
    }
    
    // 9. Update display
    UpdateInfoPanel();
    
    // 10. Entry signals
    if (!IsInSession() || !g_tradingEnabled || g_ejectionTriggered)
        return;
    
    int signal = GetEntrySignal();
    
    if (signal == 1)
    {
        OpenBuyTrade();
    }
    else if (signal == -1)
    {
        OpenSellTrade();
    }
}

//+------------------------------------------------------------------+
//| Trade transaction handler                                         |
//+------------------------------------------------------------------+
void OnTradeTransaction(const MqlTradeTransaction& trans,
                        const MqlTradeRequest& request,
                        const MqlTradeResult& result)
{
    if (trans.type == TRADE_TRANSACTION_HISTORY_ADD)
    {
        ulong deal_ticket = trans.deal;
        
        if (deal_ticket > 0)
        {
            if (HistoryDealSelect(deal_ticket))
            {
                long magic = HistoryDealGetInteger(deal_ticket, DEAL_MAGIC);
                ENUM_DEAL_ENTRY entry = (ENUM_DEAL_ENTRY)HistoryDealGetInteger(deal_ticket, DEAL_ENTRY);
                
                if (magic == InpMagicNumber && entry == DEAL_ENTRY_OUT)
                {
                    double profit = HistoryDealGetDouble(deal_ticket, DEAL_PROFIT);
                    double commission = HistoryDealGetDouble(deal_ticket, DEAL_COMMISSION);
                    double swap = HistoryDealGetDouble(deal_ticket, DEAL_SWAP);
                    double net_profit = profit + commission + swap;
                    
                    if (net_profit > 0)
                    {
                        g_winningTrades++;
                        Print("Trade closed: WIN +", DoubleToString(net_profit, 2));
                    }
                    else
                    {
                        g_losingTrades++;
                        Print("Trade closed: LOSS ", DoubleToString(net_profit, 2));
                    }
                    
                    UpdateCampaignTracking();
                }
            }
        }
    }
}
//+------------------------------------------------------------------+
