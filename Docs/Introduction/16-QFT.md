# Chapter 16 — The Quantum Fourier Transform and Phase Estimation

> The quantum Fourier transform built as a real gate circuit instead of a black-box matrix: a
> hand-derived controlled-phase gate assembled from `p` and `cx`, a ladder of Hadamards and that
> gate that reproduces the textbook discrete Fourier transform to fifteen digits, and a swap
> network whose necessity is demonstrated rather than asserted. The same machinery then runs
> phase estimation standalone — reading an unknown phase directly out of a counting register,
> exactly for phases that are exact fractions of a power of two, and closing in on everything
> else as more counting qubits are added.

| | |
|---|---|
| Playground page | [`16QFT`](../../../SwiftQiskit/PlaygroundDocs/16QFTHELP.md) |
| In the app | ● — the controlled-phase gate a 2-qubit QFT and phase estimation need is exactly T/T†/S/S† plus `cx`; only a 3-qubit ladder needs one angle off that grid, and the P tile's slider lands within ~2×10⁻⁴ of it |
| Library APIs | `QuantumCircuit.h/x/p/cx/t/tdg/s/sdg`, `.run()`, `measure(shots:)`, `BlochVector(_:qubit:)`, `Complex` |
| Prerequisites | Chapters 7, 8, 11, 13 |

## 16.1 What the QFT computes

The quantum Fourier transform maps a basis state to a superposition carrying its index in the
*phases* of every amplitude: `|c⟩ → (1/√N) Σ_y e^(2πi·y·c/N) |y⟩`, the same discrete Fourier
transform used everywhere in classical signal processing, applied to N = 2ⁿ amplitudes at once.
Chapter 8 showed that interference is entirely a matter of phase — two paths with the same
probability can cancel or reinforce depending on the angle between their amplitudes. The QFT is
what turns "information written into phases" into a *tool*: run it forward to spread a periodic
pattern across many phases, or run it backward (the inverse QFT) to collapse a family of phases
back down to the number that produced them. This chapter builds the transform gate by gate, checks
it against the formula above, and then uses the inverse QFT for its most common job — reading an
unknown phase out of a quantum state.

| § | What happens |
|---|---|
| 16.2 | The controlled-phase gate CP(θ), built from `p` and `cx`, and its exact T/T†/S/S† forms |
| 16.3 | The QFT ladder: Hadamards and CP's, checked against the DFT formula |
| 16.4 | Why the ladder ends in a swap network |
| 16.5 | The QFT of a basis state is a product state — every qubit stays pure |
| 16.6 | The inverse QFT, and QFT·QFT† = I |
| 16.7 | Phase estimation: reading a phase out of a counting register |
| 16.8 | Precision scales with the number of counting qubits |

## 16.2 The controlled-phase gate CP(θ)

CP(θ) should act as `|11⟩ → e^(iθ)|11⟩` and leave `|00⟩`, `|01⟩`, `|10⟩` alone — a controlled
version of the single-qubit phase gate P(θ) from Chapter 7. There is no native two-qubit phase
gate in the palette, but the standard identity builds one from gates that already exist:

```text
CP(θ) = P(θ/2)_control · CX(control, target) · P(−θ/2)_target · CX(control, target) · P(θ/2)_target
```

Tracking the phase picked up at each of the four basis states explains why. When the control is
`0`, both `CX`'s are no-ops regardless of the target's bit, so only the two target-side `P`'s can
contribute — and `−θ/2` followed by `+θ/2` cancels outright. Net phase 0 for `|00⟩` and `|01⟩`.
When the control is `1`, `P(θ/2)_control` contributes a flat `θ/2`, and each `CX` flips the
target — so the target sees `P(−θ/2)` on the *opposite* of its starting bit, then `P(θ/2)` back
on its own bit. Starting at target = `0`: the `CX`'s move it to `1` then back to `0`, so
`P(−θ/2)` lands on `1` (contributing `−θ/2`) and the final `P(θ/2)` lands on `0` (contributing
nothing) — net `θ/2 − θ/2 + 0 = 0`, so `|10⟩` is untouched too. Starting at target = `1`: the
`CX`'s move it to `0` then back to `1`, so `P(−θ/2)` lands on `0` (nothing) and the final
`P(θ/2)` lands on `1` (contributing `θ/2`) — net `θ/2 + 0 + θ/2 = θ`. Only `|11⟩` picks up the
full angle; every other basis state nets exactly 0.

Two angles land exactly on palette gates, since T = P(π/4), T† = P(−π/4), S = P(π/2), S† = P(−π/2):

| Angle θ | Palette form | `\|11⟩` phase |
|---|---|---|
| π/2 | `t(control); cx(control,target); tdg(target); cx(control,target); t(target)` | +i |
| π | `s(control); cx(control,target); sdg(target); cx(control,target); s(target)` | −1 |

```text
CP(θ) on all four basis states, control=0, target=1:
input  CP(π/2) via p()   CP(π/2) via T/T†   CP(π) via S/S†
 |00⟩    +1.0000              +1.0000               +1.0000
 |01⟩    +1.0000              +1.0000               +1.0000
 |10⟩    +1.0000              +1.0000               +1.0000
 |11⟩    +1.0000i              +1.0000i               -1.0000

CP(π) on |s⟩ = H,H|00⟩ (ties to Ch15 §15.2's CZ):
+0.5000   +0.5000   +0.5000   -0.5000
```

