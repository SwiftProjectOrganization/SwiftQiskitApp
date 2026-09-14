# Chapter 13 — Oracles and Phase Kickback: Deutsch's Algorithm

> The first quantum algorithm, read as a phase-manipulation pipeline: an oracle that looks like it
> writes to an ancilla actually marks the query qubit with a sign, and a single closing `H`
> converts that sign into a certain answer — one query where a classical machine needs two.

| | |
|---|---|
| Playground page | [`10DeutschExample`](../../../SwiftQiskit/PlaygroundDocs/10DEUTSCHHELP.md) |
| In the app | ● — all four oracles are `x`/`cx` combinations; the kickback shows as a sign flip in the panel and a 180° azimuth swing in Display → Steps |
| Library APIs | `QuantumCircuit.h/x/cx`, `.amplitudes`/`.probabilities`, `measure(shots:)`, `BlochVector(_:qubit:)`, `Ket.minus`/postfix `†` |
| Prerequisites | Chapters 8, 9, 12 |

## 13.1 Why one query is enough

You are handed a black-box function f: {0,1} → {0,1} and asked only one thing about it: is it
**constant** (f(0) = f(1)) or **balanced** (f(0) ≠ f(1))? Classically there is no way around
evaluating f twice — knowing f(0) alone says nothing about f(1). Deutsch's algorithm (David
Deutsch, 1985) answers with a single query to a quantum oracle. It was the first demonstration
that a quantum computer could do something a classical one provably could not do as cheaply, and
its 1-bit shape is the direct ancestor of Deutsch–Jozsa and Bernstein–Vazirani (Chapter 14) and,
further out, the query structure Grover (Chapter 15) and Shor (Chapter 17) both build on. One
historical detail worth being precise about: Deutsch's 1985 circuit was only *conclusive* half the
time (§13.7 rebuilds it exactly and shows why); the fully deterministic version below, ancilla
prepared in `|−⟩` rather than `|0⟩`, is the 1998 refinement usually credited to Cleve, Ekert,
Macchiavello, and Mosca. It is the version every textbook — and this chapter — calls "Deutsch's
algorithm."

The mechanism, not the history, is this chapter's subject. The algorithm never asks the oracle
"what is f(0)?" or "what is f(1)?" — every question like that costs a query. Instead it arranges
for the oracle to write f's two values as two *signs* on a single superposed state, using the
phase-kickback trick from Chapter 8: mark a branch, then recombine with an `H`, and the mark
becomes a probability. Sections 13.2–13.6 below build that pipeline stage by stage; §13.5 pauses
to check a fact the kickback depends on but rarely gets named — the two qubits never entangle, so
"the phase sits on q0" is literally true, not a figure of speech; and §13.7 rebuilds the *wrong*
version, ancilla in `|0⟩`, to show concretely what breaks without it.

| § | What happens |
|---|---|
| 13.2 | The four 1-bit oracles, built from `x`/`cx` |
| 13.3 | Why the ancilla starts in `\|−⟩`: the eigenvalue that powers the kickback |
| 13.4 | Phase kickback, stage by stage — value becomes sign |
| 13.5 | The register never entangles — the phase genuinely sits on one qubit |
| 13.6 | The closing `H`: sign becomes a certain bit |
| 13.7 | The wrong ancilla — Deutsch's 1985 original, conclusive half the time |
| 13.8 | Shot statistics, and the honest accounting of what one query buys |

## 13.2 The four 1-bit oracles

There are exactly four functions {0,1} → {0,1}, and every oracle `U_f: |x⟩|y⟩ → |x⟩|y ⊕ f(x)⟩` is
buildable from gates already in the palette:

| f | Type | Gates |
|---|---|---|
| f(x) = 0 | constant | (none — identity) |
| f(x) = 1 | constant | `x(1)` |
| f(x) = x | balanced | `cx(0, 1)` |
| f(x) = 1−x | balanced | `cx(0, 1)` then `x(1)` |

Qubit 0 is the input register, qubit 1 the ancilla — and, as throughout Chapters 10–14, qubit 0 is
the most-significant (leftmost) bit of every label. Note the input qubit is only ever a *control*:
`U_f` never changes `|x⟩` directly. That single fact is what makes reading the outcome off q0 as
"f's answer" valid at all — nothing else in the circuit touches it except the two `H`s that bracket
the oracle.

## 13.3 Preparing the phase register

Two gates before the oracle ever runs: `x(1)` puts the ancilla at `|1⟩`, then `h(0); h(1)` reaches

```text
|+⟩|−⟩ = ( |00⟩ − |01⟩ + |10⟩ − |11⟩ ) / 2
```

