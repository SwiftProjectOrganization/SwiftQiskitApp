# Chapter 17 — Shor's Algorithm, Compiled

> Factoring 15 by finding a period: the classical reduction from factoring to order-finding,
> modular multiplication as a hand-built permutation matrix, phase estimation reading the order
> out of a counting register, and the classical gcd step that turns it into a factor — including
> the one base, `a = 14`, where that last step fails. A closing section then asks how few qubits
> the app's fixed palette actually needs once the base and its order are known, and builds two of
> the six coprime bases from nothing but `h`/`x`/`cx`.

| | |
|---|---|
| Playground page | [`12ShorExample`](../../../SwiftQiskit/PlaygroundDocs/12SHORHELP.md) |
| In the app | ◐ — `a = 11` and `a = 14` (order 2) compile down to `h`/`x`/`cx` plus a single closing `h`; `a = 7` (order 4, optional) needs one Toffoli, built the way Chapter 15 built its CCZ; the general permutation `U_a` and the entrywise QFT† matrix stay code-only |
| Library APIs | `QuantumCircuit.h/x/t/tdg/cx/p`, `apply(_:)`, `Matrix`, `⊗`, postfix `†`, `.run()`, `.probabilities`, `measure(shots:)`, `CircuitBuilder` |
| Prerequisites | Chapters 11, 13, 15, 16 |

## 17.1 From factoring to order finding

Every known classical algorithm for factoring a composite number takes super-polynomial time —
the presumed hardness of factoring is what RSA encryption rests on. Shor's algorithm (Peter Shor,
1994) factors in polynomial time on a quantum computer, the result that made quantum computing
famous. It works by reducing factoring to a different-looking problem: pick a base `a` coprime to
`N` and find its *order* — the smallest r > 0 with `a^r ≡ 1 (mod N)`. If r is even and
`a^(r/2) ≢ −1 (mod N)`, then `(a^(r/2) − 1)(a^(r/2) + 1) = a^r − 1 ≡ 0 (mod N)` while neither
factor is itself `≡ 0`, so each shares a nontrivial divisor with N — `gcd(a^(r/2) ± 1, N)` are
nontrivial factors. And if `a` isn't even coprime to N, no quantum computer is needed:
`gcd(a, N)` is already a factor.

| a | gcd(a,15) | |
|---|---|---|
| 3, 5, 6, 9, 10, 12 | 3 or 5 | lucky guess — already a factor |
| 2, 4, 7, 8, 11, 13, 14 | 1 | coprime — needs the order r |

```text
 a   gcd(a,15)
 2        1      coprime — needs the order r
 3        3      lucky guess — 3 is already a factor
 4        1      coprime — needs the order r
 5        5      lucky guess — 5 is already a factor
 6        3      lucky guess — 3 is already a factor
 7        1      coprime — needs the order r
 8        1      coprime — needs the order r
 9        3      lucky guess — 3 is already a factor
10        5      lucky guess — 5 is already a factor
11        1      coprime — needs the order r
12        3      lucky guess — 3 is already a factor
13        1      coprime — needs the order r
14        1      coprime — needs the order r
```

The quantum part finds r by phase estimation (Chapter 16) on the modular multiplication operator
`U_a|w⟩ = |a·w mod N⟩`, whose eigenvalues `e^(2πi·s/r)`, s = 0…r−1, encode r. This chapter runs the
**compiled** N = 15 instance — the smallest number Shor can factor, and the one first demonstrated
on real hardware (IBM, 2001). Every order mod 15 divides 4, so 3 counting qubits give perfectly
sharp peaks with no continued-fraction step: reducing the measured y/8 to lowest terms is enough.

| § | What happens |
|---|---|
| 17.2 | The classical answer key: powers of 7 mod 15 |
| 17.3 | Modular multiplication as a permutation matrix, and its orbit |
| 17.4 | Two routes to the inverse QFT: gate ladder vs. entrywise matrix |
| 17.5 | The full circuit for a = 7, stage by stage |
| 17.6 | Sampling the counting register |
| 17.7 | Classical post-processing: from y to the factors |
| 17.8 | A base sweep, including the a = 14 failure |
| 17.9 | Compiling further: as many qubits as the base actually needs |

## 17.2 The classical answer key: powers of 7 mod 15

Before building anything quantum, compute the order directly — a cheat sheet to check the
hardware against:

```text
7^k mod 15, k = 0…7:  1 7 4 13 1 7 4 13
7^2 ≡ 4: gcd(3,15)=3, gcd(5,15)=5
```

The sequence repeats with period r = 4: `ord₁₅(7) = 4`. §17.1's reduction already delivers
`15 = 3 × 5` from this alone. Everything from here on is about finding r = 4 *without* the cheat
sheet.

## 17.3 Modular multiplication as a permutation

For `a` coprime to 15, `w ↦ a·w mod 15` permutes {0, …, 14} — reversible, hence unitary, with
exactly one 1 per column. The 4-qubit work register has 16 basis states; the unused `|15⟩` is a
fixed point:

```swift
func modMultiplyGate(_ a: Int) -> Matrix {
    var m = Matrix(rows: 16, cols: 16)
    for w in 0..<15 { m[(a * w) % 15, w] = .one }
    m[15, 15] = .one
    return m
}
```

`U₇ * U₇† == I` exactly — a permutation matrix holds only 0s and 1s, so `Matrix`'s `==` has no
rounding to forgive. Walking U₇ from `|1⟩` traces its orbit:

```text
U₇ exactly unitary: true
start:  |0001⟩: 1.0
U₇^1:   |0111⟩: 1.0
U₇^2:   |0100⟩: 1.0
U₇^3:   |1101⟩: 1.0
U₇^4:   |0001⟩: 1.0
```

`|0001⟩ → |0111⟩ → |0100⟩ → |1101⟩` and back (1 → 7 → 4 → 13 → 1): the orbit closes after exactly
r = 4 steps. The order is a geometric fact about U₇ before it is a spectral one — §17.9 returns to
this orbit directly.

