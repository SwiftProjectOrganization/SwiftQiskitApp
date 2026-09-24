# Chapter 5 — The Bloch Sphere in 2D, and Its Projections

> A qubit's state drawn as a point on a sphere: the six canonical states, a general tilted
> state, and the x–y/z–y plane projections that make a 2D drawing of a 3D object legible.

| | |
|---|---|
| Playground page | [`02Bloch2d`](../../../SwiftQiskit/PlaygroundDocs/02BLOCH2DHELP.md), [`03Bloch2dProjection`](../../../SwiftQiskit/PlaygroundDocs/03BLOCH2DPROJECTIONHELP.md) |
| In the app | ◐ — the **Display** button draws each qubit's 2D Bloch sphere; the app has no separate x–y/z–y projection panes |
| Library APIs | `BlochVector` (single-qubit case), `BlochSphereView` |
| Prerequisites | Chapters 3, 4 |

## 5.1 Why a qubit fits on a sphere

A single qubit's state looks, on paper, like it should need four real numbers: two complex
amplitudes, each with a real and imaginary part. It doesn't. Normalization (Chapter 2 §2.7)
removes one degree of freedom — the amplitudes must satisfy `|α|² + |β|² = 1`, a single
constraint. Global phase removes a second: multiplying the whole state by any `e^{iγ}` leaves
every `|amplitude|²` unchanged, so no measurement can ever detect it — §5.2 below makes this
precise for the coordinates this chapter builds. Four real numbers, minus two constraints, leaves
two — and a surface parametrized by two independent numbers, sitting at a fixed distance from an
origin, is a sphere. That is not a metaphor; it is the entire content of this chapter, spelled out
coordinate by coordinate.

The three numbers Chapter 4 §4.5 computed as bra–ket sandwiches — `⟨ψ|X|ψ⟩`, `⟨ψ|Y|ψ⟩`,
`⟨ψ|Z|ψ⟩` — are exactly the `x, y, z` this chapter plots, and the sphere they land on is the
**Bloch sphere**, the picture the rest of this book reasons with instead of columns of complex
numbers. Placing states on it pays off immediately: the six states every later chapter reaches
for by name sit at the six axis points (§5.2), gates become rotations of this same sphere
(Chapter 7), a hidden relative phase becomes a longitude that a second `H` can read as a latitude
(Chapter 8), and an entangled qubit's reduced state shows up as an arrow that no longer reaches
the surface at all (Chapter 12). The one cost this chapter has to pay up front: a sphere is a 3D
object, and a page — or an app's canvas — is not, so §5.4 closes with what a 2D drawing of it
necessarily throws away.

| § | What happens |
|---|---|
| 5.2 | The six axis states named and placed: `\|0⟩ \|1⟩ \|+⟩ \|−⟩ \|+i⟩ \|−i⟩` |
| 5.3 | A general, off-axis state, reached by direction cosines |
| 5.4 | Two projections of the same sphere onto a flat page, and what each one drops |

## 5.2 The six canonical states on the sphere

Chapter 4 §4.5 showed that the three Pauli expectation values `⟨ψ|X|ψ⟩`, `⟨ψ|Y|ψ⟩`, `⟨ψ|Z|ψ⟩`
of a single-qubit state `|ψ⟩ = α|0⟩ + β|1⟩` are three real numbers. This chapter gives them
names and a picture: they are the coordinates

```text
x = 2·Re(ᾱβ)
y = 2·Im(ᾱβ)
z = |α|² − |β|²
```

of a point on the unit sphere — the **Bloch sphere**. `BlochVector` (`SwiftQiskitApp/BlochVector.swift`)
computes exactly this triple from a state's amplitudes, with no dependence on `Bra`/`Matrix`
at all; it is the same formula Chapter 4 verified against the bra–ket computation to the last
printed digit.

Two states that differ only by an unobservable global phase `e^{iγ}` land on the *same* point:
multiplying both `α` and `β` by `e^{iγ}` leaves `ᾱβ` unchanged (the phases cancel:
`(e^{-iγ}ᾱ)(e^{iγ}β) = ᾱβ`) and leaves `|α|²`, `|β|²` unchanged outright. The sphere shows
exactly the physically distinguishable content of a state — nothing more, nothing less. For a
normalized state, `x² + y² + z² = (|α|² + |β|²)² = 1`, so every pure state sits exactly on the
surface, never inside it.

