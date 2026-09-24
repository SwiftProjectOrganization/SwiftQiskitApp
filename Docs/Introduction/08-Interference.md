# Chapter 8 — Phase, Interference, and Why Z Hides

> The book's hinge chapter: why a phase flip is invisible in probabilities yet completely real,
> and how a second `H` turns that hidden phase into an observable bit flip through interference.

| | |
|---|---|
| Playground page | [`05Gates`](../../../SwiftQiskit/PlaygroundDocs/05GATESHELP.md) §4, [`01Qubits`](../../../SwiftQiskit/PlaygroundDocs/01QUBITSHELP.md) (`circuit2`) |
| In the app | ● — `H;Z`, `H;Z;H`, the continuous `H;P(φ);H` fringe, and a 3D Bloch orbit are all placeable/viewable |
| Library APIs | `QuantumCircuit.h/z/p/rz`, `.amplitudes` vs `.probabilities`, `BlochVector` |
| Prerequisites | Chapters 6, 7 |

## 8.1 Why interference matters

Four earlier chapters have been quietly deferring to this one. Chapter 2 §2.4 split a complex
number into magnitude and phase and noted that phase "never touches a probability" — without
saying why that might matter. Chapter 3 turned up a sign it could describe but not yet explain.
Chapter 5 §5.2 showed a global phase vanishing from the Bloch sphere without a trace. Chapter 7
§7.4 applied `Z` to `|0⟩` and found nothing happened at all. This chapter is where those four
loose threads join into one mechanism: **interference**.

The mechanism is physical, not merely notational, and it has a one-sentence version: split a
path in two, let one branch pick up a phase the other doesn't, recombine the two branches, and
—because amplitudes **add together before they are squared into a probability**— the phase
that was invisible a moment ago now decides the outcome. That is the two-slit experiment in one
sentence, and `H; Z; H` (§8.4 below) is its smallest possible quantum-computing instance: `H`
splits, `Z` marks one branch, the second `H` recombines.

The question this chapter answers, precisely, is when a phase survives that recombination and
when it doesn't. A phase attached to *every* amplitude in a state equally — a **global**
phase — is nothing: no measurement, and no further gate, can ever recover it. A phase attached
to *one* amplitude out of several — a **relative** phase — is potentially everything, and
whether it actually shows up in a probability depends entirely on what gate comes next. Holding
onto that distinction is the single idea the rest of the chapter is organized around.

By the end of §8.7, the reader should be able to: predict, without running anything, whether two
circuits differing only by a phase gate will produce the same histogram or different ones;
explain why `Z` alone is unmeasurable but `H;Z;H` is a deterministic bit flip; read a relative
phase as an azimuth and a measurement probability as a latitude on the Bloch sphere, and name
`H` as the gate that trades one for the other; and recognize the shape — mark a branch with a
phase, then recombine — that Chapters 13–15's Deutsch, Deutsch–Jozsa, and Grover algorithms all
repeat at larger scale.

The sections ahead trace that shape from its quietest form to its most consequential:

| § | What happens |
|---|---|
| 8.2 | `Z` on `\|0⟩`: nothing to see, and precisely why not |
| 8.3 | `Z` after `H`: the state genuinely changes, the probabilities don't |
| 8.4 | A second `H`: cancellation and reinforcement turn the hidden phase into a bit |
| 8.5 | `P(φ)` swept continuously: a full interference fringe, `p₀ = cos²(φ/2)` |
| 8.6 | The same story read geometrically, orbiting a rotatable 3D sphere |
| 8.7 | The one real number a measurement destroys, and how a basis change gets it back |
| 8.8 | One phase mark made certain by interference — a two-qubit rehearsal for Grover |

## 8.2 Z alone on \|0⟩: nothing observable

`Z = diag(1, −1)` leaves `|0⟩` alone entirely: `Z|0⟩ = |0⟩` exactly, amplitudes `[1.0, 0.0]`,
probabilities `[1.0, 0.0]` — indistinguishable from an empty circuit. The reason is worth naming
precisely, because the rest of the chapter is built on the distinction: with only one non-zero
amplitude, any sign or phase attached to it is a **global** phase — a factor multiplying *every*
amplitude in the state equally. A global phase is invisible to every measurement (probabilities
depend on `|amplitude|²`, and `|e^{iγ}| = 1` for any γ) and even to the Bloch sphere (Chapter 5
§5.2) — it is not a special property of `Z`, it is a fact about single-branch states in general.
Chapter 7 §7.4 showed the same emptiness; this chapter is about what happens once there is a
*second* branch to compare against.

