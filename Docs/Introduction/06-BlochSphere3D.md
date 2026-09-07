# Chapter 6 — The Bloch Sphere in 3D: θ and φ

> The full spherical parametrization `|ψ⟩ = cos(θ/2)|0⟩ + e^{iφ}sin(θ/2)|1⟩`, explored with a
> rotatable, perspective-projected 3D sphere and live sliders.

| | |
|---|---|
| Playground page | [`04Bloch3d`](../../../SwiftQiskit/PlaygroundDocs/04BLOCH3DHELP.md) |
| In the app | ○ — a 3D/rotatable Bloch view is an open item in `Docs/Todo.md`; the app only has the 2D `BlochSphereView` |
| Library APIs | `Bloch3DView`, `BlochExplorerView` (playground `Sources/`, not vendored into the app) |
| Prerequisites | Chapters 4, 5 |

## 6.1 The θ/φ parametrization
Deriving the sphere coordinates from a general single-qubit state.

## 6.2 Rotating the view
What changes (and doesn't) when you drag the sphere versus drag θ/φ.

## 6.3 Live sliders as a state-space explorer
Sweeping θ and φ and watching probabilities/amplitudes track the arrow.

## Build it in the app
○ Not expressible today — use the playground page; the app's Chapter 5 badge (◐) is the closest
in-app equivalent, and a rotatable 3D view is tracked in `Docs/Todo.md` if this ever changes.

## Run it in code

```swift
import SwiftQiskitCore
// derive (theta, phi) from a StateVector's amplitudes
```

## Try it yourself

1. What θ/φ gives `|+i⟩`?
   <details><summary>Answer</summary>θ = π/2, φ = π/2 — the equator, a quarter-turn from
   `|+⟩`.</details>

---
[← Chapter 5](05-BlochSphere2D.md) · [Contents](../../INTRODUCTION.md) · [Chapter 7 →](07-SingleQubitGates.md)
