# Chapter 20 — Bell Tests: The CHSH Inequality

> Why entanglement isn't "hidden classical information": the classical bound enumerated
> exhaustively, a Bell pair's measured S = 2√2, no-signalling confirmed alongside it, and the
> gap plotted live.

| | |
|---|---|
| Playground page | [`15CHSH`](../../../SwiftQiskit/PlaygroundDocs/15CHSHHELP.md) |
| In the app | ● — the Bell pair, both measurement-basis rotations (`ry`), and reading off each of the four settings are all tappable; only the 16-strategy enumeration, the classical model, and summing the four settings into S are code-only — see "Build it in the app" |
| Library APIs | `QuantumCircuit.h/cx/ry`, `.run()`, `measure(shots:)`, `Matrix` `+`/scalar `*`/`⊗`, `†`, `Bra * Matrix`, `BlochVector(_:qubit:)` |
| Prerequisites | Chapters 4, 9, 12 |

## 20.1 The classical bound, enumerated

Suppose Alice and Bob share a pair of particles prepared in advance, then separate. Each picks
one of two measurement settings and gets a ±1 outcome. **Local realism** says: if their
outcomes were fixed all along by *some* shared variable λ — unknown to us, but the same for
both — no matter how λ is distributed or how convoluted the rule mapping (setting, λ) to an
outcome is, the CHSH statistic

```text
S = E(a,b) − E(a,b′) + E(a′,b) + E(a′,b′)
```

(E(x,y) is the average of the product of their ±1 outcomes at settings x, y) can never exceed 2
in magnitude. A deterministic local-hidden-variable strategy is just four fixed answers —
Alice's response to each of her two settings, Bob's to each of his, each ±1, chosen in advance
and independent of what the other side measures. There are 2⁴ = 16 such strategies; enumerating
every one confirms the bound directly, not as a sample:

```text
deterministic strategies checked: 16
max |S| over all of them: 2
```

A randomized λ can only average over these fixed strategies, so it can't escape the bound
either — but it's worth checking with an actual model. Let λ be a shared random direction, and
let each side's answer be "which side of my axis does λ fall on": A(a, λ) = sign(cos(a − λ)),
B(b, λ) = sign(cos(b − λ)). This "classical polarizer" model turns out to **saturate** the
bound rather than merely respect it:

```text
shared-direction model, 200,000 trials per correlator: S ≈ 1.9982
```

(statistical — a re-run lands within about ±0.01 of 2.0000). Its correlator, as a function of
the angle difference, comes out to exactly the line 1 − 2θ/π used later as the classical
comparison curve in §20.7.

## 20.2 Measuring along a tilted axis

A(θ) = cos θ·Z + sin θ·X is the observable "spin measured along an axis tilted θ from Z toward
X." `Matrix` has both entrywise `+` and scalar `*` (`Math/Matrix.swift`), so this is built
directly rather than entrywise:

```text
A(θ) = cos(θ)·Z + sin(θ)·X
```