## 17.4 Two routes to the inverse QFT: gate ladder vs. entrywise matrix

Chapter 16 built the inverse QFT as a gate ladder — Hadamards and controlled-phase gates, then a
swap network. `12ShorExample` builds the same operator a second way: the *matrix* is just the
inverse discrete Fourier transform, `QFT†[y, c] = e^(−2πi·y·c/8)/√8`, written entrywise with
`cos`/`sin` and fed to `apply(_:)`. Working with the whole matrix sidesteps the ladder's
bit-reversal bookkeeping entirely — qubit 0 is the MSB and `Matrix.tensor` puts its left factor in
the high bits, so the register's index within its 8-dimensional block *is* the integer c directly.

Both routes are exactly the same operator, checked against each other rather than against the
formula a second time:

```text
gate-level inverse QFT vs. entrywise matrix, all 8 basis states: max amplitude deviation = 1.3743915342634358e-15
```

Fifteen digits of agreement — Chapter 16's ladder and this chapter's matrix implement the same
unitary. The matrix route is what `12ShorExample` uses throughout, embedded across the full
register as `qft3Dagger ⊗ Matrix.identity(size: 16)`.

## 17.5 The full circuit for a = 7, stage by stage

Two registers, 7 qubits total (qubit 0 is the most-significant bit, as always): counting qubits
0–2, work qubits 3–6, holding the register index `count·16 + work`.

```text
counting q0–q2: |0⟩ ─ H ──●───────────────┐
                |0⟩ ─ H ──┼──●────────────┤ QFT† ── measure y ≈ 8·s/r
                |0⟩ ─ H ──┼──┼──●─────────┘
                          │  │  │
work     q3–q6: |0001⟩ ── U⁴ U² U¹ ──────── (never read)
```

Counting qubit k has bit weight `2^(2−k)` in the count, so it controls `U₇^(2^(2−k))` — qubit 0's
power is the identity, since `7⁴ ≡ 1`:

```text
counting qubit k → controlled power of 7:
  qubit 0 (bit weight 4):  U₇^4 = ×1 mod 15
  qubit 1 (bit weight 2):  U₇^2 = ×4 mod 15
  qubit 2 (bit weight 1):  U₇^1 = ×7 mod 15
```

Because qubit 0's operation is a no-op, the work register is still the classical value 1 when
qubit 1's `×4` is applied — only qubit 2's `×7`, applied last, ever acts on a work register already
spread across two values. That ordering detail is exactly what makes §17.9's shortcut work.

Growing the circuit and reading `run()` after each stage:

```text
stage 1: |0000001⟩: 0.3536   |0010001⟩: 0.3536   |0100001⟩: 0.3536   |0110001⟩: 0.3536   |1000001⟩: 0.3536   |1010001⟩: 0.3536   |1100001⟩: 0.3536   |1110001⟩: 0.3536
stage 2: |0000001⟩: 0.3536   |0010111⟩: 0.3536   |0100100⟩: 0.3536   |0111101⟩: 0.3536   |1000001⟩: 0.3536   |1010111⟩: 0.3536   |1100100⟩: 0.3536   |1111101⟩: 0.3536

stage 3, grouped by y:
  y = 0:  work 1: 0.25   work 4: 0.25   work 7: 0.25   work 13: 0.25
  y = 2:  work 1: 0.25   work 4: -0.25   work 7: -0.25i   work 13: 0.25i
  y = 4:  work 1: 0.25   work 4: 0.25   work 7: -0.25   work 13: -0.25
  y = 6:  work 1: 0.25   work 4: -0.25   work 7: 0.25i   work 13: -0.25i

y    P(y)
0    0.2500
1    0.0000
2    0.2500
3    0.0000
4    0.2500
5    0.0000
6    0.2500
7    0.0000
```

Stage 1: every count c from 000 to 111, work register frozen at 1. Stage 2: the work value cycles
1, 7, 4, 13 as c counts up, repeating with period r = 4 — the period is now written across the
state, but measuring here would just return one random `(c, 7^c)` pair. Stage 3, after QFT†: only
even y survive, each with the four work values at magnitude 0.25 and y-dependent phases — the
counting register's marginal (summed over the never-read work register, since there is no partial
measurement API) is exactly 0.2500 at y = 0, 2, 4, 6 and zero at odd y. The work register's `|1⟩`
is an equal superposition of U₇'s eigenvectors, so phase estimation lands on one of the four
phases at random — exactly the mechanism Chapter 16 §16.7 built standalone.

## 17.6 Sampling the counting register

At dimension 128 every controlled multiplication is a dense 128×128 matrix, but one `run()` is
still only tens of milliseconds. `measure(shots:)` replays every recorded operation per shot, so
1000 shots at this dimension would take most of a minute; sampling one run's `probabilities`
directly is statistically identical for a full measurement of a pure state, and instant:

```text
1000 shots of the counting register:
  000: 240
  010: 237
  100: 276
  110: 247
```

Four bins near 250, as the exact marginals predict — this is one real run; a re-run will jitter by
about ±40 per bin, not land on this split again.

## 17.7 Classical post-processing: from y to the factors

A measured y estimates the phase `y/8 ≈ s/r` for a uniformly random `s ∈ {0, …, r−1}`. Because r
divides 8 here, `y/8` *equals* `s/r` exactly, and reducing to lowest terms reveals a candidate r —
which still must be verified, since s can share a factor with r:

```text
y   phase   lowest terms   candidate r   7^r mod 15   verdict
0   0/8     0/1            1             7            ✗ retry
2   2/8     1/4            4             1            ✓ order found
4   4/8     1/2            2             4            ✗ retry
6   6/8     3/4            4             1            ✓ order found

r = 4:  7^(r/2) ≡ 4,  gcd(3,15)=3,  gcd(5,15)=5
```

y = 2 and y = 6 both yield r = 4. y = 0 reduces to 0/1 — s = 0 says nothing, retry. y = 4 reduces
to 1/2, so the candidate is r = 2, but `7² ≡ 4 ≠ 1`: s = 2 shared a factor with r = 4. Half of all
shots find the order outright; a real run just measures again. `15 = 3 × 5` — the quantum computer
has factored 15.

