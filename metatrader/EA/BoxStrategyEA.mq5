//+------------------------------------------------------------------+
//|                                              BoxStrategyEA.mq5  |
//|                                   Box Strategy EA - Phase 1 MVP |
//|                               Based on EA_SPECIFICATION.md v1.6 |
//+------------------------------------------------------------------+
#property copyright "Box Strategy EA"
#property link      "https://github.com/p99agent/box_strategy"
#property version   "1.30"
#property description "Box Strategy Scalping EA - Phase 1 MVP v1.3"
#property description "EUR/USD | 10:00-12:00 ET | 9 pips box | 3 pips target"
#property description "v1.3: Added RECYCLE mode (reset clicks when flat + profit)"

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
//| Click Mode Enum (v1.3)                                            |
//+------------------------------------------------------------------+
enum ENUM_CLICK_MODE {
    CLICK_MODE_SESSION,   // SESSION: Fixed budget (16/day max)
    CLICK_MODE_RECYCLE    // RECYCLE: Reset when flat + profit
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

// THROTTLE: Prevent rapid-fire entries (v1.2 FIX)
datetime       g_lastTradeBar = 0;       // Last bar we traded on
datetime       g_lastLogTime = 0;        // Last time we logged a block message

// Statistics
int            g_totalTrades = 0;
int            g_winningTrades = 0;
int            g_losingTrades = 0;
double         g_totalPipsGained = 0;
double         g_totalPipsLost = 0;
double         g_sessionPnL = 0;          // Session P/L for recycle logic (v1.3)
int            g_openPositionsCount = 0;  // Track number of open positions

//+------------------------------------------------------------------+
//| Helper Functions - SPEC-001: Pip Size                            |
//+------------------------------------------------------------------+
double GetPipSize()
{
    int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
    double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
    
    // 3-digit (JPY) or 5-digit (EUR/USD) = multiply by 10
    // 2-digit or 4-digit = use as-is
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
    else  // Crosses midnight
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
//| Persistence Functions (persist across restarts)                   |
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
    
    SaveStateToGlobalVariables();
    
    Print("=== NEW SESSION STARTED ===");
    Print("Session Start Equity: ", g_sessionStartEquity);
    Print("Broker Session Hours: ", GetBrokerSessionStart(), ":00 - ", GetBrokerSessionEnd(), ":00");
    Print("Click Mode: ", (InpClickMode == CLICK_MODE_RECYCLE ? "RECYCLE" : "SESSION"));
}

//+------------------------------------------------------------------+
//| v1.3: Click Recycle Logic                                         |
//+------------------------------------------------------------------+
void CheckClickRecycle()
{
    // Only recycle if RECYCLE mode is enabled
    if (InpClickMode != CLICK_MODE_RECYCLE)
        return;
    
    // Calculate current session P/L
    double current_equity = AccountInfoDouble(ACCOUNT_EQUITY);
    g_sessionPnL = current_equity - g_sessionStartEquity;
    
    // If session is profitable (or break-even), reset clicks
    if (g_sessionPnL >= 0)
    {
        int old_clicks = g_sessionClicksUsed;
        g_sessionClicksUsed = 0;
        g_currentBox = 1;  // Also reset box level since no drawdown
        
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
    
    // Calculate pip value using MT5 tick info
    double tick_value = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
    double tick_size = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
    double pip_value = (tick_value / tick_size) * pip_size;  // per 1.0 lot
    
    // Full position sizing formula
    double equity = AccountInfoDouble(ACCOUNT_EQUITY);
    double risk_amount = equity * (InpRiskPercent / 100.0);  // Convert to decimal
    double risk_per_lot = MAX_STOP_PIPS * pip_value;
    double lot_size = risk_amount / risk_per_lot;
    
    // Use SYMBOL_VOLUME_STEP for proper rounding
    double volume_step = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
    double volume_min = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
    double volume_max = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
    
    lot_size = MathFloor(lot_size / volume_step) * volume_step;  // Round down to valid step
    lot_size = MathMax(volume_min, MathMin(lot_size, volume_max));  // Clamp to limits
    
    return lot_size;
}

//+------------------------------------------------------------------+
//| SPEC-004: Box Counter - Price-based drawdown                      |
//+------------------------------------------------------------------+
void UpdateCampaignTracking()
{
    // Recalculate weighted average entry and total lots for our positions
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
                
                // Determine direction from position type
                if (posInfo.PositionType() == POSITION_TYPE_BUY)
                    direction = 1;
                else
                    direction = -1;
            }
        }
    }
    
    // Check if we just went flat (had positions, now none)
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
        // No positions - reset campaign
        g_campaignLots = 0;
        g_campaignEntryPrice = 0;
        g_campaignDirection = 0;
        
        // v1.3: Check for click recycle when going flat
        if (just_went_flat)
        {
            CheckClickRecycle();
        }
    }
}

