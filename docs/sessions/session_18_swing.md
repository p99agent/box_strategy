# Session 18: Mastering Swing Trading with Price and Time Cycles

---

## Swing Trading with Boxes

### Extended Time Frame Application
- Same box calculation method
- Larger standard deviations
- Longer holding periods

### Box Scaling
| Time Frame | Typical 1 SD | 4 SD Stop |
|------------|--------------|-----------|
| 1-minute | 9 pips | 36 pips |
| 1-hour | 18 pips | 72 pips |
| 4-hour | 36 pips | 144 pips |
| Daily | 60+ pips | 240+ pips |

---

## Time Cycles for Swing Trades

### Identifying Cycles
1. Count bars between pivots on chosen time frame
2. Average the count
3. Divide by 3 for 1 standard deviation
4. Expect move to complete in that many bars

### Example: 4-Hour Chart
```
Average swing: 6 bars (24 hours)
1 SD duration: 2 bars (8 hours)
Full move: 6 bars (24 hours)
```

---

## Combining Scalp and Swing

### The Dual Approach
| Strategy | Role | Frequency |
|----------|------|-----------|
| 3-pip scalps | Consistent income | Daily |
| Swing trades | Boost returns | Weekly/monthly |

> *"This is the burger and this is the soft drink. McDonald's makes their money on soft drinks."*

---

## Swing Trade Entry Criteria

### Using Box Levels
1. Wait for price at box edge
2. Confirm with daily/4H bias
3. Enter with 4 SD stop
4. Target 3-4 boxes profit

### Risk Management
- Still 1% risk per box
- Larger pip stop = smaller position
- Same percentage exposure

---

## Time-Price Exchange on Higher TFs

### Faster Than Expected
- Price reaches level in fewer bars
- Expect larger move
- More standard deviations likely

### Slower Than Expected
- Price uses all time, less distance
- Move running out of steam
- Reversal more likely

---

## Ichimoku and Camarilla Integration

### Ichimoku for Bias
- Cloud direction = trend
- Price vs cloud = long/short bias
- Senkou spans = future support/resistance

### Camarilla for Levels
- Pivot-based S/R levels
- Intraday action points
- Combine with box edges

---

## Key Parameters for Swing EA

| Parameter | 4-Hour Chart | Daily Chart |
|-----------|--------------|-------------|
| Box measurement | 20 swings | 20 swings |
| Typical 1 SD | 36 pips | 60 pips |
| Max stop | 144 pips | 240 pips |
| Hold time | 1-3 days | 5-10 days |
| Position size | Smaller | Smaller |

---

## Psychology of Longer Holds

### Challenges
- More time for doubt
- More price volatility visible
- Harder to stay patient

### Solutions
- Set alerts, don't watch constantly
- Trust the box calculations
- Review only at key times

---

## Key Quotes

1. *"By counting standard deviations, if I'm risking 4 SD from my stop, it makes sense to expect at least 4 SD for reward."*

2. *"On a 4 hour chart, one box might take a day, maybe 2 days to get across."*

---

## Action Items for Swing EA

- [ ] Add multi-time-frame box calculation
- [ ] Create 4-hour and daily bias detection
- [ ] Build larger position sizing calculator
- [ ] Add optional swing trade mode
