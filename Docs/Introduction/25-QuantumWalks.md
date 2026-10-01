# Chapter 25 — Discrete-Time Quantum Walks

> The quantum analogue of a random walk: a hand-built shift permutation, ballistic (∝t) spreading
> against classical diffusive (∝√t) comparison, and why the `|0⟩`-coin distribution is lopsided
> while `|+i⟩`'s is symmetric.

| | |
|---|---|
| Playground page | [`22Walk`](../../../SwiftQiskit/PlaygroundDocs/22WALKHELP.md) |
| In the app | ◐ — the coin-conditioned shift on a 4-site cycle (2 position qubits) decomposes exactly into three palette gates and is fully tappable; the 16-site shift used for the spreading and interference numbers below needs the same trick on a wider register, which runs into a carry that isn't linear past 2 position qubits and needs a gate this simulator doesn't have |
| Library APIs | `Matrix(rows:cols:)` + subscript, `.tensor(_:)`/`⊗`, `Matrix.identity(size:)`, `HadamardGate.matrix`, `RYGate.matrix(theta:)`, `CNOTGate.matrix(qubits:control:target:)`, `PauliXGate.matrix`, `StateVector([Complex])`, `.apply(_:)`, `Ket.zero`/`.plusI`, `QuantumCircuit.h/x/s/cx`, `CircuitBuilder.place` |
| Prerequisites | Chapters 9, 11, 17 |

## 25.1 Coin and position registers

Every algorithm so far has answered a question — is this function constant or balanced, is this
the marked item, what phase did this eigenvector pick up. A quantum walk asks a different kind of
question: starting from one point, how does probability *spread*? The answer turns out to depend
entirely on interference, and the walk is the cleanest place in this book to see a spreading
*distribution*, rather than an oracle answer or an amplified marked state, be the thing interference
directly produces.

The setup splits the register into two parts with different jobs. A single **coin qubit** decides
a direction, the way flipping a coin decides which way to step in a classical random walk. A
**position register** of several qubits represents *where* the walker is, as a one-hot amplitude
over site indices rather than a binary-encoded number to be arithmetically incremented — site `k`
is basis state `|k⟩` of the position register, full stop. To keep the walk on a line without an
edge to fall off, the sites are arranged on a cycle of `n` sites, wrapping site `n−1` back around
to site `0`.

Following `22Walk`, this chapter uses **16 sites** (a 4-qubit position register) plus 1 coin qubit,
for a total dimension `2 × 16 = 32`. Coin is qubit 0 (the most-significant, per this project's
convention), so the combined register is `coin ⊗ position` and a basis state's index is
`coin·16 + pos`. Sixteen sites is not an arbitrary round number: starting at site 0, a
nearest-neighbor walk can reach sites `−t..+t` after `t` steps, so avoiding the two tails
overlapping around the cycle through `t = 7` needs `2·7 + 1 = 15` distinct sites — 8 sites would
have the tails colliding by `t ≈ 4`, while 16 keeps `t = 7` clean.

## 25.2 The shift operator as a hand-built permutation

One step of the walk is two operators in sequence: a **coin flip**, then a **conditional shift**.
The coin flip is exactly `H` applied to qubit 0 alone — nothing new. The shift is new: it moves the
*position* register left or right depending on the *coin's* value, entangling the two registers
together the same way `cx` entangles two qubits, except here the "target" is an entire 4-qubit
register, and the operation isn't in `QuantumCircuit`'s fixed gate set. It has to be built by hand
as a `Matrix` and applied via `apply(_:)` — the same idiom Chapter 17 used for Shor's modular
multiplication and Chapter 19's error-correction playground used for its 32×32 syndrome correction.

The shift's action on a basis state is a simple rule: `|0,x⟩ → |0,x+1 mod 16⟩` (coin 0: step right),
`|1,x⟩ → |1,x−1 mod 16⟩` (coin 1: step left). Because this rule sends every basis state to exactly
one other basis state, the resulting matrix is a **permutation matrix** — unitary by construction,
with no need to solve for a matrix square root or invert anything:

```swift
func buildShift() -> Matrix {
    var m = Matrix(rows: dim, cols: dim)   // dim = 32
    for coin in 0...1 {
        for pos in 0..<numSites {          // numSites = 16
            let newPos = coin == 0 ? (pos + 1) % numSites : (pos - 1 + numSites) % numSites
            m[coin * numSites + newPos, coin * numSites + pos] = .one
        }
    }
    return m
}
```

