# Chapter 3 — Qubits: Amplitudes and Probabilities

> What a qubit actually is in this simulator: a normalized pair of complex amplitudes, and the
> Born rule that turns them into the probabilities you see in the app's State Vector panel.

| | |
|---|---|
| Playground page | [`01Qubits`](../../../SwiftQiskit/PlaygroundDocs/01QUBITSHELP.md) |
| In the app | ● — every state shown here is exactly what the State Vector panel displays |
| Library APIs | `StateVector` (auto-normalizing `init`, `.amplitudes`, `.probabilities`, `apply(_:)`) |
| Prerequisites | Chapters 1, 2 |

## 3.1 A qubit as two complex amplitudes

A qubit's state is a `StateVector` holding two complex amplitudes, `α` and `β` — one for each
outcome, `0` and `1`. Chapter 2 built vectors like this by hand as plain `[Complex]` arrays, with
no enforcement at all; `StateVector` (`Quantum/StateVector.swift`) is the type that actually
carries a state through the rest of this book, and it enforces the one rule that matters:
`|α|² + |β|² = 1`.

`StateVector.init(_:)` takes any array of amplitudes and normalizes immediately, dividing every
entry by the vector's length if it isn't already 1:

```swift
let raw = StateVector([Complex(0.5), Complex(0.5)])
print(raw.amplitudes)
```

```text
[0.7071067811865475, 0.7071067811865475]
```

The constructor was handed `[0.5, 0.5]` — length √0.5 ≈ 0.707, not 1 — and rescaled it to
`[0.707…, 0.707…]` before you ever see it. This is exactly the guarantee Chapter 2 §2.7 promised:
"from Chapter 3 onward the constraint above is enforced by the type rather than something you
check by hand." There is no way to hold an un-normalized `StateVector` — `.amplitudes` is
`private(set)`, and every mutating operation (`apply(_:)`, the gate methods on `QuantumCircuit`)
renormalizes afterward.

`StateVector(qubits:)` is the other constructor, building `|0…0⟩` directly rather than
normalizing something you supply:

```swift
let zero = StateVector(qubits: 1)
print(zero.amplitudes)
```

```text
[1.0, 0.0]
```

## 3.2 From amplitudes to probabilities: the Born rule

`.probabilities` computes `|amplitude|²` for every entry — the Born rule from Chapter 2 §2.3,
now a stored property instead of something you compute by hand:

```swift
print(raw.probabilities, raw.probabilities.reduce(0, +))
```

```text
[0.4999999999999999, 0.4999999999999999] 0.9999999999999998
```

Both entries ≈ 0.500, summing to ≈ 1 (floating-point rounding again, not a bug) — `|α|² + |β|² =
1` from §3.1, now visible as `.probabilities` rather than asserted by hand.

`.probabilities` is a lossy view, and it is worth seeing exactly how much it throws away. `|+⟩`
and `|+i⟩` are different states — a real amplitude on `|1⟩` versus a purely imaginary one — but
`.probabilities` cannot tell them apart:

```swift
print(StateVector.plus.amplitudes, StateVector.plus.probabilities)
print(StateVector.plusI.amplitudes, StateVector.plusI.probabilities)
```

```text
[0.7071067811865475, 0.7071067811865475] [0.4999999999999999, 0.4999999999999999]
[0.7071067811865475, 0.7071067811865475i] [0.4999999999999999, 0.4999999999999999]
```

Identical probability lists, `[≈0.500, ≈0.500]` both times — the phase difference on `|1⟩`
(real `0.707` versus imaginary `0.707i`) is invisible to `.probabilities` even though it is a
real, physical difference between the two states. This is the same point Chapter 2 §2.3/§2.4
made about phase and magnitude carrying separate information; §3.3 below walks through a circuit
where that hidden phase is the entire story, and Chapter 8 is where a phase difference finally
does change a probability.

## 3.3 Two worked circuits

`01Qubits`'s `circuit1` and `circuit2` are both single-qubit circuits that start at `|0⟩` and
diverge after the first `H`. Stage by stage, printing `.amplitudes` and `.probabilities` after
each gate:

**`circuit1`: `H` → `P(π/2)` → `P(π)`**

| Stage | Amplitudes | Probabilities |
|---|---|---|
| `\|0⟩` | `[1.0, 0.0]` | `[1.000, 0.000]` |
| `H` | `[0.707…, 0.707…]` | `[≈0.500, ≈0.500]` |
| `P(π/2)` | `[0.707…, ≈0 + 0.707…i]` | `[≈0.500, ≈0.500]` |
| `P(π)` | `[0.707…, ≈0 − 0.707…i]` | `[≈0.500, ≈0.500]` |

