# Chapter 18 — Teleportation and Superdense Coding

> Moving a qubit's state across an entangled pair without moving the qubit: Bell-basis
> rotation, deferred measurement standing in for a classical channel, and the Bloch spheres of
> every branch Bob could have ended up holding — plus the reverse trick, superdense coding,
> which spends the same shared pair to send two classical bits over one qubit with certainty.

| | |
|---|---|
| Playground page | [`13Teleportation`](../../../SwiftQiskit/PlaygroundDocs/13TELEPORTATIONHELP.md) |
| In the app | ◐ — every gate in both protocols is tappable (`ry`/`rz` for the payload, `h`, `cx`, and CZ as `h;cx;h`); what's missing is real mid-circuit measurement with a classically conditioned correction, and reading out one measurement branch without collapsing the rest |
| Library APIs | `QuantumCircuit.ry/rz/h/x/z/cx`, `.run()`, `measure(shots:)`, `Ket`/`Bra` outer-product projectors, mixed `⊗`, `StateVector.apply(_:)`, postfix `†`, `Ket.plus`, `PauliXGate.matrix`/`PauliZGate.matrix`, `BlochVector` |
| Prerequisites | Chapters 4, 9, 11, 12, 15 |

## 18.1 The protocol, stage by stage

Alice holds a qubit in an unknown state |ψ⟩ and wants Bob to have it. They share no quantum
channel — only a **Bell pair** prepared in advance and an ordinary classical channel (a phone
call, a text message). Teleportation (Bennett et al., 1993) moves |ψ⟩ to Bob using that Bell
pair and two classical bits.

Three things it is *not*:

- **Not faster than light.** Bob's qubit is useless until Alice's two bits arrive by an
  ordinary classical channel; before that, his outcome statistics don't depend on what |ψ⟩ was
  (§18.3 prints P(ab) = ¼ for every branch, independent of ψ, to make this concrete).
- **Not cloning.** Alice's own qubit ends the protocol in |+⟩, carrying nothing of |ψ⟩ — the
  state *moves*, it doesn't copy (§18.5).
- **Not a way to transmit an unknown state's description.** Neither Alice nor Bob ever learns
  ψ's amplitudes; the two classical bits carry a correction recipe, not α and β.

Register (qubit 0 is the most-significant/leftmost bit, as throughout this book): q0 is
Alice's payload |ψ⟩, q1 is Alice's half of a Bell pair, q2 is Bob's half.

```text
q0: |ψ⟩ ──────────────■── H ─────────■─── (Alice, ends in |+⟩)
                      │              │
q1: |0⟩ ── H ──■─────⊕──────────■────│─── (Alice, ends in |+⟩)
               │                 │    │
q2: |0⟩ ───────⊕────────────────⊕───Z─── (Bob, ends in |ψ⟩)
```

| Step | Circuit | Effect |
|---|---|---|
| 1 | `ry(θ,0); rz(φ,0)` | prepare the payload \|ψ⟩ on q0 |
| 2 | `h(1); cx(1,2)` | the shared Bell pair on q1, q2 |
| 3 | `cx(0,1); h(0)` | Alice's rotation into the Bell basis |
| 4 | *measure q0 → a, q1 → b; send (a,b)* | the classical channel |
| 5 | X^b then Z^a on q2 | Bob's correction |

The payload throughout this chapter is |ψ⟩ = cos(θ/2)|0⟩ + e^{iφ}sin(θ/2)|1⟩ with θ = 60°,
φ = 45° — the same qubit Chapters 6 and 8 used, built here with `ry(θ, 0); rz(φ, 0)`:

```swift
let theta = Double.pi / 3
let phi = Double.pi / 4
let psiCircuit = QuantumCircuit(qubits: 1)
psiCircuit.ry(theta, 0)
psiCircuit.rz(phi, 0)
let psi = psiCircuit.run()
```

```text
psi:  |0⟩: 0.8001 − 0.3314i   |1⟩: 0.4619 + 0.1913i
P(0), P(1):  [0.7500, 0.2500]
Bloch point: x 0.6124  y 0.6124  z 0.5000
```

`rz` contributes an overall e^{−iφ/2} relative to Chapter 8's convention — a *global* phase,
invisible to every probability and Bloch point in this chapter. Loading q0, q1, q2 with |ψ⟩
and the Bell pair keeps them a plain product so far:

```text
after preparing q0 = psi:     |000⟩: 0.8001 − 0.3314i   |100⟩: 0.4619 + 0.1913i
after Bell pair on q1,q2:     |000⟩: 0.5658 − 0.2343i   |011⟩: 0.5658 − 0.2343i
                               |100⟩: 0.3266 + 0.1353i   |111⟩: 0.3266 + 0.1353i
```

## 18.2 Alice's Bell-basis rotation

`cx(0,1); h(0)` is exactly the change of basis that turns "measure q0, q1 in the *Bell*
basis" into "measure q0, q1 in the computational basis" — the standard trick for measuring in
a rotated basis (rotate first, then measure in the basis you already know how to measure in).
Afterward the state is

```text
½ Σ_{a,b} |ab⟩ ⊗ (X^b Z^a |ψ⟩)
```

every one of Bob's four possible states present at once, tagged by the prefix ab:

```text
after cx(0,1); h(0):
  |000⟩: 0.4001 − 0.1657i   |001⟩: 0.2310 + 0.0957i
  |010⟩: 0.2310 + 0.0957i   |011⟩: 0.4001 − 0.1657i
  |100⟩: 0.4001 − 0.1657i   |101⟩: −0.2310 − 0.0957i
  |110⟩: −0.2310 − 0.0957i  |111⟩: 0.4001 − 0.1657i
```

The magnitudes split by whether the last two bits agree, not by the prefix: |000⟩, |011⟩,
|100⟩, |111⟩ (b = c) sit at 0.4330, and |001⟩, |010⟩, |101⟩, |110⟩ (b ≠ c) sit at 0.2500 — half
of |ψ⟩'s two amplitude magnitudes, 0.8001 and 0.4619, respectively.

## 18.3 The four branches, via projectors

Rather than call `measure()` and collapse the register, `(|ab⟩⟨ab|) ⊗ I₂` — a mixed `⊗` of a
Ket*Bra outer product with the identity — projects onto one branch and leaves the other three
alone. `StateVector.apply(_:)` renormalizes automatically, so the projection comes out as a
proper state:

```swift
let branchCorrections: [String: Matrix] = [
    "00": Matrix.identity(size: 2),
    "01": PauliXGate.matrix,
    "10": PauliZGate.matrix,
    "11": PauliZGate.matrix * PauliXGate.matrix   // apply X, then Z
]

for a in 0...1 {
    for b in 0...1 {
        let label = "\(a)\(b)"
        let projector = (Ket(label) * Bra(label)) ⊗ Matrix.identity(size: 2)
        var projected = bellBasisState
        projected.apply(projector)
        // ... slice out q2's two amplitudes, apply the correction, check fidelity against psi
    }
}
```

| ab | P(ab) | Bob applies | fidelity |
|---|---|---|---|
| 00 | 0.2500 | I | 1.0000 |
| 01 | 0.2500 | X | 1.0000 |
| 10 | 0.2500 | Z | 1.0000 |
| 11 | 0.2500 | X, then Z | 1.0000 |

P(ab) is ¼ for every branch — Bob's marginal never depends on ψ, which is §18.1's
no-faster-than-light point made numerically. And every branch reaches fidelity 1.0000 once it
gets *its own* correction: branch 11 leaves Bob holding XZ|ψ⟩ (Z acts first, reading the matrix
product right to left), so undoing it means applying X and then Z — ZX, not XZ. Swapping that
order changes the recovered state only by ZX = −XZ, a global phase ("Try it yourself" below
confirms this doesn't affect fidelity, as long as it's applied consistently).

## 18.4 Deferred measurement

`SwiftQiskit` has no mid-circuit measurement, so instead of "measure (a,b), look up a
correction, apply it," the protocol applies the corrections as *controlled* gates before ever
measuring: `cx(1,2)` flips q2 exactly when q1 = 1 (the X^b part), and CZ(0,2) — built as
`h(2); cx(0,2); h(2)`, Chapter 15's idiom — phases q2 exactly when q0 = 1 (the Z^a part). Every
branch gets its own correction at once, in superposition, because the controls do the "look
up a correction" step for free:

```swift
qc.cx(1, 2)                     // X^b
qc.h(2); qc.cx(0, 2); qc.h(2)   // Z^a, as CZ(0,2)
let finalState = qc.run()
```