## 17.8 A base sweep, including the a = 14 failure

Nothing above was special to a = 7. One function builds the order-finding circuit for any coprime
base, and a second applies §17.1's reduction:

```text
 a    r    a^(r/2)   result
 2    4     4        15 = 3 × 5
 4    2     4        15 = 3 × 5
 7    4     4        15 = 3 × 5
 8    4     4        15 = 3 × 5
11    2    11        15 = 5 × 3
13    4     4        15 = 3 × 5
14    2    14        ✗ a^(r/2) ≡ −1 — trivial factors, pick another a
```

Six of the seven coprime bases factor 15 outright. Only `a = 14 ≡ −1 (mod 15)` hits the unlucky
branch: `a^(r/2) = 14 ≡ −1`, so `gcd(14 − 1, 15) = gcd(13, 15) = 1` and
`gcd(14 + 1, 15) = gcd(15, 15) = 15` — both trivial. A real run of Shor's algorithm guesses `a` at
random, so a retry or two settles it: 15 = 3 × 5, in polynomial time.

## 17.9 Compiling further: as many qubits as the base actually needs

`12ShorExample` fixes 3 counting qubits for every base, for uniformity across §17.8's sweep. But
Chapter 16 §16.8 already showed that precision scales with the number of counting qubits — n
counting qubits resolve phases with denominator dividing 2^n exactly, and no more precision than
that is ever needed. Every order mod 15 is 2 or 4, so:

- **Order 2** (`a = 4, 11, 14`) needs only **n = 1** counting qubit — the phase is 0 or ½, one
  binary digit. The inverse QFT of one qubit is a single `H` (Chapter 16 §16.7's "1 qubit: max
  |QFT† − H| ≈ 1e-16" result), so a single H closes the circuit.
- **Order 4** (`a = 2, 7, 8, 13`) needs only **n = 2** counting qubits.

That alone shrinks the counting register, but the work register can shrink too. §17.5 noted that
qubit 0's controlled power was always the identity — a consequence of the order dividing the
qubit's bit weight — so *only the last controlled multiplication in the chain ever meets a work
register already in superposition*. For an order-2 base, there is only one controlled
multiplication at all, and it always acts on the classical value 1 — so it is nothing more than a
fixed bit-flip mask, `cx` gates from the single counting qubit straight onto the work register,
no ancilla needed. The mask is just `1 ⊕ (a mod 15)` written in 4 bits:

| a | 1 ⊕ a (4 bits) | flips |
|---|---|---|
| 11 | 1010 | bit-weight-8 and bit-weight-2 work qubits |
| 14 | 1111 | every work qubit |

For an order-4 base like `a = 7`, the *second* controlled multiplication (`×7`, controlled by the
lowest-weight counting qubit) meets a work register already spread over `{1, 4}` — masking no
longer works, since `1 ⊕ 7 = 0110` but `4 ⊕ 13 = 1001`: two different masks for the same gate. The
orbit from §17.3 supplies the fix: only 4 of the 16 work states are ever reached, so instead of a
4-qubit register holding the raw mod-15 value, a 2-qubit register can hold the *orbit step*
(0, 1, 2, 3 for values 1, 7, 4, 13). `×7` becomes "add 1 mod 4" on that 2-qubit register, and `×4`
(= `×7` twice) becomes "add 2 mod 4" — adding 2 mod 4 always flips only the top bit, a single `cx`;
adding 1 mod 4 is the standard 2-bit increment (flip the low bit; flip the high bit only when the
low bit was 1, i.e. a carry) — controlled, that carry is exactly a Toffoli, and the app has no
Toffoli tile. Chapter 15 §15.9 already built one from three palette gates alone — `t`, `tdg`, and
`cx` — as a controlled-Z; conjugating its target qubit with `H` on either side turns that CCZ into
a Toffoli (`H(target); CCZ; H(target)`), so no `apply(_:)` is needed here either.

## Build it in the app

◐ Every step starts from **Clear**. Qubit 0 is the leftmost bit in every panel row, as throughout
this book — but note that these compiled circuits use a *different*, smaller register layout than
`12ShorExample`'s fixed 7-qubit one, per §17.9. Unlike Chapter 16, nothing here needs the P tile's
slider — one or two counting qubits is exact for every order this chapter meets, so every gate
lands on a palette tile exactly.

1. **a = 11 (order 2, success).** Qubits: 5 — q0 is the single counting qubit, q1–q4 the work
   register (q1 the most-significant work bit). Arm **X**, tap `q4` in column 0 (work ← `|0001⟩`,
   the value 1). Arm **H**, tap `q0` in column 0. **CX** `q0`→`q1` (col 1), **CX** `q0`→`q3`
   (col 2) — the `1010` mask from §17.9. Arm **H**, tap `q0` in column 3 (the inverse QFT of one
   qubit). Panel: four rows at flat `p=0.250` — `|00001⟩`, `|01011⟩`, `|10001⟩`, `|11011⟩`: `q0`
   paired with work `0001` (=1) when `q0=0`, work `1011` (=11) when `q0=1`. Set **Shots: 1000**,
   tap **Measure**: roughly half the shots land `q0=0`, half `q0=1` (a genuine 50/50, no sharper
   peak — order 2 needs exactly one bit). Reading `q0=1` as y = 1: candidate r = 2/gcd(1,2) = 2;
   `11² mod 15 = 1` ✓. `11¹ ≡ 11`: `gcd(10, 15) = 5`, `gcd(12, 15) = 3` — `15 = 5 × 3`.
2. **a = 14 (order 2, failure).** Clear, Qubits: 5. Same X and H taps in column 0. Then the
   `1111` mask: **CX** `q0`→`q1` (col 1), `q0`→`q2` (col 2), `q0`→`q3` (col 3), `q0`→`q4` (col 4).
   Arm **H**, tap `q0` in column 5. Panel: `|00001⟩`, `|01110⟩`, `|10001⟩`, `|11110⟩`, again flat
   at `p=0.250` and a 50/50 split under Measure. Reading `q0=1` gives the same r = 2, but
   `14¹ ≡ 14 ≡ −1`: `gcd(13, 15) = 1` and `gcd(15, 15) = 15` — both trivial. Same circuit shape,
   same order, and the base alone decides success or failure — entirely in the classical gcd step
   §17.1 described, not in anything the quantum part did differently.
3. **Optional: a = 7 (order 4).** Clear, Qubits: 4 — q0, q1 counting (q0 the higher weight, ×4);
   q2, q3 the 2-qubit orbit register (q2 the high bit), starting at `00` (step 0, value 1, so no
   `X` tap is needed here). Arm **H**, tap `q0` and `q1` in column 0. **CX** `q0`→`q2` (col 1) —
   "add 2 mod 4," controlled ×4. Then the controlled ×7 ("add 1 mod 4"): a Toffoli on
   (control `q1`, control `q3`, target `q2`) built as `H(q2)` (col 2), Chapter 15 §15.9's 13-gate
   CCZ sequence on `(q1, q3, q2)` (cols 3–15: `cx q3→q2`, `tdg q2`, `cx q1→q2`, `t q2`,
   `cx q3→q2`, `tdg q2`, `cx q1→q2`, `t q3`, `t q2`, `cx q1→q3`, `t q1`, `tdg q3`, `cx q1→q3`),
   then `H(q2)` (col 16) to close the Toffoli, then **CX** `q1`→`q3` (col 17, the increment's
   remaining low-bit flip). Then the 2-qubit inverse QFT on `q0`/`q1`: swap as three CX's (cols
   18–20), **H** `q1` (col 21), CP(−π/2) in T†/T form (**T†** `q1` col 22, **CX** `q1`→`q0`
   col 23, **T** `q0` col 24, **CX** `q1`→`q0` col 25, **T†** `q0` col 26), **H** `q0` (col 27).
   28 columns total. Panel: sixteen rows at flat `p=0.062` (= ¼ × ¼, since the orbit register's
   own two bits are still visible in the panel, ungrouped) — grouping by `q0 q1` alone reproduces
   the ¼-¼-¼-¼ split at y = 0, 1, 2, 3 that §17.5's raw 7-qubit circuit found at y = 0, 2, 4, 6 (the
   same peaks at half the resolution, since this register only needs 2 bits, not 3). Measuring
   `q0 q1 = 01` or `11` gives r = 4 and `7⁴ ≡ 1` ✓, exactly as §17.7 found by hand.

