# Chapter 5 — The Bloch Sphere in 2D, and Its Projections

> A qubit's state drawn as a point on a sphere: the six canonical states, a general tilted
> state, and the x–y/z–y plane projections that make a 2D drawing of a 3D object legible.

| | |
|---|---|
| Playground page | [`02Bloch2d`](../../../SwiftQiskit/PlaygroundDocs/02BLOCH2DHELP.md), [`03Bloch2dProjection`](../../../SwiftQiskit/PlaygroundDocs/03BLOCH2DPROJECTIONHELP.md) |
| In the app | ◐ — the **Display** button draws each qubit's 2D Bloch sphere; the app has no separate x–y/z–y projection panes |
| Library APIs | `BlochVector` (single-qubit case), `BlochSphereView` |
| Prerequisites | Chapters 3, 4 |

## 5.1 The six canonical states on the sphere
`|0⟩ |1⟩ |+⟩ |−⟩ |+i⟩ |−i⟩` as poles and equator points.

## 5.2 A general tilted state
Reading off θ/φ for an arbitrary single-qubit state.

## 5.3 Reading a 3D sphere in 2D: the two projections
Why `03Bloch2dProjection` draws x–y and z–y planes side by side, and what each one hides.

## Build it in the app
◐ Build any single-qubit circuit, tap **Display**, and read its arrow on the sphere — but the
app shows one oblique 2D view per qubit, not separate projection planes; use the playground page
for the plane-by-plane breakdown.

## Run it in code

```swift
import SwiftQiskitCore
// BlochVector for each of the six canonical states
```

## Try it yourself

1. Place `RY(π/4)` in the app and predict where the arrow lands before opening Display.
   <details><summary>Answer</summary>It sits at polar angle π/4 from the north pole, on the
   x–z great circle — see Chapter 6 for the full θ/φ parametrization.</details>

---
[← Chapter 4](04-DiracNotation.md) · [Contents](../../INTRODUCTION.md) · [Chapter 6 →](06-BlochSphere3D.md)
