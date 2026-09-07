# Chapter 22 — State Tomography

> Reconstructing an unknown state from `measure(shots:)` alone: basis rotations pinned by hand,
> 1/√N error scaling, and why a *pure* state's reconstruction stays "unphysical" about half the
> time no matter how many shots you take.

| | |
|---|---|
| Playground page | [`20Tomography`](../../../SwiftQiskit/PlaygroundDocs/20TOMOGRAPHYHELP.md) |
| In the app | ◐ — the three basis-rotation-then-measure circuits are tappable one at a time; combining the three shot counts into a reconstructed Bloch vector is code-only |
| Library APIs | `QuantumCircuit.h/rx/ry/measure(shots:)` |
| Prerequisites | Chapters 5, 9 |

## 22.1 Measuring in X, Y, and Z bases
Basis-rotation gates that turn "measure in Z" into "measure in X" or "measure in Y".

## 22.2 Reconstructing the Bloch vector
Turning three shot counts into `(x, y, z)` estimates.

## 22.3 Error scaling as 1/√N
More shots tighten the estimate, but only as the square root.

## 22.4 Why reconstruction is "unphysical" about half the time
Finite-shot noise can push the estimated vector outside the sphere, even for a genuinely pure
state.

## Build it in the app
◐ Build each of the three basis-rotation circuits (identity, `h`, `rx(-π/2)` or similar for the
Y basis) and read off each `measure(shots:)` histogram by hand; assembling the three counts into
a Bloch-vector estimate is code-only.

## Run it in code

```swift
import SwiftQiskitCore
// tomography of |+i> from three measure(shots:) runs, reconstructed (x,y,z)
```

## Try it yourself

1. Run tomography with 100 shots, then 10,000, and compare how far the reconstructed vector's
   magnitude departs from 1.
   <details><summary>Answer</summary>The departure shrinks roughly by a factor of 10 (√100),
   matching the 1/√N scaling `20TOMOGRAPHYHELP.md` describes.</details>

---
[← Chapter 21](21-Noise.md) · [Contents](../../INTRODUCTION.md) · [Chapter 23 →](23-VQE.md)