Verified directly rather than assumed — `S†S = I` entrywise:

```text
S†S = I max diff: 0.00e+00
```

One full step is the shift applied after the coin flip, `U = S · (H ⊗ I₁₆)`, and the **position
marginal** — the quantity actually plotted below — sums out the coin: `P(site k) = |⟨0,k|ψ⟩|² +
|⟨1,k|ψ⟩|²`.

## 25.3 Ballistic vs. diffusive spreading

The headline comparison is how fast the distribution's spread grows. For the classical random
walk (a fair coin flip choosing +1 or −1 at each step, no quantum anything), the position variance
after `t` steps grows linearly, so the standard deviation `σ` grows as `√t` — textbook diffusion.
The quantum walk, run below for `t = 1..7` steps starting from coin `|0⟩`, grows *faster*:

```text
t   quantum σ   σ/t
1   1.0000      1.0000
2   1.4142      0.7071
3   1.6583      0.5528
4   2.0000      0.5000
5   2.5951      0.5190
6   3.1125      0.5187
7   3.4500      0.4929

t   classical σ   σ/√t
1   1.0000       1.0000
2   1.4142       1.0000
3   1.7321       1.0000
4   2.0000       1.0000
5   2.2361       1.0000
6   2.4495       1.0000
7   2.6458       1.0000
```

The classical `σ/√t` column is pinned at exactly `1.0` at every single `t` — the diffusive
signature, `σ ∝ √t`. The quantum `σ/t` column instead hovers around `0.5`, not settling as smoothly
(a known finite-size/parity effect in small coined walks, not an error) — but it is *not* shrinking
toward zero the way `σ/√t` would if the quantum walk were secretly diffusive too. The quantum walk
is **ballistic**: `σ` grows roughly linearly in `t`, quadratically faster than the classical
`√t`, purely from interference between the two coin-conditioned paths at every site.

**A genuine gotcha, caught while verifying this page:** computing `σ` from raw site *indices*
silently breaks once a distribution's support nears the 0/15 wraparound boundary, because index 15
is actually adjacent to index 0 on the cycle, but a naive variance calculation treats them as far
apart, producing non-monotonic, nonsensical "spread" numbers. The fix is to unwrap each index to a
**signed offset from the start site** before computing variance:

```swift
func signedOffset(_ pos: Int) -> Int { pos <= numSites / 2 ? pos : pos - numSites }
```

This is valid as long as the spread stays under half the cycle, true through `t = 7` on 16 sites
here. Anyone implementing a walk on a cycle for the first time hits this; it isn't specific to this
simulator.

## 25.4 Why `|0⟩` is lopsided and `|+i⟩` is symmetric

The position distribution after `t = 7` steps, coin starting in `|0⟩`, is visibly asymmetric —
site 3 gets roughly 8× the probability of its mirror site 13:

```text
site   P(biased, coin=|0⟩)   P(symmetric, coin=|+i⟩)
1      0.1328                 0.1016
3      0.3203                 0.1797
5      0.2891                 0.2109
7      0.0078                 0.0078
9      0.0078                 0.0078
11      0.1328                 0.2109
13      0.0391                 0.1797
15      0.0703                 0.1016
```

Starting the coin in `|+i⟩` instead — an existing basis ket, `(|0⟩ + i|1⟩)/√2`, needing no new
code — restores left-right symmetry *exactly*, to four decimal places at every mirrored pair
(1↔15, 3↔13, 5↔11, 7↔9). Nothing about the shift operator itself changed between these two runs;
only the coin's initial relative phase did. The asymmetry is therefore not a flaw or an artifact of
this particular cycle — it is **interference**, exactly as much as the fringes in Chapter 8's phase
demonstrations or Chapter 15's Grover amplification, just now shaping a whole distribution instead
of a single measured bit. (Two further connections, for context rather than for use in this
chapter: Grover's search, Chapter 15, can itself be recast as a quantum walk on a different graph;
and a *continuous-time* walk — no coin, no discrete steps — is `expm(−iAt)` applied directly to a
graph's adjacency matrix `A`, using Chapter 24's `expm`.)

## Build it in the app

