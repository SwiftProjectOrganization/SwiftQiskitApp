# Chapter 19 — Quantum Error Correction

> The 3-qubit bit-flip code: encoding one qubit into three, a syndrome that names the error
> without ever reading α or β, a correction built entirely from palette gates, a continuous
> error digitized exactly, and where a distance-3 code breaks.

| | |
|---|---|
| Playground page | [`14ErrorCorrection`](../../../SwiftQiskit/PlaygroundDocs/14ERRORCORRECTIONHELP.md) |
| In the app | ● — encode, inject an error, decode, and correct all build from palette gates: `cx` for the code itself, `x`/`y`/`z`/`rx` for the error, and a Toffoli built from Chapter 15's CCZ for the correction. It's a different (but equivalent) circuit from the playground page's, which uses two separate syndrome ancillas and a hand-built permutation matrix — see "Build it in the app" |
| Library APIs | `QuantumCircuit.h/x/y/z/rx/cx/t/tdg`, `.run()`, `measure(shots:)`, `Matrix`, `⊗`, `BlochVector(_:qubit:)` |
| Prerequisites | Chapters 8, 11, 12, 15, 18 |

## 19.1 Encoding one qubit into three

A physical qubit is fragile — any stray rotation corrupts it — and you cannot check on it
without collapsing the very superposition you are trying to protect. The 3-qubit bit-flip code
sidesteps both problems by spreading one logical qubit across three physical ones. Register
(qubit 0 is the most-significant/leftmost bit, as throughout this book): q0 starts holding
|ψ⟩ = cos(θ/2)|0⟩ + e^{iφ}sin(θ/2)|1⟩ with θ = 60°, φ = 45° — the same payload Chapters 8, 18,
and others use, built with `ry(θ, 0); rz(φ, 0)`:

```text
|ψ⟩ on q0:  |0⟩: 0.8001 − 0.3314i   |1⟩: 0.4619 + 0.1913i
```

`cx(0,1); cx(0,2)` copies q0's *basis label* — not its amplitudes — onto q1 and q2:

```text
encoded (α|000⟩+β|111⟩):  |000⟩: 0.8001 − 0.3314i   |111⟩: 0.4619 + 0.1913i
```

This is not cloning. Chapter 18 §18.5 already made this point for teleportation, and it holds
here too: the two terms above are entangled, and neither q1 nor q2 alone holds a copy of |ψ⟩ —
tracing either one out leaves the other two in exactly the maximally-mixed marginal Chapter 12
found for the Bell state.

## 19.2 Injecting a bit-flip error

`x(q)` on any one of the three data qubits corrupts the encoding, but corrupts it in a way
that's still detectable, because the three qubits no longer agree. An error on q1:

```text
error on q1:  |010⟩: 0.8001 − 0.3314i   |101⟩: 0.4619 + 0.1913i
```

Every single-qubit error looks the same shape — one bit disagrees with the other two — just at
a different position, and that position is exactly what the syndrome below reads out.

## 19.3 The syndrome and its correction

Two ancilla qubits, q3 and q4, learn the *parities* q0⊕q1 and q1⊕q2 without ever touching α or
β: `cx(0,3); cx(1,3)` puts q0⊕q1 onto q3, `cx(1,4); cx(2,4)` puts q1⊕q2 onto q4. Every
single-qubit error gives a distinct two-bit syndrome:

| error | syndrome (q3 q4) | P |
|---|---|---|
| none | 00 | 1.0000 |
| q0 | 10 | 1.0000 |
| q1 | 11 | 1.0000 |
| q2 | 01 | 1.0000 |

(The P column above is the syndrome's *total* probability, summed over q0–q2 — every single
error produces its syndrome with certainty, which is the whole point. `14ERRORCORRECTIONHELP.md`'s
own printed P column, 0.7500, is the probability of the single largest basis amplitude instead;
see the package-side note at the end of this chapter.)

Reading two parities without collapsing the payload is only half the job — a correction still
has to *act* on whichever qubit the syndrome accuses, without ever measuring the syndrome
classically (measuring it would collapse the very superposition of "which qubit is wrong" that
keeps α and β untouched). "Flip q0 if the syndrome is 10" is a Toffoli-with-mixed-controls,
three times over, and `SwiftQiskit` has no Toffoli gate — so the playground page builds the
whole three-case correction as one 32×32 permutation matrix and applies it with `apply(_:)`.
Checked against every single-error case:

