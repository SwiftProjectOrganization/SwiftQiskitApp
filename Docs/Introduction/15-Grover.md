# Chapter 15 — Grover's Search

> Amplitude amplification: a phase oracle marks one basis state with an invisible sign, and a
> second reflection — diffusion, "inversion about the mean" — turns that sign into probability.
> One iteration finds the marked item with certainty among 4; among 8, two iterations peak at
> ≈ 0.945 and a third overshoots, the quadratic speedup's probabilistic character laid bare.

| | |
|---|---|
| Playground page | [`11GroverExample`](../../../SwiftQiskit/PlaygroundDocs/11GROVERHELP.md) |
| In the app | ● — CZ (`h;cx;h`) and X-conjugated phase oracles are tappable, and so is the 3-qubit finale's CCZ: `t`/`tdg` plus `cx` reproduce it exactly (§15.9), no `apply(_:)` needed |
| Library APIs | `QuantumCircuit.h/x/cx/t/tdg`, `.apply(_:)` (§15.8's Dirac form only), `.probabilities`, `measure(shots:)`, `BlochVector(_:qubit:)` |
| Prerequisites | Chapters 8, 12, 13, 14 |

## 15.1 Search as an oracle-query problem

Among N = 2ⁿ items exactly one, `|w⟩`, is marked, and the only tool available is an oracle that
answers "is this the one?" — no other structure, no shortcuts. Classically that means trying
items one at a time: N/2 queries on average, N − 1 in the worst case. Grover's algorithm (Lov
Grover, 1996) finds `|w⟩` with high probability in about (π/4)·√N queries — a quadratic speedup
that applies to any problem phrased as "recognize the answer when you see it," not just database
search. Chapters 13 and 14 already built one-query oracles that mark a state with a sign instead
of writing it to an ancilla; Grover asks what happens when that trick is applied more than once
and steered by a second operator built specifically to read the sign back out.

| § | What happens |
|---|---|
| 15.2 | CZ from `h`/`cx`/`h` — the one two-qubit phase gate everything else is built from |
| 15.3 | Phase oracles via X-conjugation, and their equivalence to Chapter 13's bit oracles |
| 15.4 | Diffusion: inversion about the mean, stage by stage |
| 15.5 | The register entangles mid-circuit — unlike every oracle in Chapters 13–14 |
| 15.6 | Exact success at N = 4, and a shot count with no ancilla coin to slice off |
| 15.7 | Over-rotation: P(marked) = sin²((2k+1)θ), and why stopping at the right k matters |
| 15.8 | Diffusion as `2\|s⟩⟨s\| − I`, the Dirac outer-product form of the same operator |
| 15.9 | A 3-qubit finale: CCZ from `t`/`tdg`/`cx`, and Grover's genuinely probabilistic regime |
| 15.10 | The query-count gap, and the cost of not knowing k in advance |

## 15.2 CZ from H and CX

There is no native controlled-Z, but conjugating CNOT's target with Hadamards turns its X into a
Z (`HXH = Z`):

```text
CZ = (I ⊗ H) · CNOT · (I ⊗ H)   →   h(1); cx(0, 1); h(1)
```

Running it on the uniform superposition `|s⟩ = H⊗H|00⟩` confirms it touches exactly one term:

```text
CZ on |s⟩:  |00⟩: +0.5000   |01⟩: +0.5000   |10⟩: +0.5000   |11⟩: -0.5000
```

Only `|11⟩` flips sign — every other amplitude is untouched, exactly the definition of
controlled-Z. `cx(control, target)` works between any distinct pair of qubits, so this
construction builds a CZ between any two qubits of a larger register, not just qubits 0 and 1.

## 15.3 Phase oracles via X-conjugation

A phase oracle for an arbitrary marked state `|w⟩` is CZ conjugated by X gates: X on every qubit
whose bit in w is 0 maps `|w⟩ ↔ |11⟩`, CZ flips the sign there, and the same X's map back. Qubit 0
is the most-significant (leftmost) bit, as throughout Chapters 10–14, so the oracle for `|10⟩`
needs `x(1)` — qubit 1 is the 0 bit — not `x(0)`:

| Marked state | Gates | Sign pattern on `\|s⟩` (`\|00⟩ \|01⟩ \|10⟩ \|11⟩`) |
|---|---|---|
| `\|00⟩` | `x(0); x(1); cz; x(0); x(1)` | `−0.5  +0.5  +0.5  +0.5` |
| `\|01⟩` | `x(0); cz; x(0)` | `+0.5  −0.5  +0.5  +0.5` |
| `\|10⟩` | `x(1); cz; x(1)` | `+0.5  +0.5  −0.5  +0.5` |
| `\|11⟩` | `cz` | `+0.5  +0.5  +0.5  −0.5` |

Every probability stays flat at 0.25 for every oracle — the mark is entirely a phase, invisible
to measurement, exactly Chapter 8 §8.2's point applied to a two-qubit register instead of one.

This is the same trick Chapter 13 built, widened. Building the `|10⟩` oracle instead as a genuine
*bit* oracle `U_f: |x⟩|y⟩ → |x⟩|y ⊕ f(x)⟩` on a third qubit prepared in `|−⟩` — `f(x) = [x = 10]`,
via a hand-built permutation matrix since the palette has no native multi-controlled XOR —
and tracing the ancilla's fixed `|−⟩` split out of each branch recovers the identical sign per
input state:

```text
bit-oracle-on-|-> ancilla: |000⟩:+0.3536 |001⟩:-0.3536 |010⟩:+0.3536 |011⟩:-0.3536
                            |100⟩:-0.3536 |101⟩:+0.3536 |110⟩:+0.3536 |111⟩:-0.3536
direct phase oracle:        |00⟩:+0.5000  |01⟩:+0.5000  |10⟩:-0.5000  |11⟩:+0.5000
```