A **relative** phase is different: a sign or angle attached to one amplitude but not another,
which is what `Z` produces once a state has two non-zero amplitudes. Whether a relative phase is
visible depends entirely on what happens next — that is §8.3 and §8.4's whole story. A direct
check that global phase really vanishes without a trace: `H;Z;H;Z;H` (five gates — §8.4's
`H;Z;H` "flip", done twice, with a trailing `H`) lands on `−|−⟩`, not `|−⟩` — an extra global
minus sign — yet its Bloch card is bit-for-bit identical to plain `|−⟩`'s:

```text
|->        [0.7071067811865475, -0.7071067811865475]   x -1.0000  y +0.0000  z +0.0000
-|->       [-0.7071067811865474, 0.7071067811865474]   x -1.0000  y +0.0000  z +0.0000
```

## 8.3 Z after H: a real amplitude change, an unchanged probability

`H` first reaches `|+⟩ = (|0⟩+|1⟩)/√2`, genuinely superposed: both amplitudes are `0.7071…`,
probabilities `[0.5, 0.5]`. Applying `Z` next flips the second amplitude's sign —
`[0.7071067811865475, -0.7071067811865475]` — landing on `|−⟩ = (|0⟩−|1⟩)/√2`. `|+⟩` and `|−⟩`
are **orthogonal states**, as different as two states can be, yet `H;Z`'s probabilities are
still `[0.4999999999999999, 0.4999999999999999]` — identical to plain `H`'s, because
`|−0.7071…|² = |+0.7071…|²`. The sign is completely real (§8.4 shows exactly what it changes),
but no measurement made right at this point can tell `|+⟩` from `|−⟩` apart.

The Bloch sphere makes the "same statistics, different state" claim precise: both points sit on
the sphere's equator (`z = 0`, so both measurement outcomes are equally likely), but at opposite
azimuths — `φ = 0` for `|+⟩`, `φ = π` for `|−⟩`. Same latitude, opposite longitude.

## 8.4 The second H: interference makes the phase visible

The mechanism is one line: `H` sends amplitudes `(a, b)` to `((a+b)/√2, (a−b)/√2)` —
**amplitudes add together, and only afterward get squared into a probability.** That single fact
is the entire chapter. Follow both branches from `|0⟩` (`a=1, b=0`):

- `H` alone: `(1/√2, 1/√2)` — the two new amplitudes agree in sign.
- `H` then `Z`: `(1/√2, −1/√2)` — `Z` flips the second one's sign, invisibly (§8.3).
- A second `H` recombines `(1/√2, −1/√2)` into `((1/√2 − 1/√2)/√2, (1/√2 + 1/√2)/√2) = (0, 1)`.

The `|0⟩`-amplitude's two contributions (`1/√2` and `−1/√2`) now **cancel** — destructive
interference — while the `|1⟩`-amplitude's contributions (`1/√2` and `1/√2`) **reinforce** —
constructive interference. Verified:

```text
H;Z;H probabilities: [0.0, 0.9999999999999996]
```

A deterministic bit flip, recovered entirely from a phase that a moment ago was unmeasurable —
the same construction `01Qubits`'s `circuit2` used, and the mechanism behind every two-slit
interference pattern: split, let one path pick up a phase, recombine, and the phase becomes a
probability.

## 8.5 The fringe: any phase, not just π

`Z` is one point (φ = π) on a continuous family. Replacing it with the general phase gate
`P(φ) = diag(1, e^{iφ})` and sweeping φ traces out a full interference fringe,
`P(0) = cos²(φ/2)`, matching the textbook two-path formula to every printed digit:

```text
phi     p0      cos^2(phi/2)
0.0000  1.0000  1.0000
0.7854  0.8536  0.8536
1.5708  0.5000  0.5000
2.3562  0.1464  0.1464
3.1416  0.0000  0.0000
3.9270  0.1464  0.1464
4.7124  0.5000  0.5000
5.4978  0.8536  0.8536
6.2832  1.0000  1.0000
```

φ = π reproduces §8.4's `H;Z;H` exactly (`P(π) ≡ Z`, Chapter 7 §7.7); φ = π/2 and π/4 land on the
fixed gates `S` and `T`, each one further tappable point on the same curve:

