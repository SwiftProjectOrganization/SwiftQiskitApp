# Chapter 22 — State Tomography

> Reconstructing an unknown state from `measure(shots:)` alone: basis rotations pinned by hand,
> 1/√N error scaling, and why a *pure* state's reconstruction stays "unphysical" about half the
> time no matter how many shots you take.

| | |
|---|---|
| Playground page | [`20Tomography`](../../../SwiftQiskit/PlaygroundDocs/20TOMOGRAPHYHELP.md) |
| In the app | ◐ — the three basis-rotation-then-measure circuits are tappable one at a time; combining the three shot counts into a reconstructed Bloch vector is code-only |
| Library APIs | `QuantumCircuit.h/s/sdg/rx/cx`, `.run()`, `measure(shots:)`, `SimulationResult.counts`, `StateVector.measure()`, `†`, `Bra * Matrix`, `BlochVector(x:y:z:)` |
| Prerequisites | Chapters 5, 9, 12, 21 |

## 22.1 Measuring in X, Y, and Z bases

Every chapter so far has read a state's amplitudes straight off the `StateVector` — something no
real device permits. A real device only ever reports a Z-basis outcome, `0` or `1`. To learn
anything about X or Y, the trick is the same one Chapter 9 used for interference: rotate the
axis you want *into* Z first, then measure as usual.

```text
X basis:  h(0)              then measure
Y basis:  sdg(0); h(0)       then measure
Z basis:  (nothing)          then measure
```

The Y-basis order matters, and it's worth pinning down before trusting it rather than guessing.
`|+i⟩` is a known +1 eigenstate of Y, so rotating it correctly into Z should collapse it to
`|0⟩` deterministically:

```text
|+i⟩ rotated by (Sdg; H): |0⟩ amplitude ≈ 1.0, |1⟩ amplitude ≈ 0.0
|+i⟩ rotated by (H; Sdg): |0⟩ amplitude ≈ 0.5+0.5i, |1⟩ amplitude ≈ -0.5-0.5i   (wrong order)
```

`Sdg` then `H` diagonalizes Y; the reverse order gives an equal superposition, useless for
reading off a bit. A single-tile alternative that gives the same collapse — worth knowing for
"Build it in the app" below — is `rx(π/2)`:

```text
|+i⟩ rotated by rx(+π/2): |0⟩ amplitude ≈ 1.0, |1⟩ amplitude ≈ 0.0   (same result as Sdg; H)
```

## 22.2 Reconstructing the Bloch vector

The estimator behind every number in this chapter is one line: run `shots` copies of the
unknown state, rotate into a basis, measure, and count.

```text
⟨A⟩ ≈ (N₀ − N₁) / N
```