Measuring A(θ) is `ry(−θ)` followed by an ordinary computational-basis read. The sign of that
rotation isn't obvious from the gate's docstring alone, so it's pinned numerically against the
exact expectation value ⟨ψ|A(θ)|ψ⟩ — computed with the Dirac idiom `ψ† * A(θ) * ψ`
(`Quantum/Dirac.swift`'s `Bra * Matrix` and `Bra * StateVector` operators) rather than a hand
loop — before trusting anything downstream, using the same test qubit as Chapters 4 and 8
(`ry(π/3, 0); rz(π/4, 0)`):

```text
angle    exact ⟨A(θ)⟩   via ry(−θ)+Z
0.0000   0.5000         0.5000
0.5236   0.7392         0.7392
0.7854   0.7866         0.7866
1.5708   0.6124         0.6124
```

The two columns agree at every angle. θ = 0 reproduces Chapters 4/8's ⟨Z⟩ = 0.5000 for this same
qubit; θ = π/2 reproduces their ⟨X⟩ = 0.6124. A(θ) really does interpolate between Z and X.

## 20.3 A Bell pair's correlations, two ways

On a Bell pair |Φ⁺⟩ = (|00⟩ + |11⟩)/√2, every E(a,b) is computed both exactly
(⟨ψ|A(a)⊗A(b)|ψ⟩, using the same Dirac idiom plus `Matrix`'s `⊗`) and by sampling 4000 shots
after rotating each qubit into its measurement basis (`ry(-a, 0); ry(-b, 1)`, then counting
"same"/"different" outcomes as ±1):

```text
setting pair      exact E    sampled E   cos(a−b)
(a, b)     0.7071    0.7055     0.7071
(a, b')   -0.7071   -0.7230    -0.7071
(a', b)    0.7071    0.7215     0.7071
(a', b')   0.7071    0.6915     0.7071
```

Both columns agree with cos(a − b); the sampled column jitters by a few hundredths at 4000
shots, as expected.

## 20.4 S = 2√2

At a = 0, a′ = π/2, b = π/4, b′ = 3π/4, all four correlators have magnitude 1/√2 and their signs
add constructively:

```text
exact S = 2.8284   (2√2 = 2.8284)
sampled S = 2.8405
```

The exact value is exactly 2√2, comfortably clear of the classical 2 — and §20.1 showed that
bound is exhaustive, not just unbeaten by one model.

## 20.5 Controls: entanglement is necessary, and Tsirelson's bound

A product state gives a smaller S at the same angles — entanglement is necessary for the
violation, not incidental:

```text
product state |+⟩⊗|+⟩: S = 1.4142   (= √2)
```

Quantum mechanics beats the classical bound but doesn't reach the algebraic maximum of 4
either. Sweeping the second setting (holding a = 0, a′ = π/2 fixed, b′ = b + π/2) finds a hard
ceiling:

```text
max |S| over the b-sweep (a=0, a'=pi/2 fixed): 2.8284   (Tsirelson: 2.8284)
```

Nothing beats 2√2 — Tsirelson's bound, confirmed by a sweep rather than merely asserted.

## 20.6 No signalling

The violation never lets Alice send Bob a message. Whatever basis-rotation angle Alice applies
to q0, Bob's own marginal statistics don't move at all:

```text
Alice's ry(-a) setting   Bob's marginal P(q1=0)
0.0000   0.5000
0.5236   0.5000
0.7854   0.5000
1.5708   0.5000
3.1416   0.5000
```

The same holds for q1's reduced Bloch vector (`BlochVector(_:qubit:)`, Chapter 12): it stays
pinned at |r| = 0 for every angle Alice chooses —

```text
Alice's ry(-a) setting   q1 Bloch |r|
0.0000   0.0000
0.5236   0.0000
0.7854   0.0000
1.5708   0.0000
3.1416   0.0000
```

— exactly the maximally-mixed marginal Chapter 12 found for the Bell state. The correlations
that violate CHSH only show up when Alice and Bob later compare notes and look at the *joint*
statistics; neither side's own data, taken alone, ever changes.

## 20.7 The gap, plotted

E(θ) = ⟨A(0)⊗A(θ)⟩ = cos θ against the shared-direction classical model from §20.1 (the line
1 − 2θ/π on [0, π]):

```text
θ        quantum cos θ   classical line
0.0000    1.0000          1.0000
0.3927    0.9239          0.7500
0.7854    0.7071          0.5000
1.1781    0.3827          0.2500
1.5708    0.0000          0.0000
1.9635   -0.3827         -0.2500
2.3562   -0.7071         -0.5000
2.7489   -0.9239         -0.7500
3.1416   -1.0000         -1.0000
```

The two columns agree only at θ = 0, π/2, π and diverge most (≈0.207) near θ = π/4 and 3π/4 —
precisely where §20.4's four angles sit. The playground page renders this as three series on
one chart (`CHSHChartView`, a stateless SwiftUI `Canvas` chart vendored in
`Playgrounds.playground/Sources/`): the exact cos θ curve, the classical comparison line, and
nine 500-shot samples scattered near the quantum curve. Like the Bloch views this book already
vendors into the app (`BlochSphereView.swift`, `Bloch3DSphereView.swift`), `CHSHChartView` lives
in a playground `Sources/` folder and isn't importable outside the playground, so it isn't part
of the app; the visible gap between its blue and red curves around θ = π/4 *is* the CHSH
violation made geometric.

## Build it in the app

● Every quantum step above is tappable. Clear, set **Qubits: 2**.

1. **The Bell pair.** Arm **H**, tap `q0` in column 0. Arm **CX**, tap `q0` then `q1` in
   column 1. State Vector panel: two rows at `|00⟩` and `|11⟩`, each p=0.500 — the familiar
   Bell state.
2. **Arm both measurement rotations.** Arm **RY**, tap `q0` in column 2 (θ starts at 0, a
   no-op). Arm **RY** again, tap `q1` in column 2 (shares the column with q0's tile — different
   qubit, exactly like Chapter 19's shared-column Toffoli tiles). Because the popover's slider
   only runs over 0…2π and `ry(−θ)` is what §20.2 calls for, every setting angle below is dialed
   in as `2π − θ` — a global phase, invisible to every probability and Bloch point this chapter
   reads off:

   | setting | angle | tile θ (drag to) |
   |---|---|---|
   | a | 0 | `0.000` |
   | a′ | π/2 | `4.712` (≈ 3π/2) |
   | b | π/4 | `5.498` (≈ 7π/4) |
   | b′ | 3π/4 | `3.927` (≈ 5π/4) |

3. **Read off E(a,b).** Drag q0's tile to `0.000` and q1's tile to `5.498`. Panel:

   ```text
   |00⟩: -0.653  (p=0.427)
   |01⟩:  0.271  (p=0.073)
   |10⟩: -0.271  (p=0.073)
   |11⟩: -0.653  (p=0.427)
   ```

   E = (p00 + p11) − (p01 + p10) = (0.427 + 0.427) − (0.073 + 0.073) = 0.707, matching §20.3's
   exact 0.7071.
4. **The other three settings.** Re-drag the two tiles to each remaining pair and read the same
   four probabilities off the panel:

   | setting pair | tile θ (q0, q1) | p00 | p01 | p10 | p11 | E |
   |---|---|---|---|---|---|---|
   | (a, b′) | 0.000, 3.927 | 0.073 | 0.427 | 0.427 | 0.073 | −0.707 |
   | (a′, b) | 4.712, 5.498 | 0.427 | 0.073 | 0.073 | 0.427 | 0.707 |
   | (a′, b′) | 4.712, 3.927 | 0.427 | 0.073 | 0.073 | 0.427 | 0.707 |

   S = E(a,b) − E(a,b′) + E(a′,b) + E(a′,b′) = 0.707 − (−0.707) + 0.707 + 0.707 = 2.828,
   matching §20.4's exact 2.8284.
5. **Measure it.** Rebuild the (a, b) setting (tiles at `0.000`/`5.498`), set **Shots: 1000**,
   tap **Measure**:

   ```text
   1000 shots (q0 q1):
     00: 426
     01: 68
     10: 85
     11: 421
   ```

   Sampled E ≈ (426 + 421 − 68 − 85)/1000 = 0.694 — close to the exact 0.707 (a fresh tap will
   jitter, per §20.3).
6. **The product-state control.** Remove the CX tile (§20.5). Display → Final on q0 and q1 now
   shows two independent points instead of the Bell pair's maximally-mixed pair — rebuild the
   panel reading from step 4 with the CX gone and the same four settings gives the smaller
   S = 1.414.
7. **No signalling.** With the Bell pair and CX back in place, drag q0's tile through several
   values while leaving q1's tile at `0.000`; Display → Final on q1 stays put at the sphere's
   center (|r| = 0) throughout, per §20.6 — Alice's choice never moves Bob's own marginal.

What stays in code: the 16-strategy enumeration and the shared-direction Monte Carlo model
(§20.1) are plain Swift, not circuits; `CHSHChartView` (§20.7) is a vendored playground view,
not part of the app; and summing the four settings into S is arithmetic you do by hand from the
panel, not a button. "Run it in code" below does all three.

## Run it in code

Every snippet was run with `RunCodeSnippet` against `SwiftQiskitApp/CircuitModel.swift`.

```swift
import Foundation

// Section 1: the classical bound, enumerated exhaustively, plus the
// shared-direction hidden-variable model that saturates it.
var maxClassicalS = 0
for a in [-1, 1] {
    for ap in [-1, 1] {
        for b in [-1, 1] {
            for bp in [-1, 1] {
                let S = a * b - a * bp + ap * b + ap * bp
                maxClassicalS = max(maxClassicalS, abs(S))
            }
        }
    }
}
print("deterministic strategies checked: 16")
print("max |S| over all of them: \(maxClassicalS)")

func lhvSign(_ setting: Double, _ lambda: Double) -> Double {
    cos(setting - lambda) >= 0 ? 1.0 : -1.0
}
func lhvCorrelator(_ a: Double, _ b: Double, trials: Int) -> Double {
    var sum = 0.0
    for _ in 0..<trials {
        let lambda = Double.random(in: 0..<(2 * Double.pi))
        sum += lhvSign(a, lambda) * lhvSign(b, lambda)
    }
    return sum / Double(trials)
}
let a = 0.0, ap = Double.pi / 2, b = Double.pi / 4, bp = 3 * Double.pi / 4
let lhvS = lhvCorrelator(a, b, trials: 200_000) - lhvCorrelator(a, bp, trials: 200_000)
    + lhvCorrelator(ap, b, trials: 200_000) + lhvCorrelator(ap, bp, trials: 200_000)
print("shared-direction model S ≈ \(String(format: "%.4f", lhvS))")
```

```text
deterministic strategies checked: 16
max |S| over all of them: 2
shared-direction model S ≈ 1.9982
```

```swift
import SwiftQiskit

func fmt(_ d: Double) -> String { String(format: "%.4f", d) }

// Section 2: A(theta) built with Matrix's own + and scalar *, sign-pinned
// against ry(-theta) using the Dirac psi-dagger * M * psi idiom.
func A(_ theta: Double) -> Matrix {
    let Z = Matrix([[Complex(1), Complex(0)], [Complex(0), Complex(-1)]])
    let X = Matrix([[Complex(0), Complex(1)], [Complex(1), Complex(0)]])
    return cos(theta) * Z + sin(theta) * X
}

let testQubit = QuantumCircuit(qubits: 1)
testQubit.ry(Double.pi / 3, 0)
testQubit.rz(Double.pi / 4, 0)
let testPsi = testQubit.run()

print("angle    exact ⟨A(θ)⟩   via ry(−θ)+Z")
for angle in [0.0, Double.pi / 6, Double.pi / 4, Double.pi / 2] {
    let exact = (testPsi† * A(angle) * testPsi).real
    var rotated = testPsi
    rotated.apply(RYGate.matrix(theta: -angle))
    let viaMeasurement = rotated.probabilities[0] - rotated.probabilities[1]
    print("\(fmt(angle))   \(fmt(exact))         \(fmt(viaMeasurement))")
}

// Sections 3-4: Bell-pair correlators two ways, and the violation.
let bell = QuantumCircuit(qubits: 2)
bell.h(0); bell.cx(0, 1)
let bellState = bell.run()

func exactCorrelator(_ x: Double, _ y: Double, state: StateVector) -> Double {
    (state† * (A(x) ⊗ A(y)) * state).real
}
func sampledCorrelator(_ x: Double, _ y: Double, shots: Int) -> Double {
    let qc = QuantumCircuit(qubits: 2)
    qc.h(0); qc.cx(0, 1)
    qc.ry(-x, 0); qc.ry(-y, 1)
    let counts = qc.measure(shots: shots)
    var total = 0.0
    for (outcome, count) in counts.counts {
        let bits = Array(outcome)
        total += (bits[0] == bits[1] ? 1.0 : -1.0) * Double(count)
    }
    return total / Double(shots)
}

print("\nsetting pair      exact E    sampled E   cos(a−b)")
for (x, y, name) in [(a, b, "(a, b)  "), (a, bp, "(a, b') "), (ap, b, "(a', b) "), (ap, bp, "(a', b')")] {
    print("\(name)   \(fmt(exactCorrelator(x, y, state: bellState)))    \(fmt(sampledCorrelator(x, y, shots: 4000)))     \(fmt(cos(x - y)))")
}

let exactS = exactCorrelator(a, b, state: bellState) - exactCorrelator(a, bp, state: bellState)
    + exactCorrelator(ap, b, state: bellState) + exactCorrelator(ap, bp, state: bellState)
print("\nexact S = \(fmt(exactS))   (2√2 = \(fmt(2 * sqrt(2))))")
```

```text
angle    exact ⟨A(θ)⟩   via ry(−θ)+Z
0.0000   0.5000         0.5000
0.5236   0.7392         0.7392
0.7854   0.7866         0.7866
1.5708   0.6124         0.6124

setting pair      exact E    sampled E   cos(a−b)
(a, b)     0.7071    0.7055     0.7071
(a, b')   -0.7071    -0.7230    -0.7071
(a', b)    0.7071    0.7215     0.7071
(a', b')   0.7071    0.6915     0.7071

exact S = 2.8284   (2√2 = 2.8284)
```

```swift
import SwiftQiskit

func fmt(_ d: Double) -> String { String(format: "%.4f", d) }
func A(_ theta: Double) -> Matrix {
    let Z = Matrix([[Complex(1), Complex(0)], [Complex(0), Complex(-1)]])
    let X = Matrix([[Complex(0), Complex(1)], [Complex(1), Complex(0)]])
    return cos(theta) * Z + sin(theta) * X
}
func exactCorrelator(_ x: Double, _ y: Double, state: StateVector) -> Double {
    (state† * (A(x) ⊗ A(y)) * state).real
}

// Section 5: entanglement is necessary, and the Tsirelson sweep.
let product = QuantumCircuit(qubits: 2)
product.h(0); product.h(1)
let productState = product.run()
let a = 0.0, ap = Double.pi / 2, b = Double.pi / 4, bp = 3 * Double.pi / 4
let productS = exactCorrelator(a, b, state: productState) - exactCorrelator(a, bp, state: productState)
    + exactCorrelator(ap, b, state: productState) + exactCorrelator(ap, bp, state: productState)
print("product state |+⟩⊗|+⟩: S = \(fmt(productS))")

let bell = QuantumCircuit(qubits: 2)
bell.h(0); bell.cx(0, 1)
let bellState = bell.run()
var maxSweptS = 0.0
var probe = 0.0
while probe < Double.pi {
    let s = exactCorrelator(0, probe, state: bellState) - exactCorrelator(0, probe + Double.pi / 2, state: bellState)
        + exactCorrelator(Double.pi / 2, probe, state: bellState) + exactCorrelator(Double.pi / 2, probe + Double.pi / 2, state: bellState)
    maxSweptS = max(maxSweptS, abs(s))
    probe += 0.001
}
print("max |S| over the b-sweep: \(fmt(maxSweptS))   (Tsirelson: \(fmt(2 * sqrt(2))))")

// Section 6: no-signalling — Bob's marginal and q1's reduced Bloch vector
// stay fixed for every setting Alice chooses.
print("\nAlice's ry(-a) setting   Bob's marginal P(q1=0)")
for angle in [0.0, Double.pi / 6, Double.pi / 4, Double.pi / 2, Double.pi] {
    let qc = QuantumCircuit(qubits: 2)
    qc.h(0); qc.cx(0, 1)
    qc.ry(-angle, 0)
    let state = qc.run()
    let pQ1zero = state.probabilities[0] + state.probabilities[2]   // q0 is the MSB
    print("\(fmt(angle))   \(fmt(pQ1zero))")
}
```

```text
product state |+⟩⊗|+⟩: S = 1.4142
max |S| over the b-sweep: 2.8284   (Tsirelson: 2.8284)

Alice's ry(-a) setting   Bob's marginal P(q1=0)
0.0000   0.5000
0.5236   0.5000
0.7854   0.5000
1.5708   0.5000
3.1416   0.5000
```

Finally, the app-path walkthrough behind "Build it in the app," driving `CircuitBuilder`
directly:

```swift
import SwiftQiskit

@MainActor
func appCorrelator(_ qTileA: Double, _ qTileB: Double) -> Double {
    var b = CircuitBuilder(qubitCount: 2)
    b.place(.h, qubits: [0], column: 0)
    b.place(.cx, qubits: [0, 1], column: 1)
    b.place(.ry(qTileA), qubits: [0], column: 2)
    b.place(.ry(qTileB), qubits: [1], column: 2)
    let p = b.buildCircuit().run().probabilities
    return (p[0] + p[3]) - (p[1] + p[2])
}

func fmt(_ d: Double) -> String { String(format: "%.4f", d) }

MainActor.assumeIsolated {
    let twoPi = 2 * Double.pi
    // tile theta = 2*pi - angle: the popover slider only runs over 0...2*pi,
    // and ry(-angle) = ry(2*pi - angle) up to a global phase.
    let aTile = 0.0
    let apTile = twoPi - Double.pi / 2
    let bTile = twoPi - Double.pi / 4
    let bpTile = twoPi - 3 * Double.pi / 4

    let eab = appCorrelator(aTile, bTile)
    let eabp = appCorrelator(aTile, bpTile)
    let eapb = appCorrelator(apTile, bTile)
    let eapbp = appCorrelator(apTile, bpTile)
    print("E(a,b)=\(fmt(eab))  E(a,b')=\(fmt(eabp))  E(a',b)=\(fmt(eapb))  E(a',b')=\(fmt(eapbp))")
    print("S = \(fmt(eab - eabp + eapb + eapbp))")
}
```

```text
E(a,b)=0.7071  E(a,b')=-0.7071  E(a',b)=0.7071  E(a',b')=0.7071
S = 2.8284
```

## Try it yourself

1. Confirm no classical assignment of ±1 outcomes to the four settings can reach S > 2.
   <details><summary>Answer</summary>This is exactly §20.1's exhaustive enumeration — every
   one of the 16 deterministic local strategies caps out at |S| ≤ 2, and the shared-direction
   randomized model saturates rather than beats it (S ≈ 1.9982, statistical).</details>

2. Build the singlet |Ψ⁻⟩ = (|01⟩ − |10⟩)/√2 instead (`h(0); cx(0,1); x(1); z(0)`) and predict
   S at the standard angles.
   <details><summary>Answer</summary>The singlet's correlator is the negative of the Bell
   pair's, E(a,b) = −cos(a − b) — confirmed at all four setting pairs — giving
   S = −2.8284, a violation in the opposite direction. Relabeling Bob's ±1 outcome convention
   (treating "different" as +1 instead of "same") flips every correlator's sign and restores
   S = +2.8284 — the singlet violates CHSH exactly as strongly as |Φ⁺⟩, just with Bob's two
   particles anti-correlated instead of correlated at matched settings.</details>

3. Instead of rotating both qubits (`ry(-a, 0)` and `ry(-b, 1)`), rotate only q1, by the angle
   difference b − a. Predict E and check it against the two-tile version.
   <details><summary>Answer</summary>They match exactly — verified at (a=0, b=π/4): both give
   E = 0.7071; at (a=π/2, b=π/4): both give 0.7071; at (a=π/6, b=π/3): both give 0.8660. The
   Bell state |Φ⁺⟩ is invariant under any matched real rotation applied to both qubits
   (RY(θ)⊗RY(θ)|Φ⁺⟩ = |Φ⁺⟩), so `ry(-a,0); ry(-b,1)` is the same measurement as
   `ry(-a,0); ry(-a,1); ry(-(b-a),1)` — and the first two rotations cancel against the
   invariance, leaving only `ry(-(b-a))` on q1.</details>

4. Replace the Bell pair's `h(0)` with `ry(θ, 0)` before the `cx`, giving a *partially*
   entangled state instead of a maximally entangled one. Predict S at the standard angles as a
   function of θ.
   <details><summary>Answer</summary>S = √2(1 + sin θ) — confirmed numerically at five angles,
   matching the closed form to four decimals at each (e.g. θ=π/3 gives S=2.6390 both ways).
   θ=0 gives the unentangled product-state result S=√2 (§20.5); θ=π/2 reproduces the full Bell
   pair's 2√2, since `ry(π/2)|0⟩` is exactly `h|0⟩`. The classical bound of 2 is crossed at
   sin θ = √2 − 1, i.e. θ ≈ 0.4271 — below that angle the state is entangled but too weakly to
   violate CHSH at these particular settings.</details>

---
[← Chapter 19](19-ErrorCorrection.md) · [Contents](../../INTRODUCTION.md) · [Chapter 21 →](21-Noise.md)
