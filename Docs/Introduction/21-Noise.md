# Chapter 21 — Noise, Density Matrices and Channels

> Where the state-vector picture stops being enough: density matrices, Kraus channels
> (bit-flip, phase-flip, depolarizing, amplitude damping), coherence decay, a Monte-Carlo
> unraveling, and entanglement entropy from a Bell pair's reduced state.

| | |
|---|---|
| Playground page | [`19Noise`](../../../SwiftQiskit/PlaygroundDocs/19NOISEHELP.md) |
| In the app | ○ — `SwiftQiskitCore` is a pure state-vector simulator; there is no density-matrix type or channel API, in the app or the package |
| Library APIs | none in `SwiftQiskitCore`; the page's own local helpers (`rho`, `purity`, `bitFlipKraus`/`phaseFlipKraus`/`depolarizingKraus`/`ampDampingKraus`, `applyChannel`, `partialTraceLast`, `entropy`) |
| Prerequisites | Chapters 4, 11, 12 |

## 21.1 From state vectors to density matrices
`ρ = |ψ⟩⟨ψ|` for a pure state, and why mixed states need the more general object.

## 21.2 Kraus channels
Bit-flip, phase-flip, depolarizing, and amplitude-damping channels as sets of Kraus operators.

## 21.3 Coherence decay
Watching off-diagonal density-matrix entries shrink under a channel.

## 21.4 A Monte-Carlo unraveling
Sampling discrete jump outcomes and averaging back to the channel's density-matrix prediction.

## 21.5 Entanglement entropy from a Bell pair's reduced state
`partialTraceLast` and `entropy`, applied to the maximally-entangled Bell pair.

## 21.6 A live Bloch gallery
Watching a qubit's Bloch vector shrink toward the sphere's center under noise.

## Build it in the app
○ Not expressible — copy the page's helper functions into a standalone snippet, per
`AUTHORING.md`'s note that these live in the page body, not `SwiftQiskitCore`.

## Run it in code

```swift
import SwiftQiskitCore
// rho/purity/Kraus-channel helpers copied from 19Noise, applied to a bit-flip channel
```

## Try it yourself

1. Confirm a Bell pair's reduced single-qubit state has entropy `ln(2)` (maximal for a qubit).
   <details><summary>Answer</summary>This is the density-matrix restatement of Chapter 12's
   "the Bloch arrow collapses to the sphere's center" — maximal entanglement means maximal
   entropy in the reduced state.</details>

---
[← Chapter 20](20-CHSH.md) · [Contents](../../INTRODUCTION.md) · [Chapter 22 →](22-Tomography.md)
