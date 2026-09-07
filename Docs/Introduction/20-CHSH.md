# Chapter 20 — Bell Tests: The CHSH Inequality

> Why entanglement is provably not "hidden classical information": the classical bound
> enumerated exhaustively, a Bell pair's S = 2√2, and the gap plotted live.

| | |
|---|---|
| Playground page | [`15CHSH`](../../../SwiftQiskit/PlaygroundDocs/15CHSHHELP.md) |
| In the app | ◐ — the Bell pair and each measurement-basis rotation (`ry`) are tappable one setting at a time; sweeping all four settings and summing the CHSH statistic S is code-only |
| Library APIs | `QuantumCircuit.h/cx/ry` |
| Prerequisites | Chapter 12 |

## 20.1 The classical bound, enumerated
Exhaustively checking every classical (local hidden-variable) strategy tops out at S = 2.

## 20.2 A Bell pair's quantum correlations
Measuring in rotated bases via `ry`.

## 20.3 S = 2√2
Summing the four correlation terms and exceeding the classical bound.

## 20.4 Plotting the gap live
`CHSHChartView`'s live comparison of classical vs. quantum S.

## Build it in the app
◐ Build the Bell pair (`h;cx`) and, for one of the four measurement-setting combinations, add
the `ry(θ)` basis rotation on each qubit before measuring — but summing all four combinations
into the single CHSH statistic S needs code.

## Run it in code

```swift
import SwiftQiskitCore
// CHSH: four measurement settings on a Bell pair, summed into S ≈ 2√2
```

## Try it yourself

1. Confirm no classical assignment of ±1 outcomes to the four settings can reach S > 2.
   <details><summary>Answer</summary>This is exactly `15CHSHHELP.md`'s exhaustive enumeration
   — every one of the 16 deterministic local strategies caps out at \|S\| ≤ 2.</details>

---
[← Chapter 19](19-ErrorCorrection.md) · [Contents](../../INTRODUCTION.md) · [Chapter 21 →](21-Noise.md)
