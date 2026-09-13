# Chapter 9 — Measurement, Shots and Statistics

> Turning a state vector into classical bits: what a measurement actually does, `run()` vs
> `measure(shots:)`, why shot counts jitter by a predictable amount, and how to read a histogram
> without over- or under-reading it.

| | |
|---|---|
| Playground page | — (drawn from `05Gates`/`06Superposition` and `Quantum/SimulationResult.swift`) |
| In the app | ● — the Results panel's **Shots** stepper, **Measure** button, and histogram are exactly this |
| Library APIs | `QuantumCircuit.run()`, `.runAndMeasure()`, `.measure(shots:)`, `StateVector.measure()`, `SimulationResult`, `.sortedCounts` |
| Prerequisites | Chapters 3, 7 |

## 9.1 What a measurement is

Every state vector in this book carries complex amplitudes, but nothing ever *reads* an amplitude
directly — not on real hardware, and not in this simulator. What comes out of a measurement is one
classical bit string, chosen randomly according to the **Born rule**: the probability of landing
on basis state `i` is `|amplitudeᵢ|²`, the squaring first met in Chapter 3 and used without
comment ever since. `|+⟩ = (|0⟩+|1⟩)/√2` does not "contain" 50% of `|0⟩` the way a mixture does —
it is one state, and a measurement's job is to convert that one state into one classical outcome,
governed by amplitude-squared odds.

That conversion has a consequence with no analogue anywhere else in this book: it is **not
reversible**. Every gate covered in Chapter 7 is a unitary rotation that can, in principle, be
undone by another gate. A measurement cannot — once a qubit reads `0`, its state is `|0⟩`, full
stop, with no trace left of whatever superposition it started in. `StateVector.measure()` (§9.3)
makes this concrete: it does not just *report* an outcome, it **collapses** the vector into it.

A measurement is also **basis-dependent**, a fact easy to miss because this app only ever offers
one measurement button. Chapter 8 §8.6 already demonstrated the point without naming it as such:
`|+⟩` and `|−⟩` give indistinguishable, roughly-even splits forever if measured as-is, yet
appending a single `H` before measuring separates them completely — all-`"0"` for one, all-`"1"`
for the other. Nothing about either qubit changed; what changed is which question was asked of it.
"Measure" is shorthand for "measure in the computational (Z) basis" — a real choice, not the only
one, and this chapter's closing example (§9.7) restates it as a fact about measurement rather than
about phase.

Finally, a single measurement and a *statistical* measurement answer different questions. One shot
gives one bit — useless for recovering the probabilities that produced it. Only an **ensemble** of
many independent shots, tallied into a histogram, lets those probabilities be estimated back out —
and only approximately, with an error that shrinks as more shots are spent. That trade-off, between
shots spent and precision gained, is the rest of the chapter.

## 9.2 Exact vs. sampled: `run()` vs `measure(shots:)`

`QuantumCircuit.run()` is the simulator's privileged view: it returns the exact `StateVector`,
amplitudes and all, with no randomness anywhere — a vantage point no real quantum device offers,
since a real device can only be measured, never inspected mid-flight. Calling `run()` twice on the
same circuit gives identical numbers every time:

```text
run() call 1: [0.4999999999999999, 0.4999999999999999]
run() call 2: [0.4999999999999999, 0.4999999999999999]
```

`measure(shots:)` is the honest one — it simulates the only thing a real device can actually do,
repeated collapse, and reports the tally. On the same `H` circuit, six separate calls to
`measure(shots: 1000)` gave six different splits:

```text
measure(shots: 1000) run 1: [("0", 504), ("1", 496)]
measure(shots: 1000) run 2: [("0", 503), ("1", 497)]
measure(shots: 1000) run 3: [("0", 516), ("1", 484)]
measure(shots: 1000) run 4: [("0", 481), ("1", 519)]
measure(shots: 1000) run 5: [("0", 508), ("1", 492)]
measure(shots: 1000) run 6: [("0", 525), ("1", 475)]
```