```text
H;S;H probabilities: [0.4999999999999998, 0.4999999999999998]
H;T;H probabilities: [0.8535533905932735, 0.14644660940672616]
```

**Global phase drops out of the fringe entirely.** `RZ(φ)` and `P(φ)` differ by a global phase
factor `e^{−iφ/2}` (Chapter 7 §7.8) — different raw amplitudes, but `H;RZ(φ);H` reproduces
`H;P(φ);H`'s probabilities to floating-point rounding, at every φ tested:

```text
phi 0.7854  P probs [0.8536, 0.1464]  RZ probs [0.8536, 0.1464]   (agree to ~2e-16)
phi 1.5708  P probs [0.5000, 0.5000]  RZ probs [0.5000, 0.5000]   (agree to ~2e-16)
```

This is the sharp version of §8.2's distinction: relative phase is everything interference can
use; global phase is nothing it can, no matter how the recombination is arranged.

## 8.6 Reading interference off the sphere (in 3D)

Geometrically, `H` is a π rotation about the sphere's `(x+z)/√2` axis, and the visible effect of
that rotation is that **`H` swaps the x- and z-coordinates (and flips the sign of y)**:

```text
state              before H                                after H
|0>                x +0.000  y +0.000  z +1.000     →      x +1.000  y +0.000  z +0.000
H;Z -> |->         x -1.000  y +0.000  z +0.000     →      x +0.000  y +0.000  z -1.000
```

Relative phase lives on the sphere's equator — the x/y plane, read off as the azimuth φ; a
measurement probability lives on the z-axis — the latitude, read off as θ. `H` is precisely the
gate that trades one for the other, which is why it is the universal recombiner: whatever phase
the equator was holding becomes, after one more `H`, a latitude a measurement can read. The
identity is exact, not approximate: `P(0) = (1 + x)/2`, where `x` is the Bloch x-coordinate of
the state *immediately before* the final `H`. Reading down the fringe table in §8.5 against the
pre-final-`H` x-coordinates confirms it at every sampled φ (φ = π/4: `x = 0.7071` → `(1+0.7071)/2
= 0.8536`, matching `p0` exactly; φ = π: `x = −1.0000` → `0.0000`, also exact).

This is also the chapter where a 3D Bloch view earns its keep. `BlochSphereView`'s fixed oblique
projection (Chapter 5 §5.4) foreshortens the x-axis by a factor of `0.5·√0.5 ≈ 0.354` — and x is
exactly the coordinate a relative phase moves. `Bloch3DSphereView` — the app's rotatable Display
mode, introduced in Chapter 6 §6.3 — orbits a real camera around the sphere instead: drag
until you are looking straight down the z-axis, and φ becomes a protractor reading with no
foreshortening at all, rather than a compressed sliver of the 2D card.

## 8.7 Why probabilities lose information amplitudes keep

A single-qubit state carries two independent real numbers, θ and φ (Chapter 6 §6.2). The
probability pair `(cos²(θ/2), sin²(θ/2))` is a function of θ alone — one real number. Exactly one
real number of information is destroyed by measuring in the computational basis, and it is
always φ, never θ: this is §6.4's derivation restated as the reason `Z`, `P(φ)`, and `RZ(φ)`
alone are all unmeasurable, and the reason a second `H` is needed to get any of φ back.

Recovering φ requires **changing basis before measuring**, not just measuring harder or more
often. Appending `H` immediately before **Measure** turns a computational-basis (Z-basis)
measurement into an X-basis one, and `|+⟩`/`|−⟩` — indistinguishable in the Z basis at any shot
count — become perfectly distinguishable in the X basis:

```text
|+> Z-basis, 1000 shots: ["0": 526, "1": 474]      |+> X-basis, 1000 shots: ["0": 1000]
|-> Z-basis, 1000 shots: ["0": 503, "1": 497]      |-> X-basis, 1000 shots: ["1": 1000]
```