Two spherical angles read the same point a second way: `θ = acos(z)` (the polar angle from the
`|0⟩` pole) and `φ = atan2(y, x)` (the azimuth in the x–y plane). `BlochVector` exposes both
directly as `theta` and `phi`.

The six states that sit exactly on the axes:

| State | Bloch vector | Location |
|---|---|---|
| \|0⟩ | (0, 0, +1) | north pole |
| \|1⟩ | (0, 0, −1) | south pole |
| \|+⟩ = (\|0⟩ + \|1⟩)/√2 | (+1, 0, 0) | +x axis |
| \|−⟩ = (\|0⟩ − \|1⟩)/√2 | (−1, 0, 0) | −x axis |
| \|+i⟩ = (\|0⟩ + i\|1⟩)/√2 | (0, +1, 0) | +y axis |
| \|−i⟩ = (\|0⟩ − i\|1⟩)/√2 | (0, −1, 0) | −y axis |

Building each with a circuit (`|0⟩` empty, `|1⟩` via `x(0)`, `|+⟩` via `h(0)`, `|−⟩` via
`h(0); z(0)`, `|+i⟩` via `h(0); s(0)`, `|−i⟩` via `h(0); sdg(0)` — `s`/`sdg` is the phase gate
`S = √Z` and its inverse, Chapter 7's territory) and reading off `BlochVector`:

```swift
import SwiftQiskit

let zero = QuantumCircuit(qubits: 1)
let one = QuantumCircuit(qubits: 1); one.x(0)
let plus = QuantumCircuit(qubits: 1); plus.h(0)
let minus = QuantumCircuit(qubits: 1); minus.h(0); minus.z(0)
let plusI = QuantumCircuit(qubits: 1); plusI.h(0); plusI.s(0)
let minusI = QuantumCircuit(qubits: 1); minusI.h(0); minusI.sdg(0)

let states: [(name: String, bloch: BlochVector)] = [
    ("|0⟩", BlochVector(zero.run())),
    ("|1⟩", BlochVector(one.run())),
    ("|+⟩", BlochVector(plus.run())),
    ("|−⟩", BlochVector(minus.run())),
    ("|+i⟩", BlochVector(plusI.run())),
    ("|−i⟩", BlochVector(minusI.run()))
]

for s in states {
    let b = s.bloch
    print(String(format: "%@  x %+.3f  y %+.3f  z %+.3f  (θ %.3f, φ %.3f)",
                 s.name, b.x, b.y, b.z, b.theta, b.phi))
}
```

```text
|0⟩  x +0.000  y +0.000  z +1.000  (θ 0.000, φ 0.000)
|1⟩  x +0.000  y +0.000  z -1.000  (θ 3.142, φ 0.000)
|+⟩  x +1.000  y +0.000  z +0.000  (θ 1.571, φ 0.000)
|−⟩  x -1.000  y +0.000  z +0.000  (θ 1.571, φ 3.142)
|+i⟩  x +0.000  y +1.000  z +0.000  (θ 1.571, φ 1.571)
|−i⟩  x +0.000  y -1.000  z +0.000  (θ 1.571, φ -1.571)
```

Reading notes:

- **θ 3.142 is π, θ 1.571 is π/2** — the poles sit at θ = 0 and θ = π; the equator at θ = π/2.
- **φ = 0.000 at both poles is a convention, not information** — with x = y = 0 the azimuth is
  undefined, and `atan2(0, 0)` returns 0 by definition. Only equatorial (and more generally
  non-polar) states have a meaningful φ, like `|−⟩`'s φ = π.
- **The zeros are exact, the ±1s carry ~1e-16** — `H` fills both amplitudes with the same
  double, `±1/√2`, so `z = |α|² − |β|²` for `|±⟩` subtracts two identical doubles to exactly
  zero, and `y = 2·Im(ᾱβ)` of real amplitudes is exactly zero too. Only the axis entries
  themselves round: `2·(1/√2)²` is `0.9999999999999998`, the same ~1e-16 Chapter 4 measured on
  `H†H` — invisible at three decimals.

## 5.3 A general tilted state

Most states aren't on an axis. Take a Bloch vector making a 45° angle with the x-axis and a 60°
angle with the y-axis. The components of a unit vector are its direction cosines, so:

```text
x = cos 45° = √2/2 ≈ 0.7071
y = cos 60° = 1/2
z = √(1 − x² − y²) = √(1 − 3/4) = 1/2      (choosing the upper hemisphere)
```

which happens to also put the vector 60° from the z-axis: `θ = acos(z) = 60°`,
`φ = atan2(y, x) ≈ 35.264°`. Every single-qubit state can be written, up to the same
unobservable global phase §5.2 dropped, as

```text
|ψ⟩ = cos(θ/2)|0⟩ + e^{iφ}·sin(θ/2)|1⟩
```

(Chapter 6 derives this fully; here it is only a way to build a state with a genuinely tilted
Bloch vector.) Substituting θ = 60°, φ ≈ 35.264° gives
`|ψ⟩ ≈ 0.8660|0⟩ + (0.4082 + 0.2887i)|1⟩` — built directly from amplitudes below, then again
from gates, to check they agree:

```swift
let theta = Double.pi / 3                       // 60°
let phi = atan2(0.5, sqrt(2) / 2)                // ≈ 35.264°

let alpha = Complex(cos(theta / 2))
let beta = Complex(sin(theta / 2) * cos(phi), sin(theta / 2) * sin(phi))
let psi = StateVector([alpha, beta])

let bloch = BlochVector(psi)
print(bloch.x, bloch.y, bloch.z)
print(acos(bloch.x) * 180 / .pi, acos(bloch.y) * 180 / .pi, acos(bloch.z) * 180 / .pi)

let builder = CircuitBuilder(qubitCount: 1)
builder.place(.ry(theta), qubits: [0], column: 0)
builder.place(.p(phi), qubits: [0], column: 1)
let state = builder.buildCircuit().run()
print(state.amplitudes, state.probabilities)
let blochFromGates = BlochVector(state, qubit: 0)
print(blochFromGates.x, blochFromGates.y, blochFromGates.z, blochFromGates.theta, blochFromGates.phi)
```

```text
0.7071067811865475 0.4999999999999999 0.5000000000000002
45.00000000000001 60.00000000000001 59.999999999999986
[0.8660254037844387, 0.40824829046386296 + 0.2886751345948128i] [0.7500000000000001, 0.24999999999999992]
0.7071067811865475 0.4999999999999999 0.5000000000000002 1.0471975511965974 0.6154797086703873
```

The recovered angles land back on 45.0°/60.0°/60.0° to within ~1e-14 — the round trip closing
(build ψ from θ, φ → recover x, y, z → recover the angles). Note that
`RY(θ); P(φ)` reproduces the hand-built amplitudes exactly, and its Bloch `x`, `y`, `z` agree
with the direct construction to the last printed digit; `blochFromGates.phi` prints as
`0.6154797086703873` rather than `atan2(0.5, √2/2)`'s literal value because `atan2(y, x)` is
being fed the *recovered* `y`, `x` — algebraically the same φ, arrived at from the other
direction. Also worth noting: `P(0)` and `P(1)` depend only on θ, never on φ — sliding φ moves
the state around its latitude (the equator at that θ) without changing the measurement
statistics at all.

## 5.4 Reading a 3D sphere in 2D: the two projections

`03Bloch2dProjection` draws this tilted state's sphere alongside two **plane projections**: an
orthographic projection onto a coordinate plane simply drops the out-of-plane component and
draws the remaining two as a point inside a unit circle, with `r = hypot(h, v)` the projected
vector's length.

- **x–y plane (view from +z)** — drops z. `r² = x² + y² = 1 − z²`, so the shortfall from the
  unit circle is exactly the dropped z-component: here `r ≈ 0.866`, ` z ≈ 0.5`.
- **z–y plane (view from +x)** — drops x. `r² = 1 − x²`, shortfall `r ≈ 0.707` against the
  dropped `x ≈ 0.707`.

The x–y panel additionally flips its vertical axis (`verticalPointsDown: true`) — it's the view
looking down from the `|0⟩` pole along `−z`, and keeping the same viewer-facing convention as the
main sphere (`x` toward the viewer) means `x` must point *down* on that particular canvas. A
projected arrow shorter than the unit circle is expected any time the state points out of that
plane; only a state lying exactly in the plane reaches the edge.

The app draws neither panel. Instead `BlochSphereView` (`SwiftQiskitApp/BlochSphereView.swift`)
renders a single **oblique** projection of the whole sphere at once: `y` maps straight to
canvas-right, `z` to canvas-up, and `x` — the axis pointing at the viewer — is foreshortened by
`0.5·√0.5 ≈ 0.354` toward the lower-left:

```text
canvas-right = y − x·0.354
canvas-up    = z − x·0.354
```

So `|+⟩` (pure +x) draws as a short arrow toward the lower-left, `|−⟩` toward the upper-right,
and the poles straight up/down at full length — one 2D picture standing in for both of
`03Bloch2dProjection`'s panes, at the cost that a short arrow is ambiguous between "points
mostly toward the viewer" and "is a mixed/entangled reduced state with `|r| < 1`" (Chapter 12
covers the latter) until you read the numeric readout underneath, which always states `|r|`
explicitly whenever it drops below 1.

