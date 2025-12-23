# Session 05: Deciding on the Bias (Top-Down Analysis)

---

## Top-Down Analysis Framework

### The Hierarchy
```
Daily Chart    → Get the IDEA (direction for the day)
Hourly Chart   → Get the PLAN (range and key levels)
5-Minute Chart → Get the ROAD MAP (action points)
1-Minute Chart → EXECUTE (actual trades)
```

> *"The daily is where we get the idea. The hourly is where we get the plan."*

---

## Step 1: Daily Chart Analysis

### What to Look For
- Compare TODAY's candle vs YESTERDAY's closed candle
- Look at structure: Higher highs? Lower lows?
- Check Average Daily Range (ADR)—how much is left?

### Key Questions
1. How much of ADR is already done?
2. Are we bullish (going up) or bearish (going down)?
3. Is this an extension that's about to end?

### Extension Detection
> *"If it's already exceeded the ADR, look for this extension to come to an end. It's not going to the moon."*

Extensions end in **boxes** (standard deviations):
- 1 box beyond ADR = normal
- 2-3 boxes beyond = unusual
- Half box = move ending soon

---

## Step 2: Hourly Chart Analysis

### Define the Range
- Identify most recent HIGH
- Identify current LOW
- This defines your playing field

### Three Scenarios
| Condition | Action |
|-----------|--------|
| Break above HIGH | Bullish continuation |
| Break below LOW | Bearish move |
| Stay inside range | Range trade (bounces) |

---

## Step 3: 5-Minute Chart Analysis

### Create the Road Map
- Highlight past levels that were useful (support/resistance)
- Mark levels as **action points**, not targets or stops
- These are "rungs on a ladder"—price will revisit them

> *"These rungs on the ladder are action points. One way or another, over time, we revisit these."*

### How to Use Road Map
```
Level Hit → Look at 1-min chart
         → Worth attempting 3 pips?
         → Probability says YES at key levels
```

---

## Step 4: 1-Minute Execution

### With Your Box Ready
- Stack boxes from most recent swing
- Wait for price to reach box edge
- Execute based on bias + box alignment

---

## Geographic Time Considerations

### For North American Traders
- Start on DAILY chart (16+ hours of history)
- 2 sessions already complete (Asia + Europe)
- More reference points available

### For European Traders
- Start on 4-HOUR chart instead
- Only Asia session history (8 hours)
- Compare current 4H candle with previous closed one

> *"If you live in Europe, start your top down on the 4-hour chart."*

---

## Alignment Principle

### When Higher + Intermediate Agree
→ **Recycle, recycle, recycle** (easy money)

### When They Disagree
→ **Layering mode** (buying the dip/selling the rally)
→ Postponed gratification
→ Build position, wait for bounce

---

## Building the Wick

### Daily Candle Context
- Near the LOW? Building the bottom wick
- Near the HIGH? Building the top wick
- In the middle? Building the body

> *"Maybe you're coming in near the low of the day and you're going to build a wick on the daily candle."*

---

## Key Bias Parameters for EA

| Element | Usage |
|---------|-------|
| Daily Structure | Determines overall direction |
| ADR Remaining | How much room left for moves |
| Hourly Range | Defines current boundaries |
| 5-Min Levels | Action/decision points |
| 1-Min Box | Execution timing |

---

## EA Logic: Top-Down Bias

```
// Daily bias
IF daily_high > yesterday_high AND daily_low > yesterday_low:
    BIAS = BULLISH
ELSE IF daily_high < yesterday_high AND daily_low < yesterday_low:
    BIAS = BEARISH
ELSE:
    BIAS = RANGING

// ADR check
adr_used = daily_high - daily_low
adr_remaining = average_daily_range - adr_used

IF adr_remaining < 9 pips:
    EXPECT_REVERSAL = true
```

---

## Key Quotes

1. *"Top down, not bottom up. Bottom up is an excuse to stick around a bad trade."*

2. *"By picking the right side, you're simplifying your life for the next couple of hours."*

3. *"I'm only here for 2 hours each day, so I'm not looking very far."*

---

## Action Items for EA

- [ ] Implement daily structure analysis (HH/HL or LH/LL)
- [ ] Add ADR calculation and remaining check
- [ ] Create hourly range boundary detection
- [ ] Build 5-min support/resistance level mapper
