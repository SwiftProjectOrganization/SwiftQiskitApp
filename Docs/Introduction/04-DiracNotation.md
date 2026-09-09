# Chapter 4 — Dirac Notation and Expectation Values

> The `Ket`/`Bra`/`†` notation the rest of the book writes math in, and how projectors and Pauli
> expectation values (`⟨ψ|X|ψ⟩`) read a qubit's Bloch coordinates straight off its state vector.

| | |
|---|---|
| Playground page | [`01Qubits`](../../../SwiftQiskit/PlaygroundDocs/01QUBITSHELP.md), [`08Dirac`](../../../SwiftQiskit/PlaygroundDocs/08DIRACHELP.md) |
| In the app | ◐ — ψ's Bloch readout in the Display sheet *is* the three Pauli expectation values; the bra/projector algebra itself is code-only |
| Library APIs | `Quantum/Dirac.swift` (`Ket`, `Bra`, postfix `†`, inner/outer `*`, `Bra * Matrix -> Bra`, `Matrix.adjoint`, basis kets `Ket("01")`, `.zero/.one/.plus/.minus/.plusI/.minusI`) |
| Prerequisites | Chapters 2, 3 |

## 4.1 Ket, Bra, and the dagger

`Ket` is a typealias of `StateVector` — everything Chapter 3 established about amplitudes and
normalization carries over unchanged; Dirac notation is a new way to *write* the same object,
not a new type of state. `Bra` (`Quantum/Dirac.swift`) is the conjugate-transpose row form,
`⟨ψ| = (|ψ⟩)†`, and it stores its amplitudes **already conjugated** — the reason `Bra * Ket`
below is a plain (unconjugated) dot product rather than something that has to conjugate on
every multiplication.

```swift
let plus = Ket.plus
print(plus)
print(plus†)
```

```text
|0⟩: 0.7071067811865475
|1⟩: 0.7071067811865475
⟨0|: 0.7071067811865475
⟨1|: 0.7071067811865475
```

Note the labels are **not** zero-padded here — `|0⟩`/`|1⟩` rather than a fixed-width binary
string. (Zero-padded labels only appear in measurement results, via `SimulationResult` —
Chapter 9.)

The postfix `†` operator overloads three ways: `Ket → Bra`, `Bra → Ket`, and `Matrix → Matrix`
(via `Matrix.adjoint`, introduced in Chapter 2 §2.9). Daggering twice is an exact involution:

```swift
print((plus†)† == plus)
```

```text
true
```

*Exactly* `true`, not "true up to rounding." The reason is the guard inside
`StateVector.normalize()` (`Quantum/StateVector.swift`): renormalizing a vector whose length is
already within `1e-12` of 1 is skipped entirely, so daggering twice returns the identical
`Double`s it started with rather than re-dividing by a length computed twice. This is the same
mechanism Chapter 2 §2.7 promised — normalization enforced by the type — now paying off as an
exact equality rather than an approximate one.

`†` is the Unicode dagger, U+2020 (⌥T on a US keyboard layout). If you can't type it, every use
in this chapter has an ASCII equivalent: `Bra(ket)` for `ket†`, `bra.ket` for `bra†`, and
`matrix.adjoint` for `matrix†`.

## 4.2 Inner and outer products

`Bra * Ket` is the inner product ⟨φ\|ψ⟩ — a single `Complex` number measuring the overlap of two
states. This is the same formula Chapter 2 §2.6 built by hand as a `zip`/`map` helper over plain
`[Complex]` arrays; Dirac notation just gives it operator syntax that reads like the math:

```swift
print(Bra("0") * Ket("0"))
print(Bra("0") * Ket("1"))
print(Ket.plus† * Ket.zero)
```

```text
1.0
0.0
0.7071067811865475
```

