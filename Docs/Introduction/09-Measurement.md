# Chapter 9 — Measurement, Shots and Statistics

> Turning a state vector into classical bits: `run()` vs `measure(shots:)`, why shot counts
> jitter, and how to read a histogram honestly.

| | |
|---|---|
| Playground page | — (drawn from `05Gates`/`06Superposition` and `Quantum/SimulationResult.swift`) |
| In the app | ● — the Results panel's **Measure** button and histogram are exactly this |
| Library APIs | `QuantumCircuit.run()`, `.runAndMeasure()`, `.measure(shots:)`, `SimulationResult` |
| Prerequisites | Chapters 3, 7 |

## 9.1 Exact vs. sampled: run() vs measure(shots:)
`run()` gives amplitudes/probabilities with no randomness; `measure(shots:)` simulates repeated
collapse.

## 9.2 Why shots jitter
Binomial variance at small vs. large shot counts.

## 9.3 Reading a histogram
Mapping bars back to basis-state labels and the qubit-0-is-leftmost convention.

## Build it in the app
● Place `RX(π/2)`, set Shots to 1000, tap **Measure** repeatedly, and watch the roughly-50/50
split jitter run to run.

## Run it in code

```swift
import SwiftQiskitCore
// measure(shots: 1000) on an RX(pi/2) circuit, twice, to show jitter
```

## Try it yourself

1. Increase shots from 100 to 100,000 and observe the split tighten toward 50/50.
   <details><summary>Answer</summary>Standard error shrinks as 1/√N — the same scaling law
   Chapter 22 (tomography) relies on.</details>

---
[← Chapter 8](08-Interference.md) · [Contents](../../INTRODUCTION.md) · [Chapter 10 →](10-Superposition.md)
