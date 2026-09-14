# Chapter 12 — Entanglement: Bell and GHZ

> Why the Bell state's failure to factor (Chapter 11 §11.6) is more than an algebraic curiosity:
> correlated measurement outcomes with no locally-detectable signal, reduced Bloch vectors that
> collapse to the sphere's center, and the same recipe extended non-adjacently to a 3-qubit GHZ
> state.

| | |
|---|---|
| Playground page | [`07Entanglement`](../../../SwiftQiskit/PlaygroundDocs/07ENTANGLEMENTHELP.md) |
| In the app | ● — every step below is tappable |
| Library APIs | `QuantumCircuit.h/x/z/cx`, `measure(shots:)`/`SimulationResult.sortedCounts`, `CNOTGate.matrix(qubits:control:target:)`, `apply(_:)`, `BlochVector(_:qubit:)` |
| Prerequisites | Chapters 5, 9, 10, 11 |

## 12.1 Why entanglement matters

Four earlier chapters have been quietly deferring to this one. Chapter 5 §5.1 showed a reduced
Bloch vector shorter than 1 and put off explaining it. Chapter 7 §7.9 placed a lone `CX` as an
explicit teaser for "Chapter 12's territory." Chapter 9 noted that the Bell state's `|01⟩` and
`|10⟩` are exactly zero, not merely rare, and again deferred. And Chapter 11 §11.5–11.6 proved
two negative results about `⊗` — it cannot build the entangling *gate*, and it cannot build the
entangled *state* — without saying what either fact means for anyone actually running the
circuit. This chapter is where those four threads land.

Stated once in plain language before any numbers appear: two qubits are **entangled** when their
measurement outcomes are perfectly correlated — whichever value one comes up with, the other is
forced to match — while each qubit, read on its own, still looks like a fair coin. Chapter 11
§11.6 proved this algebraically (no `v ⊗ w` factorization exists for the Bell state); this chapter
shows what that means experimentally, and the through-line every section below returns to is:
**the marginal probabilities cannot tell an entangled state from a plain product state — only the
joint distribution can.** `|++⟩ = h(0); h(1)` is the running control case: identical 50/50
marginals to the Bell state's, but no correlation between the two qubits at all.

Entanglement is not a curiosity kept for its own sake — it is the resource the rest of this book
spends. Teleportation (Chapter 18) moves a qubit's state across an entangled pair instead of
moving the qubit; the 3-qubit error-correcting code (Chapter 19) fans one logical qubit out across
three physical ones with the same `cx` recipe used here; the CHSH test (Chapter 20) and the
density-matrix view of a reduced state (Chapter 21 §21.\*) both build directly on what this
chapter establishes.

What this chapter does *not* establish is worth stating plainly, since perfectly correlated
outcomes are easy to over-read: on their own, they are not evidence of anything specifically
quantum. Two coins sealed in envelopes before being separated reproduce §12.3's "only `00` and
`11` ever appear" pattern exactly, with no quantum mechanics involved at all. What rules out that
classical explanation is measuring in *rotated* bases and comparing the results against a
provable classical ceiling — Chapter 20's CHSH inequality, where a Bell pair's `S = 2√2` exceeds
the classical bound of `S = 2`. Chapter 12 establishes the correlation and its geometry; Chapter
20 establishes that no classical account can reproduce it. And §12.6 below rules out the
most common misreading directly: no-signalling means this correlation carries no message between
the two qubits, so nothing in this chapter is faster-than-light communication.

The two-part technical story — one statistical, one geometric — is visible with tools already in
hand: `measure(shots:)` (Chapter 9) and `BlochVector` (Chapters 5, 10), applied to the entangling
gate Chapter 11 §11.5 singled out as the one thing `⊗` cannot build: `cx`.

| § | What happens |
|---|---|
| 12.2 | Building the Bell state one gate at a time, watching the state vector change at each stage |
| 12.3 | Correlation in the shot counts: `01`/`10` have exactly zero probability, contrasted with `\|++⟩` |
| 12.4 | Reduced Bloch spheres: both qubits collapse to the sphere's center |
| 12.5 | The other three Bell states, reached from `\|Φ⁺⟩` by local taps |
| 12.6 | Local gates can neither create nor destroy entanglement — the no-signalling principle |
| 12.7 | The GHZ state: extending the recipe to 3 qubits with a non-adjacent `cx` |

This chapter also names, plainly, a limit that shapes every section below: neither the app nor the
package can measure a single qubit, or measure mid-circuit. `measure(shots:)`
(`QuantumCircuit.swift`) always samples the *whole* register at once, via `runAndMeasure()`. So
"measure q0 and watch q1 collapse" is never observed directly here — it is inferred from the joint
`00`/`11` counts (§12.3) and from marginal probabilities computed from them, the same way it would
be inferred from any real experiment's statistics.

## 12.2 Building the Bell state

`h(0)` alone spreads amplitude across `|00⟩` and `|10⟩` — one qubit in superposition, the other
still pinned at `0`, exactly Chapter 10's single-qubit case:

```text
h(0) only: |00⟩: 0.7071067811865475   |10⟩: 0.7071067811865475
probabilities: [0.4999999999999999, 0.0, 0.4999999999999999, 0.0]
```

`cx(0, 1)` — control q0, target q1 — then flips q1 wherever q0 reads `1`, moving all the amplitude
sitting on `|10⟩` over to `|11⟩` and leaving `|00⟩` untouched:

```text
h(0); cx(0,1): |00⟩: 0.7071067811865475   |11⟩: 0.7071067811865475
probabilities: [0.4999999999999999, 0.0, 0.0, 0.4999999999999999]
amp |00⟩: 0.7071067811865475
amp |11⟩: 0.7071067811865475
```

This is `|Φ⁺⟩ = (|00⟩ + |11⟩)/√2`, the Bell state Chapter 11 spent a section proving cannot be
written as any product `v ⊗ w`. The `0.4999999999999999` in the probabilities, not a clean `0.5`,
is the same floating-point residue Chapters 8–11 have all flagged: one `±1/√2` amplitude squared
leaves about `1e-16` of rounding, not a bug.

## 12.3 Correlation, not local randomness

Measuring the Bell state 1000 times gives only two outcomes:

```text
Bell measurement counts (1000 shots):
  |00⟩: 512  (51.2%)
  |11⟩: 488  (48.8%)
```

`01` and `10` do not appear — not because they are rare, but because their probability is exactly
zero. Each qubit read alone is a fair coin (its marginal, summing over the other qubit's two
values, is `[0.5, 0.5]`), but the two coins are not independent: whichever value q0 comes up with,
q1 always matches it. Contrast this with `|++⟩` (`h(0); h(1)`), which has the *same* 50/50 marginal
on each qubit individually, but no such correlation — all four outcomes appear, in roughly equal
numbers:

```text
|++⟩ probabilities: [0.2499999999999999, 0.2499999999999999, 0.2499999999999999, 0.2499999999999999]
|++⟩ measurement counts (1000 shots):
  |00⟩: 258
  |01⟩: 244
  |10⟩: 234
  |11⟩: 264

Bell q0 marginal [P(0), P(1)]: [0.4999999999999999, 0.4999999999999999]
Bell q1 marginal [P(0), P(1)]: [0.4999999999999999, 0.4999999999999999]
|++⟩ q0 marginal [P(0), P(1)]: [0.4999999999999998, 0.4999999999999998]
```

Same marginals, completely different joint behavior — the marginal alone cannot distinguish an
entangled state from a product one; only the joint probabilities (or, as here, the shot counts)
can. This is the same distinction Chapter 11 §11.6 drew algebraically (`α₀₀α₁₁ = α₀₁α₁₀` holds for
`|++⟩`, fails for the Bell state); this section is that fact restated as something measurable.

## 12.4 Bloch spheres of an entangled pair

`BlochVector(state, qubit:)` (Chapters 5, 10) computes a *reduced* single-qubit vector by summing
over the other qubit's basis configurations — a partial trace. For the Bell state, both qubits'
reduced vectors collapse to the sphere's center:

```text
Bell qubit 0 card: x +0.000  y +0.000  z +0.000  θ 1.571 rad  |r| 0.000
Bell qubit 1 card: x +0.000  y +0.000  z +0.000  θ 1.571 rad  |r| 0.000
```

against `|++⟩`'s two independent, fully-defined `|+⟩` states:

```text
|++⟩ qubit 0 card: x +1.000  y +0.000  z +0.000  θ 1.571 rad
|++⟩ qubit 1 card: x +1.000  y +0.000  z +0.000  θ 1.571 rad
```

`|r| = 0` is the visual signature Chapter 5's Display button was built to show: a qubit that is
part of an entangled pair has no single point on the sphere's surface that describes it alone.
This is not a missing measurement — it is the correct answer. Any pure single-qubit state has
`|r| = 1`; a reduced vector strictly inside the sphere is only possible when the qubit is entangled
with something outside the picture.

## 12.5 The four Bell states

`|Φ⁺⟩` is one of four maximally-entangled 2-qubit states, all reachable from it by tapping a
single local gate:

| State | Recipe | Probabilities |
|---|---|---|
| `\|Φ⁺⟩` | `h(0); cx(0,1)` | `\|00⟩` 0.500, `\|11⟩` 0.500 |
| `\|Φ⁻⟩` | `+ z(0)` | `\|00⟩` 0.500, `\|11⟩` 0.500 |
| `\|Ψ⁺⟩` | `+ x(1)` | `\|01⟩` 0.500, `\|10⟩` 0.500 |
| `\|Ψ⁻⟩` | `+ x(1); z(0)` | `\|01⟩` 0.500, `\|10⟩` 0.500 |

Verified:

```text
Phi+ (h(0);cx(0,1)) probabilities: [0.4999999999999999, 0.0, 0.0, 0.4999999999999999]
Phi- (+z(0)) probabilities:        [0.4999999999999999, 0.0, 0.0, 0.4999999999999999]
Psi+ (+x(1)) probabilities:        [0.0, 0.4999999999999999, 0.4999999999999999, 0.0]
Psi- (+x(1);z(0)) probabilities:   [0.0, 0.4999999999999999, 0.4999999999999999, 0.0]
```

`|Φ⁻⟩`'s probabilities are identical to `|Φ⁺⟩`'s — `z(0)` only flips the relative sign between the
`|00⟩` and `|11⟩` amplitudes, a two-qubit echo of Chapter 8's "Z hides" result: the state genuinely
changes (`|11⟩`'s amplitude goes from `+0.7071` to `-0.7071`), but nothing in a probability, a
histogram, or a `|r|` reading shows it. All four states give `|r| = 0` on both qubits — every Bell
state is equally entangled, differing only in which pair of basis labels carries the amplitude and
what relative phase sits between them.

## 12.6 Local gates can't create or destroy entanglement

Chapter 11 §11.4's mixed-product identity, `(A⊗B)(x⊗y) = (Ax)⊗(By)`, has a physical reading: any
gate built as `A ⊗ B` — which is every single-qubit gate in the palette, applied to just one qubit
— acts on that qubit alone and cannot touch the other qubit's reduced state at all. Checked
directly: appending `x`, `h`, `z`, or `s` to q1 of an already-built Bell state leaves q0's card and
marginal exactly where they were:

```text
No-signalling check: local gates on q1 of the Bell state
  after x(1): q0 card: x +0.000  y +0.000  z +0.000  θ 1.571 rad  |r| 0.000  q0 marginal: [0.4999999999999999, 0.4999999999999999]
  after h(1): q0 card: x +0.000  y +0.000  z +0.000  θ 1.571 rad  |r| 0.000  q0 marginal: [0.4999999999999998, 0.4999999999999998]
  after z(1): q0 card: x +0.000  y +0.000  z +0.000  θ 1.571 rad  |r| 0.000  q0 marginal: [0.4999999999999999, 0.4999999999999999]
  after s(1): q0 card: x +0.000  y +0.000  z +0.000  θ 1.571 rad  |r| 0.000  q0 marginal: [0.4999999999999999, 0.4999999999999999]
```

This is the **no-signalling principle**: no gate applied only to q1 can change anything an observer
looking only at q0 could detect, however the joint state is entangled. It is also why entanglement,
once created, cannot be undone by acting on one qubit alone — undoing it takes the same kind of
gate that created it. Running the Bell recipe forward and then immediately backward, `cx(0,1)`
again followed by `h(0)`, returns exactly to `|00⟩`:

```text
h(0); cx(0,1); cx(0,1); h(0) amplitudes: [0.9999999999999998, 0.0, 0.0, 0.0]
```

## 12.7 The GHZ state

The Bell recipe extends past two qubits by chaining a further `cx` from the same control. On 3
qubits, `h(0); cx(0,1)` produces an intermediate state that is already entangled, but only between
q0 and q1 — q2 stays fixed at `0` in every surviving term:

```text
after h(0); cx(0,1):
|000⟩: 0.7071067811865475   |110⟩: 0.7071067811865475
```

Adding `cx(0, 2)` — control q0, target q2, **skipping over q1** — pulls q2 into the same
correlation:

```text
after +cx(0,2):
|000⟩: 0.7071067811865475   |111⟩: 0.7071067811865475
probabilities: [0.4999999999999999, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.4999999999999999]
```

This is `|GHZ⟩ = (|000⟩ + |111⟩)/√2`. `cx(0, 2)` is a genuinely non-adjacent CNOT — its matrix
comes from `CNOTGate.matrix(qubits:control:target:)`'s general permutation construction, not a
fixed adjacent-pair 4×4 embedded via `⊗` — and it is not the only wiring that reaches this state.
Chaining adjacent pairs instead, `cx(0,1); cx(1,2)`, lands on the identical amplitudes:

```text
alternate wiring cx(0,1);cx(1,2) amplitudes:      [0.7071067811865475, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.7071067811865475]
non-adjacent wiring cx(0,1);cx(0,2) amplitudes:    [0.7071067811865475, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.7071067811865475]
max amplitude diff: 0.0
```

Neither wiring is "the" correct one — both produce the same three-way correlation, just built by
different control/target pairs. Measurement shows the same all-or-nothing pattern as the Bell
state, now across three qubits, and every qubit's reduced Bloch vector collapses to the center:

```text
GHZ measurement counts (1000 shots):
  |000⟩: 480
  |111⟩: 520
GHZ qubit 0 card: x +0.000  y +0.000  z +0.000  θ 1.571 rad  |r| 0.000
GHZ qubit 1 card: x +0.000  y +0.000  z +0.000  θ 1.571 rad  |r| 0.000
GHZ qubit 2 card: x +0.000  y +0.000  z +0.000  θ 1.571 rad  |r| 0.000
```

One caution carried over from the playground page: the finale trick from §12.2's alternate
construction, `apply(CNOTGate.matrix)` in place of `.cx(0, 1)`, only works because `CNOTGate.matrix`
is a fixed 4×4 and `apply(_:)` requires an exact `2ⁿ×2ⁿ` match (`QuantumCircuit.swift`) — it is a
drop-in for `.cx(0, 1)` on a 2-qubit circuit only, and would trap immediately on the 3-qubit GHZ
circuit above.

```text
Bell via apply(CNOTGate.matrix) probabilities: [0.4999999999999999, 0.0, 0.0, 0.4999999999999999]
```

## Build it in the app

● Every step starts from **Clear** unless noted. As throughout Chapters 10–14, qubit 0 is the
leftmost bit in every label.

1. **Build the Bell state** — Set **Qubits: 2**. Arm **H** (Pauli / Hadamard section), tap `q0` in
   column 0. Panel: `|00⟩: p=0.500`, `|10⟩: p=0.500` (§12.2). Arm **CX** (Multi-qubit section), tap
   `q0` then `q1` in column 1. Panel: `|00⟩: p=0.500`, `|11⟩: p=0.500`.
2. **Measure it** — Set **Shots: 1000**, tap **Measure**: two bars, roughly even, and nothing
   elsewhere; re-tapping **Measure** jitters the split (§12.3).
3. **Watch it collapse** — Tap **Display**, pick **Steps** and `q0`: the sphere starts at the pole
   (`|0⟩`), swings to the `+x` equator after `H`, then collapses to the center after `CX`. Switch
   to **Final**: both qubits read `|r| = 0.000` (§12.4).
4. **The other three Bell states** — Arm **Z**, tap `q0`'s column-2 cell: panel unchanged
   (`|00⟩: p=0.500`, `|11⟩: p=0.500`) — `|Φ⁻⟩`'s sign flip is invisible to the panel (§12.5). Undo
   that tap (context menu → Delete), then arm **X** and tap `q1`'s column-2 cell instead: panel now
   reads `|01⟩: p=0.500`, `|10⟩: p=0.500` — `|Ψ⁺⟩`.
5. **No-signalling, by tapping** — Starting from step 1's Bell circuit, arm any single-qubit gate
   (**X** works) and tap `q1`'s column-2 cell only. Tap **Display → Final** and select `q0`: still
   `|r| = 0.000`, unchanged by a gate that never touched it (§12.6).
6. **Undo it** — From step 1's circuit, arm **CX** again and repeat `q0` then `q1` in column 2, then
   arm **H** and tap `q0` in column 3. Panel collapses to a single row: `|00⟩: p=1.000`.
7. **The GHZ state** — Clear, set **Qubits: 3**. Arm **H**, tap `q0` in column 0. Arm **CX**, tap
   `q0` then `q1` in column 1 — panel: `|000⟩: p=0.500`, `|110⟩: p=0.500`. Arm **CX** again, tap
   `q0` then `q2` in column 2 — the connector spans across the `q1` wire without touching it
   (§12.7). Panel: `|000⟩: p=0.500`, `|111⟩: p=0.500`. **Display → Final**: all three qubits read
   `|r| = 0.000`.

Two limits worth stating plainly, not glossed over: neither the app nor the package can measure a
single qubit or measure mid-circuit — every Measure tap samples the whole register at once, so
step 2's and step 7's "collapse" is read off the joint counts, never watched directly on one wire.
And the State Vector panel has no marginal-probability readout — §12.3's per-qubit marginals, the
number that makes "locally a fair coin, jointly perfectly correlated" precise, are a code-only
computation.

## Run it in code

Every snippet below was run with `RunCodeSnippet` against
`SwiftQiskitApp/SwiftQiskitApp/CircuitModel.swift`.

```swift
import SwiftQiskitCore

// 12.2 -- Bell state, staged: h(0) alone, then +cx(0,1)
let hOnly = QuantumCircuit(qubits: 2)
hOnly.h(0)
let hOnlyState = hOnly.run()
print("h(0) only:")
print(hOnlyState)
print("probabilities:", hOnlyState.probabilities)

let bellCircuit = QuantumCircuit(qubits: 2)
bellCircuit.h(0)
bellCircuit.cx(0, 1)
let bellState = bellCircuit.run()
print("\nh(0); cx(0,1):")
print(bellState)
print("probabilities:", bellState.probabilities)
print("amp |00>:", bellState[0])
print("amp |11>:", bellState[3])

let bellResult = bellCircuit.measure(shots: 1000)
print("\nBell measurement counts (1000 shots):")
for (state, count) in bellResult.sortedCounts {
    let pct = Double(count) / Double(bellResult.shots) * 100
    print("  |\(state)>: \(count)  (\(String(format: "%.1f", pct))%)")
}

// contrast: |++> -- h(0); h(1)
let plusplus = QuantumCircuit(qubits: 2)
plusplus.h(0); plusplus.h(1)
let ppState = plusplus.run()
print("\n|++> probabilities:", ppState.probabilities)
let ppResult = plusplus.measure(shots: 1000)
print("|++> measurement counts (1000 shots):")
for (state, count) in ppResult.sortedCounts {
    print("  |\(state)>: \(count)")
}

func marginal(_ probs: [Double], qubits: Int, qubit: Int) -> [Double] {
    var result = [0.0, 0.0]
    for i in 0..<probs.count {
        let bit = (i >> (qubits - 1 - qubit)) & 1
        result[bit] += probs[i]
    }
    return result
}

print("\nBell q0 marginal [P(0), P(1)]:", marginal(bellState.probabilities, qubits: 2, qubit: 0))
print("Bell q1 marginal [P(0), P(1)]:", marginal(bellState.probabilities, qubits: 2, qubit: 1))
print("|++> q0 marginal [P(0), P(1)]:", marginal(ppState.probabilities, qubits: 2, qubit: 0))
```

```text
h(0) only:
|0⟩: 0.7071067811865475
|1⟩: 0.0
|10⟩: 0.7071067811865475
|11⟩: 0.0
probabilities: [0.4999999999999999, 0.0, 0.4999999999999999, 0.0]

h(0); cx(0,1):
|0⟩: 0.7071067811865475
|1⟩: 0.0
|10⟩: 0.0
|11⟩: 0.7071067811865475
probabilities: [0.4999999999999999, 0.0, 0.0, 0.4999999999999999]
amp |00>: 0.7071067811865475
amp |11>: 0.7071067811865475

Bell measurement counts (1000 shots):
  |00>: 512  (51.2%)
  |11>: 488  (48.8%)

|++> probabilities: [0.2499999999999999, 0.2499999999999999, 0.2499999999999999, 0.2499999999999999]
|++> measurement counts (1000 shots):
  |00>: 258
  |01>: 244
  |10>: 234
  |11>: 264

Bell q0 marginal [P(0), P(1)]: [0.4999999999999999, 0.4999999999999999]
Bell q1 marginal [P(0), P(1)]: [0.4999999999999999, 0.4999999999999999]
|++> q0 marginal [P(0), P(1)]: [0.4999999999999998, 0.4999999999999998]
```

```swift
import SwiftQiskitCore

func card(_ bloch: BlochVector) -> String {
    var text = String(format: "x %+.3f  y %+.3f  z %+.3f  θ %.3f rad",
                       bloch.x, bloch.y, bloch.z, bloch.theta)
    if abs(bloch.magnitude - 1) > 1e-3 { text += String(format: "  |r| %.3f", bloch.magnitude) }
    return text
}

// 12.4 -- reduced Bloch vectors of the Bell state
let bell = QuantumCircuit(qubits: 2); bell.h(0); bell.cx(0, 1)
let bellState = bell.run()
for q in 0..<2 { print("Bell qubit \(q) card:", card(BlochVector(bellState, qubit: q))) }

let pp = QuantumCircuit(qubits: 2); pp.h(0); pp.h(1)
let ppState = pp.run()
for q in 0..<2 { print("|++> qubit \(q) card:", card(BlochVector(ppState, qubit: q))) }

// 12.5 -- the four Bell states, from |Phi+> by local X/Z taps
func describe(_ label: String, _ qc: QuantumCircuit) {
    let s = qc.run()
    print("\n\(label) probabilities:", s.probabilities)
    for q in 0..<2 { print("  qubit \(q) card:", card(BlochVector(s, qubit: q))) }
}

let phiPlus = QuantumCircuit(qubits: 2); phiPlus.h(0); phiPlus.cx(0, 1)
describe("Phi+ (h(0);cx(0,1))", phiPlus)

let phiMinus = QuantumCircuit(qubits: 2); phiMinus.h(0); phiMinus.cx(0, 1); phiMinus.z(0)
describe("Phi- (+z(0))", phiMinus)

let psiPlus = QuantumCircuit(qubits: 2); psiPlus.h(0); psiPlus.cx(0, 1); psiPlus.x(1)
describe("Psi+ (+x(1))", psiPlus)

let psiMinus = QuantumCircuit(qubits: 2); psiMinus.h(0); psiMinus.cx(0, 1); psiMinus.x(1); psiMinus.z(0)
describe("Psi- (+x(1);z(0))", psiMinus)

// 12.6 -- no-signalling: local gates on q1 leave q0's card and marginal unchanged
func marginal(_ probs: [Double], qubits: Int, qubit: Int) -> [Double] {
    var result = [0.0, 0.0]
    for i in 0..<probs.count {
        let bit = (i >> (qubits - 1 - qubit)) & 1
        result[bit] += probs[i]
    }
    return result
}

print("\nNo-signalling check: local gates on q1 of the Bell state")
let gatesToTry: [(String, (QuantumCircuit) -> Void)] = [
    ("x", { $0.x(1) }), ("h", { $0.h(1) }), ("z", { $0.z(1) }), ("s", { $0.s(1) })
]
for (name, gate) in gatesToTry {
    let qc = QuantumCircuit(qubits: 2); qc.h(0); qc.cx(0, 1); gate(qc)
    let s = qc.run()
    print("  after \(name)(1): q0 card:", card(BlochVector(s, qubit: 0)), " q0 marginal:", marginal(s.probabilities, qubits: 2, qubit: 0))
}

// undoing entanglement: only the entangling gate itself reverses it
let undo = QuantumCircuit(qubits: 2); undo.h(0); undo.cx(0, 1); undo.cx(0, 1); undo.h(0)
print("\nh(0); cx(0,1); cx(0,1); h(0) amplitudes:", undo.run().amplitudes)
```

```text
Bell qubit 0 card: x +0.000  y +0.000  z +0.000  θ 1.571 rad  |r| 0.000
Bell qubit 1 card: x +0.000  y +0.000  z +0.000  θ 1.571 rad  |r| 0.000
|++> qubit 0 card: x +1.000  y +0.000  z +0.000  θ 1.571 rad
|++> qubit 1 card: x +1.000  y +0.000  z +0.000  θ 1.571 rad

Phi+ (h(0);cx(0,1)) probabilities: [0.4999999999999999, 0.0, 0.0, 0.4999999999999999]
  qubit 0 card: x +0.000  y +0.000  z +0.000  θ 1.571 rad  |r| 0.000
  qubit 1 card: x +0.000  y +0.000  z +0.000  θ 1.571 rad  |r| 0.000

Phi- (+z(0)) probabilities: [0.4999999999999999, 0.0, 0.0, 0.4999999999999999]
  qubit 0 card: x +0.000  y +0.000  z +0.000  θ 1.571 rad  |r| 0.000
  qubit 1 card: x +0.000  y +0.000  z +0.000  θ 1.571 rad  |r| 0.000

Psi+ (+x(1)) probabilities: [0.0, 0.4999999999999999, 0.4999999999999999, 0.0]
  qubit 0 card: x +0.000  y +0.000  z +0.000  θ 1.571 rad  |r| 0.000
  qubit 1 card: x +0.000  y +0.000  z +0.000  θ 1.571 rad  |r| 0.000

Psi- (+x(1);z(0)) probabilities: [0.0, 0.4999999999999999, 0.4999999999999999, 0.0]
  qubit 0 card: x +0.000  y +0.000  z +0.000  θ 1.571 rad  |r| 0.000
  qubit 1 card: x +0.000  y +0.000  z +0.000  θ 1.571 rad  |r| 0.000

No-signalling check: local gates on q1 of the Bell state
  after x(1): q0 card: x +0.000  y +0.000  z +0.000  θ 1.571 rad  |r| 0.000  q0 marginal: [0.4999999999999999, 0.4999999999999999]
  after h(1): q0 card: x +0.000  y +0.000  z +0.000  θ 1.571 rad  |r| 0.000  q0 marginal: [0.4999999999999998, 0.4999999999999998]
  after z(1): q0 card: x +0.000  y +0.000  z +0.000  θ 1.571 rad  |r| 0.000  q0 marginal: [0.4999999999999999, 0.4999999999999999]
  after s(1): q0 card: x +0.000  y +0.000  z +0.000  θ 1.571 rad  |r| 0.000  q0 marginal: [0.4999999999999999, 0.4999999999999999]

h(0); cx(0,1); cx(0,1); h(0) amplitudes: [0.9999999999999998, 0.0, 0.0, 0.0]
```

```swift
import SwiftQiskitCore

func card(_ bloch: BlochVector) -> String {
    var text = String(format: "x %+.3f  y %+.3f  z %+.3f  θ %.3f rad",
                       bloch.x, bloch.y, bloch.z, bloch.theta)
    if abs(bloch.magnitude - 1) > 1e-3 { text += String(format: "  |r| %.3f", bloch.magnitude) }
    return text
}

// 12.7 -- GHZ via non-adjacent cx(0,2)
let ghz = QuantumCircuit(qubits: 3)
ghz.h(0)
ghz.cx(0, 1)
var ghzState = ghz.run()
print("after h(0); cx(0,1):")
print(ghzState)

ghz.cx(0, 2)
ghzState = ghz.run()
print("\nafter +cx(0,2):")
print(ghzState)
print("probabilities:", ghzState.probabilities)

let ghzResult = ghz.measure(shots: 1000)
print("\nGHZ measurement counts (1000 shots):")
for (state, count) in ghzResult.sortedCounts {
    print("  |\(state)>: \(count)")
}

for q in 0..<3 { print("GHZ qubit \(q) card:", card(BlochVector(ghzState, qubit: q))) }

// alternate wiring: cx(0,1); cx(1,2) reaches the same state
let ghzAlt = QuantumCircuit(qubits: 3)
ghzAlt.h(0)
ghzAlt.cx(0, 1)
ghzAlt.cx(1, 2)
let ghzAltState = ghzAlt.run()
print("\nalternate wiring cx(0,1);cx(1,2) amplitudes:", ghzAltState.amplitudes)
print("non-adjacent wiring cx(0,1);cx(0,2) amplitudes: ", ghzState.amplitudes)
let maxDiff = zip(ghzAltState.amplitudes, ghzState.amplitudes).map { ($0 - $1).magnitude }.max() ?? 0
print("max amplitude diff:", maxDiff)

// the apply(CNOTGate.matrix) drop-in only works on a 2-qubit circuit
let bellViaMatrix = QuantumCircuit(qubits: 2)
bellViaMatrix.h(0)
bellViaMatrix.apply(CNOTGate.matrix)
print("\nBell via apply(CNOTGate.matrix) probabilities:", bellViaMatrix.run().probabilities)
```

```text
after h(0); cx(0,1):
|0⟩: 0.7071067811865475
|1⟩: 0.0
|10⟩: 0.0
|11⟩: 0.0
|100⟩: 0.0
|101⟩: 0.0
|110⟩: 0.7071067811865475
|111⟩: 0.0

after +cx(0,2):
|0⟩: 0.7071067811865475
|1⟩: 0.0
|10⟩: 0.0
|11⟩: 0.0
|100⟩: 0.0
|101⟩: 0.0
|110⟩: 0.0
|111⟩: 0.7071067811865475
probabilities: [0.4999999999999999, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.4999999999999999]

GHZ measurement counts (1000 shots):
  |000>: 480
  |111>: 520
GHZ qubit 0 card: x +0.000  y +0.000  z +0.000  θ 1.571 rad  |r| 0.000
GHZ qubit 1 card: x +0.000  y +0.000  z +0.000  θ 1.571 rad  |r| 0.000
GHZ qubit 2 card: x +0.000  y +0.000  z +0.000  θ 1.571 rad  |r| 0.000

alternate wiring cx(0,1);cx(1,2) amplitudes: [0.7071067811865475, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.7071067811865475]
non-adjacent wiring cx(0,1);cx(0,2) amplitudes:  [0.7071067811865475, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.7071067811865475]
max amplitude diff: 0.0

Bell via apply(CNOTGate.matrix) probabilities: [0.4999999999999999, 0.0, 0.0, 0.4999999999999999]
```

Finally, the app-path walkthrough behind every "Build it in the app" step above, driving
`CircuitBuilder` directly and formatting output exactly as `ResultsView`'s panel and
`BlochSphereView`'s card do (helpers first defined in Chapters 8–11's "Run it in code"):

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