Grouping the bit-oracle's amplitudes by their leading two bits, each pair is `(+0.3536,
−0.3536)` or `(−0.3536, +0.3536)` — an overall `+` or `−` coefficient times the fixed `|−⟩` split
— and that overall sign, `+, +, −, +` for `00, 01, 10, 11`, matches the phase oracle's sign column
exactly. A phase oracle *is* a bit oracle acting on a `|−⟩` ancilla, with the ancilla's own qubit
elided because Chapter 13 §13.5 already showed it never entangles and never needs to be carried
around explicitly.

## 15.4 Diffusion: inversion about the mean

The diffusion operator D = 2`|s⟩⟨s|` − I reflects every amplitude aᵢ about their mean ā:
aᵢ → 2ā − aᵢ. It is the same X-conjugated CZ trick as the oracle, but sandwiched in Hadamards so
the reflection happens about `|s⟩` instead of about `|11⟩`:

```text
h(0); h(1); x(0); x(1); cz; x(0); x(1); h(0); h(1)
```

Stage by stage, for the oracle marking `|10⟩`:

```text
uniform |s⟩:      |00⟩: +0.5000   |01⟩: +0.5000   |10⟩: +0.5000   |11⟩: +0.5000
after oracle:      |00⟩: +0.5000   |01⟩: +0.5000   |10⟩: -0.5000   |11⟩: +0.5000
amplitude mean:    0.24999999999999992
after diffusion:   |10⟩: -1.0000
```

The mean of the post-oracle amplitudes is 0.25 — three terms at +0.5 and one at −0.5, averaged.
Diffusion sends each unmarked term to 2(0.25) − 0.5 = 0 and the marked term to 2(0.25) − (−0.5) =
1 (printed as −1; this gate construction equals −D, a global phase no measurement can see). Every
unmarked amplitude cancels exactly; the marked one lands at the pole. One iteration, and the state
is `|10⟩` outright.

## 15.5 The register entangles — unlike Chapters 13–14

Every oracle in Chapters 13 and 14 left its ancilla and query qubits unentangled throughout —
`|r| = 1` on every qubit at every stage (Chapter 13 §13.5, Chapter 14's Bernstein–Vazirani
readout). Grover's two-qubit register does not have that luxury: reduced Bloch cards through the
same `|10⟩` run —

```text
after H,H (uniform):  q0 x +1.000  |r| 1.000   q1 x +1.000  |r| 1.000
after oracle:          q0 x +0.000  |r| 0.000   q1 x +0.000  |r| 0.000
after diffusion H,H:   q0 x +0.000  |r| 0.000   q1 x +0.000  |r| 0.000
after diffusion X,X:   q0 x +0.000  |r| 0.000   q1 x +0.000  |r| 0.000
after diffusion CZ:    q0 x -1.000  |r| 1.000   q1 x +1.000  |r| 1.000
after diffusion X,X:   q0 x -1.000  |r| 1.000   q1 x +1.000  |r| 1.000
final (after H,H):     q0 x +0.000 z -1.000  |r| 1.000   q1 x +0.000 z +1.000  |r| 1.000
```

`|r|` drops to exactly 0 — full entanglement, the same reading Chapter 12 §12.4 found for the Bell
state — the instant the oracle's `cz` lands, and stays at 0 through diffusion's opening `h(0);
h(1)` and `x(0); x(1)`. That persistence is not a coincidence: single-qubit gates applied
independently to each qubit are *local* unitaries, and local unitaries can never change how
entangled two qubits are (they permute a qubit's own Bloch sphere but can't touch the other
qubit's share of the correlation). Only a genuinely two-qubit gate can move `|r|`, and diffusion
has exactly one — its own `cz` — which is precisely where the trajectory jumps back to `|r| = 1`,
landing q0 and q1 on a clean product state again, one that final `H`s convert straight to the
marked bit string. Grover spends its one two-qubit interaction per iteration passing through
entanglement on the way to an answer, not avoiding it the way Deutsch and Deutsch–Jozsa do.

## 15.6 Exact success at N = 4

Running one iteration for all four possible marked states:

```text
marked   P(marked)  found
|00⟩     1.0000     found
|01⟩     1.0000     found
|10⟩     1.0000     found
|11⟩     1.0000     found
```

Every one is found with certainty from a single oracle query, where a classical search of 4 items
costs 2.25 queries on average. Sampling confirms it — with P(marked) = 1, every shot agrees:

```text
marked |10⟩, 1000 shots:
  10: 1000
