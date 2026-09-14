# Chapter 14 — Deutsch–Jozsa and Bernstein–Vazirani

> Chapter 13's one-query trick, widened from one bit to n: Deutsch–Jozsa decides constant vs.
> balanced on an n-bit function in a single query where a classical machine needs exponentially
> many in the worst case, and Bernstein–Vazirani reuses the identical circuit to read back an
> entire hidden n-bit string in that same one query.

| | |
|---|---|
| Playground page | [`17DeutschJozsa`](../../../SwiftQiskit/PlaygroundDocs/17DEUTSCHJOZSAHELP.md) |
| In the app | ● — up to the app's 8-qubit maximum (7 query qubits + 1 ancilla); every `cx`-built oracle below is tappable |
| Library APIs | `QuantumCircuit.h/x/cx`, `.apply(_:)`, `.probabilities`, `measure(shots:)`, `BlochVector(_:qubit:)` |
| Prerequisites | Chapters 12, 13 |

## 14.1 From one bit to n

Chapter 13 answered one question about a black-box f: {0,1} → {0,1} — constant or balanced — with
a single query, using phase kickback onto one query qubit and one ancilla. Deutsch–Jozsa (Deutsch
and Jozsa, 1992) asks the identical question of f: {0,1}ⁿ → {0,1}: is f constant (the same output
for every one of the 2ⁿ inputs) or balanced (output 1 for exactly half of them)? A classical
algorithm checking this by evaluating f on inputs one at a time can be unlucky for a very long
time — it can see the same output 2ⁿ⁻¹ times running through a balanced function's zeros before
the 2ⁿ⁻¹+1'th query is forced to reveal the other value — so a classical *certain* answer costs up
to 2ⁿ⁻¹+1 queries. The quantum circuit answers with exactly one query, for every n. Bernstein and
Vazirani noticed in 1993 that the very same circuit, pointed at a different (but still linear)
family of oracles, does something stronger: it recovers an entire hidden n-bit string s in that
one query, where reading s off classically costs exactly n queries, one bit at a time. Nothing
below needs a new mechanism — every idea is Chapter 13's kickback, run on more qubits at once.

| § | What happens |
|---|---|
| 14.2 | The circuit, widened to n input qubits + 1 ancilla |
| 14.3 | Oracles from `cx`: two constant, two balanced |
| 14.4 | The verdict — an exact 0/1 marginal over the input register, from one query |
| 14.5 | Shot statistics and a gotcha: the ancilla's bit is a free coin, even with an extra `H` |
| 14.6 | Bernstein–Vazirani: the same circuit reads back a whole hidden string, one query |
| 14.7 | Why one circuit answers two questions — and where a non-linear oracle breaks it |
| 14.8 | The query-count gap, and what "exponential" actually assumes |

## 14.2 The circuit, widened

Qubit 0 remains the most-significant (leftmost) bit, as throughout Chapters 10–14; the ancilla
here is placed *last* — qubit n, the rightmost character of every outcome string — matching the
playground page and keeping the n query qubits as a contiguous leading block. The circuit is
Chapter 13's, unchanged in shape:

```text
1. x(ancilla)              prepare the ancilla as |1⟩
2. H on every qubit         inputs → |+⟩^⊗n, ancilla → |−⟩
3. oracle U_f                one query, via phase kickback onto the inputs
4. H on every input          interfere — but NOT on the ancilla
5. measure the inputs        all-zeros ⇒ constant (DJ), or the hidden string s (BV)
```

The one detail that costs care: step 4's closing `H` layer runs on the n *input* qubits only, not
the ancilla. Re-Hadamarding the ancilla is a common transcription slip, and it's worth being exact
about what it does and doesn't do (§14.5 measures it directly) — nothing about the input qubits'
readout depends on it, because Chapter 13 §13.5's finding still holds here: the ancilla never
entangles with the inputs, so whatever happens to its own qubit stays confined to its own qubit.

## 14.3 Oracles from `cx`

Every oracle below is `U_f: |x⟩|y⟩ → |x⟩|y ⊕ f(x)⟩`, built the same way Chapter 13 §13.2 built its
four 1-bit oracles — `cx` from each input qubit that f depends on, into the ancilla:

| f | Type | Gates (n = 3, ancilla = qubit 3) |
|---|---|---|
| f(x) = 0 | constant | (none — identity) |
| f(x) = 1 | constant | `x(3)` |
| f(x) = x₀ | balanced | `cx(0, 3)` |
| f(x) = x₀ ⊕ x₁ ⊕ x₂ (full parity) | balanced | `cx(0, 3); cx(1, 3); cx(2, 3)` |

Every one of these is a **linear** function of the input bits — a XOR of some subset of them,
possibly empty (the constant-0 case) or complemented by a leading `X` (constant-1). §14.7 returns
to why that linearity matters.

## 14.4 The verdict

Running all four oracles and reading `P(all-zero input)` — the marginal probability that the n
input qubits measure `|00…0⟩`, summing out the ancilla, since the app and the library alike report
the whole register's probabilities together and there's no way to measure a subset in isolation:

```text
oracle             P(|000⟩)  verdict    expected
constant 0        1.0000    constant   constant
constant 1        1.0000    constant   constant
balanced on x0    0.0000    balanced   balanced
balanced parity   0.0000    balanced   balanced
```

Exactly 1 or exactly 0, for every n — this is the same `x = ±1` exactness Chapter 13 §13.6 found
for the single-bit case, now read off n qubits' worth of interference at once rather than one.
Constant oracles leave the input register unchanged by the final `H` layer (every input qubit was
never touched by the oracle, so `H` simply undoes the opening `H`, landing back at `|0⟩^⊗n`);
balanced ones scatter the amplitude away from `|00…0⟩` entirely. One query, and the marginal is
never anywhere in between.

## 14.5 Shot statistics, and a gotcha

`measure(shots:)` reports every qubit, including the ancilla — and the ancilla ends the circuit in
`|−⟩`, an equal superposition, so its own bit is a fair coin regardless of what the oracle did.
Sampling the balanced-on-x₀ oracle 200 times:

```text
balanced-on-x0, 200 shots, raw outcome strings:
  1000: 96
  1001: 104
```