double GetCurrentDrawdownPips()
{
    // Calculate drawdown based on PRICE DISTANCE from campaign entry
    UpdateCampaignTracking();
    
    if (g_campaignDirection == 0 || g_campaignLots == 0)
        return 0;  // No open positions
    
    double pip_size = GetPipSize();
    double current_price;
    
    if (g_campaignDirection == 1)  // Long campaign
    {
        current_price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
        double price_diff = g_campaignEntryPrice - current_price;  // Negative if in profit
        if (price_diff < 0) return 0;  // In profit, no drawdown
        return price_diff / pip_size;
    }
    else  // Short campaign
    {
        current_price = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
        double price_diff = current_price - g_campaignEntryPrice;  // Negative if in profit
        if (price_diff < 0) return 0;  // In profit, no drawdown
        return price_diff / pip_size;
    }
}

int CalculateCurrentBox()
{
    double drawdown_pips = GetCurrentDrawdownPips();
    int current_box = (int)MathFloor(drawdown_pips / BOX_HEIGHT_PIPS) + 1;
    return MathMin(current_box, MAX_BOXES + 1);  // Cap at Box 5 for ejection
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
//| SPEC-005: Click Counter - Enforce 4 per box + persistence         |
//+------------------------------------------------------------------+
bool HasClicksRemaining()
{
    return (g_sessionClicksUsed < MAX_CLICKS);
}

bool HasClicksInCurrentBox()
{
    // Properly calculate clicks allowed in current box
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
    SaveStateToGlobalVariables();  // Persist immediately
    Print("Click used. Total: ", g_sessionClicksUsed, "/", MAX_CLICKS, 
          " | Box ", g_currentBox, ": ", GetClicksUsedInCurrentBox(), "/", CLICKS_PER_BOX);
}

//+------------------------------------------------------------------+
//| SPEC-006: Entry Logic - Box Edge Detection                        |
//+------------------------------------------------------------------+
void UpdateBoxEdges()
{
    // Calculate current box edges based on recent price action
    double pip_size = GetPipSize();
    double box_height_price = BOX_HEIGHT_PIPS * pip_size;
    
    // Get recent high/low for box placement
    double recent_high = iHigh(_Symbol, PERIOD_M1, iHighest(_Symbol, PERIOD_M1, MODE_HIGH, BOX_DURATION_BARS, 0));
    double recent_low = iLow(_Symbol, PERIOD_M1, iLowest(_Symbol, PERIOD_M1, MODE_LOW, BOX_DURATION_BARS, 0));
    
    double range = recent_high - recent_low;
    double mid = (recent_high + recent_low) / 2;
    
    // If range is less than box height, center the box on the range
    if (range < box_height_price)
    {
        g_lastBoxTop = mid + (box_height_price / 2);
        g_lastBoxBottom = mid - (box_height_price / 2);
    }
    else
    {
        // Multiple boxes in range - use the nearest edges
        double current_price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
        
        // Find which box level we're in
        int box_level = (int)MathFloor((recent_high - current_price) / box_height_price);
        g_lastBoxTop = recent_high - (box_level * box_height_price);
        g_lastBoxBottom = g_lastBoxTop - box_height_price;
    }
    
    g_lastBoxTime = TimeCurrent();
    
    // Update visual box
    if (InpShowBoxes)
        DrawBoxOnChart();
}

bool IsPriceAtBoxTop()
{
    double pip_size = GetPipSize();
    double tolerance = 2 * pip_size;  // 2 pip tolerance
    double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    
    return (bid >= g_lastBoxTop - tolerance && bid <= g_lastBoxTop + tolerance);
}

bool IsPriceAtBoxBottom()
{
    double pip_size = GetPipSize();
    double tolerance = 2 * pip_size;  // 2 pip tolerance
    double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    
    return (bid >= g_lastBoxBottom - tolerance && bid <= g_lastBoxBottom + tolerance);
}

int GetEntrySignal()
{
    // Check if price is at a box edge
    if (IsPriceAtBoxBottom())
    {
        // At box bottom - potential BUY (if no existing short campaign)
        if (g_campaignDirection != -1)  // Not in a short campaign
            return 1;  // Buy signal
    }
    
    if (IsPriceAtBoxTop())
    {
        // At box top - potential SELL (if no existing long campaign)
        if (g_campaignDirection != 1)  // Not in a long campaign
            return -1;  // Sell signal
    }
    
    // If in a campaign, allow adding at box edges in same direction
    if (g_campaignDirection == 1 && IsPriceAtBoxBottom())
        return 1;  // Add to long campaign
    
    if (g_campaignDirection == -1 && IsPriceAtBoxTop())
        return -1;  // Add to short campaign
    
    return 0;  // No signal
}

//+------------------------------------------------------------------+
//| THROTTLE: One trade per M1 bar (v1.2 FIX)                         |
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

//+------------------------------------------------------------------+
//| LOG RATE LIMIT: Avoid spam (v1.2 FIX)                             |
//+------------------------------------------------------------------+
void LogBlockedTrade(string reason)
{
    // Only log once per 30 seconds to avoid spam
    if (TimeCurrent() - g_lastLogTime >= 30)
    {
        Print(reason);
        g_lastLogTime = TimeCurrent();
    }
}

bool CanOpenNewTrade()
{
    // Check symbol constraint
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
    
    // Check all conditions
    if (!g_tradingEnabled)
    {
        return false;
    }
    
    if (!IsInSession())
    {
        return false;  // Silent - outside session
    }
    
    if (g_ejectionTriggered)
    {
        return false;
    }
    
    // v1.2 FIX: Throttle - only one trade per M1 bar
    if (!IsNewBar())
    {
        return false;  // Silent - already traded this bar
    }
    
    if (!HasClicksRemaining())
    {
        LogBlockedTrade("Max clicks reached: " + IntegerToString(g_sessionClicksUsed));
        return false;
    }
    
    // Enforce 4 clicks per box
    if (!HasClicksInCurrentBox())
    {
        LogBlockedTrade("Max clicks in Box " + IntegerToString(g_currentBox) + " reached: " + IntegerToString(GetClicksUsedInCurrentBox()));
        return false;
    }
    
    if (g_currentBox > MAX_BOXES)
    {
        return false;
    }
    
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
        MarkBarAsTraded();  // v1.2: Mark this bar as traded
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
        MarkBarAsTraded();  // v1.2: Mark this bar as traded
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
//| SPEC-007 & SPEC-008: Exit Logic (TP and SL)                       |
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
//| SPEC-013: Visual Box Indicator (v1.2 NEW)                         |
//+------------------------------------------------------------------+
void DrawBoxOnChart()
{
    if (!InpShowBoxes) return;
    
    string box_name = BOX_OBJ_PREFIX + "Current";
    
    // Delete old box
    ObjectDelete(0, box_name);
    
    // Draw box from BOX_DURATION_BARS ago to now
    datetime start_time = iTime(_Symbol, PERIOD_M1, BOX_DURATION_BARS);
    datetime end_time = TimeCurrent() + 300;  // Extend 5 minutes into future
    
    // Create rectangle
    if (ObjectCreate(0, box_name, OBJ_RECTANGLE, 0, start_time, g_lastBoxTop, end_time, g_lastBoxBottom))
    {
        ObjectSetInteger(0, box_name, OBJPROP_COLOR, InpBoxColor);
        ObjectSetInteger(0, box_name, OBJPROP_STYLE, STYLE_SOLID);
        ObjectSetInteger(0, box_name, OBJPROP_WIDTH, 2);
        ObjectSetInteger(0, box_name, OBJPROP_FILL, false);
        ObjectSetInteger(0, box_name, OBJPROP_BACK, true);
        ObjectSetInteger(0, box_name, OBJPROP_SELECTABLE, false);
    }
    
    // Draw box top line (sell zone)
    string top_name = BOX_OBJ_PREFIX + "Top";
    ObjectDelete(0, top_name);
    if (ObjectCreate(0, top_name, OBJ_HLINE, 0, 0, g_lastBoxTop))
    {
        ObjectSetInteger(0, top_name, OBJPROP_COLOR, InpSellColor);
        ObjectSetInteger(0, top_name, OBJPROP_STYLE, STYLE_DOT);
        ObjectSetInteger(0, top_name, OBJPROP_WIDTH, 1);
        ObjectSetString(0, top_name, OBJPROP_TEXT, "Box Top (Sell Zone)");
    }
    
    // Draw box bottom line (buy zone)
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
    // Delete all BoxEA objects
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
//| Display Panel                                                      |
//+------------------------------------------------------------------+
void UpdateInfoPanel()
{
    if (!InpShowPanel) return;
    
    string session_status = IsInSession() ? "ACTIVE" : "CLOSED";
    string trading_status = g_tradingEnabled ? "ENABLED" : "DISABLED";
    string campaign_str = (g_campaignDirection == 1) ? "LONG" : 
                          (g_campaignDirection == -1) ? "SHORT" : "NONE";
    string click_mode_str = (InpClickMode == CLICK_MODE_RECYCLE) ? "RECYCLE" : "SESSION";
    
    // Calculate current session P/L
    double current_pnl = AccountInfoDouble(ACCOUNT_EQUITY) - g_sessionStartEquity;
    
    // Build panel string (MQL5 Comment() has parameter limit)
    string panel = "";
    panel += "=== BOX STRATEGY EA v1.3 (MVP) ===\n";
    panel += "Symbol: " + _Symbol + " | TF: " + EnumToString(Period()) + "\n";
    panel += "Click Mode: " + click_mode_str + "\n";
    panel += "----------------------------------------\n";
    panel += "Session: " + session_status + " (" + IntegerToString(GetBrokerSessionStart()) + ":00-" + IntegerToString(GetBrokerSessionEnd()) + ":00)\n";
    panel += "Trading: " + trading_status + "\n";
    panel += "----------------------------------------\n";
    panel += "Current Box: " + IntegerToString(g_currentBox) + " / " + IntegerToString(MAX_BOXES) + "\n";
    panel += "Clicks Used: " + IntegerToString(g_sessionClicksUsed) + " / " + IntegerToString(MAX_CLICKS) + "\n";
    panel += "Clicks in Box " + IntegerToString(g_currentBox) + ": " + IntegerToString(GetClicksUsedInCurrentBox()) + " / " + IntegerToString(CLICKS_PER_BOX) + "\n";
    panel += "----------------------------------------\n";
    panel += "Campaign: " + campaign_str + " (" + IntegerToString(g_openPositionsCount) + " pos)\n";
    panel += "Avg Entry: " + DoubleToString(g_campaignEntryPrice, 5) + "\n";
    panel += "Drawdown: " + DoubleToString(GetCurrentDrawdownPips(), 1) + " pips\n";
    panel += "----------------------------------------\n";
    panel += "Session P/L: " + (current_pnl >= 0 ? "+" : "") + DoubleToString(current_pnl, 2) + "\n";
    panel += "Wins: " + IntegerToString(g_winningTrades) + " | Losses: " + IntegerToString(g_losingTrades) + "\n";
    panel += "----------------------------------------\n";
    panel += "Box Top: " + DoubleToString(g_lastBoxTop, 5) + " (SELL)\n";
    panel += "Box Bottom: " + DoubleToString(g_lastBoxBottom, 5) + " (BUY)\n";
    
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
    Print("Box Strategy EA v1.2 - Phase 1 MVP");
    Print("==============================================");
    
    // Validate symbol
    if (_Symbol != MVP_SYMBOL)
    {
        if (InpStrictMVP)
        {
            Print("ERROR: This EA is locked to ", MVP_SYMBOL, " in strict MVP mode");
            Print("Current symbol: ", _Symbol);
            Print("Either change to EURUSD or disable Strict MVP mode");
            return(INIT_FAILED);
        }
        else
        {
            Print("WARNING: This EA is optimized for ", MVP_SYMBOL);
            Print("Current symbol: ", _Symbol);
        }
    }
    
    // Validate timeframe
    if (Period() != PERIOD_M1)
    {
        Print("WARNING: This EA is optimized for M1 timeframe");
        Print("Current timeframe: ", EnumToString(Period()));
    }
    
    // Initialize trade object with proper filling mode
    trade.SetExpertMagicNumber(InpMagicNumber);
    trade.SetDeviationInPoints(10);
    trade.SetTypeFilling(GetFillingMode());
    
    // Load persisted state
    LoadStateFromGlobalVariables();
    
    // Check if new session
    if (IsNewSession())
    {
        ResetSessionCounters();
    }
    else
    {
        Print("Resuming session. Clicks used: ", g_sessionClicksUsed);
    }
    
    // Initialize box edges
    UpdateBoxEdges();
    
    // Display settings
    Print("Broker Session: ", GetBrokerSessionStart(), ":00 - ", GetBrokerSessionEnd(), ":00 (server time)");
    Print("Lot Size: ", CalculateLotSize());
    Print("Pip Size: ", GetPipSize());
    Print("Filling Mode: ", EnumToString(GetFillingMode()));
    Print("Max Stop: ", MAX_STOP_PIPS, " pips");
    Print("Take Profit: ", TAKE_PROFIT_PIPS, " pips");
    Print("Entry Throttle: 1 trade per M1 bar (v1.2)");
    Print("Box Visualization: ", (InpShowBoxes ? "ON" : "OFF"));
    Print("==============================================");
    
    return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                  |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    SaveStateToGlobalVariables();  // Save state on exit
    CleanupChartObjects();         // Remove visual objects
    Comment("");                   // Clear panel
    Print("Box Strategy EA stopped. State saved. Reason: ", reason);
}

//+------------------------------------------------------------------+
//| Expert tick function                                              |
//+------------------------------------------------------------------+
void OnTick()
{
    // Check for new session (daily reset)
    if (IsNewSession())
    {
        ResetSessionCounters();
    }
    
    // Update campaign tracking
    UpdateCampaignTracking();
    
    // Update box level based on drawdown
    UpdateBoxLevel();
    
    // Check for ejection
    if (g_currentBox > MAX_BOXES && !g_ejectionTriggered)
    {
        TriggerEjection();
    }
    
    // Update display
    UpdateInfoPanel();
    
    // Only process entries if in session and trading enabled
    if (!IsInSession() || !g_tradingEnabled || g_ejectionTriggered)
        return;
    
    // Update box edges periodically (every new bar)
    static datetime last_bar = 0;
    datetime current_bar = iTime(_Symbol, PERIOD_M1, 0);
    if (current_bar != last_bar)
    {
        UpdateBoxEdges();
        last_bar = current_bar;
    }
    
    // Check entry signals
    int signal = GetEntrySignal();
    
    if (signal == 1)  // Buy signal
    {
        OpenBuyTrade();
    }
    else if (signal == -1)  // Sell signal
    {
        OpenSellTrade();
    }
}

//+------------------------------------------------------------------+
//| Trade transaction handler - Track win/loss stats                  |
//+------------------------------------------------------------------+
void OnTradeTransaction(const MqlTradeTransaction& trans,
                        const MqlTradeRequest& request,
                        const MqlTradeResult& result)
{
    // Track closed trades for statistics
    if (trans.type == TRADE_TRANSACTION_HISTORY_ADD)
    {
        // A deal was added to history - check if it's a close
        ulong deal_ticket = trans.deal;
        
        if (deal_ticket > 0)
        {
            if (HistoryDealSelect(deal_ticket))
            {
                long magic = HistoryDealGetInteger(deal_ticket, DEAL_MAGIC);
                ENUM_DEAL_ENTRY entry = (ENUM_DEAL_ENTRY)HistoryDealGetInteger(deal_ticket, DEAL_ENTRY);
                
                if (magic == InpMagicNumber && entry == DEAL_ENTRY_OUT)
                {
                    // This is a closing deal for our EA
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
                    
                    // Update campaign after close
                    UpdateCampaignTracking();
                }
            }
        }
    }
}
//+------------------------------------------------------------------+