```

This is the sharpest contrast yet with Chapters 13 and 14: their ancilla always ended in `|−⟩`, a
fair coin sliced off the readout no matter how certain the verdict. Grover has no ancilla to
discard — the whole register *is* the answer, and here it is exactly, not approximately, right.

## 15.7 Over-rotation

Each iteration rotates the state by 2θ toward `|w⟩`, where sin θ = 1/√N. After k iterations,
P(marked) = sin²((2k+1)θ). For N = 4, θ = π/6, and running k = 0…4 against that closed form:

```text
k   P(simulated)  P(formula sin²((2k+1)θ))
0    0.2500          0.2500
1    1.0000          1.0000
2    0.2500          0.2500
3    0.2500          0.2500
4    1.0000          1.0000
```

The simulated and formula columns agree to four decimal places at every k. P(marked) does not
climb monotonically with more queries — it oscillates with period 3 in k here, and a second
iteration rotates straight *past* the target back down to 0.25. More queries is not automatically
better; Grover only pays off if you stop at (or near) the right k.

## 15.8 The Dirac view: D = 2|s⟩⟨s| − I

Chapter 8's outer product builds diffusion directly from `|s⟩⟨s|`, the projector onto the uniform
superposition:

```swift
let projector = s * s†                      // |s⟩⟨s|
var d = Matrix(rows: 4, cols: 4)
for i in 0..<4 {
    for j in 0..<4 {
        d[i, j] = Complex(2) * projector[i, j] - (i == j ? Complex(1) : Complex.zero)
    }
}
```

Applied via `apply(_:)` after the same `|10⟩` oracle:

```text
via 2|s⟩⟨s| − I:    |10⟩: +1.0000
via gate diffusion:  |10⟩: -1.0000
```

Both land on `|10⟩` with certainty — the sign disagreement is the same global phase §15.4 already
flagged (the gate construction equals −D), invisible to every probability and every measurement.

## 15.9 A 3-qubit finale: CCZ from T, T†, and CX

N = 4 is a special case where one iteration is exact. Beyond it, the oracle and diffusion both
need a *doubly*-controlled Z, and H/X/Z/CX alone cannot build one. The playground page reaches
for `apply(_:)` with a hand-built matrix — but the palette also has `t` and `tdg`, and the
standard T-gate decomposition of CCZ needs nothing else:

```text
cx(1,2); tdg(2); cx(0,2); t(2); cx(1,2); tdg(2); cx(0,2);
t(1); t(2); cx(0,1); t(0); tdg(1); cx(0,1)
```

Checked against the hand-built matrix (identity with the `|111⟩` entry negated) on all 8 basis
states:

```text
basis  gates-CCZ  matrix-CCZ  match
 0     +1.0       +1.0       true
 1     +1.0       +1.0       true
 2     +1.0       +1.0       true
 3     +1.0       +1.0       true
 4     +1.0       +1.0       true
 5     +1.0       +1.0       true
 6     +1.0       +1.0       true
 7     -1.0       -1.0       true
```

Every entry matches — this sequence *is* a CCZ, tappable one gate at a time. With `h(_:)` and
`x(_:)` already embedding into any register size, the same oracle/diffusion pattern scales to 3
qubits with no `apply(_:)` anywhere. Now sin θ = 1/√8 and the optimal iteration count,
round(π/(4θ) − ½), is 2 — success is high but no longer certain:

```text
k (iterations)  P(marked |101⟩)
  1              0.7812
  2              0.9453
  3              0.3301
  4              0.0122
```

P rises to a peak at k = 2 and then rotates past the target, exactly as the 2-qubit case did but
without ever touching 1.0000 — Grover's genuinely probabilistic regime. Sampling at the optimal
k = 2:

```text
1000 shots at k = 2:
  000: 7
  001: 8
  010: 7
  011: 6
  100: 11
  101: 947
  110: 6
  111: 8
