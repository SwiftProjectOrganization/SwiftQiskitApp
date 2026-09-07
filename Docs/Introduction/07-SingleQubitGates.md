# Chapter 7 — Single-Qubit Gates, One at a Time

> A gentle, gate-by-gate tour of the built-in gate set — `x h z y s sdg t p rx ry rz` — each
> shown individually on a 1-qubit circuit, ending with a one-line Bell-state teaser.

| | |
|---|---|
| Playground page | [`05Gates`](../../../SwiftQiskit/PlaygroundDocs/05GATESHELP.md) |
| In the app | ● — every gate here is in the palette |
| Library APIs | `QuantumCircuit.h/x/y/z/s/sdg/t/tdg`, `p/rx/ry/rz(_:_:)` |
| Prerequisites | Chapters 3, 5 |

## 7.1 The bit flip: X
`\|0⟩ → \|1⟩`.

## 7.2 Superposition: H
`\|0⟩ → (\|0⟩+\|1⟩)/√2`.

## 7.3 The phase flip: Z, and why it's invisible alone
Sets up Chapter 8.

## 7.4 Y as X and Z together
Same probabilities as X, a different amplitude (`Y = iXZ`).

## 7.5 Quarter and eighth turns: S, S†, T
`S² = Z`'s relatives; two `T`s equal one `S`.

## 7.6 The general phase gate P(θ)
`P(π/2) ≡ S`, `P(π/4) ≡ T`, `P(π) ≡ Z`.

## 7.7 Continuous rotations: RX, RY, RZ
Where they land on states H/S/Z already reach, and where they differ in raw amplitude.

## 7.8 A Bell-state teaser
`H` + `CX`, pointing ahead to Chapter 12.

## Build it in the app
● Place each gate alone on a fresh 1-qubit circuit and read the State Vector panel; for
parameterized gates, tap the placed tile to open the θ popover.

## Run it in code

```swift
import SwiftQiskitCore
// each gate applied alone to |0>, matching 05GATESHELP.md's table
```

## Try it yourself

1. Confirm `T` applied twice matches `S` to within floating-point error, not exactly.
   <details><summary>Answer</summary>The two paths accumulate rounding differently; expect
   agreement to about 1e-16, not bit-for-bit — see `05GATESHELP.md` §7.</details>

---
[← Chapter 6](06-BlochSphere3D.md) · [Contents](../../INTRODUCTION.md) · [Chapter 8 →](08-Interference.md)
