# Chapter 6 — The Bloch Sphere in 3D: θ and φ

> The full spherical parametrization `|ψ⟩ = cos(θ/2)|0⟩ + e^{iφ}sin(θ/2)|1⟩`, explored with a
> rotatable, perspective-projected 3D sphere and live sliders.

| | |
|---|---|
| Playground page | [`04Bloch3d`](../../../SwiftQiskit/PlaygroundDocs/04BLOCH3DHELP.md) |
| In the app | ◐ — the Display sheet's readout prints θ and φ directly for any single-qubit state, built by placing **RY** then **P**; there is no rotatable camera and no live-while-dragging slider loop |
| Library APIs | `Bloch3DView`, `BlochExplorerView` (playground `Sources/`, not vendored into the app) |
| Prerequisites | Chapters 4, 5 |

## 6.1 The θ/φ parametrization

Chapter 5 placed six special states on the sphere by name, then one general tilted state by
direction cosines. This chapter derives the parametrization that reaches *every* state that way.

Start from a general normalized `|ψ⟩ = α|0⟩ + β|1⟩`. Multiplying both amplitudes by the same
`e^{-iγ}` (Chapter 5 §5.1's global phase, invisible to the Bloch sphere) can always be chosen to
make `α` real and non-negative, without changing where the state sits. Writing the now-real `α`
as `cos(θ/2)` for some `θ ∈ [0, π]`, normalization forces `|β| = sin(θ/2)`, so `β` is
`sin(θ/2)` times some unit-modulus phase `e^{iφ}`:

```text
|ψ⟩ = cos(θ/2)|0⟩ + e^{iφ}·sin(θ/2)|1⟩
```

with `θ ∈ [0, π]` the polar angle from the `|0⟩` pole (matching Chapter 5's `θ = acos(z)`) and
`φ ∈ [0, 2π)` the azimuth from the x-axis (matching `φ = atan2(y, x)`). Note the half-angle:
`θ` is the sphere angle, but `θ/2` is what actually appears in the amplitudes — an antipodal
pair of Bloch points, `θ` and `θ + π`, corresponds to a pair of *orthogonal* states, since
`cos((θ+π)/2)` and `cos(θ/2)` are 90° apart in the underlying half-angle.

Why can θ and φ vary completely independently, with no constraint linking them? Because the
parametrization satisfies normalization *identically*, for every choice of the two angles:

```text
|α|² + |β|² = cos²(θ/2) + |e^{iφ}|²·sin²(θ/2) = cos²(θ/2) + sin²(θ/2) = 1
```

`e^{iφ}` is a pure phase — `|e^{iφ}| = 1` always — so it never touches a magnitude. A quick
sweep confirms the identity holds well past a few sample angles:

```swift
func makeState(theta: Double, phi: Double) -> StateVector {
    StateVector([
        Complex(cos(theta / 2)),
        Complex(sin(theta / 2) * cos(phi), sin(theta / 2) * sin(phi))
    ])
}

for theta in stride(from: 0.0, through: Double.pi, by: Double.pi / 4) {
    for phi in stride(from: 0.0, through: 2 * Double.pi, by: Double.pi / 3) {
        let s = makeState(theta: theta, phi: phi)
        let norm = s[0].magnitudeSquared + s[1].magnitudeSquared
        if abs(norm - 1) > 1e-9 { print("FAIL", theta, phi, norm) }
    }
}
print("sweep ok")
```

```text
sweep ok
```

No failure printed across 5 × 7 = 35 angle pairs. This is the reason `04Bloch3d`'s live view
exposes **sliders for the angles**, not the raw amplitudes: every slider position is
automatically a valid normalized state, so the sliders can only move around the surface of the
sphere, never off of it — there is nothing left to renormalize.

## 6.2 Rotating the view

Chapter 5's `BlochSphereView` fixes one oblique viewpoint for good: `y` right, `z` up, `x`
foreshortened toward the lower-left. `Bloch3DView` (playground `Sources/`, not vendored into
this app) instead orbits a genuine perspective camera around a fixed sphere: an azimuth angle
(about the z-axis) and an elevation angle (above the equator) place the camera at
`cameraDistance = 4` sphere-radii, and every world point is perspective-divided,
`scale = d / (d − depth)`, so nearer geometry draws larger. Dragging the canvas changes the
*camera's* azimuth/elevation — nothing about `|ψ⟩` moves. That is the distinction this chapter's
title draws: **rotating the view** (a spectator choice, orbiting around a fixed point) is a
completely different action from **rotating the state** (dragging θ or φ, which is what §6.3
does).

A fixed single projection has a real cost, and Chapter 5 §5.3 already named it: a short
projected arrow is ambiguous between "points toward the viewer" and "is genuinely shorter than
1." An orbit camera resolves that ambiguity by letting you look at the same state from another
angle instead of reading a numeric `|r|` fallback — which is the whole reason page `04Bloch3d`
exists as a companion to the fixed 2D view, rather than a replacement for it.

## 6.3 Live sliders as a state-space explorer

`BlochExplorerView` pairs `Bloch3DView` with live θ and φ sliders, rebuilding
`makeState(theta:phi:)` on every change. The two angles have asymmetric effects on what you can
measure: `P(0) = cos²(θ/2)` and `P(1) = sin²(θ/2)` depend **only on θ** — dragging φ slides the
state around its latitude (the circle of constant θ) without moving the measurement statistics
at all. A sweep across four values of θ, each paired with a fixed `φ = π/4`, makes both halves of
that claim checkable at once — the probabilities track θ, and `bloch.theta` recovers the same θ
back:

```swift
for theta in [0.0, Double.pi / 3, Double.pi / 2, 2 * Double.pi / 3] {
    let b = CircuitBuilder(qubitCount: 1)
    b.place(.ry(theta), qubits: [0], column: 0)
    b.place(.p(.pi / 4), qubits: [0], column: 1)
    let st = b.buildCircuit().run()
    print("theta", theta, "probs", st.probabilities, "bloch.theta", BlochVector(st, qubit: 0).theta)
}
```

```text
theta 0.0 probs [1.0, 0.0] bloch.theta 0.0
theta 1.0471975511965976 probs [0.7500000000000001, 0.24999999999999992] bloch.theta 1.0471975511965974
theta 1.5707963267948966 probs [0.5000000000000001, 0.4999999999999999] bloch.theta 1.5707963267948963
theta 2.0943951023931953 probs [0.2500000000000001, 0.75] bloch.theta 2.0943951023931953
```

And the mirror check — sweeping φ at a fixed θ = π/3 leaves the probabilities untouched while
`bloch.phi` tracks the input exactly:

```swift
for phi in [0.0, Double.pi / 4, Double.pi / 2, Double.pi] {
    let b = CircuitBuilder(qubitCount: 1)
    b.place(.ry(.pi / 3), qubits: [0], column: 0)
    b.place(.p(phi), qubits: [0], column: 1)
    let st = b.buildCircuit().run()
    print("phi", phi, "probs", st.probabilities[0], st.probabilities[1], "bloch.phi", BlochVector(st, qubit: 0).phi)
}
```

```text
phi 0.0 probs 0.7500000000000001 0.24999999999999992 bloch.phi 0.0
phi 0.7853981633974483 probs 0.7500000000000001 0.24999999999999992 bloch.phi 0.7853981633974483
phi 1.5707963267948966 probs 0.7500000000000001 0.24999999999999992 bloch.phi 1.5707963267948966
phi 1.5707963267948966 probs 0.7500000000000001 0.24999999999999992 bloch.phi 3.141592653589793
```

`0.750`/`0.250` on every row, for all four φ. The starting point `θ = π/3, φ = π/4` is the same
`|ψ⟩` Chapter 4 §4.4 built directly and read off as Pauli expectation values
`(0.6124, 0.6124, 0.5000)` — three chapters now converge on one state, reached three different
ways: expectation values (Chapter 4), a tilted-vector geometry argument (Chapter 5), and this
chapter's θ/φ sliders.

## Build it in the app

◐ Qubits → 1.

1. Arm **RY** (Rotation (θ = π/2) section), tap the empty cell on `q0`. Tap the tile, drag the
   θ slider to `1.047` (as close to π/3 as the three-decimal readout allows).
2. Arm **P**, tap the next empty cell on `q0`. Tap that tile, drag its slider to `0.785` (π/4).
3. Tap **Display** → **Final**. The `q0` card reads:

   ```text
   x +0.612  y +0.612  z +0.500
   θ 1.047 rad  φ 0.785 rad
   ```

   **The app prints θ and φ directly** — §6.1's parametrization is readable off the screen, not
   just implied by the arrow's position.

4. To see θ move: reopen the RY tile, drag it to `1.571` (π/2), leave P at `0.785`, reopen
   **Display**. The card now reads `θ 1.571 rad` with the same `φ 0.785 rad`, and the State
   Vector panel's `p=` values shift from `0.750/0.250` to `0.500/0.500` — θ alone carries the
   measurement statistics, exactly as §6.3 derived.
5. To see φ move independently: put RY back to `1.047`, instead drag the P tile to `3.142` (π).
   Reopen Display: `θ 1.047 rad` is unchanged, `φ` moves to `3.142 rad`, and the State Vector
   panel's `p=` values are still `0.750/0.250` — φ alone, no effect on what a measurement would
   show.
6. **Steps** mode (`Start` → `Col 1` → `Col 2`) walks the same trajectory one gate at a time:
   `Start` sits at the `|0⟩` pole; `Col 1` (after RY) swings out to `θ ≈ 1.047 rad` at `φ = 0`,
   since a real amplitude vector puts it on the prime meridian; `Col 2` (after P) holds that same
   θ and rotates purely in azimuth to `φ ≈ 0.785 rad` — this is the app's substitute for
   animating the arrow as a slider moves.

Two things stay genuinely out of reach, not just inconvenient:

- **No rotatable camera.** Every card is `BlochSphereView`'s single fixed oblique projection
  (Chapter 5 §5.3); there is no orbit-camera view like `Bloch3DView`'s. A rotatable 3D Bloch view
  is an open item in `Docs/Todo.md`.
- **No live-while-dragging loop.** `BlochExplorerView`'s sliders redraw the sphere on every
  pixel of drag; the app's θ slider lives inside `ParameterPopover` on the circuit grid, and
  `Display` is a separate sheet — so a slider move is followed by closing the popover and
  reopening Display, not a single continuous gesture.

The θ slider also has no exact-entry field and only a three-decimal readout (`ParameterPopover`,
range `0...2π`), so steps 1–2 only approximate the code's exact `.pi / 3` and `.pi / 4` — close
enough that the app's rounded values match the code below to three decimals, not bit-for-bit.
The slider's range also means you can drag θ past π (see Try it yourself, question 2) — the
sphere still renders correctly, but the printed θ is no longer the raw slider value.

## Run it in code

Every snippet above was run with `RunCodeSnippet` against
`SwiftQiskitApp/SwiftQiskitApp/CircuitModel.swift`. The starting-state console readout, matching
page `04Bloch3d`'s own:

```swift
let initialTheta = Double.pi / 3
let initialPhi = Double.pi / 4
let psi = makeState(theta: initialTheta, phi: initialPhi)

print("Starting state:")
print(String(format: "  θ = %.3f rad (%.1f°), φ = %.3f rad (%.1f°)",
             initialTheta, initialTheta * 180 / .pi, initialPhi, initialPhi * 180 / .pi))
print("  α = ⟨0|ψ⟩ = \(psi[0])")
print("  β = ⟨1|ψ⟩ = \(psi[1])")
print(String(format: "  |α|² + |β|² = %.6f", psi[0].magnitudeSquared + psi[1].magnitudeSquared))
```

```text
Starting state:
  θ = 1.047 rad (60.0°), φ = 0.785 rad (45.0°)
  α = ⟨0|ψ⟩ = 0.8660254037844387
  β = ⟨1|ψ⟩ = 0.35355339059327373 + 0.3535533905932737i
  |α|² + |β|² = 1.000000
```

And the app-path check behind step 3 above, driving `CircuitBuilder` directly and formatting the
result exactly as `BlochSphereView` does:

```swift
let builder = CircuitBuilder(qubitCount: 1)
builder.place(.ry(initialTheta), qubits: [0], column: 0)
builder.place(.p(initialPhi), qubits: [0], column: 1)
let state = builder.buildCircuit().run()
let bloch = BlochVector(state, qubit: 0)
print(String(format: "App readout: x %+.3f  y %+.3f  z %+.3f\nθ %.3f rad  φ %.3f rad",
             bloch.x, bloch.y, bloch.z, bloch.theta, bloch.phi))
```

```text
App readout: x +0.612  y +0.612  z +0.500
θ 1.047 rad  φ 0.785 rad
```

Identical to what step 3 reads on the Display card.

## Try it yourself

1. What θ/φ gives `|+i⟩`?
   <details><summary>Answer</summary>θ = π/2, φ = π/2 — the equator, a quarter-turn from
   `|+⟩`.</details>

2. Drag the RY slider to `4.189` (≈ 4π/3, past π) and predict the Display readout before
   checking. Why doesn't the printed θ equal the raw slider value?
   <details><summary>Answer</summary>`RY(4.189)` produces the real amplitude pair
   `(cos(2.0945), sin(2.0945)) ≈ (-0.500, 0.866)` — a negative `|0⟩` amplitude. Global phase is
   unobservable, so this is the same physical state as `(0.500, -0.866)`, whose canonical θ/φ
   representation (real, non-negative α) is θ = acos(-0.5·2 ... ) — concretely,
   `BlochVector` reports `x ≈ -0.866, y ≈ 0.000, z ≈ -0.500`, giving `θ ≈ 2.094 rad` (120°) and
   `φ = π`. The raw slider angle (240°) and the reported Bloch θ (120°, with a π phase folded
   into φ) describe the same point by two different conventions — `acos`/`atan2` always report
   the canonical one.</details>

3. Which of θ, φ would a histogram (`ResultsView`'s **Measure** button, Chapter 9) let you tell
   apart, and which would it hide completely?
   <details><summary>Answer</summary>Only θ shows up in measurement statistics —
   `P(0) = cos²(θ/2)`, `P(1) = sin²(θ/2)` — so a histogram lets you estimate θ from the split.
   φ has no effect on any computational-basis measurement outcome at all; two states differing
   only in φ produce statistically indistinguishable histograms, no matter how many shots you
   run.</details>

4. Why does the app never need to renormalize after any RY/P slider drag, no matter where the
   sliders land?
   <details><summary>Answer</summary>§6.1's identity: `cos²(θ/2) + sin²(θ/2) = 1` for every θ,
   and multiplying `|1⟩`'s amplitude by `e^{iφ}` (what `P` does) never changes a magnitude, since
   `|e^{iφ}| = 1`. Every slider position is already normalized by construction — there is
   nothing for `StateVector.normalize()` to correct.</details>

---
[← Chapter 5](05-BlochSphere2D.md) · [Contents](../../INTRODUCTION.md) · [Chapter 7 →](07-SingleQubitGates.md)