What's still missing: a generic controlled-`U_a` for an arbitrary, unknown input (the app can only
compile a circuit once it already knows the base *and* which single input it will run on — a real
attacker doesn't get to assume that), the exact entrywise QFT† matrix, and any way to read a
counting-register marginal directly — the panel and the Measure histogram always show every qubit,
so grouping by the counting bits is left to the reader, as step 3 above does by hand.

## Run it in code

Every snippet below was run with `RunCodeSnippet` against
`SwiftQiskitApp/SwiftQiskitApp/CircuitModel.swift`.

```swift
import Foundation
import SwiftQiskit

func gcd(_ a: Int, _ b: Int) -> Int { b == 0 ? a : gcd(b, a % b) }
func modPow(_ base: Int, _ exponent: Int, _ modulus: Int) -> Int {
    var result = 1, square = base % modulus, e = exponent
    while e > 0 { if e & 1 == 1 { result = result * square % modulus }; square = square * square % modulus; e >>= 1 }
    return result
}

print(" a   gcd(a,15)")
for a in 2...14 {
    let g = gcd(a, 15)
    let note = g > 1 ? "lucky guess — \(g) is already a factor" : "coprime — needs the order r"
    print(String(format: "%2d       %2d      ", a, g) + note)
}

var powers: [Int] = []
for k in 0..<8 { powers.append(modPow(7, k, 15)) }
print("\n7^k mod 15, k = 0…7:  \(powers.map(String.init).joined(separator: " "))")
let half7 = modPow(7, 2, 15)
print("7^2 ≡ \(half7): gcd(\(half7-1),15)=\(gcd(half7-1,15)), gcd(\(half7+1),15)=\(gcd(half7+1,15))")

func modMultiplyGate(_ a: Int) -> Matrix {
    var m = Matrix(rows: 16, cols: 16)
    for w in 0..<15 { m[(a * w) % 15, w] = .one }
    m[15, 15] = .one
    return m
}
func fmt(_ value: Complex) -> String {
    func rounded(_ x: Double) -> Double { abs(x) < 1e-9 ? 0 : (x * 10_000).rounded() / 10_000 }
    return Complex(rounded(value.real), rounded(value.imag)).description
}
func pretty(_ state: StateVector, qubits: Int) -> String {
    (0..<state.dimension).filter { state[$0].magnitude > 1e-10 }.map { index -> String in
        var label = String(index, radix: 2)
        while label.count < qubits { label = "0" + label }
        return "|\(label)⟩: \(fmt(state[index]))"
    }.joined(separator: "   ")
}

let u7 = modMultiplyGate(7)
print("\nU₇ exactly unitary:", u7† * u7 == Matrix.identity(size: 16))
let orbit = QuantumCircuit(qubits: 4)
orbit.x(3)
print("start:  \(pretty(orbit.run(), qubits: 4))")
for step in 1...4 {
    orbit.apply(u7)
    print("U₇^\(step):   \(pretty(orbit.run(), qubits: 4))")
}
```