Both outcomes share the input prefix `100` — the balanced verdict, fixed — and differ only in the
last character, the ancilla, split close to but not exactly 50/50 (Chapter 9's usual shot jitter).
Reading a verdict off shot data means slicing off that last character first; §14.4's marginal is
the exact way to get the same answer without sampling at all.

What if the closing `H` layer is mistakenly widened to include the ancilla — the transcription slip
§14.2 warned about? Running the balanced-on-x₀ oracle with `H` on all four qubits at the end,
instead of just the three inputs:

```text
extra H on ancilla too, nonzero probs:
  1001: 1.0000
```

A single certain outcome, not a broken circuit — the extra `H` on `|−⟩` deterministically lands the
ancilla at `|1⟩` (Chapter 8 §8.4's `H;Z;H` identity: `|−⟩` is `H|1⟩` up to a global phase, so a
second `H` returns it to `|1⟩` exactly), and the input bits are entirely undisturbed, still reading
the correct verdict `100`. The extra `H` doesn't corrupt the phase-kickback result; it just pins a
bit that would otherwise be random.

## 14.6 Bernstein–Vazirani: reading back a hidden string

Point the identical circuit at a *linear* oracle family instead: `f(x) = s·x mod 2` for a hidden
bit string s, built as `cx(q, ancilla)` for every input qubit q where s has a 1. For n = 3,
s = 101 means `cx(0, 3)` and `cx(2, 3)` (qubit 1's bit is 0, so it's skipped). Reading the query
qubits' Bloch cards stage by stage makes the string visible even before the closing `H` layer:

```text
after oracle, s = 101:
  q0: x -1.000  y +0.000  z +0.000  |r| 1.000
  q1: x +1.000  y +0.000  z +0.000  |r| 1.000
  q2: x -1.000  y +0.000  z +0.000  |r| 1.000
  q3: x -1.000  y +0.000  z +0.000  |r| 1.000

final cards:
  q0: x +0.000  y +0.000  z -1.000  |r| 1.000
  q1: x +0.000  y +0.000  z +1.000  |r| 1.000
  q2: x +0.000  y +0.000  z -1.000  |r| 1.000
  q3: x -1.000  y +0.000  z +0.000  |r| 1.000
```

Each query qubit that appears in s picks up an `x = −1` phase kickback (Chapter 13 §13.3–13.4's
mechanism, run three times independently — one per input qubit that `cx`'s into the ancilla); the
one that doesn't stays at `x = +1`. The closing `H` on the inputs turns `−x → −z` (bit 1) and
`+x → +z` (bit 0) exactly as Chapter 13 §13.6 converted one sign into one certain bit — q0 and q2
land at `z −1.000` (bit 1), q1 at `z +1.000` (bit 0), reading back `101`. The ancilla, untouched by
the input-only closing `H`, stays parked at `x −1.000` throughout, exactly as in Chapter 13 §13.5.

Running the marginal for several hidden strings confirms every one comes back exactly:

```text
hidden s   recovered   P
101        101         1.0000
110        110         1.0000
111        111         1.0000
000        000         1.0000
```

One query recovers all n bits of s at once, with certainty — where a classical algorithm has no
better strategy than querying the n standard-basis strings e₀, e₁, …, eₙ₋₁ one at a time, learning
exactly one bit of s per query.

## 14.7 Why one circuit answers two questions

Deutsch–Jozsa asks "is s the zero string?" and Bernstein–Vazirani asks "what is s?" — two different
questions that turn out to have the same answer procedure because every oracle in both families is
the *same kind* of function: `f(x) = s·x mod 2` for some fixed s (DJ's balanced oracles are exactly
the nonzero-s case; its constant oracles are `s = 0`, optionally XORed with a fixed 1 via the
leading `X`). Any such f is **linear** in the input bits, and phase kickback turns a linear f into
a single sign per basis state that the closing `H` layer converts, one qubit at a time, straight
into s's own bits. DJ only ever asks a coarser question of the same output; BV asks for the whole
thing.

That linearity is doing real work, which is visible by breaking it. Take a **non-linear** balanced
function, f(x) = (x₀ ∧ x₁) ⊕ x₂ — still balanced (exactly half of the 8 inputs give 1), but not
expressible as any `cx` combination, since `cx` only ever XORs single input qubits into the
ancilla, never their AND. Building it instead as a hand-written permutation matrix via
`QuantumCircuit.apply(_:)` (◐ — this step needs the escape hatch; see "Build it in the app" below)
and running the same circuit:

```text
non-linear oracle f = x0 x1 XOR x2, cards after the oracle:
  q0: x +0.000  y +0.000  z +0.000  |r| 0.000
  q1: x +0.000  y +0.000  z +0.000  |r| 0.000
  q2: x -1.000  y +0.000  z +0.000  |r| 1.000
  q3: x -1.000  y +0.000  z +0.000  |r| 1.000

P(|000⟩) = 0.0000
nonzero final outcomes:
  0010: 0.1250
  0011: 0.1250
  0110: 0.1250
  0111: 0.1250
  1010: 0.1250
  1011: 0.1250
  1110: 0.1250
  1111: 0.1250
```

Two things happen at once. First, q0 and q1 read `|r| = 0.000` right after the oracle — the AND
term entangles them with each other (and with the ancilla) instead of cleanly kicking back a
per-qubit sign, the opposite of Chapter 13 §13.5's and this chapter's §14.6 finding for linear
oracles. Second, Deutsch–Jozsa's verdict still comes out right — `P(|000⟩) = 0.0000`, correctly
balanced, because DJ's proof only ever needs f to be *some* balanced function, linear or not.
Bernstein–Vazirani's readout, by contrast, is destroyed: the final distribution spreads evenly over
eight different three-bit strings instead of collapsing onto one, because there is no single
hidden linear string for a non-linear f to encode. DJ survives non-linearity; BV specifically needs
it.

## 14.8 The query-count gap

Quantum: exactly 1 query, for any n. Classical, worst case:

```text
n    quantum queries   classical DJ (worst case)   classical BV
2    1                 3                          2
3    1                 5                          3
4    1                 9                          4
5    1                 17                          5
```

Deutsch–Jozsa's classical worst case, 2ⁿ⁻¹+1, and Bernstein–Vazirani's, exactly n, are the standard
closed-form results (there is no classical oracle-query model in this library to simulate; the
table above is arithmetic, not a run). One accounting point worth stating plainly, so the gap isn't
over-read: that exponential classical cost is for an algorithm required to be *certain*. A
classical algorithm allowed a small, bounded error probability can decide constant-vs-balanced in a
*constant* number of queries — sample a handful of random inputs, and either see two different
outputs (certainly balanced) or, after enough tries, be confident enough it's constant. Deutsch–
Jozsa's headline speedup is against *exact* classical algorithms specifically; it's Bernstein–
Vazirani's n-queries-minimum that holds even against classical algorithms allowed to guess and get
lucky, since recovering all n bits of an arbitrary hidden string genuinely needs n bits of
information, however you gather them.

## Build it in the app

● Every step starts from **Clear**, **Qubits: 4**. Qubit 0 is the leftmost bit of every label,
qubit 3 is the ancilla and the rightmost bit, as throughout Chapters 10–14.

1. **Prepare the phase register** — Arm **X** (Pauli section), tap `q3` in column 0. Arm **H**, tap
   `q0`, `q1`, `q2`, `q3` in column 1. Panel: 16 rows at flat `p=0.062` each — every ± sign present,
   `|+⟩^⊗3|−⟩`.
2. **Query the Bernstein–Vazirani oracle for s = 101** — Arm **CX**, tap `q0` then `q3` in column 2
   (this is `cx(0,3)`). Since a column can only hold one `cx` touching a given qubit, arm **CX**
   again and tap `q2` then `q3` in column 3 (`cx(2,3)`) — a separate column, not because the app
   requires it structurally, but because `q3` is already occupied in column 2. Panel still shows 16
   rows at `p=0.062`, but the sign pattern has shifted (Chapter 13 §13.4's kickback, now landing on
   two qubits instead of one).
3. **Watch it on the sphere** — Tap **Display**, pick **Steps**, qubit picker on `q0`: swings to
   `+x` after column 1's `H`, then to `−x` after column 2's `cx` (its own oracle term), and stays
   there through column 3 (untouched by `cx(2,3)`). Switch to `q1`: swings to `+x` at column 1 and
   stays there — no oracle term touches it, matching s's middle bit `0`. Switch to `q2`: `+x` after
   column 1, unchanged through column 2, then `−x` after column 3's `cx`. Switch to `q3`: flips to
   the south pole at column 0, to `−x` at column 1, and stays parked there through both `cx`s —
   Chapter 13 §13.5's "the ancilla's card doesn't move" finding, confirmed on two oracle
   applications instead of one.
4. **Close with H, read the string off the panel** — Arm **H**, tap `q0`, `q1`, `q2` in column 4
   (**not** `q3` — leaving the ancilla's own `H` off is the detail §14.2 and §14.5 flag). Panel
   collapses to two rows, `|1010⟩: p=0.500` and `|1011⟩: p=0.500` — leading three bits `101`,
   exactly s, on both rows; only the ancilla's trailing bit varies. Set **Shots: 1000**, tap
   **Measure**: outcomes split close to 50/50 between `1010` and `1011`, confirming §14.5's shot
   gotcha directly — slice off the last character to read the string.
5. **Swap the oracle** — Delete both `cx` tiles via their context menu. For the **constant-0**
   oracle, leave columns 2–3 empty; Measure: only `0000`/`0001` appear (the leftmost three bits all
   zero). For the **full-parity** oracle (s = 111), place `cx(0,3)` at column 2, `cx(1,3)` at
   column 3, and `cx(2,3)` at column 4 (moving the closing `H`s to column 5); Measure: outcomes
   split between `1110`/`1111`.
6. **Try the mistaken closing H** — From step 4's circuit, also arm **H** and tap `q3` in column 4
   (now all four qubits get the closing `H`). Panel collapses to a single row, `|1011⟩: p=1.000` —
   §14.5's "extra H" result: the verdict on `q0`–`q2` is untouched, and `q3` is pinned to `1`
   instead of staying a coin flip.
7. **Scale up** — Set **Qubits: 8** (7 query qubits + 1 ancilla, the app's ceiling). Build the
   Bernstein–Vazirani oracle for any 7-bit string as one `cx(q, 7)` per set bit, each in its own
   column since qubit 7 can only be occupied once per column, then `H` on `q0`–`q6` in the next
   free column. Measure: the two outcomes to appear share the 7-bit prefix equal to the hidden
   string, differing only in the trailing ancilla bit.

Two limits stated plainly, as Chapter 13 did: the app cannot measure the query register alone, so
every verdict and every recovered string above is read off the leading characters of the whole
register's histogram, never watched in isolation; and §14.7's non-linear oracle is ◐, not ● — there
is no gate in the palette that computes an AND of two qubits into a third, so that step needs
`apply(_:)` with a hand-built permutation matrix in code, not a tap sequence.

## Run it in code

Every snippet below was run with `RunCodeSnippet` against
`SwiftQiskitApp/SwiftQiskitApp/CircuitModel.swift`.

```swift
import SwiftQiskitCore

let n = 3
let ancilla = n
let total = n + 1

func djCircuit(oracle: (QuantumCircuit) -> Void) -> QuantumCircuit {
    let qc = QuantumCircuit(qubits: total)
    qc.x(ancilla)
    for q in 0...ancilla { qc.h(q) }
    oracle(qc)
    for q in 0..<n { qc.h(q) }
    return qc
}

func inputMarginal(_ qc: QuantumCircuit) -> [Double] {
    let probs = qc.run().probabilities
    var marginal = [Double](repeating: 0, count: 1 << n)
    for (i, p) in probs.enumerated() { marginal[i >> 1] += p }
    return marginal
}

struct Oracle {
    let name: String
    let isBalanced: Bool
    let apply: (QuantumCircuit) -> Void
}

let oracles: [Oracle] = [
    Oracle(name: "constant 0     ", isBalanced: false) { _ in },
    Oracle(name: "constant 1     ", isBalanced: false) { $0.x(ancilla) },
    Oracle(name: "balanced on x0 ", isBalanced: true) { $0.cx(0, ancilla) },
    Oracle(name: "balanced parity", isBalanced: true) { qc in
        for q in 0..<n { qc.cx(q, ancilla) }
    }
]

// 14.4 -- the verdict
print("oracle             P(|000⟩)  verdict    expected")
for oracle in oracles {
    let marginal = inputMarginal(djCircuit(oracle: oracle.apply))
    let allZero = marginal[0]
    let verdict = allZero > 0.5 ? "constant" : "balanced"
    let expected = oracle.isBalanced ? "balanced" : "constant"
    print("\(oracle.name)   \(String(format: "%.4f", allZero))    \(verdict)   \(expected)")
}

// 14.8 -- the query-count gap
print("\nn    quantum queries   classical DJ (worst case)   classical BV")
for bits in 2...5 {
    let classicalDJ = (1 << (bits - 1)) + 1
    print("\(bits)    1                 \(classicalDJ)                          \(bits)")
}
```

```text
oracle             P(|000⟩)  verdict    expected
constant 0        1.0000    constant   constant
constant 1        1.0000    constant   constant
balanced on x0    0.0000    balanced   balanced
balanced parity   0.0000    balanced   balanced

n    quantum queries   classical DJ (worst case)   classical BV
2    1                 3                          2
3    1                 5                          3
4    1                 9                          4
5    1                 17                          5
```

```swift
import SwiftQiskitCore

let n = 3
let ancilla = n
let total = n + 1

func djCircuit(oracle: (QuantumCircuit) -> Void) -> QuantumCircuit {
    let qc = QuantumCircuit(qubits: total)
    qc.x(ancilla)
    for q in 0...ancilla { qc.h(q) }
    oracle(qc)
    for q in 0..<n { qc.h(q) }
    return qc
}

// 14.5 -- shots include the ancilla bit
let balancedShots = djCircuit(oracle: { $0.cx(0, ancilla) }).measure(shots: 200)
print("balanced-on-x0, 200 shots, raw outcome strings:")
for (outcome, count) in balancedShots.sortedCounts {
    print("  \(outcome): \(count)")
}

// 14.5 -- the mistaken extra H on the ancilla
let qcExtra = QuantumCircuit(qubits: total)
qcExtra.x(ancilla)
for q in 0...ancilla { qcExtra.h(q) }
qcExtra.cx(0, ancilla)
for q in 0...ancilla { qcExtra.h(q) }   // H on inputs AND ancilla -- the slip
let extra = qcExtra.run()
print("\nextra H on ancilla too, nonzero probs:")
for (i, p) in extra.probabilities.enumerated() where p > 1e-9 {
    let bits = String(i, radix: 2).leftPadding(toLength: total, withPad: "0")
    print("  \(bits): \(String(format: "%.4f", p))")
}
```

```text
balanced-on-x0, 200 shots, raw outcome strings:
  1000: 96
  1001: 104

extra H on ancilla too, nonzero probs:
  1001: 1.0000
```

```swift
import SwiftQiskitCore

let n = 3
let ancilla = n
let total = n + 1

func bvOracle(_ s: Int) -> (QuantumCircuit) -> Void {
    { qc in
        for q in 0..<n where (s >> (n - 1 - q)) & 1 == 1 {
            qc.cx(q, ancilla)
        }
    }
}

func card(_ b: BlochVector) -> String {
    String(format: "x %+.3f  y %+.3f  z %+.3f  |r| %.3f", b.x, b.y, b.z, b.magnitude)
}

// 14.6 -- Bloch cards, stage by stage, for s = 101
let s = 0b101
let qc = QuantumCircuit(qubits: total)
qc.x(ancilla)
for q in 0...ancilla { qc.h(q) }
bvOracle(s)(qc)
let afterOracle = qc.run()
print("after oracle, s = 101:")
for q in 0..<total {
    print("  q\(q):", card(BlochVector(afterOracle, qubit: q)))
}
for q in 0..<n { qc.h(q) }
let final = qc.run()
print("\nfinal cards:")
for q in 0..<total {
    print("  q\(q):", card(BlochVector(final, qubit: q)))
}

// 14.6 -- recovering several hidden strings exactly
func djCircuit(oracle: (QuantumCircuit) -> Void) -> QuantumCircuit {
    let qc = QuantumCircuit(qubits: total)
    qc.x(ancilla)
    for q in 0...ancilla { qc.h(q) }
    oracle(qc)
    for q in 0..<n { qc.h(q) }
    return qc
}
func inputMarginal(_ qc: QuantumCircuit) -> [Double] {
    let probs = qc.run().probabilities
    var marginal = [Double](repeating: 0, count: 1 << n)
    for (i, p) in probs.enumerated() { marginal[i >> 1] += p }
    return marginal
}

print("\nhidden s   recovered   P")
for hidden in [0b101, 0b110, 0b111, 0b000] {
    let marginal = inputMarginal(djCircuit(oracle: bvOracle(hidden)))
    let top = marginal.enumerated().max(by: { $0.element < $1.element })!
    let hiddenStr = String(hidden, radix: 2).leftPadding(toLength: n, withPad: "0")
    let recoveredStr = String(top.offset, radix: 2).leftPadding(toLength: n, withPad: "0")
    print("\(hiddenStr)        \(recoveredStr)         \(String(format: "%.4f", top.element))")
}
```

```text
after oracle, s = 101:
  q0: x -1.000  y +0.000  z +0.000  |r| 1.000
  q1: x +1.000  y +0.000  z +0.000  |r| 1.000
  q2: x -1.000  y +0.000  z +0.000  |r| 1.000
  q3: x -1.000  y +0.000  z +0.000  |r| 1.000

final cards:
  q0: x +0.000  y +0.000  z -1.000  |r| 1.000
  q1: x +0.000  y +0.000  z +1.000  |r| 1.000
  q2: x +0.000  y +0.000  z -1.000  |r| 1.000
  q3: x -1.000  y +0.000  z +0.000  |r| 1.000

hidden s   recovered   P
101        101         1.0000
110        110         1.0000
111        111         1.0000
000        000         1.0000
```

```swift
import SwiftQiskitCore

let n = 3
let ancilla = n
let total = n + 1

func card(_ b: BlochVector) -> String {
    String(format: "x %+.3f  y %+.3f  z %+.3f  |r| %.3f", b.x, b.y, b.z, b.magnitude)
}

func inputMarginal(_ qc: QuantumCircuit) -> [Double] {
    let probs = qc.run().probabilities
    var marginal = [Double](repeating: 0, count: 1 << n)
    for (i, p) in probs.enumerated() { marginal[i >> 1] += p }
    return marginal
}

// 14.7 -- a non-linear balanced oracle: f(x) = (x0 AND x1) XOR x2
// not expressible as cx alone -- built as a hand-written permutation matrix.
var matrix = Matrix(rows: 1 << total, cols: 1 << total)
for basis in 0..<(1 << total) {
    let x0 = (basis >> 3) & 1, x1 = (basis >> 2) & 1, x2 = (basis >> 1) & 1
    let f = (x0 & x1) ^ x2
    let out = f == 1 ? (basis ^ 1) : basis
    matrix[out, basis] = Complex(1, 0)
}

let qc = QuantumCircuit(qubits: total)
qc.x(ancilla)
for q in 0...ancilla { qc.h(q) }
qc.apply(matrix)
let afterOracle = qc.run()
print("non-linear oracle f = x0 x1 XOR x2, cards after the oracle:")
for q in 0..<total {
    print("  q\(q):", card(BlochVector(afterOracle, qubit: q)))
}

for q in 0..<n { qc.h(q) }
let final = qc.run()

let checkCircuit: QuantumCircuit = {
    let c = QuantumCircuit(qubits: total)
    c.x(ancilla)
    for q in 0...ancilla { c.h(q) }
    c.apply(matrix)
    for q in 0..<n { c.h(q) }
    return c
}()
let marginal = inputMarginal(checkCircuit)
print("\nP(|000⟩) =", String(format: "%.4f", marginal[0]))
print("nonzero final outcomes:")
for (i, p) in final.probabilities.enumerated() where p > 1e-9 {
    let bits = String(i, radix: 2).leftPadding(toLength: total, withPad: "0")
    print("  \(bits): \(String(format: "%.4f", p))")
}
```

```text
non-linear oracle f = x0 x1 XOR x2, cards after the oracle:
  q0: x +0.000  y +0.000  z +0.000  |r| 0.000
  q1: x +0.000  y +0.000  z +0.000  |r| 0.000
  q2: x -1.000  y +0.000  z +0.000  |r| 1.000
  q3: x -1.000  y +0.000  z +0.000  |r| 1.000

P(|000⟩) = 0.0000
nonzero final outcomes:
  0010: 0.1250
  0011: 0.1250
  0110: 0.1250
  0111: 0.1250
  1010: 0.1250
  1011: 0.1250
  1110: 0.1250
  1111: 0.1250
```

Finally, the app-path walkthrough behind steps 1–4 of "Build it in the app," driving
`CircuitBuilder` directly and formatting output exactly as `ResultsView`'s panel and
`BlochSphereView`'s card do (helpers first defined in Chapters 7–8, reused unchanged from
Chapter 13):

```swift
import SwiftQiskitCore

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

// s = 101: x@0, h(0..3)@1, cx(0,3)@2, cx(2,3)@3, h(0..2)@4
var b = CircuitBuilder(qubitCount: 4)
b.place(.x, qubits: [3], column: 0)
for q in 0..<4 { b.place(.h, qubits: [q], column: 1) }
b.place(.cx, qubits: [0, 3], column: 2)
b.place(.cx, qubits: [2, 3], column: 3)
for q in 0..<3 { b.place(.h, qubits: [q], column: 4) }

print("panel after col 3 (post-oracle):", panelRows(b.buildCircuit(throughColumn: 3).run(), qubits: 4))
print("final panel:", panelRows(b.buildCircuit().run(), qubits: 4))

let afterOracle = b.buildCircuit(throughColumn: 3).run()
for q in 0..<4 { print("q\(q) after oracle:", card(BlochVector(afterOracle, qubit: q))) }

// confirm a second cx can't share column 2 -- q3 is already occupied there
print("\nsecond cx attempt sharing column 2 (should fail, occupied):", b.place(.cx, qubits: [1, 3], column: 2))
```

```text
panel after col 3 (post-oracle): ["|0000⟩: 0.24999999999999992  (p=0.062)", "|0001⟩: -0.24999999999999992  (p=0.062)", "|0010⟩: -0.24999999999999992  (p=0.062)", "|0011⟩: 0.24999999999999992  (p=0.062)", "|0100⟩: 0.24999999999999992  (p=0.062)", "|0101⟩: -0.24999999999999992  (p=0.062)", "|0110⟩: -0.24999999999999992  (p=0.062)", "|0111⟩: 0.24999999999999992  (p=0.062)", "|1000⟩: -0.24999999999999992  (p=0.062)", "|1001⟩: 0.24999999999999992  (p=0.062)", "|1010⟩: 0.24999999999999992  (p=0.062)", "|1011⟩: -0.24999999999999992  (p=0.062)", "|1100⟩: -0.24999999999999992  (p=0.062)", "|1101⟩: 0.24999999999999992  (p=0.062)", "|1110⟩: 0.24999999999999992  (p=0.062)", "|1111⟩: -0.24999999999999992  (p=0.062)"]
final panel: ["|1010⟩: 0.7071067811865471  (p=0.500)", "|1011⟩: -0.7071067811865471  (p=0.500)"]
q0 after oracle: x -1.000  y +0.000  z +0.000  |r| 1.000
q1 after oracle: x +1.000  y +0.000  z +0.000  |r| 1.000
q2 after oracle: x -1.000  y +0.000  z +0.000  |r| 1.000
q3 after oracle: x -1.000  y +0.000  z +0.000  |r| 1.000

second cx attempt sharing column 2 (should fail, occupied): false
```

Re-running either shot-count block above will land close to, but not exactly on, the printed
splits — the app-visible statistics are genuinely probabilistic (Chapter 9), same as Chapter 13.

## Try it yourself

1. For n = 3 and the oracle `cx(1, ancilla)` (s = 010), what does §14.4's marginal read, and what
   verdict does that give?
   <details><summary>Answer</summary>Balanced — a single nonzero-`s` `cx` oracle is still
   balanced, so `P(|000⟩) = 0.0000` exactly, same as `balanced on x0` and `balanced parity` in the
   table. Deutsch–Jozsa only ever answers constant-vs-balanced; it cannot distinguish which
   balanced oracle it saw. Bernstein–Vazirani's marginal, run on the same oracle, is what actually
   tells `s0`0` apart from `100` or `001` (§14.6).</details>

2. Why is the ancilla's bit a fair coin in §14.5's 200-shot run for every oracle, even after the
   correct circuit gives a perfectly deterministic input-register verdict?
   <details><summary>Answer</summary>The ancilla starts and ends the circuit in `\|−⟩` — the
   oracle's `cx`s kick a phase back onto the *inputs*, but (per Chapter 13 §13.5's finding, still
   true here) never change the ancilla's own state, and the closing `H` layer deliberately skips
   it. A `\|−⟩` qubit measured in the computational basis is `0` or `1` with equal probability no
   matter what happened elsewhere in the circuit.</details>

3. §14.7 built a non-linear balanced oracle and found Deutsch–Jozsa still gave the right verdict
   while Bernstein–Vazirani's readout spread across eight strings instead of one. Why does DJ
   survive that but BV doesn't?
   <details><summary>Answer</summary>Deutsch–Jozsa's proof only needs f to be *some* balanced
   function — it never assumes linearity, so its verdict (constant vs. balanced) is correct for any
   f satisfying that definition. Bernstein–Vazirani's readout specifically decodes a *linear*
   function's coefficient string s; a non-linear f has no single s to decode, so the amplitude
   that would have concentrated on one string instead spreads over every string consistent with
   the AND term's entangling effect (§14.7's `\|r\| = 0.000` cards on q0/q1).</details>

4. Deutsch–Jozsa's classical worst case is exponential in n — but only for algorithms required to
   answer with certainty. What changes if a classical algorithm is allowed a small, bounded chance
   of being wrong?
   <details><summary>Answer</summary>A randomized classical algorithm can sample a small constant
   number of random inputs (independent of n): if it ever sees two different outputs, the function
   is certainly balanced; if all samples agree after enough tries, it's confident (though not
   certain) the function is constant. That drops the classical cost from exponential to constant,
   which is why Deutsch–Jozsa's speedup is specifically against *exact* classical algorithms
   (§14.8) — unlike Bernstein–Vazirani's n-query lower bound, which holds even against randomized
   classical algorithms, since recovering all n bits of an arbitrary string is n bits of
   information under any strategy.</details>

---
[← Chapter 13](13-Deutsch.md) · [Contents](../../INTRODUCTION.md) · [Chapter 15 →](15-Grover.md)