Every stage keeps probability split ≈0.500/≈0.500 — `P` never touches probability, only phase
(Chapter 2 §2.4 again). What moves is the amplitude on `|1⟩`: real and positive after `H`, then
rotated onto the imaginary axis by `P(π/2)`, then rotated again — past `+i` and on to `−i` — by a
*second* application of `P`, this time with `θ = π`. Because `P` gates compose by adding their
angles (`P(a)` then `P(b)` is the same phase as a single `P(a+b)`), the `|1⟩` phase after both
gates is `e^{i(π/2+π)} = e^{i·3π/2} = -i`, which is exactly `|−i⟩` in the notation Chapter 5
introduces for the Bloch sphere's equator.

**`circuit2`: `H` → `Z` → `H`**

| Stage | Amplitudes | Probabilities |
|---|---|---|
| `\|0⟩` | `[1.0, 0.0]` | `[1.000, 0.000]` |
| `H` | `[0.707…, 0.707…]` | `[≈0.500, ≈0.500]` |
| `Z` | `[0.707…, −0.707…]` | `[≈0.500, ≈0.500]` |
| `H` | `[0.0, ≈1.0]` | `[≈0.000, ≈1.000]` |

Here probability *does* move, on the very last step: `Z` only flips the sign of the `|1⟩`
amplitude (still ≈0.500/≈0.500, same reasoning as `circuit1`), but the second `H` turns that sign
flip into a definite outcome — the state lands on `|1⟩` with probability ≈1, not back on `|0⟩`.
`H;Z;H` on `|0⟩` behaves like `X` on `|0⟩`: same destination, reached by an entirely different
route through phase space. This is the interference mechanism Chapter 8 names and explains in
depth; for now, notice that the phase `Z` introduced after the first `H` was invisible in
`.probabilities` right up until the second `H` converted it into one.

## Build it in the app

● Both circuits are single-qubit, so start by dropping the **Qubits** stepper to 1 — only the
`q0` row remains.

1. **Place `H`.** Arm **H** ("Pauli / Hadamard" section) and tap the first empty cell on `q0`.
   The State Vector panel lists `|0⟩: 0.707…  (p=0.500)` and `|1⟩: 0.707…  (p=0.500)` — both
   amplitudes real, matching the `H` row of both tables above.

2. **`circuit1`'s first `P`.** Arm **P** ("Rotation (θ = π/2)" section) — it arms at its default
   `θ = π/2`, so nothing further is needed before placing it. Tap the next empty cell on `q0`.
   The probabilities don't move, but `|1⟩`'s printed amplitude changes shape to `0.707…i` — a
   purely imaginary number — matching the `P(π/2)` row.

3. **`circuit1`'s second `P`.** Arm **P** again and tap the following empty cell on the same
   wire. Tap that new tile to reopen its θ popover, and drag the slider away from its default
   `π/2` toward `π` — the readout above the slider shows θ to three decimals, so get as close to
   `3.142` as you can. There is no exact-entry field, so this only approximates the code's exact
   `.pi`; watch `|1⟩`'s amplitude swing from `+i`-like toward `−i`-like as you drag, while both
   probabilities hold at ≈0.500.