CP(π) on the uniform superposition reproduces Chapter 15 §15.2's controlled-Z output exactly —
CP(π) *is* CZ, derived here from a different starting point (a general phase gate rather than
`H·X·H`) but landing on the same operator.

## 16.3 The QFT ladder

For each qubit j (0 is the most-significant, as throughout this book): a Hadamard, then
CP(2π/2^(k−j+1)) controlled by every later qubit k. That produces the transform with its output
bits reversed — §16.4 shows why — so a swap network un-reverses them at the end:

```swift
func appendQFT(_ qc: QuantumCircuit, qubits n: Int, uncompute: Bool = false) {
    for j in 0..<n {
        qc.h(j)
        for k in (j + 1)..<n {
            cp(qc, 2 * Double.pi / pow(2.0, Double(k - j + 1)), k, j)
        }
    }
    if !uncompute {
        for q in 0..<(n / 2) { swapQubits(qc, q, n - 1 - q) }
    }
}
```

Checked against the entrywise formula `e^(2πi·y·c/N)/√N` on every one of the 8 basis states of a
3-qubit register:

```text
gate-level 3-qubit QFT vs. entrywise DFT formula: max amplitude deviation = 1.3788683915077173e-15
```

Fifteen digits of agreement — the five-gate CP(θ) and the swap network really do implement the
same unitary the formula describes.

## 16.4 Why the ladder ends in a swap network

Run the same ladder without the final swaps (`uncompute: true` above) and the *amplitudes* land
at the bit-reversal of where they belong:

```text
no-swap amplitude at y equals swapped amplitude at bit-reverse(y): max deviation = 0.0
```

Zero deviation, not an approximation — the swaps are correcting an exact effect of qubit 0 being
the most-significant bit throughout the H/CP ladder, not a cosmetic fix. Every j-loop's Hadamard
lands its output on the *same* qubit j it started from, but the DFT formula's `y` index counts
bits in the opposite order the ladder naturally produces them, so the fix has to be a genuine
reordering of qubits, not just a relabeling of output.

## 16.5 The QFT of a basis state is a product state

Chapter 15 §15.5 found Grover's two-qubit register drops to `|r| = 0` — full entanglement — the
instant its oracle's `cz` lands. The QFT's `cp`'s look superficially similar (both are built from
`cx`), so it is worth checking whether the QFT entangles its register the same way. Reduced Bloch
cards for a few transformed basis states of a 3-qubit register answer that directly:

```text
QFT|0⟩: q0 x +1.000  y +0.000  z +0.000  |r| 1.000   q1 x +1.000  y -0.000  z +0.000  |r| 1.000   q2 x +1.000  y +0.000  z +0.000  |r| 1.000
QFT|3⟩: q0 x -1.000  y +0.000  z +0.000  |r| 1.000   q1 x -0.000  y -1.000  z +0.000  |r| 1.000   q2 x -0.707  y +0.707  z +0.000  |r| 1.000
QFT|5⟩: q0 x -1.000  y +0.000  z +0.000  |r| 1.000   q1 x +0.000  y +1.000  z +0.000  |r| 1.000   q2 x -0.707  y -0.707  z -0.000  |r| 1.000
```

`|r| = 1` on every qubit, every time — each one stays pure, parked on the Bloch sphere's equator
at a phase set by its own bit of c. That is exactly what the closed form predicts: the transform
of a basis state is a literal tensor product `⊗ⱼ (|0⟩ + e^(2πi·c/2^(j+1))|1⟩)/√2` (Chapter 11's
tensor-product machinery, one Hadamard-rotated qubit per factor), never a sum over more than one
term of any joint basis state. The difference from Grover's `cz` is what it is applied *to*: CP's
inside the QFT ladder act on qubits that started in `|0⟩`/`|1⟩` — a basis state, an eigenstate of
every diagonal phase gate — so they pick up a phase without ever mixing amplitudes between qubits.
Grover's `cz` acts on qubits already in `|+⟩`/`|−⟩` superpositions, where a controlled phase does
mix amplitudes across the joint state. Same gate family, opposite entangling behavior, depending
entirely on what state it meets.

## 16.6 The inverse QFT, and unitarity

QFT† reverses the circuit and negates every angle — same gates, opposite order, opposite phases:

```swift
func appendInverseQFT(_ qc: QuantumCircuit, qubits n: Int) {
    for q in 0..<(n / 2) { swapQubits(qc, q, n - 1 - q) }
    for j in stride(from: n - 1, through: 0, by: -1) {
        for k in stride(from: n - 1, through: j + 1, by: -1) {
            cp(qc, -2 * Double.pi / pow(2.0, Double(k - j + 1)), k, j)
        }
        qc.h(j)
    }
}
```

QFT then QFT† should return every basis state to itself:

```text
QFT then QFT†, every basis state: max |amplitude at c| deviation from 1 = 6.661338147750939e-16
```

Unitary, to the same precision as every other check in this chapter.

## 16.7 Phase estimation: reading a phase out of a counting register