## Build it in the app

◐ Set **Qubits** to 6 and build all six canonical states side by side, one per wire, so
**Display** shows the whole gallery in one grid — the app's version of `02Bloch2d`'s 2×3 gallery:

1. Leave `q0` empty (that wire stays `|0⟩`).
2. Arm **X** (Pauli / Hadamard section), tap `q1`'s column-0 cell.
3. Arm **H**, tap `q2`'s column-0 cell.
4. Arm **H**, tap `q3`'s column-0 cell; then arm **Z**, tap `q3`'s column-1 cell.
5. Arm **H**, tap `q4`'s column-0 cell; then arm **S** (Phase section), tap `q4`'s column-1 cell.
6. Arm **H**, tap `q5`'s column-0 cell; then arm **S†**, tap `q5`'s column-1 cell.
7. Tap **Display** → **Final**. Six sphere cards appear, labeled `q0`–`q5`:

```text
q0  x +0.000  y +0.000  z +1.000        q3  x -1.000  y +0.000  z +0.000
    θ 0.000 rad  φ 0.000 rad                θ 1.571 rad  φ 3.142 rad
q1  x +0.000  y +0.000  z -1.000        q4  x +0.000  y +1.000  z +0.000
    θ 3.142 rad  φ 0.000 rad                θ 1.571 rad  φ 1.571 rad
q2  x +1.000  y +0.000  z +0.000        q5  x +0.000  y -1.000  z +0.000
    θ 1.571 rad  φ 0.000 rad                θ 1.571 rad  φ -1.571 rad
```

