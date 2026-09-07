# Chapter 3 — Qubits: Amplitudes and Probabilities

> What a qubit actually is in this simulator: a normalized pair of complex amplitudes, and the
> Born rule that turns them into the probabilities you see in the app's State Vector panel.

| | |
|---|---|
| Playground page | [`01Qubits`](../../../SwiftQiskit/PlaygroundDocs/01QUBITSHELP.md) |
| In the app | ● — every state shown here is exactly what the State Vector panel displays |
| Library APIs | `StateVector` (auto-normalizing `init`, `.amplitudes`, `.probabilities`, `apply(_:)`) |
| Prerequisites | Chapters 1, 2 |

## 3.1 A qubit as two complex amplitudes
`StateVector`'s normalization on `init`, and why `|α|² + |β|² = 1`.

## 3.2 From amplitudes to probabilities: the Born rule
`.probabilities` as `|amplitude|²`, and why probabilities alone lose information amplitudes keep.

## 3.3 Two worked circuits
`circuit1` (`H` → `P(π/2)` → `P(π)`) and `circuit2` (`H` → `Z` → `H`) from the page, stage by
stage.

## Build it in the app
● Place `H` on an empty qubit; read the two probabilities (≈0.5, ≈0.5) and note the amplitudes
aren't shown as complex numbers directly — only their magnitudes-squared.

## Run it in code

```swift
import SwiftQiskitCore
// StateVector amplitudes/probabilities for |0⟩, |+⟩, and circuit1/circuit2's stages
```

## Try it yourself

1. Predict `circuit2`'s final amplitudes before running it, then check.
   <details><summary>Answer</summary>`H;Z;H` on \|0⟩ lands on \|1⟩ — this is the same
   interference trick Chapter 8 explains in depth.</details>

---
[← Chapter 2](02-ComplexAndMatrices.md) · [Contents](../../INTRODUCTION.md) · [Chapter 4 →](04-DiracNotation.md)
