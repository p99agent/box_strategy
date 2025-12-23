# Box Strategy EA - Technical Specification

**Version:** 1.6  
**Last Updated:** 2025-12-23  
**Source:** STRATEGY_BIBLE.md + 18 Mentorship Sessions  
**Review Status:** ChatGPT 5.2 Review v6 Complete ✅ READY FOR DEVELOPMENT

---

## Table of Contents
1. [Overview](#overview)
2. [Core Parameters](#core-parameters)
3. [Feature Specifications](#feature-specifications)
4. [Implementation Priority](#implementation-priority)
5. [Validation Criteria](#validation-criteria)

---

## Overview

### Purpose
A MetaTrader 5 Expert Advisor that automates the Box Strategy scalping methodology, targeting 3-pip profits with >95% win rate through probability-based range trading.

### Design Philosophy
- **Spec-Driven Development**: Each feature traced to source session
- **Measurable Goals**: Clear success criteria for each component
- **Risk-First**: Risk management is primary, profit is secondary

---

## Core Parameters

### MVP Constraints (v1.6 - LOCKED)
> **These values are hardcoded for Phase 1 MVP because the instructor calculated them specifically for this configuration.**

| Parameter | Locked Value | Source | Why Locked |
|-----------|--------------|--------|------------|
| **Symbol** | EURUSD | Sessions 1, 4 | 9-pip box calculated for EUR/USD |
| **Session Start** | 10:00 ET | Sessions 2, 10 | After 8:30 news + 9:30 NYSE open |
| **Session End** | 12:00 ET | Sessions 2, 10 | 2-hour window, before lunch volatility |
| **Box Height** | 9 pips | Session 4 | EUR/USD during 10:00-12:00 ET |
| **Box Duration** | 60 bars | Session 4 | 60 one-minute bars = 1 hour |
| **Time Frame** | M1 (1-minute) | Sessions 3, 4 | Required for 3-pip scalping |

### Fixed Parameters (Non-Configurable)
| Parameter | Value | Source | Rationale |
|-----------|-------|--------|-----------|
| Take Profit | 3 pips | Sessions 1-4 | Average 1-min bar size, highest probability |
| Max Stop Loss | 36 pips | Session 4 | 4 standard deviations, ejection seat |
| Risk per Click | 0.25% | Session 4 | 16 clicks × 0.25% = 4% max |
| Risk per Box | 1% | Session 4 | 4 clicks per box |
| Max Total Risk | 4% | Session 4 | 4 boxes maximum |
| Clicks per Box | 4 | Session 4 | Spread risk across attempts |
| Max Total Clicks | 16 | Session 6 | 4 boxes × 4 clicks |

### Configurable Parameters (Phase 2+)
| Parameter | Default | Range | Source | Notes |
|-----------|---------|-------|--------|-------|
| Account Type | HEDGE | HEDGE/FIFO | Session 17 | Affects position handling |
| End of Session Mode | HOLD | HOLD/CLOSE/REDUCE | Session 12 | What to do with open trades |

---

## Global Helper Definitions (v1.2 FIX)

### Pip Size Helper
```cpp
// CRITICAL: Handles both 4-digit and 5-digit brokers
double GetPipSize() {
    int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
    double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
    
    // 3-digit (JPY) or 5-digit (EUR/USD) = multiply by 10
    // 2-digit or 4-digit = use as-is
    if (digits == 3 || digits == 5)
        return point * 10;
    else
        return point;
}

// Usage everywhere: pip_size = GetPipSize();
```

### Max Stop Logic (v1.5 - with timezone handling)
```cpp
// MVP Phase 1: FIXED values for EUR/USD @ 10:00-12:00 ET
// These match the instructor's calculated parameters

#define MVP_SYMBOL "EURUSD"

// Timezone handling (v1.5 FIX)
// FTMO and most brokers use GMT+2 or GMT+3 (DST)
// Eastern Time = GMT-5 (or GMT-4 during DST)
// User must set this offset based on their broker
input int BrokerGMTOffset = 2;     // e.g., FTMO = GMT+2 (winter) or GMT+3 (summer)
input int TargetGMTOffset = -5;    // Eastern Time = GMT-5 (or -4 during DST)

// Effective session times in broker server hours:
// ET 10:00 = GMT 15:00 = Broker(GMT+2) 17:00
// ET 12:00 = GMT 17:00 = Broker(GMT+2) 19:00
#define SESSION_START_ET 10
#define SESSION_END_ET   12

// Convert ET to broker time (v1.6 FIX - with wrap-around):
int NormalizeHour(int hour) {
    while (hour < 0) hour += 24;
    return hour % 24;
}

int GetBrokerSessionStart() {
    int offset = BrokerGMTOffset - TargetGMTOffset;
    return NormalizeHour(SESSION_START_ET + offset);  // Handles wrap-around
}
int GetBrokerSessionEnd() {
    int offset = BrokerGMTOffset - TargetGMTOffset;
    return NormalizeHour(SESSION_END_ET + offset);
}

// Handle session crossing midnight:
bool IsInSession(int current_hour) {
    int start = GetBrokerSessionStart();
    int end = GetBrokerSessionEnd();
    if (start < end)
        return (current_hour >= start && current_hour < end);
    else  // Crosses midnight
        return (current_hour >= start || current_hour < end);
}

// Box and risk parameters (FIXED for MVP)
#define BOX_HEIGHT_PIPS 9        // EUR/USD box size
#define BOX_DURATION_BARS 60     // 60 one-minute bars
#define MAX_BOXES 4
#define MAX_STOP_PIPS (BOX_HEIGHT_PIPS * MAX_BOXES)  // = 36
#define TAKE_PROFIT_PIPS 3
```

---

## Feature Specifications

### SPEC-001: Box Calculation Engine
**Priority:** CRITICAL  
**Source:** Session 7  
**Goal:** Automatically calculate box dimensions from historical swing data

#### Requirements
- [ ] Measure last 10-12 swings on 5-minute chart
- [ ] Calculate average pips per swing (represents ~3 SD full move)
- [ ] Calculate average bars per swing
- [ ] Derive 1 SD using formula: `Box_Height = (Average_Swing_Pips / 3) + 1`
- [ ] Derive box duration = average bars × 5 (convert to 1-min)
- [ ] Clamp result: if Box_Height < 5, use 5; if > 15, use 15 (edge case handling)

#### Formula Clarification (CRITICAL FIX #1)
```
// The average swing measured = full move = ~3 standard deviations
// Divide by 3 to get 1 SD, add 1 pip as safety margin

average_swing = sum(swing_pips) / count(swings)  // e.g., 25 pips
one_sd = average_swing / 3                        // e.g., 8.33 pips
box_height = round(one_sd) + 1                    // e.g., 9 pips (with margin)
```

#### Success Criteria
- Box height within ±2 pips of manual calculation
- Box duration within ±10 bars of manual calculation

#### Implementation Decision
**IMPLEMENT**: Core functionality, enables all other features

---

### SPEC-002: Session Time Filter
**Priority:** CRITICAL  
**Source:** Sessions 2, 10  
**Goal:** Only trade within defined business hours

#### Requirements
- [ ] Allow trading only between start/end times
- [ ] Support timezone configuration via BrokerGMTOffset/TargetGMTOffset inputs
- [ ] Handle session crossing midnight (use IsInSession() helper)
- [ ] ~~Block trading 30 minutes before high-impact news~~ *(Deferred to SPEC-012)*
- [ ] ~~Wait 5 minutes after news events to resume~~ *(Deferred to SPEC-012)*

> **Phase 1 Note:** News filtering is NOT implemented in MVP. See SPEC-012 (Phase 3).

#### Success Criteria
- Zero trades outside session window
- Correct timezone conversion for any broker offset

#### Implementation Decision
**IMPLEMENT**: Prevents overtrading, matches professional schedule

---

### SPEC-003: Position Sizing Calculator
**Priority:** CRITICAL  
**Source:** Sessions 4, 14  
**Goal:** Calculate correct lot size for 0.25% risk per click

#### Requirements
- [ ] Calculate lot size using formula below
- [ ] Adjust for account currency (USD, GBP, AUD, etc.)
- [ ] Recalculate on each new trade
- [ ] Support micro/mini/standard lots
- [ ] Use broker's tick value for accuracy

#### Pip Value Calculation (v1.3 FIX - uses GetPipSize())
```cpp
// Use GetPipSize() helper for broker compatibility
double pip_size = GetPipSize();  // Works on 3/4/5-digit brokers

// Calculate pip value using MT5 tick info
double tick_value = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
double tick_size = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
double pip_value = (tick_value / tick_size) * pip_size;  // per 1.0 lot

// Full position sizing formula:
double risk_amount = AccountInfoDouble(ACCOUNT_EQUITY) * 0.0025;  // 0.25%
double risk_per_lot = MAX_STOP_PIPS * pip_value;  // Uses #define = 36
double lot_size = risk_amount / risk_per_lot;

// v1.6 FIX: Use SYMBOL_VOLUME_STEP for proper rounding (not NormalizeDouble)
double volume_step = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
double volume_min = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
double volume_max = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
lot_size = MathFloor(lot_size / volume_step) * volume_step;  // Round down to valid step
lot_size = MathMax(volume_min, MathMin(lot_size, volume_max));  // Clamp to limits

// Example on $10,000 account, EUR/USD (volume_step = 0.01):
// risk_amount = 10000 * 0.0025 = $25
// pip_value = ~$10 per pip per lot
// risk_per_lot = 36 * 10 = $360
// lot_size = 25 / 360 = 0.069 → floor to 0.06 lots
```

#### Success Criteria
- Each click risks exactly 0.25% of equity
- Works correctly across different account currencies
- Matches broker's margin calculator

#### Implementation Decision
**IMPLEMENT**: Core risk management, prevents over-leveraging

---

### SPEC-004: Box Counter and Tracker
**Priority:** CRITICAL  
**Source:** Sessions 4, 6  
**Goal:** Track current box level based on drawdown

#### Requirements
- [ ] Calculate current drawdown in pips
- [ ] Determine box level using BOX_HEIGHT_PIPS (fixed at 9 for MVP)
- [ ] Display on chart (Box 1, 2, 3, or 4)
- [ ] Alert when entering Box 4
- [ ] Block new trades if Box 5 reached

#### Box Level Calculation (v1.5 - uses fixed BOX_HEIGHT_PIPS)
```cpp
// MVP: BOX_HEIGHT_PIPS = 9 (fixed, matches position sizing)
double pip_size = GetPipSize();

double drawdown_pips = GetCurrentDrawdownPips();
int current_box = (int)MathFloor(drawdown_pips / BOX_HEIGHT_PIPS) + 1;

// Max stop = BOX_HEIGHT_PIPS * MAX_BOXES = 9 * 4 = 36
if (current_box > MAX_BOXES) {
    BlockNewTrades();
    TriggerEjection();
}
```

> **MVP Note:** Box height is fixed at 9 pips. SPEC-001 calculates "live" box height for display/validation only.

#### Success Criteria
- Accurate box level at all times
- Trading stops when 36 pips (4 × 9) drawdown reached

#### Implementation Decision
**IMPLEMENT**: Core risk management, prevents catastrophic loss

---

### SPEC-005: Click Counter
**Priority:** CRITICAL (MOVED TO PHASE 1 - FIX #2)  
**Source:** Session 6  
**Goal:** Limit total trades per session to 16 clicks

#### Requirements
- [ ] Track clicks used per session (reset daily)
- [ ] Track clicks used per box (reset when box changes)
- [ ] Display remaining clicks on chart
- [ ] Block new trades when 16 clicks reached
- [ ] Persist count across EA restarts (save to global variable)

#### Success Criteria
- Maximum 16 trades per session
- Maximum 4 trades per box level

#### Implementation Decision
**IMPLEMENT**: CRITICAL for risk management - prevents overtrading

---

### SPEC-006: Entry Logic - Support/Resistance Test
**Priority:** HIGH  
**Source:** Session 3 (Axiom 1)  
**Goal:** Enter trades at box edges testing for bounce

#### Requirements
- [ ] Detect when price reaches box bottom (for buys)
- [ ] Detect when price reaches box top (for sells)
- [ ] Confirm with top-down bias before entry
- [ ] Only enter if clicks available

#### Entry Conditions (BUY)
```
IF price <= box_bottom
AND bias == BULLISH
AND clicks_remaining > 0
AND current_box <= 4
THEN OPEN_BUY()
```

#### Success Criteria
- Entries only at box edges
- Entries aligned with bias

#### Implementation Decision
**IMPLEMENT**: Core entry logic based on axioms

---

### SPEC-007: Exit Logic - Take Profit
**Priority:** HIGH  
**Source:** Sessions 1-4  
**Goal:** Close profitable trades at 3 pips

#### Requirements
- [ ] Set TP at +3 pips from entry
- [ ] Close immediately when TP hit
- [ ] Track win for statistics

#### Success Criteria
- All profits closed at exactly 3 pips
- No slippage beyond 0.5 pips

#### Implementation Decision
**IMPLEMENT**: Core profit-taking mechanism

---

### SPEC-008: Exit Logic - Stop Loss (Ejection)
**Priority:** HIGH  
**Source:** Session 4  
**Goal:** Hard stop at 36 pips to protect account

#### Requirements
- [ ] Set SL at -36 pips from average entry
- [ ] Close ALL positions when hit
- [ ] Stop trading for session
- [ ] Log ejection event

#### Success Criteria
- Maximum loss per session = 4%
- Automatic recovery mode triggered

#### Implementation Decision
**IMPLEMENT**: Account protection, non-negotiable

---

### SPEC-009: Top-Down Bias Detection
**Priority:** HIGH  
**Source:** Sessions 5, 16  
**Goal:** Automatically determine bullish/bearish bias

#### Requirements
- [ ] Analyze daily chart for structure (HH/HL or LH/LL)
- [ ] Calculate ADR and remaining range
- [ ] Determine hourly range boundaries
- [ ] Set bias direction

#### Bias Logic (ENHANCED - WARNING #1 FIX)
```
// Step 1: Determine structure
IF daily_high > yesterday_high AND daily_low > yesterday_low:
    structure = BULLISH
ELSE IF daily_high < yesterday_high AND daily_low < yesterday_low:
    structure = BEARISH
ELSE:
    structure = RANGING

// Step 2: Check ADR exhaustion (WARNING #1 FIX)
adr = calculate_average_daily_range(20);  // 20-day ADR
adr_used = daily_high - daily_low;
adr_ratio = adr_used / adr;

IF adr_ratio > 0.80:  // 80% of ADR already used
    BIAS = RANGING    // Expect reversal, trade both edges
ELSE:
    BIAS = structure  // Use structure-based bias
```

#### Success Criteria
- Bias matches manual analysis >85% of time
- No counter-trend trades during strong trends
- Correctly identifies ADR exhaustion scenarios

#### Implementation Decision
**IMPLEMENT**: Improves win rate, reduces drawdown

---

### SPEC-010: Layering Mode (Drawdown Repair)
**Priority:** MEDIUM  
**Source:** Sessions 3, 8  
**Goal:** Add trades in boxes 2-4 to average down

#### Requirements
- [ ] When in Box 2+, continue adding per original strategy
- [ ] Track average entry price across all positions
- [ ] Adjust break-even level dynamically
- [ ] Limit to 4 trades per box

#### Break-Even Calculation (v1.2 FIX - BUY/SELL separated)
```cpp
double pip_size = GetPipSize();  // Use helper, not Point*10

// Calculate weighted average entry
double total_lots = 0;
double weighted_sum = 0;

for (int i = 0; i < PositionsTotal(); i++) {
    if (PositionSelectByTicket(tickets[i])) {
        double lots = PositionGetDouble(POSITION_VOLUME);
        double entry = PositionGetDouble(POSITION_PRICE_OPEN);
        total_lots += lots;
        weighted_sum += entry * lots;
    }
}

double average_entry = weighted_sum / total_lots;
double target_pips = 3;  // NET profit target (after spread)

// BUY positions: need price to go UP
IF position_type == POSITION_TYPE_BUY:
    // Entry already paid the spread, so just add 3 pips
    break_even_price = average_entry + (target_pips * pip_size);

// SELL positions: need price to go DOWN  
ELSE IF position_type == POSITION_TYPE_SELL:
    // Entry already paid the spread, so just subtract 3 pips
    break_even_price = average_entry - (target_pips * pip_size);

// Note: "3 pips target" means NET profit of 3 pips
// Spread is paid at entry, not calculated into break-even
```

#### Example:
```
// BUY Scenario:
// Position 1: Buy 0.1 lots @ 1.0850
// Position 2: Buy 0.1 lots @ 1.0841 (9 pips lower)
// Average entry = (1.0850*0.1 + 1.0841*0.1) / 0.2 = 1.08455
// Break-even = 1.08455 + 0.0003 (3 pips) = 1.08485

// SELL Scenario:
// Position 1: Sell 0.1 lots @ 1.0850
// Position 2: Sell 0.1 lots @ 1.0859 (9 pips higher)
// Average entry = (1.0850*0.1 + 1.0859*0.1) / 0.2 = 1.08545
// Break-even = 1.08545 - 0.0003 (3 pips) = 1.08515
```

#### Success Criteria
- Break-even achieved when price returns to calculated level
- No over-commitment beyond 4% total risk

#### Implementation Decision
**IMPLEMENT**: Core repair mechanism, enables high win rate

---

### SPEC-011: End of Session Handler
**Priority:** MEDIUM  
**Source:** Session 12  
**Goal:** Handle open trades when session ends

#### Requirements
- [ ] Detect session end time
- [ ] Stop opening new trades
- [ ] Options for open positions:
  - Hold as-is (default)
  - Close all
  - Reduce worst losers

#### Success Criteria
- Clean session boundaries
- No unexpected overnight behavior

#### Implementation Decision
**IMPLEMENT**: Professional operation, defined exit

---

### SPEC-012: News Event Filter
**Priority:** MEDIUM  
**Source:** Session 10  
**Goal:** Avoid trading during high-impact news

#### Requirements
- [ ] Integrate with economic calendar
- [ ] Detect high-impact events (NFP, FOMC, CPI)
- [ ] Block trading 30 min before
- [ ] Wait 5 min after
- [ ] Detect spike bars (>20 pips) and pause

#### Success Criteria
- Zero trades during news events
- Resume trading when bars normalize

#### Implementation Decision
**IMPLEMENT**: Significant risk reduction

---

### SPEC-013: Visual Box Indicator
**Priority:** MEDIUM  
**Source:** Session 7  
**Goal:** Display boxes on chart for visual reference

#### Requirements
- [ ] Draw box rectangles from swing points
- [ ] Color code by box level (1-4)
- [ ] Show break-even line
- [ ] Show entry levels

#### Success Criteria
- Clear visual representation matching manual boxes
- Updates in real-time

#### Implementation Decision
**IMPLEMENT**: Aids monitoring and validation

---

### SPEC-014: Statistics Dashboard
**Priority:** LOW  
**Source:** Session 15  
**Goal:** Track performance metrics

#### Requirements
- [ ] Win rate percentage
- [ ] Total pips gained/lost
- [ ] Clicks used today
- [ ] Current box level
- [ ] Daily P/L percentage

#### Success Criteria
- Accurate real-time statistics
- Matches broker account history

#### Implementation Decision
**IMPLEMENT**: Essential for business operation

---

### SPEC-015: FIFO Compliance Mode
**Priority:** LOW  
**Source:** Session 17  
**Goal:** Support US brokers with FIFO rules

#### Requirements
- [ ] Detect account type (HEDGE/NETTING)
- [ ] If FIFO: close oldest trades first
- [ ] If FIFO: prevent opposite positions
- [ ] Adjust layering strategy accordingly

#### Success Criteria
- No broker violations
- Works correctly on US accounts

#### Implementation Decision
**IMPLEMENT IF NEEDED**: Only for US traders

---

### SPEC-016: Multi-Pair Support
**Priority:** LOW  
**Source:** Session 14  
**Goal:** Trade multiple pairs simultaneously

#### Requirements
- [ ] Check correlation before adding pairs
- [ ] Separate risk pools per pair
- [ ] Avoid correlated risk stacking

#### Success Criteria
- Maximum 2-3 uncorrelated pairs
- No correlation above 70%

#### Implementation Decision
**DEFER**: Start with single pair, add later if needed

---

### SPEC-017: Swing Trade Mode
**Priority:** LOW  
**Source:** Session 18  
**Goal:** Support higher time frame box trading

#### Requirements
- [ ] Allow 1-hour, 4-hour, daily time frame selection
- [ ] Recalculate box dimensions
- [ ] Adjust position sizing for larger stops

#### Success Criteria
- Works on all time frames
- Same percentage risk regardless of TF

#### Implementation Decision
**DEFER**: Focus on 1-min scalping first

---

## Implementation Priority

### Phase 1: Core (MVP) - v1.6 FINAL
1. SPEC-001: Box Calculation Engine (for display/validation)
2. SPEC-003: Position Sizing Calculator (with GetPipSize())
3. SPEC-002: Session Time Filter (with timezone offset)
4. SPEC-004: Box Counter and Tracker (fixed 9 pips)
5. SPEC-005: Click Counter
6. SPEC-006: Entry Logic
7. SPEC-007: Exit Logic - Take Profit
8. SPEC-008: Exit Logic - Stop Loss

### Phase 2: Enhanced
9. SPEC-009: Top-Down Bias Detection (with ADR fix)
10. SPEC-010: Layering Mode (with BUY/SELL break-even fix)
11. SPEC-011: End of Session Handler
12. SPEC-013: Visual Box Indicator (aids validation)

### Phase 3: Optimization
13. SPEC-012: News Event Filter
14. SPEC-014: Statistics Dashboard

### Phase 4: Extensions
15. SPEC-015: FIFO Compliance Mode
16. SPEC-016: Multi-Pair Support
17. SPEC-017: Swing Trade Mode

---

## Validation Criteria

### Backtest Requirements
| Metric | Target | Source |
|--------|--------|--------|
| Win Rate | >90% | Sessions 1-4, 13 |
| Max Drawdown | <4% | Session 4 |
| Target/Day | 0.25-0.5% | Session 11 |
| Trades/Session | 10-50 | Session 2 |
| Max Loss/Trade | 36 pips | Session 4 |

### Demo Testing Checklist
- [ ] Correct position sizing
- [ ] Trading only in session window
- [ ] Stops at 16 clicks
- [ ] Stops at 36 pips drawdown
- [ ] Visual boxes match manual
- [ ] Statistics accurate
- [ ] No broker violations

---

## Revision History
| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2025-12-23 | Initial specification from 18 sessions |
| 1.1 | 2025-12-23 | ChatGPT 5.2 Review fixes: (1) Clarified box formula, (2) Moved Click Counter to Phase 1, (3) Added pip value calculation, (4) Added ADR to bias detection, (5) Added break-even formula |
| 1.2 | 2025-12-23 | ChatGPT 5.2 Review v2 fixes: (1) Added GetPipSize() helper for 4/5-digit brokers, (2) Dynamic box_height in SPEC-004, (3) Fixed phase list duplicate SPEC-013, (4) Added BUY/SELL break-even formulas |
| 1.3 | 2025-12-23 | ChatGPT 5.2 Review v3 fixes: (1) Locked BOX_HEIGHT_PIPS=9 for MVP consistency, (2) SPEC-003 uses GetPipSize() instead of Point*10, (3) All specs use consistent MAX_STOP_PIPS=36 via #define |
| 1.4 | 2025-12-23 | MVP Constraints locked: EUR/USD only, 10:00-12:00 ET, M1 timeframe, 9 pips box, 60 bars duration - matching instructor's exact configuration |
| 1.5 | 2025-12-23 | (1) Added timezone handling with BrokerGMTOffset/TargetGMTOffset inputs, (2) Fixed Phase 1 header to v1.5 FINAL, (3) Cleaned SPEC-004 phrasing - removed all "dynamic" references |
| 1.6 | 2025-12-23 | FINAL: (1) Added NormalizeHour() + IsInSession() for hour wrap-around/midnight crossing, (2) Deferred news blackout to SPEC-012, (3) SPEC-003 uses SYMBOL_VOLUME_STEP for lot rounding |
