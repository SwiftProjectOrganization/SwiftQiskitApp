# Chapter 2 — Complex Numbers and Matrices in Swift

> The building blocks everything else rests on: `Complex` numbers, plain complex vectors, and
> the `Matrix` type — including unitarity and the Kronecker/tensor product `⊗` that later
> chapters use to combine qubits.

| | |
|---|---|
| Playground page | — (see also [`09Tensor`](../../../SwiftQiskit/PlaygroundDocs/09TENSORHELP.md) for `⊗` in depth) |
| In the app | ○ — the app has no matrix-entry UI; only the results of gates applied to it are visible |
| Library APIs | `Math/Complex.swift`, `Math/Matrix.swift` (`+ - * /`, `multiply(by:)`, `identity(size:)`, `tensor(_:)`/`⊗`), `Quantum/Dirac.swift` (`.adjoint`, postfix `†`) |
| Prerequisites | Chapter 1 |

## 2.1 Why these mathematical tools

Quantum computing needs a language for exactly three things: **states** (the condition of a
quantum system), **operations** (what changes it), and **measurements** (what happens when you
look). Linear algebra supplies all three at once. A qubit's state is a vector. A quantum gate is
a matrix, and applying the gate is a matrix-vector multiplication. The numbers inside that
vector are complex, because quantum mechanics needs them to describe interference between
possibilities.

None of this is arbitrary — nature at the quantum scale behaves the way complex linear algebra
describes. Here is the preview the rest of this chapter unpacks: a qubit's state is a vector
with two entries, each entry a complex number called an amplitude. Applying a gate multiplies by
a matrix. Measuring an outcome gives it probability equal to the magnitude squared of its
amplitude.

## 2.2 Complex numbers in Swift

A complex number has a real part and an imaginary part, written `a + bi`, where `i` is defined
by `i² = -1`. Its powers cycle with period 4:

```text
i¹ = i,  i² = -1,  i³ = -i,  i⁴ = 1,  i⁵ = i,  i⁶ = -1,  i⁷ = -i,  i⁸ = 1
```

`Complex` (`Math/Complex.swift`) stores `.real` and `.imag` as `Double`s, built with a positional
initializer:

```swift
import SwiftQiskitCore

let a = Complex(3, 4)
let b = Complex(1, -2)
print(a * b, a / b)
```

```text
11.0 - 2.0i
-1.0 + 2.0i
```

Multiplication follows from `i² = -1`: `(3+4i)(1-2i) = 3 - 6i + 4i - 8i² = 3 - 2i + 8 = 11 - 2i`.
Division is the same trick with the conjugate:
`(3+4i)/(1-2i) = (3+4i)(1+2i)/5 = (-5+10i)/5 = -1+2i` — matching the printed result exactly.

`.conjugate` flips the sign of the imaginary part (`z̄` in the article this chapter follows,
written `z*` elsewhere). `.magnitude` is the modulus, the distance from the origin in the
complex plane; `.magnitudeSquared` skips the square root. The two are related by
`z · z̄ = |z|²`:

```swift
let z = Complex(3, 2)
print(z * z.conjugate, z.magnitudeSquared)
```

```text
13.0
13.0
```

Both print as plain `13.0` with no imaginary part — `z · z̄` is always real, which is exactly why
it can serve as a probability in §2.3. One formatting quirk to know now: `Complex`'s
`description` drops a zero imaginary part entirely, so a purely imaginary result like `i · i`
prints `-1.0`, and a vector of mixed real/imaginary entries prints unevenly — you'll see this
again the first time you print `PauliYGate.matrix.multiply(by:)` in Chapter 7.

## 2.3 Why the amplitudes have to be complex

Classical probability uses real numbers between 0 and 1 — a 30% chance of rain. Quantum
mechanics needs more: each outcome gets an **amplitude**, a complex number, and amplitudes must
be able to reinforce or cancel each other. A real number can't encode that; a complex number
can, because it carries two pieces of information at once — its magnitude ("how much") and its
phase ("which direction"). When two amplitudes combine, their phases decide whether they add
constructively or destructively. This interference is the engine behind every quantum algorithm
in this book, starting in earnest in Chapter 8.

The rule connecting amplitude to probability — magnitude squared — is the **Born rule**. Take a
single amplitude:

```swift
let amp = Complex(1.0 / sqrt(2.0), 0)
print(amp.magnitudeSquared)
```