Both methods agree on the underlying probabilities — every split above hovers near 50/50 — but
`run()` states them outright while `measure(shots:)` only ever approximates them, and a different
approximation every time. Re-running the snippet above will not reproduce these exact six splits.

## 9.3 Collapse, seen once

`QuantumCircuit.runAndMeasure()` returns a single outcome — one basis index, chosen with `run()`'s
probabilities but reported as a classical `Int` rather than a state vector:

```text
runAndMeasure() outcome: 1
```

That single call hides the mechanism, which lives on `StateVector` itself.
`var sv = qc.run(); sv.measure()` is `mutating`: it picks an outcome exactly as above, but leaves
the collapsed state sitting in `sv` afterward, so it can be inspected. Before measuring, `sv` is
the genuine 50/50 superposition; after, its probabilities are a hard `[0.0, 1.0]` or `[1.0, 0.0]`,
and measuring again changes nothing further:

```text
before measure(): [0.4999999999999999, 0.4999999999999999]
measure() returned: 1  probabilities now:   [0.0, 1.0]
measure() again returned: 1  probabilities still: [0.0, 1.0]
```

This is §9.1's irreversibility claim, made numeric: the superposition is simply gone, and no
further call to `measure()` — or any gate — brings back a coefficient that collapse deleted.

## 9.4 Why shots jitter

`measure(shots:)` runs `runAndMeasure()` independently `shots` times (confirmed in §9.7) and tallies
the results, so each shot behaves like a coin flip with probability `p` of landing on any given
outcome. Standard results for a **binomial** count of `N` independent flips give the spread
directly: the *fraction* of shots landing on an outcome has standard deviation
`σ = √(p(1−p)/N)`, and the raw *count* has `σ_count = √(N·p(1−p))`.

Repeating `measure(shots: N)` 40 times at each of four shot counts, on the same `H` circuit
(`p = 0.5` for either outcome), and comparing the observed spread in the fraction against the
formula's prediction:

| N | mean p₀ | observed σ | predicted σ = √(0.25/N) |
|---|---|---|---|
| 10 | 0.5175 | 0.1738 | 0.1581 |
| 100 | 0.4890 | 0.0451 | 0.0500 |
| 1000 | 0.5004 | 0.0160 | 0.0158 |
| 10000 | 0.5007 | 0.0049 | 0.0050 |

The match tightens as `N` grows — 40 repeats is itself a small sample, so the smaller-`N` rows are
noisier estimates of `σ` than the larger ones, but every row lands in the right neighborhood, and
the **1/√N law** is unmistakable: `σ` roughly halves every time `N` quadruples. This is the same
scaling Chapter 22 (tomography) leans on when it asks how many shots are needed to pin down an
unknown state to a given precision — quadrupling the shot budget only buys one more bit of
precision, never more.

A practical reading rule follows directly: about 95% of repeated runs land within `±1.96σ` of the
true mean. At `N = 1000`, `p = 0.5`, `σ_count = √(1000 · 0.25) ≈ 15.8`, so a 95% band is roughly
`±31` counts around 500 — which is exactly why every one of §9.2's six 1000-shot splits above
landed between 481 and 525, comfortably inside that band, and why none of them landed on 500
exactly.

## 9.5 Reading a histogram honestly

`SimulationResult.sortedCounts` sorts its entries by the binary state string — for the fixed-width,
zero-padded labels this app always produces, that is the same as sorting numerically ascending,
with **qubit 0 as the leftmost, most-significant bit** of each label (the same convention as every
other chapter). `HistogramView` draws one bar per entry, and — worth knowing before trusting a bar
chart by eye — scales every bar's height against the *largest* count present, not against the shot
total (`HistogramView.swift`, `maxBarHeight * CGFloat(entry.count) / CGFloat(maxCount)`). A
histogram with a single, dominant outcome always shows a full-height bar for it, whatever the
actual count; the printed number above each bar, not its height relative to the shot total, is the
number to read.

