//+------------------------------------------------------------------+
//|                                              BoxStrategyEA.mq5  |
//|                                   Box Strategy EA - Phase 1 MVP |
//|                               Based on EA_SPECIFICATION.md v1.6 |
//+------------------------------------------------------------------+
#property copyright "Box Strategy EA"
#property link      "https://github.com/p99agent/box_strategy"
#property version   "1.00"
#property description "Box Strategy Scalping EA - Phase 1 MVP"
#property description "EUR/USD | 10:00-12:00 ET | 9 pips box | 3 pips target"

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
input color    InpBuyColor = clrLime;     // Buy arrow color
input color    InpSellColor = clrRed;     // Sell arrow color

//+------------------------------------------------------------------+
//| Global Variables                                                  |
//+------------------------------------------------------------------+
CTrade         trade;
CPositionInfo  posInfo;

// Session tracking
int            g_sessionClicksUsed = 0;
int            g_currentBox = 1;
double         g_sessionStartEquity = 0;
datetime       g_lastSessionDate = 0;
bool           g_tradingEnabled = true;
bool           g_ejectionTriggered = false;

// Box calculation (for display/validation - SPEC-001)
double         g_calculatedBoxHeight = BOX_HEIGHT_PIPS;
int            g_calculatedBoxDuration = BOX_DURATION_BARS;

// Statistics
int            g_totalTrades = 0;
int            g_winningTrades = 0;
double         g_totalPipsGained = 0;
double         g_totalPipsLost = 0;

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

void ResetSessionCounters()
{
    g_sessionClicksUsed = 0;
    g_currentBox = 1;
    g_sessionStartEquity = AccountInfoDouble(ACCOUNT_EQUITY);
    g_tradingEnabled = true;
    g_ejectionTriggered = false;
    Print("=== NEW SESSION STARTED ===");
    Print("Session Start Equity: ", g_sessionStartEquity);
    Print("Broker Session Hours: ", GetBrokerSessionStart(), ":00 - ", GetBrokerSessionEnd(), ":00");
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
    
    // v1.6 FIX: Use SYMBOL_VOLUME_STEP for proper rounding
    double volume_step = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
    double volume_min = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
    double volume_max = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
    
    lot_size = MathFloor(lot_size / volume_step) * volume_step;  // Round down to valid step
    lot_size = MathMax(volume_min, MathMin(lot_size, volume_max));  // Clamp to limits
    
    return lot_size;
}

//+------------------------------------------------------------------+
//| SPEC-004: Box Counter and Tracker                                 |
//+------------------------------------------------------------------+
double GetCurrentDrawdownPips()
{
    double total_drawdown = 0;
    double pip_size = GetPipSize();
    
    for (int i = PositionsTotal() - 1; i >= 0; i--)
    {
        if (posInfo.SelectByIndex(i))
        {
            if (posInfo.Symbol() == _Symbol && posInfo.Magic() == InpMagicNumber)
            {
                double profit_pips = posInfo.Profit() / (posInfo.Volume() * 
                    SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE) / 
                    SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE) * pip_size);
                
                if (profit_pips < 0)
                    total_drawdown += MathAbs(profit_pips);
            }
        }
    }
    return total_drawdown;
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
//| SPEC-005: Click Counter                                           |
//+------------------------------------------------------------------+
bool HasClicksRemaining()
{
    return (g_sessionClicksUsed < MAX_CLICKS);
}

bool HasClicksInCurrentBox()
{
    // Each box gets 4 clicks
    int clicks_used_in_box = g_sessionClicksUsed % CLICKS_PER_BOX;
    return (clicks_used_in_box < CLICKS_PER_BOX);
}

void UseClick()
{
    g_sessionClicksUsed++;
    Print("Click used. Total clicks: ", g_sessionClicksUsed, "/", MAX_CLICKS);
}

