# Chapter 12 — Entanglement: Bell and GHZ

> The Bell state built and annotated stage by stage, then generalized to a 3-qubit GHZ state
> using `cx` across non-adjacent qubits.

| | |
|---|---|
| Playground page | [`07Entanglement`](../../../SwiftQiskit/PlaygroundDocs/07ENTANGLEMENTHELP.md) |
| In the app | ● — this is the app's own Tutorial.md walkthrough |
| Library APIs | `QuantumCircuit.h/cx` |
| Prerequisites | Chapters 10, 11 |

## 12.1 Building the Bell state
`h(0); cx(0,1)` — circuit, state vector, probabilities, shots.

## 12.2 Bloch spheres of an entangled pair
Both qubits collapse to the sphere's center (`|r| ≈ 0`) — Chapter 5's Display button made
concrete.

## 12.3 The GHZ state
3 qubits, `h(0); cx(0,1); cx(0,2)` — `cx` across non-adjacent qubits.

## Build it in the app
● The exact recipe in `Docs/Tutorial.md`'s Bell-state walkthrough, extended to 3 qubits for GHZ;
open **Display** afterward to see both qubits' arrows collapse to the sphere's center.

## Run it in code

```swift
import SwiftQiskitCore
// Bell state and 3-qubit GHZ state, amplitudes and probabilities
```

## Try it yourself

1. Build a 4-qubit GHZ state and predict its two nonzero states before running.
   <details><summary>Answer</summary>`\|0000⟩` and `\|1111⟩`, each ≈ 0.500 — one `h` and three
   `cx`s from qubit 0.</details>

---
[← Chapter 11](11-TensorProducts.md) · [Contents](../../INTRODUCTION.md) · [Chapter 13 →](13-Deutsch.md)
