# Chapter 7 — Single-Qubit Gates, One at a Time

> A gentle, gate-by-gate tour of the built-in gate set — `x h z y s sdg t tdg p rx ry rz` — each
> shown individually on a 1-qubit circuit, ending with a one-line Bell-state teaser.

| | |
|---|---|
| Playground page | [`05Gates`](../../../SwiftQiskit/PlaygroundDocs/05GATESHELP.md) |
| In the app | ● — every gate here is in the palette |
| Library APIs | `QuantumCircuit.h/x/y/z/s/sdg/t/tdg`, `p/rx/ry/rz(_:_:)` |
| Prerequisites | Chapters 3, 5 |

## 7.1 Why one gate at a time

Every chapter so far has described states without changing them: a fixed `|ψ⟩`, its amplitudes,
its Bloch point. This is the first chapter about *acting* on one. Every gate is a unitary matrix
(Chapter 2 §2.9), and Chapters 5–6 showed that on a single qubit, every unitary has a
geometric meaning: it moves a point on the Bloch sphere, generally by rotating it. That single
fact makes the whole catalog below readable two ways at once — as a matrix acting on a pair of
amplitudes, and as a rotation moving an arrow — and this chapter deliberately keeps both readings
in view, gate by gate, before Chapter 8 needs both at once.

Two distinctions are worth having before the list starts. First, fixed turns versus continuous
families: `X`, `Y`, `Z`, `H`, `S`, `S†`, `T`, `T†` are each one specific rotation, while `P(θ)`,
`RX(θ)`, `RY(θ)`, `RZ(θ)` are continuous rotations that reproduce several of the fixed gates at
particular angles — `P(π/2) ≡ S`, `P(π) ≡ Z`, and so on. Second, gates that move measurement
probabilities versus gates that only move phase: `X` and `H` change what a measurement will show;
`Z` alone, applied to `|0⟩`, changes nothing a measurement can detect at all. That second fact is
not a dead end — it is a deliberately unresolved puzzle. §7.4 states it plainly and stops there;
Chapter 8 is the chapter that resolves it, by showing what a *second* gate does with the phase `Z`
leaves behind.

| § | What happens |
|---|---|
| 7.2 | `X`: the bit flip |
| 7.3 | `H`: superposition |
| 7.4 | `Z`: a phase flip invisible on its own — the puzzle Chapter 8 resolves |
| 7.5 | `Y`: `X` and `Z` together |
| 7.6 | `S`, `S†`, `T`: quarter- and eighth-turns around the equator |
| 7.7 | `P(θ)`: the general phase gate the quarter/eighth turns are special cases of |
| 7.8 | `RX`, `RY`, `RZ`: continuous rotations about all three axes |
| 7.9 | A first two-qubit gate, `CX`, as a teaser for Chapter 12 |

## 7.2 The bit flip: X

`X` swaps the two basis amplitudes: `|0⟩ → |1⟩`, `|1⟩ → |0⟩`. Its matrix is the off-diagonal
`[[0,1],[1,0]]`. On `|0⟩` the result is a single basis state with probability 1 — nothing
statistical to report, and the Bloch point (Chapter 5) lands exactly on the south pole, `(0, 0, −1)`.

## 7.3 Superposition: H

`H` sends `|0⟩ → (|0⟩+|1⟩)/√2 = |+⟩` — Chapter 5's `+x` axis point, `(+1, 0, 0)`. Both basis
states now carry probability ≈ 0.500; a measurement (Chapter 9) is genuinely undetermined until
it happens, unlike `X`'s deterministic flip.

## 7.4 The phase flip: Z, and why it's invisible alone

`Z` is `diag(1, −1)`: it leaves `|0⟩` alone and multiplies `|1⟩`'s amplitude by −1. Applied to
`|0⟩` by itself, this changes nothing observable — `Z|0⟩ = |0⟩` exactly, probabilities `[1.0, 0.0]`.
The sign only becomes visible once there's a second amplitude to compare it against: `H` first,
then `Z`, gives `(0.7071, −0.7071)` — same probabilities `[0.500, 0.500]` as plain `H`, but the
second amplitude's sign has flipped. That sign is real (it changes what a *second* `H` does to
the state) but invisible to any measurement made right after `Z` — probabilities depend only on
magnitude, and `|−1|² = |+1|²`.

