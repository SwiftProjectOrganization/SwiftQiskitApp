# Chapter 4 — Dirac Notation and Expectation Values

> The `Ket`/`Bra`/`†` notation the rest of the book writes math in, and how projectors and Pauli
> expectation values (`⟨ψ|X|ψ⟩`) read a qubit's Bloch coordinates straight off its state vector.

| | |
|---|---|
| Playground page | [`01Qubits`](../../../SwiftQiskit/PlaygroundDocs/01QUBITSHELP.md), [`08Dirac`](../../../SwiftQiskit/PlaygroundDocs/08DIRACHELP.md) |
| In the app | ○ — no bra/projector/expectation-value display; the app only shows amplitudes and probabilities |
| Library APIs | `Quantum/Dirac.swift` (`Ket`, `Bra`, postfix `†`, inner/outer `*`, basis kets `Ket("01")`, `.zero/.one/.plus/.minus/.plusI/.minusI`) |
| Prerequisites | Chapter 3 |

## 4.1 Ket, Bra, and the dagger
`Ket` as a typealias of `StateVector`; `Bra` as its conjugated row form; postfix `†`.

## 4.2 Inner and outer products
`Bra * Ket` (a number) vs. `Ket * Bra` (a projector matrix).

## 4.3 Projectors and adjoints
Building `|ψ⟩⟨ψ|` and checking it's Hermitian and idempotent.

## 4.4 Pauli expectation values as Bloch coordinates
`⟨ψ|X|ψ⟩, ⟨ψ|Y|ψ⟩, ⟨ψ|Z|ψ⟩` computed via `Bra * Matrix -> Bra`, matched against a static
3D Bloch sphere from `08Dirac`.

## Build it in the app
○ Not expressible — pin this to Chapter 6's 3D Bloch sphere for the visual, and to Chapters 2/3's
code for the algebra.

## Run it in code

```swift
import SwiftQiskitCore
// Ket/Bra/† ; ⟨ψ|X|ψ⟩ for the plusI state
```

## Try it yourself

1. Verify `⟨+i|Z|+i⟩ ≈ 0` — `|+i⟩` sits on the sphere's equator.
   <details><summary>Answer</summary>Equatorial states have zero Z-expectation by construction;
   this is exactly the Bloch-sphere geometry Chapter 5 draws.</details>

---
[← Chapter 3](03-Qubits.md) · [Contents](../../INTRODUCTION.md) · [Chapter 5 →](05-BlochSphere2D.md)
