# Session 14: Alternative Time Frames and Instruments

---

## Extending the Box to Other Instruments

### Core Principle
> *"You can pick any pair at any moment, figure out a quick dirty box, and trade that box."*

### Sample Size Requirement
- 20 days of data minimum
- Covers one month of events
- Includes FOMC, CPI, PPI, etc.
- Large enough to be reliable

---

## Correlation Awareness

### Why Correlations Matter
If trading multiple pairs:
- EUR/USD + GBP/USD = Both anti-USD
- If USD moves, BOTH positions hit
- Risk multiplies unknowingly

### The Correlation Matrix
Use tools like myfxbook.com correlation:
- 96% correlated = basically same trade
- 0% correlated = independent
- -96% correlated = opposite trades

> *"Correlation will be your downfall if you start adding things to your portfolio."*

---

## Currency Funding Impact

### Same Setup, Different Currency
| Funding | Allowed Lots | Clicks |
|---------|--------------|--------|
| GBP | 9 lots | 16+ |
| AUD | 4 lots | ~8 |
| CAD | 4.8 lots | ~9 |

> *"Same account, same criteria, same everything, but different funding."*

### Solution
Fund accounts in USD to standardize calculations.

---

## Multiple Pair Experiment Results

### Test 1: 27 Pairs
- Ran for years
- Found some pairs much better than others
- Many stragglers cost thousands

### Test 2: 16 Pairs (removed correlated)
- Better consistency
- Still had issues

### Test 3: 8-9 Pairs (majors only)
- Best results
- Led back to just EUR/USD

> *"I spent 2 years trying to figure out what pair would be more beneficial, only to find out the euro is good enough."*

---

## Time Frame Considerations

### Volatility by Session
| Session | Volatility Pattern |
|---------|-------------------|
| Asia Start | Low, increasing |
| Asia End | Steady |
| Europe Start | High, trending |
| Europe End | Decreasing |
| US Start | Moderate |
| US Mid | Decreasing |

### Match Your Style
- Increasing volatility → Breakout trading
- Decreasing volatility → Range trading
- Pick when you show up

---

## Box Scaling to Higher Time Frames

### 4-Hour Chart Example
- 1 box might = 36 pips
- 1 box might take 1-2 days
- Same axioms apply
- Different psychology required

> *"The box does work on the NASDAQ. The box does work on all other markets. There's a box for everything."*

---

## Unique Time Frames

### The 2-Hour Chart Advantage
> *"Very few traders even bother looking at the 2 hour chart."*

- Between 1-hour and 4-hour
- Step in front of 4-hour close
- See support/resistance before others

---

## Position Sizing Across Instruments

### The 0.25% Adjustment
For different instruments with different box sizes:

| Instrument | 1 SD Box | 4 SD Stop | Adjustment |
|------------|----------|-----------|------------|
| EUR/USD | 9 pips | 36 pips | Standard |
| USD/JPY | 12 pips | 48 pips | Fewer clicks |
| GBP/USD | 15 pips | 60 pips | Even fewer |

> *"The 0.25% per trade will change depending on your funding, size of account."*

---

## Key Parameters for Multi-Instrument EA

| Parameter | Consideration |
|-----------|---------------|
| Sample size | 20 days minimum |
| Correlation | Check before adding pairs |
| Funding | Standardize to USD if possible |
| Box size | Calculate per instrument |
| Position size | Adjust for different stops |

---

## Key Quotes

1. *"If you're trying to be a discretionary trader, one instrument is all you need."*

2. *"Don't be afraid to experiment. Feel free to give it the 4 boxes that it requires mathematically."*

3. *"Think in standard deviations, and think in bars."*

---

## Action Items for Multi-Instrument EA

- [ ] Build correlation checking module
- [ ] Create per-instrument box calculator
- [ ] Add funding currency adjustment
- [ ] Implement session volatility filter
- [ ] Allow custom time frame boxes
