# Chapter 23 — Variational Algorithms: VQE

> Finding a ground-state energy by optimization instead of diagonalization: an H₂ Hamiltonian, a
> one-parameter ansatz confined to a single 2×2 block, exact parameter-shift gradients, and
> gradient descent that converges to the exact answer in about ten steps.

| | |
|---|---|
| Playground page | [`18VQE`](../../../SwiftQiskit/PlaygroundDocs/18VQEHELP.md) |
| In the app | ◐ — the one-parameter ansatz (`x`, `ry(θ)`, `cx`) is tappable and its state readable at any θ; computing the Hamiltonian's expectation value, the gradient, and running the optimization loop is code-only |
| Library APIs | `QuantumCircuit.x/ry/cx`, `.run()`, `Matrix` `+`/scalar `*`/`⊗`, `†`, `Bra * Matrix * Ket` |
| Prerequisites | Chapters 4, 8, 22 |

## 23.1 The H₂ Hamiltonian

Every algorithm so far has run a *fixed* circuit: compiled once, executed once (or sampled many
times), done. VQE is different — it's the loop that defines the NISQ era, and the reason
today's small, noisy devices are usable for anything beyond toy demonstrations at all:

```text
1. Prepare a trial state |ψ(θ)⟩ from a parameterized circuit (the "ansatz").
2. Measure the expectation value E(θ) = ⟨ψ(θ)|H|ψ(θ)⟩ of a target Hamiltonian H.
3. Let a classical optimizer choose a new θ that should lower E(θ).
4. Repeat until E(θ) stops improving.
```

No step here needs to diagonalize H directly — the exponential cost §0.2 described for a
classical computer representing an n-qubit state never appears, because the quantum computer
only ever *prepares* states and *measures* them. The target this chapter minimizes over is the
qubit Hamiltonian for H₂ in a minimal (STO-3G) basis, after the Jordan–Wigner transform, near
its equilibrium bond length — the standard worked example from the VQE literature (O'Malley et
al., 2016), reused across most VQE tutorials because it is small enough to check by hand:

```text
H = g₀·I⊗I + g₁·Z⊗I + g₂·I⊗Z + g₃·Z⊗Z + g₄·Y⊗Y + g₅·X⊗X

g = (-0.4804, 0.3435, -0.4347, 0.5716, 0.0910, 0.0910)
```

`Matrix` already has scalar multiplication and `+` (Chapter 21 leaned on the same two operators
for its Kraus channels), and `⊗` for the Pauli tensor products, so the Hamiltonian is one
expression, not a hand-rolled entrywise loop:

```swift
let H = (I2 ⊗ I2) * g[0] + (Z ⊗ I2) * g[1] + (I2 ⊗ Z) * g[2]
      + (Z ⊗ Z) * g[3] + (Y ⊗ Y) * g[4] + (X ⊗ X) * g[5]
```

`X⊗X` and `Y⊗Y` each flip *both* qubits at once, so they only ever connect `|00⟩` with `|11⟩`
and `|01⟩` with `|10⟩` — never a state in one pair with a state in the other. That makes `H`
block-diagonal in the `{|00⟩,|11⟩}` and `{|01⟩,|10⟩}` pairs, a fact §23.2's ansatz is built to
exploit.

## 23.2 A one-parameter ansatz

The entire variational family this chapter searches over is three gates and one real number:

```swift
func ansatz(_ theta: Double) -> StateVector {
    let qc = QuantumCircuit(qubits: 2)
    qc.x(0); qc.ry(theta, 1); qc.cx(1, 0)
    return qc.run()
}
```

Traced through by hand: `x(0)` flips qubit 0 to `|10⟩`. `ry(θ, 1)` then rotates *only* qubit 1,
giving `cos(θ/2)|10⟩ + sin(θ/2)|11⟩`. `cx(1, 0)` — qubit 1 as control, qubit 0 as target — leaves
the `|10⟩` term alone (control is `0`) but flips qubit 0 in the `|11⟩` term (control is `1`),
turning it into `|01⟩`:

```text
ansatz(θ) = cos(θ/2)|10⟩ + sin(θ/2)|01⟩
```

Never `|00⟩`, never `|11⟩`, for any θ — confirmed directly rather than assumed:

```text
ansatz(0.9): |00⟩=0.000000  |01⟩=0.434966  |10⟩=0.900447  |11⟩=0.000000
```

`sin(0.45) = 0.434966` and `cos(0.45) = 0.900447` match the amplitudes exactly. The ansatz is
provably confined to the `{|01⟩,|10⟩}` block of §23.1's Hamiltonian for every θ — exactly the
"single-excitation" subspace chemists care about for H₂, and the reason a *one-parameter*
family is enough to reach this Hamiltonian's ground state at all.

