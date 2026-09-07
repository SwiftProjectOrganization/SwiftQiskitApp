# Chapter 14 — Deutsch–Jozsa and Bernstein–Vazirani

> Generalizing Chapter 13's one-query trick from one bit to n bits, then repurposing the same
> circuit shape to recover an entire hidden bit-string in a single query.

| | |
|---|---|
| Playground page | [`17DeutschJozsa`](../../../SwiftQiskit/PlaygroundDocs/17DEUTSCHJOZSAHELP.md) |
| In the app | ● — up to the app's 8-qubit maximum (7 query qubits + 1 ancilla) |
| Library APIs | `QuantumCircuit.h/x/cx` |
| Prerequisites | Chapter 13 |

## 14.1 Deutsch–Jozsa: constant vs. balanced on n bits
The n-bit oracle generalization of Chapter 13.

## 14.2 Bernstein–Vazirani: recovering a hidden string
The same circuit shape, read differently, returns a secret bit-string in one query.

## 14.3 Why both algorithms share one circuit
The structural reason a single construction answers two different questions.

## Build it in the app
● With 4 total qubits (3 query + 1 ancilla), build the oracle for a chosen hidden string as
`cx` gates from each "1" bit's query qubit to the ancilla, and read the string straight off the
final measurement.

## Run it in code

```swift
import SwiftQiskitCore
// Bernstein-Vazirani recovering a 3-bit hidden string in one query
```

## Try it yourself

1. Build the oracle for hidden string `101` and confirm the algorithm recovers it.
   <details><summary>Answer</summary>`cx(0,3)` and `cx(2,3)` (skipping qubit 1, whose bit is
   0) on a 4-qubit circuit (3 query + ancilla at index 3).</details>

---
[← Chapter 13](13-Deutsch.md) · [Contents](../../INTRODUCTION.md) · [Chapter 15 →](15-Grover.md)