```

`101` dominates at ≈ 95%, matching P ≈ 0.9453, with the remaining ~5% spread thinly over the other
seven outcomes. This is the generic Grover pattern for N > 4: run ~(π/4)√N queries, measure, and
*check* the answer classically (one evaluation of f) — repeating the whole search in the unlucky
minority of runs where the sample lands on an unmarked state.

## 15.10 The query-count gap

Quantum queries scale as (π/4)√N; classical scales linearly:

```text
n   N     optimal k   quantum queries ≈ k·√N   classical avg (N/2)   classical worst (N−1)
2   4     1           2.0                       2                     3
3   8     2           5.7                       4                     7
4   16    3           12.0                      8                     15
5   32    4           22.6                      16                    31
6   64    6           48.0                      32                    63
7   128   8           90.5                      64                    127
8   256   12          192.0                     128                   255
```

The gap is quadratic, not exponential — a much narrower advantage than Deutsch–Jozsa's, and one
worth stating precisely: Grover's √N is provably *optimal* for unstructured search (Bennett,
Bernstein, Brassard, Vazirani, 1997) — no quantum algorithm can do better with only oracle access,
unlike Deutsch–Jozsa and Bernstein–Vazirani's one-query answers, which exploit a promise about the
oracle's structure that a generic search problem doesn't offer. One further cost this table hides:
picking k at all requires knowing (or estimating) how many items are marked, since θ depends on
that count; guessing wrong over- or under-rotates exactly as §15.7 showed for a single marked item.

## Build it in the app

● Every step starts from **Clear**. Qubit 0 is the leftmost bit of every label, as throughout
Chapters 10–15.

1. **Qubits: 2. Uniform superposition** — Arm **H**, tap `q0` then `q1` in column 0. Panel: four
   rows at flat `p=0.250`.
2. **Oracle for `|10⟩`** — Arm **X** (Pauli section), tap `q1` in column 1. Arm **H**, tap `q1` in
   column 2. Arm **CX** (Multi-qubit section), tap `q0` then `q1` in column 3. Arm **H**, tap `q1`
   in column 4. Arm **X**, tap `q1` in column 5 (this six-gate sequence is `x(1); h(1); cx(0,1);
   h(1); x(1)` — CZ conjugated by X, exactly §15.3). Panel: still four rows at `p=0.250`, but
   `|10⟩`'s sign has flipped relative to step 1.
3. **Diffusion** — Arm **H**, tap `q0` and `q1` in column 6. Arm **X**, tap `q0` and `q1` in
   column 7. Arm **H**, tap `q1` in column 8. Arm **CX**, tap `q0` then `q1` in column 9. Arm
   **H**, tap `q1` in column 10. Arm **X**, tap `q0` and `q1` in column 11. Arm **H**, tap `q0`
   and `q1` in column 12. Panel collapses to one row: `|10⟩: p=1.000`. Set **Shots: 1000**, tap
   **Measure**: every shot reads `10`.
4. **Watch the entanglement on the sphere** — Tap **Display**, pick **Steps**, qubit picker on
   `q0`: `|r|` visibly shrinks to 0 right after column 5 (the oracle) and stays shrunk through
   columns 6–11, then springs back to 1 at column 12 landing on the south pole — the mid-circuit
   entanglement §15.5 describes, made visible without reading any numbers.
5. **Swap the marked state** — Delete the column 1 and column 5 `X` tiles via their context menu
   (for `|11⟩`, delete none; for `|01⟩`, keep only `q0`'s `X`; for `|00⟩`, add `X` on both `q0` and
   `q1` at columns 1 and 5). Measure again: the outcome always matches the newly marked state.
6. **Over-rotate** — From step 3's circuit, append a second oracle-and-diffusion block (columns
   13–24, repeating steps 2–3's gate sequence). Panel: four rows at flat `p=0.250` again — P has
   rotated past the target, matching §15.7's k = 2 row.
7. **Qubits: 3, marked `|111⟩`, CCZ from T/T†/CX** — Clear, set **Qubits: 3**. Arm **H**, tap `q0`,
   `q1`, `q2` in column 0 (no oracle `X`'s needed — `|111⟩` is already `|11⟩` in CZ's own basis).
   Build the CCZ oracle across columns 1–11: **CX** `q1`→`q2` (col 1), **T†** `q2` (col 2), **CX**
   `q0`→`q2` (col 3), **T** `q2` (col 4), **CX** `q1`→`q2` (col 5), **T†** `q2` (col 6), **CX**
   `q0`→`q2` (col 7), **T** `q1` *and* **T** `q2` together in column 8 (different qubits, same
   column), **CX** `q0`→`q1` (col 9), **T** `q0` *and* **T†** `q1` together in column 10, **CX**
   `q0`→`q1` (col 11). Then diffusion: **H** all three in column 12, **X** all three in column 13,
   the same 11-column CCZ sequence again in columns 14–24, **X** all three in column 25, **H** all
   three in column 26 — 27 columns total for one iteration. Measure: `111` dominates at
   P ≈ 0.7812, matching §15.9's k = 1 row exactly.

Two limits worth stating plainly, as earlier chapters did: the 3-qubit CCZ costs 13 gate-taps per
use (11 columns, since two T/T† pairs each share a column) and appears twice per iteration, so
building even k = 2 by hand runs past 50 columns — tedious but not impossible, and nothing here
needs the `apply(_:)` escape hatch the playground page reaches for. And as always, the app cannot
hide the oracle from the person building it — the "one query" claim describes the circuit's
structure (one oracle tile-sequence per iteration), not any enforced ignorance of what is inside
it.

## Run it in code

Every snippet below was run with `RunCodeSnippet` against
`SwiftQiskitApp/SwiftQiskitApp/CircuitModel.swift`.

```swift
import SwiftQiskit

func cz(_ qc: QuantumCircuit) { qc.h(1); qc.cx(0, 1); qc.h(1) }

func pretty(_ state: StateVector, qubits: Int) -> String {
    (0..<state.dimension)
        .filter { state[$0].magnitude > 1e-10 }
        .map { index -> String in
            var label = String(index, radix: 2)
            while label.count < qubits { label = "0" + label }
            return "|\(label)⟩: \(String(format: "%+.4f", state[index].real))"
        }
        .joined(separator: "   ")
}

// 15.2 -- CZ on |s>
let czCheck = QuantumCircuit(qubits: 2)
czCheck.h(0); czCheck.h(1)
cz(czCheck)
print("CZ on |s>: ", pretty(czCheck.run(), qubits: 2))

// 15.3 -- the four phase oracles
struct GroverOracle {
    let name: String
    let markedIndex: Int
    let apply: (QuantumCircuit) -> Void
}

func phaseOracle(marked: Int) -> (QuantumCircuit) -> Void {
    { qc in
        let zeroBits = (0..<2).filter { (marked >> (1 - $0)) & 1 == 0 }
        for q in zeroBits { qc.x(q) }
        cz(qc)
        for q in zeroBits { qc.x(q) }
    }
}

let oracles: [GroverOracle] = (0..<4).map { m in
    var label = String(m, radix: 2)
    while label.count < 2 { label = "0" + label }
    return GroverOracle(name: "|\(label)>", markedIndex: m, apply: phaseOracle(marked: m))
}

print("\noracle on |s>:")
for oracle in oracles {
    let qc = QuantumCircuit(qubits: 2)
    qc.h(0); qc.h(1)
    oracle.apply(qc)
    print(" U_\(oracle.name):", pretty(qc.run(), qubits: 2))
}

// 15.4 -- stage walk for marked |10>, amplitude mean
func diffusion(_ qc: QuantumCircuit) {
    qc.h(0); qc.h(1); qc.x(0); qc.x(1); cz(qc); qc.x(0); qc.x(1); qc.h(0); qc.h(1)
}

let walk = QuantumCircuit(qubits: 2)
walk.h(0); walk.h(1)
print("\nuniform |s>:     ", pretty(walk.run(), qubits: 2))
walk.x(1); cz(walk); walk.x(1)
let afterOracle = walk.run()
print("after oracle:    ", pretty(afterOracle, qubits: 2))
var sum = Complex.zero
for i in 0..<afterOracle.dimension { sum = sum + afterOracle[i] }
let mean = sum * Complex(0.25)
print("amplitude mean:  ", mean)
diffusion(walk)
print("after diffusion: ", pretty(walk.run(), qubits: 2))

