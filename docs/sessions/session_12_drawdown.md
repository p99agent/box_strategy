# Session 12: Drawdown Management at End of Session

---

## The Four Ways to Handle Risk

### When Already In a Trade
1. **Transfer Risk** → Hedge (opposite trades)
2. **Reduce Risk** → Close worst losers first
3. **Accept Risk** → Leave trades as-is (preferred)
4. **Avoid Risk** → Don't overtrade in first place

---

## Option 1: Transfer Risk (Hedging)

### How It Works
- Open equal opposite position
- Net exposure = 0
- Risk "frozen" temporarily

### Example
```
Current: Long 0.60 lots, in drawdown
Action: Open Short 0.55 lots
Result: Net exposure = 0.05 long (almost flat)
```

### Unwinding the Hedge
> *"The only way to unwind the hedge is to start removing losing trades."*

1. Remove worst losers from one side
2. Add small winners to other side
3. Gradually reduce net exposure
4. Eventually go flat

### Warning
> *"Hedging kind of opens the can of worms to both sides. Now you have 2 cans of worms."*

---

## Option 2: Reduce Risk

### Priority Order
1. Close WORST losers first
2. Leave better positions with hope
3. Book small loss now
4. Let remaining trades recover

### Why Worst First?
The worst losers are most likely to get worse.
Better positions have better chance of recovery.

---

## Option 3: Accept Risk (Preferred)

### The Original Agreement
> *"I agreed to the stop loss when I took the trade."*

When you entered:
- Accepted 36-pip stop
- Accepted 3-pip target
- Made a commitment

### Why Accept?
- Don't make false moves
- Don't make another false move to fix first
- Trust the statistics
- Trust the box measurements

---

## Option 4: Avoid in First Place

### Prevention > Cure
- Track time remaining
- Know when session ends
- Don't push to the limit
- Walk away after meeting goal

---

## Risk as a Speedometer

### Reading the Market
The box is like a speedometer/odometer in your car:
- Shows how much moved
- Shows how much further likely to go
- Helps anticipate next move

> *"By measuring where you're coming from, you can see the end of the move potentially."*

---

## Session Transition Considerations

### European to US Transition
| Factor | European Session | US Session |
|--------|------------------|------------|
| Volatility | High (their currency) | Decreasing |
| Direction | Often trending | Mean reversion |
| ADR | Being fulfilled | Near complete |
| Risk | Increasing | Decreasing |

### US Trader Perspective
> *"European traders are heading out. The risk is heading out the door."*

---

## Overnight Trade Decisions

### Before Leaving
1. Check current drawdown (how many boxes?)
2. Check structure (still valid?)
3. Check overnight events (news calendar)
4. Decide: hold, reduce, or close

### Hold If:
- Drawdown < 2 boxes
- Structure unchanged
- No major overnight news

### Reduce/Close If:
- Drawdown > 2 boxes
- Structure broken
- High-impact news overnight

---

## Progressive Problem Awareness

### Losses Build Gradually
> *"A 4% loss is a progressive problem. It's not something that will just happen."*

```
Box 1: Small issue → Can stop here
Box 2: Growing → Can stop here
Box 3: Getting serious → Can stop here
Box 4: At limit → MUST stop here
Box 5: Disaster → Too late
```

### Many Chances to Stop
Each click has its own stop loss.
You don't lose all clicks at once.
Close what you need, keep engineering.

---

## Real Example: Nick C's Recovery

### The Strategy
From Slack daily accountability:
1. Reduced risk overnight
2. Bought himself extra boxes
3. Came out at break-even
4. Instead of full loss

### The Principle
> *"Willingness to spend a little bit to save a lot."*

---

## Box 5 = Ejection Required

### The Rule
> *"If we go into box number 5, going into box number 5 would have cost us trades from box number 1."*

At box 5:
- Model is failing
- Trend has taken over
- Exit immediately
- Don't hope for recovery

---

## EA Logic: End of Session

```
// End of session check
IF session_ended:
    current_drawdown = calculate_drawdown()
    
    IF current_drawdown == 0:
        // All good, no action needed
        CLOSE_SESSION()
        
    ELSE IF current_drawdown <= 18 pips:  // 2 boxes
        // Acceptable, hold trades
        HOLD_TRADES()
        SET_OVERNIGHT_ALERTS()
        
    ELSE IF current_drawdown <= 27 pips:  // 3 boxes
        // Getting risky
        IF overnight_high_impact_news:
            CLOSE_WORST_TRADES()
        ELSE:
            HOLD_WITH_CAUTION()
            
    ELSE:  // 4+ boxes
        // Too risky for overnight
        REDUCE_POSITION_SIZE()
        OR CLOSE_ALL()
```

---

## Key Quotes

1. *"The box does not change in height, even on higher time frames."*

2. *"Understanding the next move is where our salvation is."*

3. *"Abnormal would have been going into box number 5. That would have cost us trades from box number 1."*

---

## Action Items for EA

- [ ] Implement end-of-session handler
- [ ] Add drawdown-based decision logic
- [ ] Create overnight news detection
- [ ] Build hedge/unhedge functionality
- [ ] Add gradual position reduction
