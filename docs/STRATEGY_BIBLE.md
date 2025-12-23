# Box Strategy - Single Source of Truth
*Last Updated: 2025-12-23*

> **Purpose**: This document consolidates all trading rules, parameters, and logic extracted from Jean Francois Bouchet's Box Strategy mentorship sessions. It serves as the definitive reference for EA development.

---

## Table of Contents
1. [Strategy Overview](#strategy-overview)
2. [Core Philosophy](#core-philosophy)
3. [Box Calculation](#box-calculation)
4. [Trading Rules](#trading-rules)
5. [Risk Management](#risk-management)
6. [Session Timing](#session-timing)
7. [Instrument Selection](#instrument-selection)
8. [Entry Criteria](#entry-criteria)
9. [Exit Criteria](#exit-criteria)
10. [Trade Management](#trade-management)
11. [Session Notes](#session-notes)

---

## Strategy Overview

The Box Strategy is a **probability-based scalping methodology** that:
- Exploits **mean reversion** within statistically measured ranges
- Uses **standard deviation** to define tradeable boxes
- Targets **small, consistent profits** (3 pips) with high win rate
- Manages risk through **position spreading** (4 trades per box)

### Theoretical Foundation
- **Brownian Motion in Finance** - Price follows random walk within predictable bounds
- **Bayes' Theorem** - Historical data informs future probabilities
- **Bell Curve Distribution** - 68% of moves fall within 1 SD, 95% within 2 SD

---

## Core Philosophy

### The Insurance Company Model
> *"I'm taking in many, many small returns. And I seldomly pay out on a claim or loss."*

| Swing Trading | Box Strategy |
|---------------|--------------|
| Few trades, big targets | Many trades, small targets |
| Risk:Reward focus | Win rate focus |
| Wait for breakouts | Trade the bounces |
| Accept series of losses | Avoid losing streaks |

### Psychology Shift
- **From**: Fear of missing out (FOMO), chasing breakouts
- **To**: Consistency, discipline, operating like a business

---

## Box Calculation

### Measurement Process
1. Go to **5-minute chart** at your trading time
2. Measure **10-12 swing moves** (use ZigZag indicator)
3. Record for each swing: **pips** and **bars**
4. **Average** both values
5. **Divide by 3** to get 1 standard deviation
6. **Add 1** for margin of error

### Example Calculation
```
Swing 1: 25 pips, 28 bars
Swing 2: 5 pips, 26 bars
Swing 3: 12 pips, 38 bars
...
Total: 242 pips / 10 = 24.2 pips average
Total bars: 120 / 10 = 12 bars average

1 Standard Deviation = 24/3 = 8 pips (round to 9)
Box Duration = 12 bars on 5-min = 60 bars on 1-min
```

### Standard Box Values (EUR/USD)
| Parameter | Value |
|-----------|-------|
| 1 Box (1 SD) | **9 pips** |
| 2 Boxes (2 SD) | 18 pips |
| 3 Boxes (3 SD) | **27 pips** |
| 4 Boxes (4 SD) | **36 pips** |
| Box Duration | **60 one-minute bars** |

---

## Trading Rules

### The Three Axioms

#### Axiom 1: Support/Resistance Test
> *"If testing for support, you know you've found support when price moves up."*

- A bounce = support confirmed → take profit
- No bounce = move to Axiom 2

#### Axiom 2: Trend Initiation
> *"A trend will start with the failure of support or resistance."*

- Failed support → bearish trend starting
- Failed resistance → bullish trend starting

#### Axiom 3: Momentum Measurement
> *"The distance between pivots is the best way to measure momentum."*

- Large pivot spacing = strong momentum
- Decreasing spacing = reversal coming

---

## Risk Management

### Position Sizing

| Level | Risk Allocation | Usage |
|-------|-----------------|-------|
| Per Click | **0.25%** | Single trade entry |
| Per Box | **1%** (4 clicks) | One standard deviation zone |
| Max Total | **4%** (4 boxes) | Emergency stop level |

### The 4-Box Rule
```
Box 1: Normal trading zone (0-9 pips drawdown)
Box 2: Repair zone (9-18 pips drawdown)  
Box 3: Extended repair (18-27 pips drawdown)
Box 4: Final defense (27-36 pips drawdown)
Box 5+: EJECT - Close all trades
```

### Stop Loss Philosophy
> *"The stop loss is an ejection seat to protect the account. It's not to stop the trade itself."*

- **Hard Stop**: 36 pips (automatic)
- **Soft Management**: Engineer exits before reaching 36

---

## Session Timing

### Optimal Trading Windows

| Session | Time (Eastern) | Characteristics |
|---------|----------------|-----------------|
| **North America Start** | 10:00-12:00 | Best for US traders, after options expiry |
| Europe Close | 11:00-12:00 | Reduced volatility, ranging |
| Avoid | Before 10:00 | News events, stock market open |

### Daily Schedule
```
8:30  - Major news releases (STAND ASIDE)
9:30  - Stock market opens (STAND ASIDE)
10:00 - Options expiry complete (START TRADING)
10:05 - Begin placing trades
12:00 - Close session (STOP TRADING)
```

### News Avoidance
- Never trade INTO news events
- Wait 5 minutes after news to trade
- Be an "ambulance chaser" - clean up the mess

---

## Instrument Selection

### Preferred Pairs (Ranging Behavior)
| Pair | Reason |
|------|--------|
| **EUR/GBP** | Geopolitically stable, range-bound |
| **EUR/CHF** | Neighboring economies, stable relationship |
| **GBP/CHF** | Cross-pair, limited trending |

### Avoid (Trending Behavior)
- Pairs with **USD** (safe haven flows)
- Pairs with **JPY** (safe haven flows)
- Any pair during major news

---

## Entry Criteria

### Checklist Before Entry
1. ✅ Within trading session (10:00-12:00 ET)
2. ✅ Bias determined (top-down analysis complete)
3. ✅ At edge of box (support or resistance level)
4. ✅ Risk budget available (<4 boxes used)
5. ✅ No pending news events

### Entry Logic
```
IF price at bottom of box AND bias is bullish:
    → BUY (test for support)
    
IF price at top of box AND bias is bearish:
    → SELL (test for resistance)
```

---

## Exit Criteria

### Take Profit
- **Target**: 3 pips (1 one-minute bar of movement)
- **Rationale**: High probability, consistent, repeatable

### Stop Loss Levels
| Condition | Action |
|-----------|--------|
| +3 pips | Close with profit |
| 0 to -9 pips | Hold, within Box 1 |
| -9 to -18 pips | Add trades, Box 2 |
| -18 to -27 pips | Add trades, Box 3 |
| -27 to -35 pips | Last chance, Box 4 |
| **-36 pips** | **CLOSE ALL** |

---

## Trade Management

### Layering / Averaging
- Add trades at each box level as price moves against you
- Each new trade aims for same 3-pip target
- Average entry improves with each addition

### End of Session Options
1. **Accept trades as-is** (preferred) - Let stop/target work overnight
2. **Reduce risk** - Close worst losers, keep better positions
3. **Hedge** - Offset with opposite trades (advanced, opens complexity)
4. **Close all** - Book small loss, start fresh tomorrow

---

## Session Notes

### Session 01: Philosophy of Trading Ranges ✅
**Key Extractions:**
- **Insurance Model**: Many small wins (premiums), rare losses (claims)
- **Psychology**: Shift from fear-based to reward-seeking behavior
- **Pairs**: Prefer EUR/GBP, EUR/CHF, GBP/CHF (ranging crosses)
- **Avoid**: USD pairs, JPY pairs (trending safe havens)
- **Capital Matching**: Small accounts → 1-min chart; Large accounts → Daily chart
- **Core Quote**: *"Ask what the market is willing to give, then ask for that many times"*
- [Full Session Notes](sessions/session_01_philosophy.md)

### Session 02: Assumptions and Basics ✅
**Key Extractions:**
- **Scalping Definition**: Small slice at edges, not meat of move
- **PAY Concept**: Potential Average Yield = time frame × time of day × consistency
- **Business Hours**: 10:00-12:00 Eastern (2-hour window)
- **Schedule**: Wait for options expiry (10:00), avoid news, leave daily
- **Plan A/B**: Always think one move ahead, prepare for both outcomes
- **Spreading**: Break 1% risk into 4 × 0.25% trades
- [Full Session Notes](sessions/session_02_assumptions.md)

### Session 03: Axioms of Trading ✅
**Key Extractions:**
- **Axiom 1**: Support confirmed when price bounces UP; resistance when bounces DOWN
- **Axiom 2**: Trend starts when support/resistance FAILS
- **Axiom 3**: Pivot spacing measures momentum (decreasing = reversal)
- **Box Origin**: Measured from market, not invented—average 10-12 swings
- **4-Attempt Rule**: Maximum 4 tries per direction, then stop
- **Time-Price Exchange**: Unused time converts to price movement
- [Full Session Notes](sessions/session_03_axioms.md)

### Session 04: Risk Guidelines ✅
**Key Extractions:**
- **Per Click**: 0.25% | **Per Box**: 1% | **Max Total**: 4%
- **Stop Loss**: 36 pips = ejection seat, not trade stopper
- **Target**: 3 pips (average 1-min bar size)
- **Box at Rest**: 9 pips, 60 one-min bars (EUR/USD Asia)
- **Daily Target**: 0.3-0.5% realistic, risk 1% to get it
- **Leave Casino**: Close doors daily, prevent overtrading
- **Loss Prevention**: Engineer exits before 36-pip stop hits
- [Full Session Notes](sessions/session_04_risk.md)

### Session 05: Deciding on the Bias ✅
**Key Extractions:**
- **Top-Down**: Daily (idea) → Hourly (plan) → 5-min (road map) → 1-min (execute)
- **ADR Check**: How much daily range already used? Remaining = opportunity
- **Structure**: HH+HL = bullish, LH+LL = bearish
- [Full Session Notes](sessions/session_05_bias.md)

### Session 06: Overtrading and Trade Management ✅
**Key Extractions:**
- **Budget System**: 4 clicks per box, 16 total maximum
- **End of Session Options**: Hold as-is (preferred), reduce, hedge (last resort), close all
- [Full Session Notes](sessions/session_06_overtrading.md)

### Session 07: Boxes - Creation & Measurement ✅
**Key Extractions:**
- **Measurement**: 10-12 swings on 5-min chart, average pips and bars
- **Formula**: Full move ÷ 3 = 1 SD, add 1 pip margin → ~9 pips × 60 bars
- [Full Session Notes](sessions/session_07_boxes.md)

### Session 08: Trading Under Different Conditions ✅
**Key Extractions:**
- **Aligned Bias**: Recycle, recycle, recycle
- **Wrong Bias**: Layer in, wait for bounce
- [Full Session Notes](sessions/session_08_conditions.md)

### Session 09: Learning Resources ✅
- **Brownian Motion + Bayes' Theorem** = theoretical foundation
- [Full Session Notes](sessions/session_09_resources.md)

### Session 10: News Trading ✅
- **Never trade INTO news** — be an ambulance chaser (trade AFTER)
- [Full Session Notes](sessions/session_10_news.md)

### Session 11: Scalper Mindset ✅
- **Insurance company model** — hate paying claims
- [Full Session Notes](sessions/session_11_mindset.md)

### Session 12: Drawdown Management ✅
- **4 Options**: Transfer, Reduce, Accept (preferred), Avoid
- [Full Session Notes](sessions/session_12_drawdown.md)

### Session 13: Psychology of Scalping ✅
- **Law of Large Numbers** — 1000 scalps in months vs years
- [Full Session Notes](sessions/session_13_psychology.md)

### Session 14: Alternative Instruments ✅
- **Correlations matter** — after testing 27 pairs, EUR/USD was enough
- [Full Session Notes](sessions/session_14_timeframes.md)

### Session 15: Trading as Business ✅
- **Raise standards, not goals** — pay yourself on schedule
- [Full Session Notes](sessions/session_15_business.md)

### Session 16: Top-Down Analysis ✅
- **Daily→Hourly→5min→1min** = Idea→Plan→Map→Execute
- [Full Session Notes](sessions/session_16_topdown.md)

### Session 17: FIFO vs Hedging ✅
- **FIFO (US)**: No hedging | **Non-FIFO**: Hedging allowed
- [Full Session Notes](sessions/session_17_fifo.md)

### Session 18: Swing Trading ✅
- **Box scaling**: 4-hour=36 pips, Daily=60+ pips
- [Full Session Notes](sessions/session_18_swing.md)


---

## Quick Reference Card

```
┌─────────────────────────────────────────────────┐
│              BOX STRATEGY CHEAT SHEET            │
├─────────────────────────────────────────────────┤
│ Box Size:        9 pips (1 SD)                  │
│ Max Loss:        36 pips (4 SD)                 │
│ Target:          3 pips                         │
│ Clicks/Box:      4                              │
│ Risk/Click:      0.25%                          │
│ Max Risk:        4%                             │
│ Session:         10:00-12:00 ET                 │
│ Pairs:           EUR/GBP, EUR/CHF               │
├─────────────────────────────────────────────────┤
│ Box 1: Trade normally                           │
│ Box 2: Start repairs                            │
│ Box 3: Continue repairs                         │
│ Box 4: Last defense                             │
│ Box 5: EJECT!                                   │
└─────────────────────────────────────────────────┘
```
