# Chapter 11 — Tensor Products and Composite Systems

> Why combining qubits multiplies dimensions instead of adding them: `⊗` on matrices and state
> vectors, gate embedding, the mixed-product identity, and why entangling gates and entangled
> states both refuse to factor.

| | |
|---|---|
| Playground page | [`09Tensor`](../../../SwiftQiskit/PlaygroundDocs/09TENSORHELP.md) |
| In the app | ◐ — placing `h(0)` on a multi-qubit circuit is the tappable half; the underlying `⊗` algebra (hand-building H ⊗ I₂) is code-only |
| Library APIs | `Matrix.tensor(_:)`/`⊗`, `StateVector.tensor(_:)`/`⊗`, `QuantumCircuit.apply(_:)`, `Matrix.identity(size:)` |
| Prerequisites | Chapters 2, 7, 10 |

## 11.1 Why `⊗` matters

A single qubit lives in a 2-dimensional space; two qubits live in a 4-dimensional one, not a
4-dimensional-because-2+2 one. Every chapter since Chapter 3 has used this fact without deriving
it — a 2-qubit state vector has 4 amplitudes, a 4-qubit one has 16, and Chapter 10 §10.6 built a
table of `2ⁿ` costs straight from it. The rule that produces those dimensions is the **tensor
(Kronecker) product**, written `⊗`: it is how quantum mechanics combines two systems into one, and
it is the composition rule every multi-qubit gate and every multi-qubit state in this book is
secretly built from.

`⊗` shows up in two places, doing the same job at two different levels:

- On **state vectors**, `⊗` combines two registers into one: `|ψ⟩ ⊗ |φ⟩` is the state of "system
  ψ next to system φ," and its dimension is the *product* of the two dimensions, not the sum.
- On **matrices**, `⊗` combines two operators into one: `H ⊗ I₂` is "apply `H` here, leave that
  qubit alone," and it is exactly the 4×4 matrix `QuantumCircuit.h(0)` builds for you on a
  2-qubit circuit.

Chapter 10 §10.2 deferred to this chapter for "the product of all four" — that phrase names `⊗`,
and §11.3 below makes the connection exact: `H ⊗ H ⊗ H ⊗ H` applied once is the same unitary as
four separate calls to `h`.

| § | What happens |
|---|---|
| 11.2 | `⊗` on state vectors: `\|0⟩⊗\|0⟩ = \|00⟩`, ordering, and a labeling trap |
| 11.3 | `⊗` on matrices: the block rule, `H⊗I₂` is what `h(0)` builds, and the `2ⁿ` cost table's origin |
| 11.4 | The mixed-product identity: why local gates keep local structure |
| 11.5 | What `⊗` cannot build: entangling *gates* |
| 11.6 | What `⊗` cannot build: entangled *states* |

## 11.2 Combining registers: `⊗` on state vectors

`StateVector.tensor(_:)` (the `⊗` operator's spelling for state vectors) combines two registers
into one: the result's amplitude at index `i · dim(other) + j` is `self[i] · other[j]`. The
simplest instance is exact, not approximate — `|0⟩ ⊗ |0⟩` is `|00⟩` on the nose:

```text
|0⟩ ⊗ |0⟩ == |00⟩ -> true
```

Tensoring a genuinely superposed state with a plain `|0⟩` checks against the app-visible operation
it stands in for: `(H|0⟩) ⊗ |0⟩` must equal what `h(0)` builds on a 2-qubit circuit, since "apply
`H` to qubit 0, leave qubit 1 alone" is exactly what tensoring a `|+⟩` with a `|0⟩` means.

```text
(H|0⟩) ⊗ |0⟩: [0.7071067811865475, 0.0, 0.7071067811865475, 0.0]
h(0) circuit:  [0.7071067811865475, 0.0, 0.7071067811865475, 0.0]
max diff: 0.0
```

`⊗` is **not commutative** — the left operand always lands in the high-order bits, matching this
book's qubit-0-is-MSB convention (worth restating here: Chapter 10's AUTHORING warning about
Chapters 10–14 applies just as much to this one). Swapping the order of `|+⟩` and `|0⟩` produces a
genuinely different state:

```text
plus ⊗ zero: [0.7071067811865475, 0.0, 0.7071067811865475, 0.0]
zero ⊗ plus: [0.7071067811865475, 0.7071067811865475, 0.0, 0.0]
```

`plus ⊗ zero` puts the superposition in qubit 0 (spreading over `|00⟩`/`|10⟩`); `zero ⊗ plus` puts
it in qubit 1 (spreading over `|00⟩`/`|01⟩`) — same two factors, different composite state,
because `⊗` reads left-to-right the same way a ket label does: `|1⟩ ⊗ |0⟩ = |10⟩`, confirmed
directly:

```text
|1⟩ ⊗ |0⟩ amplitudes: [0.0, 0.0, 1.0, 0.0]
```

One reading trap worth flagging before it causes confusion later: `StateVector`'s own
`description` does **not** zero-pad its labels the way `ResultsView`'s State Vector panel does.
Printing `(H|0⟩) ⊗ |0⟩` directly gives:

```text
|0⟩: 0.7071067811865475
|1⟩: 0.0
|10⟩: 0.7071067811865475
|11⟩: 0.0
```

Here `|0⟩` and `|1⟩` are shorthand for the 2-qubit basis states `|00⟩` and `|01⟩` — the label is
just the binary digits of the index, un-padded, not a claim about how many qubits are involved.
`SimulationResult`'s measurement labels (Chapter 9) are always fixed-width and zero-padded; raw
`StateVector.description` is not, and this is the first chapter where that difference is visible
directly rather than papered over by the app's own panel formatting.

## 11.3 Embedding a gate: `⊗` on matrices

`Matrix.tensor(_:)` follows the **block rule**: `A ⊗ B` replaces every entry `aᵢⱼ` of `A` with the
block `aᵢⱼ · B`, so an `m×n ⊗ p×q` product has shape `mp×nq`. The simplest check, `I₂ ⊗ I₂`,
lands on `I₄` exactly — no irrational entries, so `==` is the right tool:

```text
I₂ ⊗ I₂ == I₄ -> true
```

`H ⊗ I₂` shows the block rule with entries that actually vary: each of `H`'s four `±1/√2` entries
becomes a `±1/√2 · I₂` block —

```text
H ⊗ I₂ =
[0.7071067811865475, 0.0, 0.7071067811865475, 0.0]
[0.0, 0.7071067811865475, 0.0, 0.7071067811865475]
[0.7071067811865475, 0.0, -0.7071067811865475, -0.0]
[0.0, 0.7071067811865475, -0.0, -0.7071067811865475]
```

(the `-0.0` entries are ordinary floating-point signed zeros from multiplying `0.0` by `−1/√2`,
not a bug.) Unlike ordinary matrix multiplication, `⊗` is defined for *any* pair of shapes — there
is no dimension precondition to violate:

```text
(2×3) ⊗ (2×2) -> 4×6
```

The payoff is that `H ⊗ I₂`, applied to the 4-dimensional state via `QuantumCircuit.apply(_:)`,
is *exactly* what `h(0)` does on a 2-qubit circuit — not an analogy, the literal matrix
`embedSingleQubitGate` builds internally (`QuantumCircuit.swift`, the loop `result! ⊗ factor`,
one identity factor per untouched qubit):

```text
apply(H ⊗ I2): [0.7071067811865475, 0.0, 0.7071067811865475, 0.0]
h(0):          [0.7071067811865475, 0.0, 0.7071067811865475, 0.0]
```

and the same holds for `H` on every qubit of a register at once — `apply(H ⊗ H)` reproduces
`h(0); h(1)` exactly, and four tensored copies of `H` reproduce Chapter 10 §10.2's "four taps"
circuit:

```text
apply(H ⊗ H):   [0.4999999999999999, 0.4999999999999999, 0.4999999999999999, 0.4999999999999999]
h(0);h(1):      [0.4999999999999999, 0.4999999999999999, 0.4999999999999999, 0.4999999999999999]

H⊗H⊗H⊗H applied vs h(0);h(1);h(2);h(3), max amplitude diff: 0.0
```

That is the notation Chapter 10 §10.2 promised for "the product of all four": `H ⊗ H ⊗ H ⊗ H`.
It also explains Chapter 10 §10.6's `2ⁿ×2ⁿ` operator-size table directly — tensoring `n` copies of
a 2×2 factor doubles both dimensions at each step, so the entry count is `4ⁿ`, not `2·n`:

