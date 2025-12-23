# Session 10: Special Days / News Trading

---

## Core Principle: Avoid Trading the News

### What NOT to Do
- Trade INTO news events
- Forecast news outcomes
- Position for expected moves

### What TO Do
- Stand aside before news
- Let the move happen
- Trade AFTER the dust settles

> *"We don't plan for it, we don't schedule it, we don't forecast the outcome."*

---

## News Event Types

### High Impact Events to Avoid
| Event | Typical Impact |
|-------|----------------|
| NFP (Non-Farm Payrolls) | 50-100+ pips |
| FOMC (Fed Rate Decision) | 50-100+ pips |
| CPI (Inflation Data) | 30-80 pips |
| GDP | 30-50 pips |

### The Calendar Advantage
> *"You can plan your trades with the calendar a year in advance."*

---

## The "Ambulance Chaser" Approach

### Mindset
You're not the first responder. You're the cleanup crew.

> *"Think of yourself as an ambulance chaser, and we're just here to clean up the mess."*

### Process
1. News releases at 8:30 ET
2. Market spikes 50-100 pips
3. Move settles after 5-30 minutes
4. THEN you start trading

---

## Optimal Entry Timing

### Wait for Settlement
```
News Event     → STAND ASIDE
Spike occurs   → STAND ASIDE  
Price settles  → BEGIN TRADING
```

### Practical Example (from transcript)
> *"The market fell 36 pips and it stopped. Here we are trading when it stopped falling. We did not trade the fall."*

---

## Why 10:00 AM Start Time

### Events Before 10:00 ET
| Time | Event | Risk |
|------|-------|------|
| 8:30 | Major news releases | HIGH |
| 9:30 | Stock market opens | HIGH |
| 10:00 | Options expiry | Wait complete |
| 10:01+ | Post-event calm | TRADE NOW |

> *"This is why we begin trading at the top of the hour, 10 o'clock Eastern."*

---

## Handling Open Trades During News

### Options Available

| Option | Description | When to Use |
|--------|-------------|-------------|
| Tighten stops | Move from 36 to 18 pips | Moderate news |
| Close trades | Book current P/L | Major news |
| Do nothing | Let it ride | Minor news |

### Personal Preference (Instructor)
> *"I tend to close my eyes and hope for the best. Odds are, it will fit within my standard deviations."*

---

## Post-News Trading Pattern

### Normal Size Returns
After the spike:
- Bars return to normal size
- Expectations normalize
- Standard box applies again

> *"By the time we came to the computer, the news kind of settled. It's no longer these big crazy bars. We're back to normal size bars with normal expectations."*

---

## Patience and Control

### Key Insight
> *"In reality, you have a lot more control than you think."*

### Why You're Not Missing Out
- With 16 clicks available, you can't miss
- News creates opportunities AFTER
- Post-news trends are tradeable

---

## News Event EA Parameters

| Parameter | Value |
|-----------|-------|
| Pre-news blackout | 30 minutes before |
| Post-news wait | 5 minutes minimum |
| Spike detection | >20 pips in 1 bar |
| Resume trading | When bar size normalizes |

---

## EA Logic: News Filter

```
// News time check (example for major US news)
news_times = [8:30, 10:00, 14:00]  // ET

current_time = get_current_time()

for each news_time in news_times:
    IF current_time > (news_time - 30min) AND current_time < (news_time + 5min):
        TRADING_ALLOWED = false
        REASON = "News blackout period"
        
// Spike detection
IF last_bar_range > 20 pips:
    TRADING_ALLOWED = false
    WAIT_FOR_NORMAL_BARS()
```

---

## Key Quotes

1. *"We wait for the news, NFP, FOMC. We don't plan for it, we don't forecast the outcome."*

2. *"Wait for the price to come to your level, wait for that support."*

3. *"We prefer stuff that's sideways, stuff that's measured, predictable."*

---

## Action Items for EA

- [ ] Implement news time blackout filter
- [ ] Add spike detection algorithm
- [ ] Create "return to normal" detector
- [ ] Build configurable news time inputs
