# Chapter 2 — Complex Numbers and Matrices in Swift

> The two building blocks everything else rests on: `Complex` numbers and the `Matrix` type,
> including the Kronecker/tensor product `⊗` that later chapters use to combine qubits.

| | |
|---|---|
| Playground page | — (see also [`09Tensor`](../../../SwiftQiskit/PlaygroundDocs/09TENSORHELP.md) for `⊗` in depth) |
| In the app | ○ — the app has no matrix-entry UI; only the results of gates applied to it are visible |
| Library APIs | `Math/Complex.swift`, `Math/Matrix.swift` (`+ - * /`, `multiply(by:)`, `identity(size:)`, `tensor(_:)`/`⊗`) |
| Prerequisites | Chapter 1 |

## 2.1 Complex numbers as Swift values
`Complex`'s four arithmetic operators, scalar multiplication, and `.zero/.one/.i`.

## 2.2 Matrices as row-major grids of Complex
Construction, `*` (matrix × matrix), `multiply(by:)` (matrix × vector), `identity(size:)`.

## 2.3 The tensor product `⊗`
Why combining two qubits needs a 4×4 matrix from two 2×2s, and what `Matrix.tensor(_:)` computes.

## Build it in the app
○ Not expressible — there's no way to enter a raw matrix in the app. Every later "Not
expressible" chapter comes back to this same limitation.

## Run it in code

```swift
import SwiftQiskitCore
// Complex arithmetic and a 2x2 * 2x2 tensor product
```

## Try it yourself

1. Compute `HadamardGate.matrix.tensor(Matrix.identity(size: 2))` by hand for one entry and
   check it against the code.
   <details><summary>Answer</summary>This is exactly the embedding `07-SingleQubitGates` and
   `11-TensorProducts` rely on to apply a single-qubit gate to one qubit of a larger register.</details>

---
[← Chapter 1](01-Setup.md) · [Contents](../../INTRODUCTION.md) · [Chapter 3 →](03-Qubits.md)