## 23.3 The energy landscape

The energy is Chapter 4/8's Dirac expectation-value idiom, unchanged: `⟨ψ|H|ψ⟩` is `psi† * H *
psi`.

```swift
func energy(_ theta: Double) -> Double {
    let psi = ansatz(theta)
    return (psi† * H * psi).real
}
```

```text
θ        E(θ)
0.000000  -1.830200
1.570796  -0.870000
3.141593  -0.273800
4.712389  -1.234000
```

This is the *exact* expectation value, read straight off the simulator's state vector — a real
device never gets this directly. It would instead measure each of the six Pauli terms
(`I⊗I, Z⊗I, I⊗Z, Z⊗Z, Y⊗Y, X⊗X`) in its own basis via `measure(shots:)`, exactly Chapter 22's
basis-rotation-then-measure trick, and add up the weighted shot averages — the "measure only the
Hamiltonian's own Pauli terms" idea §22.6 named as VQE's escape from tomography's exponential
cost. That estimation step is real, and it's why VQE energies on actual hardware carry shot
noise on top of everything below; this chapter, like the playground page it's drawn from, uses
the exact expectation value throughout so the optimizer's behavior can be graded against a
closed-form answer without shot noise obscuring it.

Because the ansatz never leaves the `{|01⟩,|10⟩}` block, that block's own eigenvalues are the
exact ground energy — no eigensolver needed, just the closed form for a 2×2 Hermitian matrix
`[[a, b],[b*, d]]`: eigenvalues `(a+d)/2 ± √(((a-d)/2)² + |b|²)`.

```text
exact electronic ground energy = -1.851199 Ha
total with nuclear repulsion   = -1.145699 Ha
```

(Nuclear repulsion, 0.7055 Ha, is a fixed classical offset from the nuclei's own Coulomb
repulsion — it plays no role in the qubit Hamiltonian or the optimization, only in the number a
chemist would actually quote.) `E(0) = -1.830200` is already close to this exact ground energy,
but only gradient descent (§23.5) confirms just how close the optimum sits nearby.

## 23.4 Exact gradients via the parameter-shift rule

`ry(θ)` is generated by the Pauli `Y`, and `Y² = I`, so its gradient has a closed form that
needs no infinitesimal limit at all — the **parameter-shift rule**:

```text
dE/dθ = [E(θ + π/2) − E(θ − π/2)] / 2
```

This is *exact*, not an approximation, for any gate of the form `exp(-iθP/2)` with `P² = I` —
unlike a finite difference, which only converges to the true derivative as its step size `h → 0`
and always carries some truncation error at any finite `h`. Checked against an ordinary central
finite difference (`h = 10⁻⁵`) before trusting it:

```text
θ      param-shift    finite-diff
0.000000  0.182000     0.182000
0.400000  0.470678     0.470678
1.000000  0.753168     0.753168
2.500000  0.319923     0.319923
```

They agree to six decimal places at every θ tried — not because parameter-shift is only
*approximately* right, but because `h = 10⁻⁵` is already small enough that the finite
difference's own truncation error is below the precision printed. The real advantage of
parameter-shift shows up on hardware, not in this table: it needs the same two energy
evaluations as the finite difference, but at a hardware-safe angle (`π/2`) instead of a
vanishingly small one that shot noise would swamp.

## 23.5 Gradient descent, plotted live

Plain gradient descent, fixed learning rate 1.0, starting from θ = 0:

```text
step   θ           E(θ)
1      -0.182000   -1.850288
10      -0.229744   -1.851199
20      -0.229744   -1.851199
30      -0.229744   -1.851199
40      -0.229744   -1.851199