More important: `counts` (and therefore `sortedCounts`) contains **no entry at all** for an
outcome that never came up in that batch of shots — it is not a zero stored for every possible
outcome, only the ones actually observed. A 2-qubit Bell circuit (`H` on `q0`, `CX` from `q0` to
`q1`) measured for 500 shots produced exactly two histogram bars, not four with two of them at
zero height:

```text
Bell histogram (500 shots): ["|00⟩: 238", "|11⟩: 262"]   key count: 2
```

`|01⟩` and `|10⟩` are absent because the Bell state assigns them exactly zero probability
(Chapter 12's subject); but the same absence would show up for any outcome rare enough to miss
entirely at a given shot count, zero probability or not. §9.7 and the exercises return to this
distinction. Contrast this with the State Vector panel above the histogram, which uses a display
cutoff of its own (`ResultsView.swift`, `probabilities[index] > 1e-9`) to hide near-zero rows —
a display choice, not a reflection of what `counts` stores, since `probabilities` always has one
entry per basis state, computed exactly by `run()`, with nothing sampled or omitted.

## 9.6 Unequal splits

Every example so far has been a fair coin. `RY(θ)` (Chapter 7 §7.7) gives a state with probability
`cos²(θ/2)` of measuring `0` for any θ, so sweeping θ and reading counts back recovers a known
curve from statistics alone — this app's smallest possible rehearsal for tomography (Chapter 22):

```text
theta 0.0000  cos²(theta/2) 1.0000  run() p0 1.0000  measured p0 (10000 shots) 1.0000
theta 0.7854  cos²(theta/2) 0.8536  run() p0 0.8536  measured p0 (10000 shots) 0.8583
theta 1.5708  cos²(theta/2) 0.5000  run() p0 0.5000  measured p0 (10000 shots) 0.5043
theta 2.3562  cos²(theta/2) 0.1464  run() p0 0.1464  measured p0 (10000 shots) 0.1473
theta 3.1416  cos²(theta/2) 0.0000  run() p0 0.0000  measured p0 (10000 shots) 0.0000
```

`run()`'s exact probability and the formula agree to every printed digit, as they must; the
10,000-shot measured column tracks both closely but not exactly — the small gaps (0.8536 vs.
0.8583, 0.5000 vs. 0.5043) are §9.4's jitter, right where `σ ≈ 0.005` at this shot count predicts
they should be.

## 9.7 What this simulator's measurement does and doesn't do

A few implementation facts worth knowing before relying on any measurement result:

- `measure(shots:)` is a plain loop over `runAndMeasure()` (`QuantumCircuit.swift`), and
  `runAndMeasure()` calls `run()` fresh each time. Every single shot is an **independent full
  replay** of the circuit from `|0…0⟩` — there is no notion of running the circuit once and
  sampling from it repeatedly, and each shot's collapse is discarded the moment the loop moves on.
- There is no mid-circuit measurement and no classical register: a placed gate always runs before
  any measurement, never after one conditioned on an earlier outcome. Measurement is always the
  last, terminal step.
- Collapse itself — the state actually changing, not just an outcome being reported — is only
  observable by calling `StateVector.measure()` directly in code (§9.3); neither **Measure** in the
  app nor `measure(shots:)` in code exposes a collapsed state, only the tally of outcomes.
- The app's **Shots** stepper is bounded `1...10000` in steps of 100 (`ResultsView.swift`), so the
  10,000-shot column above is the practical ceiling reachable by tapping — reaching further, as the
  first exercise below does, means writing code.

## Build it in the app

● Every step starts from **Clear** with **Qubits: 1** unless noted.

1. **A fair coin, measured** — arm **H** (Pauli / Hadamard section), tap `q0`. State Vector panel:
   `p=0.500` on both rows. Set **Shots: 1000**, tap **Measure** four or five times in a row without
   touching the circuit: the two histogram bars reshuffle within roughly `500 ± 30` each time,
   while the panel's `p=` values never move — the panel is exact (§9.2), the histogram is sampled.
2. **Fewer shots, more noise** — step **Shots** down to 100 and **Measure** repeatedly: visibly
   wider swings than step 1's. Step up to **10,000** (the stepper's cap) and **Measure** again: the
   split visibly tightens toward even — the same 1/√N law as §9.4's table, watched live.