```text
n=1: 2x2 = 4 entries
n=2: 4x4 = 16 entries
n=3: 8x8 = 64 entries
n=4: 16x16 = 256 entries
```

`n` gates for `2ⁿ` amplitudes and `4ⁿ` matrix entries — the exponential Chapter 10 introduced is,
concretely, `n` factors of a fixed 2×2 matrix multiplying together under `⊗`.

## 11.4 The mixed-product identity

The property that makes `⊗` the *right* composition rule for quantum mechanics, not just a
convenient one, is the **mixed-product identity**:

```text
(A ⊗ B)(x ⊗ y) = (Ax) ⊗ (By)
```

Acting on a composite system with `A ⊗ B` gives the same result as acting on each part
separately and then combining. Checked numerically with `A = X`, `B = H`, and two small vectors:

```text
max |(X⊗H)(x⊗y) - (Xx)⊗(Hy)| = 0.0
```

This identity is the whole reason `embedSingleQubitGate` (§11.3) is allowed to work the way it
does: applying `H ⊗ I₂` to a 2-qubit state is guaranteed to act on qubit 0 exactly as plain `H`
would and leave qubit 1 exactly alone, with no cross-talk between the two factors. It also has a
consequence that sets up the rest of the chapter: if a state starts as a product `x ⊗ y`, and
every gate applied to it is itself of the form `A ⊗ B` (i.e., built one qubit at a time, the way
`h`, `x`, `z`, and every other single-qubit gate in the palette are), the mixed-product identity
guarantees the result is `(Ax) ⊗ (By)` — still a product state. No amount of single-qubit gates,
however many, can ever produce anything else. Something genuinely different is needed to escape a
product state, which is exactly what §11.5 and §11.6 make precise.

## 11.5 What `⊗` cannot build: entangling gates

Not every 4×4 unitary is `A ⊗ B` for some 2×2 `A` and `B`. A matrix built as `A ⊗ B` has a
signature: viewed as four 2×2 blocks, every block is a scalar multiple of every other block (block
`(i,j)` is `aᵢⱼ · B`, so blocks `(0,0)` and `(1,1)` differ only by the scalar `a₀₀/a₁₁`, entrywise
proportional to each other). `H ⊗ I₂` passes this test by construction:

```text
H ⊗ I2 is block-proportional (as expected, it IS a tensor product): true
```

`cx`'s matrix does not. Its `(0,0)` block is the identity (control bit `0` leaves the target
alone) and its `(1,1)` block is `X` (control bit `1` flips the target) — two blocks that are not
scalar multiples of each other for any choice of scalar:

```text
CNOT is block-proportional: false
CNOT blocks: [[1.0, 0.0, 0.0, 1.0], [0.0, 0.0, 0.0, 0.0], [0.0, 0.0, 0.0, 0.0], [0.0, 1.0, 1.0, 0.0]]
```

That failure is not a limitation of this particular check — it is the reason `cx` exists as its
own gate at all. `CNOTGate.matrix(qubits:control:target:)` is built directly, by placing `1`s at
the permuted positions the truth table calls for (`CNOT.swift`), not by tensoring two single-qubit
factors together the way `embedSingleQubitGate` does for `h`/`x`/`y`/`z`/`s`/`t`/`p`/`rx`/`ry`/`rz`.
No pair of single-qubit gates tensors into `cx`, which is why the app's palette needs a dedicated
two-qubit `CX` tile rather than letting two single-qubit tiles stand in for it.

## 11.6 What `⊗` cannot build: entangled states

§11.4 already previewed the consequence: any state built as `x ⊗ y` — for single-qubit vectors `x`
and `y` — has amplitudes `(x₀y₀, x₀y₁, x₁y₀, x₁y₁)`, and those four numbers always satisfy one
algebraic identity:

```text
α₀₀ · α₁₁ = α₀₁ · α₁₀        (both equal x₀y₀x₁y₁)
```

Every genuine product state passes this check, including ones built with real single-qubit
superpositions on both sides — not just the trivial `|00⟩` case where every cross term is zero:

```text
|00⟩: a00*a11 = 0.0, a01*a10 = 0.0, diff = 0.0
|+0⟩: a00*a11 = 0.0, a01*a10 = 0.0, diff = 0.0
|++⟩: a00*a11 = 0.2499999999999999, a01*a10 = 0.2499999999999999, diff = 0.0
ry(0.9,0);ry(1.3,1): a00*a11 = 0.18869526390727887, a01*a10 = 0.18869526390727887, diff = 0.0
```

(the last row's amplitudes — `[0.7168, 0.5449, 0.3463, 0.2632]` — are all nonzero, and the two
sides of the identity still agree exactly, which is the strongest form of the check.)

The Bell state fails it outright:

```text
Bell (h(0);cx(0,1)): a00*a11 = 0.4999999999999999, a01*a10 = 0.0, diff = 0.4999999999999999
```

`(|00⟩ + |11⟩)/√2` has `α₀₀ = α₁₁ = 1/√2` and `α₀₁ = α₁₀ = 0`, so the left side is `1/2` and the
right side is `0` — no choice of single-qubit `v` and `w` can produce this state as `v ⊗ w`. This
is §11.5's failure restated one level up: `cx` is the gate that can't be written as `A ⊗ B`, and
the state it produces from a product input can't be written as `x ⊗ y` either. Appending a further
single-qubit gate afterward doesn't rescue it — `x` on qubit 1 of the Bell state just swaps which
cross term is nonzero, and the identity still fails by exactly the same amount:

```text
Bell;x(1): a00*a11 = 0.0, a01*a10 = 0.4999999999999999, diff = 0.4999999999999999
```

This non-factorization *is* entanglement, algebraically: an entangled state is precisely one that
cannot be decomposed into independent single-qubit pieces, however hard you look. Chapter 12 takes
this fact and asks what it *means* physically — correlated measurement outcomes, no signal a local
gate on one qubit can send to the other — this chapter's job was only to show the fact itself, at
the level of amplitudes and matrices.

## Build it in the app

◐ Every step starts from **Clear** unless noted.

1. **`h(0)` on 2 qubits** — Set **Qubits: 2**. Arm **H** (Pauli / Hadamard section), tap `q0` in
   column 0. State Vector panel: `|00⟩: p=0.500`, `|10⟩: p=0.500` — matching `(H|0⟩) ⊗ |0⟩`
   (§11.2).