```text
correction matrix is unitary: true

error   fidelity to (α|000⟩+β|111⟩)⊗|syndrome⟩
none   1.0000
q0   1.0000
q1   1.0000
q2   1.0000
```

`cx(0,2); cx(0,1)` — the encoding run in reverse — then returns |ψ⟩ to q0 alone:

```text
error   fidelity to |ψ⟩⊗|00⟩⊗|syndrome⟩
none   1.0000
q0   1.0000
q1   1.0000
q2   1.0000
```

Every single-qubit error is corrected exactly, whichever qubit it hit.

## 19.4 Continuous errors, digitized exactly

Replace the `x` error with `rx(θ)` on q0 — a *partial* bit flip, i.e. a coherent superposition
of "no error" and "X error." Because the correction above is unitary and never conditioned on
an actual measurement, it acts coherently on the full superposition and corrects *both*
branches at once: the payload comes back with fidelity exactly 1.0000 for every θ, while the
syndrome ancillas end up holding a superposition that records how much error there was:

```text
θ       fidelity   P(syndrome none)  P(syndrome q0)
0       1.0000     1.0000            0.0000
π/6     1.0000     0.9330            0.0670
π/3     1.0000     0.7500            0.2500
π/2     1.0000     0.5000            0.5000
π       1.0000     0.0000            1.0000
```

The two probabilities are cos²(θ/2) and sin²(θ/2) exactly. This is the chapter's least
intuitive fact: a continuous error becomes a discrete, fully-corrected outcome *before* anyone
measures anything — the correction doesn't care how much error there was, only which basis
state (no-error / error) accompanies it, and it fixes every basis state's data qubits
simultaneously.

## 19.5 Where a distance-3 code breaks

The code is distance 3: it corrects any *one* error but is fooled by two. X on q0 **and** q1
gives syndrome 01 — indistinguishable from a lone error on q2 — so the correction "fixes" q2,
which was fine. Net result: all three qubits end up flipped, a full logical X on the encoded
qubit. With |ψ⟩ = |1⟩ the failure is unmistakable:

```text
|ψ⟩ = |1⟩, errors on q0 AND q1 (syndrome wrongly accuses q2):
decoded P(0) = 1.0000   P(1) = 0.0000
```

The corrected circuit reports success with full confidence in the wrong answer — a
miscorrection is worse than no correction, because it's silent. Enumerating all 8 independent
single-qubit-flip patterns, weighted by the per-qubit flip probability p, gives the exact
logical error rate:

```text
p       p_L (enumerated)   formula 3p²−2p³
0.05    0.0073              0.0073
0.10    0.0280              0.0280
0.20    0.1040              0.1040
0.30    0.2160              0.2160
0.50    0.5000              0.5000
```

p_L = 3p² − 2p³ beats the unencoded error rate p only below the break-even point p = ½ —
encoding helps against weak, independent noise and actively hurts against strong noise.

## 19.6 Phase flips, by conjugation

The same code protects against Z errors too, if you look at it in the X basis: `h` the three
data qubits, suffer a Z error, `h` them back. Since HZH = X — Chapter 8's basis-change idea,
doing real work — a phase flip becomes exactly the bit flip Sections 19.1–19.5 already know how
to fix. The syndrome table and every fidelity above come out identical:

```text
phase-flip error   fidelity to |ψ⟩⊗|00⟩⊗|syndrome⟩
none   1.0000
q0   1.0000
q1   1.0000
q2   1.0000
```

## 19.7 Bloch spheres, and what's next

Three Bloch points for q0 tell the whole story in one picture: |ψ⟩ as prepared, q0 after
decoding a single X error **without** running the correction first, and q0 after the full
correction:

| Sphere | x | y | z |
|---|---|---|---|
| \|ψ⟩ as prepared | 0.6124 | 0.6124 | 0.5000 |
| q0, error, no correction | 0.6124 | −0.6124 | −0.5000 |
| q0, error, corrected | 0.6124 | 0.6124 | 0.5000 |

The middle sphere is exactly X|ψ⟩ — decoding without correcting first still separates q0 into a
clean product state, it just carries the error through untouched — and the last sphere lands
back on the first.

A code that fixes *either* kind of error needs both ideas at once: Shor's original 9-qubit code
concatenates this bit-flip code inside a phase-flip code (three blocks of three). That's
deliberately out of scope here — `QuantumCircuit` records every operation as a full 2ⁿ×2ⁿ
matrix, and a 9-data-qubit version of this chapter's circuit (plus ancillas) would sit at
dimension 2¹³ or higher, well beyond what a dense-matrix simulator handles comfortably.

