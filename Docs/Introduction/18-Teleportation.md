# Chapter 18 — Teleportation and Superdense Coding

> Moving a qubit's state across an entangled pair without moving the qubit: Bell-basis
> projectors, deferred measurement, and Bloch spheres of every branch — plus the reverse trick,
> superdense coding.

| | |
|---|---|
| Playground page | [`13Teleportation`](../../../SwiftQiskit/PlaygroundDocs/13TELEPORTATIONHELP.md) |
| In the app | ◐ — the entangling and Bell-basis-rotation gates are tappable; the app has no mid-circuit measurement, so the classical-communication step is deferred (simulated by carrying all branches) rather than actually measured partway through |
| Library APIs | `QuantumCircuit.h/x/z/cx`, `Dirac` projectors for the Bell-basis measurement |
| Prerequisites | Chapters 4, 12 |

## 18.1 The protocol, stage by stage
Entangle, Bell-basis-rotate, "measure", classically communicate, correct.

## 18.2 Deferred measurement
Why the simulator carries every branch instead of collapsing partway through, and how that's
equivalent.

## 18.3 Bloch spheres of every branch
Visualizing all four correction branches side by side.

## 18.4 Superdense coding
The reverse protocol: two classical bits from one qubit, given a pre-shared Bell pair.

## Build it in the app
◐ Build the entangling `h;cx` and the sender's Bell-basis-rotating gates by tapping; the
"measure, then classically send, then correct" step has no mid-circuit-measurement equivalent in
the app — represent it in code with deferred measurement instead.

## Run it in code

```swift
import SwiftQiskitCore
// full teleportation protocol via deferred measurement (Bell-basis projectors)
```

## Try it yourself

1. Teleport `|+i⟩` instead of the page's default state and confirm the receiver's qubit matches
   after correction.
   <details><summary>Answer</summary>The protocol is state-agnostic — any single-qubit state
   teleports correctly, per `13TELEPORTATIONHELP.md`.</details>

---
[← Chapter 17](17-Shor.md) · [Contents](../../INTRODUCTION.md) · [Chapter 19 →](19-ErrorCorrection.md)