converged: θ = -0.229744, E = -1.851199
error vs. exact = 0.00e+00
```

Converged by step 10, to the exact ground energy from §23.3 to every digit printed. The
playground page's live view (`CHSHChartView`, shared with Chapter 20's CHSH scatter/line chart)
draws this as a picture: the blue `E(θ)` curve over one full period, with orange dots at the 41
`(θ, E(θ))` points gradient descent actually visited, clustering tightly into the well by the
tenth point. `SwiftQiskitApp` has no general-purpose line/scatter chart of its own —
`HistogramView` only draws bar charts of `measure(shots:)` counts — so the table above is this
chapter's version of that picture: the same walk downhill, in numbers instead of pixels.

## Build it in the app

◐ Every gate the ansatz needs (`x`, `ry`, `cx`) is in the palette, so the state `ansatz(θ)`
itself is fully tappable and readable at any θ — only the energy, the gradient, and the
optimization loop stay code-only.

1. Clear, set **Qubits: 2**. Arm **X**, tap `q0` column 0.
2. Arm **RY**, tap `q1` in the *same* column 0 (parallel placement, same idiom Chapter 21 used
   for its environment qubit) — drag to a trial angle, e.g. `θ = 0.900`.
3. Arm **CX**, tap `q1` then `q0` in column 1 — q1 is the **control**, q0 the target (the
   opposite direction from most earlier chapters' CX examples, and the detail worth
   double-checking against §23.2 if the numbers below don't match).

   State Vector panel: only `|01⟩` and `|10⟩` are populated —

   ```text
   |01⟩ amplitude ≈ 0.434966   |10⟩ amplitude ≈ 0.900447
   ```

   matching §23.2's `cos(θ/2)|10⟩ + sin(θ/2)|01⟩` exactly (`sin(0.45) ≈ 0.435`,
   `cos(0.45) ≈ 0.900`). `|00⟩` and `|11⟩` read exactly 0 at every θ tried — the subspace
   confinement, visible tap by tap rather than just asserted.
4. **The converged ground state.** §23.5 found the optimum at θ ≈ -0.229744; the popover's
   slider only runs 0 to 2π, so dial in `θ = 6.053` (`= 2π − 0.229744`, the same negative-angle
   trick Chapters 20–21 used). State Vector panel:

   ```text
   |01⟩ amplitude ≈ 0.114839   |10⟩ amplitude ≈ 0.993384
   ```

   — probabilities ≈ 0.013 / 0.987, overwhelmingly `|10⟩`: the H₂ ground state here sits close
   to the uncorrelated reference determinant, with only a small admixture of the doubly-excited
   configuration `|01⟩` (the amplitudes match §23.5's converged θ up to the slider's 3-decimal
   display rounding).

**What's still out of reach:** the app has no way to attach a Hamiltonian to a circuit, read an
expectation value, or run an optimizer — `CircuitBuilder` only ever replays gates and reports
either the raw state vector or shot counts. Building the Hamiltonian, computing `E(θ)`, taking
its gradient, and stepping θ downhill are all "Run it in code" below.

## Run it in code

Every snippet was run with `RunCodeSnippet` against `SwiftQiskitApp/CircuitModel.swift`.

```swift
import SwiftQiskit

func fmt(_ d: Double) -> String { String(format: "%.6f", d) }

let g: [Double] = [-0.4804, 0.3435, -0.4347, 0.5716, 0.0910, 0.0910]
let I2 = Matrix.identity(size: 2)
let X = PauliXGate.matrix
let Y = PauliYGate.matrix
let Z = PauliZGate.matrix

let H = (I2 ⊗ I2) * g[0] + (Z ⊗ I2) * g[1] + (I2 ⊗ Z) * g[2] + (Z ⊗ Z) * g[3]
      + (Y ⊗ Y) * g[4] + (X ⊗ X) * g[5]

func ansatz(_ theta: Double) -> StateVector {
    let qc = QuantumCircuit(qubits: 2)
    qc.x(0); qc.ry(theta, 1); qc.cx(1, 0)
    return qc.run()
}

func energy(_ theta: Double) -> Double {
    let psi = ansatz(theta)
    return (psi† * H * psi).real
}

let testPsi = ansatz(0.9)
print("ansatz(0.9): |00⟩=\(fmt(testPsi[0].magnitude))  |01⟩=\(fmt(testPsi[1].magnitude))  |10⟩=\(fmt(testPsi[2].magnitude))  |11⟩=\(fmt(testPsi[3].magnitude))")

print("\nθ        E(θ)")
for theta in [0.0, Double.pi / 2, Double.pi, 3 * Double.pi / 2] {
    print("\(fmt(theta))  \(fmt(energy(theta)))")
}

// Exact closed-form ground energy: H is block-diagonal; the ansatz stays in the {|01⟩,|10⟩} block.
let a = H[1, 1].real
let d = H[2, 2].real
let bMagSq = H[1, 2].magnitudeSquared
let mean = (a + d) / 2
let discriminant = ((a - d) / 2) * ((a - d) / 2) + bMagSq
let groundEnergy = mean - discriminant.squareRoot()
let nuclearRepulsion = 0.7055
print("\nexact electronic ground energy = \(fmt(groundEnergy)) Ha")
print("total with nuclear repulsion   = \(fmt(groundEnergy + nuclearRepulsion)) Ha")

func parameterShiftGradient(_ theta: Double) -> Double {
    (energy(theta + .pi / 2) - energy(theta - .pi / 2)) / 2
}
func finiteDifferenceGradient(_ theta: Double, h: Double = 1e-5) -> Double {
    (energy(theta + h) - energy(theta - h)) / (2 * h)
}
print("\nθ      param-shift    finite-diff")
for theta in [0.0, 0.4, 1.0, 2.5] {
    print("\(fmt(theta))  \(fmt(parameterShiftGradient(theta)))     \(fmt(finiteDifferenceGradient(theta)))")
}