## Build it in the app

● Everything above is tappable, but not with the playground page's literal circuit — the app
has no Toffoli-with-mixed-controls and no separate syndrome ancillas for it to act on. Instead,
Chapter 15 §15.9's CCZ (built from `t`/`tdg`/`cx`) gives a Toffoli, and re-running the *decode*
step before correcting turns out to route the syndrome onto q1 and q2 themselves — no extra
ancillas needed. The circuit is: encode, inject the error, decode again (the same two `cx`
gates), then a Toffoli with controls q1, q2 and target q0. This reproduces every number in
19.1–19.6 exactly, with the syndrome living on q1, q2 instead of q3, q4: none → q1q2 = 00,
q0 → 11, q1 → 10, q2 → 01.

Clear, set **Qubits: 3**. Worked example: error on q1.

1. **Encode.** Arm **RY** (Rotation section), tap `q0` in column 0; drag θ to `1.047` (≈ π/3).
   Arm **RZ**, tap `q0` in column 1; drag θ to `0.785` (≈ π/4). Arm **CX**, tap `q0` then `q1`
   in column 2. Arm **CX** again, tap `q0` then `q2` in column 3. State Vector panel: two rows
   matching §19.1's "encoded" line.
2. **Inject the error.** Arm **X**, tap `q1` in column 4. Panel: `|010⟩` and `|101⟩`, matching
   §19.2.
3. **Decode.** Arm **CX**, tap `q0` then `q1` in column 5. Arm **CX**, tap `q0` then `q2` in
   column 6. Panel: `|010⟩: 0.8001 − 0.3314i` and `|110⟩: 0.4619 + 0.1913i` — q0 is already
   correct (this error's syndrome is 10, which needs no further fix to q0), and q1q2 = `10` is
   the syndrome.
4. **The Toffoli correction.** This fires only when the syndrome is `11` (an error on q0
   itself), so for this worked example it changes nothing — but it has to be present for every
   case to be corrected, so tap it in anyway: arm **H**, tap `q0` in column 7. Then Chapter
   15's CCZ sequence with controls q1, q2 and target q0 (relabeled from §15.9's
   controls-0,1/target-2 version): arm **CX**, tap `q2` then `q0` in column 8; arm **T†**, tap
   `q0` in column 9; arm **CX**, tap `q1` then `q0` in column 10; arm **T**, tap `q0` in
   column 11; arm **CX**, tap `q2` then `q0` in column 12; arm **T†**, tap `q0` in column 13;
   arm **CX**, tap `q1` then `q0` in column 14; arm **T**, tap `q2` in column 15 (shares the
   column with the next tile — different qubit); arm **T**, tap `q0` in column 15; arm **CX**,
   tap `q1` then `q2` in column 16; arm **T**, tap `q1` in column 17 (shares the column); arm
   **T†**, tap `q2` in column 17; arm **CX**, tap `q1` then `q2` in column 18; arm **H**, tap
   `q0` in column 19. 20 columns total. Panel: unchanged from step 3 — confirming the Toffoli
   is a no-op on this syndrome, exactly as it should be.
5. **Check the other syndromes.** Move the error tile from column 4 to `q0` or `q2` instead
   (tap the tile, drag or retap) and re-check the panel after column 19: an error on q0 now
   shows the Toffoli actually firing, landing on `|011⟩: 0.8001 − 0.3314i` and
   `|111⟩: 0.4619 + 0.1913i` — q0 flipped back to agree with α and β.
6. **Continuous error.** Swap the column-4 **X** tile for **RX** and drag its popover's θ —
   the panel's probabilities move continuously, but Display → Steps on q0 (Display → Steps,
   select **q0**) shows the Bloch point sitting at exactly `x 0.6124  y 0.6124  z 0.5000` at
   every θ, per §19.4.
7. **Phase flips.** Clear and rebuild with `h(0); h(1); h(2)` (column 4) before a **Z** error
   tile (column 5) and `h(0); h(1); h(2)` again (column 6), then the same decode-and-Toffoli
   sequence — reproduces §19.6's identical fidelities.
8. **Measure it.** Rebuild the column-4-error-on-q1 version from steps 1–4, set **Shots: 1000**,
   tap **Measure**:

   ```text
   1000 shots (q0 q1 q2):
     010: 750
     110: 250
   ```

   Roughly 750/250, matching |ψ|²'s 0.75/0.25 split on q0, with q1q2 = 10 (the syndrome) fixed
   for every shot since only one error was ever injected (a fresh tap will jitter).