3. **RX(π/2)** — Clear, arm **RX** (Rotation section — arms at θ = π/2), tap `q0`, **Measure** —
   roughly even, like `H`, but reached from a different state (Chapter 7 §7.7).
4. **An unequal split** — Clear, arm **RY**, tap `q0`. Tap the placed tile to open its popover and
   drag θ to `1.047` (≈ π/3): the panel now reads `p≈0.750/0.250`. **Measure** at 10,000 shots and
   read the histogram back: an actual run gave `7463`/`2537` — close to, not exactly, the panel's
   75/25 split.
5. **A histogram with holes** — **Qubits: 2**. Arm **H**, tap `q0`'s column-0 cell; arm **CX**
   (Multi-qubit section), tap `q0` then `q1` in column 1. **Measure**: exactly two bars,
   `|00⟩` and `|11⟩` — `|01⟩` and `|10⟩` never appear, not as zero-height bars but as bars that
   don't exist (§9.5). Recall the leftmost-qubit convention: `|00⟩` means `q0=0, q1=0`.
6. **Basis dependence, once more** — Clear, **H** at `q0`. **Measure**: roughly even. Add a second
   **H** at column 1 and **Measure** again: the histogram collapses to all-`"0"` — the same
   circuit as Chapter 8 step 7, now read as a statement about measurement rather than about phase.

Two genuine limits, not a missing-capability paragraph: the **Shots** stepper tops out at 10,000 in
steps of 100, so anything beyond that (the first "Try it yourself" exercise) has to be done in
code; and there is no way to watch a single shot's collapse in the UI — the app only ever reports
the finished tally, never the intermediate state `StateVector.measure()` exposes in code.

## Run it in code

Every snippet below was run with `RunCodeSnippet` against
`SwiftQiskitApp/SwiftQiskitApp/CircuitModel.swift`.

```swift
import SwiftQiskitCore

// 9.2 — run() is deterministic; measure(shots:) jitters
let qcH = QuantumCircuit(qubits: 1); qcH.h(0)
print("run() call 1:", qcH.run().probabilities)
print("run() call 2:", qcH.run().probabilities)
for i in 1...6 {
    print("measure(shots: 1000) run \(i):", qcH.measure(shots: 1000).sortedCounts)
}

// 9.3 — a single outcome, and collapse you can actually inspect
let outcome = qcH.runAndMeasure()
print("runAndMeasure() outcome:", outcome)

var sv = qcH.run()
print("before measure():", sv.probabilities)
let idx = sv.measure()
print("measure() returned:", idx, "probabilities now:", sv.probabilities)
let idx2 = sv.measure()
print("measure() again returned:", idx2, "probabilities still:", sv.probabilities)
```

```text
run() call 1: [0.4999999999999999, 0.4999999999999999]
run() call 2: [0.4999999999999999, 0.4999999999999999]
measure(shots: 1000) run 1: [(state: "0", count: 504), (state: "1", count: 496)]
measure(shots: 1000) run 2: [(state: "0", count: 503), (state: "1", count: 497)]
measure(shots: 1000) run 3: [(state: "0", count: 516), (state: "1", count: 484)]
measure(shots: 1000) run 4: [(state: "0", count: 481), (state: "1", count: 519)]
measure(shots: 1000) run 5: [(state: "0", count: 508), (state: "1", count: 492)]
measure(shots: 1000) run 6: [(state: "0", count: 525), (state: "1", count: 475)]
runAndMeasure() outcome: 1
before measure(): [0.4999999999999999, 0.4999999999999999]
measure() returned: 1 probabilities now: [0.0, 1.0]
measure() again returned: 1 probabilities still: [0.0, 1.0]
```

Re-running the six `measure(shots: 1000)` lines will not reproduce these exact splits — only the
same rough 470–530 neighborhood §9.4 predicts.