Checked against the exact `ψ† A ψ` on a generic tilted state (`ry(1.0472)` then `rz(0.7854)`,
i.e. θ≈60°, φ≈45° in Chapter 4/8's parametrization — 1.0472 ≈ π/3, 0.7854 ≈ π/4) before trusting
it statistically:

```text
exact    ⟨X⟩=0.612372  ⟨Y⟩=0.612374  ⟨Z⟩=0.499998
N=100000 ⟨X⟩=0.613780  ⟨Y⟩=0.614820  ⟨Z⟩=0.501960
```

All three land within about 0.002 of the exact value at N=100,000 — statistical, a re-run will
differ, but always by roughly that much.

## 22.3 Error scaling as 1/√N

More shots tighten the estimate, but only as the square root of N — a fourfold increase in
shots only halves the error. RMS error of the X-estimate against the exact value, over 20
trials per N:

```text
N         RMS error in ⟨X⟩ (20 trials)
100       0.069924
1000      0.025534
10000     0.009175
100000    0.002345
```

Successive ratios (0.070/0.026≈2.7, 0.026/0.009≈2.8, 0.009/0.002≈3.9) bracket the √10≈3.16
predicted by each tenfold increase in N — some scatter is expected from only 20 trials per
point, but the declining trend is the section's point, not the exact digits.

## 22.4 Why reconstruction is "unphysical" about half the time

A per-axis estimate can put the reconstructed vector `(x, y, z)` *outside* the Bloch ball
(`|r| > 1`) — a physically impossible state, since the estimate is really three independent
noisy readings, not one consistent measurement. The surprising result: for a genuinely *pure*
state (sitting exactly on the ball's boundary), that happens roughly **half the time no matter
how large N is**:

```text
Pure tilted state, unphysical (|r|>1) frequency over 500 trials:
  N=10: 0.626   N=50: 0.530   N=200: 0.514   N=1000: 0.502   N=5000: 0.516
```

Symmetric per-axis noise straddles a boundary point equally in both directions, so the
frequency plateaus near 0.5 instead of trending to 0. `|+⟩` is a misleading edge case: its
X-estimate is *deterministic* at 1.0 exactly, so any Y/Z noise alone is enough to push the norm
over 1 on nearly every trial:

```text
|+⟩ edge case, unphysical frequency over 500 trials:
  N=10: 0.928   N=50: 0.994   N=200: 0.990   N=1000: 1.000
```

Only a genuinely *mixed* state's frequency shrinks toward zero, since it sits strictly inside
the ball to begin with:

```text
Mixed state (|r|=0.5), unphysical frequency over 500 trials:
  N=10: 0.100   N=50: 0.000   N=200: 0.000   N=1000: 0.000
```

The fix — maximum-likelihood or linear-inversion reconstruction, which projects the raw estimate
onto the nearest physical state — is named here but not implemented; §22.7's "Run it in code"
shows the crude version (rescale to the sphere's surface when `|r| > 1`) and what it costs.

## 22.5 An entangled qubit's marginal, from shots alone

Chapter 21 derived a Bell pair's reduced single-qubit state exactly: `ρ_A = I/2`, the sphere's
center. Estimating it from `measure(shots:)` alone — 50,000 shots per basis, on qubit 0 of
`|Φ⁺⟩` — reproduces that by measurement instead of derivation:

```text
Bell-pair qubit-0 marginal from shots: (x,y,z) = (0.003040, -0.003520, 0.002600), |r| = 0.005328
```

Statistically indistinguishable from the origin — restating Chapter 12's no-cloning-flavored
point that one copy of an entangled qubit's own state carries no information at all, however
many bases you measure it in.

## 22.6 Why full tomography doesn't scale

Full tomography needs a setting per qubit per basis: 3 choices (X, Y, Z) to the power of the
qubit count.

```text
qubits   settings (3ⁿ)
1        3
2        9
3        27
4        81
5        243
```

By 20-something qubits this number exceeds the number of atoms worth counting — exactly why
Chapter 23 (VQE) never reconstructs a full state, and instead measures only the individual
Pauli terms of a Hamiltonian it actually needs.

## Build it in the app

◐ Each of the three basis-rotation circuits is a handful of tiles; turning three separate shot
counts into one (x, y, z) triple is arithmetic the app doesn't do for you.

1. **Prepare `|+i⟩`.** Clear, **Qubits: 1**. Arm **H**, tap `q0` column 0. Arm **S**, tap `q0`
   column 1. State Vector panel: `|0⟩` and `|1⟩` each ≈ 0.707, with `|1⟩`'s amplitude showing
   the `i` that makes this a Y-eigenstate, not an X one.
2. **Z basis.** Set **Shots: 2000**, tap **Measure** as-is. Panel: `0` and `1` roughly
   1000/1000 → z-estimate ≈ 0.
3. **X basis.** Arm **H**, tap `q0` in the next empty column, then Measure again. Panel:
   roughly 1000/1000 → x-estimate ≈ 0.
4. **Y basis.** Undo step 3 (remove that tile), then arm **RX**, tap `q0`, drag the popover to
   `θ = 1.571` (`= π/2`) — one tile does what §22.1 showed `sdg; h` needs two for. Measure.
   Panel: **all 2000 shots land on `0`** → y-estimate = 1.0.

   Assembled by hand: `(x, y, z) ≈ (0, 1, 0)` — exactly `|+i⟩`'s Bloch vector, each component
   read off a separate Measure tap. Display → Final shows the same point directly, the "answer
   a real device never shows you."
5. **All three axes in one tap.** Clear, **Qubits: 3**. Repeat step 1's two tiles (`h`, `s`) on
   `q0`, `q1`, *and* `q2` — three independent copies of the same unknown state. Leave `q0` in
   the Z basis untouched; arm **H**, tap `q1` in the next column (X basis); arm **RX**, tap
   `q2` in that same column, `θ = 1.571` (Y basis). One **Measure** now reads all three axes at
   once, provided the histogram is split by qubit (q0's bit gives z, q1's gives x, q2's gives
   y) — a 4000-shot run landed at `(x, y, z) ≈ (-0.016, 1.000, 0.009)`, the same point as step
   4, in a third the taps.
6. **A Bell pair's marginal.** Clear, **Qubits: 2**. Arm **H**, tap `q0` column 0; arm **CX**,
   tap `q0` then `q1` column 1 — the familiar Bell circuit. Measure as-is for the z-estimate,
   then append `h(q0)` and re-measure for x, then `sdg(q0); h(q0)` (or the single-tile
   `rx(π/2)`) and re-measure for y, marginalizing q1 out of each histogram by hand. All three
   land near 0 — qubit 0's marginal, measured rather than derived, matching §22.5.

**What's still out of reach:** the app never combines a set of counts into `(x, y, z)`, checks
whether the result is physical, or scales to more than one qubit's worth of settings — all of
that, plus the RMS-error and unphysical-frequency sweeps (thousands of repeated Measure taps),
stays in "Run it in code."

## Run it in code

Every snippet was run with `RunCodeSnippet` against `SwiftQiskitApp/CircuitModel.swift`.

```swift
import SwiftQiskit

func fmt(_ d: Double) -> String { String(format: "%.6f", d) }

let H = HadamardGate.matrix
let Sdg = SDaggerGate.matrix
let X = PauliXGate.matrix
let Y = PauliYGate.matrix
let Z = PauliZGate.matrix

func basisRotation(_ axis: String, _ s: inout StateVector) {
    switch axis {
    case "X": s.apply(H)
    case "Y": s.apply(Sdg); s.apply(H)
    default: break
    }
}

var plusI = StateVector.plusI
basisRotation("Y", &plusI)
print("|+i⟩ rotated by (Sdg;H): \(plusI)")
```

```text
|+i⟩ rotated by (Sdg;H): |0⟩: 0.9999999999999998
|1⟩: 0.0
```

The estimator, checked against the exact expectation:

```swift
func tiltedState() -> Ket {
    var s = StateVector.zero
    s.apply(RYGate.matrix(theta: 1.0472))
    s.apply(RZGate.matrix(theta: 0.7854))
    return s
}
func exactExpectation(_ psi: Ket, _ A: Matrix) -> Double { (psi† * A * psi).real }

func estimate(_ axis: String, psi: Ket, shots: Int) -> Double {
    var plus = 0
    for _ in 0..<shots {
        var s = psi
        basisRotation(axis, &s)
        if s.measure() == 0 { plus += 1 }
    }
    return 2 * Double(plus) / Double(shots) - 1
}

let psi = tiltedState()
print("exact    ⟨X⟩=\(fmt(exactExpectation(psi, X)))  ⟨Y⟩=\(fmt(exactExpectation(psi, Y)))  ⟨Z⟩=\(fmt(exactExpectation(psi, Z)))")
print("N=100000 ⟨X⟩=\(fmt(estimate("X", psi: psi, shots: 100_000)))  ⟨Y⟩=\(fmt(estimate("Y", psi: psi, shots: 100_000)))  ⟨Z⟩=\(fmt(estimate("Z", psi: psi, shots: 100_000)))")
```

```text
exact    ⟨X⟩=0.612372  ⟨Y⟩=0.612374  ⟨Z⟩=0.499998
N=100000 ⟨X⟩=0.613780  ⟨Y⟩=0.614820  ⟨Z⟩=0.501960
```

1/√N error scaling:

```swift
func rmsError(_ axis: String, exact: Double, psi: Ket, shots: Int, trials: Int) -> Double {
    let errors = (0..<trials).map { _ in estimate(axis, psi: psi, shots: shots) - exact }
    return (errors.map { $0 * $0 }.reduce(0, +) / Double(trials)).squareRoot()
}

let exactX = exactExpectation(psi, X)
print("N         RMS error in ⟨X⟩ (20 trials)")
for n in [100, 1_000, 10_000, 100_000] {
    print("\(n)     \(fmt(rmsError("X", exact: exactX, psi: psi, shots: n, trials: 20)))")
}
```

```text
N         RMS error in ⟨X⟩ (20 trials)
100     0.069924
1000     0.025534
10000     0.009175
100000     0.002345
```

Unphysical-reconstruction frequency — pure, a stabilizer edge case, and genuinely mixed:

```swift
func reconstructedMagnitude(_ psi: Ket, shots: Int) -> Double {
    let ex = estimate("X", psi: psi, shots: shots)
    let ey = estimate("Y", psi: psi, shots: shots)
    let ez = estimate("Z", psi: psi, shots: shots)
    return (ex * ex + ey * ey + ez * ez).squareRoot()
}
func unphysicalFrequency(_ psi: Ket, shots: Int, trials: Int) -> Double {
    let hits = (0..<trials).filter { _ in reconstructedMagnitude(psi, shots: shots) > 1.0 }.count
    return Double(hits) / Double(trials)
}

print("Pure tilted state, unphysical frequency (500 trials):")
for n in [10, 50, 200, 1000, 5000] {
    print("  N=\(n): \(fmt(unphysicalFrequency(psi, shots: n, trials: 500)))")
}

var plusState = StateVector.zero
plusState.apply(H)
print("|+⟩ edge case, unphysical frequency (500 trials):")
for n in [10, 50, 200, 1000] {
    print("  N=\(n): \(fmt(unphysicalFrequency(plusState, shots: n, trials: 500)))")
}

func sampleMixedAndMeasure(_ axis: String) -> Int {
    var s: Ket = Double.random(in: 0..<1) < 0.75 ? StateVector.zero : StateVector.one
    basisRotation(axis, &s)
    return s.measure()
}
func estimateMixed(_ axis: String, shots: Int) -> Double {
    var plus = 0
    for _ in 0..<shots { if sampleMixedAndMeasure(axis) == 0 { plus += 1 } }
    return 2 * Double(plus) / Double(shots) - 1
}
func unphysicalFrequencyMixed(shots: Int, trials: Int) -> Double {
    var count = 0
    for _ in 0..<trials {
        let ex = estimateMixed("X", shots: shots)
        let ey = estimateMixed("Y", shots: shots)
        let ez = estimateMixed("Z", shots: shots)
        if (ex * ex + ey * ey + ez * ez).squareRoot() > 1.0 { count += 1 }
    }
    return Double(count) / Double(trials)
}
print("Mixed state (|r|=0.5), unphysical frequency (500 trials):")
for n in [10, 50, 200, 1000] {
    print("  N=\(n): \(fmt(unphysicalFrequencyMixed(shots: n, trials: 500)))")
}
```

```text
Pure tilted state, unphysical frequency (500 trials):
  N=10: 0.626000   N=50: 0.530000   N=200: 0.514000   N=1000: 0.502000   N=5000: 0.516000

|+⟩ edge case, unphysical frequency (500 trials):
  N=10: 0.928000   N=50: 0.994000   N=200: 0.990000   N=1000: 1.000000

Mixed state (|r|=0.5), unphysical frequency (500 trials):
  N=10: 0.100000   N=50: 0.000000   N=200: 0.000000   N=1000: 0.000000
```

(All three plateaus are statistical over 500 trials; a re-run will land within a few percent of
each number, not on it exactly.)

A Bell pair's qubit-0 marginal, reconstructed from shots alone:

```swift
let I2 = Matrix.identity(size: 2)
var bell = StateVector(qubits: 2)
bell.apply(H.tensor(I2))
bell.apply(CNOTGate.matrix(qubits: 2, control: 0, target: 1))

func estimateQubit0(_ axis: String, state: Ket, shots: Int) -> Double {
    var plus = 0
    for _ in 0..<shots {
        var s = state
        switch axis {
        case "X": s.apply(H.tensor(I2))
        case "Y": s.apply(Sdg.tensor(I2)); s.apply(H.tensor(I2))
        default: break
        }
        let bit0 = (s.measure() >> 1) & 1   // qubit 0 is the MSB
        if bit0 == 0 { plus += 1 }
    }
    return 2 * Double(plus) / Double(shots) - 1
}

let bx = estimateQubit0("X", state: bell, shots: 50_000)
let by = estimateQubit0("Y", state: bell, shots: 50_000)
let bz = estimateQubit0("Z", state: bell, shots: 50_000)
print("Bell-pair qubit-0 marginal: (x,y,z) = (\(fmt(bx)), \(fmt(by)), \(fmt(bz))), |r| = \(fmt((bx*bx+by*by+bz*bz).squareRoot()))")
```

```text
Bell-pair qubit-0 marginal: (x,y,z) = (0.003040, -0.003520, 0.002600), |r| = 0.005328
```

The cost table:

```swift
print("qubits   settings (3ⁿ)")
for n in 1...5 {
    print("\(n)        \(Int(pow(3.0, Double(n))))")
}
```

```text
qubits   settings (3ⁿ)
1        3
2        9
3        27
4        81
5        243
```

A `CircuitBuilder` replay confirming the app's step 5 (all three axes, one Measure tap):

```swift
let builder = CircuitBuilder(qubitCount: 3)
builder.place(.h, qubits: [0], column: 0)
builder.place(.h, qubits: [1], column: 0)
builder.place(.h, qubits: [2], column: 0)
builder.place(.s, qubits: [0], column: 1)
builder.place(.s, qubits: [1], column: 1)
builder.place(.s, qubits: [2], column: 1)
builder.place(.h, qubits: [1], column: 2)                 // q1 -> X basis
builder.place(.rx(Double.pi / 2), qubits: [2], column: 2)  // q2 -> Y basis, one tile

builder.shots = 4000
builder.measure()
let counts = builder.lastResult?.counts ?? [:]

func marginal(_ qubit: Int) -> (n0: Int, n1: Int) {
    var n0 = 0, n1 = 0
    for (key, c) in counts {
        if Array(key)[qubit] == "0" { n0 += c } else { n1 += c }
    }
    return (n0, n1)
}
func est(_ n0: Int, _ n1: Int) -> Double { 2 * Double(n0) / Double(n0 + n1) - 1 }
let (z0, z1) = marginal(0), (x0, x1) = marginal(1), (y0, y1) = marginal(2)
print("q0 Z estimate: \(est(z0, z1))  q1 X estimate: \(est(x0, x1))  q2 Y estimate: \(est(y0, y1))")
```

```text
q0 Z estimate: 0.0085   q1 X estimate: -0.016   q2 Y estimate: 1.0
```

## Try it yourself

1. Run tomography with 100 shots, then 10,000, and compare how far the reconstructed vector's
   magnitude departs from 1.
   <details><summary>Answer</summary>The departure shrinks roughly by a factor of 10 (√100),
   matching the 1/√N scaling §22.3 verified directly: the RMS error in a single component fell
   from 0.069924 at N=100 to 0.009175 at N=10,000, a ratio of ≈7.6 — in the same range as √100,
   with the usual run-to-run scatter from a finite number of trials.</details>
2. §22.4 measured the bit-flip-free `|+⟩` as *nearly always* unphysical, not roughly half the
   time like a generic pure state. Why is `|+⟩` different?
   <details><summary>Answer</summary>`|+⟩`'s X-estimate is deterministic — every shot in the X
   basis returns the same outcome, so the estimate is exactly 1.0 with zero variance. Any
   nonzero Y or Z noise alone is then enough to push `√(1² + y² + z²)` over 1, so almost every
   trial is unphysical (measured 0.928–1.000 across N=10…1000). A generic tilted state has no
   axis pinned at exactly ±1, so its noise is free to land on either side of the boundary about
   equally often, giving the ≈0.5 plateau instead.</details>
3. A Bell pair needs 9 settings for full two-qubit tomography (3² from §22.6). Which of those 9
   are tappable one at a time in the app, and which three correlators come out at exactly ±1
   for `|Φ⁺⟩`?
   <details><summary>Answer</summary>All 9 are tappable: build `h(0); cx(0,1)`, then append one
   of {nothing, `h`, `rx(π/2)`} to *each* qubit before Measure — 3 choices per qubit, 9 circuits
   total, each read as a single 2-bit histogram. Computing the exact correlator for each of the
   9 confirms only the three matched-basis settings are extremal: ⟨ZZ⟩ = 1.000000,
   ⟨XX⟩ = 1.000000, ⟨YY⟩ = -1.000000 (the minus sign is `|Φ⁺⟩`'s signature), while every
   mismatched pairing (⟨XZ⟩, ⟨ZX⟩, ⟨XY⟩, …) is exactly 0 — no correlation at all between
   different bases.</details>
4. When an estimate lands outside the ball, a cheap (if biased) fix is to rescale it back onto
   the surface: `r → r/|r|` whenever `|r| > 1`. Does this make the estimate more accurate?
   <details><summary>Answer</summary>Slightly, on average: over 500 trials at N=200 on the
   tilted state, the raw 3D RMS error was 0.100188 versus 0.089936 after rescaling — an
   improvement, but a small one, because rescaling only touches the roughly-half of trials that
   land outside the ball and leaves the rest untouched. It's also a biased fix (it always moves
   an over-shoot estimate toward the surface, never lets it stay outside), which is exactly why
   §22.4 named maximum-likelihood reconstruction, not this shortcut, as the real
   answer.</details>

---
[← Chapter 21](21-Noise.md) · [Contents](../../INTRODUCTION.md) · [Chapter 23 →](23-VQE.md)