//+------------------------------------------------------------------+
//| SPEC-006: Entry Logic                                             |
//+------------------------------------------------------------------+
bool CanOpenNewTrade()
{
    // Check all conditions
    if (!g_tradingEnabled)
    {
        Print("Trading disabled for this session");
        return false;
    }
    
    if (!IsInSession())
    {
        return false;  // Silent - outside session
    }
    
    if (g_ejectionTriggered)
    {
        Print("Ejection triggered - no new trades");
        return false;
    }
    
    if (!HasClicksRemaining())
    {
        Print("Max clicks reached: ", g_sessionClicksUsed);
        return false;
    }
    
    if (g_currentBox > MAX_BOXES)
    {
        Print("Beyond Box 4 - trading blocked");
        return false;
    }
    
    // Check if symbol matches MVP constraint
    if (_Symbol != MVP_SYMBOL)
    {
        Print("WARNING: EA designed for ", MVP_SYMBOL, " only. Current: ", _Symbol);
        // Still allow but warn
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
        g_totalTrades++;
        Print("BUY opened: ", lot_size, " lots @ ", ask, " SL: ", sl, " TP: ", tp);
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
        g_totalTrades++;
        Print("SELL opened: ", lot_size, " lots @ ", bid, " SL: ", sl, " TP: ", tp);
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

void CheckForClosedTrades()
{
    // This would be called in OnTradeTransaction for full implementation
    // For MVP, we track manually or use history
}

//+------------------------------------------------------------------+
//| Display Panel                                                      |
//+------------------------------------------------------------------+
void UpdateInfoPanel()
{
    if (!InpShowPanel) return;
    
    string session_status = IsInSession() ? "ACTIVE" : "CLOSED";
    string trading_status = g_tradingEnabled ? "ENABLED" : "DISABLED";
    
    Comment(
        "=== BOX STRATEGY EA v1.0 (MVP) ===\n",
        "Symbol: ", _Symbol, " | TF: ", EnumToString(Period()), "\n",
        "----------------------------------------\n",
        "Session: ", session_status, " (", GetBrokerSessionStart(), ":00-", GetBrokerSessionEnd(), ":00)\n",
        "Trading: ", trading_status, "\n",
        "----------------------------------------\n",
        "Current Box: ", g_currentBox, " / ", MAX_BOXES, "\n",
        "Clicks Used: ", g_sessionClicksUsed, " / ", MAX_CLICKS, "\n",
        "Drawdown: ", DoubleToString(GetCurrentDrawdownPips(), 1), " pips\n",
        "----------------------------------------\n",
        "Lot Size: ", DoubleToString(CalculateLotSize(), 2), "\n",
        "Pip Size: ", DoubleToString(GetPipSize(), 5), "\n",
        "----------------------------------------\n",
        "Session Trades: ", g_totalTrades, "\n",
        "Win Rate: ", (g_totalTrades > 0 ? DoubleToString((double)g_winningTrades/g_totalTrades*100, 1) : "N/A"), "%\n"
    );
}

//+------------------------------------------------------------------+
//| Simple Entry Signal (placeholder for proper logic)                |
//+------------------------------------------------------------------+
int GetEntrySignal()
{
    // Basic RSI-based entry for MVP testing
    // TODO: Replace with proper box edge detection
    
    double rsi[];
    ArraySetAsSeries(rsi, true);
    
    int rsi_handle = iRSI(_Symbol, PERIOD_M1, 14, PRICE_CLOSE);
    if (rsi_handle == INVALID_HANDLE) return 0;
    
    if (CopyBuffer(rsi_handle, 0, 0, 3, rsi) < 3) return 0;
    
    // Oversold = Buy signal
    if (rsi[0] < 30 && rsi[1] < 30)
        return 1;  // Buy
    
    // Overbought = Sell signal
    if (rsi[0] > 70 && rsi[1] > 70)
        return -1;  // Sell
    
    return 0;  // No signal
}

//+------------------------------------------------------------------+
//| Expert initialization function                                    |
//+------------------------------------------------------------------+
int OnInit()
{
    Print("==============================================");
    Print("Box Strategy EA v1.0 - Phase 1 MVP");
    Print("==============================================");
    
    // Validate symbol
    if (_Symbol != MVP_SYMBOL)
    {
        Print("WARNING: This EA is optimized for ", MVP_SYMBOL);
        Print("Current symbol: ", _Symbol);
    }
    
    // Validate timeframe
    if (Period() != PERIOD_M1)
    {
        Print("WARNING: This EA is optimized for M1 timeframe");
        Print("Current timeframe: ", EnumToString(Period()));
    }
    
    // Initialize trade object
    trade.SetExpertMagicNumber(InpMagicNumber);
    trade.SetDeviationInPoints(10);
    trade.SetTypeFilling(ORDER_FILLING_IOC);
    
    // Initialize session
    ResetSessionCounters();
    
    // Display settings
    Print("Broker Session: ", GetBrokerSessionStart(), ":00 - ", GetBrokerSessionEnd(), ":00 (server time)");
    Print("Lot Size: ", CalculateLotSize());
    Print("Pip Size: ", GetPipSize());
    Print("Max Stop: ", MAX_STOP_PIPS, " pips");
    Print("Take Profit: ", TAKE_PROFIT_PIPS, " pips");
    Print("==============================================");
    
    return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                  |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    Comment("");  // Clear panel
    Print("Box Strategy EA stopped. Reason: ", reason);
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
//| Trade transaction handler                                         |
//+------------------------------------------------------------------+
void OnTradeTransaction(const MqlTradeTransaction& trans,
                        const MqlTradeRequest& request,
                        const MqlTradeResult& result)
{
    // Track closed trades for statistics
    if (trans.type == TRADE_TRANSACTION_DEAL_ADD)
    {
        if (trans.deal_type == DEAL_TYPE_BUY || trans.deal_type == DEAL_TYPE_SELL)
        {
            // Position closed
            // TODO: Update win/loss statistics
        }
    }
}
//+------------------------------------------------------------------+
