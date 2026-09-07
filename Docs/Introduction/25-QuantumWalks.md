# Chapter 25 — Discrete-Time Quantum Walks

> The quantum analogue of a random walk: a hand-built shift permutation, ballistic (∝t) spreading
> against classical diffusive (∝√t) comparison, and why the `|0⟩`-coin distribution is lopsided
> while `|+i⟩`'s is symmetric.

| | |
|---|---|
| Playground page | [`22Walk`](../../../SwiftQiskit/PlaygroundDocs/22WALKHELP.md) |
| In the app | ○ — the shift operator is a hand-built position-register permutation applied via `apply(_:)`; there is no in-app equivalent |
| Library APIs | `QuantumCircuit.apply(_:)`, `h` (the coin flip) |
| Prerequisites | Chapters 9, 11, 17 |

## 25.1 Coin and position registers
Splitting the walker into a coin qubit and a position register.

## 25.2 The shift operator as a hand-built permutation
Moving the position register left/right conditioned on the coin.

## 25.3 Ballistic vs. diffusive spreading
Quantum ∝t spreading against a classical random walk's ∝√t.

## 25.4 Why `|0⟩` is lopsided and `|+i⟩` is symmetric
The coin's initial phase determines the walk's interference pattern.

## Build it in the app
○ Not expressible — the shift permutation needs `apply(_:)` with a hand-built matrix at a size
this simulator's fixed gate set can't reach through tapping.

## Run it in code

```swift
import SwiftQiskitCore
// coin flip (h) + shift permutation via apply(_:), position distribution after n steps
```

## Try it yourself

1. Compare the walk's position spread after 10 steps starting from coin state `|0⟩` versus
   `|+i⟩`.
   <details><summary>Answer</summary>`|0⟩` gives a lopsided, asymmetric distribution; `|+i⟩`
   gives a symmetric one — the coin's relative phase controls which interference pattern
   emerges, per `22WALKHELP.md`.</details>

---
[← Chapter 24](24-Trotter.md) · [Contents](../../INTRODUCTION.md) · [Chapter 26 →](26-Epilogue.md)