`⟨0|0⟩ = 1` and `⟨0|1⟩ = 0`: the computational basis states are normalized and orthogonal to
each other (Chapter 2 §2.6's definition of orthogonality, now on named basis kets).
`⟨+|0⟩ = 1/√2 ≈ 0.707` is neither — `|+⟩` has partial overlap with `|0⟩`, which is exactly what
"superposition" means geometrically.

Every normalized state overlaps itself with exactly 1, and swapping bra and ket conjugates the
result — `⟨φ|ψ⟩ = ⟨ψ|φ⟩*`:

```swift
let ketPhi = Ket([Complex(0.6), Complex(0.8)])
print(ketPhi† * ketPhi)

let forward = ketPhi† * Ket.plusI
let backward = Ket.plusI† * ketPhi
print(forward)
print(backward.conjugate)
```

```text
1.0
0.42426406871192845 + 0.565685424949238i
0.42426406871192845 + 0.565685424949238i
```

`forward` and `backward.conjugate` print identically — that identity *is* the conjugate-symmetry
check, with the second value already conjugated before printing so the two lines can be compared
directly.

`Ket * Bra` runs the same two operands the other way and produces a different *type* entirely —
a `Matrix`, the outer product |ψ⟩⟨φ|. §4.3 below is built entirely on that distinction: a bra
before a ket is a number; a ket before a bra is a matrix.

## 4.3 Projectors and adjoints

`|0⟩⟨0|` and `|1⟩⟨1|` are outer products — each one a `Matrix` that projects any state onto that
basis vector:

```swift
let p0 = Ket.zero * Ket.zero†
let p1 = Ket.one * Ket.one†
print(p0)
print(p1)
```

```text
[1.0, 0.0]
[0.0, 0.0]
[0.0, 0.0]
[0.0, 1.0]
```

A projector has two defining properties, both checkable directly: it is **Hermitian**
(`P† = P` — projecting is its own adjoint) and **idempotent** (`P·P = P` — projecting twice does
nothing a single projection didn't already do):

```swift
print(p0† == p0)
print((p0 * p0) == p0)
```

```text
true
true
```

The two basis projectors are also **complete**: they sum to the identity, so every state
decomposes over the basis as `|ψ⟩ = |0⟩⟨0|ψ⟩ + |1⟩⟨1|ψ⟩`. `Matrix` has a `+` operator, so this
is a direct check:

```swift
print(p0 + p1 == Matrix.identity(size: 2))
```

```text
true
```

Sandwiching a projector between a bra and its ket recovers the Born rule from Chapter 3 §3.2 —
`⟨φ|0⟩⟨0|φ⟩` is another way to write `P(0) = |⟨0|φ⟩|²`, and it matches `.probabilities[0]`
exactly:

```swift
let born = ketPhi† * p0 * ketPhi
print(born, ketPhi.probabilities[0])
```

```text
0.36 0.36
```

`†` on a `Matrix` is the same conjugate-transpose operation Chapter 2 §2.9 introduced. `H` and
the Pauli gates are all unitary (`U†U = I`), and the Paulis and `H` are additionally
**Hermitian** (`U† = U`) — a stronger property most gates don't have:

```swift
print(HadamardGate.matrix† == HadamardGate.matrix)
print(PauliYGate.matrix† == PauliYGate.matrix)
```

```text
true
true
```

This is a sharper use of `==` than Chapter 2 §2.9 warned against, not a contradiction of it:
daggering only transposes and conjugates entries — no arithmetic happens, so no new rounding is
introduced, and `==` is exact and safe here. The moment multiplication enters, §2.9's warning is
back in force:

```swift
print(HadamardGate.matrix† * HadamardGate.matrix)

func maxDiff(_ a: Matrix, _ b: Matrix) -> Double {
    var m = 0.0
    for i in 0..<a.rows { for j in 0..<a.cols {
        m = max(m, (a[i, j] - b[i, j]).magnitude)
    } }
    return m
}
print(maxDiff(HadamardGate.matrix† * HadamardGate.matrix, Matrix.identity(size: 2)))
```

```text
[0.9999999999999998, 0.0]
[0.0, 0.9999999999999998]
2.220446049250313e-16
```

`H†H` misses `I` by the same ~1e-16 Chapter 2 §2.9 measured directly on `H†H` there — the
`maxDiff`/`1e-10` tolerance idiom applies exactly as before.

Hermitian operators matter beyond this chapter for one reason: their expectation values are
always real numbers, never complex. §4.4 is built entirely on that fact.

## 4.4 Pauli expectation values as Bloch coordinates

Every single-qubit state can be written as `|ψ⟩ = cos(θ/2)|0⟩ + e^{iφ}·sin(θ/2)|1⟩` for some
angles θ and φ — the parametrization Chapters 5 and 6 use to place `|ψ⟩` on the Bloch sphere.
This chapter only needs it as a way to build a state with a genuinely nonzero phase, `φ`, in
both its real and imaginary parts at once:

```swift
func makeState(theta: Double, phi: Double) -> StateVector {
    StateVector([
        Complex(cos(theta / 2)),
        Complex(sin(theta / 2) * cos(phi), sin(theta / 2) * sin(phi))
    ])
}
let theta = Double.pi / 3
let phi = Double.pi / 4
let psi = makeState(theta: theta, phi: phi)
```

A bra against a basis ket extracts a single amplitude — `⟨0|ψ⟩ = α`, `⟨1|ψ⟩ = β` — which reads
exactly like the standard `|ψ⟩ = α|0⟩ + β|1⟩` notation:

```swift
print(Bra("0") * psi)
print(Bra("1") * psi)
```

```text
0.8660254037844387
0.35355339059327373 + 0.3535533905932737i
```

`α = cos(30°) ≈ 0.866`, `β = 0.5·e^{iπ/4} ≈ 0.354 + 0.354i` — both match the parametrization
directly.

The point of this section: the three Pauli **expectation values** `⟨ψ|X|ψ⟩`, `⟨ψ|Y|ψ⟩`,
`⟨ψ|Z|ψ⟩` are exactly the Bloch coordinates `x, y, z` Chapters 5–6 draw. The `Bra * Matrix -> Bra`
overload (`Quantum/Dirac.swift`) is what lets the code read in the same order as the math:

```swift
let expectX = psi† * PauliXGate.matrix * psi
let expectY = psi† * PauliYGate.matrix * psi
let expectZ = psi† * PauliZGate.matrix * psi
print(expectX, expectY, expectZ)
print(sin(theta) * cos(phi), sin(theta) * sin(phi), cos(theta))
```

```text
0.6123724356957945 0.6123724356957945 0.5000000000000002
0.6123724356957946 0.6123724356957945 0.5000000000000001
```

Each printed value has **no `i` suffix** — `Complex.description` drops a zero imaginary part
entirely (Chapter 2 §2.2's formatting note), and here that's the point, not a coincidence: X, Y,
and Z are all Hermitian (§4.3), so their expectation values against any state are guaranteed
real. The closed forms `sin θ cos φ`, `sin θ sin φ`, `cos θ` agree with the bra–ket computation
to about 15 significant figures — two independent routes to the same three numbers.

`BlochVector` — the app's own type (`SwiftQiskitApp/BlochVector.swift`) — computes the identical
point straight from the amplitudes, without going through `Bra`/`Matrix` at all:
`x = 2·Re(ᾱβ)`, `y = 2·Im(ᾱβ)`, `z = |α|² − |β|²`:

```swift
let bloch = BlochVector(psi)
print(bloch.x, bloch.y, bloch.z)
```

```text
0.6123724356957945 0.6123724356957945 0.5000000000000002
```

Identical to the bra–ket result above, to the last printed digit. This is not a second,
unrelated formula — it is algebraically the same expectation value, and it's the formula the
app's Bloch sphere actually draws every time it renders a qubit.

## 4.5 Multi-qubit kets and bras

`Ket`/`Bra` basis labels extend to multiple qubits the same way Chapter 2 §2.10's tensor product
does — qubit 0 is the most-significant (leftmost) bit, and `⊗` concatenates registers exactly
like label concatenation:

```swift
print(Ket("01") == Ket.zero ⊗ Ket.one)
```

```text
true
```

Conjugation distributes over `⊗` *exactly*: `(|a⟩ ⊗ |b⟩)† = ⟨a| ⊗ ⟨b|`, with no rounding gap,
for the same reason §4.1's double-dagger was exact — conjugation touches no lengths, and
re-normalizing an already-normalized tensor product is a no-op:

```swift
print(Ket.plus† ⊗ Ket.one† == (Ket.plus ⊗ Ket.one)†)
```

```text
true
```

Mixing a bra and a ket in `⊗` is not a new operation — it is the outer product from §4.3,
spelled with `⊗` instead of `*`. A column (m×1) tensored with a row (1×n) is literally an m×n
matrix with entries `aᵢb̄ⱼ`, which is `|a⟩⟨b|`; a row tensored with a column puts the ket back in
the columns, which is why the operands swap: `⟨a| ⊗ |b⟩ = |b⟩⟨a|`.

```swift
let mixed1 = Ket.zero ⊗ Ket.zero†
let mixed2 = Ket.zero * Ket.zero†
print(mixed1 == mixed2)

let asym = Ket("10") ⊗ Bra("0")
print(asym.rows, asym.cols)
```

```text
true
4 2
```

`Ket ⊗ Bra` produces exactly the same `Matrix` as the outer product spelled with `*`. Unlike `*`,
`⊗` places no constraint on matching dimensions — `Ket("10")` (a 2-qubit, 4-dimensional register)
tensored with `Bra("0")` (1 qubit, dimension 2) gives a 4×2 result, not a square one.

Finally, a Bell-state amplitude as a one-line bra–ket product — the circuit from
`Docs/Tutorial.md`'s walkthrough, which Chapter 12 covers properly:

```swift
let bellCircuit = QuantumCircuit(qubits: 2)
bellCircuit.h(0)
bellCircuit.cx(0, 1)
let bellState = bellCircuit.run()
print(Bra("11") * bellState)
```

```text
0.7071067811865475
```

`⟨11|Φ⁺⟩ = 1/√2` — the same amplitude the app's State Vector panel would show on the `|11⟩` row
of that circuit, now read out as an inner product instead of a panel row. Chapter 11 covers the
tensor-product mechanics in depth, and Chapter 12 covers what makes this particular state,
`Φ⁺`, entangled.

## Build it in the app

◐ Section §4.4's three numbers are exactly what the **Display** sheet's Bloch readout already
shows — that part is real, tap-by-tap:

1. Drop **Qubits** to 1.
2. Arm **RY** ("Rotation (θ = π/2)" section), tap the empty cell on `q0`. Tap the tile, and drag
   the θ slider to `1.047` (as close to π/3 as the three-decimal readout lets you get).
3. Arm **P**, tap the next empty cell on `q0`. Tap that tile and drag its slider to `0.785`
   (π/4).
4. The State Vector panel now shows `|0⟩: 0.866…  (p=0.750)` and
   `|1⟩: 0.354… + 0.354…i  (p=0.250)` — this is `|ψ⟩` from §4.4, `α` and `β` read directly off
   the panel instead of via `Bra("0")`/`Bra("1")`.
5. Tap **Display** → **Final**. The `q0` sphere's readout reads
   `x +0.612  y +0.612  z +0.500` with `θ 1.047 rad  φ 0.785 rad` underneath. **Those three
   numbers are `⟨ψ|X|ψ⟩`, `⟨ψ|Y|ψ⟩`, `⟨ψ|Z|ψ⟩`** — the whole content of §4.4, produced by the
   same `BlochVector` type the "Run it in code" section calls directly, read off the screen
   instead of printed to a console.
6. Switch to **Steps** mode: `Start` (the `|0⟩` pole) → `Col 1` (after `RY`, swung out to
   `θ ≈ 1.047 rad` at azimuth `φ = 0`, since a real amplitude puts it on the sphere's prime
   meridian) → `Col 2` (after `P`, same `θ` — `P` never changes `|α|` or `|β|` — rotated purely
   in azimuth to `φ ≈ 0.785`) shows the same trajectory one gate at a time.

What's still missing, and stays code-only: there is no bra display, no way to enter an arbitrary
matrix or projector, and no expectation value for anything other than the three fixed Paulis —
and even those only appear implicitly, as Bloch coordinates, never labeled `⟨ψ|X|ψ⟩` on screen.
§4.1–§4.3's ket/bra/projector algebra has no visual counterpart at all. Also note the θ slider
has no exact-entry field and a three-decimal readout, so step 2–3 above only approximate the
code's exact `.pi / 3` and `.pi / 4` — small enough that the app's rounded readout still matches
the values above to three decimals, but not bit-for-bit identical to them.

## Run it in code

Every snippet above was run with `RunCodeSnippet` against
`SwiftQiskitApp/SwiftQiskitApp/CircuitModel.swift`; the printed output beneath each one is the
real result, not a transcription. The app-path claim in step 5 above was separately verified by
driving `CircuitBuilder` directly:

```swift
let builder = CircuitBuilder(qubitCount: 1)
_ = builder.place(.ry(.pi / 3), qubits: [0], column: 0)
_ = builder.place(.p(.pi / 4), qubits: [0], column: 1)
let state = builder.buildCircuit().run()
print(state.amplitudes, state.probabilities)
let bloch = BlochVector(state, qubit: 0)
print(bloch.x, bloch.y, bloch.z, bloch.theta, bloch.phi)
```

```text
[0.8660254037844387, 0.35355339059327373 + 0.3535533905932737i] [0.7500000000000001, 0.24999999999999992]
0.6123724356957945 0.6123724356957945 0.5000000000000002 1.0471975511965974 0.7853981633974483
```

Identical to §4.4's `makeState(theta: .pi/3, phi: .pi/4)` result — building `|ψ⟩` by tapping
`RY` then `P` onto the app's grid is the same state as building it directly from the closed-form
amplitudes, and `bloch.theta`/`bloch.phi` recover the exact input angles, π/3 and π/4.

## Try it yourself

1. `⟨+i|Z|+i⟩ ≈ 0` — verify it, and explain why in terms of `|α|²` and `|β|²` rather than just
   "it's on the equator."
   <details><summary>Answer</summary>`Ket.plusI† * PauliZGate.matrix * Ket.plusI` gives exactly
   `0.0`. `⟨ψ|Z|ψ⟩ = |α|² − |β|²` (§4.4's `z` coordinate), and `|+i⟩ = (|0⟩ + i|1⟩)/√2` has
   `|α|² = |β|² = 0.5`, so the two terms cancel exactly. Equatorial states have `z = 0` by this
   same reasoning generally — the geometry Chapter 5 draws is just this algebra, drawn.</details>

2. Why is `(|ψ⟩†)† == |ψ⟩` checked as *exactly* `true` in §4.1, when so much of this book's
   arithmetic only holds "up to floating-point rounding"?
   <details><summary>Answer</summary>`StateVector.normalize()` skips rescaling whenever the
   vector's length is already within `1e-12` of 1 (the guard at
   `Quantum/StateVector.swift`'s `normalize()`). Daggering a normalized ket twice never leaves
   that tolerance, so the rescaling step — the only place rounding could enter — never runs
   twice, and the second dagger returns the exact `Double`s the first one started from.</details>

3. `Ket.zero * Ket.zero†` and `Ket.zero† * Ket.zero` both type-check. What type does each
   produce, and what does each one mean physically?
   <details><summary>Answer</summary>`Ket * Bra` is `Ket * (Ket)†`, a ket followed by a bra —
   the outer product, a `Matrix` (here, `|0⟩⟨0|`, the projector onto `|0⟩`). `Ket† * Ket` is a
   bra followed by a ket — the inner product, a `Complex` number (here, `⟨0|0⟩ = 1.0`, the
   state's overlap with itself). Same two operands, reversed order, different type
   entirely.</details>

4. `ketPhi† * ketPhi` is exactly `1.0` for `Ket([Complex(0.6), Complex(0.8)])`, but the same
   check on `Ket([Complex(0.5), Complex(0.5)])` gives `0.9999999999999998`. Why the
   difference?
   <details><summary>Answer</summary>`0.6² + 0.8² = 1` exactly in floating point, so
   `normalize()`'s guard (question 2's answer) sees a length already at 1 and skips rescaling —
   the inner product with itself is then exact. `0.5² + 0.5² = 0.5`, so `[0.5, 0.5]` *is*
   rescaled, by `1/√0.5`, and that division is where the ~1e-16 rounding enters — the same
   mechanism as question 2, just triggered instead of avoided.</details>

---
[← Chapter 3](03-Qubits.md) · [Contents](../../INTRODUCTION.md) · [Chapter 5 →](05-BlochSphere2D.md)