What's still missing: a real classically-conditioned mid-circuit measurement — the app applies
the correction coherently to every branch, exactly as §19.4 describes, rather than measuring
the syndrome and branching on the classical result. To build the playground page's own
ancilla-based version (two separate syndrome qubits, permutation-matrix correction via
`apply(_:)`), see "Run it in code" below — its three mixed-control Toffolis would need roughly
50 columns to tap out by hand, so that version stays in code.

## Run it in code

Every snippet below was run with `RunCodeSnippet` against
`SwiftQiskitApp/SwiftQiskitApp/CircuitModel.swift`.

```swift
import SwiftQiskit

func lbl(_ i: Int, _ n: Int) -> String {
    var s = String(i, radix: 2)
    while s.count < n { s = "0" + s }
    return s
}
func pretty(_ state: StateVector, qubits: Int) -> String {
    (0..<state.dimension)
        .filter { state[$0].magnitude > 1e-9 }
        .map { "|\(lbl($0, qubits))⟩: \(state[$0])" }
        .joined(separator: "   ")
}

let theta = Double.pi / 3
let phi = Double.pi / 4

// Section 1-2: encode, then inject a bit-flip error.
func syndromeCircuit(errors: [Int]) -> QuantumCircuit {
    let qc = QuantumCircuit(qubits: 5)
    qc.ry(theta, 0); qc.rz(phi, 0)
    qc.cx(0, 1); qc.cx(0, 2)
    for q in errors { qc.x(q) }
    qc.cx(0, 3); qc.cx(1, 3)   // q3 <- q0 xor q1
    qc.cx(1, 4); qc.cx(2, 4)   // q4 <- q1 xor q2
    return qc
}

print("error   syndrome (q3 q4)   P")
for (name, errs) in [("none", []), ("q0", [0]), ("q1", [1]), ("q2", [2])] {
    let state = syndromeCircuit(errors: errs).run()
    var pByBits = [String: Double]()
    for i in 0..<32 { pByBits[String(lbl(i, 5).suffix(2)), default: 0] += state.probabilities[i] }
    let dominant = pByBits.max(by: { $0.value < $1.value })!
    print("\(name)     \(dominant.key)              \(String(format: "%.4f", dominant.value))")
}

// Section 3: the 32x32 permutation correction, one basis-index remap per branch.
var correction = Matrix(rows: 32, cols: 32)
for i in 0..<32 {
    let bits = lbl(i, 5).map { Int(String($0))! }
    var c = bits
    switch (bits[3], bits[4]) {
    case (1, 0): c[0] = 1 - c[0]   // syndrome 10 accuses q0
    case (1, 1): c[1] = 1 - c[1]   // syndrome 11 accuses q1
    case (0, 1): c[2] = 1 - c[2]   // syndrome 01 accuses q2
    default: break
    }
    let j = c[0] * 16 + c[1] * 8 + c[2] * 4 + c[3] * 2 + c[4]
    correction[j, i] = Complex(1)
}

let psiOnly: StateVector = {
    let qc = QuantumCircuit(qubits: 1)
    qc.ry(theta, 0); qc.rz(phi, 0)
    return qc.run()
}()
let codeword = StateVector([psiOnly[0], .zero, .zero, .zero, .zero, .zero, .zero, psiOnly[1]])
let syndromeIndex: [String: Int] = ["none": 0, "q0": 2, "q1": 3, "q2": 1]

func withDecode(errors: [Int]) -> QuantumCircuit {
    let qc = syndromeCircuit(errors: errors)
    qc.apply(correction)
    qc.cx(0, 2); qc.cx(0, 1)   // decode: undo the encoding
    return qc
}

let zeroKet = StateVector([Complex(1), .zero])
print("\nerror   fidelity to |ψ⟩⊗|00⟩⊗|syndrome⟩")
for (name, errs) in [("none", []), ("q0", [0]), ("q1", [1]), ("q2", [2])] {
    let state = withDecode(errors: errs).run()
    var syndromeAmps = Array(repeating: Complex.zero, count: 4)
    syndromeAmps[syndromeIndex[name]!] = Complex(1)
    let expected = psiOnly ⊗ zeroKet ⊗ zeroKet ⊗ StateVector(syndromeAmps)
    var overlap = Complex.zero
    for i in 0..<32 { overlap = overlap + state[i].conjugate * expected[i] }
    print("\(name)     \(String(format: "%.4f", overlap.magnitudeSquared))")
}
```