```text
 a   gcd(a,15)
 2        1      coprime — needs the order r
 3        3      lucky guess — 3 is already a factor
 4        1      coprime — needs the order r
 5        5      lucky guess — 5 is already a factor
 6        3      lucky guess — 3 is already a factor
 7        1      coprime — needs the order r
 8        1      coprime — needs the order r
 9        3      lucky guess — 3 is already a factor
10        5      lucky guess — 5 is already a factor
11        1      coprime — needs the order r
12        3      lucky guess — 3 is already a factor
13        1      coprime — needs the order r
14        1      coprime — needs the order r

7^k mod 15, k = 0…7:  1 7 4 13 1 7 4 13
7^2 ≡ 4: gcd(3,15)=3, gcd(5,15)=5

U₇ exactly unitary: true
start:  |0001⟩: 1.0
U₇^1:   |0111⟩: 1.0
U₇^2:   |0100⟩: 1.0
U₇^3:   |1101⟩: 1.0
U₇^4:   |0001⟩: 1.0
```

```swift
import Foundation
import SwiftQiskit

func cp(_ qc: QuantumCircuit, _ theta: Double, _ control: Int, _ target: Int) {
    qc.p(theta / 2, control); qc.cx(control, target); qc.p(-theta / 2, target); qc.cx(control, target); qc.p(theta / 2, target)
}
func swapQubits(_ qc: QuantumCircuit, _ a: Int, _ b: Int) { qc.cx(a, b); qc.cx(b, a); qc.cx(a, b) }
func appendInverseQFT(_ qc: QuantumCircuit, qubits n: Int) {
    for q in 0..<(n / 2) { swapQubits(qc, q, n - 1 - q) }
    for j in stride(from: n - 1, through: 0, by: -1) {
        for k in stride(from: n - 1, through: j + 1, by: -1) { cp(qc, -2 * Double.pi / pow(2.0, Double(k - j + 1)), k, j) }
        qc.h(j)
    }
}
func inverseQFTMatrix(size: Int) -> Matrix {
    var m = Matrix(rows: size, cols: size)
    let scale = 1.0 / sqrt(Double(size))
    for y in 0..<size {
        for c in 0..<size {
            let theta = -2.0 * Double.pi * Double(y * c) / Double(size)
            m[y, c] = Complex(cos(theta), sin(theta)) * scale
        }
    }
    return m
}
func basisPrep(_ qc: QuantumCircuit, _ c: Int, qubits n: Int) {
    for q in 0..<n where (c >> (n - 1 - q)) & 1 == 1 { qc.x(q) }
}

let n = 3
let qftDaggerMatrix = inverseQFTMatrix(size: 8)
var maxDeviation = 0.0
for c in 0..<8 {
    let gateQC = QuantumCircuit(qubits: n)
    basisPrep(gateQC, c, qubits: n)
    appendInverseQFT(gateQC, qubits: n)
    let gateAmps = gateQC.run().amplitudes

    let matrixQC = QuantumCircuit(qubits: n)
    basisPrep(matrixQC, c, qubits: n)
    matrixQC.apply(qftDaggerMatrix)
    let matrixAmps = matrixQC.run().amplitudes

    for y in 0..<8 { maxDeviation = max(maxDeviation, (gateAmps[y] - matrixAmps[y]).magnitude) }
}
print("gate-level inverse QFT vs. entrywise matrix, all 8 basis states: max amplitude deviation =", maxDeviation)
```

```text
gate-level inverse QFT vs. entrywise matrix, all 8 basis states: max amplitude deviation = 1.3743915342634358e-15
```

```swift
import Foundation
import SwiftQiskit

func fmt(_ value: Complex) -> String {
    func rounded(_ x: Double) -> Double { abs(x) < 1e-9 ? 0 : (x * 10_000).rounded() / 10_000 }
    return Complex(rounded(value.real), rounded(value.imag)).description
}
func pretty(_ state: StateVector, qubits: Int) -> String {
    (0..<state.dimension).filter { state[$0].magnitude > 1e-10 }.map { index -> String in
        var label = String(index, radix: 2)
        while label.count < qubits { label = "0" + label }
        return "|\(label)⟩: \(fmt(state[index]))"
    }.joined(separator: "   ")
}
func gcd(_ a: Int, _ b: Int) -> Int { b == 0 ? a : gcd(b, a % b) }
func modPow(_ base: Int, _ exponent: Int, _ modulus: Int) -> Int {
    var result = 1, square = base % modulus, e = exponent
    while e > 0 { if e & 1 == 1 { result = result * square % modulus }; square = square * square % modulus; e >>= 1 }
    return result
}

func controlledModMultiply(controlQubit: Int, multiplier: Int) -> Matrix {
    var m = Matrix(rows: 128, cols: 128)
    for index in 0..<128 {
        let count = index >> 4, work = index & 15
        var newWork = work
        if (count >> (2 - controlQubit)) & 1 == 1 && work < 15 { newWork = (multiplier * work) % 15 }
        m[(count << 4) | newWork, index] = .one
    }
    return m
}
var qftDagger = Matrix(rows: 8, cols: 8)
for y in 0..<8 { for c in 0..<8 {
    let theta = -2.0 * Double.pi * Double(y * c) / 8.0
    qftDagger[y, c] = Complex(cos(theta), sin(theta)) * (1.0 / sqrt(8.0))
} }

print("counting qubit k → controlled power of 7:")
for k in 0..<3 {
    let power = 1 << (2 - k)
    print("  qubit \(k) (bit weight \(power)):  U₇^\(power) = ×\(modPow(7, power, 15)) mod 15")
}

let shor7 = QuantumCircuit(qubits: 7)
for q in 0..<3 { shor7.h(q) }
shor7.x(6)
print("\nstage 1: \(pretty(shor7.run(), qubits: 7))")
for k in 0..<3 { shor7.apply(controlledModMultiply(controlQubit: k, multiplier: modPow(7, 1 << (2 - k), 15))) }
print("stage 2: \(pretty(shor7.run(), qubits: 7))")
shor7.apply(qftDagger ⊗ Matrix.identity(size: 16))
let final7 = shor7.run()
let finalProbabilities = final7.probabilities
print("\nstage 3, grouped by y:")
for y in 0..<8 {
    let terms = (0..<16).filter { final7[(y << 4) | $0].magnitude > 1e-10 }.map { w in "work \(w): \(fmt(final7[(y << 4) | w]))" }
    if !terms.isEmpty { print("  y = \(y):  \(terms.joined(separator: "   "))") }
}
var marginals = [Double](repeating: 0, count: 8)
for index in 0..<128 { marginals[index >> 4] += finalProbabilities[index] }
print("\ny    P(y)")
for y in 0..<8 { print("\(y)    \(String(format: "%.4f", marginals[y]))") }

func sample(_ probabilities: [Double], shots: Int) -> [Int: Int] {
    var counts: [Int: Int] = [:]
    for _ in 0..<shots {
        var u = Double.random(in: 0..<1); var outcome = probabilities.count - 1
        for (index, p) in probabilities.enumerated() { u -= p; if u < 0 { outcome = index; break } }
        counts[outcome, default: 0] += 1
    }
    return counts
}
var histogram = [Int: Int]()
for (index, count) in sample(finalProbabilities, shots: 1000) { histogram[index >> 4, default: 0] += count }
print("\n1000 shots of the counting register:")
for y in 0..<8 {
    guard let count = histogram[y] else { continue }
    var label = String(y, radix: 2); while label.count < 3 { label = "0" + label }
    print("  \(label): \(count)")
}

print("\ny   phase   lowest terms   candidate r   7^r mod 15   verdict")
for y in [0, 2, 4, 6] {
    let g = gcd(y, 8); let s = y / g; let candidate = 8 / g; let check = modPow(7, candidate, 15)
    let verdict = check == 1 ? "✓ order found" : "✗ retry"
    print("\(y)   \(y)/8     \(s)/\(candidate)            \(candidate)             \(check)            \(verdict)")
}
let h = modPow(7, 2, 15)
print("\nr = 4:  7^(r/2) ≡ \(h),  gcd(\(h-1),15)=\(gcd(h-1,15)),  gcd(\(h+1),15)=\(gcd(h+1,15))")
```

