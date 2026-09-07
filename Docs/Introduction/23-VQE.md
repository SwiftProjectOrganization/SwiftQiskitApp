# Chapter 23 — Variational Algorithms: VQE

> Finding a ground-state energy by optimization instead of diagonalization: an H₂ Hamiltonian, a
> one-parameter ansatz, exact parameter-shift gradients, and gradient descent plotted live.

| | |
|---|---|
| Playground page | [`18VQE`](../../../SwiftQiskit/PlaygroundDocs/18VQEHELP.md) |
| In the app | ◐ — the one-parameter ansatz (an `ry(θ)` circuit) is tappable and its state readable; computing the energy expectation value and running gradient descent is code-only |
| Library APIs | `QuantumCircuit.ry`; the page's local `ansatz`, `energy`, `parameterShiftGradient`, `finiteDifferenceGradient` |
| Prerequisites | Chapters 4, 8 |

## 23.1 The H₂ Hamiltonian
The toy Hamiltonian this chapter minimizes over.

## 23.2 A one-parameter ansatz
`ry(θ)` as the entire variational family.

## 23.3 The energy landscape
Plotting `energy(θ)` across θ and finding the minimum by eye.

## 23.4 Exact gradients via the parameter-shift rule
Comparing `parameterShiftGradient` to a finite-difference approximation.

## 23.5 Gradient descent, plotted live
Watching θ converge toward the ground-state angle.

## Build it in the app
◐ Place `ry(θ)` on a qubit and read its state vector at a few trial angles by hand — but
computing the Hamiltonian's expectation value, the gradient, or running an optimization loop
needs code.

## Run it in code

```swift
import SwiftQiskitCore
// ansatz/energy/parameterShiftGradient copied from 18VQE, one gradient-descent step
```

## Try it yourself

1. Compare the parameter-shift gradient to a finite-difference gradient at the same θ.
   <details><summary>Answer</summary>They should agree closely — parameter-shift is exact for
   this ansatz, finite-difference is only approximate, per `18VQEHELP.md`.</details>

---
[← Chapter 22](22-Tomography.md) · [Contents](../../INTRODUCTION.md) · [Chapter 24 →](24-Trotter.md)
