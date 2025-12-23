# Session 17: FIFO vs Hedging - Account Types

---

## FIFO (First In, First Out)

### What Is FIFO?
- US regulatory requirement (NFA)
- Must close oldest trades first
- Cannot have opposing positions simultaneously

### Impact on Box Strategy
- Cannot layer trades in opposite direction
- Cannot hedge with same pair
- Must use alternate approaches

---

## Non-FIFO Accounts (Hedging Allowed)

### Features
- Can have simultaneous buy/sell
- Can close any trade in any order
- More flexibility for box layering

### Where Available
- Non-US brokers
- Some offshore jurisdictions
- European brokers (varies)

---

## Adapting Box Strategy for FIFO

### Method 1: One Direction Only
- Pick bias, stick to it
- Only buy OR only sell
- Add trades in same direction

### Method 2: Close All Before Reversing
- If changing direction, close all first
- Book P/L, then restart

### Method 3: Use Correlated Pairs
- Instead of hedging EUR/USD
- Sell a correlated pair (e.g., GBP/USD)
- Approximate hedge effect

---

## EA Considerations

### For FIFO Accounts
```
IF account_type == FIFO:
    DISABLE_HEDGING()
    ENFORCE_SINGLE_DIRECTION()
    CLOSE_ALL_BEFORE_DIRECTION_CHANGE()
```

### For Non-FIFO Accounts
```
IF account_type == HEDGING:
    ALLOW_OPPOSITE_POSITIONS()
    ALLOW_SELECTIVE_CLOSE()
    ENABLE_HEDGE_MODE()
```

---

## Key Parameters

| Feature | FIFO Account | Hedging Account |
|---------|--------------|-----------------|
| Opposite trades | Not allowed | Allowed |
| Close order | Oldest first | Any order |
| Flexibility | Limited | Full |
| Best for | US traders | Non-US |

---

## Key Quotes

1. *"Hedging opens the can of worms to both sides. Now you have 2 cans of worms."*

2. *"Learn to lose before you learn to hedge."*

---

## Action Items for EA

- [ ] Add account type detection (FIFO/Non-FIFO)
- [ ] Implement FIFO-compliant order closing
- [ ] Add optional hedge mode for non-FIFO
- [ ] Create correlated pair hedge option