var theta = 0.0
let lr = 1.0
print("\nstep   θ           E(θ)")
for step in 1...40 {
    theta -= lr * parameterShiftGradient(theta)
    if [1, 10, 20, 30, 40].contains(step) {
        print("\(step)      \(fmt(theta))   \(fmt(energy(theta)))")
    }
}
print("\nconverged: θ = \(fmt(theta)), E = \(fmt(energy(theta)))")
print("error vs. exact = \(String(format: "%.2e", abs(energy(theta) - groundEnergy)))")
```

```text
ansatz(0.9): |00⟩=0.000000  |01⟩=0.434966  |10⟩=0.900447  |11⟩=0.000000

θ        E(θ)
0.000000  -1.830200
1.570796  -0.870000
3.141593  -0.273800
4.712389  -1.234000

exact electronic ground energy = -1.851199 Ha
total with nuclear repulsion   = -1.145699 Ha

θ      param-shift    finite-diff
0.000000  0.182000     0.182000
0.400000  0.470678     0.470678
1.000000  0.753168     0.753168
2.500000  0.319923     0.319923

step   θ           E(θ)
1      -0.182000   -1.850288
10      -0.229744   -1.851199
20      -0.229744   -1.851199
30      -0.229744   -1.851199
40      -0.229744   -1.851199

converged: θ = -0.229744, E = -1.851199
error vs. exact = 0.00e+00
```

The app-tap circuit from step 4 above, replayed with `CircuitBuilder` and checked against
`ansatz(0.9)` directly:

```swift
let builder = CircuitBuilder(qubitCount: 2)
builder.place(.x, qubits: [0], column: 0)
builder.place(.ry(0.9), qubits: [1], column: 0)
builder.place(.cx, qubits: [1, 0], column: 1)
let appState = builder.buildCircuit().run()
let codeState = ansatz(0.9)
print("app == code: \(appState == codeState)")
```

```text
app == code: true
```

## Try it yourself

1. Compare the parameter-shift gradient to a finite-difference gradient at the same θ.
   <details><summary>Answer</summary>They agree to six decimals at every θ tried (§23.4) —
   parameter-shift is exact for this ansatz, finite-difference is only approximate, but at
   `h = 10⁻⁵` its truncation error is already below the digits printed.</details>
2. Trace `ansatz(θ)` through its three gates by hand: why does it never produce `|00⟩` or
   `|11⟩`, for any θ?
   <details><summary>Answer</summary>`x(0)` first sends `|00⟩` to `|10⟩` — `|00⟩` and `|11⟩`
   are never touched again. `ry(θ, 1)` only rotates qubit 1, turning `|10⟩` into
   `cos(θ/2)|10⟩ + sin(θ/2)|11⟩`. The final `cx(1, 0)` flips qubit 0 exactly when qubit 1 is
   `|1⟩`, so the `|11⟩` term (qubit 1 = 1) becomes `|01⟩`, while the `|10⟩` term (qubit 1 = 0) is
   untouched — leaving `cos(θ/2)|10⟩ + sin(θ/2)|01⟩` and nothing else, for every θ.</details>
3. At θ = π, `ansatz(π)` collapses to a single basis state. Which one, and what does that predict
   for `E(π)` without running the full `ψ† * H * ψ` expectation-value machinery?
   <details><summary>Answer</summary>`cos(π/2) = 0` and `sin(π/2) = 1`, so
   `ansatz(π) = |01⟩` exactly — confirmed: `|01⟩` amplitude = 1.000000, the other three exactly
   0. For a basis state, `⟨01|H|01⟩` is just the matrix's own diagonal entry, no cross terms:
   `H[1,1] = -0.273800`, matching `E(π) = -0.273800` from §23.3 exactly, with no need for the
   general Dirac expectation-value formula at all.</details>
4. Run gradient descent from a different starting point, e.g. θ₀ = π instead of θ₀ = 0. Does it
   find the same ground energy?
   <details><summary>Answer</summary>Yes: from θ₀ = π, 40 steps converge to θ = 6.053442 and
   E = -1.851199 — the same energy as §23.5's run from θ₀ = 0, and the same physical state,
   since `6.053442 = -0.229744 + 2π` up to the optimizer's own step-to-step rounding. Starting
   from θ₀ = 2.0 converges to θ = -0.229744 directly. This one-parameter landscape has a single
   well per period, so gradient descent finds the same minimum regardless of where in that
   period it starts.</details>

---
[← Chapter 22](22-Tomography.md) · [Contents](../../INTRODUCTION.md) · [Chapter 24 →](24-Trotter.md)
