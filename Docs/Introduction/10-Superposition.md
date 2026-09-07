# Chapter 10 — Superposition Across a Register

> Scaling superposition from one qubit to many: a 4-qubit register with every qubit put into
> superposition, its 16-state amplitude/probability spread, and a partial-superposition contrast.

| | |
|---|---|
| Playground page | [`06Superposition`](../../../SwiftQiskit/PlaygroundDocs/06SUPERPOSITIONHELP.md) |
| In the app | ● — up to the app's 8-qubit maximum |
| Library APIs | `QuantumCircuit.h`, multi-qubit `.amplitudes`/`.probabilities` |
| Prerequisites | Chapters 3, 7, 9 |

## 10.1 Every qubit in superposition
4× `H` giving 16 equally-likely states.

## 10.2 Reading multi-qubit labels
Bit-string ordering, qubit 0 as the leftmost character.

## 10.3 Partial superposition
`H` on 2 of 4 qubits — a contrast showing which bits stay fixed.

## Build it in the app
● Set Qubits to 4, place `H` on each row in the first column, and read the 16-row state vector
(all ≈ 6.25%).

## Run it in code

```swift
import SwiftQiskitCore
// 4-qubit all-H register vs a 2-of-4 partial superposition
```

## Try it yourself

1. With 3 qubits, put `H` on q0 and q2 only. How many nonzero states result, and which bit stays
   fixed?
   <details><summary>Answer</summary>4 nonzero states; the middle bit (q1) stays `0` in every
   one.</details>

---
[← Chapter 9](09-Measurement.md) · [Contents](../../INTRODUCTION.md) · [Chapter 11 →](11-TensorProducts.md)