4. **Clear**, then build `circuit2`: **H**, then **Z** ("Pauli / Hadamard" section), then **H**
   again — three plain taps, no popover needed since none of these gates take a parameter. After
   `Z`, `|1⟩`'s amplitude flips to a negative real number with probabilities still ≈0.500/≈0.500.
   After the second `H`, the panel settles on `|1⟩: ≈1.0  (p=1.000)` with the `|0⟩` row gone
   entirely (its probability has dropped below the panel's display threshold) — the same
   collapse the table above shows.

## Run it in code

```swift
import SwiftQiskitCore

let raw = StateVector([Complex(0.5), Complex(0.5)])
print(raw.amplitudes)
print(raw.probabilities, raw.probabilities.reduce(0, +))
```

```text
[0.7071067811865475, 0.7071067811865475]
[0.4999999999999999, 0.4999999999999999] 0.9999999999999998
```

```swift
let zero = StateVector(qubits: 1)
print(zero.amplitudes)

print(StateVector.plus.amplitudes, StateVector.plus.probabilities)
print(StateVector.plusI.amplitudes, StateVector.plusI.probabilities)
```

```text
[1.0, 0.0]
[0.7071067811865475, 0.7071067811865475] [0.4999999999999999, 0.4999999999999999]
[0.7071067811865475, 0.7071067811865475i] [0.4999999999999999, 0.4999999999999999]
```

```swift
let circuit1 = QuantumCircuit(qubits: 1)
print(circuit1.run().amplitudes, circuit1.run().probabilities)
circuit1.h(0)
print(circuit1.run().amplitudes, circuit1.run().probabilities)
circuit1.p(.pi / 2, 0)
print(circuit1.run().amplitudes, circuit1.run().probabilities)
circuit1.p(.pi, 0)
print(circuit1.run().amplitudes, circuit1.run().probabilities)
```

```text
[1.0, 0.0] [1.0, 0.0]
[0.7071067811865475, 0.7071067811865475] [0.4999999999999999, 0.4999999999999999]
[0.7071067811865475, 4.329780281177466e-17 + 0.7071067811865475i] [0.4999999999999999, 0.4999999999999999]
[0.7071067811865475, -1.2989340843532398e-16 - 0.7071067811865475i] [0.4999999999999999, 0.4999999999999999]
```

```swift
let circuit2 = QuantumCircuit(qubits: 1)
print(circuit2.run().amplitudes, circuit2.run().probabilities)
circuit2.h(0)
print(circuit2.run().amplitudes, circuit2.run().probabilities)
circuit2.z(0)
print(circuit2.run().amplitudes, circuit2.run().probabilities)
circuit2.h(0)
print(circuit2.run().amplitudes, circuit2.run().probabilities)
```

```text
[1.0, 0.0] [1.0, 0.0]
[0.7071067811865475, 0.7071067811865475] [0.4999999999999999, 0.4999999999999999]
[0.7071067811865475, -0.7071067811865475] [0.4999999999999999, 0.4999999999999999]
[0.0, 0.9999999999999998] [0.0, 0.9999999999999996]
```

The tiny `e-17`/`e-16` real parts on `circuit1`'s `P` stages are ordinary floating-point
rounding from `cos(π/2)`/`cos(π)` not landing on exactly `0` — the amplitude is imaginary "up to"
that rounding, same idiom as Chapter 2's tolerance discussion in §2.9.

## Try it yourself

1. Predict `circuit2`'s final amplitudes before running it, then check.
   <details><summary>Answer</summary>`H;Z;H` on `|0⟩` lands on `|1⟩`: amplitudes `[0.0,
   ≈1.0]`, probabilities `[≈0.000, ≈1.000]`. `Z` alone only flips the sign of the `|1⟩`
   amplitude (still ≈0.500/≈0.500); it's the second `H` that turns that sign flip into a
   definite outcome — the same interference trick Chapter 8 explains in depth.</details>

2. `StateVector.plus` and `StateVector.plusI` report identical `.probabilities`, `[≈0.500,
   ≈0.500]`, despite being different states. What information did the Born rule discard, and
   where in this chapter does it stop being invisible?
   <details><summary>Answer</summary>The Born rule keeps only magnitude-squared and discards
   phase — `|+⟩`'s `|1⟩` amplitude is real (`0.707`) while `|+i⟩`'s is imaginary (`0.707i`), a
   real difference `.probabilities` can't see. §3.3's `circuit2` is where that hidden phase
   stops being invisible: the sign `Z` puts on the `|1⟩` amplitude doesn't move any probability
   by itself, but the following `H` converts it into a probability that does move, landing the
   state on `|1⟩` instead of back on `|0⟩`.</details>

3. `StateVector([Complex(0.5), Complex(0.5)])` prints as `[0.707…, 0.707…]`, not `[0.5, 0.5]`.
   Why, and what would `raw.probabilities` have summed to if `init` hadn't rescaled it?
   <details><summary>Answer</summary>`init(_:)` normalizes on construction (§3.1): the supplied
   vector `[0.5, 0.5]` has length `√(0.25+0.25) = √0.5 ≈ 0.707`, not `1`, so every entry is
   divided by that length, giving `0.5 / 0.707 ≈ 0.707`. Had normalization been skipped,
   `.probabilities` would be `[0.25, 0.25]`, summing to `0.5` — not a valid quantum state, since
   probabilities must sum to `1`.</details>

---
[← Chapter 2](02-ComplexAndMatrices.md) · [Contents](../../INTRODUCTION.md) · [Chapter 4 →](04-DiracNotation.md)
