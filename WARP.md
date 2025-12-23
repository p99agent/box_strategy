# WARP.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.

## What this repo is
This repo contains a **MetaTrader 5 (MT5) Expert Advisor** implementing Jean Francois Bouchet’s “Box Strategy” scalping approach.

The code is intentionally “spec-driven”: the primary EA file is annotated with `SPEC-00x` markers that map back to `docs/EA_SPECIFICATION.md`.

## Key files (start here)
- `README.md`: project status, quick-start, parameters, and current scope.
- `metatrader/EA/BoxStrategyEA.mq5`: the EA implementation (v1.3 in-code `#property version "1.30"`).
- `docs/EA_SPECIFICATION.md`: technical spec (v1.6), priorities, and phase/backlog items.
- `docs/STRATEGY_BIBLE.md`: “single source of truth” for trading rules and rationale.
- `docs/REVIEW_LOG.md`: history of spec review fixes (timezone wrap-around, pip sizing helper, volume step rounding, etc.).

Notes:
- `docs/sessions/` are the extracted mentorship session summaries referenced by the spec.
- `box_strategy.md` is a consolidated transcript dump. It references a regeneration script + transcript paths that are **not present in this repo**, so treat it as static source material unless those inputs are reintroduced.

## Common workflows (build/run/test)
### Build / compile (MT5)
There is no repo-local CLI build; compilation is done via **MetaEditor**:
1. Copy `metatrader/EA/BoxStrategyEA.mq5` into your MT5 data folder’s `MQL5/Experts/` directory.
2. Open the file in MetaEditor and compile (F7).
3. Attach the EA to an **EURUSD M1** chart (the MVP is hardcoded for EURUSD unless `InpStrictMVP=false`).

### Reset state between runs
The EA persists state via **MT5 Global Variables** (keys like `BoxEA_*`). If behavior seems “stuck” (clicks already consumed, ejection latched, etc.), clear those globals in MT5:
- MT5: Tools → Global Variables (F3) → delete `BoxEA_*` entries.

### “Run a single test” (manual backtest)
There is no automated unit test suite in this repo. The typical “single test” is an MT5 Strategy Tester run:
1. Open MT5 Strategy Tester.
2. Select the EA, `EURUSD`, timeframe `M1`.
3. Run a short date range and verify:
   - trades only open during the configured session window (`IsInSession()`),
   - click limits are enforced (4 per box / 16 total),
   - throttle behavior: at most 1 trade per M1 bar.

### Helpful PowerShell snippets (optional)
Copy the EA into an MT5 Experts folder (replace the destination with your MT5 Data Folder path from MT5: File → Open Data Folder):
```powershell
Copy-Item -Force .\metatrader\EA\BoxStrategyEA.mq5 "{{MT5_DATA_FOLDER}}\MQL5\Experts\BoxStrategyEA.mq5"
```

## High-level architecture (EA)
### Event-driven lifecycle
All runtime behavior is inside `metatrader/EA/BoxStrategyEA.mq5`:
- `OnInit()`: validates symbol/timeframe, configures `CTrade`, loads persisted state, initializes box edges.
- `OnTick()`: orchestrates session reset, campaign tracking, box level/ejection logic, box-edge updates, and entry execution.
- `OnDeinit()`: persists state and removes chart objects.
- `OnTradeTransaction()`: updates simple win/loss stats when deals close.

### Core state model
The EA tracks three main “layers” of state:
1. **Session state** (daily): click budget (`g_sessionClicksUsed`), session start equity, and whether trading is enabled.
2. **Campaign state** (open positions): direction (+1/-1), weighted-average entry, total lots. This drives drawdown-in-pips.
3. **Box state**: current box level derived from drawdown (Box 1–4; Box 5 triggers “ejection”).

Persistence is via MT5 Global Variables (see `GV_*` constants); this is why clearing `BoxEA_*` matters during debugging.

### Entry/exit flow (current MVP behavior)
- **Session filter**: `IsInSession()` gates entries using broker/target GMT offsets.
- **Box edges**: `UpdateBoxEdges()` derives a “current” box from the last 60 M1 bars and draws it (optional).
- **Signal generation**: `GetEntrySignal()` triggers at box top/bottom (with tolerance) and avoids flipping against an existing campaign.
- **Execution**: `OpenBuyTrade()` / `OpenSellTrade()` place market orders with fixed TP (3 pips) and SL (36 pips).
- **Risk throttles**:
  - one trade per M1 bar (`g_lastTradeBar`),
  - 4 clicks per box / 16 clicks max per session.
- **Ejection**: when drawdown exceeds 4 boxes, `TriggerEjection()` closes all EA positions and disables trading.

### Feature toggles / inputs that matter when debugging
- `InpBrokerGMTOffset` / `InpTargetGMTOffset`: session window conversion to broker server time.
- `InpRiskPercent`: per-click risk sizing (defaults to 0.25%).
- `InpMagicNumber`: used to identify EA positions/deals.
- `InpClickMode`: `RECYCLE` resets clicks when flat and session P/L is non-negative; `SESSION` keeps a fixed 16/day budget.
- `InpShowBoxes` / `InpShowPanel`: affects chart objects + `Comment()` output.

## Spec alignment and “where to implement changes”
When adding Phase 2+ features, keep these alignments in mind:
- The spec is in `docs/EA_SPECIFICATION.md`; code sections are labeled `SPEC-00x`.
- Current EA entry logic does **not** implement top-down bias detection (`SPEC-009`) or news filtering (`SPEC-012`); both are called out as later-phase work in the docs/README.
- “Dynamic box calculation” (computing box height/duration from swings) is described in the spec but the MVP code uses locked constants for box height/stop/TP.