```text
counting qubit k → controlled power of 7:
  qubit 0 (bit weight 4):  U₇^4 = ×1 mod 15
  qubit 1 (bit weight 2):  U₇^2 = ×4 mod 15
  qubit 2 (bit weight 1):  U₇^1 = ×7 mod 15

stage 1: |0000001⟩: 0.3536   |0010001⟩: 0.3536   |0100001⟩: 0.3536   |0110001⟩: 0.3536   |1000001⟩: 0.3536   |1010001⟩: 0.3536   |1100001⟩: 0.3536   |1110001⟩: 0.3536
stage 2: |0000001⟩: 0.3536   |0010111⟩: 0.3536   |0100100⟩: 0.3536   |0111101⟩: 0.3536   |1000001⟩: 0.3536   |1010111⟩: 0.3536   |1100100⟩: 0.3536   |1111101⟩: 0.3536

stage 3, grouped by y:
  y = 0:  work 1: 0.25   work 4: 0.25   work 7: 0.25   work 13: 0.25
  y = 2:  work 1: 0.25   work 4: -0.25   work 7: -0.25i   work 13: 0.25i
  y = 4:  work 1: 0.25   work 4: 0.25   work 7: -0.25   work 13: -0.25
  y = 6:  work 1: 0.25   work 4: -0.25   work 7: 0.25i   work 13: -0.25i

y    P(y)
0    0.2500
1    0.0000
2    0.2500
3    0.0000
4    0.2500
5    0.0000
6    0.2500
7    0.0000

1000 shots of the counting register:
  000: 240
  010: 237
  100: 276
  110: 247

y   phase   lowest terms   candidate r   7^r mod 15   verdict
0   0/8     0/1            1             7            ✗ retry
2   2/8     1/4            4             1            ✓ order found
4   4/8     1/2            2             4            ✗ retry
6   6/8     3/4            4             1            ✓ order found

r = 4:  7^(r/2) ≡ 4,  gcd(3,15)=3,  gcd(5,15)=5
```

```swift
import Foundation
import SwiftQiskit

func gcd(_ a: Int, _ b: Int) -> Int { b == 0 ? a : gcd(b, a % b) }
func modPow(_ base: Int, _ exponent: Int, _ modulus: Int) -> Int {
    var result = 1, square = base % modulus, e = exponent
    while e > 0 { if e & 1 == 1 { result = result * square % modulus }; square = square * square % modulus; e >>= 1 }
    return result
}
func controlledModMultiply(controlQubit: Int, multiplier: Int) -> Matrix {
    var m = Matrix(rows: 128, cols: 128)
    for index in 0..<128 {
        let count = index >> 4, work = index & 15
        var newWork = work
        if (count >> (2 - controlQubit)) & 1 == 1 && work < 15 { newWork = (multiplier * work) % 15 }
        m[(count << 4) | newWork, index] = .one
    }
    return m
}
var qftDagger = Matrix(rows: 8, cols: 8)
for y in 0..<8 { for c in 0..<8 {
    let theta = -2.0 * Double.pi * Double(y * c) / 8.0
    qftDagger[y, c] = Complex(cos(theta), sin(theta)) * (1.0 / sqrt(8.0))
} }
func shorCircuit(a: Int) -> QuantumCircuit {
    let qc = QuantumCircuit(qubits: 7)
    for q in 0..<3 { qc.h(q) }
    qc.x(6)
    for k in 0..<3 { qc.apply(controlledModMultiply(controlQubit: k, multiplier: modPow(a, 1 << (2 - k), 15))) }
    qc.apply(qftDagger ⊗ Matrix.identity(size: 16))
    return qc
}
func shorOrder(a: Int) -> Int? {
    let probabilities = shorCircuit(a: a).run().probabilities
    var counting = [Double](repeating: 0, count: 8)
    for index in 0..<128 { counting[index >> 4] += probabilities[index] }
    var best: Int?
    for y in 1..<8 where counting[y] > 1e-9 {
        let candidate = 8 / gcd(y, 8)
        if modPow(a, candidate, 15) == 1 { best = best.map { min($0, candidate) } ?? candidate }
    }
    return best
}
func shorFactors(a: Int, order: Int) -> (Int, Int)? {
    guard order % 2 == 0 else { return nil }
    let h = modPow(a, order / 2, 15)
    guard (h + 1) % 15 != 0 else { return nil }
    return (gcd(h - 1, 15), gcd(h + 1, 15))
}
print(" a    r    a^(r/2)   result")
for a in [2, 4, 7, 8, 11, 13, 14] {
    guard let order = shorOrder(a: a) else { print(String(format: "%2d    ?", a)); continue }
    let h = modPow(a, order / 2, 15)
    if let (f1, f2) = shorFactors(a: a, order: order) {
        print(String(format: "%2d    %d    %2d        15 = %d × %d", a, order, h, f1, f2))
    } else {
        print(String(format: "%2d    %d    %2d        ✗ a^(r/2) ≡ −1 — trivial factors, pick another a", a, order, h))
    }
}
```

