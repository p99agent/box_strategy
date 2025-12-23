# Session 08: Trading Under Different Market Conditions

---

## Two Main Market Conditions

### Condition 1: Bias is Correct (Aligned)
- Market moving in your predicted direction
- **Action**: Recycle, recycle, recycle
- Each trade hits target, open next immediately

### Condition 2: Bias is Wrong (Counter-Trend)
- Market moving against your prediction
- **Action**: Layer in, wait for bounce
- Postponed gratification

---

## Trading When Bias is Correct

### The Recycling Pattern
```
Trade 1: Buy → +3 pips → Close
Trade 2: Buy → +3 pips → Close
Trade 3: Buy → +3 pips → Close
...repeat...
```

### Key Principle
> *"We're not chasing the market, but exploiting what the market has to give."*

### Measuring the Move
- Count boxes from starting point
- Know when the move is "running out"
- 2-3 boxes typical, 4 boxes maximum

---

## Trading When Bias is Temporarily Wrong

### The Layering Pattern
```
Trade 1: Buy at level A → Goes against
Trade 2: Buy at level B (lower) → Goes against
Trade 3: Buy at level C (lower) → Goes against
Trade 4: Buy at level D (lower) → BOUNCE
All trades: Close at +3 pips average
```

### Measuring Drawdown
> *"At 8 o'clock we'd already moved 2 boxes, so I bought. Market pulled against me: 1 box, 2 boxes. We had 2 boxes layered in—got paid an hour later."*

---

## The 16-Chance System

### Not Random Throws
Each attempt must have:
1. Look left (find reference)
2. Find support/resistance
3. Find an excuse to expect bounce

> *"The 16 chances are not random throws of darts."*

---

## Rinse, Wash, Repeat

### Two Patterns
| Pattern | Description | Frequency |
|---------|-------------|-----------|
| Recycle | Trade works, repeat immediately | Common |
| Layer | Trade fails, add more, wait | Less common |

### Combined Example (Real Session)
```
8:00 AM - Bullish bias, market bearish
  → Bought, made 3 pips
  → Recycled, made 3 pips
  → Market pulled against
  → Layered in 2 boxes
  → Got paid 1 hour later
  → Repeated same scenario
  → Paid again
```

---

## Never Fight the Trend

### Stay Aligned
> *"By not counter-trend trading, when the big move comes along, I'm not threatened by it."*

### Even When Layering
- Still trading WITH the overall trend
- Just buying the dip within the trend
- Making higher highs, higher lows

---

## When Things DON'T Work (5+ Boxes)

### Warning Signs
- 4th box has trades
- 5th box from top (but only 2 boxes have money)
- This is a TREND, not a pullback

### Priority Change
> *"When things don't go our way, the priority becomes breaking even."*

### Engineering Exits
- Spend money to lose LESS
- Don't just let it go to stop
- Interfere, average, find break-even

---

## Averaging In and Out

### Luxury of Averaging
> *"By averaging in, we have the luxury of averaging back out."*

### Purpose
- Reduce losses
- Engineer less dramatic loss
- NOT trying to make a million
- Trying to not lose what you started with

---

## Spreading Risk = Winning

### Why 4 Chances Per Box?
> *"Would you not rather have 4 chances to be right per box instead of 1 chance per box?"*

Odds of being right go UP with spread trades.

---

## Key Trading Scenarios for EA

| Scenario | Detection | Action |
|----------|-----------|--------|
| Aligned, bouncing | Each trade profits | Recycle |
| Dip in uptrend | Drawdown building | Layer buys |
| Rally in downtrend | Drawdown building | Layer sells |
| 5 boxes against | Trend reversal | Stop adds, engineer exit |
| 4 boxes with bounce | Normal recovery | Close all at average profit |

---

## EA Logic: Market Conditions

```
// Determine mode
IF last_trade_profitable:
    MODE = RECYCLE
    OPEN_NEW_TRADE_SAME_DIRECTION()
ELSE:
    MODE = LAYER
    IF boxes_used < 4:
        ADD_TRADE_AT_NEXT_LEVEL()
    ELSE:
        ENGINEER_EXIT()

// Trend vs Pullback detection
IF boxes_against > 4:
    TREND_MODE = true
    STOP_ADDING()
    SEEK_BREAKEVEN()
```

---

## Key Quotes

1. *"It's either recycle, recycle, recycle, or exploit drawdown, exploit drawdown, eventually get paid."*

2. *"I'm not trying to make a million dollars, I'm trying to not lose what I started with."*

3. *"It's the spreading of that risk that makes you a winner in the end."*

---

## Action Items for EA

- [ ] Implement recycle mode detection
- [ ] Build layer mode with position tracking
- [ ] Add 5-box trend detection
- [ ] Create break-even seeking algorithm