◐ The 16-site shift needed for every number above is a 32×32 permutation with no path onto this
app's fixed single/two-qubit gate palette. But shrink the cycle to **4 sites** (2 position qubits,
3 qubits total: coin q0, position MSB q1, position LSB q2) and something notable happens: the
coin-conditioned shift turns out to have an *exact* three-gate decomposition using only gates
already in `GateKind`:

```text
cx(0,1); cx(2,1); x(2)
```

Checked directly against the hand-built 4-site permutation matrix, not assumed: max diff `0.00e+00`.
The reason is a carry computation that happens to stay linear at this size. Incrementing a 2-bit
number always flips the low bit, and flips the high bit exactly when the low bit was `1` — no
`AND` needed, just an `XOR`. Decrementing turns out to need the same two operations in the opposite
order. Conditioning on the coin merges the two into one formula for the new high bit,
`q1' = q1 ⊕ q0 ⊕ q2` (using the *original* q2, before it flips) and one formula for the new low
bit, `q2' = ¬q2`, **unconditionally** — the low bit flips every step no matter which way the coin
points. `q1' = q1 ⊕ q0 ⊕ q2` is exactly what `cx(0,1); cx(2,1)` computes (two CNOTs into the same
target commute and just XOR their controls in), followed by `x(2)` for the unconditional flip. This
stops working at 8 sites: a 3-bit incrementer's carry into the *third* bit is `q2 ⊕ (q0 ∧ q1)` — a
genuine `AND`, which needs a Toffoli this simulator doesn't have.

On this 4-site cycle, 3 steps from coin `|0⟩` lands with **certainty** on site 1 — a clean,
exactly-verified illustration of constructive interference, not an approximate tendency:

1. Clear, set **Qubits: 3**.
2. Repeat this 4-column block three times (columns 0–3, 4–7, 8–11): arm **H**, tap `q0`; arm
   **CX**, tap `q0` then `q1` (control `q0`, target `q1`); arm **CX**, tap `q2` then `q1` (control
   `q2`, target `q1`); arm **X**, tap `q2`.

State Vector panel after 12 columns — probabilities: `|001⟩ ≈ 1.0000`, every other basis state
`≈ 0.0000` (`q1q2 = 01` is site 1). Both position qubits deterministic, despite three rounds of a
Hadamard coin flip in between.

For the **symmetric coin**, prepend `H` then `S` on `q0` (columns −2, −1, i.e. before the block
above) to prepare `|+i⟩`. After the same three rounds, the State Vector panel instead splits
evenly: `|001⟩ ≈ 0.5000`, `|011⟩ ≈ 0.5000` (sites 1 and 3), all else `≈ 0.0000` — the coin's phase
alone is the difference between a certain outcome and an even split, confirmed by tapping, not just
asserted.

**What's still out of reach:** the 16-site register used for every number in §25.2–25.4 (the
ballistic-spreading table and the `|0⟩`-vs-`|+i⟩` distributions), and the classical-walk
comparison, which isn't a quantum circuit at all. Both are "Run it in code" below.

## Run it in code

Every snippet was run with `RunCodeSnippet` against `SwiftQiskitApp/CircuitModel.swift`.

