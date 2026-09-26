# Chapter 21 — Noise, Density Matrices and Channels

> Where the state-vector picture stops being enough: density matrices, Kraus channels
> (bit-flip, phase-flip, depolarizing, amplitude damping), coherence decay, a Monte-Carlo
> unraveling, and entanglement entropy from a Bell pair's reduced state.

| | |
|---|---|
| Playground page | [`19Noise`](../../../SwiftQiskit/PlaygroundDocs/19NOISEHELP.md) |
| In the app | ◐ — every Kraus channel except depolarizing is exactly reachable by entangling the system with one extra "environment" qubit and reading the system's reduced Bloch vector; purity and entropy are still read off that vector by hand — see "Build it in the app" |
| Library APIs | `QuantumCircuit.h/ry/cx`, `.run()`, `measure(shots:)`, `Matrix` `+`/`-`/scalar `*`, `†`, `Ket * Bra`, `BlochVector(_:qubit:)` |
| Prerequisites | Chapters 4, 9, 11, 12 |

## 21.1 From state vectors to density matrices

Every earlier chapter wrote a qubit's state as a ket `|ψ⟩` — an amplitude vector, always
normalized, always representing *complete* knowledge of the system. That stops being enough the
moment a qubit talks to something you don't get to track: a stray photon, a thermal bath, an
imperfect gate. What's left is a **mixture** — a classical probability distribution over
possible kets — and the object that describes it is the density matrix

```text
ρ = |ψ⟩⟨ψ|        (pure state)
ρ = Σᵢ pᵢ |ψᵢ⟩⟨ψᵢ|  (mixture, Σpᵢ = 1)
```

`ρ = |ψ⟩⟨ψ|` needs nothing new: it's `Ket * Bra`, the same outer product `Dirac.swift` already
provides for the projectors earlier chapters used. A single-qubit ρ is always expressible as
`ρ = (I + r·σ)/2` for some vector `r = (x, y, z)` with `|r| ≤ 1` — exactly the Bloch vector every
`BlochSphereView` already draws, except now the arrow is allowed to have length less than 1.
`|r| = 1` is a pure state; `|r| < 1` is a genuine mixture.

The distinction that matters: a mixture and a superposition can agree on every measurement in
one basis and disagree in another. `½|0⟩⟨0| + ½|1⟩⟨1|` (a coin flip between two *known* states)
and `|+⟩⟨+|` (a genuine superposition) are both diagonal-(0.5, 0.5) in the Z basis — a Z
measurement can't tell them apart — but only one of them has the off-diagonal coherence a
superposition needs:

```text
ρ(|+⟩):        diag 0.500000, 0.500000   off-diag 0.4999999999999999
ρ(mixture):    diag 0.500000, 0.500000   off-diag 0.0
purity: |+⟩ = 1.000000,  mixture = 0.500000
```

Purity, `Tr(ρ²)`, is 1 for any pure state and drops toward `1/d` (here 0.5) the more mixed ρ
becomes — a single number that tracks exactly what the vanishing off-diagonal shows.

## 21.2 Kraus channels

A **quantum channel** is the most general physically allowed evolution of a density matrix:

```text
ρ' = Σᵢ Kᵢ ρ Kᵢ†          subject to  Σᵢ Kᵢ†Kᵢ = I
```

The constraint is trace preservation — probabilities must still sum to 1 after the channel acts
— and it's checked before any channel is trusted, not assumed. Four channels, each as a pair or
quadruple of scaled Pauli/identity matrices:

```text
bit-flip(p):       {√(1−p)·I, √p·X}
phase-flip(p):     {√(1−p)·I, √p·Z}
depolarizing(p):   {√(1−¾p)·I, √(p/4)·X, √(p/4)·Y, √(p/4)·Z}
amp-damping(γ):    {diag(1, √(1−γ)), [[0, √γ], [0, 0]]}
```

The playground page builds these with page-level `addM`/`scaleM` helpers because `Matrix` had
no `+`, `-`, or scalar `*` when it was written. Both now exist (`Math/Matrix.swift`), so this
chapter uses them directly — `I2 * (1 - p).squareRoot()` instead of `scaleM(I2, ...)` — with no
change to any result:

```text
ΣKᵢ†Kᵢ − I max residual, p = 0.3:
  bit-flip:      0.00e+00
  phase-flip:    0.00e+00
  depolarizing:  1.11e-16
  amp-damping:   0.00e+00
```

All four are trace-preserving to floating-point precision.

## 21.3 Coherence decay

Repeated phase-flip(p) applied to `ρ = |+⟩⟨+|` decays the off-diagonal exactly as `(1 − 2p)ⁿ` —
a closed form checked against the simulation at every step, not assumed:

```text
n    off-diag (measured)   (1-2p)ⁿ predicted   [p = 0.1]
1     0.400000              0.400000
5     0.163840              0.163840
10     0.053687              0.053687
20     0.005765              0.005765
```

Purity tracks the same decay from the other side — 0.820000 at n=1, falling toward but never
exactly reaching 0.5 at any finite n (0.505765 at n=10, 0.500066 at n=20). A full depolarizing
round (p=1) reaches the maximally mixed state in one step: `diag(0.5, 0.5)`, purity exactly
0.5 — indistinguishable from a fair coin in *any* basis, not just Z.

## 21.4 Amplitude damping

Dephasing shrinks the Bloch vector's x and y coordinates but never touches z — it's a pure loss
of coherence, not of energy. Amplitude damping is different: it's a channel toward |0⟩'s pole,
model of a qubit at absolute zero relaxing to its ground state. Starting from `|+⟩` (Bloch
`(1, 0, 0)`) and applying γ = 0.2 twenty times:

```text
|+⟩ after 20 rounds of amplitude damping (γ=0.2):
  Bloch (x,y,z) = (0.107374, 0.000000, 0.988471)
  purity = 0.994302
```

x shrinks by `√(1−γ)` per round (`0.8¹⁰ = 0.107374...`), while z rises as `1 − (1−γ)ⁿ`
(`1 − 0.8²⁰ = 0.988471...`). The Bloch vector sitting *inside* the sphere at a point no pure
state can reach — shorter *and* off-center — is the picture dephasing alone can't draw.

## 21.5 Monte-Carlo unraveling

Every channel above can be reproduced from ordinary pure-state code, without a density matrix at
all: per shot, flip a biased coin and apply the error gate or not, then measure. This is how
noise gets added to a state-vector simulator like this one's, and it's the section that turns
the chapter from linear algebra into a program:

```text
Monte-Carlo phase-flip(0.1) on |+⟩, 20000 shots: P(+x) = 0.899050
exact prediction (1+(1-2p))/2 = 0.900000
```

The measured value is statistical — a re-run lands within about ±0.002 of 0.900000 (shot noise
over 20,000 trials), matching what §21.2's exact Kraus channel predicts.

## 21.6 Entanglement entropy from a Bell pair's reduced state

Tracing out one qubit of an entangled pair leaves the other **mixed**, even though the full
2-qubit state is pure — the explanation Chapter 12's marginals were owed. For a single-qubit ρ
with Bloch vector r, the eigenvalues of ρ are always `λ± = (1 ± |r|)/2`, so its von Neumann
entropy `S(ρ) = −Σλ log₂λ` is computable straight from the Bloch magnitude, no matrix
diagonalization required:

```text
Bell pair |Φ⁺⟩: full-state purity = 1.000000
qubit 0's reduced state ρ_A: diag 0.500000, 0.500000, purity 0.500000, entropy 1.000000 bits
product state |+⟩⊗|0⟩: ρ_A entropy = 0.000000 bits
```

The full Bell state is pure (`purity = 1`), but its reduced single-qubit state has `|r| = 0` —
the sphere's center, purity 0.5, entropy exactly **1 bit**, the maximum a single qubit's reduced
state can carry. A product state's marginal stays pure (`entropy = 0`) — no entanglement, no
mixedness. 1 bit is `ln 2 ≈ 0.693147` nats; both describe the same maximally mixed qubit, just in
different units.

## 21.7 A live Bloch gallery