The shots-jitter statistics table (§9.4), 40 repeats at each of four shot counts:

```swift
import SwiftQiskitCore
import Foundation

let qc = QuantumCircuit(qubits: 1); qc.h(0)

for n in [10, 100, 1000, 10000] {
    var fracs: [Double] = []
    for _ in 0..<40 {
        let c = qc.measure(shots: n).counts["0"] ?? 0
        fracs.append(Double(c) / Double(n))
    }
    let mean = fracs.reduce(0, +) / Double(fracs.count)
    let sd = sqrt(fracs.map { pow($0 - mean, 2) }.reduce(0, +) / Double(fracs.count - 1))
    let predicted = sqrt(0.25 / Double(n))
    print(String(format: "N %6d  mean %.4f  observed sd %.4f  predicted sd %.4f", n, mean, sd, predicted))
}

let sigmaCount = sqrt(1000.0 * 0.5 * 0.5)
print(String(format: "N=1000 count sigma %.2f, 95%% band +-%.1f counts around 500", sigmaCount, 1.96 * sigmaCount))
```

```text
N     10  mean 0.5175  observed sd 0.1738  predicted sd 0.1581
N    100  mean 0.4890  observed sd 0.0451  predicted sd 0.0500
N   1000  mean 0.5004  observed sd 0.0160  predicted sd 0.0158
N  10000  mean 0.5007  observed sd 0.0049  predicted sd 0.0050
N=1000 count sigma 15.81, 95% band +-31.0 counts around 500
```

The `RY(θ)` unequal-split sweep (§9.6), `run()`'s exact probability and a 10,000-shot measured
fraction against `cos²(θ/2)`:

```swift
import SwiftQiskitCore
import Foundation

for k in 0...4 {
    let theta = Double(k) * Double.pi / 4
    let qc = QuantumCircuit(qubits: 1); qc.ry(theta, 0)
    let p0 = qc.run().probabilities[0]
    let counts = qc.measure(shots: 10000).counts
    let measured0 = Double(counts["0"] ?? 0) / 10000.0
    print(String(format: "theta %.4f  cos^2(theta/2) %.4f  run() p0 %.4f  measured p0 (10000 shots) %.4f",
                 theta, pow(cos(theta / 2), 2), p0, measured0))
}

let qcThird = QuantumCircuit(qubits: 1); qcThird.ry(1.047, 0)
print("theta=1.047 (~pi/3) probabilities:", qcThird.run().probabilities)
print("theta=1.047 measure(shots: 10000):", qcThird.measure(shots: 10000).sortedCounts)
```

```text
theta 0.0000  cos^2(theta/2) 1.0000  run() p0 1.0000  measured p0 (10000 shots) 1.0000
theta 0.7854  cos^2(theta/2) 0.8536  run() p0 0.8536  measured p0 (10000 shots) 0.8583
theta 1.5708  cos^2(theta/2) 0.5000  run() p0 0.5000  measured p0 (10000 shots) 0.5043
theta 2.3562  cos^2(theta/2) 0.1464  run() p0 0.1464  measured p0 (10000 shots) 0.1473
theta 3.1416  cos^2(theta/2) 0.0000  run() p0 0.0000  measured p0 (10000 shots) 0.0000
theta=1.047 (~pi/3) probabilities: [0.7500855372985351, 0.24991446270146492]
theta=1.047 measure(shots: 10000): [(state: "0", count: 7463), (state: "1", count: 2537)]
```

Finally, the app-path walkthrough behind steps 1, 5, and 6 above, driving `CircuitBuilder` directly
and formatting histogram rows the way `HistogramView` labels its bars (helpers first defined in
Chapter 7's and Chapter 8's "Run it in code"):

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

func histogramRows(_ result: SimulationResult) -> [String] {
    result.sortedCounts.map { "|\($0.state)⟩: \($0.count)" }
}

