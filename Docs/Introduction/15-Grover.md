# Chapter 15 — Grover's Search

> Amplitude amplification: phase oracles, inversion about the mean, an exact 1-iteration success
> on 2 qubits, over-rotation past the optimum, and a 3-qubit finale with a CCZ diffusion step.

| | |
|---|---|
| Playground page | [`11GroverExample`](../../../SwiftQiskit/PlaygroundDocs/11GROVERHELP.md) |
| In the app | ◐ — CZ (`h;cx;h`) and X-conjugated phase oracles are tappable; the 3-qubit finale's hand-built CCZ needs a decomposition the palette doesn't have a single button for |
| Library APIs | `QuantumCircuit.h/x/cx`, `apply(_:)` (for the page's hand-built CCZ) |
| Prerequisites | Chapters 8, 12, 13 |

## 15.1 CZ from H and CX
`h(1); cx(0,1); h(1)` as a phase-flip-on-\|11⟩ gate.

## 15.2 Phase oracles via X-conjugation
Marking an arbitrary target state by sandwiching CZ in X gates.

## 15.3 Inversion about the mean
The diffusion operator, and why it amplifies the marked amplitude.

## 15.4 Exact success at 2 qubits, over-rotation beyond it
One iteration is exact for N=4; more iterations overshoot.

## 15.5 The diffusion operator as `2|s⟩⟨s| − I`
The Dirac outer-product form of the same operator.

## 15.6 A 3-qubit finale: CCZ via `apply(_:)`
The page's hand-built CCZ, and the decomposition (`h; cx; tdg; cx; t; cx; tdg; cx; t; h`, or
similar T/T†+CX chains) that would make it tappable in principle.

## Build it in the app
◐ Build the 2-qubit case entirely from `h`/`x`/`cx` (CZ = `h;cx;h`, oracle = X-conjugated CZ,
diffusion = `h;x;cz;x;h`); for 3 qubits, the palette has no single CCZ gate — decompose it into
T/T†/CX or fall back to `apply(_:)` in code.

## Run it in code

```swift
import SwiftQiskitCore
// 2-qubit Grover: one iteration, exact success; a second iteration, over-rotation
```

## Try it yourself

1. Run the 2-qubit search for 2 iterations instead of 1 and confirm the success probability
   drops.
   <details><summary>Answer</summary>N=4 needs exactly 1 iteration (π/4 rotation); a second
   iteration over-rotates past the target, matching `11GROVERHELP.md`'s over-rotation
   section.</details>

---
[← Chapter 14](14-DeutschJozsa.md) · [Contents](../../INTRODUCTION.md) · [Chapter 16 →](16-QFT.md)