Three Bloch points side by side make the whole chapter visible at once: the pure `|+⟩` on the
equator, its dephased image shrunk toward the center along the same direction, and the fully
depolarized point sitting exactly at the origin. This reuses the app's own additive
`BlochVector(x:y:z:)` initializer (`BlochVector.swift`) — the same one that lets `BlochSphereView`
draw sub-unit arrows for the entangled/mixed states in Chapters 12 and 19 — so no new drawing
code is needed; only the gallery layout itself (`NoiseGalleryView`) is vendored from the
playground page's `Sources/`, per `AUTHORING.md`'s note that these aren't importable.

## Build it in the app

◐ The app has no density-matrix type — `CircuitBuilder` only ever replays unitary gates onto a
`QuantumCircuit`. But every channel above except depolarizing is a mixture of exactly *two*
outcomes (do nothing, or apply one fixed unitary), and a two-outcome mixture is precisely what
one extra "environment" qubit gives you for free: entangle the system with it, and the system's
own **reduced** Bloch vector — already drawn by Display → Final, exactly as in Chapters 12/19/20
— *is* the density matrix's Bloch vector, |r| < 1 included.

Clear, set **Qubits: 2**. Arm **RY**, tap `q0` in column 0, drag to `θ = 1.000` — a test state
with Bloch `(sin 1, 0, cos 1) = (0.841, 0, 0.540)`, off both the pole and the equator so every
channel below visibly moves it.

1. **Bit-flip, p = 0.3.** Arm **RY**, tap `q1` in column 1 (shares the column with q0's tile,
   same as Chapter 20's two-tile columns), drag to `θ = 1.159` (`= 2·arcsin(√0.3)`, the angle
   that puts environment qubit q1 in `cos(θ/2)|0⟩ + sin(θ/2)|1⟩` — a `sin²(θ/2) = 0.3` chance of
   being `|1⟩`). Arm **CX**, tap `q1` then `q0` in column 2 — q1 is the *control*: when it comes
   up `|1⟩`, it flips the system, exactly the Kraus term `√p·X`. Panel:

   ```text
   |00⟩: p=0.539   |01⟩: p=0.069   |10⟩: p=0.161   |11⟩: p=0.231
   ```

   Display → Final on q0: Bloch `(0.841, 0.000, 0.216)` — z has shrunk from 0.540 toward 0 by a
   factor `(1 − 2p) = 0.4`, x is untouched, matching §21.2's Kraus prediction exactly.
2. **Phase-flip, p = 0.3.** Rebuild through q1's tile (steps above), then arm **H**, tap `q0` in
   column 2; arm **CX**, tap `q1` then `q0` in column 3; arm **H**, tap `q0` in column 4 — a
   Hadamard sandwich turns the same CX into a controlled-Z, so q1 coming up `|1⟩` applies Z
   instead of X. Panel:

   ```text
   |00⟩: p=0.539   |01⟩: p=0.231   |10⟩: p=0.161   |11⟩: p=0.069
   ```

   Display → Final on q0: Bloch `(0.337, 0.000, 0.540)` — x has shrunk by `(1 − 2p) = 0.4`, z is
   untouched, the mirror image of step 1.
3. **Amplitude damping, γ = 0.2.** Rebuild q0's opening tile only, then place a controlled-`ry`
   from q0 (system) onto q1 (environment) using the same `cx`-sandwich decomposition Chapter 20
   used for its tilted-axis measurement: arm **RY**, tap `q1` in column 1, drag to `θ = 0.464`
   (`= (2·arcsin(√0.2))/2`); arm **CX**, tap `q0` then `q1` in column 2 (q0 control, q1 target —
   the opposite direction from steps 1–2); arm **RY**, tap `q1` in column 3, drag to `θ = 5.820`
   (`= 2π − 0.464`, the popover's only way to dial in a negative angle, exactly as Chapter 20's
   `2π − θ` trick); arm **CX**, tap `q0` then `q1` in column 4. Finish with the reset step: arm
   **CX**, tap `q1` then `q0` in column 5 (q1 control, q0 target, same direction as steps 1–2).
   Panel:

   ```text
   |00⟩: p=0.770   |01⟩: p=0.046   |10⟩: p=0.184   |11⟩: p=0.000
   ```

   Display → Final on q0: Bloch `(0.753, 0.000, 0.632)` — both x and z have moved, x shrinking
   and z rising toward +1, matching §21.4's toward-|0⟩ pull exactly.