Both Z-basis splits are the expected roughly-even jitter (Chapter 9's subject); re-running either
will land close to, but not exactly on, 500/500. This one-basis-at-a-time limitation is exactly
what Chapter 22 (tomography) generalizes: no single measurement basis ever recovers a fully
unknown state's phase, but three well-chosen ones together do.

## 8.8 Interference as the engine of algorithms

Interference is not just a curiosity about single qubits — it is the mechanism every quantum
speedup in this book runs on. A minimal two-qubit teaser, using `CZ` (not in the palette,
decomposed as `H` on the target, `CX`, `H` on the target — Chapter 7's ◐-style decomposition):
uniform superposition, then `CZ` phase-marks `|11⟩` alone. That mark is completely invisible to
measurement on its own — every outcome is still equally likely:

```text
oracle only probabilities: [0.25, 0.25, 0.25, 0.25]
```

Add a diffuser (`Z` on both qubits, then `CZ` again, sandwiched between two more rounds of `H`)
and the picture changes completely — every branch's amplitude interferes, and all of it piles
onto the one marked branch:

```text
oracle + diffuser amplitudes:    [0.0, 0.0, 0.0, 0.9999999999999992]
oracle + diffuser probabilities: [0.0, 0.0, 0.0, 0.9999999999999984]
```

One phase mark, invisible alone, made certain by interference — a two-qubit rehearsal for
Chapters 13–15's Deutsch, Deutsch–Jozsa, and Grover algorithms, all of which are this same trick
at larger scale.

## Build it in the app

● Every step below starts from **Clear** with **Qubits: 1** unless noted.

1. **Z alone** — arm **Z** (Pauli / Hadamard section), tap `q0`. State Vector panel:
   `|0⟩: 1.0  (p=1.000)` — indistinguishable from an empty circuit. Tap **Display → Final**:
   card unchanged at the `|0⟩` pole, `z +1.000`.
2. **H then Z** — Clear, **H** at column 0, arm **Z**, tap column 1. Panel: `|0⟩: 0.707…
   (p=0.500)`, `|1⟩: -0.707…  (p=0.500)` — same `p=` as plain `H`, a minus sign on the second
   amplitude. **Display → Final**: `x −1.000  y +0.000  z +0.000` — same latitude as `H` alone,
   opposite azimuth.
3. **H, Z, H** — add a second **H** at column 2. Panel collapses to one row: `|1⟩:
   0.9999999999999998  (p=1.000)`. **Display → Steps**: `Start` at the `|0⟩` pole (`z +1.000`),
   `Col 1` (after `H`) at `x +1.000`, `Col 2` (after `Z`) at `x −1.000`, `Col 3` (after the
   second `H`) at the south pole, `z −1.000` — the whole phase-into-bit-flip trajectory.
4. **The fringe by fixed gates** — Clear, **H** at column 0. One at a time (Clear the tile and
   re-place to swap gates), add at column 1 then a final **H** at column 2: **T** (Phase
   section) → panel `p=0.854/0.146`; **S** → `p=0.500/0.500`; **Z** → `p=0.000/1.000` — three
   points on the same curve, all tappable without a slider.
5. **The fringe by slider, in 3D** — Clear, **H** at column 0, arm **P** (Rotation section — it
   arms at θ = π/2), tap column 1. Tap **Display**, select the **3D** segment: the sphere is now
   rotatable. Drag the canvas to orbit until you are looking straight down from the `|0⟩` pole —
   φ becomes directly readable as an angle around the rim, with none of the 2D card's
   foreshortening. Tap the placed **P** tile and drag θ to `0.785` (≈ π/4): reopen **Display →
   3D** and the arrow has swung a further eighth of a turn around the equator.
6. **The recombination, in 3D** — with **H;P(0.785)** still in place, add a final **H** at
   column 2. Reopen **Display → 3D**: the arrow has tipped from the equator toward the `|1⟩`
   pole — the same x-to-z axis swap §8.5 derives, now watched from an angle the 2D card can't
   show. Drag θ to `3.142` (≈ π) instead and reopen: the arrow lands almost exactly on the south
   pole, matching step 3's `Z` result.
7. **Reading a phase: X-basis measurement** — Clear, **H** at column 0 (this is `|+⟩`). Set
   **Shots: 1000**, tap **Measure**: histogram splits roughly evenly. Now add a second **H** at
   column 1 and **Measure** again: the histogram collapses to all-`"0"`. Clear and rebuild as
   **H** then **Z** (`|−⟩`) — Z-basis measurement is again roughly even, but adding a final **H**
   before **Measure** collapses it to all-`"1"` — the opposite outcome from `|+⟩`'s, recovered
   only once the basis is changed by hand.
8. **Two-qubit teaser** — **Qubits: 2**. Arm **H**, tap `q0` and `q1` in column 0. Build `CZ` by
   hand: arm **H** (Multi-qubit gates aren't in the palette as `CZ`, so this is the
   decomposition), tap `q1`'s column-1 cell; arm **CX** (Multi-qubit section), tap `q0` then `q1`
   in column 2; arm **H**, tap `q1`'s column-3 cell. Panel: flat `p=0.250` on all four rows — the
   phase mark is invisible. Now add the diffuser: **Z** on `q0` and `q1` at column 4, then repeat
   the `H`/`CX`/`H` triple for `CZ` at columns 5–7, then **H** on both qubits at column 8. Panel
   collapses to `|11⟩: …  (p=1.000)`.

Two genuine limits, not a missing-capability paragraph: `CZ` is not a palette gate, so every
teaser column above is a hand-built decomposition, not one tap; and there is no "measure in the
X basis" toggle — step 7's basis change is a real gate appended to the circuit before **Measure**,
not a setting.

## Run it in code

Every snippet below was run with `RunCodeSnippet` against
`SwiftQiskitApp/SwiftQiskitApp/CircuitModel.swift`.

```swift
import SwiftQiskit

let qcZ = QuantumCircuit(qubits: 1); qcZ.z(0)
print(qcZ.run().amplitudes, qcZ.run().probabilities)          // 1 — Z alone

let qcHZ = QuantumCircuit(qubits: 1); qcHZ.h(0); qcHZ.z(0)
let stateHZ = qcHZ.run()
print(stateHZ.amplitudes, stateHZ.probabilities)               // 2 — H;Z

let qcHZH = QuantumCircuit(qubits: 1); qcHZH.h(0); qcHZH.z(0); qcHZH.h(0)
print(qcHZH.run().probabilities)                               // 3 — H;Z;H

let qcHTH = QuantumCircuit(qubits: 1); qcHTH.h(0); qcHTH.t(0); qcHTH.h(0)
print(qcHTH.run().probabilities)                               // 4 — fringe point: T

let qcHSH = QuantumCircuit(qubits: 1); qcHSH.h(0); qcHSH.s(0); qcHSH.h(0)
print(qcHSH.run().probabilities)                               // 4 — fringe point: S

// the fringe: H; P(phi); H, swept, against cos^2(phi/2)
for k in 0...8 {
    let phi = Double(k) * Double.pi / 4
    let c = QuantumCircuit(qubits: 1); c.h(0); c.p(phi, 0); c.h(0)
    let p0 = c.run().probabilities[0]
    print(String(format: "phi %.4f  p0 %.4f  cos^2(phi/2) %.4f", phi, p0, pow(cos(phi / 2), 2)))
}

// global phase drops out: P(phi) vs RZ(phi) give the same fringe
for k in [1, 2] {
    let phi = Double(k) * Double.pi / 4
    let a = QuantumCircuit(qubits: 1); a.h(0); a.p(phi, 0); a.h(0)
    let b = QuantumCircuit(qubits: 1); b.h(0); b.rz(phi, 0); b.h(0)
    print("phi", phi, "P probs", a.run().probabilities, "RZ probs", b.run().probabilities)
}

// the exercise circuit: an odd number of H;Z sandwiches
let q5 = QuantumCircuit(qubits: 1)
q5.h(0); q5.z(0); q5.h(0); q5.z(0); q5.h(0)
let s5 = q5.run()
print(s5.amplitudes, s5.probabilities)                         // Try it yourself #1 — H;Z;H;Z;H
```

```text
[1.0, 0.0] [1.0, 0.0]
[0.7071067811865475, -0.7071067811865475] [0.4999999999999999, 0.4999999999999999]
[0.0, 0.9999999999999996]
[0.8535533905932735, 0.14644660940672616]
[0.4999999999999998, 0.4999999999999998]
phi 0.0000  p0 1.0000  cos^2(phi/2) 1.0000
phi 0.7854  p0 0.8536  cos^2(phi/2) 0.8536
phi 1.5708  p0 0.5000  cos^2(phi/2) 0.5000
phi 2.3562  p0 0.1464  cos^2(phi/2) 0.1464
phi 3.1416  p0 0.0000  cos^2(phi/2) 0.0000
phi 3.9270  p0 0.1464  cos^2(phi/2) 0.1464
phi 4.7124  p0 0.5000  cos^2(phi/2) 0.5000
phi 5.4978  p0 0.8536  cos^2(phi/2) 0.8536
phi 6.2832  p0 1.0000  cos^2(phi/2) 1.0000
phi 0.7853981633974483 P probs [0.8535533905932735, 0.14644660940672616] RZ probs [0.8535533905932733, 0.14644660940672616]
phi 1.5707963267948966 P probs [0.49999999999999983, 0.4999999999999997] RZ probs [0.4999999999999999, 0.4999999999999998]
[-0.7071067811865474, 0.7071067811865474] [0.4999999999999998, 0.4999999999999998]
```

`P` and `RZ` agree to between `2×10⁻¹⁶` and `3×10⁻¹⁶` at every φ tested — the same
floating-point-only difference Chapter 7 measured for `P`'s other special angles.

The app-path walkthrough behind steps 2–3 and 7, driving `CircuitBuilder` directly and
formatting output exactly as `ResultsView`'s panel and `BlochSphereView`'s card do (helpers
first defined in Chapter 7's "Run it in code"):

```swift
import SwiftQiskit

func panelRows(_ state: StateVector, qubits: Int) -> [String] {
    let probs = state.probabilities
    return (0..<state.dimension).compactMap { i in
        guard probs[i] > 1e-9 else { return nil }
        let bits = String(i, radix: 2)
        let padded = String(repeating: "0", count: max(0, qubits - bits.count)) + bits
        return "|\(padded)⟩: \(state[i].description)  (p=\(String(format: "%.3f", probs[i])))"
    }
}

func card(_ bloch: BlochVector) -> String {
    var text = String(format: "x %+.3f  y %+.3f  z %+.3f  θ %.3f rad",
                       bloch.x, bloch.y, bloch.z, bloch.theta)
    if abs(bloch.magnitude - 1) > 1e-3 { text += String(format: "  |r| %.3f", bloch.magnitude) }
    return text
}

var b = CircuitBuilder(qubitCount: 1)
b.place(.h, qubits: [0], column: 0)
b.place(.z, qubits: [0], column: 1)
b.place(.h, qubits: [0], column: 2)
print("H;Z;H panel:", panelRows(b.buildCircuit().run(), qubits: 1))
for col in -1...2 {
    let label = col == -1 ? "Start" : "Col \(col + 1)"
    print(label, card(BlochVector(b.buildCircuit(throughColumn: col).run(), qubit: 0)))
}

let beforeBuilder = CircuitBuilder(qubitCount: 1)
beforeBuilder.place(.h, qubits: [0], column: 0)
beforeBuilder.place(.z, qubits: [0], column: 1)
print("H;Z before final H:", card(BlochVector(beforeBuilder.buildCircuit().run(), qubit: 0)))

let afterBuilder = CircuitBuilder(qubitCount: 1)
afterBuilder.place(.h, qubits: [0], column: 0)
afterBuilder.place(.z, qubits: [0], column: 1)
afterBuilder.place(.h, qubits: [0], column: 2)
print("H;Z after final H: ", card(BlochVector(afterBuilder.buildCircuit().run(), qubit: 0)))

let plus = CircuitBuilder(qubitCount: 1); plus.place(.h, qubits: [0], column: 0)
let plusXBasis = CircuitBuilder(qubitCount: 1)
plusXBasis.place(.h, qubits: [0], column: 0); plusXBasis.place(.h, qubits: [0], column: 1)
print("|+> Z-basis 1000 shots:", plus.buildCircuit().measure(shots: 1000).counts)
print("|+> X-basis 1000 shots:", plusXBasis.buildCircuit().measure(shots: 1000).counts)

let minus = CircuitBuilder(qubitCount: 1)
minus.place(.h, qubits: [0], column: 0); minus.place(.z, qubits: [0], column: 1)
let minusXBasis = CircuitBuilder(qubitCount: 1)
minusXBasis.place(.h, qubits: [0], column: 0); minusXBasis.place(.z, qubits: [0], column: 1)
minusXBasis.place(.h, qubits: [0], column: 2)
print("|-> Z-basis 1000 shots:", minus.buildCircuit().measure(shots: 1000).counts)
print("|-> X-basis 1000 shots:", minusXBasis.buildCircuit().measure(shots: 1000).counts)
```

```text
H;Z;H panel: ["|1⟩: 0.9999999999999998  (p=1.000)"]
Start x +0.000  y +0.000  z +1.000  θ 0.000 rad
Col 1 x +1.000  y +0.000  z +0.000  θ 1.571 rad
Col 2 x -1.000  y +0.000  z +0.000  θ 1.571 rad
Col 3 x +0.000  y +0.000  z -1.000  θ 3.142 rad
H;Z before final H: x -1.000  y +0.000  z +0.000  θ 1.571 rad
H;Z after final H:  x +0.000  y +0.000  z -1.000  θ 3.142 rad
|+> Z-basis 1000 shots: ["0": 526, "1": 474]
|+> X-basis 1000 shots: ["0": 1000]
|-> Z-basis 1000 shots: ["0": 503, "1": 497]
|-> X-basis 1000 shots: ["1": 1000]
```

Re-running the two Z-basis lines will land close to, but not exactly on, 500/500 — the shot
counts are genuinely probabilistic (Chapter 9).

Finally, §8.8's two-qubit teaser, `CZ` built by hand exactly as step 8 does on the grid:

```swift
import SwiftQiskit

// CZ, decomposed as H on the target, CX, H on the target — not in the palette directly
func cz(_ c: QuantumCircuit) { c.h(1); c.cx(0, 1); c.h(1) }

let oracleOnly = QuantumCircuit(qubits: 2)
oracleOnly.h(0); oracleOnly.h(1)
cz(oracleOnly)
print("oracle only probs:", oracleOnly.run().probabilities)

let grover = QuantumCircuit(qubits: 2)
grover.h(0); grover.h(1)
cz(grover)
grover.h(0); grover.h(1)
grover.z(0); grover.z(1)
cz(grover)
grover.h(0); grover.h(1)
let gs = grover.run()
print("oracle+diffuser amplitudes:", gs.amplitudes)
print("oracle+diffuser probs:     ", gs.probabilities)
```

```text
oracle only probs: [0.24999999999999983, 0.24999999999999983, 0.24999999999999983, 0.24999999999999983]
oracle+diffuser amplitudes: [0.0, 0.0, 0.0, 0.9999999999999992]
oracle+diffuser probs:      [0.0, 0.0, 0.0, 0.9999999999999984]
```

## Try it yourself

1. The stub version of this exercise asked: does `H;Z;H;Z;H` return to `|0⟩` or `|1⟩`? That's a
   trick question — check for yourself which is wrong, and what the circuit actually returns.
   <details><summary>Answer</summary>Neither. Measured above: `[-0.7071067811865474,
   0.7071067811865474]`, probabilities `[0.5, 0.5]` — the state is `−|−⟩`, sitting on the
   equator, not at either pole. Each `H;Z;H` sandwich is a bit flip up to global phase (§8.4), so
   two of them return to the start up to a sign, and the fifth, unpaired `H` is what leaves the
   state on the equator instead of a pole. The leading `−` is a global phase (§8.2) with no
   physical consequence — `−|−⟩` and `|−⟩` are the same physical state.</details>

2. Predict `H;T;T;H`'s `P(0)` before running it, using `T² = S` (Chapter 7 §7.6).
   <details><summary>Answer</summary>`0.5`. `T` applied twice is `S` (to floating-point
   rounding), so `H;T;T;H` lands on the same fringe point as `H;S;H`, measured above as
   `0.4999999999999998`.</details>

3. Name a pair of states that produce statistically indistinguishable histograms no matter how
   many shots you measure, and the single gate that would separate them.
   <details><summary>Answer</summary>`|+⟩` and `|−⟩` — both give roughly 50/50 splits forever in
   the Z basis (measured above: `526/474` and `503/497`). Appending one `H` before **Measure**
   separates them completely: all-`"0"` for `|+⟩`, all-`"1"` for `|−⟩`.</details>

4. `H;P(π/2);H` and `H;RZ(π/2);H` produce different amplitudes but the same probabilities. Why?
   <details><summary>Answer</summary>`P(φ)` and `RZ(φ)` are the same gate up to the global phase
   factor `e^{−iφ/2}` (Chapter 7 §7.8). Global phase multiplies every amplitude in the state
   equally and cancels out of every `|amplitude|²`, so it can never survive into a probability —
   §8.5 verified the two circuits' probabilities agree to floating-point rounding at every φ
   tested, even though their raw amplitudes differ.</details>

---
[← Chapter 7](07-SingleQubitGates.md) · [Contents](../../INTRODUCTION.md) · [Chapter 9 →](09-Measurement.md)