```text
0.4999999999999999
```

Not exactly `0.5` — ordinary floating-point rounding on `1/√2`. This is why this book always
writes probabilities as "≈ 0.500" rather than claiming an exact value; Chapter 3 applies this
rule to a full state vector and the app's State Vector panel displays exactly these numbers.

## 2.4 The complex plane: magnitude and phase

Plot a complex number with the real part on the horizontal axis and the imaginary part on the
vertical: `3+2i` sits at the point `(3, 2)`. The magnitude is the distance from the origin to
that point; the phase is the angle from the positive real axis. Two complex numbers can have the
same magnitude but different phases — same "size," different direction.

`Complex` has no polar API — no `.argument`, no way to build a number directly from an angle.
To get a pure phase `e^{iθ}`, you write it out with Euler's formula:

```swift
let theta = 0.7
let phase = Complex(cos(theta), sin(theta))
print(phase, phase.magnitude)
print(PhaseGate.matrix(theta: theta)[1, 1])
```

```text
0.7648421872844885 + 0.644217687237691i
1.0
0.7648421872844885 + 0.644217687237691i
```

The hand-built value matches the library's own `PhaseGate.matrix(theta:)` at row 1, column 1,
bit for bit — that's not a coincidence, it's literally how `Phase.swift` builds the gate, and how
`Rotation.swift` builds both entries of `RZGate`. `|e^{iθ}| == 1` always: a pure phase changes
direction, never size, which is why it never touches a probability — the subject of Chapter 8.

## 2.5 Vectors of amplitudes

A vector is an ordered list of numbers, written as a column. In quantum computing every entry is
complex. A single qubit's state is a 2-dimensional vector whose entries are amplitudes for the
outcomes 0 and 1:

```swift
let zero: [Complex] = [.one, .zero]              // certain to measure 0
let one: [Complex] = [.zero, .one]                // certain to measure 1
let plus: [Complex] = [Complex(1/sqrt(2), 0), Complex(1/sqrt(2), 0)]  // equal superposition
```

Addition is componentwise, and scalar multiplication multiplies every entry — the scalar itself
may be complex, which is common in quantum computing:

```swift
func addVec(_ a: [Complex], _ b: [Complex]) -> [Complex] {
    zip(a, b).map { $0 + $1 }
}
func scale(_ c: Complex, _ v: [Complex]) -> [Complex] {
    v.map { c * $0 }
}
print(addVec([Complex(1, 0), Complex(0, 1)], [Complex(2, 0), Complex(0, -1)]))
print(scale(Complex.i, [Complex(1, 0), Complex(2, 0)]))
```

```text
[3.0, 0.0]
[1.0i, 2.0i]
```

The library has no vector arithmetic of its own on plain `[Complex]` — no `+`, no scalar `*` —
these are one-line `zip`/`map` helpers. That's fine: Chapter 3 hands this job to `StateVector`,
which does normalize, add gates, and print sensibly. Section 2.7 below is the reason plain
arrays are still worth knowing.

## 2.6 Inner products, the dagger, and orthogonality

The inner product multiplies two vectors together into a single number, measuring how aligned
they are. For complex vectors, the *first* vector's entries get conjugated first:

```text
⟨a|b⟩ = Σᵢ conj(aᵢ) · bᵢ
```

The `†` symbol ("dagger") names the operation that produces the conjugated, transposed vector —
turn the column into a row, conjugate every entry. It reappears constantly from Chapter 4 on,
where `Bra`/`Ket` and postfix `†` (`Quantum/Dirac.swift`) give it real Swift syntax; here it's
just the rule above, spelled out over `[Complex]`:

```swift
func innerProduct(_ a: [Complex], _ b: [Complex]) -> Complex {
    var sum = Complex.zero
    for i in a.indices { sum = sum + a[i].conjugate * b[i] }
    return sum
}
let v: [Complex] = [Complex(1, 0), Complex.i]
let w: [Complex] = [Complex(1, 0), Complex(0, -1)]
print(innerProduct(v, w))
```

```text
0.0
```

Inner products matter for three reasons: they measure similarity (large when vectors point the
same way, zero when perpendicular), they compute transition probabilities between states, and
they determine distinguishability. Two vectors are **orthogonal** when their inner product is
zero — geometrically, perpendicular. `v` and `w` above are orthogonal.