Chapter 13 built phase kickback: a controlled gate applied to an eigenstate doesn't move the
eigenstate, it writes the eigenvalue's phase onto the control qubit instead. Phase estimation is
that trick run n times in parallel and read out with the inverse QFT. Prepare an "eigenstate"
qubit in `|1⟩` — an eigenstate of P(2πφ), since P(2πφ)|1⟩ = e^(2πiφ)|1⟩ — put n counting qubits in
superposition, and apply P(2πφ) to the eigenstate qubit controlled by counting qubit j, raised to
the power 2^(n−1−j). Each controlled power writes one binary digit of φ into a counting qubit's
phase; the inverse QFT reads those digits back out as amplitudes:

```swift
func phaseEstimation(counting n: Int, phase: Double) -> [Double] {
    let total = n + 1
    let qc = QuantumCircuit(qubits: total)
    qc.x(n)                                    // eigenstate |1⟩ of P(θ)
    for q in 0..<n { qc.h(q) }
    for j in 0..<n {
        let power = 1 << (n - 1 - j)
        cp(qc, 2 * Double.pi * phase * Double(power), j, n)
    }
    appendInverseQFT(qc, qubits: n)
    let probs = qc.run().probabilities
    var marginal = [Double](repeating: 0, count: 1 << n)
    for (i, p) in probs.enumerated() { marginal[i >> 1] += p }   // eigenstate qubit is the LSB
    return marginal
}
```

Dyadic phases — exact multiples of 1/8 with 3 counting qubits — come back with certainty:

```text
phase       best estimate   P(that estimate)
0.1250        0.1250          1.0000
0.5000        0.5000          1.0000
0.7500        0.7500          1.0000
```

A phase that isn't a multiple of 1/8 can't land on a single counting value; the distribution
spreads over its neighbors instead:

```text
φ = 0.3, 3 counting qubits:
  y=0 (estimate 0.0000): P = 0.0216
  y=1 (estimate 0.1250): P = 0.0518
  y=2 (estimate 0.2500): P = 0.5775
  y=3 (estimate 0.3750): P = 0.2593
  y=4 (estimate 0.5000): P = 0.0409
  y=5 (estimate 0.6250): P = 0.0194
  y=6 (estimate 0.7500): P = 0.0145
  y=7 (estimate 0.8750): P = 0.0149
```

y = 2 and y = 3 — the two grid points flanking 0.3 — together carry ≈ 0.837 of the probability,
above the textbook worst-case bound of 8/π² ≈ 0.811 for landing within one grid step of the true
value. Sampling a dyadic case directly confirms it at the shot level, with no spread at all:

```text
φ=0.25, 2 counting qubits, 1000 shots:
  011: 1000
```

Every one of 1000 shots reads counting register `01` (= 0.25) with the eigenstate qubit at `1`.

## 16.8 Precision scales with the number of counting qubits

More counting qubits narrow the grid an estimate is rounded to (1/2ⁿ), so the same non-dyadic
φ = 0.3 is resolved more tightly with more of them:

```text
counting qubits   best estimate   error     P
3                  0.2500           0.0500     0.5775
6                  0.2969           0.0031     0.8752
```

Doubling the counting register from 3 to 6 qubits shrinks the error by more than an order of
magnitude *and* concentrates more of the probability on the best estimate — both improve
together, exactly as the theory predicts. This is the general-purpose engine behind Shor's
algorithm: phase estimation applied to a specially chosen unitary turns "find the period of a
function" into "estimate an eigenphase," which is precisely the problem this section just solved.

## Build it in the app

● Every step starts from **Clear**. Qubit 0 is the leftmost bit of every label, as throughout
this book. The P tile's slider (Chapter 7) shows three decimal digits, so an angle it can't hit
exactly — π/8 ≈ 0.393 — still lands within about 2×10⁻⁴ of the real thing.

1. **CP(π/2) on `|11⟩`.** Qubits: 2. Arm **X**, tap `q0` then `q1` in column 0. Then the T-form
   taps: **T** on `q0` (col 1), **CX** `q0`→`q1` (col 2), **T†** on `q1` (col 3), **CX** `q0`→`q1`
   (col 4), **T** on `q1` (col 5). Panel: one row, `|11⟩` with phase `+i` — CP(π/2) landed exactly,
   five palette taps.
2. **The 2-qubit QFT on `|01⟩`.** Clear. Arm **X**, tap `q1` in column 0. Arm **H**, tap `q0` in
   column 1. Then CP(π/2) controlled by `q1` on `q0`: **T** `q1` (col 2), **CX** `q1`→`q0`
   (col 3), **T†** `q0` (col 4), **CX** `q1`→`q0` (col 5), **T** `q0` (col 6). Arm **H**, tap `q1`
   in column 7. Swap as three CX's: **CX** `q0`→`q1`, **CX** `q1`→`q0`, **CX** `q0`→`q1` (columns
   8–10). Panel: four rows at flat `p=0.250`, with phases `+1, +i, −1, −i` on `|00⟩, |01⟩, |10⟩,
   |11⟩` — the QFT of `|01⟩`, matching `e^(2πi·y/4)` for y = 0…3. Tap **Display**: every qubit
   sits on the equator, `|r| = 1`.