The payoff comes from a second `H`: `H; Z; H` on `|0⟩` gives `[0.0, 1.0]` — a deterministic bit
flip, recovered entirely from a phase that was, a moment ago, unmeasurable. This
interference — the same construction Chapter 3 used to reveal a hidden sign, and the subject
Chapter 8 is entirely built around — is `05Gates`'s central lesson, and the app makes it visible
in two independent places at once: the minus sign printed in the State Vector panel's amplitude
column, and the Display arrow swinging from `+x` to `−x` while the panel's `p=` values don't move
at all.

## 7.5 Y as X and Z together

`Y = iXZ`: a bit flip and a phase flip applied together, packaged as one gate,
`[[0,−i],[i,0]]`. On `|0⟩`, `Y` gives `i|1⟩` — the same probabilities `[0.0, 1.0]` as `X`, and
(as it turns out) the exact same Bloch point, the south pole — but a different raw amplitude,
carrying a factor of `i` that `X` doesn't. `X` and `Y` become distinguishable — on the sphere,
not just in the amplitude column — once they act on a state that isn't already a pole; §7's
exercises pick this up on `|+⟩`.

## 7.6 Quarter and eighth turns: S, S†, T

`S = P(π/2) = diag(1, i)` is `√Z` — two `S`s compose to `Z`. Applied after `H`, `S` rotates
`|+⟩` a quarter turn around the equator to `|+i⟩`, `(0, +1, 0)`; its adjoint `S†` rotates the
other way, to `|−i⟩`, `(0, −1, 0)`. `T = P(π/4)` is a further eighth-turn: `H` then `T` twice
lands on `H` then `S` — `T² = S` — to within a measured `1.11×10⁻¹⁶`, not exactly, since the two
paths accumulate floating-point rounding differently (§ Run it in code below has the actual
number). `T†` is `T`'s adjoint, the eighth-turn the other way.

## 7.7 The general phase gate P(θ)

