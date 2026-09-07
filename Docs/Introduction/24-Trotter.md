# Chapter 24 — Hamiltonian Simulation and Trotter Error

> Simulating time evolution of a spin chain by chopping it into gates: an `expm` ground truth,
> the exact ZZ-rotation gate identity, Trotter error shrinking as 1/n (1/n² for Suzuki), and the
> non-commuting terms that cause it.

| | |
|---|---|
| Playground page | [`21Trotter`](../../../SwiftQiskit/PlaygroundDocs/21TROTTERHELP.md) |
| In the app | ◐ — the ZZ(θ) rotation decomposes exactly into `cx; rz; cx` and is tappable; the `expm` ground truth and the error-scaling sweep across step counts n are code-only |
| Library APIs | `QuantumCircuit.cx/rz`; the page's local `expm`, `zzViaGates`, `trotterUnitary` |
| Prerequisites | Chapters 7, 11 |

## 24.1 The spin-chain Hamiltonian
The non-commuting terms whose sum can't be exponentiated in closed form.

## 24.2 An `expm` ground truth
Matrix exponential by series expansion, as the reference every approximation is checked against.

## 24.3 ZZ(θ) as an exact gate identity
`cx; rz(θ); cx` computes `exp(-iθZZ/2)` exactly — no approximation needed for this one term.

## 24.4 Trotter error shrinking as 1/n
Splitting time evolution into more, smaller steps.

## 24.5 Suzuki's second-order correction: 1/n²
A symmetrized step order that converges faster.

## 24.6 Why non-commuting terms cause the error at all
The commutator that vanishes only in the n→∞ limit.

## Build it in the app
◐ Build the exact `cx; rz(θ); cx` identity for one ZZ term and confirm it matches the page's
`zzViaGates` — but chaining multiple non-commuting terms into a full Trotter step, and comparing
against `expm`, needs code.

## Run it in code

```swift
import SwiftQiskitCore
// expm/zzViaGates/trotterUnitary copied from 21Trotter; error vs n
```

## Try it yourself

1. Compare first-order and Suzuki second-order Trotter error at the same step count n.
   <details><summary>Answer</summary>Second-order error should be noticeably smaller, scaling
   as 1/n² instead of 1/n, per `21TROTTERHELP.md`.</details>

---
[← Chapter 23](23-VQE.md) · [Contents](../../INTRODUCTION.md) · [Chapter 25 →](25-QuantumWalks.md)