// 15.6 -- one iteration, all four oracles
func groverCircuit(oracle: (QuantumCircuit) -> Void, iterations: Int) -> QuantumCircuit {
    let qc = QuantumCircuit(qubits: 2)
    qc.h(0); qc.h(1)
    for _ in 0..<iterations { oracle(qc); diffusion(qc) }
    return qc
}

print("\nmarked   P(marked)  found")
for oracle in oracles {
    let qc = groverCircuit(oracle: oracle.apply, iterations: 1)
    let p = qc.run().probabilities[oracle.markedIndex]
    print(" \(oracle.name)    ", String(format: "%.4f", p), p > 0.999 ? "  found" : "  missed")
}

// 15.7 -- over-rotation vs formula, N = 4
let theta = asin(1.0 / 2.0)
print("\nk   P(simulated)  P(formula sin^2((2k+1)theta))")
for k in 0...4 {
    let qc = groverCircuit(oracle: oracles[2].apply, iterations: k)
    let pSim = qc.run().probabilities[2]
    let pFormula = pow(sin(Double(2 * k + 1) * theta), 2)
    print(" \(k)   ", String(format: "%.4f", pSim), "        ", String(format: "%.4f", pFormula))
}
```

```text
CZ on |s>:  |00⟩: +0.5000   |01⟩: +0.5000   |10⟩: +0.5000   |11⟩: -0.5000

oracle on |s>:
 U_|00>: |00⟩: -0.5000   |01⟩: +0.5000   |10⟩: +0.5000   |11⟩: +0.5000
 U_|01>: |00⟩: +0.5000   |01⟩: -0.5000   |10⟩: +0.5000   |11⟩: +0.5000
 U_|10>: |00⟩: +0.5000   |01⟩: +0.5000   |10⟩: -0.5000   |11⟩: +0.5000
 U_|11>: |00⟩: +0.5000   |01⟩: +0.5000   |10⟩: +0.5000   |11⟩: -0.5000

uniform |s>:      |00⟩: +0.5000   |01⟩: +0.5000   |10⟩: +0.5000   |11⟩: +0.5000
after oracle:     |00⟩: +0.5000   |01⟩: +0.5000   |10⟩: -0.5000   |11⟩: +0.5000
amplitude mean:   0.24999999999999992
after diffusion:  |10⟩: -1.0000

marked   P(marked)  found
 |00>     1.0000   found
 |01>     1.0000   found
 |10>     1.0000   found
 |11>     1.0000   found

k   P(simulated)  P(formula sin^2((2k+1)theta))
 0    0.2500          0.2500
 1    1.0000          1.0000
 2    0.2500          0.2500
 3    0.2500          0.2500
 4    1.0000          1.0000
```

```swift
import SwiftQiskit

func cz(_ qc: QuantumCircuit) { qc.h(1); qc.cx(0, 1); qc.h(1) }
func card(_ b: BlochVector) -> String {
    String(format: "x %+.3f  y %+.3f  z %+.3f  |r| %.3f", b.x, b.y, b.z, b.magnitude)
}
func pretty(_ state: StateVector, qubits: Int) -> String {
    (0..<state.dimension)
        .filter { state[$0].magnitude > 1e-10 }
        .map { index -> String in
            var label = String(index, radix: 2)
            while label.count < qubits { label = "0" + label }
            return "|\(label)⟩: \(String(format: "%+.4f", state[index].real))"
        }
        .joined(separator: "   ")
}

// 15.3 -- a genuine bit oracle f(x) = [x = 10] on a |-> ancilla (q2),
// compared against the direct phase oracle for |10>
var m = Matrix.identity(size: 8)
for basis in 0..<8 {
    let q0 = (basis >> 2) & 1, q1 = (basis >> 1) & 1
    if q0 == 1 && q1 == 0 {
        let flipped = basis ^ 1
        m[basis, basis] = Complex.zero
        m[flipped, basis] = Complex(1)
    }
}
let ancillaQC = QuantumCircuit(qubits: 3)
ancillaQC.x(2)
ancillaQC.h(0); ancillaQC.h(1); ancillaQC.h(2)
ancillaQC.apply(m)
print("bit-oracle-on-|-> ancilla:", pretty(ancillaQC.run(), qubits: 3))

let phaseQC = QuantumCircuit(qubits: 2)
phaseQC.h(0); phaseQC.h(1)
phaseQC.x(1); cz(phaseQC); phaseQC.x(1)
print("direct phase oracle for |10>:", pretty(phaseQC.run(), qubits: 2))

// 15.5 -- Bloch cards through every stage (entanglement mid-circuit)
func diffusion(_ qc: QuantumCircuit) {
    qc.h(0); qc.h(1); qc.x(0); qc.x(1); cz(qc); qc.x(0); qc.x(1); qc.h(0); qc.h(1)
}
let walk = QuantumCircuit(qubits: 2)
walk.h(0); walk.h(1)
print("\nafter H,H:  q0", card(BlochVector(walk.run(), qubit: 0)), " q1", card(BlochVector(walk.run(), qubit: 1)))
walk.x(1); cz(walk); walk.x(1)
print("after oracle: q0", card(BlochVector(walk.run(), qubit: 0)), " q1", card(BlochVector(walk.run(), qubit: 1)))
walk.h(0); walk.h(1)
print("after diff H,H: q0", card(BlochVector(walk.run(), qubit: 0)), " q1", card(BlochVector(walk.run(), qubit: 1)))
walk.x(0); walk.x(1)
print("after diff X,X: q0", card(BlochVector(walk.run(), qubit: 0)), " q1", card(BlochVector(walk.run(), qubit: 1)))
walk.h(1); walk.cx(0, 1); walk.h(1)
print("after diff CZ:  q0", card(BlochVector(walk.run(), qubit: 0)), " q1", card(BlochVector(walk.run(), qubit: 1)))
walk.x(0); walk.x(1)
print("after diff X,X: q0", card(BlochVector(walk.run(), qubit: 0)), " q1", card(BlochVector(walk.run(), qubit: 1)))
walk.h(0); walk.h(1)
print("final:          q0", card(BlochVector(walk.run(), qubit: 0)), " q1", card(BlochVector(walk.run(), qubit: 1)))
```

```text
bit-oracle-on-|-> ancilla: |000⟩: +0.3536   |001⟩: -0.3536   |010⟩: +0.3536   |011⟩: -0.3536   |100⟩: -0.3536   |101⟩: +0.3536   |110⟩: +0.3536   |111⟩: -0.3536
direct phase oracle for |10>: |00⟩: +0.5000   |01⟩: +0.5000   |10⟩: -0.5000   |11⟩: +0.5000