Verified: `after h(0),h(1): [0.4999999999999999, -0.4999999999999999, 0.4999999999999999,
-0.4999999999999999]`. The query qubit needs `|+⟩` for the reason Chapter 8 §8.2 gives: a relative
phase needs *two* non-zero amplitudes to attach to, and `|+⟩` is the state with the least
commitment to one of them. The ancilla needs `|−⟩` for a sharper reason: `|−⟩` is an eigenvector of
`X` with eigenvalue −1,

```text
<-|X|-> = -0.9999999999999998
```

(computed via the Dirac API — `Ket.minus`, postfix `†`, `Bra * Ket` — exactly as Chapter 8's §8.7
first used it). Since XOR-ing `f(x)` into the ancilla means applying `X` to it `f(x)` times, and
`X|−⟩ = −|−⟩`, every application of `X` the oracle makes to the ancilla multiplies the *whole
branch* by −1 without changing the ancilla's state at all:

```text
|x⟩|−⟩  -->  (−1)^f(x) |x⟩|−⟩
```

The value `f(x)` — a bit the algorithm is trying to learn — has just become a sign. That
substitution is the entire trick; everything after this point is about what happens to that sign.

## 13.4 Phase kickback, stage by stage

Following `f(x) = x` (the `cx(0,1)` oracle) one gate at a time:

```text
after x(1):        [0.0, 1.0, 0.0, 0.0]                                              -- |01⟩
after h(0),h(1):    [0.4999999999999999, -0.4999999999999999,
                      0.4999999999999999, -0.4999999999999999]                        -- |+⟩|−⟩
after cx(0,1):      [0.4999999999999999, -0.4999999999999999,
                     -0.4999999999999999, 0.4999999999999999]                         -- |−⟩|−⟩
after final h(0):   [0.0, 0.0, 0.7071067811865474, -0.7071067811865474]               -- |1⟩|−⟩
```

The `cx` line is the kickback happening: the ancilla's own amplitudes are untouched
(`−0.4999…, 0.4999…` both before and after — same numbers, same order), but the `|1⟩` branch of the
query qubit (where `f(x) = 1`) has picked up a minus sign it didn't have a moment ago. `|+⟩` has
become `|−⟩` — all from an oracle that, read naively, looks like it only ever touches q1.

Running the same "before the final `H`" snapshot for all four oracles makes the constant/balanced
split visible directly in the sign pattern:

| Oracle | Amplitudes `\|00⟩ \|01⟩ \|10⟩ \|11⟩` | Phase type |
|---|---|---|
| f(x) = 0 | `+0.5000 −0.5000 +0.5000 −0.5000` | global — both branches scaled by +1 |
| f(x) = 1 | `−0.5000 +0.5000 −0.5000 +0.5000` | global — both branches scaled by −1 |
| f(x) = x | `+0.5000 −0.5000 −0.5000 +0.5000` | relative — branches scaled oppositely |
| f(x) = 1−x | `−0.5000 +0.5000 +0.5000 −0.5000` | relative — branches scaled oppositely |

All four rows give identical probabilities, `[0.25, 0.25, 0.25, 0.25]` — nothing measurable has
happened yet, exactly Chapter 8 §8.2's point that a phase is invisible right up until something
recombines it. But the two constant rows and the two balanced rows are related in a way worth
naming precisely: `f(x)=1`'s amplitudes are `f(x)=0`'s negated *entirely* — a single overall sign
flipping both branches equally, which is a **global** phase (Chapter 8 §8.2) and physically
nothing at all: the state is still `|+⟩|−⟩` up to a sign no measurement can ever recover. The two
balanced rows, by contrast, each have their two branches scaled by *opposite* signs — a
**relative** phase between the branches, which is exactly the ingredient interference can use.
That is the whole constant-vs-balanced distinction, read off as one column of a table before a
single shot has been fired.

## 13.5 The register never entangles

`cx` sits in the middle of this circuit, and Chapter 12 built exactly this gate into the Bell
state. It is worth checking directly that nothing analogous happens here. Reduced Bloch vectors of
both qubits through every stage of the `f(x)=x` run:

```text
after x(1): q0 x +0.000 y +0.000 z +1.000 |r| 1.000   q1 x +0.000 y +0.000 z -1.000 |r| 1.000
after h,h:  q0 x +1.000 y +0.000 z +0.000 |r| 1.000   q1 x -1.000 y +0.000 z +0.000 |r| 1.000
after cx:   q0 x -1.000 y +0.000 z +0.000 |r| 1.000   q1 x -1.000 y +0.000 z +0.000 |r| 1.000
after H:    q0 x +0.000 y +0.000 z -1.000 |r| 1.000   q1 x -1.000 y +0.000 z +0.000 |r| 1.000
```

