# Chapter 16 — The Quantum Fourier Transform and Phase Estimation

> The QFT built as a gate circuit rather than a black-box matrix: a hand-derived controlled-phase
> gate, the QFT ladder checked against Chapter 17's compiled matrix, and standalone phase
> estimation.

| | |
|---|---|
| Playground page | [`16QFT`](../../../SwiftQiskit/PlaygroundDocs/16QFTHELP.md) |
| In the app | ◐ — the controlled-phase gate decomposes into `p` + `cx` and is tappable; chaining the full ladder for n > 2 qubits by hand is tedious but possible; the page's matrix cross-check against Chapter 17 is code-only |
| Library APIs | `QuantumCircuit.h/p/cx` |
| Prerequisites | Chapters 7, 11 |

## 16.1 Deriving the controlled-phase gate
Building CP(θ) from single-qubit `p` and `cx`.

## 16.2 The QFT ladder
Chaining H and CP gates across n qubits.

## 16.3 Checking against the compiled matrix
Comparing the gate-circuit QFT to Chapter 17's hand-built QFT† matrix.

## 16.4 Standalone phase estimation
Using the QFT to read out an eigenphase directly, decoupled from Shor's algorithm.

## Build it in the app
◐ For 2 qubits: `h(0); h(1)` then the CP(π/2) decomposition (`p(π/4,1); cx(0,1); p(-π/4,1);
cx(0,1); p(π/4,0)`), then a final `h` — tappable but fiddly; beyond 2 qubits the ladder grows
fast and the code version is more practical.

## Run it in code

```swift
import SwiftQiskitCore
// 2-qubit QFT via H/CP gates, compared to the page's hand-built matrix
```

## Try it yourself

1. Confirm the gate-circuit QFT and the matrix QFT agree to floating-point tolerance on a
   2-qubit input.
   <details><summary>Answer</summary>They should match to ~1e-10, per the tolerance
   `16QFTHELP.md` uses for the same comparison.</details>

---
[← Chapter 15](15-Grover.md) · [Contents](../../INTRODUCTION.md) · [Chapter 17 →](17-Shor.md)