after H,H:  q0 x +1.000  y +0.000  z +0.000  |r| 1.000  q1 x +1.000  y +0.000  z +0.000  |r| 1.000
after oracle: q0 x +0.000  y +0.000  z +0.000  |r| 0.000  q1 x +0.000  y +0.000  z +0.000  |r| 0.000
after diff H,H: q0 x +0.000  y +0.000  z +0.000  |r| 0.000  q1 x +0.000  y +0.000  z +0.000  |r| 0.000
after diff X,X: q0 x +0.000  y +0.000  z +0.000  |r| 0.000  q1 x +0.000  y +0.000  z +0.000  |r| 0.000
after diff CZ:  q0 x -1.000  y +0.000  z +0.000  |r| 1.000  q1 x +1.000  y +0.000  z +0.000  |r| 1.000
after diff X,X: q0 x -1.000  y +0.000  z +0.000  |r| 1.000  q1 x +1.000  y +0.000  z +0.000  |r| 1.000
final:          q0 x +0.000  y +0.000  z -1.000  |r| 1.000  q1 x +0.000  y +0.000  z +1.000  |r| 1.000
```

```swift
import SwiftQiskit

func cz(_ qc: QuantumCircuit) { qc.h(1); qc.cx(0, 1); qc.h(1) }
func diffusion(_ qc: QuantumCircuit) {
    qc.h(0); qc.h(1); qc.x(0); qc.x(1); cz(qc); qc.x(0); qc.x(1); qc.h(0); qc.h(1)
}
func pretty(_ state: StateVector, qubits: Int) -> String {
    (0..<state.dimension)
        .filter { state[$0].magnitude > 1e-10 }
        .map { index -> String in
            var label = String(index, radix: 2)
            while label.count < qubits { label = "0" + label }
            return "|\(label)⟩: \(String(format: "%+.4f", state[index].real))"
        }
        .joined(separator: "   ")
}

// 15.6 -- 1000 shots, marked |10>
let marked10 = QuantumCircuit(qubits: 2)
marked10.h(0); marked10.h(1)
marked10.x(1); cz(marked10); marked10.x(1)
diffusion(marked10)
let shots = marked10.measure(shots: 1000)
print("marked |10>, 1000 shots:")
for (state, count) in shots.sortedCounts { print("  \(state): \(count)") }

// 15.8 -- Dirac D = 2|s><s| - I
let sPrep = QuantumCircuit(qubits: 2)
sPrep.h(0); sPrep.h(1)
let s = sPrep.run()
let projector = s * s†
var d = Matrix(rows: 4, cols: 4)
for i in 0..<4 {
    for j in 0..<4 {
        d[i, j] = Complex(2) * projector[i, j] - (i == j ? Complex(1) : Complex.zero)
    }
}
let viaDirac = QuantumCircuit(qubits: 2)
viaDirac.h(0); viaDirac.h(1)
viaDirac.x(1); cz(viaDirac); viaDirac.x(1)
viaDirac.apply(d)
print("\nvia 2|s><s| - I:", pretty(viaDirac.run(), qubits: 2))

let viaGates = QuantumCircuit(qubits: 2)
viaGates.h(0); viaGates.h(1)
viaGates.x(1); cz(viaGates); viaGates.x(1)
diffusion(viaGates)
print("via gate diffusion:", pretty(viaGates.run(), qubits: 2))
```

```text
marked |10>, 1000 shots:
  10: 1000

via 2|s><s| - I: |10⟩: +1.0000
via gate diffusion: |10⟩: -1.0000
```

```swift
import SwiftQiskit

func cczGates(_ qc: QuantumCircuit, _ a: Int, _ b: Int, _ c: Int) {
    qc.cx(b, c); qc.tdg(c); qc.cx(a, c); qc.t(c); qc.cx(b, c); qc.tdg(c); qc.cx(a, c)
    qc.t(b); qc.t(c); qc.cx(a, b); qc.t(a); qc.tdg(b); qc.cx(a, b)
}

// 15.9 -- check the T/Tdg/CX decomposition against the hand-built CCZ matrix
var ccz = Matrix.identity(size: 8)
ccz[7, 7] = Complex(-1)

print("basis  gates-CCZ  matrix-CCZ  match")
for basis in 0..<8 {
    let gateQC = QuantumCircuit(qubits: 3)
    for q in 0..<3 where (basis >> (2 - q)) & 1 == 1 { gateQC.x(q) }
    cczGates(gateQC, 0, 1, 2)
    let gateResult = gateQC.run()[basis].real

    let matrixQC = QuantumCircuit(qubits: 3)
    for q in 0..<3 where (basis >> (2 - q)) & 1 == 1 { matrixQC.x(q) }
    matrixQC.apply(ccz)
    let matrixResult = matrixQC.run()[basis].real
    print(" \(basis)     \(String(format: "%+.1f", gateResult))       \(String(format: "%+.1f", matrixResult))       \(abs(gateResult - matrixResult) < 1e-9)")
}