`|r| = 1.000` on both qubits at every stage, including immediately after `cx` — the exact opposite
of Chapter 12 §12.4's Bell-state reading, `|r| = 0` on both qubits the moment `cx` lands. The
ancilla's card doesn't even move: `x −1.000` at every stage from `h(1)` onward, parked at `|−⟩`
while the oracle nominally acts on it. What moves is q0's card alone — `+z` → `+x` → `−x` → `−z`
for this balanced oracle — and because `|r|` never drops, that trajectory is a complete
description of q0 by itself, not a shadow of a larger entangled state the way Chapter 12's reduced
vectors were. This is what makes "the phase sits on q0" true in the strongest sense available: q0's
reduced state really is the whole story for that qubit.

The constant case moves through the same two points and back: q0 goes `+z → +x → +x → +z` (no
sign flip at the oracle step, since `f(x)=0` applies no `X` to the ancilla and therefore no `X`
eigenvalue to kick back), landing exactly where it started.

## 13.6 The closing H: sign becomes a certain bit

The final `h(0)` is not a fifth ingredient — it is the same recombination Chapter 8 §8.4 already
derived, now with the oracle supplying the phase instead of a tapped `Z`. Chapter 8 §8.6's exact
identity, `P(0) = (1 + x)/2` where `x` is the Bloch x-coordinate immediately before the closing
`H`, applies unchanged: q0 sits at `x = +1` after a constant oracle and `x = −1` after a balanced
one (§13.5's table), giving `P(0) = 1` or `P(0) = 0` — not approximately, exactly, because `x` is
exactly `±1` here, never partway between.

Running all four oracles through the full circuit confirms both verdicts land on the certain
extremes:

```text
oracle       P(q0=1)  verdict     expected
f(x) = 0     0.0000   constant    constant
f(x) = 1     0.0000   constant    constant
f(x) = x     1.0000   balanced    balanced
f(x) = 1−x   1.0000   balanced    balanced
```

Two checks confirm the closing `H` is doing all the work, not the oracle by itself. First, deleting
it: measuring right after the oracle, with no final `H`, gives a flat ~25% split on all four
outcomes for every one of the four oracles — the phase is completely real (§13.4) and completely
unreadable in the Z basis without a basis change, exactly Chapter 8 §8.7's lesson applied here.
Second, the single-qubit skeleton: strip the ancilla away and the query qubit alone runs
`H; (phase); H` — Chapter 8 §8.4's `H;Z;H` for the balanced case (deterministic flip to `|1⟩`) and
plain `H;H` for the constant case (identity, back to `|0⟩`) — the same two outcomes, derived
without a second qubit at all. The oracle's only job is to manufacture that one sign; Chapter 8
already worked out everything that happens to it next.

## 13.7 The wrong ancilla — Deutsch's 1985 original

Deutsch's 1985 circuit prepared the ancilla in `|0⟩`, not `|−⟩`. Rebuilding it exactly —
`h(0); cx(0,1); h(0)`, no `x(1)` — shows both why it works at all and why it needed the 1998 fix.
For the balanced oracle `f(x) = x`, the `cx` step doesn't kick back a phase; it entangles:

```text
after h(0):  q0 x +1.000 y +0.000 z +0.000 |r| 1.000
after cx:    q0 |r| 0.000   q1 |r| 0.000   probs [0.4999999999999999, 0.0, 0.0, 0.4999999999999999]
```

`|r| = 0` on both qubits, probabilities `[0.5, 0, 0, 0.5]` — this is exactly Chapter 12's Bell
state, `|Φ⁺⟩`. Where the correct circuit keeps a clean single-qubit phase on q0, the `|0⟩`-ancilla
circuit spends the query creating entanglement instead. The final `h(0)` then gives:

```text
constant f=0:   probs [1.0, 0, 0, 0]     P(q0=1) = 0.0
constant f=1:   probs [0, 1.0, 0, 0]     P(q0=1) = 0.0
balanced f=x:   probs [0.25, 0.25, 0.25, 0.25]   P(q0=1) = 0.5
balanced f=1−x: probs [0.25, 0.25, 0.25, 0.25]   P(q0=1) = 0.5
```

A constant oracle still gives a certain answer — `P(q0=1) = 0` exactly, every time — but a balanced
oracle now gives a coin flip. Read carefully, this is not useless: since *no* constant oracle can
ever produce `q0 = 1`, seeing `q0 = 1` is still proof the function is balanced, with certainty.
Seeing `q0 = 0` is inconclusive — it happens always for constant functions and half the time for
balanced ones. This is Deutsch's actual 1985 result: right whenever it commits to an answer, but
conclusive only about half the time. Preparing the ancilla in `|1⟩` alone (`x(1)` with no `h(1)`)
or `|+⟩` alone (`h(1)` with no `x(1)`) fares no better — both also land on flat `0.25` probabilities
for the balanced oracle, confirming it is specifically `|−⟩`, not "any non-`|0⟩` ancilla," that
makes the deterministic version work.

## 13.8 Shot statistics, and what one query actually buys

Sampling the correct (`|−⟩`-ancilla) circuit 1000 times per oracle shows the same story
statistically. The leftmost bit — qubit 0, the verdict — never varies; the ancilla, still parked at
`|−⟩`, is a fair coin, because it carried the phase and nothing else:

```text
f(x) = 1 (constant), 1000 shots:
  00: 523
  01: 477

f(x) = x (balanced), 1000 shots:
  10: 483
  11: 517
```

Both splits are the expected roughly-even jitter (Chapter 9) — a re-run lands close to, but not
exactly on, 500/500, and either way the leftmost bit is unanimous.

Stated plainly, so the algorithm's power isn't over-read: one query buys exactly one bit, the
parity `f(0) ⊕ f(1)` — 0 for constant, 1 for balanced. It does not reveal `f(0)` or `f(1)`
individually; if you need either of those, phase kickback doesn't help you, because a single-branch
measurement of an XOR gives no way to separate the two summands back out. Trading the values you
could ask for, for a global property neither of them alone would answer, is the shape every later
algorithm in this book — Deutsch–Jozsa's n-bit version (Chapter 14), Grover's marked-item search
(Chapter 15) — repeats at larger scale.

## Build it in the app

● Every step starts from **Clear**, **Qubits: 2**, unless noted. Qubit 0 is the leftmost bit in
every label, as throughout Chapters 10–14.

1. **Prepare the phase register** — Arm **X** (Pauli section), tap `q1` in column 0. Arm **H**, tap
   `q0` then `q1`, both in column 1. Panel: four rows at `p=0.250` — `|00⟩: +0.500`, `|01⟩: −0.500`,
   `|10⟩: +0.500`, `|11⟩: −0.500` (§13.3's `|+⟩|−⟩`).
2. **Query the oracle for f(x) = x** — Arm **CX** (Multi-qubit section), tap `q0` then `q1` in
   column 2. Panel probabilities are unchanged (`p=0.250` on all four rows), but two signs have
   flipped: `|10⟩` and `|11⟩` swap sign relative to step 1 — the kickback, visible as a sign change
   with zero visible change in probability (§13.4).
3. **Watch it on the sphere** — Tap **Display**, pick **Steps**, qubit picker on `q0`: `Start` at
   the `|0⟩` pole, `Col 1` (column 0's `X` only touches q1, so q0 hasn't moved) is still at the
   pole, `Col 2` (after the `H`s) has swung to `+x`, then `Col 3` — after the `CX` oracle — has
   swung to `−x`. Switch the picker to `q1`: north pole (`z +1.000`) at `Start`, flips to the
   south pole (`z −1.000`) at `Col 1` (its own `X`), swings to `−x` at `Col 2` (its own `H`), and
   stays there — untouched by the `CX` that's nominally acting on it. Switch to **Final**: both
   qubits read `|r| = 1.000` — no entanglement, unlike Chapter 12's Bell-state step 3 (§13.5).
4. **Close with H, get a certain answer** — Arm **H**, tap `q0` in column 3. Panel collapses to two
   rows, `|10⟩: p=0.500`, `|11⟩: p=0.500` — both with q0 = 1. Set **Shots: 1000**, tap **Measure**:
   only `10` and `11` appear, each near 50% (§13.8). Tap **Display → Final**: q0's card is at the
   south pole, `z −1.000`.
5. **Swap the oracle** — Use the tile's context menu to delete the `CX` at column 2. For **f(x) =
   1** (constant), arm **X** and tap `q1`'s column-2 cell instead; Measure again: only `00` and
   `01` appear — leftmost bit always `0`. For **f(x) = 0** (constant), leave column 2 empty
   entirely; same `00`/`01` split. For **f(x) = 1−x** (balanced), place **CX** at column 2 *and*
   **X** on `q1` at column 3 (they can't share a column), moving the closing **H** to column 4;
   Measure: only `10`/`11` appear, matching `f(x) = x`.
6. **Delete the closing H** — From step 4's circuit, delete the column-3 `H` tile. Measure 1000
   shots: all four outcomes appear in roughly equal numbers, for every oracle — the phase is real
   but unreadable without the basis change (§13.6).
7. **The wrong ancilla** — Clear. Arm **H**, tap `q0` in column 0 (skip the `X` on `q1` entirely —
   the ancilla starts at `|0⟩`). Arm **CX**, tap `q0` then `q1` in column 1. Tap **Display →
   Final**: both qubits read `|r| = 0.000` — this is Chapter 12's Bell state, reached by accident.
   Arm **H**, tap `q0` in column 2. Panel: four rows at flat `p=0.250` — compare against step 4's
   two clean rows for the same oracle (§13.7).

Two limits worth stating plainly: the app cannot measure q0 alone, so every verdict above is read
off the leftmost bit of the whole-register histogram, never watched in isolation; and there is no
way to hide the oracle from yourself the way a real black box would — the "single query" claim is
about the circuit's structure (one oracle tile, queried once), not about the app enforcing any
ignorance of what's inside it.

## Run it in code

Every snippet below was run with `RunCodeSnippet` against
`SwiftQiskitApp/SwiftQiskitApp/CircuitModel.swift`.

```swift
import SwiftQiskitCore

struct DeutschOracle {
    let name: String
    let isBalanced: Bool
    let apply: (QuantumCircuit) -> Void
}

let oracles: [DeutschOracle] = [
    DeutschOracle(name: "f(x) = 0  ", isBalanced: false) { _ in },
    DeutschOracle(name: "f(x) = 1  ", isBalanced: false) { $0.x(1) },
    DeutschOracle(name: "f(x) = x  ", isBalanced: true) { $0.cx(0, 1) },
    DeutschOracle(name: "f(x) = 1−x", isBalanced: true) { $0.cx(0, 1); $0.x(1) }
]

func deutschCircuit(oracle: (QuantumCircuit) -> Void) -> QuantumCircuit {
    let qc = QuantumCircuit(qubits: 2)
    qc.x(1)
    qc.h(0)
    qc.h(1)
    oracle(qc)
    qc.h(0)
    return qc
}

// 13.4 -- stage walk for f(x) = x
let walk = QuantumCircuit(qubits: 2)
walk.x(1)
print("after x(1):", walk.run().amplitudes)
walk.h(0); walk.h(1)
print("after h(0),h(1):", walk.run().amplitudes)
walk.cx(0, 1)
print("after cx(0,1):", walk.run().amplitudes)
walk.h(0)
print("after final h(0):", walk.run().amplitudes)

// 13.4 -- sign pattern after the oracle, before the final H, all four oracles
print("\nsign pattern after oracle (before final H):")
for oracle in oracles {
    let qc = QuantumCircuit(qubits: 2)
    qc.x(1); qc.h(0); qc.h(1)
    oracle.apply(qc)
    let s = qc.run()
    print("\(oracle.name): amps", s.amplitudes.map { String(format: "%+.4f", $0.real) }, "probs", s.probabilities)
}

// 13.6 -- verdict table
print("\noracle       P(q0=1)  verdict     expected")
for oracle in oracles {
    let qc = deutschCircuit(oracle: oracle.apply)
    let probs = qc.run().probabilities
    let pOne = probs[2] + probs[3]
    let verdict = pOne > 0.5 ? "balanced" : "constant"
    let expected = oracle.isBalanced ? "balanced" : "constant"
    print("\(oracle.name)   \(String(format: "%.4f", pOne))   \(verdict)    \(expected)")
}

// 13.3 -- the eigenvalue behind the kickback
var xMinus = Ket.minus
xMinus.apply(PauliXGate.matrix)
print("\n<-|X|-> =", Ket.minus† * xMinus)
```

```text
after x(1): [0.0, 1.0, 0.0, 0.0]
after h(0),h(1): [0.4999999999999999, -0.4999999999999999, 0.4999999999999999, -0.4999999999999999]
after cx(0,1): [0.4999999999999999, -0.4999999999999999, -0.4999999999999999, 0.4999999999999999]
after final h(0): [0.0, 0.0, 0.7071067811865474, -0.7071067811865474]

sign pattern after oracle (before final H):
f(x) = 0  : amps ["+0.5000", "-0.5000", "+0.5000", "-0.5000"] probs [0.2499999999999999, 0.2499999999999999, 0.2499999999999999, 0.2499999999999999]
f(x) = 1  : amps ["-0.5000", "+0.5000", "-0.5000", "+0.5000"] probs [0.2499999999999999, 0.2499999999999999, 0.2499999999999999, 0.2499999999999999]
f(x) = x  : amps ["+0.5000", "-0.5000", "-0.5000", "+0.5000"] probs [0.2499999999999999, 0.2499999999999999, 0.2499999999999999, 0.2499999999999999]
f(x) = 1−x: amps ["-0.5000", "+0.5000", "+0.5000", "-0.5000"] probs [0.2499999999999999, 0.2499999999999999, 0.2499999999999999, 0.2499999999999999]

oracle       P(q0=1)  verdict     expected
f(x) = 0     0.0000   constant    constant
f(x) = 1     0.0000   constant    constant
f(x) = x     1.0000   balanced    balanced
f(x) = 1−x   1.0000   balanced    balanced

<-|X|-> = -0.9999999999999998
```

```swift
import SwiftQiskitCore

func card(_ b: BlochVector) -> String {
    String(format: "x %+.3f  y %+.3f  z %+.3f  |r| %.3f", b.x, b.y, b.z, b.magnitude)
}

// 13.5 -- reduced Bloch vectors through every stage of the correct (|-> ancilla) circuit
let qcBal = QuantumCircuit(qubits: 2)
qcBal.x(1)
print("after x(1): q0", card(BlochVector(qcBal.run(), qubit: 0)), " q1", card(BlochVector(qcBal.run(), qubit: 1)))
qcBal.h(0); qcBal.h(1)
print("after h,h:  q0", card(BlochVector(qcBal.run(), qubit: 0)), " q1", card(BlochVector(qcBal.run(), qubit: 1)))
qcBal.cx(0, 1)
print("after cx:   q0", card(BlochVector(qcBal.run(), qubit: 0)), " q1", card(BlochVector(qcBal.run(), qubit: 1)))
qcBal.h(0)
print("after H:    q0", card(BlochVector(qcBal.run(), qubit: 0)), " q1", card(BlochVector(qcBal.run(), qubit: 1)))

// 13.7 -- the wrong ancilla, |0>: entanglement instead of kickback
let bad0 = QuantumCircuit(qubits: 2)
bad0.h(0)
print("\nwrong ancilla |0>, f(x)=x:")
print("after h(0): q0", card(BlochVector(bad0.run(), qubit: 0)))
bad0.cx(0, 1)
print("after cx:   q0", card(BlochVector(bad0.run(), qubit: 0)), " q1", card(BlochVector(bad0.run(), qubit: 1)), " probs", bad0.run().probabilities)
bad0.h(0)
let bad0Final = bad0.run()
print("after H:    probs", bad0Final.probabilities, " P(q0=1)", bad0Final.probabilities[2] + bad0Final.probabilities[3])

// wrong ancilla |0>, constant oracle -- still certain
let bad0Const = QuantumCircuit(qubits: 2)
bad0Const.h(0); bad0Const.h(0)
print("\nwrong ancilla |0>, f(x)=0: probs", { let c = QuantumCircuit(qubits: 2); c.h(0); c.h(0); return c.run().probabilities }())

// wrong ancilla |1> and |+> -- also non-deterministic on the balanced oracle
let bad1 = QuantumCircuit(qubits: 2)
bad1.x(1); bad1.h(0); bad1.cx(0, 1); bad1.h(0)
print("wrong ancilla |1>, f(x)=x: probs", bad1.run().probabilities)

let badPlus = QuantumCircuit(qubits: 2)
badPlus.h(0); badPlus.h(1); badPlus.cx(0, 1); badPlus.h(0)
print("wrong ancilla |+>, f(x)=x: probs", badPlus.run().probabilities)
```

```text
after x(1): q0 x +0.000  y +0.000  z +1.000  |r| 1.000   q1 x +0.000  y +0.000  z -1.000  |r| 1.000
after h,h:  q0 x +1.000  y +0.000  z +0.000  |r| 1.000   q1 x -1.000  y +0.000  z +0.000  |r| 1.000
after cx:   q0 x -1.000  y +0.000  z +0.000  |r| 1.000   q1 x -1.000  y +0.000  z +0.000  |r| 1.000
after H:    q0 x +0.000  y +0.000  z -1.000  |r| 1.000   q1 x -1.000  y +0.000  z +0.000  |r| 1.000

wrong ancilla |0>, f(x)=x:
after h(0): q0 x +1.000  y +0.000  z +0.000  |r| 1.000
after cx:   q0 x +0.000  y +0.000  z +0.000  |r| 0.000   q1 x +0.000  y +0.000  z +0.000  |r| 0.000  probs [0.4999999999999999, 0.0, 0.0, 0.4999999999999999]
after H:    probs [0.2499999999999999, 0.2499999999999999, 0.2499999999999999, 0.2499999999999999]  P(q0=1) 0.4999999999999998

wrong ancilla |0>, f(x)=0: probs [0.9999999999999996, 0.0, 0.0, 0.0]
wrong ancilla |1>, f(x)=x: probs [0.2499999999999999, 0.2499999999999999, 0.2499999999999999, 0.2499999999999999]
wrong ancilla |+>, f(x)=x: probs [0.4999999999999998, 0.4999999999999998, 0.0, 0.0]
```

```swift
import SwiftQiskitCore

func deutschCircuit(oracle: (QuantumCircuit) -> Void) -> QuantumCircuit {
    let qc = QuantumCircuit(qubits: 2)
    qc.x(1); qc.h(0); qc.h(1); oracle(qc); qc.h(0)
    return qc
}

// 13.8 -- shot counts for one constant and one balanced oracle
let constResult = deutschCircuit(oracle: { $0.x(1) }).measure(shots: 1000)
print("f(x)=1 (constant), 1000 shots:")
for (state, count) in constResult.sortedCounts { print("  \(state): \(count)") }

let balResult = deutschCircuit(oracle: { $0.cx(0, 1) }).measure(shots: 1000)
print("\nf(x)=x (balanced), 1000 shots:")
for (state, count) in balResult.sortedCounts { print("  \(state): \(count)") }

// 13.6 -- without the closing H, every oracle is a flat ~25% split
print("\nno final H, 1000 shots each:")
let oraclesNoH: [(String, (QuantumCircuit) -> Void)] = [
    ("f=0", { _ in }), ("f=1", { $0.x(1) }), ("f=x", { $0.cx(0,1) }), ("f=1-x", { $0.cx(0,1); $0.x(1) })
]
for (name, oracle) in oraclesNoH {
    let qc = QuantumCircuit(qubits: 2)
    qc.x(1); qc.h(0); qc.h(1); oracle(qc)
    print(name, qc.measure(shots: 1000).counts)
}
```

```text
f(x)=1 (constant), 1000 shots:
  00: 523
  01: 477

f(x)=x (balanced), 1000 shots:
  10: 483
  11: 517

no final H, 1000 shots each:
f=0 ["01": 225, "10": 264, "11": 242, "00": 269]
f=1 ["01": 236, "10": 248, "00": 262, "11": 254]
f=x ["01": 251, "10": 249, "00": 248, "11": 252]
f=1-x ["10": 255, "01": 240, "11": 254, "00": 251]
```

Re-running any of the four shot-count blocks above will land close to, but not exactly on, the
printed numbers — the app-visible splits are genuinely probabilistic (Chapter 9).

Finally, the app-path walkthrough behind every "Build it in the app" step, driving `CircuitBuilder`
directly and formatting output exactly as `ResultsView`'s panel and `BlochSphereView`'s card do
(helpers first defined in Chapters 7–8's "Run it in code"):

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

// steps 1-4: f(x) = x, column layout x(1)@0, h(0);h(1)@1, cx@2, h(0)@3
var b = CircuitBuilder(qubitCount: 2)
b.place(.x, qubits: [1], column: 0)
b.place(.h, qubits: [0], column: 1)
b.place(.h, qubits: [1], column: 1)
b.place(.cx, qubits: [0, 1], column: 2)
b.place(.h, qubits: [0], column: 3)

print("step 1 panel (after col 1):", panelRows(b.buildCircuit(throughColumn: 1).run(), qubits: 2))
print("step 2 panel (after oracle, col 2):", panelRows(b.buildCircuit(throughColumn: 2).run(), qubits: 2))
print("step 4 panel (final):", panelRows(b.buildCircuit().run(), qubits: 2))

for col in -1...3 {
    let label = col == -1 ? "Start" : "Col \(col + 1)"
    print(label, "q0:", card(BlochVector(b.buildCircuit(throughColumn: col).run(), qubit: 0)),
          " q1:", card(BlochVector(b.buildCircuit(throughColumn: col).run(), qubit: 1)))
}

// step 7: the wrong ancilla, |0>
var bBad = CircuitBuilder(qubitCount: 2)
bBad.place(.h, qubits: [0], column: 0)
bBad.place(.cx, qubits: [0, 1], column: 1)
bBad.place(.h, qubits: [0], column: 2)
print("\nstep 7 panel:", panelRows(bBad.buildCircuit().run(), qubits: 2))
let bBadFinal = bBad.buildCircuit().run()
for q in 0..<2 { print("step 7 q\(q) card:", card(BlochVector(bBadFinal, qubit: q))) }
```

```text
step 1 panel (after col 1): ["|00⟩: 0.4999999999999999  (p=0.250)", "|01⟩: -0.4999999999999999  (p=0.250)", "|10⟩: 0.4999999999999999  (p=0.250)", "|11⟩: -0.4999999999999999  (p=0.250)"]
step 2 panel (after oracle, col 2): ["|00⟩: 0.4999999999999999  (p=0.250)", "|01⟩: -0.4999999999999999  (p=0.250)", "|10⟩: -0.4999999999999999  (p=0.250)", "|11⟩: 0.4999999999999999  (p=0.250)"]
step 4 panel (final): ["|10⟩: 0.7071067811865474  (p=0.500)", "|11⟩: -0.7071067811865474  (p=0.500)"]
Start q0: x +0.000  y +0.000  z +1.000  |r| 1.000  q1: x +0.000  y +0.000  z +1.000  |r| 1.000
Col 1 q0: x +0.000  y +0.000  z +1.000  |r| 1.000  q1: x +0.000  y +0.000  z -1.000  |r| 1.000
Col 2 q0: x +1.000  y +0.000  z +0.000  |r| 1.000  q1: x -1.000  y +0.000  z +0.000  |r| 1.000
Col 3 q0: x -1.000  y +0.000  z +0.000  |r| 1.000  q1: x -1.000  y +0.000  z +0.000  |r| 1.000
Col 4 q0: x +0.000  y +0.000  z -1.000  |r| 1.000  q1: x -1.000  y +0.000  z +0.000  |r| 1.000

step 7 panel: ["|00⟩: 0.4999999999999999  (p=0.250)", "|01⟩: 0.4999999999999999  (p=0.250)", "|10⟩: 0.4999999999999999  (p=0.250)", "|11⟩: -0.4999999999999999  (p=0.250)"]
step 7 q0 card: x +0.000  y +0.000  z +0.000  |r| 0.000
step 7 q1 card: x +0.000  y +0.000  z +0.000  |r| 0.000
```

`Col 1` in the trajectory table above already includes column 0's `X` on `q1`, which is why q1
reads `z −1.000` (its `|1⟩` start) one column before its own `H` — the `Col N` label always means
"through column N−1," matching `BlochDisplayView`'s `Steps` mode exactly.

## Try it yourself

1. Which of the four oracles are balanced and which are constant, and how does that split show up
   in §13.4's sign-pattern table without running anything?
   <details><summary>Answer</summary>Constant: `f(x)=0` and `f(x)=1`. Balanced: `f(x)=x` and
   `f(x)=1−x`. In the table, the two constant rows are related by negating every amplitude (a
   global phase — physically nothing), while the two balanced rows each have their `|0⟩`-branch and
   `|1⟩`-branch amplitudes scaled by opposite signs (a relative phase) — that opposite-sign pattern
   is what the closing `H` turns into a certain `q0 = 1`.</details>

2. Why is the ancilla's measured bit a fair coin in §13.8's shot counts, for every oracle, even
   though the verdict bit is perfectly deterministic?
   <details><summary>Answer</summary>The ancilla starts in `\|−⟩ = (\|0⟩−\|1⟩)/√2` and the oracle
   never changes it — §13.5 confirms its Bloch card stays at `x −1.000` through every stage. A `\|−⟩`
   qubit measured in the computational basis gives `0` or `1` with equal probability regardless of
   anything else in the circuit, exactly as Chapter 8 §8.7 found for `\|+⟩`/`\|−⟩` generally — the
   ancilla carried the phase that made the algorithm work, not any part of the answer.</details>

3. What does the app report if you build the correct circuit but skip the final `H`?
   <details><summary>Answer</summary>A flat ~25% split across all four two-bit outcomes, for every
   one of the four oracles (§13.6, §13.8) — the relative phase kicked back onto q0 is completely
   real (§13.4) but invisible to a Z-basis measurement without the recombining `H`, the same
   "phase real, probability unchanged" split Chapter 8 §8.3 first established.</details>

4. Deutsch's algorithm tells you `f(0) ⊕ f(1)` in one query. What would it cost to learn `f(0)`
   itself?
   <details><summary>Answer</summary>Phase kickback only ever recovers the *global* property the
   phase was built to carry — the parity of the two values, not either value alone (§13.8). Getting
   `f(0)` specifically means a different question and, on a genuine black box, a genuine additional
   query: nothing in this circuit's superposition lets you split the XOR back into its two
   summands.</details>

---
[← Chapter 12](12-Entanglement.md) · [Contents](../../INTRODUCTION.md) · [Chapter 14 →](14-DeutschJozsa.md)