4. **Repeated rounds.** Clear, set **Qubits: 3**. Arm **H**, tap `q0` in column 0 (system →
   `|+⟩`). Give each round its *own* fresh environment qubit (up to 7 rounds fit the app's
   8-qubit maximum): round 1 uses q1 exactly as step 2 above (`θ = 0.644 = 2·arcsin(√0.1)` for
   p = 0.1, columns 1–4); round 2 repeats the same four-tile pattern on q2 (columns 5–8).
   Display → Steps on q0 reads the decay off column by column:

   ```text
   through col 0: q0 Bloch x = 1.000   (before any round)
   through col 4: q0 Bloch x = 0.800   (= (1-2·0.1)¹)
   through col 8: q0 Bloch x = 0.640   (= (1-2·0.1)²)
   ```

   — §21.3's `(1 − 2p)ⁿ` table, reproduced column by column instead of computed.
5. **The Monte-Carlo unraveling.** Rebuild step 2's phase-flip circuit with p = 0.1 on `|+⟩` (arm
   **H** on q0 first), then arm one more **H** on q0 in the next column to change basis, set
   **Shots: 20000**, and tap **Measure**: the `q0 = 0` fraction lands close to 0.900 (a re-run at
   these shot counts landed at 0.897), matching §21.5's exact 0.900000 within shot noise.