// step 1: Bell state h(0) col0, cx(0,1) col1
var b1 = CircuitBuilder(qubitCount: 2)
b1.place(.h, qubits: [0], column: 0)
b1.place(.cx, qubits: [0, 1], column: 1)
let b1state = b1.buildCircuit().run()
print("step 1 panel:", panelRows(b1state, qubits: 2))

// step 3: Steps mode trajectory for q0 -- after column 0 (H only), and after column 1 (full)
let b1AfterH = b1.buildCircuit(throughColumn: 0).run()
let b1Final = b1.buildCircuit(throughColumn: 1).run()
print("step 3 q0 after H:", card(BlochVector(b1AfterH, qubit: 0)))
print("step 3 q0 after CX (final):", card(BlochVector(b1Final, qubit: 0)))
for q in 0..<2 { print("step 3 qubit \(q) final card:", card(BlochVector(b1Final, qubit: q))) }

// step 4: the four Bell states by adding Z on q0 / X on q1 in column 2
var b4phiMinus = CircuitBuilder(qubitCount: 2)
b4phiMinus.place(.h, qubits: [0], column: 0)
b4phiMinus.place(.cx, qubits: [0, 1], column: 1)
b4phiMinus.place(.z, qubits: [0], column: 2)
print("step 4 Phi- panel:", panelRows(b4phiMinus.buildCircuit().run(), qubits: 2))

