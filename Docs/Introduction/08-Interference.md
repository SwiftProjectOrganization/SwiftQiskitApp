# Chapter 8 — Phase, Interference, and Why Z Hides

> The book's hinge chapter: why a phase flip is invisible in probabilities yet completely real,
> and how a second `H` turns that hidden phase into an observable bit flip through interference.

| | |
|---|---|
| Playground page | [`05Gates`](../../../SwiftQiskit/PlaygroundDocs/05GATESHELP.md) §4, [`01Qubits`](../../../SwiftQiskit/PlaygroundDocs/01QUBITSHELP.md) (`circuit2`) |
| In the app | ● — `H;Z` and `H;Z;H` are both placeable |
| Library APIs | `QuantumCircuit.h/z`, `.amplitudes` vs `.probabilities` |
| Prerequisites | Chapter 7 |

## 8.1 Z alone on \|0⟩: nothing observable
`[1.0, 0.0]` either way.

## 8.2 Z after H: a real amplitude change, an unchanged probability
`H;Z` still measures 50/50, but the amplitudes' signs differ.

## 8.3 The second H: interference makes the phase visible
`H;Z;H` deterministically returns `\|1⟩` — the same construction as `circuit2` in Chapter 3.

## 8.4 Why probabilities lose information amplitudes keep
Generalizing the lesson beyond this one example.

## Build it in the app
● Place `H` then `Z` then `H` in three columns on one qubit; watch the State Vector panel
collapse to a deterministic `\|1⟩` only after the third gate.

## Run it in code

```swift
import SwiftQiskitCore
// H;Z vs H;Z;H amplitudes and probabilities
```

## Try it yourself

1. Predict whether `H;Z;H;Z;H` returns to `\|0⟩` or `\|1⟩`.
   <details><summary>Answer</summary>Each `H;Z;H` sandwich is a bit flip (it's `X` up to
   global phase), so five gates = two and a half flips; work through the parity by hand and
   check against the code.</details>

---
[← Chapter 7](07-SingleQubitGates.md) · [Contents](../../INTRODUCTION.md) · [Chapter 9 →](09-Measurement.md)
