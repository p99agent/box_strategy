# Session 02: Assumptions and Basics

---

## Scalping vs Swing Trading Definition

| Aspect | Scalping (Box Strategy) | Swing Trading |
|--------|-------------------------|---------------|
| **Target** | Small slice of price | Meat of the move |
| **Position** | Edges of range | Middle of move |
| **Focus** | Bounces within range | Breakouts beyond range |
| **Income** | Consistent, behavioral | Risk:Reward ratio |

> *"The scalp is just a tiny tiny piece where the swing is the meat of the move."*

---

## Potential Average Yield (PAY) Concept

**Definition**: Your expected daily income based on:
1. Time frame traded
2. Time of day traded  
3. Average result per day

### Time Frame Impact on PAY

| Time Frame | Typical Yield | Risk |
|------------|---------------|------|
| 1-minute | Smaller per trade, more trades | Easier to manage losses |
| 1-hour | Larger per trade, fewer trades | Larger losses |
| Daily | Largest per trade, few trades | Biggest losses |

> *"Trade on the time frame that you can manage the losses within."*

---

## Trading as a Business

### Key Business Principles

1. **Schedule**: Fixed business hours (2-hour window)
2. **Close doors daily**: Leave the "casino" every day
3. **Match time to money**: Time for money, money for time
4. **Compare apples to apples**: Same time, same conditions daily

### Why the 1-Minute Chart?

- Smallest affordable losses
- Cheapest to lose (10-15 pips manageable)
- Most opportunities for consistent income
- Seeking **repetition and behavior**, not big payouts

---

## Market Schedule Awareness

### Professional Traders Operate on Schedule

| Time (Eastern) | Event | Strategy Response |
|----------------|-------|-------------------|
| 8:30 | Major news releases | STAND ASIDE |
| 9:30 | Stock market opens | STAND ASIDE |
| 10:00 | Options expiry (FX/equity) | START TRADING |
| 10:00-12:00 | Bull/Bear pullbacks | TRADE |
| After 12:00 | Lunch hour volatility drop | STOP TRADING |

> *"The calendar is known by everyone one year in advance and so the risk is known one year in advance."*

### Session Behavior Patterns (Repeat 3x Daily)

```
Asian Session    → Same cycle
European Session → Same cycle  
US Session       → Same cycle
```

Each session has:
- News event risk
- Stock market opening
- Options expiry
- Bull/bear pullback patterns

---

## Plan A and Plan B Mentality

### Always Think Ahead

| Current State | Plan A | Plan B |
|---------------|--------|--------|
| In profit zone | Make 3 pips | What if it reverses? |
| In drawdown | Find bounce | Add more trades |
| At box edge | Expect bounce | Prepare for break |

> *"While I'm trying to make money, my mind is always on the lookout for Plan B."*

---

## Trade Spreading Philosophy

### Instead of One Trade → Many Small Trades

| Traditional | Box Strategy |
|-------------|--------------|
| 1 trade, hope for best | Same risk, broken into pieces |
| 1 probability | Many probabilities |
| All-or-nothing | Spread outcomes |

> *"I'm taking the same amount of risk but I will break it up and spread it."*

---

## Key Time Parameters for EA

| Parameter | Value | Source |
|-----------|-------|--------|
| Trading Window | 2 hours | Session 02 |
| Start Time (US) | 10:00 Eastern | Session 02 |
| End Time (US) | 12:00 Eastern | Session 02 |
| Avoid Before | 10:00 Eastern | Session 02 |
| Wait After News | 5 minutes | Session 02 |

---

## Extracted EA Logic

```
// Session timing logic
IF current_time < 10:00 Eastern THEN
    DO NOT TRADE (pre-market risk)
    
IF current_time >= 10:00 AND current_time <= 12:00 THEN
    TRADING ALLOWED
    
IF current_time > 12:00 THEN
    STOP TRADING (session end)
    
// After news event
IF news_event_detected THEN
    WAIT 5 minutes
    THEN resume trading
```

---

## Key Quotes

1. *"I don't trade on my lunch hour. I'm trading as a business with business acumen and business hours."*

2. *"Instead of getting surprised by volatility, I see it coming."*

3. *"We wait for the event risk and trade after the event risk."*

---

## Action Items for EA Development

- [ ] Implement trading session filter (10:00-12:00 ET)
- [ ] Add news event detection and wait period
- [ ] Build position spreading logic (break 1% into 4 x 0.25%)
- [ ] Create Plan A/B decision framework