```text
error   syndrome (q3 q4)   P
none     00              1.0000
q0     10              1.0000
q1     11              1.0000
q2     01              1.0000

error   fidelity to |ψ⟩⊗|00⟩⊗|syndrome⟩
none     1.0000
q0     1.0000
q1     1.0000
q2     1.0000
```

```swift
import SwiftQiskit

// Section 5: a continuous rx(θ) error, digitized exactly by the same correction.
// Reuses syndromeCircuit/correction/psiOnly/zeroKet from the snippet above.
print("θ       fidelity   P(syndrome none)  P(syndrome q0)")
for (name, t) in [("0    ", 0.0), ("π/6  ", Double.pi / 6), ("π/3  ", Double.pi / 3),
                   ("π/2  ", Double.pi / 2), ("π    ", Double.pi)] {
    let qc = QuantumCircuit(qubits: 5)
    qc.ry(theta, 0); qc.rz(phi, 0)
    qc.cx(0, 1); qc.cx(0, 2)
    qc.rx(t, 0)
    qc.cx(0, 3); qc.cx(1, 3)
    qc.cx(1, 4); qc.cx(2, 4)
    qc.apply(correction)
    qc.cx(0, 2); qc.cx(0, 1)
    let state = qc.run()

    let ancilla = StateVector([Complex(cos(t / 2)), .zero, Complex(0, -sin(t / 2)), .zero])
    let expected = psiOnly ⊗ zeroKet ⊗ zeroKet ⊗ ancilla
    var overlap = Complex.zero
    for i in 0..<32 { overlap = overlap + state[i].conjugate * expected[i] }

    var pNone = 0.0, pQ0 = 0.0
    for i in 0..<32 {
        let suffix = lbl(i, 5).suffix(2)
        if suffix == "00" { pNone += state.probabilities[i] }
        if suffix == "10" { pQ0 += state.probabilities[i] }
    }
    print("\(name)   \(String(format: "%.4f", overlap.magnitudeSquared))     \(String(format: "%.4f", pNone))            \(String(format: "%.4f", pQ0))")
}
```

```text
θ       fidelity   P(syndrome none)  P(syndrome q0)
0       1.0000     1.0000            0.0000
π/6     1.0000     0.9330            0.0670
π/3     1.0000     0.7500            0.2500
π/2     1.0000     0.5000            0.5000
π       1.0000     0.0000            1.0000
```

```swift
import Foundation

// Section 6: two simultaneous errors, and the enumerated logical error rate.
func minorityCorrectionFails(_ flippedQubits: [Int]) -> Bool {
    var flips = [0, 0, 0]
    for q in flippedQubits { flips[q] = 1 }
    var corrected = flips
    switch (flips[0] ^ flips[1], flips[1] ^ flips[2]) {
    case (1, 0): corrected[0] ^= 1
    case (1, 1): corrected[1] ^= 1
    case (0, 1): corrected[2] ^= 1
    default: break
    }
    return corrected != [0, 0, 0]
}
func logicalErrorRate(_ p: Double) -> Double {
    var total = 0.0
    for mask in 0..<8 {
        let pattern = (0..<3).filter { (mask >> $0) & 1 == 1 }
        let k = pattern.count
        if minorityCorrectionFails(pattern) {
            total += pow(p, Double(k)) * pow(1 - p, Double(3 - k))
        }
    }
    return total
}
print("p       p_L (enumerated)   formula 3p²-2p³")
for p in [0.05, 0.1, 0.2, 0.3, 0.5] {
    let formula = 3 * p * p - 2 * p * p * p
    print("\(String(format: "%.2f", p))    \(String(format: "%.4f", logicalErrorRate(p)))              \(String(format: "%.4f", formula))")
}
```

```text
p       p_L (enumerated)   formula 3p²-2p³
0.05    0.0073              0.0073
0.10    0.0280              0.0280
0.20    0.1040              0.1040
0.30    0.2160              0.2160
0.50    0.5000              0.5000
```

Finally, the app-path walkthrough behind "Build it in the app," driving `CircuitBuilder`
directly and formatting output as `ResultsView`'s panel does (`panelRows`, reused unchanged
from Chapters 13–17):