func oracle3(_ qc: QuantumCircuit, marked: Int) {
    let zeroBits = (0..<3).filter { (marked >> (2 - $0)) & 1 == 0 }
    for q in zeroBits { qc.x(q) }
    cczGates(qc, 0, 1, 2)
    for q in zeroBits { qc.x(q) }
}
func diffusion3(_ qc: QuantumCircuit) {
    for q in 0..<3 { qc.h(q) }
    for q in 0..<3 { qc.x(q) }
    cczGates(qc, 0, 1, 2)
    for q in 0..<3 { qc.x(q) }
    for q in 0..<3 { qc.h(q) }
}
func grover3(marked: Int, iterations: Int) -> QuantumCircuit {
    let qc = QuantumCircuit(qubits: 3)
    for q in 0..<3 { qc.h(q) }
    for _ in 0..<iterations { oracle3(qc, marked: marked); diffusion3(qc) }
    return qc
}

print("\nk (iterations)  P(marked |101>)")
for k in 1...4 {
    let p = grover3(marked: 5, iterations: k).run().probabilities[5]
    print("  \(k)              \(String(format: "%.4f", p))")
}

let counts3 = grover3(marked: 5, iterations: 2).measure(shots: 1000)
print("\n1000 shots at k = 2:")
for (state, count) in counts3.sortedCounts { print("  \(state): \(count)") }
```

```text
basis  gates-CCZ  matrix-CCZ  match
 0     +1.0       +1.0       true
 1     +1.0       +1.0       true
 2     +1.0       +1.0       true
 3     +1.0       +1.0       true
 4     +1.0       +1.0       true
 5     +1.0       +1.0       true
 6     +1.0       +1.0       true
 7     -1.0       -1.0       true

k (iterations)  P(marked |101>)
  1              0.7812
  2              0.9453
  3              0.3301
  4              0.0122

1000 shots at k = 2:
  000: 7
  001: 8
  010: 7
  011: 6
  100: 11
  101: 947
  110: 6
  111: 8
```

```swift
import Foundation

// 15.10 -- classical vs quantum query counts, n = 2...8 (arithmetic, not a simulation,
// same as Chapter 14 §14.8's table)
print("n   N     optimal k   quantum queries ≈ k·√N   classical avg (N/2)   classical worst (N-1)")
for n in 2...8 {
    let N = 1 << n
    let theta = asin(1.0 / Double(N).squareRoot())
    let k = Int((Double.pi / (4 * theta) - 0.5).rounded())
    print("\(n)   \(N)   \(k)           \(String(format: "%.1f", Double(k) * Double(N).squareRoot()))                      \(N / 2)                  \(N - 1)")
}
```

```text
n   N     optimal k   quantum queries ≈ k·√N   classical avg (N/2)   classical worst (N-1)
2   4   1           2.0                      2                  3
3   8   2           5.7                      4                  7
4   16   3           12.0                      8                  15
5   32   4           22.6                      16                  31
6   64   6           48.0                      32                  63
7   128   8           90.5                      64                  127
8   256   12           192.0                      128                  255
```

Finally, the app-path walkthrough behind "Build it in the app," driving `CircuitBuilder` directly
and formatting output exactly as `ResultsView`'s panel and `BlochSphereView`'s card do (helpers
first defined in Chapters 7–8, reused unchanged from Chapters 13–14):

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
    String(format: "x %+.3f  y %+.3f  z %+.3f  |r| %.3f", bloch.x, bloch.y, bloch.z, bloch.magnitude)
}

@MainActor
func placeCCZ(_ builder: CircuitBuilder, startColumn: Int) -> Int {
    var col = startColumn
    builder.place(.cx, qubits: [1, 2], column: col); col += 1
    builder.place(.tdg, qubits: [2], column: col); col += 1
    builder.place(.cx, qubits: [0, 2], column: col); col += 1
    builder.place(.t, qubits: [2], column: col); col += 1
    builder.place(.cx, qubits: [1, 2], column: col); col += 1
    builder.place(.tdg, qubits: [2], column: col); col += 1
    builder.place(.cx, qubits: [0, 2], column: col); col += 1
    builder.place(.t, qubits: [1], column: col); builder.place(.t, qubits: [2], column: col); col += 1
    builder.place(.cx, qubits: [0, 1], column: col); col += 1
    builder.place(.t, qubits: [0], column: col); builder.place(.tdg, qubits: [1], column: col); col += 1
    builder.place(.cx, qubits: [0, 1], column: col); col += 1
    return col
}

// step 1-4: 2-qubit walkthrough, marked |10>, one iteration
var b = CircuitBuilder(qubitCount: 2)
b.place(.h, qubits: [0], column: 0); b.place(.h, qubits: [1], column: 0)
b.place(.x, qubits: [1], column: 1)
b.place(.h, qubits: [1], column: 2)
b.place(.cx, qubits: [0, 1], column: 3)
b.place(.h, qubits: [1], column: 4)
b.place(.x, qubits: [1], column: 5)
b.place(.h, qubits: [0], column: 6); b.place(.h, qubits: [1], column: 6)
b.place(.x, qubits: [0], column: 7); b.place(.x, qubits: [1], column: 7)
b.place(.h, qubits: [1], column: 8)
b.place(.cx, qubits: [0, 1], column: 9)
b.place(.h, qubits: [1], column: 10)
b.place(.x, qubits: [0], column: 11); b.place(.x, qubits: [1], column: 11)
b.place(.h, qubits: [0], column: 12); b.place(.h, qubits: [1], column: 12)

print("column count:", b.columnCount())
print("panel after oracle (col 5):", panelRows(b.buildCircuit(throughColumn: 5).run(), qubits: 2))
print("final panel:", panelRows(b.buildCircuit().run(), qubits: 2))

// step 7: 3-qubit walkthrough, marked |111>, one iteration, CCZ via T/Tdg/CX
let c = CircuitBuilder(qubitCount: 3)
c.place(.h, qubits: [0], column: 0); c.place(.h, qubits: [1], column: 0); c.place(.h, qubits: [2], column: 0)
var col = placeCCZ(c, startColumn: 1)
c.place(.h, qubits: [0], column: col); c.place(.h, qubits: [1], column: col); c.place(.h, qubits: [2], column: col); col += 1
c.place(.x, qubits: [0], column: col); c.place(.x, qubits: [1], column: col); c.place(.x, qubits: [2], column: col); col += 1
col = placeCCZ(c, startColumn: col)
c.place(.x, qubits: [0], column: col); c.place(.x, qubits: [1], column: col); c.place(.x, qubits: [2], column: col); col += 1
c.place(.h, qubits: [0], column: col); c.place(.h, qubits: [1], column: col); c.place(.h, qubits: [2], column: col)

print("\ntotal columns:", c.columnCount())
let result3 = c.buildCircuit().run()
print("P(|111>) =", String(format: "%.4f", result3.probabilities[7]))
```