3. **Phase estimation, φ = ¼.** Clear, set **Qubits: 3**. Arm **X**, tap `q2` in column 0 (the
   eigenstate). Arm **H**, tap `q0` and `q1` in column 1. CP(π) controlled by `q0` on `q2`, in S
   form: **S** `q0` (col 2), **CX** `q0`→`q2` (col 3), **S†** `q2` (col 4), **CX** `q0`→`q2`
   (col 5), **S** `q2` (col 6). CP(π/2) controlled by `q1` on `q2`, in T form: **T** `q1` (col 7),
   **CX** `q1`→`q2` (col 8), **T†** `q2` (col 9), **CX** `q1`→`q2` (col 10), **T** `q2` (col 11).
   Then the 2-qubit inverse QFT on the counting register: swap `q0`/`q1` as three CX's (cols
   12–14), **H** `q1` (col 15), CP(−π/2) controlled by `q1` on `q0` in T† form: **T†** `q1`
   (col 16), **CX** `q1`→`q0` (col 17), **T** `q0` (col 18), **CX** `q1`→`q0` (col 19), **T†**
   `q0` (col 20), then **H** `q0` (col 21). Panel: one row, `|011⟩` at `p=1.000` — counting `01` =
   ¼, eigenstate `1`. Set **Shots: 1000**, tap **Measure**: every shot reads `011`.
