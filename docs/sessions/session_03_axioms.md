# Session 03: Axioms of Trading

---

## The Three Core Axioms

### Axiom 1: Support/Resistance Confirmation
> *"If testing for support, you know you've found support when price moves up."*

| Test For | Confirmed When | Result |
|----------|----------------|--------|
| Support | Price bounces UP | Take profit |
| Resistance | Price bounces DOWN | Take profit |
| Neither | Price continues through | Move to Axiom 2 |

**Key Insight**: Testing is done ONE BAR at a time on the 1-minute chart. One bounce bar = enough to make 3 pips.

---

### Axiom 2: Trend Initiation
> *"A trend will start with the failure of support or resistance."*

| Failed | Result |
|--------|--------|
| Support fails | Bearish trend starting |
| Resistance fails | Bullish trend starting |

**Implication**: When testing for bounce and it doesn't work → you're now in a trend.

---

### Axiom 3: Momentum Measurement
> *"The distance between pivots is the best way to measure momentum."*

| Pivot Spacing | Signal |
|---------------|--------|
| Large → Medium → Small | Reversal coming |
| Small → Medium → Large | Trend accelerating |
| Consistent | Trend continuing |

**Forward-Looking**: Momentum is a PREDICTOR of future moves.

---

## Box Origin: Where Does It Come From?

### Critical Principle
> *"The box comes from the market. It's not something we create or imagined—it's something we MEASURE."*

### Measurement Requirements
- Measure during YOUR business hours
- Use the SAME time window each day
- Look at YESTERDAY's price action for reference

---

## Box Measurement Process (Step-by-Step)

### 1. Choose Your Time Window
```
Example: 8:00 AM - 10:00 AM (your 2-hour session)
Look at yesterday's chart from 8:00 - 10:00
```

### 2. Measure Swings on 5-Minute Chart
For each swing, record:
- **Pips** (height of move)
- **Bars** (duration of move)

### 3. Sample Measurements
```
Swing 1: 25 pips, 4 bars
Swing 2: 50 pips, 6 bars
Swing 3: 50 pips, 6 bars
Swing 4: 25 pips, 4 bars
```

### 4. Calculate Averages
```
Total Pips: 25 + 50 + 50 + 25 = 150
Average Pips: 150 / 4 = 37.5 pips

Total Bars: 4 + 6 + 6 + 4 = 20
Average Bars: 20 / 4 = 5 bars (on 5-min chart)
```

### 5. Derive Standard Deviation
```
3 Standard Deviations = 37.5 pips (the full move)
1 Standard Deviation = 37.5 / 3 = 12.5 pips → Round to 12 pips
Add margin of error: 12 + 1 = ~9 pips (in practice)
```

---

## Box as Standard Deviation

The box represents **1 standard deviation** of the market's normal distribution.

| Standard Deviations | Coverage | Box Strategy Meaning |
|---------------------|----------|----------------------|
| 1 SD (1 box) | ~68% | Normal trading zone |
| 2 SD (2 boxes) | ~95% | Extended move |
| 3 SD (3 boxes) | ~99% | Near extreme |
| 4 SD (4 boxes) | ~99.7% | Maximum allowed |

---

## Using the Box in Real-Time

### Scenario Planning

| Scenario | What Happens | Action |
|----------|--------------|--------|
| **Scenario 1** | Bounce before box complete | Take 3 pips, move box |
| **Scenario 2** | Price fills exact box (68%) | Take 3 pips at edge |
| **Scenario 3** | Price gives half box | Reset box on new swing |
| **Scenario 4** | Price breaks box | Stack next box, try again |

### The 4-Attempt Rule
> *"I can only do this for 4 attempts. I'm not made of money."*

```
Attempt 1: Buy bar 7 (test support)
If fails → Attempt 2: Buy bar 8 (2 open trades, new box)
If fails → Attempt 3: Buy bar 9 (3 open trades)
If fails → Attempt 4: Buy bar 10 (4 open trades)
IF ALL FAIL → STOP. No more trades.
```

---

## Time-Price Exchange Principle

> *"If I'm not using the time, I will receive price."*

| Used | Unused | Result |
|------|--------|--------|
| All time, half price | No extra time | Smaller move, reset box |
| Half time, full price | Time remaining | Larger move, stack box |
| Exact time, exact price | Perfect 68% | Average move |

---

## Key EA Parameters from Session 3

| Parameter | Value | Source |
|-----------|-------|--------|
| Box Height | 9 pips (1 SD) | Derived from measurement |
| Box Duration | 60 bars (1-min) | 12 bars × 5 (5-min to 1-min) |
| Max Attempts | 4 per direction | Session 03 |
| Goal per Trade | 1 bar of profit | Session 03 |
| Target | 3 pips | Session 03 |

---

## EA Logic: Axiom Implementation

```
// Axiom 1: Test for Support
IF price_at_box_bottom AND bias == BULLISH:
    OPEN_BUY()
    IF next_bar_is_green:
        CLOSE_AT_3_PIPS (support confirmed)
    ELSE:
        HOLD (move to repair mode)

// Axiom 2: Trend Detection  
IF support_failed_4_times:
    TREND_DETECTED = true
    STOP_ADDING_BUYS()
    
// Axiom 3: Momentum Check
IF pivot_spacing_decreasing:
    REVERSAL_LIKELY = true
    PREPARE_FOR_OPPOSITE_DIRECTION()
```

---

## Key Quotes

1. *"The box itself is only a frame. It lets me see what the market is capable of."*

2. *"One bounce, one little bar, is enough to make me money."*

3. *"I aim for one bar of profit, then I repeat and repeat and repeat."*

---

## Action Items for EA Development

- [ ] Implement box calculation from historical swing data
- [ ] Build 4-attempt limit per direction
- [ ] Create bounce detection (green after red = support confirmed)
- [ ] Add pivot spacing momentum indicator
- [ ] Implement time-price exchange logic
