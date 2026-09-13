# Chapter 10 — Superposition Across a Register

> Scaling superposition from one qubit to many: a 4-qubit register with every qubit put into
> superposition, its 16-state amplitude/probability spread, the leftmost-qubit label convention
> multi-qubit chapters depend on, a partial-superposition contrast, and the 2ⁿ cost that caps the
> app at 8 qubits.

| | |
|---|---|
| Playground page | [`06Superposition`](../../../SwiftQiskit/PlaygroundDocs/06SUPERPOSITIONHELP.md) |
| In the app | ● — up to the app's 8-qubit maximum |
| Library APIs | `QuantumCircuit.h/x`, multi-qubit `.amplitudes`/`.probabilities`, `measure(shots:)`/`SimulationResult.sortedCounts`, `BlochVector` |
| Prerequisites | Chapters 3, 7, 8, 9 |

## 10.1 Why scaling superposition matters

Every chapter so far has put at most one qubit into superposition at a time. `H` on a single
qubit buys two simultaneous amplitudes; `H` on `n` qubits buys `2ⁿ` — a register of 4 qubits
carries 16 amplitudes at once, and 8 qubits (this app's ceiling) carries 256. That exponential is
not a curiosity: it is the resource every algorithm in Chapters 13–17 spends. Deutsch–Jozsa,
Grover, and the quantum Fourier transform all open with the same first move this chapter studies
in isolation — a layer of `H` gates turning `|0…0⟩` into a uniform superposition over every
possible input — before doing something clever with the phases hiding inside it (Chapter 8's
subject, now at register scale).

| § | What happens |
|---|---|
| 10.2 | 4× `H`: `\|0000⟩` becomes a uniform superposition of all 16 four-qubit basis states |
| 10.3 | Reading a multi-qubit label: qubit 0 is the leftmost bit, pinned down with an asymmetric example |
| 10.4 | `H` on 2 of 4 qubits: only 4 of 16 states survive, the untouched qubits frozen at `0` |
| 10.5 | Confirming uniformity by measurement, and what a low shot count misses |
| 10.6 | The `2ⁿ` cost of a state vector, and why the app stops at 8 qubits |
| 10.7 | A uniform superposition is one state, not a random pick — proved by undoing it |

## 10.2 Every qubit in superposition

`QuantumCircuit(qubits: 4)` starts at `|0000⟩`. Applying `H` to each of the four qubits in turn
sends each one independently to `(|0⟩+|1⟩)/√2`; the combined state is the product of all four,
so every one of the `2⁴ = 16` basis states picks up the same amplitude, `(1/√2)⁴ = 1/4`, and the
same probability, `(1/4)² = 1/16 = 0.0625`. (Chapter 11 gives the tensor-product notation for
"the product of all four" properly — for now, the amplitude arithmetic is enough.) Verified:

```text
|0000⟩: 0.24999999999999992   |1000⟩: 0.24999999999999992
|0001⟩: 0.24999999999999992   |1001⟩: 0.24999999999999992
|0010⟩: 0.24999999999999992   |1010⟩: 0.24999999999999992
|0011⟩: 0.24999999999999992   |1011⟩: 0.24999999999999992
|0100⟩: 0.24999999999999992   |1100⟩: 0.24999999999999992
|0101⟩: 0.24999999999999992   |1101⟩: 0.24999999999999992
|0110⟩: 0.24999999999999992   |1110⟩: 0.24999999999999992
|0111⟩: 0.24999999999999992   |1111⟩: 0.24999999999999992
probabilities: sixteen entries, each 0.06249999999999996
```

All 16 amplitudes and all 16 probabilities agree to floating-point rounding — a perfectly
uniform distribution, produced with four taps.

## 10.3 Reading multi-qubit labels

`StateVector`'s basis index `i` maps to a bit string the same way every chapter since Chapter 4
has assumed: **qubit 0 is the most-significant, leftmost bit**. `06Superposition`'s own
`binaryLabel(_:qubits:)` helper (and `ResultsView`'s matching `binaryLabel`, backed by
`String.leftPadding`) zero-pads that bit string to a fixed width so every label lines up.

The convention is easy to misread on a symmetric example — `H` on q0 and q2 alone (§10.4) looks
the same whether qubit 0 is read as leftmost or rightmost, because the pattern is symmetric
either way. An asymmetric one pins it down: `X` on q1 alone, in a 4-qubit register, flips only the
*second* character of the label, not the third:

```text
X on q1 alone -> |0100⟩: 1.0
```

`0100` reads as `q0=0, q1=1, q2=0, q3=0` — the `1` sits in the second position from the left,
confirming q1 is the second-most-significant bit, not the second-least-significant one. Reading
it the other way around would predict `|0010⟩` instead, which is not what the simulator produces.

## 10.4 Partial superposition

Putting only some qubits into superposition contrasts directly with §10.2: `H` on q0 and q2 only
(q1 and q3 left at `|0⟩`) spreads probability across just `2² = 4` of the 16 basis states, each at
probability `0.25`, with q1 and q3 pinned at `0` in every surviving label:

```text
|0000⟩: 0.2499999999999999
|0010⟩: 0.2499999999999999
|1000⟩: 0.2499999999999999
|1010⟩: 0.2499999999999999
```

The general rule follows directly: `H` on `k` of `n` qubits produces `2ᵏ` equally-likely outcomes,
each at probability `1/2ᵏ`, and the `n − k` untouched qubits are exactly the bit positions that
never vary across those outcomes — here, positions 2 and 4 (q1, q3) are always `0`.

## 10.5 Confirming uniformity statistically

Chapter 9 §9.4 gives the tool for checking §10.2's uniform 1/16 claim by measurement rather than
by trusting `run()`: for `N` shots at probability `p`, the count's standard deviation is
`σ_count = √(N·p(1−p))`. At `N = 1600`, `p = 1/16`, that predicts `σ_count ≈ 9.68`, so a 95% band
sits roughly `100 ± 19` around the expected count of 100. An actual `measure(shots: 1600)` run
landed every one of the 16 outcomes between 84 and 117 — comfortably inside that band, and not on
exactly 100 anywhere (Chapter 9's jitter, now visible across 16 outcomes instead of 2):

```text
|0000⟩: 96    |1000⟩: 93
|0001⟩: 115   |1001⟩: 105
|0010⟩: 95    |1010⟩: 93
|0011⟩: 101   |1011⟩: 117
|0100⟩: 110   |1100⟩: 84
|0101⟩: 90    |1101⟩: 90
|0110⟩: 107   |1110⟩: 110
|0111⟩: 92    |1111⟩: 102
```

Chapter 9 §9.5's warning about missing bars applies with more force here, because there are 16
ways for a shot to land somewhere else instead of the outcome being watched. A 20-shot run on the
same circuit — an expected 1.25 counts per outcome — produced only 11 of the 16 possible labels;
the other five simply never came up in that batch, not because their true probability is zero
(it's a uniform 1/16, same as every other outcome) but because 20 shots spread across 16 equally
likely outcomes is too few to expect every one to appear.

## 10.6 What a uniform superposition costs

The same exponential that makes a register interesting to build makes it expensive to simulate.
`QuantumCircuit`'s state vector has dimension `2ⁿ` for `n` qubits, and the gate matrices it
multiplies against are `2ⁿ×2ⁿ`:

| Qubits | State-vector dimension | Operator entries (`2ⁿ×2ⁿ`) |
|---|---|---|
| 1 | 2 | 4 |
| 2 | 4 | 16 |
| 3 | 8 | 64 |
| 4 | 16 | 256 |
| 5 | 32 | 1,024 |
| 6 | 64 | 4,096 |
| 7 | 128 | 16,384 |
| 8 | 256 | 65,536 |

Eight taps of `H` buy 256 simultaneous amplitudes, but the simulator underneath is holding a
256×256 matrix to get there — a 65,536-entry object built from an 8-tap circuit. This asymmetry,
`n` gates for `2ⁿ` numbers to track, is exactly why `CircuitBuilder.maxQubits` stops at 8
(`CircuitModel.swift`): the app's grid stays responsive at that size, but nothing about the
mathematics stops at 8 — a real quantum computer's whole appeal is holding this same exponential
without ever materializing the matrix a classical simulator must.

## 10.7 One state, not a random choice

It is tempting to read "16 equally likely outcomes" as meaning the register secretly *is* one of
those 16 basis states, chosen at random, and a measurement merely reveals which. Chapter 8 already
ruled this out for a single qubit (`|+⟩` is one state, not a coin flip between `|0⟩` and `|1⟩`),
and the same interference argument settles it here: a uniform superposition is one definite state,
and only interference — not any classical mixture — can undo it perfectly.

The proof is a second layer of `H`. Applying `H` to all four qubits again after §10.2's first
layer returns, exactly, to `|0000⟩`:

```text
4×H; 4×H amplitudes:    [0.9999999999999993, 0.0, 0.0, 0.0, ...]  (all 16 entries)
4×H; 4×H probabilities: [0.9999999999999987, 0.0, 0.0, 0.0, ...]  (all 16 entries)
```

A genuine 50/50-or-worse classical mixture over 16 outcomes cannot be steered back to a single
guaranteed outcome by *any* further operation — once a coin is flipped, no amount of additional
tampering makes sixteen independent coins all read the same value with certainty. A quantum
superposition can, because each of the second layer's four `H` gates recombines its own qubit's
branches exactly as Chapter 8 §8.4 describes for one qubit, undoing the first layer branch by
branch. This is the same mechanism, purely scaled up, that Chapters 13–15 exploit: build a uniform
superposition, mark it with phases, and let a further round of interference collapse the marked
branches back down to a smaller, useful set of outcomes.

## Build it in the app

● Every step starts from **Clear** unless noted.

1. **All four qubits superposed** — Set **Qubits: 4**. Arm **H** (Pauli / Hadamard section) and
   tap all four rows in column 0. State Vector panel: 16 rows, each `p=0.062`.
2. **Confirm by measurement** — Set **Shots: 1600**, tap **Measure**: 16 histogram bars, each
   near 100 (§10.5). `HistogramView` scales every bar against the *largest* count present
   (Chapter 9 §9.5), so with 16 near-equal counts every bar looks near-full-height — read the
   printed numbers above each bar, not their relative heights.
3. **Fewer shots, holes in the histogram** — Step **Shots** down to its minimum, 1 (or a small
   value like 20), and **Measure**: several of the 16 possible bars are simply absent, not
   present at zero height (§10.5, Chapter 9 §9.5).
4. **Partial superposition** — Clear, arm **H**, tap only `q0` and `q2` in column 0. Panel: 4
   rows (`|0000⟩`, `|0010⟩`, `|1000⟩`, `|1010⟩`), each `p=0.250`; `q1` and `q3` read `0` in every
   row.
5. **Label ordering** — Clear, arm **X** (Pauli / Hadamard section), tap `q1` alone in column 0.
   Panel: one row, `|0100⟩: 1.0  (p=1.000)` — the flipped bit sits second from the left, matching
   `q1`'s position, not second from the right.
6. **Undoing it** — Rebuild step 1's four-`H` column, then arm **H** again and tap all four rows
   a second time, at column 1. Panel collapses back to a single row: `|0000⟩:
   0.9999999999999993  (p=1.000)` (§10.7).
7. **Display → Final, one qubit at a time** — With only the first `H` layer in place (undo step
   6's second layer by clearing and rebuilding just column 0), tap **Display**, select each
   qubit's **Final** card in turn: all four read `x +1.000  y +0.000  z +0.000`, `|r| = 1` — four
   independent `|+⟩` states, not one entangled state (contrast with the Bell state's `|r| = 0`
   cards in Chapter 12).
8. **The app's ceiling** — Set **Qubits: 8**, arm **H**, tap all eight rows in column 0. Panel:
   256 rows, each `p=0.004` — the largest uniform superposition the app can build (§10.6).

Two genuine limits, not a missing-capability paragraph: `CircuitBuilder.maxQubits` caps the grid
at 8 qubits, which is a UI-responsiveness limit, not a mathematical one — §10.6's `2ⁿ` cost keeps
climbing well past where the app can follow; and the State Vector panel is a flat, unsorted list
with no way to group or collapse equal-probability rows, so reading a 256-row uniform
superposition by eye means scrolling through all of it.

## Run it in code

Every snippet below was run with `RunCodeSnippet` against
`SwiftQiskitApp/SwiftQiskitApp/CircuitModel.swift`.

```swift
import SwiftQiskitCore

func binaryLabel(_ index: Int, qubits: Int) -> String {
    let raw = String(index, radix: 2)
    return String(repeating: "0", count: max(0, qubits - raw.count)) + raw
}

// 10.2 — four qubits, one Hadamard each
let qc = QuantumCircuit(qubits: 4)
qc.h(0); qc.h(1); qc.h(2); qc.h(3)
let state = qc.run()
print("amplitudes:", state.amplitudes)
print("probabilities:", state.probabilities)

// 10.3 — label ordering: X on q1 alone
let qcX = QuantumCircuit(qubits: 4)
qcX.x(1)
let stateX = qcX.run()
for (i, p) in stateX.probabilities.enumerated() where p > 1e-9 {
    print("X on q1 alone ->", "|\(binaryLabel(i, qubits: 4))⟩:", p)
}

// 10.4 — partial superposition: H on q0 and q2 only
let partialCircuit = QuantumCircuit(qubits: 4)
partialCircuit.h(0); partialCircuit.h(2)
let partialState = partialCircuit.run()
for (i, p) in partialState.probabilities.enumerated() where p > 1e-9 {
    print("|\(binaryLabel(i, qubits: 4))⟩:", p)
}

// 10.7 — a second H layer undoes the first
let qcBack = QuantumCircuit(qubits: 4)
qcBack.h(0); qcBack.h(1); qcBack.h(2); qcBack.h(3)
qcBack.h(0); qcBack.h(1); qcBack.h(2); qcBack.h(3)
let stateBack = qcBack.run()
print("4×H;4×H amplitudes:", stateBack.amplitudes)
print("4×H;4×H probabilities:", stateBack.probabilities)
```

```text
amplitudes: [0.24999999999999992, 0.24999999999999992, 0.24999999999999992, 0.24999999999999992, 0.24999999999999992, 0.24999999999999992, 0.24999999999999992, 0.24999999999999992, 0.24999999999999992, 0.24999999999999992, 0.24999999999999992, 0.24999999999999992, 0.24999999999999992, 0.24999999999999992, 0.24999999999999992, 0.24999999999999992]
probabilities: [0.06249999999999996, 0.06249999999999996, 0.06249999999999996, 0.06249999999999996, 0.06249999999999996, 0.06249999999999996, 0.06249999999999996, 0.06249999999999996, 0.06249999999999996, 0.06249999999999996, 0.06249999999999996, 0.06249999999999996, 0.06249999999999996, 0.06249999999999996, 0.06249999999999996, 0.06249999999999996]
X on q1 alone -> |0100⟩: 1.0
|0000⟩: 0.2499999999999999
|0010⟩: 0.2499999999999999
|1000⟩: 0.2499999999999999
|1010⟩: 0.2499999999999999
4×H;4×H amplitudes: [0.9999999999999993, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
4×H;4×H probabilities: [0.9999999999999987, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
```

§10.5's shot-statistics claims, `measure(shots: 1600)` against the `σ_count = √(N·p(1−p))`
prediction, plus a low-shot run showing outcomes drop out of `counts` entirely:

```swift
import SwiftQiskitCore
import Foundation

let qc = QuantumCircuit(qubits: 4)
qc.h(0); qc.h(1); qc.h(2); qc.h(3)

let result = qc.measure(shots: 1600)
print("sortedCounts (1600 shots):", result.sortedCounts)
let counts = result.sortedCounts.map(\.count)
print("min:", counts.min() ?? -1, "max:", counts.max() ?? -1)

let p = 1.0 / 16.0
let sigmaCount = sqrt(1600.0 * p * (1 - p))
print(String(format: "predicted sigma_count = %.2f, 95%% band +-%.1f around 100", sigmaCount, 1.96 * sigmaCount))

let result20 = qc.measure(shots: 20)
print("\n20-shot run, keys present:", result20.counts.keys.count, "of 16")
print("20-shot sortedCounts:", result20.sortedCounts)
```

```text
sortedCounts (1600 shots): [(state: "0000", count: 96), (state: "0001", count: 115), (state: "0010", count: 95), (state: "0011", count: 101), (state: "0100", count: 110), (state: "0101", count: 90), (state: "0110", count: 107), (state: "0111", count: 92), (state: "1000", count: 93), (state: "1001", count: 105), (state: "1010", count: 93), (state: "1011", count: 117), (state: "1100", count: 84), (state: "1101", count: 90), (state: "1110", count: 110), (state: "1111", count: 102)]
min: 84 max: 117
predicted sigma_count = 9.68, 95% band +-19.0 around 100
20-shot run, keys present: 11 of 16
20-shot sortedCounts: [(state: "0000", count: 4), (state: "0001", count: 1), (state: "0011", count: 1), (state: "0100", count: 2), (state: "0101", count: 1), (state: "0110", count: 2), (state: "0111", count: 1), (state: "1010", count: 2), (state: "1100", count: 1), (state: "1110", count: 2), (state: "1111", count: 3)]
```

Every observed count in the 1600-shot run falls between 84 and 117 — inside the predicted
`100 ± 19` band — and none lands on exactly 100, the same jitter Chapter 9 describes. Re-running
either snippet will not reproduce these exact counts, only the same rough neighborhood.

§10.6's dimension table, generated rather than hand-typed:

```swift
import SwiftQiskitCore

for n in 1...8 {
    let qc = QuantumCircuit(qubits: n)
    let dim = qc.run().dimension
    print("qubits \(n)  dimension \(dim)  operator entries \(dim * dim)")
}
```

```text
qubits 1  dimension 2  operator entries 4
qubits 2  dimension 4  operator entries 16
qubits 3  dimension 8  operator entries 64
qubits 4  dimension 16  operator entries 256
qubits 5  dimension 32  operator entries 1024
qubits 6  dimension 64  operator entries 4096
qubits 7  dimension 128  operator entries 16384
qubits 8  dimension 256  operator entries 65536
```

Finally, the app-path walkthrough behind every "Build it in the app" step above, driving
`CircuitBuilder` directly and formatting output exactly as `ResultsView`'s panel,
`HistogramView`'s bars, and `BlochSphereView`'s card do (helpers first defined in Chapters 8 and
9's "Run it in code"):

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
    var text = String(format: "x %+.3f  y %+.3f  z %+.3f  θ %.3f rad",
                       bloch.x, bloch.y, bloch.z, bloch.theta)
    if abs(bloch.magnitude - 1) > 1e-3 { text += String(format: "  |r| %.3f", bloch.magnitude) }
    return text
}

var reg4 = CircuitBuilder(qubitCount: 4)
for q in 0..<4 { reg4.place(.h, qubits: [q], column: 0) }
let reg4Rows = panelRows(reg4.buildCircuit().run(), qubits: 4)
print("4-qubit panel row count:", reg4Rows.count, "first row:", reg4Rows.first ?? "")

var partial = CircuitBuilder(qubitCount: 4)
partial.place(.h, qubits: [0], column: 0)
partial.place(.h, qubits: [2], column: 0)
print("partial panel:", panelRows(partial.buildCircuit().run(), qubits: 4))

var labelCheck = CircuitBuilder(qubitCount: 4)
labelCheck.place(.x, qubits: [1], column: 0)
print("label-check panel:", panelRows(labelCheck.buildCircuit().run(), qubits: 4))

var roundTrip = CircuitBuilder(qubitCount: 4)
for q in 0..<4 { roundTrip.place(.h, qubits: [q], column: 0) }
for q in 0..<4 { roundTrip.place(.h, qubits: [q], column: 1) }
print("round-trip panel:", panelRows(roundTrip.buildCircuit().run(), qubits: 4))

var single = CircuitBuilder(qubitCount: 4)
for q in 0..<4 { single.place(.h, qubits: [q], column: 0) }
let singleState = single.buildCircuit().run()
for q in 0..<4 {
    print("qubit \(q) card:", card(BlochVector(singleState, qubit: q)))
}

var reg8 = CircuitBuilder(qubitCount: 8)
for q in 0..<8 { reg8.place(.h, qubits: [q], column: 0) }
let reg8Rows = panelRows(reg8.buildCircuit().run(), qubits: 8)
print("8-qubit panel row count:", reg8Rows.count, "sample row:", reg8Rows.first ?? "")
```

```text
4-qubit panel row count: 16 first row: |0000⟩: 0.24999999999999992  (p=0.062)
partial panel: ["|0000⟩: 0.4999999999999999  (p=0.250)", "|0010⟩: 0.4999999999999999  (p=0.250)", "|1000⟩: 0.4999999999999999  (p=0.250)", "|1010⟩: 0.4999999999999999  (p=0.250)"]
label-check panel: ["|0100⟩: 1.0  (p=1.000)"]
round-trip panel: ["|0000⟩: 0.9999999999999993  (p=1.000)"]
qubit 0 card: x +1.000  y +0.000  z +0.000  θ 1.571 rad
qubit 1 card: x +1.000  y +0.000  z +0.000  θ 1.571 rad
qubit 2 card: x +1.000  y +0.000  z +0.000  θ 1.571 rad
qubit 3 card: x +1.000  y +0.000  z +0.000  θ 1.571 rad
8-qubit panel row count: 256 sample row: |00000000⟩: 0.06249999999999996  (p=0.004)
```

The panel's `%.3f` formatting rounds `0.0625` down to `0.062` and `1/256 ≈ 0.0039` down to
`0.004` — worth knowing before expecting the printed digits to match a fraction exactly.

## Try it yourself

1. With 3 qubits, put `H` on q0 and q2 only. How many nonzero states result, and which bit stays
   fixed?
   <details><summary>Answer</summary>4 nonzero states — `|000⟩`, `|001⟩`, `|100⟩`, `|101⟩`, each
   at probability 0.25 — and the middle bit (q1) stays `0` in every one, since only q0 and q2
   were put into superposition.</details>

2. How many `H` gates are needed for a uniform superposition over all 256 states of an 8-qubit
   register, and what is each outcome's probability?
   <details><summary>Answer</summary>8 — one `H` per qubit, exactly as in §10.2 but at the app's
   maximum register size. Each of the 256 outcomes has probability `1/256 ≈ 0.0039`, which the
   State Vector panel rounds to `p=0.004` (verified above).</details>

3. A 1600-shot measurement of the 16-outcome uniform superposition gives one outcome only 78
   counts, well under the expected 100. Is the distribution broken?
   <details><summary>Answer</summary>No. §10.5 predicts `σ_count ≈ 9.68` at this shot count, so a
   95% band spans roughly `100 ± 19`, i.e. 81 to 119. A count of 78 is just outside two standard
   deviations low — unremarkable across 16 independent outcomes, where at least one landing near
   the edge of the band is the expected behavior, not a sign of a bug. (The actual run above
   landed everywhere between 84 and 117, comfortably inside the band.)</details>

4. Apply `X` to one qubit of a 4-qubit register immediately after a full `H` layer on all four
   qubits. Do the measured probabilities change?
   <details><summary>Answer</summary>No — verified above, `X` after the full `H` layer leaves all
   16 probabilities at `0.0625`, identical to the register without the extra `X`. `X` permutes a
   uniform superposition's amplitudes onto each other (swapping which basis states pair up with
   which), and a uniform distribution is unchanged by any permutation of its own equal entries.
   The state genuinely changed — the amplitude at each index is no longer produced by the same
   basis-state pairing as before — but the histogram can't tell, a register-scale echo of Chapter
   8 §8.3's "real change, same probabilities" point.</details>

---
[← Chapter 9](09-Measurement.md) · [Contents](../../INTRODUCTION.md) · [Chapter 11 →](11-TensorProducts.md)