`P(θ) = diag(1, e^{iθ})` generalizes `S`, `T`, and `Z` to an arbitrary angle:
`P(π/2) ≡ S`, `P(π/4) ≡ T`, `P(π) ≡ Z` — each an exact match to within floating-point rounding
(measured below, alongside `T²`'s). Geometrically, `P(θ)` rotates a state by θ around the sphere's
z-axis — it moves φ, never θ, so it never touches the measurement statistics established by
whatever gate ran before it.

## 7.8 Continuous rotations: RX, RY, RZ

Where §7.2–7.7 are a fixed catalog of turns, `RX(θ)`, `RY(θ)`, `RZ(θ)` are continuous rotations
by an arbitrary angle θ about the x, y, z axes, each `exp(−iθA/2)` for the corresponding Pauli
matrix `A`. Two land on states already reached above: `RY(π/2)|0⟩` gives the same `(0.7071, 0.7071)`
as `H|0⟩` — the same point, `|+⟩`, reached by a continuous turn instead of a fixed reflection.
`RX(π/2)|0⟩` gives `(0.7071, −0.7071i)` — probabilities roughly half-and-half like `H`, but at
Bloch point `(0, −1, 0)`, not `(+1, 0, 0)`: `RX` rotates about the x-axis, which carries the
north pole to the `−y` axis, not the `+x` axis that `RY`'s rotation (about the y-axis) reaches
instead. `RZ`, by contrast, illustrates §7.4's lesson generalized to a whole continuous
family: `RZ(θ)` alone on `|0⟩` never changes the measurement statistics at all, for any θ, because
a rotation about the z-axis fixes the poles — it can only move a state already off-axis. Unlike
plain `Z` alone, though, `RZ(π/2)|0⟩`'s single remaining amplitude is genuinely complex,
`0.7071 − 0.7071i`, not the untouched real `1.0` that `Z` leaves behind — the state has picked up
a global phase that no on-circuit measurement can detect, but that the State Vector panel prints
anyway. `RZ` after `H` matches `P`'s probabilities (`[0.500, 0.500]`) but not its raw amplitudes —
the two differ by the global phase factor `e^{−iθ/2}` baked into `RZ`'s definition.

## 7.9 A Bell-state teaser

One `H` and one `CX` (Chapter 12's subject) reach past a single qubit for the first time in this
chapter: `H` on `q0`, then `CX` with `q0` as control and `q1` as target, gives probabilities
`[0.5, 0.0, 0.0, 0.5]` on `|00⟩` and `|11⟩` — the two qubits' outcomes are perfectly correlated,
even though each one individually is undetermined. Recall the app's bit-ordering convention
(Chapter 3): qubit 0 is the leftmost, most-significant bit of each label, so `|00⟩` means `q0=0,
q1=0` and `|11⟩` means `q0=1, q1=1` — the two qubits always agree, never `|01⟩` or `|10⟩`. Each
qubit's own reduced Bloch vector has length 0 (`BlochVector`'s `|r|` line, first seen here) — the
full walkthrough, including what that zero-length vector means, is Chapter 12's territory.

## Build it in the app

● Every step below starts from **Clear** with **Qubits: 1** unless noted, so each section really
is one gate at a time, mirroring `05Gates`'s own structure.

1. **X** — arm **X** (Pauli / Hadamard section), tap `q0`'s column-0 cell. State Vector panel:
   `|1⟩: 1.0  (p=1.000)` — the `|0⟩` row disappears entirely once its probability is 0. Tap
   **Display** → **Final**: card reads `x +0.000  y +0.000  z −1.000`, `θ 3.142 rad`.
2. **H** — Clear, arm **H**, tap `q0`. Panel: `|0⟩: 0.707…  (p=0.500)`, `|1⟩: 0.707…  (p=0.500)`.
   Card: `x +1.000  y +0.000  z +0.000`, `θ 1.571 rad`.
3. **Z alone** — Clear, arm **Z**, tap `q0`. Panel: `|0⟩: 1.0  (p=1.000)` — indistinguishable
   from an empty circuit. Card: unchanged at the `|0⟩` pole, `z +1.000`.
4. **H then Z** — Clear, **H** at column 0, arm **Z**, tap `q0`'s column-1 cell. Panel:
   `|0⟩: 0.707…  (p=0.500)`, `|1⟩: -0.707…  (p=0.500)` — same `p=` as step 2, minus sign on the
   second amplitude. Card: `x −1.000  y +0.000  z +0.000` — the arrow has swung to the opposite
   side of the sphere while both probabilities held at 0.500.
5. **H, Z, H** — add a second **H** at column 2. Panel collapses back to one row:
   `|1⟩: 0.9999999999999998  (p=1.000)` — not exactly `1.0`, the same ~1e-16 rounding Chapter 5
   found on the axis states. Tap **Display** → **Steps**: `Start` sits at the `|0⟩` pole
   (`z +1.000`), `Col 1` (after the first `H`) is at `x +1.000`, `Col 2` (after `Z`) is at
   `x −1.000`, `Col 3` (after the second `H`) is at the south pole, `z −1.000` — the whole
   phase-into-bit-flip trajectory, one column at a time.
6. **Y** — Clear, arm **Y**, tap `q0`. Panel: `|1⟩: 1.0i  (p=1.000)` — same `p=` as step 1's `X`,
   but the amplitude column shows `1.0i` instead of a bare `1.0`. Card: identical to step 1's,
   `z −1.000` — `X` and `Y` land on the same point starting from `|0⟩`.
7. **Phase family on `|+⟩`** — Clear, **H** at column 0. Then, one at a time (Clear the tile and
   re-place to swap gates): arm **S** (Phase section) at column 1 → card `y +1.000`; **S†** →
   card `y −1.000`; **T** → card `x +0.707  y +0.707`; **T†** → card `x +0.707  y −0.707`. `z`
   and `p=` (`0.500/0.500`) hold fixed across all four — only the equatorial angle moves.
8. **P** — Clear, **H** at column 0, arm **P** (Rotation section — it arms at θ = π/2 already, no
   slider drag needed), tap column 1. Card matches step 7's **S** card exactly, `y +1.000`. Tap
   the placed **P** tile to open its popover; drag θ to `0.785` (≈ π/4): card moves to
   `x +0.707  y +0.707`, matching **T**. Drag to `3.142` (≈ π): card moves to `x −1.000`,
   matching **Z**. Both are approximate matches, not exact — the popover's three-decimal
   readout can't enter `π` exactly, and §Run it in code shows the small resulting deviation.
9. **Rotations** — Clear, arm **RY** (Rotation section, θ = π/2 default), tap `q0`. Card matches
   step 2's **H** card exactly, `x +1.000`. Clear, arm **RX** instead: card is `y −1.000`. Set
   **Shots: 1000** and tap **Measure**: the histogram splits roughly evenly (an actual run gave
   470/530 — expect your own run to differ). Clear, arm **RZ** alone: panel shows one row,
   `|0⟩: 0.707… − 0.707…i  (p=1.000)` — a genuinely complex amplitude, unlike step 3's untouched
   real `1.0` — but the card is still parked at the `|0⟩` pole, unmoved. Now add **H** at column
   0 first, **RZ** at column 1: panel returns to `p=0.500/0.500`, card matches step 7's **S**
   card, `y +1.000` — but the panel's raw amplitudes (`0.5 − 0.5i`, `0.5 + 0.5i`) don't match
   **S**'s (`0.707`, `0.707i`) at all, only the probabilities and the Bloch point do.
10. **Bell teaser** — **Qubits: 2**. Arm **H**, tap `q0`'s column-0 cell. Arm **CX**
    (Multi-qubit section), tap `q0` then `q1` in column 1. Panel: `|00⟩: 0.707…  (p=0.500)`,
    `|11⟩: 0.707…  (p=0.500)`. **Display** → **Final** shows both `q0` and `q1` cards printing an
    extra line, `|r| 0.000` — the first entangled, zero-length reduced Bloch vector this
    introduction has produced.

Two genuine limits worth naming, not a missing-capability paragraph — every gate above really is
one tap away: the θ popover only gives a three-decimal readout over `0…2π`, so an exact `π` or
`π/4` can only be approximated (step 8's small deviation is a direct consequence); and a placed
tile can only be edited in place or removed, never dragged to a different column — reordering a
sequence means clearing and re-placing.

## Run it in code

The playground page itself has no `print` calls (its results live in the sidebar); the block
below adds them, run with `RunCodeSnippet` against `SwiftQiskitApp/CircuitModel.swift`:

```swift
import SwiftQiskitCore

let qcIdentity = QuantumCircuit(qubits: 1)
print(qcIdentity.run().probabilities)                 // 1 — no gates yet

let qcX = QuantumCircuit(qubits: 1); qcX.x(0)
let stateX = qcX.run()
print(stateX.amplitudes, stateX.probabilities)         // 2 — X

let qcH = QuantumCircuit(qubits: 1); qcH.h(0)
let stateH = qcH.run()
print(stateH.amplitudes, stateH.probabilities)         // 3 — H

let qcZAlone = QuantumCircuit(qubits: 1); qcZAlone.z(0)
print(qcZAlone.run().probabilities)                    // 4 — Z alone

let qcHZ = QuantumCircuit(qubits: 1); qcHZ.h(0); qcHZ.z(0)
let stateHZ = qcHZ.run()
print(stateHZ.amplitudes, stateHZ.probabilities)        // 4 — H;Z

let qcHZH = QuantumCircuit(qubits: 1); qcHZH.h(0); qcHZH.z(0); qcHZH.h(0)
print(qcHZH.run().probabilities)                        // 4 — H;Z;H

let qcY = QuantumCircuit(qubits: 1); qcY.y(0)
let stateY = qcY.run()
print(stateY.amplitudes, stateY.probabilities)          // 5 — Y

let qcS = QuantumCircuit(qubits: 1); qcS.h(0); qcS.s(0)
let stateS = qcS.run()
print(stateS.amplitudes)                                // 6 — H;S

let qcSdg = QuantumCircuit(qubits: 1); qcSdg.h(0); qcSdg.sdg(0)
print(qcSdg.run().amplitudes)                           // 6 — H;S†

let qcTT = QuantumCircuit(qubits: 1); qcTT.h(0); qcTT.t(0); qcTT.t(0)
let stateTT = qcTT.run()
print(stateTT.amplitudes)                               // 7 — H;T;T
let diffTT = zip(stateTT.amplitudes, stateS.amplitudes).map { ($0 - $1).magnitude }.max()!
print("T² vs S max abs diff:", diffTT)

let qcPHalfPi = QuantumCircuit(qubits: 1); qcPHalfPi.h(0); qcPHalfPi.p(.pi / 2, 0)
let statePHalfPi = qcPHalfPi.run()
let diffPS = zip(statePHalfPi.amplitudes, stateS.amplitudes).map { ($0 - $1).magnitude }.max()!
print("P(π/2) vs S max abs diff:", diffPS)              // 8 — P(π/2) == S

let qcPQuarterPi = QuantumCircuit(qubits: 1); qcPQuarterPi.h(0); qcPQuarterPi.p(.pi / 4, 0)
print(qcPQuarterPi.run().amplitudes)                    // 8 — P(π/4), a single T

let qcPPi = QuantumCircuit(qubits: 1); qcPPi.h(0); qcPPi.p(.pi, 0)
let statePPi = qcPPi.run()
let diffPZ = zip(statePPi.amplitudes, stateHZ.amplitudes).map { ($0 - $1).magnitude }.max()!
print("P(π) vs H;Z max abs diff:", diffPZ)              // 8 — P(π) == Z

let qcRY = QuantumCircuit(qubits: 1); qcRY.ry(.pi / 2, 0)
print(qcRY.run().amplitudes)                            // 9 — RY(π/2)

let qcRX = QuantumCircuit(qubits: 1); qcRX.rx(.pi / 2, 0)
print(qcRX.run().amplitudes)
print(qcRX.measure(shots: 1000).counts)                 // 9 — RX(π/2)

let qcRZ = QuantumCircuit(qubits: 1); qcRZ.h(0); qcRZ.rz(.pi / 2, 0)
let stateRZ = qcRZ.run()
print(stateRZ.amplitudes, stateRZ.probabilities)        // 9 — H;RZ(π/2)

let qcBell = QuantumCircuit(qubits: 2); qcBell.h(0); qcBell.cx(0, 1)
print(qcBell.run().probabilities)                       // 10 — Bell teaser
```

```text
[1.0, 0.0]
[0.0, 1.0] [0.0, 1.0]
[0.7071067811865475, 0.7071067811865475] [0.4999999999999999, 0.4999999999999999]
[1.0, 0.0]
[0.7071067811865475, -0.7071067811865475] [0.4999999999999999, 0.4999999999999999]
[0.0, 0.9999999999999996]
[0.0, 1.0i] [0.0, 1.0]
[0.7071067811865475, 0.7071067811865475i]
[0.7071067811865475, -0.7071067811865475i]
[0.7071067811865475, 1.1102230246251565e-16 + 0.7071067811865475i]
T² vs S max abs diff: 1.1102230246251565e-16
P(π/2) vs S max abs diff: 4.329780281177466e-17
[0.7071067811865475, 0.5 + 0.4999999999999999i]
P(π) vs H;Z max abs diff: 8.659560562354932e-17
[0.7071067811865476, 0.7071067811865475]
[0.7071067811865476, -0.7071067811865475i]
["1": 510, "0": 490]
[0.5 - 0.4999999999999999i, 0.5 + 0.4999999999999999i] [0.4999999999999999, 0.4999999999999999]
[0.4999999999999999, 0.0, 0.0, 0.4999999999999999]
```

`T² = S` and `P(θ)`'s three special-angle identities all check out to between `4×10⁻¹⁷` and
`1×10⁻¹⁶` — matching `05GATESHELP.md`'s "~1e-16"/"~1e-17" estimates as measured, not asserted,
numbers. `qcRX.measure(shots: 1000)` printed `510`/`490` on this run; re-running gives a
different, still roughly-even split.

The app-path walkthrough behind every "Build it in the app" step, driving `CircuitBuilder`
directly and formatting output exactly as `ResultsView`'s panel and `BlochSphereView`'s card do:

```swift
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
b.place(.rz(.pi / 2), qubits: [0], column: 1)
var state = b.buildCircuit().run()
print("H;RZ(π/2) panel:", panelRows(state, qubits: 1))
print("H;RZ(π/2) card: " + card(BlochVector(state, qubit: 0)))

b = CircuitBuilder(qubitCount: 2)
b.place(.h, qubits: [0], column: 0)
b.place(.cx, qubits: [0, 1], column: 1)
state = b.buildCircuit().run()
print("Bell panel:", panelRows(state, qubits: 2))
print("Bell card q0: " + card(BlochVector(state, qubit: 0)))
print("Bell card q1: " + card(BlochVector(state, qubit: 1)))
```

```text
H;RZ(π/2) panel: ["|0⟩: 0.5 - 0.4999999999999999i  (p=0.500)", "|1⟩: 0.5 + 0.4999999999999999i  (p=0.500)"]
H;RZ(π/2) card: x +0.000  y +1.000  z +0.000  θ 1.571 rad
Bell panel: ["|00⟩: 0.7071067811865475  (p=0.500)", "|11⟩: 0.7071067811865475  (p=0.500)"]
Bell card q0: x +0.000  y +0.000  z +0.000  θ 1.571 rad  |r| 0.000
Bell card q1: x +0.000  y +0.000  z +0.000  θ 1.571 rad  |r| 0.000
```

Both match the readouts quoted in steps 9 and 10 above.

## Try it yourself

1. Confirm `T` applied twice matches `S` to within floating-point error, not exactly.
   <details><summary>Answer</summary>Measured above: the two amplitude vectors agree to a
   maximum absolute difference of `1.11×10⁻¹⁶`, not bit-for-bit — the two paths (one `S`, two
   `T`s) accumulate rounding differently. See `05GATESHELP.md` §7.</details>

2. Why does `RZ` alone leave the Display card exactly on the `|0⟩` pole, no matter what θ is,
   while `RZ` after `H` visibly moves it?
   <details><summary>Answer</summary>`RZ(θ)` is a rotation about the z-axis, and a rotation about
   an axis fixes the two points already sitting on that axis — the same fact §7.4 established for
   the fixed gate `Z`, now true for the whole continuous `RZ` family. `H` first moves the state
   off the z-axis (onto `|+⟩`), giving `RZ` something to actually rotate.</details>

3. Predict the Display card for `H` then `X`, and separately for `H` then `Y`, before checking.
   <details><summary>Answer</summary>`X|+⟩ = |+⟩` — `X` fixes `|+⟩`, so the card stays at
   `x +1.000`. `Y|+⟩ = −i|−⟩` — physically the `−x` point, `x −1.000`. §7.5 showed `X` and `Y`
   land on the *same* card starting from `|0⟩`; here, starting from `|+⟩`, they land on opposite
   sides of the sphere — the difference between the two gates is invisible on one input and
   maximally visible on another.</details>

4. Three different circuits in this chapter — `H;S`, `H;P(π/2)`, and `H;RZ(π/2)` — produce three
   different sets of raw amplitudes but the exact same Display card. Why?
   <details><summary>Answer</summary>Bloch coordinates are blind to a global phase (Chapter 5
   §5.2). `S`, `P(π/2)`, and `RZ(π/2)` agree on everything a measurement can detect — they all
   send `|+⟩` to the same physical state, `|+i⟩` — but `RZ`'s definition carries an extra overall
   phase factor `e^{−iπ/4}` that `S` and `P(π/2)` don't, which is why its amplitudes
   (`0.5 ∓ 0.5i`) look nothing like the other two's (`0.7071`, `0.7071i`) even though the card is
   identical.</details>

---
[← Chapter 6](06-BlochSphere3D.md) · [Contents](../../INTRODUCTION.md) · [Chapter 8 →](08-Interference.md)