```text
column count: 13
panel after oracle (col 5): ["|00⟩: 0.49999999999999983  (p=0.250)", "|01⟩: 0.49999999999999983  (p=0.250)", "|10⟩: -0.49999999999999983  (p=0.250)", "|11⟩: 0.49999999999999983  (p=0.250)"]
final panel: ["|10⟩: -0.9999999999999992  (p=1.000)"]

total columns: 27
P(|111>) = 0.7812
```

The 27-column count confirms the shared-column T/T† pairs: the CCZ's 13 gates fit 11 columns
(§15.9), so one full iteration — oracle CCZ, H-all, X-all, diffusion CCZ, X-all, H-all — is
1 + 11 + 1 + 1 + 11 + 1 + 1 = 27 columns, matching the count printed above.

Re-running either shot-count block above will land close to, but not exactly on, the printed
splits — the app-visible statistics are genuinely probabilistic (Chapter 9), same as Chapters 13
and 14.

## Try it yourself

1. Run the 2-qubit search for 2 iterations instead of 1 and confirm the success probability
   drops.
   <details><summary>Answer</summary>N = 4 needs exactly 1 iteration (a π/3 rotation per
   iteration, since 2θ = π/3 here): P(marked) = sin²(3θ) = sin²(π/2) = 1. A second iteration
   rotates the state by another 2θ past the target, giving sin²(5θ) = sin²(5π/6) = 0.25 —
   matching §15.7's k = 2 row exactly, the same over-rotation the app-build's step 6
   demonstrates.</details>

2. Why does the oracle for `|10⟩` use `x(1)` rather than `x(0)`, and what state would `x(0); cz;
   x(0)` mark instead?
   <details><summary>Answer</summary>Qubit 0 is the leftmost (most-significant) bit, so `|10⟩`
   has a 1 in qubit 0's position and a 0 in qubit 1's — the X-conjugation trick puts `X` only on
   the qubits whose bit in the target state is 0, to map that state onto `|11⟩` where CZ acts.
   `|10⟩` needs `x(1)`. `x(0); cz; x(0)` instead zeroes qubit 0's bit in the mapping and leaves
   qubit 1's bit 1, which maps `|01⟩` onto `|11⟩` — so it marks `|01⟩`, exactly the row §15.3's
   table gives for that state.</details>

3. §15.10 gives the optimal iteration count for N = 8 as k = 2. What is it for N = 16, and does
   running the 3-qubit-style circuit at that k confirm it?
   <details><summary>Answer</summary>round(π/(4θ) − ½) with θ = arcsin(1/4) gives k = 3 for
   N = 16 (§15.10's table). A 4-qubit Grover circuit — the same oracle/diffusion pattern, scaled
   up, with an 8×8-controlled Z this time — run at k = 3 would need to be checked the same way
   §15.9 checked the 3-qubit case: build it, run `probabilities` at the marked index, and confirm
   the peak lands near k = 3 rather than k = 2 or k = 4, exactly as `k (iterations) P(marked)`
   climbed to a single peak at k = 2 for N = 8.</details>

4. §15.5 found Grover's register drops to `|r| = 0` — full entanglement — right after the oracle,
   while Chapter 13's Deutsch circuit never entangled at all. Both use a `cx`-based construction.
   What is different?
   <details><summary>Answer</summary>Deutsch's `cx` acts on a query qubit in `|+⟩` and an ancilla
   pinned at `|−⟩`, an eigenstate of X with eigenvalue −1 (Chapter 13 §13.3) — flipping an
   eigenstate to itself times a sign is a phase kickback, not entanglement, so the ancilla's own
   state never moves. Grover's oracle-and-diffusion `cz` acts on two qubits that are each in `|+⟩`
   or `|−⟩` but *not* playing the fixed-eigenstate-ancilla role — CZ genuinely correlates them, the
   same way Chapter 12's Bell-state `cx` did on two `|+⟩`/`|0⟩` qubits. The mechanism (`cx`
   underneath a Hadamard sandwich) looks similar; what differs is which state it's applied to, and
   whether that state is an eigenstate of the operator being kicked back.</details>

---
[← Chapter 14](14-DeutschJozsa.md) · [Contents](../../INTRODUCTION.md) · [Chapter 16 →](16-QFT.md)
