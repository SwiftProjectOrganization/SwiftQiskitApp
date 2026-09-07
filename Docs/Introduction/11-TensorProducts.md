# Chapter 11 — Tensor Products and Composite Systems

> Why combining qubits multiplies dimensions instead of adding them: `⊗` on matrices and state
> vectors, gate embedding, the mixed-product identity, and why the Bell state doesn't factor.

| | |
|---|---|
| Playground page | [`09Tensor`](../../../SwiftQiskit/PlaygroundDocs/09TENSORHELP.md) |
| In the app | ◐ — placing `h(0)` on a multi-qubit circuit is the tappable half; the underlying `⊗` algebra (hand-building H ⊗ I₂) is code-only |
| Library APIs | `Matrix.tensor(_:)`/`⊗`, `StateVector.tensor(_:)`/`⊗` |
| Prerequisites | Chapters 2, 7, 10 |

## 11.1 Combining two registers: `⊗` on state vectors
`self` lands in the high-order bits, per the qubit-0-is-MSB convention.

## 11.2 Embedding a single-qubit gate: `⊗` on matrices
`H ⊗ I₂` by hand vs. `QuantumCircuit.h(0)` on a 2-qubit circuit — same result.

## 11.3 The mixed-product identity
`(A⊗B)(C⊗D) = (AC)⊗(BD)`, checked numerically.

## 11.4 Why the Bell state doesn't factor
The defining signature of entanglement, previewing Chapter 12.

## Build it in the app
◐ Place `h(0)` on a 2-qubit circuit and confirm the state matches `H⊗I₂` applied to `\|00⟩` — but
building `H⊗I₂` itself, or checking the mixed-product identity, has no in-app equivalent.

## Run it in code

```swift
import SwiftQiskitCore
// H.tensor(I2) vs QuantumCircuit().h(0); the mixed-product identity; Bell state factoring check
```

## Try it yourself

1. Show that the Bell state's amplitude vector cannot be written as `v ⊗ w` for any 2-vectors
   `v`, `w`.
   <details><summary>Answer</summary>Try to solve for `v, w` component-wise from
   `(1,0,0,1)/√2` — the system is inconsistent, which is exactly the algebraic statement of
   entanglement.</details>

---
[← Chapter 10](10-Superposition.md) · [Contents](../../INTRODUCTION.md) · [Chapter 12 →](12-Entanglement.md)