```swift
import Foundation
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

var b = CircuitBuilder(qubitCount: 3)
b.place(.ry(Double.pi / 3), qubits: [0], column: 0)
b.place(.rz(Double.pi / 4), qubits: [0], column: 1)
b.place(.cx, qubits: [0, 1], column: 2)
b.place(.cx, qubits: [0, 2], column: 3)
b.place(.x, qubits: [1], column: 4)          // the error, worked example: q1
b.place(.cx, qubits: [0, 1], column: 5)      // decode
b.place(.cx, qubits: [0, 2], column: 6)
// Toffoli(controls: q1, q2; target: q0) = H(0); CCZ(1,2,0); H(0)
b.place(.h, qubits: [0], column: 7)
b.place(.cx, qubits: [2, 0], column: 8)
b.place(.tdg, qubits: [0], column: 9)
b.place(.cx, qubits: [1, 0], column: 10)
b.place(.t, qubits: [0], column: 11)
b.place(.cx, qubits: [2, 0], column: 12)
b.place(.tdg, qubits: [0], column: 13)
b.place(.cx, qubits: [1, 0], column: 14)
b.place(.t, qubits: [2], column: 15)
b.place(.t, qubits: [0], column: 15)
b.place(.cx, qubits: [1, 2], column: 16)
b.place(.t, qubits: [1], column: 17)
b.place(.tdg, qubits: [2], column: 17)
b.place(.cx, qubits: [1, 2], column: 18)
b.place(.h, qubits: [0], column: 19)

print("column count:", b.columnCount())
for row in panelRows(b.buildCircuit().run(), qubits: 3) { print(row) }

let shots = b.buildCircuit().measure(shots: 1000)
print("\n1000 shots (q0 q1 q2):")
for (state, count) in shots.sortedCounts { print("  \(state): \(count)") }
```

```text
column count: 20
|010⟩: 0.8001031451912656 - 0.3314135740355918i  (p=0.750)
|110⟩: 0.46193976625564315 + 0.19134171618254484i  (p=0.250)

1000 shots (q0 q1 q2):
  010: 750
  110: 250
```

## Try it yourself

1. Inject errors on two of the three qubits simultaneously and confirm the code corrects to the
   wrong logical state.
   <details><summary>Answer</summary>A distance-3 code only guarantees correction of a single
   error; two simultaneous errors are indistinguishable from a single error on the third qubit.
   Running the app-tappable circuit with |ψ⟩ = |1⟩ and errors on q0 and q1 gives decoded
   P(0) = 1.0000, P(1) = 0.0000 — a confidently wrong answer, exactly §19.5's
   distance-3 breakdown.</details>

2. Inject a `z` error (instead of `x`) directly on the bit-flip code above, with none of §19.6's
   Hadamards. Predict the syndrome, then check q0's Bloch point.
   <details><summary>Answer</summary>The syndrome (parities of computational-basis labels) reads
   00 — a bare Z error doesn't flip any bit, so the parity checks see nothing wrong, and the
   Toffoli never fires. The result is a *logical* Z: q0's Bloch point comes out
   `x −0.6124  y −0.6124  z 0.5000`, Z|ψ⟩ — x and y flip sign, z is untouched, and no correction
   was ever applied. This is exactly why §19.6 needs the surrounding Hadamards: without them,
   the bit-flip code is blind to phase errors.</details>

3. Inject a `y` error on q0 instead of `x`, and predict what the bit-flip correction can and
   can't fix.
   <details><summary>Answer</summary>Y = iXZ up to a global phase, so the correction's Toffoli
   (built to undo bit flips) fixes the X part and leaves the Z part untouched. Running it: q0's
   Bloch point comes out `x −0.6124  y −0.6124  z 0.5000` — exactly Z|ψ⟩, the same point as
   exercise 2. A Y error on the bit-flip code always reduces to an uncorrected logical
   Z.</details>

4. Move the continuous `rx(θ)` error from q0 to q2 and predict how the syndrome weights
   change.
   <details><summary>Answer</summary>The syndrome now splits between "none" (00) and "q2" (01)
   instead of "none" and "q0" (10), but the weights are the same cos²(θ/2)/sin²(θ/2) split —
   confirmed at θ = π/3 (0.7500/0.2500) and θ = π/2 (0.5000/0.5000) — and q0's Bloch point stays
   pinned at |ψ⟩'s exact point, `x 0.6124  y 0.6124  z 0.5000`, for every θ. The correction
   doesn't care which data qubit the error landed on.</details>

---
[← Chapter 18](18-Teleportation.md) · [Contents](../../INTRODUCTION.md) · [Chapter 20 →](20-CHSH.md)
