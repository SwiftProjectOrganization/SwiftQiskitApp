# Chapter 17 — Shor's Algorithm, Compiled

> Factoring 15 end to end: modular multiplication as a hand-built permutation matrix, a compiled
> QFT†, 3-qubit phase estimation of the order r, classical gcd post-processing, and the a = 14
> failure case.

| | |
|---|---|
| Playground page | [`12ShorExample`](../../../SwiftQiskit/PlaygroundDocs/12SHORHELP.md) |
| In the app | ○ — needs hand-built permutation matrices applied via `apply(_:)`; the gate palette has no modular-arithmetic primitive |
| Library APIs | `QuantumCircuit.apply(_:)`, `Matrix.tensor(_:)` for the compiled QFT† |
| Prerequisites | Chapters 11, 16 |

## 17.1 Modular multiplication as a permutation
Building `×a mod 15` as a basis-state permutation matrix.

## 17.2 Controlled powers of the permutation
Chaining controlled `a^(2^k) mod 15` for phase estimation.

## 17.3 A compiled QFT†
The entrywise 8×8 inverse QFT, embedded with `⊗`.

## 17.4 Phase estimation of the order r
Reading the period out of the measured register.

## 17.5 Classical post-processing: gcd
Turning the estimated order into a factor of 15.

## 17.6 A base sweep, including the a = 14 failure
Why not every valid `a` succeeds, and what failure looks like.

## Build it in the app
○ Not expressible — the modular-multiplication permutation and the compiled QFT† both require
`apply(_:)` with hand-built matrices; there is no in-app path. Chapter 16 is the closest tappable
approximation of the QFT half.

## Run it in code

```swift
import SwiftQiskitCore
// factor 15 via a = 7 (success) and a = 14 (failure), per 12SHORHELP.md
```

## Try it yourself

1. Sweep every valid base `a` coprime to 15 and tally which succeed.
   <details><summary>Answer</summary>`a = 14` is the noted failure case in
   `12SHORHELP.md`; most other bases succeed on the first try.</details>

---
[← Chapter 16](16-QFT.md) · [Contents](../../INTRODUCTION.md) · [Chapter 18 →](18-Teleportation.md)