```text
 a    r    a^(r/2)   result
 2    4     4        15 = 3 × 5
 4    2     4        15 = 3 × 5
 7    4     4        15 = 3 × 5
 8    4     4        15 = 3 × 5
11    2    11        15 = 5 × 3
13    4     4        15 = 3 × 5
14    2    14        ✗ a^(r/2) ≡ −1 — trivial factors, pick another a
```

Finally, the app-path walkthrough behind "Build it in the app," driving `CircuitBuilder` directly
and formatting output as `ResultsView`'s panel does (`panelRows`, reused unchanged from
Chapters 13–16):

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

// a = 11, n = 1 counting qubit, 5 qubits total (q0 counting; q1..q4 work)
var b11 = CircuitBuilder(qubitCount: 5)
b11.place(.x, qubits: [4], column: 0)
b11.place(.h, qubits: [0], column: 0)
b11.place(.cx, qubits: [0, 1], column: 1)
b11.place(.cx, qubits: [0, 3], column: 2)
b11.place(.h, qubits: [0], column: 3)
print("a=11 columns:", b11.columnCount())
print("a=11 panel:", panelRows(b11.buildCircuit().run(), qubits: 5))
let result11 = b11.buildCircuit().measure(shots: 1000)
print("a=11 1000 shots:", result11.sortedCounts)

// a = 14, same layout
var b14 = CircuitBuilder(qubitCount: 5)
b14.place(.x, qubits: [4], column: 0)
b14.place(.h, qubits: [0], column: 0)
b14.place(.cx, qubits: [0, 1], column: 1)
b14.place(.cx, qubits: [0, 2], column: 2)
b14.place(.cx, qubits: [0, 3], column: 3)
b14.place(.cx, qubits: [0, 4], column: 4)
b14.place(.h, qubits: [0], column: 5)
print("\na=14 columns:", b14.columnCount())
print("a=14 panel:", panelRows(b14.buildCircuit().run(), qubits: 5))

// a = 7 optional, orbit-index circuit (Toffoli via Chapter 15's CCZ), 4 qubits total
var b7 = CircuitBuilder(qubitCount: 4)
b7.place(.h, qubits: [0], column: 0)
b7.place(.h, qubits: [1], column: 0)
b7.place(.cx, qubits: [0, 2], column: 1)
// Toffoli(control1: 1, control2: 3, target: 2) = H(2); CCZ(1,3,2); H(2)
b7.place(.h, qubits: [2], column: 2)
b7.place(.cx, qubits: [3, 2], column: 3)
b7.place(.tdg, qubits: [2], column: 4)
b7.place(.cx, qubits: [1, 2], column: 5)
b7.place(.t, qubits: [2], column: 6)
b7.place(.cx, qubits: [3, 2], column: 7)
b7.place(.tdg, qubits: [2], column: 8)
b7.place(.cx, qubits: [1, 2], column: 9)
b7.place(.t, qubits: [3], column: 10)
b7.place(.t, qubits: [2], column: 11)
b7.place(.cx, qubits: [1, 3], column: 12)
b7.place(.t, qubits: [1], column: 13)
b7.place(.tdg, qubits: [3], column: 14)
b7.place(.cx, qubits: [1, 3], column: 15)
b7.place(.h, qubits: [2], column: 16)
b7.place(.cx, qubits: [1, 3], column: 17)
// inverse QFT on q0,q1
b7.place(.cx, qubits: [0, 1], column: 18)
b7.place(.cx, qubits: [1, 0], column: 19)
b7.place(.cx, qubits: [0, 1], column: 20)
b7.place(.h, qubits: [1], column: 21)
b7.place(.tdg, qubits: [1], column: 22)
b7.place(.cx, qubits: [1, 0], column: 23)
b7.place(.t, qubits: [0], column: 24)
b7.place(.cx, qubits: [1, 0], column: 25)
b7.place(.tdg, qubits: [0], column: 26)
b7.place(.h, qubits: [0], column: 27)
print("\na=7 orbit-index columns:", b7.columnCount())
print("a=7 orbit-index panel:", panelRows(b7.buildCircuit().run(), qubits: 4))
let result7 = b7.buildCircuit().measure(shots: 1000)
print("a=7 1000 shots:", result7.sortedCounts)
```

```text
a=11 columns: 4
a=11 panel: ["|00001⟩: 0.4999999999999999  (p=0.250)", "|01011⟩: 0.4999999999999999  (p=0.250)", "|10001⟩: 0.4999999999999999  (p=0.250)", "|11011⟩: -0.4999999999999999  (p=0.250)"]
a=11 1000 shots: [(state: "00001", count: 264), (state: "01011", count: 247), (state: "10001", count: 254), (state: "11011", count: 235)]

a=14 columns: 6
a=14 panel: ["|00001⟩: 0.4999999999999999  (p=0.250)", "|01110⟩: 0.4999999999999999  (p=0.250)", "|10001⟩: 0.4999999999999999  (p=0.250)", "|11110⟩: -0.4999999999999999  (p=0.250)"]

