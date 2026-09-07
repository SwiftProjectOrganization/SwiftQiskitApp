# Chapter 13 — Oracles and Phase Kickback: Deutsch's Algorithm

> The first quantum speedup: telling a constant function from a balanced one in a single query,
> via an oracle built from `x`/`cx` and the phase-kickback trick that makes it work.

| | |
|---|---|
| Playground page | [`10DeutschExample`](../../../SwiftQiskit/PlaygroundDocs/10DEUTSCHHELP.md) |
| In the app | ● — all four 1-bit oracles are `x(1)`/`cx(0,1)` combinations |
| Library APIs | `QuantumCircuit.h/x/cx` |
| Prerequisites | Chapters 8, 12 |

## 13.1 The four 1-bit oracles
Building constant-0, constant-1, identity, and NOT as `x`/`cx` circuits.

## 13.2 Phase kickback, stage by stage
Why acting on an ancilla in `\|−⟩` kicks a phase back onto the query qubit.

## 13.3 One query, a deterministic verdict
Constant vs. balanced read off with certainty — no shots needed.

## 13.4 Shot statistics as a sanity check
Confirming the deterministic verdict against `measure(shots:)`.

## Build it in the app
● Build each 2-qubit oracle circuit (`H` on both qubits, the oracle's `x`/`cx`, `H` on the query
qubit) and read the deterministic final state.

## Run it in code

```swift
import SwiftQiskitCore
// all four 1-bit oracles through Deutsch's circuit
```

## Try it yourself

1. Which of the four oracles are "balanced" and which are "constant"?
   <details><summary>Answer</summary>Constant-0 and constant-1 are constant; identity and NOT
   are balanced — Deutsch's algorithm separates these two groups in one query.</details>

---
[← Chapter 12](12-Entanglement.md) · [Contents](../../INTRODUCTION.md) · [Chapter 14 →](14-DeutschJozsa.md)