2. **Ordering, by tapping** — Clear, arm **H**, tap `q1` instead of `q0`. Panel: `|00⟩: p=0.500`,
   `|01⟩: p=0.500` — a different pair of rows from step 1, from tensoring the same two factors in
   the other order (§11.2's `plus ⊗ zero` vs `zero ⊗ plus`).
3. **Label concatenation** — Clear, arm **X**, tap `q0`. Panel: one row, `|10⟩: p=1.000` —
   `|1⟩ ⊗ |0⟩` read directly off the label.
4. **`H` on both qubits** — Clear, arm **H**, tap `q0` and `q1` in column 0. Panel: four rows, each
   `p=0.250` — the tapped equivalent of `apply(H ⊗ H)` (§11.3). Tap **Display → Final**: both
   qubits read `x +1.000  y +0.000  z +0.000`, `|r| = 1` — a product state, one independent `|+⟩`
   per qubit.
5. **The Bell state, for contrast** — Clear, arm **H**, tap `q0`'s column-0 cell; arm **CX**
   (Multi-qubit section), tap `q0` then `q1` in column 1. Panel: `|00⟩: p=0.500`, `|11⟩: p=0.500`.
   Tap **Display → Final**: both qubits now read `|r| = 0.000` — collapsed to the sphere's center,
   the visible signature of a state that (§11.6) admits no single-qubit factorization at all.

Two genuine limits, not a missing-capability paragraph: there is no matrix entry anywhere in the
app — no way to type `H ⊗ I₂` directly, inspect the 4×4 (or `2ⁿ×2ⁿ`) unitary behind a placed tile,
or run `QuantumCircuit.apply(_:)` on a hand-built matrix; and there is no factorization readout —
step 5's `|r| = 0` cards are a genuine proxy for "this state can't be a product of two pure
single-qubit states" (a pure product state always has `|r| = 1` on every qubit), but they are not
a substitute for actually running §11.6's `α₀₀·α₁₁ = α₀₁·α₁₀` check, which only code can do.

## Run it in code

Every snippet below was run with `RunCodeSnippet` against
`SwiftQiskitApp/SwiftQiskitApp/CircuitModel.swift`.

```swift
import SwiftQiskit

// 11.2 -- combining registers: |0> (x) |0> = |00>
let zero1 = StateVector(qubits: 1)
print("|0> (x) |0> == |00> ->", zero1 ⊗ zero1 == StateVector(qubits: 2))

// (H|0>) (x) |0> vs h(0) on a 2-qubit circuit
var plus = StateVector(qubits: 1)
plus.apply(HadamardGate.matrix)
let combined = plus ⊗ zero1
let qc = QuantumCircuit(qubits: 2); qc.h(0)
let circuitState = qc.run()
let maxStateDiff = (0..<combined.dimension).map { (combined[$0] - circuitState[$0]).magnitude }.max() ?? 0
print("(H|0>) (x) |0>:", combined.amplitudes)
print("h(0) circuit:   ", circuitState.amplitudes)
print("max diff:", maxStateDiff)

// non-commutativity
print("\nplus (x) zero:", (plus ⊗ zero1).amplitudes)
print("zero (x) plus:", (zero1 ⊗ plus).amplitudes)

// label concatenation: |1> (x) |0>
var one1 = StateVector(qubits: 1)
one1.apply(PauliXGate.matrix)
let onezero = one1 ⊗ zero1
print("\n|1> (x) |0> amplitudes:", onezero.amplitudes)

print("\ncombined (unpadded) description:")
print(combined.description)
```

```text
|0> (x) |0> == |00> -> true
(H|0>) (x) |0>: [0.7071067811865475, 0.0, 0.7071067811865475, 0.0]
h(0) circuit:    [0.7071067811865475, 0.0, 0.7071067811865475, 0.0]
max diff: 0.0

plus (x) zero: [0.7071067811865475, 0.0, 0.7071067811865475, 0.0]
zero (x) plus: [0.7071067811865475, 0.7071067811865475, 0.0, 0.0]

|1> (x) |0> amplitudes: [0.0, 0.0, 1.0, 0.0]

combined (unpadded) description:
|0⟩: 0.7071067811865475
|1⟩: 0.0
|10⟩: 0.7071067811865475
|11⟩: 0.0
```

```swift
import SwiftQiskit
import Foundation

// 11.3 -- I2 (x) I2 == I4, exactly
let i2 = Matrix.identity(size: 2)
let i4 = Matrix.identity(size: 4)
print("I2 (x) I2 == I4 ->", i2 ⊗ i2 == i4)

// H (x) I2, printed in full
print("\nH (x) I2 =")
print(HadamardGate.matrix ⊗ Matrix.identity(size: 2))

// dimensions multiply, never fail
let a23 = Matrix(rows: 2, cols: 3, repeating: .one)
let b22 = Matrix(rows: 2, cols: 2, repeating: .i)
let shape = a23.tensor(b22)
print("\n(2x3) (x) (2x2) -> \(shape.rows)x\(shape.cols)")

// h(0) on a 2-qubit circuit IS H (x) I2, applied to |00>
let hi = HadamardGate.matrix ⊗ Matrix.identity(size: 2)
let qcApply = QuantumCircuit(qubits: 2)
qcApply.apply(hi)
let qcH = QuantumCircuit(qubits: 2); qcH.h(0)
print("\napply(H (x) I2):", qcApply.run().amplitudes)
print("h(0):            ", qcH.run().amplitudes)

// apply(H (x) H) vs h(0);h(1)
let qcHH = QuantumCircuit(qubits: 2)
qcHH.apply(HadamardGate.matrix ⊗ HadamardGate.matrix)
let qcH01 = QuantumCircuit(qubits: 2); qcH01.h(0); qcH01.h(1)
print("\napply(H (x) H):  ", qcHH.run().amplitudes)
print("h(0);h(1):       ", qcH01.run().amplitudes)

// four qubits: H(x)H(x)H(x)H vs h(0..3)
var fourH: Matrix? = nil
for _ in 0..<4 {
    fourH = fourH == nil ? HadamardGate.matrix : fourH!.tensor(HadamardGate.matrix)
}
let qcApply4 = QuantumCircuit(qubits: 4)
qcApply4.apply(fourH!)
let qcH4 = QuantumCircuit(qubits: 4)
qcH4.h(0); qcH4.h(1); qcH4.h(2); qcH4.h(3)
let maxDiff4 = zip(qcApply4.run().amplitudes, qcH4.run().amplitudes).map { ($0 - $1).magnitude }.max() ?? 0
print("\nH(x)H(x)H(x)H applied vs h(0);h(1);h(2);h(3), max amplitude diff:", maxDiff4)

// dimension table derivation, from n tensored 2x2 factors
for n in 1...4 {
    var m: Matrix? = nil
    for _ in 0..<n { m = m == nil ? Matrix.identity(size: 2) : m!.tensor(Matrix.identity(size: 2)) }
    print("n=\(n): \(m!.rows)x\(m!.cols) = \(m!.rows * m!.cols) entries")
}

// 11.4 -- mixed-product identity
func kronVector(_ u: [Complex], _ v: [Complex]) -> [Complex] { u.flatMap { ui in v.map { ui * $0 } } }
let x: [Complex] = [Complex(0.6), Complex(0.8)]
let y: [Complex] = [.zero, .one]
let lhs = (PauliXGate.matrix ⊗ HadamardGate.matrix).multiply(by: kronVector(x, y))
let rhs = kronVector(PauliXGate.matrix.multiply(by: x), HadamardGate.matrix.multiply(by: y))
print("\nmax |(X(x)H)(x(x)y) - (Xx)(x)(Hy)| =", zip(lhs, rhs).map { ($0 - $1).magnitude }.max() ?? 0)
```

```text
I2 (x) I2 == I4 -> true

H (x) I2 =
[0.7071067811865475, 0.0, 0.7071067811865475, 0.0]
[0.0, 0.7071067811865475, 0.0, 0.7071067811865475]
[0.7071067811865475, 0.0, -0.7071067811865475, -0.0]
[0.0, 0.7071067811865475, -0.0, -0.7071067811865475]

(2x3) (x) (2x2) -> 4x6

apply(H (x) I2): [0.7071067811865475, 0.0, 0.7071067811865475, 0.0]
h(0):             [0.7071067811865475, 0.0, 0.7071067811865475, 0.0]

apply(H (x) H):   [0.4999999999999999, 0.4999999999999999, 0.4999999999999999, 0.4999999999999999]
h(0);h(1):        [0.4999999999999999, 0.4999999999999999, 0.4999999999999999, 0.4999999999999999]

H(x)H(x)H(x)H applied vs h(0);h(1);h(2);h(3), max amplitude diff: 0.0
n=1: 2x2 = 4 entries
n=2: 4x4 = 16 entries
n=3: 8x8 = 64 entries
n=4: 16x16 = 256 entries

max |(X(x)H)(x(x)y) - (Xx)(x)(Hy)| = 0.0
```

```swift
import SwiftQiskit

// 11.5 -- block-proportionality test: is a 4x4 matrix M expressible as A (x) B?
func blocks(_ m: Matrix) -> [[Complex]] {
    var result: [[Complex]] = []
    for bi in 0..<2 {
        for bj in 0..<2 {
            var block: [Complex] = []
            for i in 0..<2 {
                for j in 0..<2 {
                    block.append(m[bi*2 + i, bj*2 + j])
                }
            }
            result.append(block)
        }
    }
    return result
}

func isScalarMultiple(_ a: [Complex], _ b: [Complex], tolerance: Double = 1e-9) -> Bool {
    for i in 0..<a.count {
        for j in 0..<a.count {
            let lhs = a[i] * b[j]
            let rhs = a[j] * b[i]
            if (lhs - rhs).magnitude > tolerance { return false }
        }
    }
    return true
}

func isBlockProportional(_ m: Matrix) -> Bool {
    let bs = blocks(m)
    let b0 = bs[0]
    return bs.allSatisfy { isScalarMultiple($0, b0) }
}

let hi = HadamardGate.matrix ⊗ Matrix.identity(size: 2)
print("H (x) I2 is block-proportional (as expected, it IS a tensor product):", isBlockProportional(hi))

let cnot = CNOTGate.matrix(qubits: 2, control: 0, target: 1)
print("CNOT is block-proportional:", isBlockProportional(cnot))
print("CNOT blocks:", blocks(cnot))

// 11.6 -- entangled states don't factor: alpha00*alpha11 == alpha01*alpha10 for product states
func factorCheck(_ label: String, _ state: StateVector) {
    let p = state[0] * state[3]
    let c = state[1] * state[2]
    print("\(label): a00*a11 = \(p), a01*a10 = \(c), diff = \((p - c).magnitude)")
}

factorCheck("|00>", QuantumCircuit(qubits: 2).run())

let plus0 = QuantumCircuit(qubits: 2); plus0.h(0)
factorCheck("|+0>", plus0.run())

let plusplus = QuantumCircuit(qubits: 2); plusplus.h(0); plusplus.h(1)
factorCheck("|++>", plusplus.run())

let ryProduct = QuantumCircuit(qubits: 2)
ryProduct.ry(0.9, 0); ryProduct.ry(1.3, 1)
factorCheck("ry(0.9,0);ry(1.3,1)", ryProduct.run())
print("ry product amplitudes:", ryProduct.run().amplitudes)

let bell = QuantumCircuit(qubits: 2); bell.h(0); bell.cx(0, 1)
factorCheck("Bell (h(0);cx(0,1))", bell.run())

let bellThenX = QuantumCircuit(qubits: 2); bellThenX.h(0); bellThenX.cx(0, 1); bellThenX.x(1)
factorCheck("Bell;x(1)", bellThenX.run())
```

```text
H (x) I2 is block-proportional (as expected, it IS a tensor product): true
CNOT is block-proportional: false
CNOT blocks: [[1.0, 0.0, 0.0, 1.0], [0.0, 0.0, 0.0, 0.0], [0.0, 0.0, 0.0, 0.0], [0.0, 1.0, 1.0, 0.0]]
|00>: a00*a11 = 0.0, a01*a10 = 0.0, diff = 0.0
|+0>: a00*a11 = 0.0, a01*a10 = 0.0, diff = 0.0
|++>: a00*a11 = 0.2499999999999999, a01*a10 = 0.2499999999999999, diff = 0.0
ry(0.9,0);ry(1.3,1): a00*a11 = 0.18869526390727887, a01*a10 = 0.18869526390727887, diff = 0.0
ry product amplitudes: [0.7168313496334096, 0.5449383454282483, 0.3462690146331871, 0.26323522820783213]
Bell (h(0);cx(0,1)): a00*a11 = 0.4999999999999999, a01*a10 = 0.0, diff = 0.4999999999999999
Bell;x(1): a00*a11 = 0.0, a01*a10 = 0.4999999999999999, diff = 0.4999999999999999
```

Finally, the app-path walkthrough behind every "Build it in the app" step above, driving
`CircuitBuilder` directly and formatting output exactly as `ResultsView`'s panel and
`BlochSphereView`'s card do (helpers first defined in Chapters 8–10's "Run it in code"):

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