```swift
import SwiftQiskit
import Foundation

let numSites = 16
let dim = 32

func buildShift() -> Matrix {
    var m = Matrix(rows: dim, cols: dim)
    for coin in 0...1 {
        for pos in 0..<numSites {
            let newPos = coin == 0 ? (pos + 1) % numSites : (pos - 1 + numSites) % numSites
            m[coin * numSites + newPos, coin * numSites + pos] = .one
        }
    }
    return m
}
let shift = buildShift()
let identity16 = Matrix.identity(size: numSites)
let stepOperator = shift * HadamardGate.matrix.tensor(identity16)

func initialState(coin: Ket) -> Ket {
    var posAmp = Array(repeating: Complex.zero, count: numSites)
    posAmp[0] = .one
    return coin.tensor(StateVector(posAmp))
}

func positionDistribution(_ psi: Ket) -> [Double] {
    var dist = Array(repeating: 0.0, count: numSites)
    for coin in 0...1 {
        for pos in 0..<numSites { dist[pos] += psi[coin * numSites + pos].magnitudeSquared }
    }
    return dist
}

func quantumDistribution(coin: Ket, steps: Int) -> [Double] {
    var psi = initialState(coin: coin)
    for _ in 0..<steps { psi.apply(stepOperator) }
    return positionDistribution(psi)
}

func classicalDistribution(steps: Int) -> [Double] {
    var dist = Array(repeating: 0.0, count: numSites)
    dist[0] = 1.0
    for _ in 0..<steps {
        var next = Array(repeating: 0.0, count: numSites)
        for (pos, p) in dist.enumerated() {
            next[(pos + 1) % numSites] += 0.5 * p
            next[(pos - 1 + numSites) % numSites] += 0.5 * p
        }
        dist = next
    }
    return dist
}

func signedOffset(_ pos: Int) -> Int { pos <= numSites / 2 ? pos : pos - numSites }

func stddev(_ distribution: [Double]) -> Double {
    var mean = 0.0
    for (pos, p) in distribution.enumerated() { mean += Double(signedOffset(pos)) * p }
    var variance = 0.0
    for (pos, p) in distribution.enumerated() { variance += p * pow(Double(signedOffset(pos)) - mean, 2) }
    return variance.squareRoot()
}

var maxAbs = 0.0
let StS = (shift†) * shift
for i in 0..<dim { for j in 0..<dim {
    let expected: Complex = (i == j) ? .one : .zero
    maxAbs = max(maxAbs, (StS[i, j] - expected).magnitude)
} }
print("S†S = I max diff: \(String(format: "%.2e", maxAbs))")

print("\nt   quantum σ   σ/t")
for t in 1...7 {
    let sigma = stddev(quantumDistribution(coin: .zero, steps: t))
    print("\(t)   \(String(format: "%.4f", sigma))      \(String(format: "%.4f", sigma / Double(t)))")
}

print("\nt   classical σ   σ/√t")
for t in 1...7 {
    let sigma = stddev(classicalDistribution(steps: t))
    print("\(t)   \(String(format: "%.4f", sigma))       \(String(format: "%.4f", sigma / Double(t).squareRoot()))")
}

let biased = quantumDistribution(coin: .zero, steps: 7)
let symmetric = quantumDistribution(coin: .plusI, steps: 7)
print("\nsite   P(biased, coin=|0⟩)   P(symmetric, coin=|+i⟩)")
for site in [1, 3, 5, 7, 9, 11, 13, 15] {
    print("\(site)      \(String(format: "%.4f", biased[site]))                 \(String(format: "%.4f", symmetric[site]))")
}
```

```text
S†S = I max diff: 0.00e+00

t   quantum σ   σ/t
1   1.0000      1.0000
2   1.4142      0.7071
3   1.6583      0.5528
4   2.0000      0.5000
5   2.5951      0.5190
6   3.1125      0.5187
7   3.4500      0.4929

t   classical σ   σ/√t
1   1.0000       1.0000
2   1.4142       1.0000
3   1.7321       1.0000
4   2.0000       1.0000
5   2.2361       1.0000
6   2.4495       1.0000
7   2.6458       1.0000

site   P(biased, coin=|0⟩)   P(symmetric, coin=|+i⟩)
1      0.1328                 0.1016
3      0.3203                 0.1797
5      0.2891                 0.2109
7      0.0078                 0.0078
9      0.0078                 0.0078
11      0.1328                 0.2109
13      0.0391                 0.1797
15      0.0703                 0.1016
```

Every figure matches `22WALKHELP.md`'s "Expected output" to the digit, against the current public
API.

The app-tap circuit from "Build it in the app," replayed with `CircuitBuilder` and checked against
the matrix-level 4-site walk directly (`CircuitBuilder` is `@MainActor`-isolated, so this runs
inside `MainActor.run`):

```swift
let numSites4 = 4

@MainActor
func appWalk(startWithSH: Bool, steps: Int) -> [Double] {
    let builder = CircuitBuilder(qubitCount: 3)
    var col = 0
    if startWithSH {
        builder.place(.h, qubits: [0], column: col); col += 1
        builder.place(.s, qubits: [0], column: col); col += 1
    }
    for _ in 0..<steps {
        builder.place(.h, qubits: [0], column: col); col += 1
        builder.place(.cx, qubits: [0, 1], column: col); col += 1
        builder.place(.cx, qubits: [2, 1], column: col); col += 1
        builder.place(.x, qubits: [2], column: col); col += 1
    }
    let state = builder.buildCircuit().run()
    var d = Array(repeating: 0.0, count: numSites4)
    for coin in 0...1 { for pos in 0..<numSites4 { d[pos] += state[coin * numSites4 + pos].magnitudeSquared } }
    return d
}

await MainActor.run {
    let biased3 = appWalk(startWithSH: false, steps: 3)
    let symmetric3 = appWalk(startWithSH: true, steps: 3)
    print("app circuit, coin |0⟩, 3 steps: \(biased3.map { String(format: "%.4f", $0) })")
    print("app circuit, coin |+i⟩, 3 steps: \(symmetric3.map { String(format: "%.4f", $0) })")
}
```