var b4psiPlus = CircuitBuilder(qubitCount: 2)
b4psiPlus.place(.h, qubits: [0], column: 0)
b4psiPlus.place(.cx, qubits: [0, 1], column: 1)
b4psiPlus.place(.x, qubits: [1], column: 2)
print("step 4 Psi+ panel:", panelRows(b4psiPlus.buildCircuit().run(), qubits: 2))

// step 5: no-signalling by tapping -- gate on q1 only, q0's Final card
var b5 = CircuitBuilder(qubitCount: 2)
b5.place(.h, qubits: [0], column: 0)
b5.place(.cx, qubits: [0, 1], column: 1)
b5.place(.x, qubits: [1], column: 2)
let b5state = b5.buildCircuit().run()
print("step 5 q0 card (should stay at center):", card(BlochVector(b5state, qubit: 0)))

// step 6: undo -- append cx then h to return to |00>
var b6 = CircuitBuilder(qubitCount: 2)
b6.place(.h, qubits: [0], column: 0)
b6.place(.cx, qubits: [0, 1], column: 1)
b6.place(.cx, qubits: [0, 1], column: 2)
b6.place(.h, qubits: [0], column: 3)
print("step 6 panel:", panelRows(b6.buildCircuit().run(), qubits: 2))

// step 7: GHZ, non-adjacent cx(0,2)
var b7 = CircuitBuilder(qubitCount: 3)
b7.place(.h, qubits: [0], column: 0)
b7.place(.cx, qubits: [0, 1], column: 1)
b7.place(.cx, qubits: [0, 2], column: 2)
let b7state = b7.buildCircuit().run()
print("step 7 panel:", panelRows(b7state, qubits: 3))
for q in 0..<3 { print("step 7 qubit \(q) card:", card(BlochVector(b7state, qubit: q))) }
```

```text
step 1 panel: ["|00⟩: 0.7071067811865475  (p=0.500)", "|11⟩: 0.7071067811865475  (p=0.500)"]
step 3 q0 after H: x +1.000  y +0.000  z +0.000  θ 1.571 rad
step 3 q0 after CX (final): x +0.000  y +0.000  z +0.000  θ 1.571 rad  |r| 0.000
step 3 qubit 0 final card: x +0.000  y +0.000  z +0.000  θ 1.571 rad  |r| 0.000
step 3 qubit 1 final card: x +0.000  y +0.000  z +0.000  θ 1.571 rad  |r| 0.000
step 4 Phi- panel: ["|00⟩: 0.7071067811865475  (p=0.500)", "|11⟩: -0.7071067811865475  (p=0.500)"]
step 4 Psi+ panel: ["|01⟩: 0.7071067811865475  (p=0.500)", "|10⟩: 0.7071067811865475  (p=0.500)"]
step 5 q0 card (should stay at center): x +0.000  y +0.000  z +0.000  θ 1.571 rad  |r| 0.000
step 6 panel: ["|00⟩: 0.9999999999999998  (p=1.000)"]
step 7 panel: ["|000⟩: 0.7071067811865475  (p=0.500)", "|111⟩: 0.7071067811865475  (p=0.500)"]
step 7 qubit 0 card: x +0.000  y +0.000  z +0.000  θ 1.571 rad  |r| 0.000
step 7 qubit 1 card: x +0.000  y +0.000  z +0.000  θ 1.571 rad  |r| 0.000
step 7 qubit 2 card: x +0.000  y +0.000  z +0.000  θ 1.571 rad  |r| 0.000
```

## Try it yourself

1. Build a 4-qubit GHZ state and predict its two nonzero states before running.
   <details><summary>Answer</summary>`\|0000⟩` and `\|1111⟩`, each ≈ 0.500 — one `h` and three
   `cx`s from qubit 0.</details>

2. Why does `01` never appear in the Bell state's measurement counts, even though `|++⟩` gives all
   four outcomes and both states have the same 50/50 marginal on each qubit?
   <details><summary>Answer</summary>The marginal only says what each qubit looks like read in
   isolation, and it is identical for both states (§12.3). The joint probability is what differs:
   `|++⟩`'s `α₀₀α₁₁ = α₀₁α₁₀` (Chapter 11 §11.6, a genuine product state) puts equal probability on
   all four joint outcomes, while the Bell state's amplitude sits entirely on `\|00⟩`/`\|11⟩`, so
   `\|01⟩` and `\|10⟩` get exactly zero, not merely a small share.</details>

3. Does applying `z(0)` to a Bell state change anything visible in the histogram or the Bloch
   cards?
   <details><summary>Answer</summary>No — verified in §12.5, `\|Φ⁻⟩`'s probabilities and both
   qubits' `\|r⟩=0` cards are identical to `\|Φ⁺⟩`'s. The state has genuinely changed (the `\|11⟩`
   amplitude's sign flips from `+0.7071` to `-0.7071`), but a relative phase between two terms of
   equal size is invisible to any measurement in the computational basis — the same "Z hides"
   result from Chapter 8, now at two-qubit scale.</details>

4. Can any single-qubit gate applied only to q1 change what an observer measuring only q0 would
   see?
   <details><summary>Answer</summary>No — the no-signalling check in §12.6 tries `x`, `h`, `z`, and
   `s` on q1 of a Bell state and finds q0's reduced Bloch card and marginal probabilities unchanged
   every time. This follows from Chapter 11 §11.4's mixed-product identity: a gate applied to q1
   alone is `I₂ ⊗ B` for some `B`, and `(I₂ ⊗ B)` acting on an entangled state can only ever change
   the state's description of q1, never q0's reduced state — the mathematical form of the physical
   principle that nothing you do locally can send a signal to a system you're not touching.</details>

---
[← Chapter 11](11-TensorProducts.md) · [Contents](../../INTRODUCTION.md) · [Chapter 13 →](13-Deutsch.md)