var bell = CircuitBuilder(qubitCount: 2)
bell.place(.h, qubits: [0], column: 0)
bell.place(.cx, qubits: [0, 1], column: 1)
let bellState = bell.buildCircuit().run()
print("Bell panel:", panelRows(bellState, qubits: 2))
let bellResult = bell.buildCircuit().measure(shots: 500)
print("Bell histogram (500 shots):", histogramRows(bellResult), "key count:", bellResult.counts.keys.count)

var plus = CircuitBuilder(qubitCount: 1)
plus.place(.h, qubits: [0], column: 0)
print("|+> Z-basis 1000 shots:", histogramRows(plus.buildCircuit().measure(shots: 1000)))

var plusXBasis = CircuitBuilder(qubitCount: 1)
plusXBasis.place(.h, qubits: [0], column: 0)
plusXBasis.place(.h, qubits: [0], column: 1)
print("|+> X-basis 1000 shots:", histogramRows(plusXBasis.buildCircuit().measure(shots: 1000)))
```

```text
Bell panel: ["|00⟩: 0.7071067811865475  (p=0.500)", "|11⟩: 0.7071067811865475  (p=0.500)"]
Bell histogram (500 shots): ["|00⟩: 238", "|11⟩: 262"] key count: 2
|+> Z-basis 1000 shots: ["|0⟩: 483", "|1⟩: 517"]
|+> X-basis 1000 shots: ["|0⟩: 1000"]
```

Both match steps 5 and 6 above; a re-run of the shot-based lines will land close to, but not
exactly on, these numbers.

## Try it yourself

1. The app's **Shots** stepper stops at 10,000. Continue the §9.4 table out to 100,000 shots in
   code and describe what happens to the spread.
   <details><summary>Answer</summary>The 1/√N law keeps holding: `σ = √(0.25/100000) ≈ 0.00158`,
   roughly a third of the 10,000-shot row's `0.0049`. Running it gives a fraction within a few
   thousandths of 0.5, tighter than anything reachable by tapping **Measure** in the app, since
   100,000 is beyond the stepper's 10,000 cap.</details>

2. A histogram bar is missing for a particular outcome. Does that prove the outcome's true
   probability is exactly zero?
   <details><summary>Answer</summary>No. `counts` only ever holds keys for outcomes that actually
   occurred in that batch of shots (§9.5) — an outcome with a small but nonzero probability can
   easily miss entirely at a low shot count, the same way a fair coin can miss "heads" in three
   flips. The Bell state's `|01⟩` and `|10⟩` really are exactly zero (Chapter 12), but the only way
   to tell a true zero from an unlucky miss is to check `run().probabilities` directly, which
   reports every basis state's exact probability with nothing sampled.</details>

3. Roughly how many shots would it take to reliably tell `p = 0.50` from `p = 0.51` apart by
   measurement alone?
   <details><summary>Answer</summary>The two probabilities differ by only 0.01, so `σ` needs to be
   well under that gap to separate them confidently. At `N = 10,000`, `σ ≈ 0.005` (§9.4's table) —
   barely two standard deviations away from the 0.01 gap, meaning the two would still be hard to
   distinguish reliably even at the app's shot cap. Telling them apart with real confidence needs
   `N` in the hundreds of thousands, underlining how expensive small biases are to measure.</details>

4. Calling `sv.measure()` twice in a row on the same `StateVector` always returns the same index
   (§9.3), yet calling `qc.measure(shots: 1000)` twice on the same `QuantumCircuit` gives different
   splits (§9.2). Why isn't that a contradiction?
   <details><summary>Answer</summary>The two calls measure different things. `sv.measure()` a
   second time re-measures an *already-collapsed* state, which is why it's stuck. `measure(shots:)`
   never re-measures anything — each of its shots calls `runAndMeasure()`, which replays the
   *original, uncollapsed* circuit from scratch and discards that shot's collapse before starting
   the next one (§9.7). Every shot starts fresh; only within a single shot is the outcome
   fixed.</details>

---
[← Chapter 8](08-Interference.md) · [Contents](../../INTRODUCTION.md) · [Chapter 10 →](10-Superposition.md)