var b1 = CircuitBuilder(qubitCount: 2)
b1.place(.h, qubits: [0], column: 0)
print("step 1 panel:", panelRows(b1.buildCircuit().run(), qubits: 2))

var b2 = CircuitBuilder(qubitCount: 2)
b2.place(.h, qubits: [1], column: 0)
print("step 2 panel:", panelRows(b2.buildCircuit().run(), qubits: 2))

var b3 = CircuitBuilder(qubitCount: 2)
b3.place(.x, qubits: [0], column: 0)
print("step 3 panel:", panelRows(b3.buildCircuit().run(), qubits: 2))

var b4 = CircuitBuilder(qubitCount: 2)
b4.place(.h, qubits: [0], column: 0)
b4.place(.h, qubits: [1], column: 0)
let b4state = b4.buildCircuit().run()
print("step 4 panel:", panelRows(b4state, qubits: 2))
for q in 0..<2 { print("step 4 qubit \(q) card:", card(BlochVector(b4state, qubit: q))) }

var b5 = CircuitBuilder(qubitCount: 2)
b5.place(.h, qubits: [0], column: 0)
b5.place(.cx, qubits: [0, 1], column: 1)
let b5state = b5.buildCircuit().run()
print("step 5 panel:", panelRows(b5state, qubits: 2))
for q in 0..<2 { print("step 5 (Bell) qubit \(q) card:", card(BlochVector(b5state, qubit: q))) }
```

```text
step 1 panel: ["|00⟩: 0.7071067811865475  (p=0.500)", "|10⟩: 0.7071067811865475  (p=0.500)"]
step 2 panel: ["|00⟩: 0.7071067811865475  (p=0.500)", "|01⟩: 0.7071067811865475  (p=0.500)"]
step 3 panel: ["|10⟩: 1.0  (p=1.000)"]
step 4 panel: ["|00⟩: 0.4999999999999999  (p=0.250)", "|01⟩: 0.4999999999999999  (p=0.250)", "|10⟩: 0.4999999999999999  (p=0.250)", "|11⟩: 0.4999999999999999  (p=0.250)"]
step 4 qubit 0 card: x +1.000  y +0.000  z +0.000  θ 1.571 rad
step 4 qubit 1 card: x +1.000  y +0.000  z +0.000  θ 1.571 rad
step 5 panel: ["|00⟩: 0.7071067811865475  (p=0.500)", "|11⟩: 0.7071067811865475  (p=0.500)"]
step 5 (Bell) qubit 0 card: x +0.000  y +0.000  z +0.000  θ 1.571 rad  |r| 0.000
step 5 (Bell) qubit 1 card: x +0.000  y +0.000  z +0.000  θ 1.571 rad  |r| 0.000
```

## Try it yourself

1. Show that the Bell state's amplitude vector cannot be written as `v ⊗ w` for any 2-vectors
   `v`, `w`.
   <details><summary>Answer</summary>Try to solve for `v, w` component-wise from
   `(1,0,0,1)/√2` — a product state would need `v₀w₁ = 0` and `v₁w₀ = 0` (so at least one factor
   in each product is zero) while also needing `v₀w₀ = v₁w₁ = 1/√2` (so neither `v` nor `w` can
   have a zero entry) — a direct contradiction. Numerically, verified above: the Bell state gives
   `α₀₀·α₁₁ = 0.5` but `α₀₁·α₁₀ = 0.0`, violating the identity every genuine product state
   satisfies (§11.6).</details>

2. Predict `zero ⊗ plus` before running it, given that `plus ⊗ zero` above is
   `[0.7071, 0.0, 0.7071, 0.0]`.
   <details><summary>Answer</summary>`[0.7071, 0.7071, 0.0, 0.0]` — verified above. `⊗` puts the
   left operand in the high-order (qubit 0) position, so swapping the order moves which qubit
   carries the superposition: `plus ⊗ zero` spreads over `|00⟩`/`|10⟩` (qubit 0 varies), `zero ⊗
   plus` spreads over `|00⟩`/`|01⟩` (qubit 1 varies).</details>

3. On a 3-qubit circuit, what matrix does `h(1)` build, and what shape is it?
   <details><summary>Answer</summary>`I₂ ⊗ H ⊗ I₂`, an 8×8 matrix — one identity factor for each
   untouched qubit (q0 and q2), with `H` in the position of the targeted qubit (q1). Verified
   above: `I₂ ⊗ H ⊗ I₂` applied via `apply(_:)` matches `h(1)` on a 3-qubit circuit to a max
   amplitude difference of `0.0`.</details>

4. Can any sequence of single-qubit gates (`h`, `x`, `y`, `z`, `s`, `sdg`, `t`, `tdg`, `p`, `rx`,
   `ry`, `rz`, applied to either qubit any number of times) turn a 2-qubit product state into an
   entangled one?
   <details><summary>Answer</summary>No. Every one of those gates is embedded as `A ⊗ B` with one
   factor equal to the identity (§11.3), and the mixed-product identity (§11.4) guarantees
   `(A ⊗ B)(x ⊗ y) = (Ax) ⊗ (By)` — still a product state, however many such gates are chained.
   Escaping a product state requires a gate that is not of the form `A ⊗ B`, such as `cx`, which
   §11.5 showed fails the block-proportionality test that every `A ⊗ B` matrix passes.</details>

---
[← Chapter 10](10-Superposition.md) · [Contents](../../INTRODUCTION.md) · [Chapter 12 →](12-Entanglement.md)