**What's still out of reach:** an exact depolarizing channel needs *four* independently weighted
outcomes (I, X, Y, Z), not two, so one environment qubit isn't enough — the "Try it yourself"
exercises below build the two-environment-qubit channel this does give you, and compare its
weights to true depolarizing. Purity and entropy have no numeric readout in the app at all —
both are computed by hand from the Bloch magnitude the Display panel already prints
(`purity = (1 + |r|²)/2`, `entropy` per §21.6's formula). "Run it in code" does all of this
directly.

## Run it in code

Every snippet was run with `RunCodeSnippet` against `SwiftQiskitApp/CircuitModel.swift`.

```swift
import SwiftQiskit

func fmt(_ d: Double) -> String { String(format: "%.6f", d) }

func trace(_ a: Matrix) -> Complex {
    var s = Complex.zero
    for i in 0..<a.rows { s = s + a[i, i] }
    return s
}
func rho(_ psi: Ket) -> Matrix { psi * (psi†) }
func purity(_ r: Matrix) -> Double { trace(r * r).real }

let I2 = Matrix.identity(size: 2)
let X = PauliXGate.matrix
let Y = PauliYGate.matrix
let Z = PauliZGate.matrix

// Section 1: rho = |psi><psi| via Ket * Bra; a mixture vs a superposition.
let rhoPlus = rho(Ket.plus)
let rhoMix = (rho(Ket.zero) + rho(Ket.one)) * 0.5
print("rho(|+>): diag \(fmt(rhoPlus[0,0].real)), \(fmt(rhoPlus[1,1].real))   off-diag \(rhoPlus[0,1])")
print("rho(mix): diag \(fmt(rhoMix[0,0].real)), \(fmt(rhoMix[1,1].real))   off-diag \(rhoMix[0,1])")
print("purity: |+> = \(fmt(purity(rhoPlus))),  mixture = \(fmt(purity(rhoMix)))")

// Section 2: the four Kraus channels, built with Matrix's own +/- and scalar *
// (no addM/scaleM helpers needed, unlike the playground page).
func bitFlipKraus(_ p: Double) -> [Matrix] { [I2 * (1 - p).squareRoot(), X * p.squareRoot()] }
func phaseFlipKraus(_ p: Double) -> [Matrix] { [I2 * (1 - p).squareRoot(), Z * p.squareRoot()] }
func depolarizingKraus(_ p: Double) -> [Matrix] {
    [I2 * (1 - 0.75 * p).squareRoot(), X * (p / 4).squareRoot(),
     Y * (p / 4).squareRoot(), Z * (p / 4).squareRoot()]
}
func ampDampingKraus(_ g: Double) -> [Matrix] {
    var k0 = Matrix(rows: 2, cols: 2)
    k0[0, 0] = .one; k0[1, 1] = Complex((1 - g).squareRoot())
    var k1 = Matrix(rows: 2, cols: 2)
    k1[0, 1] = Complex(g.squareRoot())
    return [k0, k1]
}
func traceResidual(_ ks: [Matrix]) -> Double {
    var sum = Matrix(rows: 2, cols: 2)
    for k in ks { sum = sum + (k†) * k }
    let diff = sum - I2
    var maxAbs = 0.0
    for i in 0..<2 { for j in 0..<2 { maxAbs = max(maxAbs, diff[i, j].magnitude) } }
    return maxAbs
}
print("\nΣKᵢ†Kᵢ − I max residual, p = 0.3:")
print("  bit-flip:      \(String(format: "%.2e", traceResidual(bitFlipKraus(0.3))))")
print("  phase-flip:    \(String(format: "%.2e", traceResidual(phaseFlipKraus(0.3))))")
print("  depolarizing:  \(String(format: "%.2e", traceResidual(depolarizingKraus(0.3))))")
print("  amp-damping:   \(String(format: "%.2e", traceResidual(ampDampingKraus(0.3))))")

func applyChannel(_ ks: [Matrix], _ r: Matrix) -> Matrix {
    var out = Matrix(rows: 2, cols: 2)
    for k in ks { out = out + k * r * (k†) }
    return out
}

// Section 3: coherence decay, exactly (1-2p)^n.
print("\nn    off-diag (measured)   (1-2p)ⁿ predicted   [p = 0.1]")
for n in [1, 5, 10, 20] {
    var r = rhoPlus
    for _ in 1...n { r = applyChannel(phaseFlipKraus(0.1), r) }
    let predicted = 0.5 * pow(0.8, Double(n))
    print("\(n)     \(fmt(r[0,1].real))              \(fmt(predicted))   purity \(fmt(purity(r)))")
}
let fullyDepolarized = applyChannel(depolarizingKraus(1.0), rho(Ket.zero))
print("\nfully depolarized (p=1) on |0>: diag \(fmt(fullyDepolarized[0,0].real)), \(fmt(fullyDepolarized[1,1].real)), purity \(fmt(purity(fullyDepolarized)))")

// Section 4: amplitude damping.
func blochOf(_ r: Matrix) -> (x: Double, y: Double, z: Double) {
    (trace(r * X).real, trace(r * Y).real, trace(r * Z).real)
}
var damped = rhoPlus
for _ in 1...20 { damped = applyChannel(ampDampingKraus(0.2), damped) }
let dampedBloch = blochOf(damped)
print("\n|+> after 20 rounds amp damping (gamma=0.2): (x,y,z) = (\(fmt(dampedBloch.x)), \(fmt(dampedBloch.y)), \(fmt(dampedBloch.z)))  purity \(fmt(purity(damped)))")

// Section 5: the Monte-Carlo unraveling.
let H = HadamardGate.matrix
func monteCarloPhaseFlipXBasis(_ p: Double, shots: Int) -> Double {
    var plusCount = 0
    for _ in 0..<shots {
        var s = StateVector.plus
        if Double.random(in: 0..<1) < p { s.apply(Z) }
        s.apply(H)
        if s.measure() == 0 { plusCount += 1 }
    }
    return Double(plusCount) / Double(shots)
}
let mcP = monteCarloPhaseFlipXBasis(0.1, shots: 20000)
print("\nMonte-Carlo phase-flip(0.1) on |+>, 20000 shots: P(+x) = \(fmt(mcP))")
print("exact prediction (1+(1-2p))/2 = \(fmt((1 + (1 - 2 * 0.1)) / 2))")

// Section 6: Bell-pair partial trace and entropy.
var bell = StateVector(qubits: 2)
bell.apply(H.tensor(I2))
bell.apply(CNOTGate.matrix(qubits: 2, control: 0, target: 1))
let rhoBell = rho(bell)
func partialTraceLast(_ r: Matrix) -> Matrix {
    var out = Matrix(rows: 2, cols: 2)
    for i in 0..<2 { for j in 0..<2 {
        var s = Complex.zero
        for k in 0..<2 { s = s + r[i * 2 + k, j * 2 + k] }
        out[i, j] = s
    } }
    return out
}
func entropy(of r: Matrix) -> Double {
    let b = blochOf(r)
    let mag = (b.x * b.x + b.y * b.y + b.z * b.z).squareRoot()
    let l1 = (1 + mag) / 2, l2 = (1 - mag) / 2
    func log2safe(_ v: Double) -> Double { v <= 0 ? 0 : log2(v) }
    return -(l1 * log2safe(l1) + l2 * log2safe(l2))
}
let rhoA = partialTraceLast(rhoBell)
print("\nBell pair |Φ⁺⟩: full-state purity = \(fmt(purity(rhoBell)))")
print("qubit 0's reduced state ρ_A: diag \(fmt(rhoA[0,0].real)), \(fmt(rhoA[1,1].real)), purity \(fmt(purity(rhoA))), entropy \(fmt(entropy(of: rhoA))) bits")
var product = StateVector(qubits: 2)
product.apply(H.tensor(I2))
let rhoProdA = partialTraceLast(rho(product))
print("product state |+⟩⊗|0⟩: ρ_A entropy = \(fmt(entropy(of: rhoProdA))) bits")
```

```text
rho(|+>): diag 0.500000, 0.500000   off-diag 0.4999999999999999
rho(mix): diag 0.500000, 0.500000   off-diag 0.0
purity: |+> = 1.000000,  mixture = 0.500000

ΣKᵢ†Kᵢ − I max residual, p = 0.3:
  bit-flip:      0.00e+00
  phase-flip:    0.00e+00
  depolarizing:  1.11e-16
  amp-damping:   0.00e+00

n    off-diag (measured)   (1-2p)ⁿ predicted   [p = 0.1]
1     0.400000              0.400000   purity 0.820000
5     0.163840              0.163840   purity 0.553687
10     0.053687              0.053687   purity 0.505765
20     0.005765              0.005765   purity 0.500066

fully depolarized (p=1) on |0>: diag 0.500000, 0.500000, purity 0.500000

|+> after 20 rounds amp damping (gamma=0.2): (x,y,z) = (0.107374, 0.000000, 0.988471)  purity 0.994302

Monte-Carlo phase-flip(0.1) on |+>, 20000 shots: P(+x) = 0.899050
exact prediction (1+(1-2p))/2 = 0.900000

Bell pair |Φ⁺⟩: full-state purity = 1.000000
qubit 0's reduced state ρ_A: diag 0.500000, 0.500000, purity 0.500000, entropy 1.000000 bits
product state |+⟩⊗|0⟩: ρ_A entropy = 0.000000 bits
```

The app-path dilation circuits behind "Build it in the app," checked against the exact Kraus
prediction above:

```swift
import SwiftQiskit

func fmt(_ d: Double) -> String { String(format: "%.6f", d) }
func trace(_ a: Matrix) -> Complex {
    var s = Complex.zero
    for i in 0..<a.rows { s = s + a[i, i] }
    return s
}
func rho(_ psi: Ket) -> Matrix { psi * (psi†) }
let I2 = Matrix.identity(size: 2)
let X = PauliXGate.matrix, Y = PauliYGate.matrix, Z = PauliZGate.matrix
func blochOf(_ r: Matrix) -> (x: Double, y: Double, z: Double) {
    (trace(r * X).real, trace(r * Y).real, trace(r * Z).real)
}
func bitFlipKraus(_ p: Double) -> [Matrix] { [I2 * (1 - p).squareRoot(), X * p.squareRoot()] }
func applyChannel(_ ks: [Matrix], _ r: Matrix) -> Matrix {
    var out = Matrix(rows: 2, cols: 2)
    for k in ks { out = out + k * r * (k†) }
    return out
}

var testState = StateVector.zero
testState.apply(RYGate.matrix(theta: 1.0))
let testRho = rho(testState)
let predicted = blochOf(applyChannel(bitFlipKraus(0.3), testRho))

let b = CircuitBuilder(qubitCount: 2)
b.place(.ry(1.0), qubits: [0], column: 0)
b.place(.ry(2 * asin(0.3.squareRoot())), qubits: [1], column: 1)
b.place(.cx, qubits: [1, 0], column: 2)
let dilated = b.buildCircuit().run()
let actual = BlochVector(dilated, qubit: 0)

print("bit-flip p=0.3   Kraus (\(fmt(predicted.x)), \(fmt(predicted.y)), \(fmt(predicted.z)))   dilation (\(fmt(actual.x)), \(fmt(actual.y)), \(fmt(actual.z)))")
```

```text
bit-flip p=0.3   Kraus (0.841471, 0.000000, 0.216121)   dilation (0.841471, 0.000000, 0.216121)
```

(The same check, run for phase-flip and amplitude damping's own dilation circuits, matched to
six decimal places in every case — the numbers reported under "Build it in the app" above.)

## Try it yourself

1. Confirm a Bell pair's reduced single-qubit state has entropy 1 bit (`ln 2 ≈ 0.693` nats) —
   the maximum a single qubit can carry.
   <details><summary>Answer</summary>This is the density-matrix restatement of Chapter 12's
   "the Bloch arrow collapses to the sphere's center": maximal entanglement means maximal
   entropy in the reduced state. §21.6 verified it directly: `|r| = 0` gives eigenvalues
   `λ± = 0.5, 0.5`, and `−(0.5·log₂0.5 + 0.5·log₂0.5) = 1.000000` bits exactly.</details>
2. The bit-flip channel leaves `|+⟩` completely unchanged for *any* p, but not `|0⟩`. Why?
   <details><summary>Answer</summary>`X|+⟩ = |+⟩` — `|+⟩` is an eigenstate of X, so every term
   in `ρ' = (1−p)ρ + pXρX` is the same `ρ`. `|0⟩` isn't an eigenstate of X (`X|0⟩ = |1⟩`), so the
   channel actually mixes it toward `|1⟩`. In Bloch terms: bit-flip fixes x and multiplies y, z
   by `(1−2p)` — a state already sitting on the x-axis (`|+⟩` is `(1,0,0)`) has nothing to
   shrink.</details>
3. Building the phase-flip dilation of §21.2's "Build it in the app" (env `ry`, then a
   bit-flip dilation right after, on separate environment qubits) gives a 4-outcome Pauli
   channel, not true depolarizing. What are its I/X/Y/Z weights at p = 0.3 on each stage, and how
   do they compare to depolarizing(p)'s `1−¾p, p/4, p/4, p/4`?
   <details><summary>Answer</summary>Applying bit-flip(p) then phase-flip(p) in sequence gives
   weights `I: (1−p)² = 0.49`, `X: p(1−p) = 0.21`, `Z: (1−p)p = 0.21`, `Y: p² = 0.09` (a Y arises
   whenever *both* stages fire, since `XZ = −iY`) — verified by comparing the sequential channel
   to the explicit weighted sum `0.49·ρ + 0.21·XρX + 0.21·ZρZ + 0.09·YρY` (max difference
   1.11e-16). This is *not* depolarizing(0.3), which would give `0.775, 0.075, 0.075, 0.075` —
   two environment qubits give an X/Z-biased channel, not the X/Y/Z-symmetric one depolarizing
   needs. That symmetry (and independent control of all three weights) is exactly what one
   environment qubit's single mixing angle can't provide, which is why depolarizing stays
   ○.</details>
4. Run amplitude damping to `|1⟩` instead of `|+⟩`, for many more rounds than §21.4's twenty.
   What happens to its purity, and how is that different from what dephasing does to
   coherence?
   <details><summary>Answer</summary>Amplitude damping has a *fixed point*: `|0⟩` is left alone
   by every Kraus operator, so repeated rounds drive any state toward it and *purity climbs back
   toward 1* — 30 rounds at γ = 0.3 starting from `|1⟩` gives diag `(0.999977, 0.000023)`,
   purity 0.999955, nearly pure again, just relocated to `|0⟩`. Dephasing has no such pull: its
   fixed points are the whole Z-axis, and repeated rounds only ever push purity *down* toward
   the maximally mixed 0.5, never back up. Energy relaxation has a preferred final state; pure
   decoherence doesn't.</details>

---
[← Chapter 20](20-CHSH.md) · [Contents](../../INTRODUCTION.md) · [Chapter 22 →](22-Tomography.md)