a=7 orbit-index columns: 28
a=7 orbit-index panel: ["|0000⟩: 0.2499999999999999  (p=0.062)", "|0001⟩: 0.2499999999999999  (p=0.062)", "|0010⟩: 0.2499999999999999  (p=0.062)", "|0011⟩: 0.2499999999999999  (p=0.062)", "|0100⟩: 0.2499999999999999  (p=0.062)", "|0101⟩: 3.925231146709437e-17 - 0.2499999999999999i  (p=0.062)", "|0110⟩: -0.2499999999999999  (p=0.062)", "|0111⟩: -3.925231146709437e-17 + 0.2499999999999999i  (p=0.062)", "|1000⟩: 0.2499999999999999  (p=0.062)", "|1001⟩: -0.2499999999999999  (p=0.062)", "|1010⟩: 0.2499999999999999  (p=0.062)", "|1011⟩: -0.2499999999999999  (p=0.062)", "|1100⟩: 0.2499999999999999  (p=0.062)", "|1101⟩: -3.925231146709437e-17 + 0.2499999999999999i  (p=0.062)", "|1110⟩: -0.2499999999999999  (p=0.062)", "|1111⟩: 3.925231146709437e-17 - 0.2499999999999999i  (p=0.062)"]
a=7 1000 shots: [(state: "0000", count: 61), (state: "0001", count: 56), (state: "0010", count: 61), (state: "0011", count: 68), (state: "0100", count: 69), (state: "0101", count: 72), (state: "0110", count: 62), (state: "0111", count: 68), (state: "1000", count: 52), (state: "1001", count: 70), (state: "1010", count: 49), (state: "1011", count: 60), (state: "1100", count: 61), (state: "1101", count: 56), (state: "1110", count: 56), (state: "1111", count: 64)]
```

`b11`'s and `b14`'s panels confirm step 1 and step 2's tap sequences exactly, and both time under
half a second for 1000 shots — the compiled circuits are small enough (dimension 32) that the app's
actual **Measure** button is fast, unlike `12ShorExample`'s 128-dimensional circuit. `b7`'s panel
lists all sixteen `q0 q1 q2 q3` combinations rather than grouping by the counting bits alone —
exactly how `ResultsView` really behaves, since it has no notion of "marginal" — but summing the
`0.062` probabilities in groups of four (fixing `q0 q1` and varying `q2 q3`) reproduces the
0.25/0.25/0.25/0.25 split step 3 describes. Re-running any of the shot counts above will land close
to, but not exactly on, the printed splits — Chapter 9's statistics apply here just as everywhere
else in this book.

## Try it yourself

1. §17.5 found that qubit 0's controlled power is always the identity, for every base mod 15, not
   just `a = 7`. Why?
   <details><summary>Answer</summary>Every order mod 15 divides 4 (§17.1's sweep only ever finds
   r = 2 or r = 4). Qubit 0 always controls the highest power, `a^4`, and `a^4 = (a^r)^(4/r)` is a
   power of `a^r ≡ 1`, so it is always `≡ 1` regardless of which coprime base is chosen — the
   identity permutation, contributing no gates at all.</details>

2. §17.9's table gives `a = 11`'s mask as `1010` and `a = 14`'s as `1111`. Work out `a = 4`'s mask
   and predict its app panel.
   <details><summary>Answer</summary>`1 ⊕ 4 = 0001 ⊕ 0100 = 0101` — flip the bit-weight-4 and
   bit-weight-1 work qubits: `cx(q0, q2); cx(q0, q4)` in the 5-qubit layout. Running it confirms
   four rows at flat `p = 0.250`:
   <pre>a=4 panel: ["|00001⟩: +0.500", "|00100⟩: +0.500", "|10001⟩: +0.500", "|10100⟩: -0.500"]</pre>
   `q0 = 0` pairs with both work branches (`0001` and `0100`) at `+0.5`, and `q0 = 1` splits them
   into `+0.5`/`−0.5` — the same four-row, one-negative-sign shape §17.9's `a = 11` panel showed,
   since both circuits are `H`, two `cx`'s, `H` with only the target qubits differing. Order r = 2
   here too: `4¹ ≡ 4`, `gcd(3, 15) = 3`, `gcd(5, 15) = 5` — `15 = 3 × 5`.</details>

3. §17.7 found `y = 4` gives a candidate `r = 2` that fails verification (`7² ≡ 4 ≠ 1`). If a real
   run measured `y = 4` and then, on a retry, measured `y = 2`, how would combining the two
   readings recover r = 4 without knowing the answer key in advance?
   <details><summary>Answer</summary>`y = 4` reduces to candidate 2; `y = 2` reduces to candidate
   4. Taking the `lcm` of every candidate seen so far (`lcm(2, 4) = 4`) and re-verifying
   (`7⁴ ≡ 1` ✓) recovers the true order even from a first candidate that alone failed — the
   standard fallback when a single shot's reduced fraction undershoots r.</details>

4. §17.9 compiled `a = 7`'s work register down to a 2-qubit orbit register, but kept `a = 11` and
   `a = 14`'s at the full 4-bit mod-15 value. Order 2 has only 2 reachable states, so a single
   orbit bit would suffice there too — what would that circuit look like, and what would it cost
   to build it that way?
   <details><summary>Answer</summary>`H(q0); CX(q0, b0); H(q0)`, measuring `q0` — two qubits, three
   gates, identical for *every* order-2 base, since "add 1 mod 2" is just a single unconditional
   bit flip regardless of which base produced that order. The saving is real (2 qubits instead of
   5), but the price is that `a = 11` and `a = 14` now build the exact same circuit — the quantum
   part only ever finds r, never distinguishes which base produced it. §17.1's gcd step, run on
   the actual value of `a` afterward, is the only place success and failure ever diverge; §17.9's
   fuller version (keeping the raw work register) was chosen here so the two bases' circuits stay
   visibly different, at the cost of two extra qubits.</details>

---
[← Chapter 16](16-QFT.md) · [Contents](../../INTRODUCTION.md) · [Chapter 18 →](18-Teleportation.md)