```text
final state:
  |000⟩: 0.4001 − 0.1657i   |001⟩: 0.2310 + 0.0957i
  |010⟩: 0.4001 − 0.1657i   |011⟩: 0.2310 + 0.0957i
  |100⟩: 0.4001 − 0.1657i   |101⟩: 0.2310 + 0.0957i
  |110⟩: 0.4001 − 0.1657i   |111⟩: 0.2310 + 0.0957i
matches |+⟩⊗|+⟩⊗|ψ⟩ to within 8.3e-17
```

The register **factors** (Chapter 11's language): q0 and q1 end in |+⟩ regardless of ψ, and
q2 ends in exactly |ψ⟩. That's the whole protocol — everything before this line was setup;
this line is the payoff.

## 18.5 No cloning, and what the shots show

q2's marginal reproduces |ψ|²; q0's marginal is a fair coin — the payload has *left* q0, not
duplicated there:

```text
q2 (Bob) marginal:    [0.7500, 0.2500]
psi probabilities:    [0.7500, 0.2500]
q0 (Alice) marginal:  [0.5000, 0.5000]
```

`measure(shots:)` replays every recorded operation per shot, so a 1000-shot run (one real run —
expect a rerun to jitter) gives:

```text
1000 shots (q0 q1 q2):
  000: 187   001: 77
  010: 192   011: 62
  100: 184   101: 60
  110: 182   111: 56
```

Each of the four ab prefixes takes roughly 250 of the 1000 shots (they're a fair coin flip,
independent of ψ), and *within* every prefix the last bit splits roughly 3-to-1 — |ψ|²'s
0.75/0.25 — the same regardless of how Alice's two bits happen to fall, since the corrections
already absorbed the difference between branches.

## 18.6 Bloch spheres of every branch

The correction matrices double as the maps that *build* each branch: applying X^bZ^a to |ψ⟩
gives exactly the state Bob would be holding before his classical bits arrive.

| Sphere | x | y | z |
|---|---|---|---|
| \|ψ⟩ (and ab = 00) | 0.6124 | 0.6124 | 0.5000 |
| ab = 01 (X\|ψ⟩) | 0.6124 | −0.6124 | −0.5000 |
| ab = 10 (Z\|ψ⟩) | −0.6124 | −0.6124 | 0.5000 |
| ab = 11 (XZ\|ψ⟩) | −0.6124 | 0.6124 | −0.5000 |
| Bob, corrected | 0.6124 | 0.6124 | 0.5000 |

Read the middle two rows as the half-turns they are: X flips y and z, leaving x; Z flips x and
y, leaving z. Bob's corrected sphere lands back exactly on the first row — that's the whole
protocol in one picture.

The app's Display → Steps view over q2 alone tells the same story a different way ("Build it in
the app" below walks through these columns): q2 starts pure at the north pole (|r| = 1),
collapses to the sphere's center once it's entangled with q1 (|r| = 0, maximally mixed from
q2's own point of view), climbs back out to a mixed |r| = 0.5 as each correction's first gate
lands, and only settles on the ψ point once *both* corrections are fully applied — briefly
passing through a *different* pure point (|r| = 1, but not yet ψ) along the way, once the CZ's
`cx` lands before its closing `H` does. A qubit's reduced Bloch vector shrinking to 0 and
growing back out is what entanglement and its resolution look like on a single sphere.

## 18.7 Superdense coding: the dual protocol

Teleportation spends one Bell pair and two classical bits to move one qubit. Superdense coding
runs the same resource the other way: Alice sends **two classical bits** by transmitting **one
qubit**, given a pre-shared Bell pair. She applies one of I / X / Z / ZX to her half, sends it,
and Bob undoes the entangling circuit with `cx(0,1); h(0)` to read both bits with certainty:

```swift
let sdMessages: [(String, (QuantumCircuit) -> Void)] = [
    ("00", { _ in }),
    ("01", { $0.x(0) }),
    ("10", { $0.z(0) }),
    ("11", { $0.z(0); $0.x(0) })
]
// for each: h(0); cx(0,1); encode; cx(0,1); h(0); read off both bits
```

```text
sent  decoded  P
 00     00    1.0000
 01     01    1.0000
 10     10    1.0000
 11     11    1.0000

Gram matrix |⟨Bell_i|Bell_j⟩|:
  00: 1.00  0.00  0.00  0.00
  01: 0.00  1.00  0.00  0.00
  10: 0.00  0.00  1.00  0.00
  11: 0.00  0.00  0.00  1.00
```

The four encodings prepare the four Bell states, and the Gram matrix printed above is exactly
the identity — they're orthonormal, which is *why* decoding never errs. Between them,
teleportation and superdense coding say the same Bell pair is worth "2 classical bits + 1
e-bit → 1 qubit" in one direction and "1 qubit + 1 e-bit → 2 classical bits" in the other.

## Build it in the app

◐ Every gate above is a palette tile. Clear, set **Qubits: 3**.

1. **The payload and the Bell pair.** Arm **RY** (Rotation section, default θ = π/2), tap `q0`
   in column 0 — its popover opens; drag θ to `1.047` (≈ π/3). Arm **H**, tap `q1` in column 0.
   Arm **RZ**, tap `q0` in column 1; drag its popover to `0.785` (≈ π/4, already exact to three
   decimals). Arm **CX**, tap `q1` (control) then `q2` (target) in column 1 — the shared Bell
   pair. State Vector panel: four rows matching §18.1's "after Bell pair" line, still a plain
   product across {q0} and {q1,q2}.
2. **Alice's rotation.** Arm **CX**, tap `q0` (control) then `q1` (target) in column 2. Arm
   **H**, tap `q0` in column 3. Panel now shows all eight rows, matching §18.2's amplitude
   table — this is the state every later step reads off.
3. **The corrections, deferred.** Arm **CX**, tap `q1` (control) then `q2` (target) in column 3
   (the X^b part — lands in the same column as the H above since they touch disjoint qubits).
   Then the Z^a part as CZ(0,2): arm **H**, tap `q2` in column 4; arm **CX**, tap `q0` then
   `q2` in column 5; arm **H**, tap `q2` in column 6. Panel: eight rows again, matching §18.4's
   final state.
4. **Check the factoring.** Tap **Display**, switch to **Steps**, and select qubit **q2**. The
   cards step through exactly the sequence in §18.6: |r| = 1 at column 0 (q2 still |0⟩), drops
   to |r| = 0 once the Bell pair forms (column 1) and stays there through Alice's `cx`
   (column 2), climbs back to a genuinely mixed |r| = 0.5 as each half of the correction lands
   (columns 3–4), jumps back to a *pure* |r| = 1 once the CZ's `cx` lands (column 5) — but at
   the wrong point, `x 0.5000  y −0.6124  z 0.6124` — and only settles on the correct ψ point,
   `x 0.6124  y 0.6124  z 0.5000`, once the closing `H` finishes the CZ (column 6).
5. **Measure it.** Back in the main view, set **Shots: 1000** and tap **Measure** — expect
   roughly 250 per ab prefix and a roughly 3-to-1 split within each, per §18.5 (a fresh tap will
   jitter).

**Superdense coding**, Clear, **Qubits: 2**, message "11" as the worked example: arm **H**, tap
`q0` column 0; arm **CX**, tap `q0` then `q1` column 1 (the Bell pair); arm **Z**, tap `q0`
column 2; arm **X**, tap `q0` column 3 (Alice's encoding); arm **CX**, tap `q0` then `q1`
column 4; arm **H**, tap `q0` column 5 (Bob's decode). Panel: a single row, `|11⟩` at
p = 1.0000 — the message decoded with certainty. The other three messages use the same six
columns with column 2 and/or 3 dropped or swapped for the identity/X/Z you need.

What's still missing: a real "measure now, branch the rest of the circuit on the result"
step — the app has no mid-circuit measurement, so both protocols above run every branch through
in superposition rather than actually collapsing partway. To see one branch in isolation
without deferring, use §18.3's projector code instead.

## Run it in code

Every snippet below was run with `RunCodeSnippet` against
`SwiftQiskitApp/SwiftQiskitApp/CircuitModel.swift`.

```swift
import SwiftQiskit

func fmt(_ value: Complex) -> String {
    let sign = value.imag < 0 ? "-" : "+"
    return String(format: "%.4f %@ %.4fi", value.real, sign, abs(value.imag))
}
func pretty(_ state: StateVector, qubits: Int) -> String {
    (0..<state.dimension)
        .filter { state[$0].magnitude > 1e-10 }
        .map { index -> String in
            var label = String(index, radix: 2)
            while label.count < qubits { label = "0" + label }
            return "|\(label)⟩: \(fmt(state[index]))"
        }
        .joined(separator: "   ")
}

let theta = Double.pi / 3
let phi = Double.pi / 4
let psiCircuit = QuantumCircuit(qubits: 1)
psiCircuit.ry(theta, 0); psiCircuit.rz(phi, 0)
let psi = psiCircuit.run()

let qc = QuantumCircuit(qubits: 3)
qc.ry(theta, 0); qc.rz(phi, 0)     // |ψ⟩ on q0
qc.h(1); qc.cx(1, 2)               // Bell pair on q1, q2
qc.cx(0, 1); qc.h(0)               // Alice's Bell-basis rotation
let bellBasisState = qc.run()
print(pretty(bellBasisState, qubits: 3))

let branchCorrections: [String: Matrix] = [
    "00": Matrix.identity(size: 2),
    "01": PauliXGate.matrix,
    "10": PauliZGate.matrix,
    "11": PauliZGate.matrix * PauliXGate.matrix   // apply X, then Z
]

print("\nab   P(ab)    fidelity")
for a in 0...1 {
    for b in 0...1 {
        let label = "\(a)\(b)"
        let projector = (Ket(label) * Bra(label)) ⊗ Matrix.identity(size: 2)
        var projected = bellBasisState
        projected.apply(projector)
        let base = a * 4 + b * 2
        var bobBranch = StateVector([projected[base], projected[base + 1]])
        let probAB = bellBasisState[base].magnitudeSquared + bellBasisState[base + 1].magnitudeSquared
        bobBranch.apply(branchCorrections[label]!)
        let fidelity = (bobBranch† * psi).magnitudeSquared
        print("\(label)   \(String(format: "%.4f", probAB))    \(String(format: "%.4f", fidelity))")
    }
}
```

```text
|000⟩: 0.4001 - 0.1657i   |001⟩: 0.2310 + 0.0957i   |010⟩: 0.2310 + 0.0957i   |011⟩: 0.4001 - 0.1657i
|100⟩: 0.4001 - 0.1657i   |101⟩: -0.2310 - 0.0957i  |110⟩: -0.2310 - 0.0957i  |111⟩: 0.4001 - 0.1657i

ab   P(ab)    fidelity
00   0.2500    1.0000
01   0.2500    1.0000
10   0.2500    1.0000
11   0.2500    1.0000
```

```swift
import SwiftQiskit

// Deferred corrections, the factoring check, marginals, and shots.
let theta = Double.pi / 3
let phi = Double.pi / 4
let psiCircuit = QuantumCircuit(qubits: 1)
psiCircuit.ry(theta, 0); psiCircuit.rz(phi, 0)
let psi = psiCircuit.run()

let qc = QuantumCircuit(qubits: 3)
qc.ry(theta, 0); qc.rz(phi, 0)
qc.h(1); qc.cx(1, 2)
qc.cx(0, 1); qc.h(0)
qc.cx(1, 2)                     // X^b
qc.h(2); qc.cx(0, 2); qc.h(2)   // Z^a, as CZ(0,2)
let finalState = qc.run()

let expectedFactored = (Ket.plus ⊗ Ket.plus) ⊗ psi
let maxDiff = (0..<8).map { (finalState[$0] - expectedFactored[$0]).magnitude }.max()!
print("matches |+⟩⊗|+⟩⊗|ψ⟩ to within \(String(format: "%.1e", maxDiff))")

func marginal(_ state: StateVector, bit: Int) -> [Double] {
    var p = [0.0, 0.0]
    for (i, prob) in state.probabilities.enumerated() { p[(i >> (2 - bit)) & 1] += prob }
    return p
}
print("q2 marginal:  \(marginal(finalState, bit: 2).map { String(format: "%.4f", $0) })")
print("q0 marginal:  \(marginal(finalState, bit: 0).map { String(format: "%.4f", $0) })")

let shots = qc.measure(shots: 1000)
print("\n1000 shots:")
for (state, count) in shots.sortedCounts { print("  \(state): \(count)") }
```

```text
matches |+⟩⊗|+⟩⊗|ψ⟩ to within 8.3e-17
q2 marginal:  [0.7500, 0.2500]
q0 marginal:  [0.5000, 0.5000]

1000 shots:
  000: 192
  001: 53
  010: 193
  011: 75
  100: 188
  101: 58
  110: 182
  111: 59
```

```swift
import SwiftQiskit

// Superdense coding: decode table and Bell-basis Gram matrix.
let sdMessages: [(String, (QuantumCircuit) -> Void)] = [
    ("00", { _ in }), ("01", { $0.x(0) }), ("10", { $0.z(0) }), ("11", { $0.z(0); $0.x(0) })
]

print("sent  decoded  P")
for (label, encode) in sdMessages {
    let sdc = QuantumCircuit(qubits: 2)
    sdc.h(0); sdc.cx(0, 1)
    encode(sdc)
    sdc.cx(0, 1); sdc.h(0)
    let probs = sdc.run().probabilities
    let decodedIndex = probs.firstIndex(where: { $0 > 0.999 })!
    var decodedLabel = String(decodedIndex, radix: 2)
    while decodedLabel.count < 2 { decodedLabel = "0" + decodedLabel }
    print(" \(label)     \(decodedLabel)    \(String(format: "%.4f", probs[decodedIndex]))")
}

let bellBasis = sdMessages.map { label, encode -> (String, StateVector) in
    let sdc = QuantumCircuit(qubits: 2)
    sdc.h(0); sdc.cx(0, 1); encode(sdc)
    return (label, sdc.run())
}
print("\nGram matrix:")
for (li, si) in bellBasis {
    let row = bellBasis.map { String(format: "%.2f", (si† * $0.1).magnitude) }.joined(separator: "  ")
    print("  \(li): \(row)")
}
```

```text
sent  decoded  P
 00     00    1.0000
 01     01    1.0000
 10     10    1.0000
 11     11    1.0000

Gram matrix:
  00: 1.00  0.00  0.00  0.00
  01: 0.00  1.00  0.00  0.00
  10: 0.00  0.00  1.00  0.00
  11: 0.00  0.00  0.00  1.00
```

## Try it yourself

1. Teleport |+i⟩ = (|0⟩ + i|1⟩)/√2 instead of this chapter's default payload, and confirm Bob's
   fidelity after correction.
   <details><summary>Answer</summary>Build |+i⟩ with `h(0); s(0)` — both palette tiles — in
   place of `ry; rz`. Running the full protocol gives fidelity 1.0000: the protocol is
   state-agnostic, exactly as `13TELEPORTATIONHELP.md` says.</details>

2. Teleport `h(0); t(0); h(0)`|0⟩ instead, which produces an *unequal* split unlike |+i⟩'s
   50/50. Predict P(0) before running it.
   <details><summary>Answer</summary>P(0) = cos²(π/8) ≈ 0.8536. Running it: `psi`'s
   probabilities come out `[0.8536, 0.1464]`, and the full protocol still reaches fidelity
   1.0000 — teleportation doesn't care that this payload is lopsided.</details>

3. Drop the Z^a correction (keep the X^b one) and predict what happens to q2's *reduced* Bloch
   vector — not by slicing two amplitudes (that only ever reads off the ab = 00 branch, which
   needs no Z correction regardless), but with `BlochVector(state, qubit: 2)`, the partial-trace
   vector Chapter 12 introduced.
   <details><summary>Answer</summary>q2's reduced Bloch vector becomes `(0.0000, 0.0000,
   0.5000)`, |r| = 0.5 — a genuinely mixed state from Bob's point of view. Z only matters on the
   branches where a = 1; averaging over a with the Z left un-applied on half of them washes out
   x and y (which Z flips the sign of) while leaving z (which Z doesn't touch) at its original
   0.5000. Bob's qubit is now entangled with Alice's unresolved bit a, not merely rotated.</details>

4. Apply Bob's corrections in the opposite order — Z^a first, then X^b — and check whether
   fidelity survives.
   <details><summary>Answer</summary>Still fidelity 1.0000, and the reduced Bloch vector lands
   on the same point, `(0.6124, 0.6124, 0.5000)`. §18.3 already found the branch-11 correction
   is ZX, not XZ; reversing the *global* application order revisits the same ZX vs. XZ
   difference, which is exactly the global phase −1 the Bloch point can't see.</details>

---
[← Chapter 17](17-Shor.md) · [Contents](../../INTRODUCTION.md) · [Chapter 19 →](19-ErrorCorrection.md)
