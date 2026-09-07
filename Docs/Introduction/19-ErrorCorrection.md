# Chapter 19 — Quantum Error Correction

> The 3-qubit bit-flip and phase-flip codes: encoding, a hand-built syndrome correction,
> continuous errors digitized exactly, and where a distance-3 code breaks.

| | |
|---|---|
| Playground page | [`14ErrorCorrection`](../../../SwiftQiskit/PlaygroundDocs/14ERRORCORRECTIONHELP.md) |
| In the app | ◐ — encoding (`cx` fan-out) and injecting a bit/phase-flip error are tappable; the syndrome-measurement-and-correction step needs mid-circuit measurement the app doesn't have |
| Library APIs | `QuantumCircuit.h/x/z/cx` |
| Prerequisites | Chapters 12, 18 |

## 19.1 Encoding one qubit into three
The `cx` fan-out that spreads one logical qubit across three physical ones.

## 19.2 Injecting a bit-flip error
Applying `x` to one of the three qubits and watching the encoding survive.

## 19.3 The syndrome and its correction
Detecting *which* qubit flipped without measuring the logical state.

## 19.4 Continuous errors, digitized exactly
Why a small-angle rotation error still corrects to the same discrete syndrome.

## 19.5 Where a distance-3 code breaks
Two simultaneous errors defeat the code.

## Build it in the app
◐ Build the 3-qubit encoding and inject a single-qubit error by tapping `x`/`z`; the syndrome
extraction (ancilla-based parity checks, then a mid-circuit correction) has no equivalent without
mid-circuit measurement — do that part in code.

## Run it in code

```swift
import SwiftQiskitCore
// 3-qubit bit-flip code: encode, inject an error on qubit 1, syndrome, correct
```

## Try it yourself

1. Inject errors on two of the three qubits simultaneously and confirm the code corrects to the
   wrong logical state.
   <details><summary>Answer</summary>A distance-3 code only guarantees correction of a single
   error; two simultaneous errors are indistinguishable from a single error on the third qubit —
   see `14ERRORCORRECTIONHELP.md`'s breakdown section.</details>

---
[← Chapter 18](18-Teleportation.md) · [Contents](../../INTRODUCTION.md) · [Chapter 20 →](20-CHSH.md)