— identical to §5.2's six numbers, read off six cards at once instead of six console lines. (If
you'd rather match `02Bloch2d` exactly, one wire at a time: drop **Qubits** to 1, arm/tap the
gates for one state, **Display** → **Final**, **Clear**, repeat for the next state.)

The subtlety worth naming, not hiding: `BlochDisplayView` calls `BlochVector(state, qubit:)`
(`SwiftQiskitApp/BlochVector.swift`), the *reduced* single-qubit vector for one wire of a
6-qubit state — a partial trace over the other five. Every card above prints no `|r|` line
because every one of these six wires is a genuinely unentangled product state, so the reduced
vector still has length exactly 1; the same machinery gives `|r| = 0` for a wire of an entangled
Bell state (Chapter 12).

What's still missing: no separate x–y/z–y projection panes — the single oblique view of §5.4 is
what's on screen instead — and no way to enter a Bloch vector's coordinates directly; every state
still has to be reached by placing gates.

## Run it in code

Both snippets above were run with `RunCodeSnippet` against
`SwiftQiskitApp/SwiftQiskitApp/CircuitModel.swift`; the printed output beneath each one is the
real result. The app-path claim in step 7 was separately verified by driving `CircuitBuilder`
directly, exercising the exact gate sequence the steps describe:

```swift
let builder = CircuitBuilder(qubitCount: 6)
builder.place(.x, qubits: [1], column: 0)
builder.place(.h, qubits: [2], column: 0)
builder.place(.h, qubits: [3], column: 0)
builder.place(.z, qubits: [3], column: 1)
builder.place(.h, qubits: [4], column: 0)
builder.place(.s, qubits: [4], column: 1)
builder.place(.h, qubits: [5], column: 0)
builder.place(.sdg, qubits: [5], column: 1)

let state = builder.buildCircuit().run()
for q in 0..<6 {
    let b = BlochVector(state, qubit: q)
    var text = String(format: "q%d  x %+.3f  y %+.3f  z %+.3f\nθ %.3f rad  φ %.3f rad",
                       q, b.x, b.y, b.z, b.theta, b.phi)
    if abs(b.magnitude - 1) > 1e-3 { text += String(format: "\n|r| %.3f", b.magnitude) }
    print(text)
}
```