```text
app circuit, coin |0⟩, 3 steps: ["0.0000", "1.0000", "0.0000", "0.0000"]
app circuit, coin |+i⟩, 3 steps: ["0.0000", "0.5000", "0.0000", "0.5000"]
```

Matching the matrix-level 4-site walk exactly (max diff `0.00e+00` against the same computation
done via `buildShift`/`apply(_:)` directly) — the tile-by-tile app circuit and the hand-built
permutation agree bit for bit, the same cross-check Chapter 24 ran for its Trotter step.

## Try it yourself

1. On the app's 4-site walk, three steps from coin `|0⟩` land with certainty on site 1. Predict
   what a *fourth* step does, for both the `|0⟩` and `|+i⟩` coins, before running it.
   <details><summary>Answer</summary>Both land on site 2 with certainty: `|0⟩` → `[0.0, 0.0, 1.0,
   0.0]`, `|+i⟩` → `[0.0, 0.0, 1.0, 0.0]` — identical. On a 4-site cycle a nearest-neighbor walk's
   two tails (reaching `±t`) already overlap by `t = 2` (`2·2+1 = 5 > 4`), so by `t = 4` the
   distribution has wrapped enough that the coin's phase no longer distinguishes the two
   cases — the same aliasing §25.1 sizes 16 sites to avoid through `t = 7`.</details>
2. The 16-site walk was sized to stay alias-free only through `t = 7`. Run the Hadamard-coin,
   `|0⟩` walk out to `t = 8, 9, 10` and see what changes.
   <details><summary>Answer</summary>`σ` keeps growing (3.7868, 4.3309, 4.4913 for t=8,9,10), but
   the *set* of sites with non-zero probability flips parity each step and, past `t=7`, no longer
   forms a single contiguous band around the start — at `t=8` probability sits only on the *even*
   sites (0,2,4,…,14), including site 8 exactly opposite the start, where the walk's two tails
   have now met and interfered on the far side of the cycle. This is the aliasing `22WALKHELP.md`
   warns about, not a bug.</details>
3. Replace the Hadamard coin with `RY(θ)` and sweep `θ` — how does the `t=7` spread change?
   <details><summary>Answer</summary>σ at t=7, 16 sites, `|0⟩` coin: θ=0.5 → 3.7130, θ=1.0 →
   3.6683, θ=π/2 → 3.4500 (Hadamard's own value — `RY(π/2)` and `H` differ only by a reflection
   that doesn't change any probability here), θ=2.0 → 2.8130, θ=2.5 → 1.6822, θ=3.0 → 0.5347.
   Larger θ biases the coin toward "always flip," which increasingly cancels the interference that
   drives ballistic spreading — near θ=π the walk nearly reflects in place instead of
   spreading.</details>
4. Chapter 24 built `expm` for Hamiltonian simulation. Use it to run a *continuous-time* walk —
   `exp(−iAt)` applied to the cycle's adjacency matrix `A` (no coin register at all) — and compare
   its spread to the discrete coined walk above.
   <details><summary>Answer</summary>σ grows quickly at first (t=1→1.4142, t=2→2.8285, t=3→4.2438,
   t=4→5.3572) — even faster than the coined walk at comparable `t` — then stops growing
   monotonically (t=5→5.1376, t=6→5.2145, t=7→4.5221): with no coin to keep injecting fresh
   superposition, the continuous-time walk on a *finite* 16-site cycle shows a partial revival,
   probability sloshing back toward the start once it has had time to circle the loop, rather than
   spreading forever.</details>

---
[← Chapter 24](24-Trotter.md) · [Contents](../../INTRODUCTION.md) · [Chapter 26 →](26-TensorDiagrams.md)
