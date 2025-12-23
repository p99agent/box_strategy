# Session 04: Risk Guidelines

---

## Core Risk Allocation Structure

### Per-Trade Risk
| Level | Allocation | Purpose |
|-------|------------|---------|
| Per Click | **0.25%** | Single trade entry |
| Per Box | **1%** (4 clicks) | One standard deviation zone |
| Max Total | **4%** (4 boxes) | Emergency stop level |

> *"I allocate 1% or less per box. I'm willing to use up to 4 boxes."*

---

## The 36-Pip Stop Loss

### Why 36 Pips?
- 4 standard deviations (4 × 9 pips)
- Beyond this = falling off the bell curve
- This is the **ejection seat**, not the trade stopper

> *"The stop loss is an ejection seat to protect the account. It's not to stop the trade itself."*

### Stop Loss Philosophy
| Traditional View | Box Strategy View |
|------------------|-------------------|
| Stop loss stops the trade | YOU stop the trade before SL |
| Let it hit or TP | Engineer an exit |
| Accept the loss | Find break-even first |

---

## The "Long Tail" Concept

A **long tail** = wick on daily chart = news reaction that reverses quickly

```
┌─────────────────────────────────────┐
│   Normal moves: Within 4 boxes      │
│   Long tail: Momentary spike        │
│   beyond 4 boxes that reverses      │
│                                     │
│   The 36-pip SL protects from       │
│   being caught in long tails        │
└─────────────────────────────────────┘
```

---

## The 3-Pip Target Rationale

### Average Bar Size
| Time Frame | Average Bar | Target |
|------------|-------------|--------|
| 1-minute | 3-4 pips | **3 pips** |
| 5-minute | ~9 pips | ~9 pips |
| 1-hour | ~18 pips | ~18 pips |

> *"On a 5-minute chart, I'm looking to bounce about 9 pips. On a 1-minute chart, I'm looking to bounce every 3 pips."*

---

## Box at Rest (Volatility Baseline)

### EUR/USD Asia Session (Low Volatility)
When nothing is pushing/pulling the market:
- Box at rest = **9 pips**
- Duration = **12 five-minute bars** = **60 one-minute bars**

### Potential Calculation
| Chart | Bars in Box | Avg Bar | Potential |
|-------|-------------|---------|-----------|
| 5-minute | 12 bars | 4 pips | 48 pips |
| 1-minute | 60 bars | 3 pips | **180 pips** |

> *"If you zoom into the box on a 1-minute chart, your potential for making money is now 180 pips."*

---

## Trading as Business: Leave the Casino Daily

### Why Leave Every Day?
1. Prevents overtrading
2. Locks in profits
3. Prevents drawdown spiraling
4. Maintains psychological health

> *"The market is not a 24-hour money machine. At best it may be worthwhile 4 or 5 hours per day. Of those 4 or 5, pick 2."*

### Daily Business Operations
```
Revenue:   3 pips × N trades
Expenses:  Losses, spreads, swaps
Profit:    Net after expenses
Action:    Close doors, go home, repeat tomorrow
```

---

## Equity Curve Expectations

### Real Account Example (from transcript)
- Account: $14,000
- Period: ~2.5 months
- Trades: ~3,000
- Each trade: 3 pips target
- Worst drawdown: $500 (~3.5%)

### Curve Characteristics
- Very high win rate (>90%)
- Small, consistent gains
- Rare but larger losses (can take 3 days of work)
- Never changed: target, size, stop, time of day

---

## Loss Prevention Hierarchy

### Priority Order
1. **Make 3 pips** (ideal outcome)
2. **Engineer break-even** (if in trouble)
3. **Engineer smaller loss** (if can't break even)
4. **Accept 36-pip ejection** (last resort only)

> *"Our job is to catch the losers before they go to the stop loss."*

---

## Progressive Drawdown Warning

Losses don't happen suddenly—they build progressively:

```
Box 1: Small drawdown → OPPORTUNITY TO STOP
Box 2: Medium drawdown → OPPORTUNITY TO STOP
Box 3: Large drawdown → OPPORTUNITY TO STOP
Box 4: Maximum drawdown → LAST CHANCE
Box 5: Account damage → TOO LATE
```

> *"A 4% loss, maybe every quarter. It's rare because we don't overtrade."*

---

## Risk Parameters for EA

| Parameter | Value | Notes |
|-----------|-------|-------|
| Risk per Click | 0.25% | Fixed |
| Risk per Box | 1% | 4 clicks |
| Max Boxes | 4 | 16 total clicks |
| Max Risk | 4% | Hard limit |
| Stop Loss | 36 pips | Ejection seat |
| Take Profit | 3 pips | Per trade |
| Daily Target | 0.3-0.5% | Realistic expectation |

---

## EA Logic: Risk Management

```
// Position sizing
lot_size = (account_equity * 0.0025) / (36 * pip_value)

// Box tracking
current_box = floor(drawdown_pips / 9) + 1

// Risk gate
IF current_box > 4:
    CLOSE_ALL_POSITIONS()
    STOP_TRADING_TODAY()

// Daily profit target
IF daily_profit >= 0.5%:
    CONSIDER_STOPPING()
```

---

## Key Quotes

1. *"One loss can take away 3 days of work. Our job is to catch the losers before they go to the stop loss."*

2. *"Pay your expenses like a business. Earn a revenue, pay your expenses, close your doors for the day."*

3. *"Size to use the 4 boxes. The 4 boxes are a prerequisite."*

---

## Action Items for EA Development

- [ ] Implement 0.25% per trade position sizing
- [ ] Create box counter (1-4) based on drawdown
- [ ] Add 36-pip hard stop loss
- [ ] Build daily profit target check (0.3-0.5%)
- [ ] Implement "leave casino" session end logic