```text
q0  x +0.000  y +0.000  z +1.000
θ 0.000 rad  φ 0.000 rad
q1  x +0.000  y +0.000  z -1.000
θ 3.142 rad  φ 0.000 rad
q2  x +1.000  y +0.000  z +0.000
θ 1.571 rad  φ 0.000 rad
q3  x -1.000  y +0.000  z +0.000
θ 1.571 rad  φ 3.142 rad
q4  x +0.000  y +1.000  z +0.000
θ 1.571 rad  φ 1.571 rad
q5  x +0.000  y -1.000  z +0.000
θ 1.571 rad  φ -1.571 rad
```

No `|r|` line on any card, confirming every reduced vector comes out at full length, as §5.2's
per-qubit numbers predicted.

## Try it yourself

1. `02Bloch2d`'s gallery reaches `|+i⟩` with `H` then `S`, and `|−i⟩` with `H` then `S†`. Predict
   the sign of `y` for each before checking §5.2's table.
   <details><summary>Answer</summary>`S` (√Z) advances the relative phase of `|1⟩` by +90°,
   rotating `|+⟩`'s point counterclockwise from `+x` to `+y`; `S†` rotates the other way, to
   `−y`. Table: `|+i⟩ → +y`, `|−i⟩ → −y`, confirmed by the `02Bloch2d` run above.</details>

2. Place `RY(π/4)` in the app and predict where the arrow lands before opening Display.
   <details><summary>Answer</summary>It sits at polar angle π/4 from the north pole, on the
   x–z great circle (φ = 0, since `RY` alone gives a real amplitude vector) — see Chapter 6 for
   the full θ/φ parametrization.</details>

3. `h(0); z(0)` and `h(0); rz(.pi, 0)` are two different gate sequences. Do they land on the same
   Bloch point?
   <details><summary>Answer</summary>Yes — `RZ(π)` and `Z` both multiply `|1⟩`'s amplitude by
   `−1` up to an overall global phase, and §5.2 established that Bloch coordinates are invariant
   under a global phase. Both circuits land on `|−⟩`, (−1, 0, 0), even though `RZ(π)`'s raw
   amplitudes carry an extra phase factor that `Z`'s don't.</details>

4. Why is a short arrow on the app's single oblique sphere ambiguous, and which part of the
   on-screen readout resolves it?
   <details><summary>Answer</summary>A short *projected* arrow can mean the state points mostly
   toward the viewer (a pure state near the `+x`/`−x` axis, foreshortened by 0.354) or that the
   reduced vector is genuinely shorter than 1 (an entangled qubit, Chapter 12). `BlochSphereView`
   only prints an explicit `|r| %.3f` line when `|magnitude − 1| > 1e-3` — its presence or
   absence is what tells the two cases apart, not the arrow's on-screen length.</details>

---
[← Chapter 4](04-DiracNotation.md) · [Contents](../../INTRODUCTION.md) · [Chapter 6 →](06-BlochSphere3D.md)
