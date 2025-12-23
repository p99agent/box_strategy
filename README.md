# Box Strategy EA Project

A MetaTrader 5 Expert Advisor implementation based on Jean Francois Bouchet's Box Strategy scalping methodology.

## 📁 Project Structure

```
final-p99/
├── docs/
│   ├── sessions/            # Individual session summaries  
│   ├── extracted/           # Extracted trading rules
│   └── STRATEGY_BIBLE.md    # Single source of truth
├── simulations/
│   ├── data/                # Historical price data
│   ├── results/             # Backtest results
│   └── *.py                 # Python simulation scripts
├── metatrader/
│   ├── EA/                  # Expert Advisors (.mq5)
│   ├── Indicators/          # Custom indicators
│   ├── Libraries/           # Shared libraries
│   └── Include/             # Header files (.mqh)
├── box_strategy.md          # Original course transcripts
└── README.md                # This file
```

## 📊 Strategy Overview

The Box Strategy is a probability-based scalping approach that:
- Uses **standard deviation** to define tradeable zones (boxes)
- Targets **3-pip profits** with >95% win rate
- Limits risk to **4% maximum** (4 boxes × 1% each)
- Operates within **2-hour trading windows**

## 🎯 Key Parameters

| Parameter | Value |
|-----------|-------|
| Box Size | 9 pips |
| Max Loss | 36 pips |
| Target | 3 pips |
| Risk/Box | 1% |
| Max Risk | 4% |
| Time Frame | 1-minute |
| Session | 10:00-12:00 ET |

## 🚀 Getting Started

### Prerequisites
- MetaTrader 5
- Python 3.x (for simulations)
- Historical forex data

### Installation
1. Copy `metatrader/EA/*.mq5` to your MT5 Experts folder
2. Copy `metatrader/Include/*.mqh` to your MT5 Include folder
3. Compile in MetaEditor
4. Attach to EURUSD M1 chart

## 📚 Documentation

- **[STRATEGY_BIBLE.md](docs/STRATEGY_BIBLE.md)** - Complete trading rules
- **[box_strategy.md](box_strategy.md)** - Original course transcripts

## ⚠️ Disclaimer

This EA is for educational purposes. Trade at your own risk. Past performance does not guarantee future results.