Orthogonality of the two basis vectors, `[1,0]` and `[0,1]` (`|0⟩` and `|1⟩` in the notation
Chapter 4 introduces properly), means they are completely distinguishable — a measurement can
always tell them apart. Chapter 3 picks this up again on `StateVector`.

## 2.7 Length and normalization

The length, or norm, of a complex vector uses the magnitude of each entry, sums the squares, and
takes the square root:

```swift
func norm(_ v: [Complex]) -> Double {
    sqrt(v.reduce(0.0) { $0 + $1.magnitudeSquared })
}
let raw: [Complex] = [Complex(1, 0), Complex.i]
print(norm(raw))
```

```text
1.4142135623730951
```

That's `[1, i]`, with norm √2 — **not** a legal quantum state as it stands. A **unit vector** has
length 1, and every valid quantum state vector must be one: the magnitude-squared of each entry
is a probability, and for those probabilities to sum to 1, the vector's length-squared must be 1.
**Normalizing** means dividing every entry by the current length:

```swift
let normalized = raw.map { $0 * (1.0 / norm(raw)) }
print(normalized, norm(normalized))
```

```text
[0.7071067811865475, 0.7071067811865475i] 0.9999999999999999
```

This normalized vector is a legal state (its printed norm is `1` up to the usual floating-point
rounding): a qubit in equal superposition, with an imaginary amplitude on `|1⟩` rather than the
real one Chapter 3's `|+⟩` uses, but equally valid — the phase is free.

This is the last point in the book where a non-unit vector can exist at all. `StateVector.init`
normalizes immediately on construction, so from Chapter 3 onward the constraint above is
enforced by the type rather than something you check by hand.

## 2.8 Matrices as transformations, and why order matters

A matrix is a rectangular array of numbers; quantum gates are matrices, built the same way the
library's gate files build them:

```swift
let H = HadamardGate.matrix
print(H[0, 0], H.rows, H.cols)
```

```text
0.7071067811865475
2
2
```

`Matrix`'s storage is private — `subscript(row, col)` is the only way to read an entry.
Matrix-vector multiplication transforms a vector, and each entry of the result is the inner
product of one matrix row with the vector — tying directly back to §2.6:

```swift
print(H.multiply(by: [Complex.one, Complex.zero]))
```

```text
[0.7071067811865475, 0.7071067811865475]
```

Both entries are √2⁄2 ≈ 0.707 — the same amplitudes Chapter 1's tutorial read off the app's State
Vector panel after placing a single `H`. `Matrix.identity(size:)` builds the matrix that leaves
any vector unchanged, and the Pauli matrices `PauliXGate.matrix`, `PauliYGate.matrix`,
`PauliZGate.matrix` are three more named constants of the same shape — their behavior is
Chapter 7's subject.

Matrices also multiply each other, combining transformations — and the order is easy to get
backwards. If you apply gate `A` first and then gate `B`, the combined matrix is `B * A`, not
`A * B`:

```swift
let Z = PauliZGate.matrix
let ket0: [Complex] = [.one, .zero]
print((Z * H).multiply(by: ket0))   // "H then Z"
print((H * Z).multiply(by: ket0))   // wrong order
```

```text
[0.7071067811865475, -0.7071067811865475]
[0.7071067811865475, 0.7071067811865475]
```

`Z * H` gives `|−⟩`; `H * Z` silently gives `|+⟩` instead — a real, easy-to-make mistake once
you start composing gates by hand, which Chapter 3's `H;Z;H` circuit will do. `QuantumCircuit`
itself never hits this trap: `run()` applies each placed gate to the state one at a time, in the
order they were added, rather than ever forming a single product matrix — so tapping gates onto
the app's grid in reading order is always correct.

## 2.9 Unitary matrices, and why `==` lies

Not every matrix is a valid quantum gate — gates must be **unitary**. A matrix `U` is unitary
when `U†U = I`, where `U†`, the adjoint, transposes the matrix and conjugates every entry
(`Matrix.adjoint`, declared in `Quantum/Dirac.swift` alongside `Bra`/`Ket`, not in
`Math/Matrix.swift`). Unitary matrices preserve vector length: applying one to a unit vector
always produces another unit vector, which is exactly why every quantum gate must be one — a
gate that shrank or grew a state would produce probabilities that no longer sum to 1.