4. **Swap the phase.** Delete the S/T tiles from step 3's counting-register block (columns 2–11)
   and rebuild for a different k: k = 0 needs no controlled-phase tiles at all; k = 2 needs only
   **S**/**S†** on `q1`→`q2` (CP(π)); k = 3 needs **S**/**S†** on `q0`→`q2` (CP(π), since 3π ≡ π)
   and **T†**/**T** on `q1`→`q2` (CP(−π/2), since 3π/2 ≡ −π/2). Each rebuild lands on counting
   register `k` with `p=1.000`.
5. **Optional: the 3-qubit QFT with the slider.** This needs CP(π/4), and P(π/8) has no exact
   palette tile — arm **P**, tap `q2` in the right column, and set the popover's slider as close
   to 0.393 as it will go (the displayed value already rounds to three digits). Building the full
   11-column, 3-qubit ladder this way lands within ~2×10⁻⁴ of the exact transform — visibly close,
   not exact, and the panel's fourth decimal digit is where the difference from §16.3's fifteen-
   digit match shows up.

Two limits worth naming, as earlier chapters did: nothing here needed the `apply(_:)` escape
hatch, but a QFT wider than 3 qubits needs a CP angle finer than π/8 with no exact tile at all —
the slider approximation compounds with every extra qubit, and code becomes the only exact route.

## Run it in code

Every snippet below was run with `RunCodeSnippet` against
`SwiftQiskitApp/SwiftQiskitApp/CircuitModel.swift`.

```swift
import SwiftQiskit

func fmtAmp(_ c: Complex) -> String {
    let re = c.real.magnitude < 1e-9 ? 0 : c.real
    let im = c.imag.magnitude < 1e-9 ? 0 : c.imag
    if im == 0 { return String(format: "%+.4f", re) }
    if re == 0 { return String(format: "%+.4fi", im) }
    return String(format: "%+.4f%+.4fi", re, im)
}

func cp(_ qc: QuantumCircuit, _ theta: Double, _ control: Int, _ target: Int) {
    qc.p(theta / 2, control)
    qc.cx(control, target)
    qc.p(-theta / 2, target)
    qc.cx(control, target)
    qc.p(theta / 2, target)
}
func cpHalfPi(_ qc: QuantumCircuit, _ c: Int, _ t: Int) { qc.t(c); qc.cx(c,t); qc.tdg(t); qc.cx(c,t); qc.t(t) }
func cpPi(_ qc: QuantumCircuit, _ c: Int, _ t: Int) { qc.s(c); qc.cx(c,t); qc.sdg(t); qc.cx(c,t); qc.s(t) }
func swapQubits(_ qc: QuantumCircuit, _ a: Int, _ b: Int) { qc.cx(a, b); qc.cx(b, a); qc.cx(a, b) }

// 16.2 -- CP(theta) on all four basis states, three forms
print("input  CP(π/2) via p()   CP(π/2) via T/T†   CP(π) via S/S†")
for c in 0..<4 {
    let a = QuantumCircuit(qubits: 2); if c & 2 != 0 { a.x(0) }; if c & 1 != 0 { a.x(1) }; cp(a, .pi/2, 0, 1)
    let b = QuantumCircuit(qubits: 2); if c & 2 != 0 { b.x(0) }; if c & 1 != 0 { b.x(1) }; cpHalfPi(b, 0, 1)
    let d = QuantumCircuit(qubits: 2); if c & 2 != 0 { d.x(0) }; if c & 1 != 0 { d.x(1) }; cpPi(d, 0, 1)
    print(" |\(String(c, radix: 2))⟩   ", fmtAmp(a.run()[c]), "  ", fmtAmp(b.run()[c]), "  ", fmtAmp(d.run()[c]))
}
let sPrep = QuantumCircuit(qubits: 2); sPrep.h(0); sPrep.h(1); cpPi(sPrep, 0, 1)
print("\nCP(π) on |s⟩:", (0..<4).map { fmtAmp(sPrep.run()[$0]) }.joined(separator: "   "))

// 16.3-16.4 -- the QFT ladder vs. the DFT formula, and the no-swap bit-reversal
func appendQFT(_ qc: QuantumCircuit, qubits n: Int, uncompute: Bool = false) {
    for j in 0..<n {
        qc.h(j)
        for k in (j + 1)..<n { cp(qc, 2 * Double.pi / pow(2.0, Double(k - j + 1)), k, j) }
    }
    if !uncompute { for q in 0..<(n / 2) { swapQubits(qc, q, n - 1 - q) } }
}
func basisPrep(_ qc: QuantumCircuit, _ c: Int, qubits n: Int) {
    for q in 0..<n where (c >> (n - 1 - q)) & 1 == 1 { qc.x(q) }
}
func bitReverse(_ y: Int, bits: Int) -> Int {
    var r = 0
    for i in 0..<bits { if (y >> i) & 1 == 1 { r |= 1 << (bits - 1 - i) } }
    return r
}

let n = 3, N = 8
var maxDeviation = 0.0
for c in 0..<N {
    let qc = QuantumCircuit(qubits: n)
    basisPrep(qc, c, qubits: n)
    appendQFT(qc, qubits: n)
    let amps = qc.run().amplitudes
    for y in 0..<N {
        let theta = 2 * Double.pi * Double(y * c) / Double(N)
        let want = Complex(cos(theta), sin(theta)) * (1.0 / sqrt(Double(N)))
        maxDeviation = max(maxDeviation, (amps[y] - want).magnitude)
    }
}
print("\ngate-level 3-qubit QFT vs. entrywise DFT formula: max amplitude deviation =", maxDeviation)

let probeInput = 3
let withSwapsCircuit = QuantumCircuit(qubits: n)
basisPrep(withSwapsCircuit, probeInput, qubits: n)
appendQFT(withSwapsCircuit, qubits: n)
let withSwaps = withSwapsCircuit.run().amplitudes
let withoutSwapsCircuit = QuantumCircuit(qubits: n)
basisPrep(withoutSwapsCircuit, probeInput, qubits: n)
appendQFT(withoutSwapsCircuit, qubits: n, uncompute: true)
let withoutSwaps = withoutSwapsCircuit.run().amplitudes
var reorderDeviation = 0.0
for y in 0..<N { reorderDeviation = max(reorderDeviation, (withSwaps[y] - withoutSwaps[bitReverse(y, bits: n)]).magnitude) }
print("no-swap amplitude at y equals swapped amplitude at bit-reverse(y): max deviation =", reorderDeviation)
```

```text
input  CP(π/2) via p()   CP(π/2) via T/T†   CP(π) via S/S†
 |00⟩    +1.0000    +1.0000    +1.0000
 |01⟩    +1.0000    +1.0000    +1.0000
 |10⟩    +1.0000    +1.0000    +1.0000
 |11⟩    +1.0000i    +1.0000i    -1.0000

CP(π) on |s⟩: +0.5000   +0.5000   +0.5000   -0.5000

gate-level 3-qubit QFT vs. entrywise DFT formula: max amplitude deviation = 1.3788683915077173e-15
no-swap amplitude at y equals swapped amplitude at bit-reverse(y): max deviation = 0.0
```

```swift
import SwiftQiskit

func cp(_ qc: QuantumCircuit, _ theta: Double, _ control: Int, _ target: Int) {
    qc.p(theta / 2, control)
    qc.cx(control, target)
    qc.p(-theta / 2, target)
    qc.cx(control, target)
    qc.p(theta / 2, target)
}
func swapQubits(_ qc: QuantumCircuit, _ a: Int, _ b: Int) { qc.cx(a, b); qc.cx(b, a); qc.cx(a, b) }
func appendQFT(_ qc: QuantumCircuit, qubits n: Int) {
    for j in 0..<n {
        qc.h(j)
        for k in (j + 1)..<n { cp(qc, 2 * Double.pi / pow(2.0, Double(k - j + 1)), k, j) }
    }
    for q in 0..<(n / 2) { swapQubits(qc, q, n - 1 - q) }
}
func basisPrep(_ qc: QuantumCircuit, _ c: Int, qubits n: Int) {
    for q in 0..<n where (c >> (n - 1 - q)) & 1 == 1 { qc.x(q) }
}
func card(_ b: BlochVector) -> String { String(format: "x %+.3f  y %+.3f  z %+.3f  |r| %.3f", b.x, b.y, b.z, b.magnitude) }

// 16.5 -- QFT of a basis state is a product state
let n = 3
for c in [0, 3, 5] {
    let qc = QuantumCircuit(qubits: n)
    basisPrep(qc, c, qubits: n)
    appendQFT(qc, qubits: n)
    let state = qc.run()
    print("QFT|\(c)⟩: q0", card(BlochVector(state, qubit: 0)), " q1", card(BlochVector(state, qubit: 1)), " q2", card(BlochVector(state, qubit: 2)))
}
```

```text
QFT|0⟩: q0 x +1.000  y +0.000  z +0.000  |r| 1.000  q1 x +1.000  y -0.000  z +0.000  |r| 1.000  q2 x +1.000  y +0.000  z +0.000  |r| 1.000
QFT|3⟩: q0 x -1.000  y +0.000  z +0.000  |r| 1.000  q1 x -0.000  y -1.000  z +0.000  |r| 1.000  q2 x -0.707  y +0.707  z +0.000  |r| 1.000
QFT|5⟩: q0 x -1.000  y +0.000  z +0.000  |r| 1.000  q1 x +0.000  y +1.000  z +0.000  |r| 1.000  q2 x -0.707  y -0.707  z -0.000  |r| 1.000
```

```swift
import SwiftQiskit

func cp(_ qc: QuantumCircuit, _ theta: Double, _ control: Int, _ target: Int) {
    qc.p(theta / 2, control)
    qc.cx(control, target)
    qc.p(-theta / 2, target)
    qc.cx(control, target)
    qc.p(theta / 2, target)
}
func swapQubits(_ qc: QuantumCircuit, _ a: Int, _ b: Int) { qc.cx(a, b); qc.cx(b, a); qc.cx(a, b) }
func appendQFT(_ qc: QuantumCircuit, qubits n: Int) {
    for j in 0..<n {
        qc.h(j)
        for k in (j + 1)..<n { cp(qc, 2 * Double.pi / pow(2.0, Double(k - j + 1)), k, j) }
    }
    for q in 0..<(n / 2) { swapQubits(qc, q, n - 1 - q) }
}
func basisPrep(_ qc: QuantumCircuit, _ c: Int, qubits n: Int) {
    for q in 0..<n where (c >> (n - 1 - q)) & 1 == 1 { qc.x(q) }
}

// 16.6 -- the inverse QFT, and unitarity
func appendInverseQFT(_ qc: QuantumCircuit, qubits n: Int) {
    for q in 0..<(n / 2) { swapQubits(qc, q, n - 1 - q) }
    for j in stride(from: n - 1, through: 0, by: -1) {
        for k in stride(from: n - 1, through: j + 1, by: -1) { cp(qc, -2 * Double.pi / pow(2.0, Double(k - j + 1)), k, j) }
        qc.h(j)
    }
}

let n = 3
var unitarityDeviation = 0.0
for c in 0..<8 {
    let qc = QuantumCircuit(qubits: n)
    basisPrep(qc, c, qubits: n)
    appendQFT(qc, qubits: n)
    appendInverseQFT(qc, qubits: n)
    let state = qc.run()
    unitarityDeviation = max(unitarityDeviation, (state[c].magnitude - 1.0).magnitude)
}
print("QFT then QFT†, every basis state: max |amplitude at c| deviation from 1 =", unitarityDeviation)
```

```text
QFT then QFT†, every basis state: max |amplitude at c| deviation from 1 = 6.661338147750939e-16
```

```swift
import SwiftQiskit

func cp(_ qc: QuantumCircuit, _ theta: Double, _ control: Int, _ target: Int) {
    qc.p(theta / 2, control)
    qc.cx(control, target)
    qc.p(-theta / 2, target)
    qc.cx(control, target)
    qc.p(theta / 2, target)
}
func swapQubits(_ qc: QuantumCircuit, _ a: Int, _ b: Int) { qc.cx(a, b); qc.cx(b, a); qc.cx(a, b) }
func appendInverseQFT(_ qc: QuantumCircuit, qubits n: Int) {
    for q in 0..<(n / 2) { swapQubits(qc, q, n - 1 - q) }
    for j in stride(from: n - 1, through: 0, by: -1) {
        for k in stride(from: n - 1, through: j + 1, by: -1) { cp(qc, -2 * Double.pi / pow(2.0, Double(k - j + 1)), k, j) }
        qc.h(j)
    }
}
func fmt(_ d: Double) -> String { String(format: "%.4f", d) }

// 16.7 -- standalone phase estimation
func phaseEstimation(counting n: Int, phase: Double) -> [Double] {
    let total = n + 1
    let qc = QuantumCircuit(qubits: total)
    qc.x(n)
    for q in 0..<n { qc.h(q) }
    for j in 0..<n {
        let power = 1 << (n - 1 - j)
        cp(qc, 2 * Double.pi * phase * Double(power), j, n)
    }
    appendInverseQFT(qc, qubits: n)
    let probs = qc.run().probabilities
    var marginal = [Double](repeating: 0, count: 1 << n)
    for (i, p) in probs.enumerated() { marginal[i >> 1] += p }
    return marginal
}

print("phase       best estimate   P(that estimate)")
for phase in [0.125, 0.5, 0.75] {
    let marginal = phaseEstimation(counting: 3, phase: phase)
    let top = marginal.enumerated().max(by: { $0.element < $1.element })!
    print(fmt(phase), "      ", fmt(Double(top.offset) / 8.0), "         ", fmt(top.element))
}

let spread = phaseEstimation(counting: 3, phase: 0.3)
print("\nφ = 0.3, 3 counting qubits:")
for (y, p) in spread.enumerated() where p > 0.01 { print("  y=\(y) (estimate \(fmt(Double(y) / 8.0))): P = \(fmt(p))") }

print("\ncounting qubits   best estimate   error     P")
for counting in [3, 6] {
    let marginal = phaseEstimation(counting: counting, phase: 0.3)
    let top = marginal.enumerated().max(by: { $0.element < $1.element })!
    let estimate = Double(top.offset) / Double(1 << counting)
    print(counting, "                ", fmt(estimate), "         ", fmt(abs(estimate - 0.3)), "   ", fmt(top.element))
}

// 16.7 -- shots for a dyadic phase, 2 counting qubits
let shotQC = QuantumCircuit(qubits: 3)
shotQC.x(2)
shotQC.h(0); shotQC.h(1)
cp(shotQC, 2 * Double.pi * 0.25 * 2, 0, 2)
cp(shotQC, 2 * Double.pi * 0.25 * 1, 1, 2)
appendInverseQFT(shotQC, qubits: 2)
let shotResult = shotQC.measure(shots: 1000)
print("\nφ=0.25, 2 counting qubits, 1000 shots:")
for (state, count) in shotResult.sortedCounts { print("  \(state): \(count)") }
```

```text
phase       best estimate   P(that estimate)
0.1250        0.1250          1.0000
0.5000        0.5000          1.0000
0.7500        0.7500          1.0000

φ = 0.3, 3 counting qubits:
  y=0 (estimate 0.0000): P = 0.0216
  y=1 (estimate 0.1250): P = 0.0518
  y=2 (estimate 0.2500): P = 0.5775
  y=3 (estimate 0.3750): P = 0.2593
  y=4 (estimate 0.5000): P = 0.0409
  y=5 (estimate 0.6250): P = 0.0194
  y=6 (estimate 0.7500): P = 0.0145
  y=7 (estimate 0.8750): P = 0.0149

counting qubits   best estimate   error     P
3                  0.2500           0.0500     0.5775
6                  0.2969           0.0031     0.8752

φ=0.25, 2 counting qubits, 1000 shots:
  011: 1000
```

Finally, the app-path walkthrough behind "Build it in the app," driving `CircuitBuilder` directly
and formatting output exactly as `ResultsView`'s panel does (the `panelRows` helper first defined
in Chapters 7–8, reused unchanged from Chapters 13–15):

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

// step 2: 2-qubit QFT on |01>
var b = CircuitBuilder(qubitCount: 2)
b.place(.x, qubits: [1], column: 0)
b.place(.h, qubits: [0], column: 1)
b.place(.t, qubits: [1], column: 2)
b.place(.cx, qubits: [1, 0], column: 3)
b.place(.tdg, qubits: [0], column: 4)
b.place(.cx, qubits: [1, 0], column: 5)
b.place(.t, qubits: [0], column: 6)
b.place(.h, qubits: [1], column: 7)
b.place(.cx, qubits: [0, 1], column: 8)
b.place(.cx, qubits: [1, 0], column: 9)
b.place(.cx, qubits: [0, 1], column: 10)
print("QFT|01⟩ column count:", b.columnCount())
print("QFT|01⟩ panel:", panelRows(b.buildCircuit().run(), qubits: 2))

// step 3: phase estimation, phi = 1/4, 2 counting + 1 eigenstate qubit, tile forms
var p = CircuitBuilder(qubitCount: 3)
p.place(.x, qubits: [2], column: 0)
p.place(.h, qubits: [0], column: 1); p.place(.h, qubits: [1], column: 1)
p.place(.s, qubits: [0], column: 2)
p.place(.cx, qubits: [0, 2], column: 3)
p.place(.sdg, qubits: [2], column: 4)
p.place(.cx, qubits: [0, 2], column: 5)
p.place(.s, qubits: [2], column: 6)
p.place(.t, qubits: [1], column: 7)
p.place(.cx, qubits: [1, 2], column: 8)
p.place(.tdg, qubits: [2], column: 9)
p.place(.cx, qubits: [1, 2], column: 10)
p.place(.t, qubits: [2], column: 11)
p.place(.cx, qubits: [0, 1], column: 12)
p.place(.cx, qubits: [1, 0], column: 13)
p.place(.cx, qubits: [0, 1], column: 14)
p.place(.h, qubits: [1], column: 15)
p.place(.tdg, qubits: [1], column: 16)
p.place(.cx, qubits: [1, 0], column: 17)
p.place(.t, qubits: [0], column: 18)
p.place(.cx, qubits: [1, 0], column: 19)
p.place(.tdg, qubits: [0], column: 20)
p.place(.h, qubits: [0], column: 21)
print("\nphase estimation column count:", p.columnCount())
print("phase estimation panel:", panelRows(p.buildCircuit().run(), qubits: 3))

// step 5: 3-qubit QFT with the P tile's slider at its displayed value (0.393) instead of pi/8
func cpHalfPi(_ qc: QuantumCircuit, _ c: Int, _ t: Int) { qc.t(c); qc.cx(c,t); qc.tdg(t); qc.cx(c,t); qc.t(t) }
func swapQ(_ qc: QuantumCircuit, _ a: Int, _ b: Int) { qc.cx(a,b); qc.cx(b,a); qc.cx(a,b) }
func qft3(_ halfAngle: Double) -> Double {
    var d = 0.0
    for c in 0..<8 {
        let qc = QuantumCircuit(qubits: 3)
        for q in 0..<3 where (c >> (2-q)) & 1 == 1 { qc.x(q) }
        qc.h(0); cpHalfPi(qc, 1, 0)
        qc.p(halfAngle, 2); qc.cx(2,0); qc.p(-halfAngle, 0); qc.cx(2,0); qc.p(halfAngle, 0)
        qc.h(1); cpHalfPi(qc, 2, 1); qc.h(2); swapQ(qc, 0, 2)
        let a = qc.run().amplitudes
        for y in 0..<8 { let th = 2 * Double.pi * Double(y*c)/8
            d = max(d, (a[y] - Complex(cos(th), sin(th)) * (1/sqrt(8.0))).magnitude) }
    }
    return d
}
print("\nexact half-angle π/8 (=\(Double.pi/8)):", qft3(Double.pi/8))
print("slider-displayed 0.393:", qft3(0.393))
```

```text
QFT|01⟩ column count: 11
QFT|01⟩ panel: ["|00⟩: 0.4999999999999999  (p=0.250)", "|01⟩: 7.850462293418875e-17 + 0.4999999999999999i  (p=0.250)", "|10⟩: -0.4999999999999999  (p=0.250)", "|11⟩: -7.850462293418875e-17 - 0.4999999999999999i  (p=0.250)"]

phase estimation column count: 22
phase estimation panel: ["|011⟩: 0.9999999999999997  (p=1.000)"]

exact half-angle π/8 (=0.39269908169872414): 1.3788683915077173e-15
slider-displayed 0.393: 0.00021278136820529302
```

The 22-column phase-estimation circuit and its `|011⟩` result confirm step 3's tap sequence
exactly — counting register `01` (¼) alongside the eigenstate qubit's `1`. And the slider check
confirms step 5's claim: rounding π/8 to the popover's displayed 0.393 costs about 2×10⁻⁴ in
amplitude, three orders of magnitude worse than the exact construction's ~10⁻¹⁵ but still a close
match on the panel's first three decimal digits.

Re-running the shot-count blocks above will land close to, but not exactly on, the printed splits
where any spread exists — the app-visible statistics are genuinely probabilistic (Chapter 9); the
dyadic 1000-shot blocks above are the exception, since P = 1.0000 there leaves no room to jitter.

## Try it yourself

1. CP(θ) is built as `P(θ/2)_control · CX · P(−θ/2)_target · CX · P(θ/2)_target`, which looks
   asymmetric between control and target. Is `cp(θ, a, b)` the same operator as `cp(θ, b, a)`?
   <details><summary>Answer</summary>Yes — CP(θ) is diagonal, `diag(1, 1, 1, e^(iθ))`, and that
   matrix is symmetric under swapping which qubit is "control" and which is "target," since the
   only nonzero-phase entry is `|11⟩`, unaffected by which label is which. §16.2's four-basis-
   state check would print the identical table with the two arguments swapped.</details>

2. §16.7's app step 3 used **S**/**S†** on `q0`→`q2` and **T**/**T†** on `q1`→`q2` for φ = ¼. Which
   tiles give φ = ¾ instead?
   <details><summary>Answer</summary>φ = ¾ needs CP(2π·¾·2) = CP(3π) on `q0`→`q2` and
   CP(2π·¾·1) = CP(3π/2) on `q1`→`q2`. Since CP(θ) only depends on θ mod 2π, CP(3π) ≡ CP(π) (the
   same S/S† tiles as φ = ¼'s `q0` block) and CP(3π/2) ≡ CP(−π/2) (T†/T tiles, the mirror of
   φ = ¼'s `q1` block). Verified in the app-build's "swap the phase" step: `k=3` reads counting
   `11` with `p=1.000`.</details>

3. §16.4 showed that skipping the swap network puts each amplitude at the bit-reversal of its
   correct position. Where does the 2-qubit QFT of `|01⟩` from the app-build's step 2 land if the
   final three-CX swap is removed?
   <details><summary>Answer</summary>With 2 qubits, bit-reversing y = 0,1,2,3 gives 0,2,1,3 — so
   the swapped result's `|01⟩` amplitude (`+i`) would appear at `|10⟩` instead, and vice versa;
   `|00⟩` and `|11⟩` are their own bit-reversals and stay put. §16.4's check confirms this exactly,
   for the general case, on 3 qubits.</details>

4. §16.8 needed 6 counting qubits to bring φ = 0.3's error down to 0.0031. Roughly how many
   counting qubits would it take to get the error below 0.001?
   <details><summary>Answer</summary>The estimate is rounded to the nearest multiple of 1/2ⁿ, so
   the worst-case error is about 1/2^(n+1); getting below 0.001 needs 2^(n+1) > 1000, i.e. n ≥ 9.
   Checking with `phaseEstimation(counting: 9, phase: 0.3)` confirms an error under 0.001, the
   same pattern §16.8's table already showed between n = 3 and n = 6.</details>

---
[← Chapter 15](15-Grover.md) · [Contents](../../INTRODUCTION.md) · [Chapter 17 →](17-Shor.md)
