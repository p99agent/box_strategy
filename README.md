# Box Strategy EA Project

[![Version](https://img.shields.io/badge/EA%20Version-1.3-blue)](metatrader/EA/BoxStrategyEA.mq5)
[![Spec](https://img.shields.io/badge/Spec-v1.6%20FINAL-green)](docs/EA_SPECIFICATION.md)
[![Status](https://img.shields.io/badge/Status-Phase%201%20Complete-success)](docs/EA_SPECIFICATION.md)

A MetaTrader 5 Expert Advisor implementation based on Jean Francois Bouchet's Box Strategy scalping methodology.

---

## 📊 Project Status

### ✅ Completed

| Phase | Description | Status |
|-------|-------------|--------|
| **Phase 1** | Knowledge Extraction | ✅ Complete |
| **Phase 2** | EA Specification | ✅ v1.6 FINAL |
| **Phase 3** | Core EA Development | ✅ v1.3 Released |

### 🚧 In Progress

| Item | Description | Priority |
|------|-------------|----------|
| Dynamic Box Calculation | Calculate boxes from historical session data | Phase 2 |
| Break-even Logic (SPEC-010) | Move SL to break-even after first win | Phase 2 |
| Bias Detection (SPEC-009) | Top-down analysis for trade direction | Phase 2 |

### 📋 Pending (Phase 2+)

- SPEC-011: Trade Repair Mode (layering)
- SPEC-012: News Time Filter
- SPEC-013: Visual Box Indicator (enhanced)
- SPEC-014: Statistics Dashboard
- SPEC-015: FIFO Compliance Mode
- SPEC-016: Multi-Pair Expansion
- SPEC-017: Swing Trade Mode

---

## 🎯 EA Features (v1.3)

### Core Trading Logic
- ✅ **Session Filter**: Trades only during 10:00-12:00 ET (configurable timezone)
- ✅ **Box Edge Entry**: Buys at box bottom, sells at box top
- ✅ **Position Sizing**: 0.25% risk per click (16 clicks max = 4% daily risk)
- ✅ **TP/SL**: 3 pips target, 36 pips max stop (ejection)

### Risk Management
- ✅ **4 Boxes × 4 Clicks**: Maximum 16 positions per session
- ✅ **Box Level Tracking**: Drawdown-based box progression
- ✅ **Ejection System**: Auto-close all at Box 5 (36+ pips drawdown)

### v1.3 Features
- ✅ **RECYCLE Mode**: Reset clicks when positions close profitably
- ✅ **SESSION Mode**: Fixed 16 clicks/day (conservative)
- ✅ **Entry Throttle**: 1 trade per M1 bar (prevents rapid-fire)
- ✅ **Box Visualization**: Rectangle + edge lines on chart
- ✅ **State Persistence**: Survives EA/MT5 restarts

---

## 📁 Project Structure

```
final-p99/
├── docs/
│   ├── sessions/              # 18 individual session summaries
│   ├── EA_SPECIFICATION.md    # Feature specs (17 specs, v1.6)
│   ├── STRATEGY_BIBLE.md      # Single source of truth
│   └── REVIEW_LOG.md          # ChatGPT 5.2 review history
├── metatrader/
│   └── EA/
│       └── BoxStrategyEA.mq5  # Main EA (v1.3, 1018 lines)
├── box_strategy.md            # Original course transcripts
└── README.md                  # This file
```

---

## 🚀 Quick Start

### Prerequisites
- MetaTrader 5 (FTMO or any broker)
- EUR/USD M1 chart

### Installation
```bash
# Copy EA to MT5 Experts folder
cp metatrader/EA/BoxStrategyEA.mq5 [MT5 Data Folder]/MQL5/Experts/
```

### Configuration
| Parameter | Default | Description |
|-----------|---------|-------------|
| `BrokerGMTOffset` | 2 | Broker server timezone (FTMO: 2 winter, 3 summer) |
| `TargetGMTOffset` | -5 | Target timezone (Eastern: -5 winter, -4 summer) |
| `RiskPercent` | 0.25 | Risk per click (%) |
| `ClickMode` | RECYCLE | SESSION (fixed 16/day) or RECYCLE (reset when flat+profit) |
| `StrictMVP` | true | Block trading on non-EURUSD |

### Before First Run
1. Clear Global Variables: **Tools → Global Variables (F3)** → Delete `BoxEA_*`
2. Compile in MetaEditor (F7)
3. Attach to EUR/USD M1 chart
4. Enable Algo Trading (button in toolbar)

---

## 🎓 Strategy Overview

The Box Strategy is a probability-based scalping approach that:
- Uses **standard deviation** to define tradeable zones (boxes)
- Targets **3-pip profits** with ~85% win rate
- Limits risk to **4% maximum** (4 boxes × 4 clicks × 0.25%)
- Operates within **2-hour trading sessions**

### Key Parameters

| Parameter | Value | Source |
|-----------|-------|--------|
| Box Size | 9 pips | Calculated for EUR/USD |
| Box Duration | 60 M1 bars | 1 hour |
| Take Profit | 3 pips | Average M1 bar size |
| Max Stop | 36 pips | 4 standard deviations |
| Risk/Click | 0.25% | 16 clicks = 4% max |
| Session | 10:00-12:00 ET | Optimal EUR/USD volatility |

---

## 📚 Documentation

| Document | Purpose |
|----------|---------|
| [EA_SPECIFICATION.md](docs/EA_SPECIFICATION.md) | Feature specs with code snippets |
| [STRATEGY_BIBLE.md](docs/STRATEGY_BIBLE.md) | Complete trading rules |
| [REVIEW_LOG.md](docs/REVIEW_LOG.md) | Review history and fixes |
| [box_strategy.md](box_strategy.md) | Original course transcripts |

---

## 📈 Test Results (Smoke Test)

| Test | Date | Result |
|------|------|--------|
| Session Filter | 2023-12-23 | ✅ Trades during 17:00-19:00 broker time |
| Lot Sizing | 2023-12-23 | ✅ 0.69 lots on $100k account |
| Click Limits | 2023-12-23 | ✅ Stops at 4 trades in Box 1 |
| Entry Throttle | 2023-12-23 | ✅ 1 trade per bar (~1 min spacing) |
| Box Visualization | 2023-12-23 | ✅ Rectangle + edge lines visible |

---

## 🔄 Version History

| Version | Date | Changes |
|---------|------|---------|
| v1.0 | 2023-12-23 | Initial Phase 1 MVP |
| v1.1 | 2023-12-23 | Fixed drawdown math, box edge entry, persistence |
| v1.2 | 2023-12-23 | Added throttle, log rate limit, box visualization |
| v1.3 | 2023-12-23 | Added RECYCLE mode for click budget recycling |

---

## ⚠️ Disclaimer

This EA is for **educational purposes only**. 

- Trade at your own risk
- Past performance does not guarantee future results
- Test thoroughly on demo before live trading
- The authors are not responsible for any financial losses

---

## 📄 License

This project is for personal educational use.