Checking `U†U == I` directly on the library's own gates turns up something worth knowing:

```swift
let I2 = Matrix.identity(size: 2)
for (name, g) in [("H", HadamardGate.matrix), ("X", PauliXGate.matrix),
                   ("S", SGate.matrix), ("T", TGate.matrix)] {
    print(name, g.adjoint * g == I2)
}
```

```text
H false
X true
S true
T true
```

`Matrix` is `Equatable` over raw `Double`s, so `==` is an *exact* comparison. `X`, `S`, and `T`
have entries that are exactly `0`, `±1`, or `±i`, so `U†U` comes out to exactly `I` and `==`
reports `true`. `H`'s entries are `±1/√2`, an irrational value that only rounds to a double —
`H.adjoint * H` misses `I` by about `2.22 × 10⁻¹⁶`, and `==` reports `false` even though `H` is
every bit as unitary as the others. A reader who happened to sanity-check unitarity with `X`
first would conclude `==` is a safe way to test it and be wrong the moment they tried `H`.

The fix is the tolerance idiom the package's own tests use throughout (for example
`SwiftQiskit/Tests/SwiftQiskitCoreTests/TensorProductTests.swift:30`): compare entries, not whole
matrices, and allow a small tolerance instead of demanding exact equality.

```swift
func maxDiff(_ a: Matrix, _ b: Matrix) -> Double {
    var m = 0.0
    for i in 0..<a.rows { for j in 0..<a.cols {
        m = max(m, (a[i, j] - b[i, j]).magnitude)
    } }
    return m
}
print(maxDiff(H.adjoint * H, I2))
```

```text
2.220446049250313e-16
```

Well under `1e-10`, the tolerance this book uses from here on whenever two matrices need to be
compared "close enough."

## 2.10 The tensor product `⊗`

The article this chapter follows holds tensor products for its next installment, and this book
does the same in depth in Chapter 11 — but the mechanics are worth seeing now, because
`QuantumCircuit` uses `⊗` on every single-qubit gate it builds.

`A.tensor(B)`, or `A ⊗ B`, replaces every entry `aᵢⱼ` of `A` with the block `aᵢⱼ · B`. Unlike
matrix multiplication, `⊗` places no constraint on shapes — an `m×n` matrix tensored with a
`p×q` matrix always gives an `mp×nq` result:

```swift
let a23 = Matrix([[Complex(1), Complex(2), Complex(3)], [Complex(4), Complex(5), Complex(6)]])
print(a23.tensor(I2).rows, a23.tensor(I2).cols)
print(H.tensor(I2))
```

```text
4 6
[0.7071067811865475, 0.0, 0.7071067811865475, 0.0]
[0.0, 0.7071067811865475, 0.0, 0.7071067811865475]
[0.7071067811865475, 0.0, -0.7071067811865475, -0.0]
[0.0, 0.7071067811865475, -0.0, -0.7071067811865475]
```

Each `±1/√2` entry of `H` became a `±1/√2 · I₂` block — the block rule directly. The `-0.0`
entries are ordinary signed zeros from multiplying by `−1/√2`; nothing is wrong. `⊗` is *not*
commutative — `I ⊗ H` and `H ⊗ I` differ — and SwiftQiskit's convention is that the left operand
occupies the high-order (leftmost) bits, matching qubit 0's place in every ket label.

This is exactly what placing `H` on qubit 0 of a 2-qubit circuit computes:

```swift
let qc = QuantumCircuit(qubits: 2)
qc.h(0)
print(qc.run().amplitudes)
print((H ⊗ I2).multiply(by: [Complex.one, .zero, .zero, .zero]))
```

```text
[0.7071067811865475, 0.0, 0.7071067811865475, 0.0]
[0.7071067811865475, 0.0, 0.7071067811865475, 0.0]
```

Identical. `h(qubit:)` builds exactly `H ⊗ I` (or `I ⊗ H`, depending on the target) internally
and applies that to the full state — there is no separate code path for "apply a gate to one
qubit of several." If you can't type `⊗` (it's Unicode U+2297), `a.tensor(b)` is the same thing.
Chapter 11 covers the mixed-product identity, product states versus entangled states, and
`StateVector`'s own `⊗`.

## 2.11 What `Complex` and `Matrix` don't have

Later chapters occasionally need something this chapter's two types don't provide. Rather than
re-explain each time, here is the complete list, checked directly against both source files:

| Missing | Where it's missed |
|---|---|
| `Complex` polar form: `.argument`, `exp`, `pow` | §2.4 above — build `e^{iθ}` by hand instead |
| Unary minus, `+`/`-`/`/` against a bare `Double` on `Complex` | none so far — write `Complex(-x, -y)` or `Complex(d, 0)` when needed |
| Standalone transpose (only the conjugated `.adjoint` exists) | none so far |
| Trace, determinant, inverse | Chapter 22's tomography |
| Matrix exponential `expm` | Chapter 24's Trotter error, which defines its own `expm` locally |
| Arithmetic (`+`, scalar `*`) on plain `[Complex]` vectors | §2.5 above — one-line `zip`/`map` helpers |

Where a chapter needs one of these, it defines a small local helper rather than extending the
library — see `AUTHORING.md`'s note that Chapters 21–25 keep such helpers self-contained in the
chapter text.

## Build it in the app

○ Not expressible directly — there is no way to enter a raw matrix or complex number in the app.
Every later "Not expressible" chapter comes back to this same limitation. But §2.3 and §2.4's
distinction between magnitude and phase *is* visible, tapped out:

1. **Place `H`** on qubit 0 of the default circuit. The State Vector panel lists both amplitudes
   at probability ≈ 0.500.
2. **Place `P`** in the next column on the same wire, then tap the tile to open its θ popover and
   drag the slider away from 0.
3. **Watch the amplitude column, not the probability column.** The second amplitude's printed
   value changes shape — from a real number to something with both a real and an imaginary part
   — while both probabilities stay at ≈ 0.500. Verified: after `H` then `P(1.1)`, the amplitudes
   are `[0.707…, 0.321… + 0.630…i]` with probabilities `[0.500, 0.500]` throughout.

That is phase moving while probability holds still — the physical content of §2.3, and the setup
for Chapter 8, where phase differences between *two* amplitudes finally do change a probability.

## Run it in code

Every snippet above was run with `RunCodeSnippet` against
`SwiftQiskitApp/SwiftQiskitApp/CircuitModel.swift`; the printed output beneath each one is the
real result, not a transcription.

## Try it yourself

1. Compute `(2+i)(3-i)` by hand, then check with `Complex(2,1) * Complex(3,-1)`.
   <details><summary>Answer</summary>`(2+i)(3-i) = 6 - 2i + 3i - i² = 6 + i + 1 = 7 + i`.</details>

2. From the block rule in §2.10, what is entry `[2, 0]` of `H ⊗ I`, and why?
   <details><summary>Answer</summary>`H[1,0] · I[0,0] = 0.7071067811865475 · 1 = 0.7071067811865475`
   — row 2, column 0 of a 4×4 tensor falls in the block for `H[1,0]`, and within that block it's
   position `[0,0]` of `I`. This is exactly the embedding Chapter 7 and Chapter 11 rely on to
   apply a single-qubit gate to one qubit of a larger register.</details>

3. Why does `X.adjoint * X == Matrix.identity(size: 2)` return `true`, while the same check on
   `H` returns `false`, even though both gates are unitary?
   <details><summary>Answer</summary>`X`'s entries are exactly `0` and `1`, so `X†X` computes to
   exactly `I` and `Matrix`'s exact `Equatable` conformance says `true`. `H`'s entries are
   `±1/√2`, an irrational value only approximated by a `Double`, so `H†H` misses `I` by about
   `2.22e-16` — real, but tiny — and `==` reports `false`. Use `maxDiff` with a `1e-10`
   tolerance instead of `==` whenever irrational entries are involved.</details>

4. You want one matrix for "apply `H`, then `Z`, then `H`" (this is Chapter 3's `circuit2`).
   Write it, and say what `H * Z * H` would give instead if you'd built it in the wrong order.
   <details><summary>Answer</summary>The first gate applied goes rightmost, so the correct
   matrix is `H * Z * H` — which happens to *look* symmetric and therefore order-proof here only
   because the sequence is a palindrome. Chapter 2's `H` then `Z` example shows the general
   danger clearly: `Z * H` and `H * Z` disagree, and only one of them is "apply `H` then
   `Z`."</details>

---
[← Chapter 1](01-Setup.md) · [Contents](../../INTRODUCTION.md) · [Chapter 3 →](03-Qubits.md)
