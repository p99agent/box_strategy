# Session 06: Overtrading and Trade Management

---

## How NOT to Overtrade

### The Budget System
| Allocation | Trades | Risk |
|------------|--------|------|
| Per Box | 4 clicks | 1% |
| 2 Boxes | 8 clicks | 2% |
| 3 Boxes | 12 clicks | 3% |
| 4 Boxes | 16 clicks | 4% MAX |

> *"In order to not overtrade, we must allocate certain amounts of money per box."*

### Pre-Planning Clicks
Before trading, know:
- At level X → I will have spent 2%
- At level Y → I will have spent 3%
- At level Z → Maybe I want to quit

---

## Overtrading Definition

### What IS Overtrading
- Trading after meeting your goal
- Using time as excuse to trade more
- Greed-driven trading
- Exceeding allocated clicks

### What is NOT Overtrading
- Spreading 1% across 4 trades in a box
- Adding trades in box 2 to repair
- Recycling after hitting target

---

## End of Session: Trade Management Options

### Option 1: Accept Trades As-Is (PREFERRED)
- You agreed to 36-pip stop when entering
- You agreed to 3-pip target
- Leave trades untouched
- Let market work overnight

> *"Typically you don't touch anything."*

### Option 2: Reduce Risk
- Close the WORST losers first
- Keep better positions with hope
- Book small loss, protect rest

### Option 3: Hedge (Advanced)
- Add opposite position to offset
- Locks current drawdown
- Opens complexity (two-sided problem)
- Still your responsibility to unwind

### Option 4: Close All
- Book total loss
- Start fresh tomorrow
- Sometimes the cleanest option

---

## The 16-Click Limit

### Bullet Counting
- Each click = ammunition
- Maximum 16 bullets per direction
- Run out of bullets = stop trading

> *"If you either run out of bullets or you run out of time, you're stuck."*

### Time + Bullets Combined
```
IF bullets_remaining == 0:
    STOP_TRADING()
    
IF session_time_remaining == 0:
    STOP_TRADING()
```

---

## Pre-Trade Risk Visualization

### Road Map as Budget
Before session starts, map out:
```
Level 1.0850 → If reached, 4 trades used (1%)
Level 1.0840 → If reached, 8 trades used (2%)
Level 1.0830 → If reached, 12 trades used (3%)
Level 1.0820 → If reached, 16 trades used (4% - STOP)
```

---

## Recycling vs Building

| Market State | Action | Risk |
|--------------|--------|------|
| Bias aligned, bouncing | Recycle same trade | Low |
| Against bias, building | Layer additional trades | Medium |
| 4+ boxes against | Stop adding | High |

---

## The Leftover Trade Problem

### When Session Ends with Open Trades
1. Check structure—is it still valid?
2. Check distance to stop—how bad is it?
3. Decision: Hold, reduce, or close

### Hold Criteria
- Structure unchanged since entry
- Drawdown within 1-2 boxes
- No imminent news overnight

### Close Criteria
- Structure clearly broken
- Approaching 36-pip stop
- High-risk news overnight

---

## Key Parameters for EA

| Parameter | Value |
|-----------|-------|
| Max clicks total | 16 |
| Clicks per box | 4 |
| Session limit | Hard stop at time |
| Leftover action | Configurable (hold/close) |

---

## EA Logic: Overtrade Prevention

```
// Track clicks
IF clicks_today >= 16:
    TRADING_ALLOWED = false
    LOG("Max clicks reached")

// Track boxes used
IF current_drawdown > 36 pips:
    CLOSE_ALL()
    TRADING_ALLOWED = false

// Session end handling
IF session_ended AND has_open_trades:
    IF drawdown < 18 pips:
        HOLD_TRADES()  // Within 2 boxes
    ELSE:
        CLOSE_WORST_LOSERS()
```

---

## Key Quotes

1. *"Each click is maybe 0.25%. You're limited to the number of clicks."*

2. *"Just walk away and don't touch your stops, don't touch your target."*

3. *"The stop loss is the last resort. The solution is usually average."*

---

## Action Items for EA

- [ ] Implement click counter (max 16)
- [ ] Add box-based position allocation
- [ ] Build end-of-session handler
- [ ] Create leftover trade management logic
