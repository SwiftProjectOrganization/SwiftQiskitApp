# Chapter 0 — What Quantum Computing Is, and Why Simulate It

> A short preview of what quantum computers are (and aren't) good for, and why a book about *simulating* is worth your time at all.


## 0.1 Who this book is for

This book assumes you use Swift and Xcode. It assumes interest in quantum physics and how mathematical
modeling can be used to describe quantum computing.

Terms are explained before they are used, and the math that quantum computing does need — complex numbers,
a little linear algebra — is introduced gradually, starting in Chapter 2. The associated macOS, iOS or 
iPadOs app, [SwiftQiskitApp](https://github.com/SwiftProjectOrganization/SwiftQiskitApp), is used to illustrate the concepts.

The plan for the book: this chapter and Chapter 1 orient you: what quantum computing is, and
what tools you need. 

Chapters 2–12 build the foundations — amplitudes, qubits, gates, phase,
measurement, tensor products, entanglement — using both the app and the underlying
[SwiftQiskit](https://github.com/SwiftProjectOrganization/SwiftQiskit) simulator. 

Chapters 13–20 cover the classic named algorithms. Most of these can be, at least partially,
demonstrated using the SwiftQiskitApp.

Chapters 21–25 look at where a pure-state simulator's assumptions start to show. 

Every chapter's examples are things you run yourself, in the app or in Swift, not equations 
to take on faith.


## 0.2 From quanta to Sycamore

Quantum computing's history has three phases.

**Early quantum theory (1900s–1920s).** Max Planck introduced *quanta* — the idea that energy
comes in discrete packets rather than a smooth continuum. Niels Bohr used the idea to explain why
electron orbits come in fixed levels. Erwin Schrödinger and Werner Heisenberg then built the
complete mathematical framework — quantum mechanics — that describes *superposition* and
*entanglement*, two words this chapter defines properly in §0.3 rather than assuming you already
know them.

**Quantum information (1970s–1980s).** Physicists started asking what quantum mechanics implies
for *information*, not just for particles. Paul Benioff modeled a quantum version of a Turing
machine, connecting quantum physics to computer science for the first time.

**Quantum computing proper (1980s onward).** Richard Feynman made the observation this entire
book exists to illustrate: classical computers cannot efficiently simulate quantum systems,
because the amount of information needed to describe *n* interacting qubits grows exponentially
with *n*, not linearly. Feynman's proposal was to fight fire with fire — build a computer that is
itself a quantum system, so that simulating quantum mechanics stops being exponentially expensive.
That is the seed every algorithm in Chapters 13–20 grew from.

You can watch Feynman's exponential wall directly in this app: `CircuitBuilder` caps you at 8
qubits (`CircuitBuilder.maxQubits`, `SwiftQiskitApp/CircuitModel.swift`), because a state vector
for `n` qubits holds 2ⁿ complex numbers, and doubling `n` from 8 to 16 would multiply that count
by 256. `SwiftQiskitCore` is exactly the classical simulation Feynman said was expensive — this
book's running example *is* the problem quantum computers exist to solve, running at a scale
small enough that an ordinary computer can still do it exactly. It's also why Chapter 17's Shor's
algorithm is "compiled" down to factoring the number 15 rather than something a real
cryptographic key would use: 15 is the largest case this simulator, and most laptops, can still
represent exactly.

The clearest recent landmark: in 2019 Google announced that its 53-qubit Sycamore processor had
completed a specific calculation in 200 seconds that the company estimated would take the world's
most powerful supercomputer of the day about 10,000 years. IBM publicly disputed the comparison,
and researchers debated whether the chosen problem was representative of anything useful. Both
things are true at once, and holding them together is the right instinct: something a classical
computer could not practically match had clearly happened, *and* the specific headline number was
contestable. §0.7 comes back to this as the model for how to read every quantum computing claim
you'll meet after this book.

## 0.3 What quantum computing is

A classical bit is 0 or 1, full stop. A **qubit** can be 0, can be 1, or can be in a
**superposition** — genuinely both at once, not "we don't know which yet." That distinction is
not philosophical hedging; superposition has measurable consequences that a mere unknown
classical bit does not have, and Chapter 8 shows you one of those consequences directly
(interference making a phase flip visible that no single measurement could ever reveal on its
own).

When you **measure** a qubit, the superposition ends and you get 0 or 1 with probabilities set by
the superposition's composition. That randomness is not a gap in your knowledge waiting to be
filled in — it is, as far as anyone has ever been able to tell, a fundamental feature of nature.

The app makes this concrete: its State Vector panel is a *simulator's* privilege
— it shows you every amplitude at once, something no real quantum computer will ever hand you —
while its **Measure** button and histogram show you the one thing a real device actually gives
you: samples that jitter run to run. Chapter 9 is built entirely around that jitter.

Two more properties matter beyond superposition:

**Entanglement** is a correlation between qubits that has no classical equivalent: once two
qubits are entangled, measuring one changes what you can say about the other, no matter how far
apart they are. Einstein called this "spooky action at a distance." You can see its visual
signature in this app right now, without writing a line of code: build a Bell state (Chapter 12
walks through exactly how), open the **Display** sheet, and watch both qubits' Bloch-sphere
arrows collapse to the center of the sphere — `|r| ≈ 0` in the readout underneath. An entangled
qubit, looked at on its own, has no single point on the sphere to call its own.

**Interference** lets quantum states combine so that correct answers reinforce each other and
wrong ones cancel out. This is the actual engine behind every quantum algorithm in Chapters 13–20
— not raw parallelism, but steering probability toward the answer you want before you ever
measure.

## 0.4 What quantum computing is not

Three common misconceptions, worth naming explicitly before they take root:

- **It is not "trying every possibility at once."** A quantum computer does not explore 2ⁿ
  answers independently and hand you the best one for free; every algorithm still has to do real
  work arranging interference so that the wrong answers cancel and the right one survives
  measurement.
- **It is not universally faster than classical computing.** For most problems your laptop
  already solves well, a quantum computer offers no advantage at all. The skill worth building is
  knowing *which* problems benefit — not assuming all of them do.
- **It is not a replacement for your laptop or phone.** Quantum computers are, and will likely
  remain, specialist co-processors for particular problem shapes, not general-purpose machines.

Two more worth adding, specific to reading this book with a *simulator* in hand:

- **A state vector is not something a real quantum computer will show you.** `SwiftQiskitCore`
  can print every amplitude because it's running on ordinary classical hardware, cheating (in the
  best sense) at a scale where cheating is still tractable. A real device gives you only
  measurement outcomes — the histogram, never the amplitudes behind it.
- **One run of `measure(shots:)` is not the answer.** Every measurement count in this book is one
  real sample from a probabilistic process; a re-run will land close but not identical. State
  every result you see that way — "≈ 0.500", never "exactly 0.500" — a habit this book keeps up
  in every later chapter.

## 0.5 Where we are now, and what this simulator leaves out

Today's quantum computers are in what researchers call the **NISQ** era — Noisy
Intermediate-Scale Quantum. Real devices have tens to hundreds of qubits, but those qubits are
imperfect: they lose their quantum properties quickly, a process called **decoherence**, and
every gate applied to them introduces some error. NISQ machines are useful for research and a
narrowing set of specialized tasks, but not yet for breaking encryption or simulating a
genuinely complex molecule.

`SwiftQiskitCore` sidesteps NISQ noise entirely, and it's worth being honest about exactly what
that buys you and costs you. This simulator is **noiseless** and works with **pure states**
only — every amplitude is an exact double-precision complex number, and there is no decoherence,
no gate error, and no density matrix anywhere in `SwiftQiskitCore` itself. That is precisely why
Chapter 21 has to *hand-build* Kraus channels (bit-flip, phase-flip, depolarizing, amplitude
damping) from scratch using nothing but existing gate matrices — there is no `.noise()` call to
reach for — and why Chapter 19's error-correction chapter has to build its own syndrome-correction
matrix by hand rather than calling into the library. Every gate you place in the app runs exactly,
every time; a real NISQ device would not make that promise.

## 0.6 What quantum computers might be good for

Four areas show real promise, with real caveats attached — and each maps onto a later chapter of
this book:

**Cryptography** cuts both ways. Shor's algorithm, given a large enough error-corrected quantum
computer, could break RSA and similar schemes that protect internet traffic today (Chapter 17,
badge ○ — compiled down to factoring 15, the largest case a classical simulator can still
represent exactly). That is not possible yet; today's machines are too small and too error-prone.
But the threat is credible enough that organizations are already migrating to
"post-quantum" cryptographic standards. On the defensive side, quantum key distribution offers
communication security based on physics rather than on an unproven mathematical assumption.

**Simulating molecules and materials** is a natural fit, because classical computers struggle
with exactly the exponential cost §0.2 described — and a quantum computer could, in principle,
represent a quantum system directly instead of approximating it. Chapter 23 (VQE) and Chapter 24
(Trotterized Hamiltonian simulation) both build small, honest versions of this idea.

**Optimization** problems — routing, scheduling, portfolio allocation — appear everywhere in
industry, and some may benefit from quantum approaches, though the size of the advantage is still
under active investigation.

**Machine learning** gets the most hype and, so far, the least settled evidence: some quantum
algorithms offer theoretical speedups for specific learning tasks, but whether that translates
into a practical advantage on real problems remains an open question.

## 0.7 Why this matters even if you never write quantum code

Four reasons to keep half an eye on this field regardless of whether you ever ship a quantum
program:

- **Security awareness.** The migration to post-quantum cryptography is happening now, not in
  some hypothetical future; understanding why helps you make informed calls about long-term data
  protection.
- **Claim evaluation.** Quantum computing shows up in news coverage and vendor pitches constantly.
  §0.2's Sycamore story — a real result *and* a contested headline number, simultaneously — is
  the template for reading the next one: ask what was actually measured, and what was merely
  claimed.
- **Career positioning.** Quantum computing expertise is increasingly valuable; starting now,
  even casually, positions you well for a technology that will keep maturing over the next
  decade.
- **Cheap intuition.** Reading and running a small simulator — this book's whole method — is the
  least expensive way to build real intuition about qubits, gates, and measurement, without
  needing access to actual quantum hardware.

## 0.8 How to read this book

Each numbered chapter follows the same shape:

- A one-line **summary** of what you'll be able to do afterward that you couldn't before.
- An **at-a-glance table** — the playground page it's drawn from, an **app badge**, the
  `SwiftQiskitCore` APIs it uses, and its prerequisite chapters.
- Numbered **sections** teaching the idea in prose first, math and code second.
- **Build it in the app** — concrete tap-by-tap steps, or (see the badge below) an honest account
  of what the app's fixed gate palette can't reach and how to get there in code instead.
- **Run it in code** — a `SwiftQiskitCore` snippet with its *real, actually-run* output pasted
  beneath it. Nothing in this book is a value copied from a reference doc and left unverified.
- **Try it yourself** — a handful of exercises with answers tucked into `<details>` blocks, so
  you can attempt them before peeking.

The **app badge** tells you how far the app's fixed single- and two-qubit gate palette can carry
a chapter: **●** full (every step is tappable as described), **◐** partial (some steps are
tappable; the rest, and exactly what's missing, are named explicitly), **○** not expressible at
all (the chapter is code-only, because it needs something — a custom matrix, mid-circuit
measurement, a density matrix — the app's palette can't reach).

## 0.9 Key terms

| Term | Meaning | Where it's built |
|---|---|---|
| Qubit | The quantum analogue of a bit; can be in superposition | Chapter 3 |
| Superposition | A qubit existing in a combination of \|0⟩ and \|1⟩, not merely an unknown classical value | Chapters 3, 7 |
| Amplitude | The complex number attached to each basis state whose squared magnitude gives a probability | Chapter 3 |
| State vector | The full list of amplitudes describing a circuit's current state | Chapter 3 |
| Ket | Dirac's bracket notation \|ψ⟩ for a quantum state | Chapter 4 |
| Gate | An operation that transforms a state, e.g. `H`, `X`, `CX` | Chapters 7–8 |
| Circuit | An ordered sequence of gates applied to a register of qubits | Chapters 1, 3 |
| Interference | Quantum states combining so right answers reinforce and wrong ones cancel | Chapter 8 |
| Entanglement | Correlation between qubits with no classical equivalent | Chapter 12 |
| Shot | One sampled measurement outcome from `measure(shots:)` | Chapter 9 |
| Bloch sphere | A geometric picture of a single qubit's state as a point (or shorter arrow, if entangled) on/in a sphere | Chapters 5–6 |
| NISQ | Noisy Intermediate-Scale Quantum — today's era of small, imperfect quantum devices | §0.5 |
| Decoherence | The loss of a qubit's quantum properties through interaction with its environment | §0.5, Chapter 21 |

## Try it yourself

1. The app's State Vector panel lists every amplitude in the circuit you've built. Name two
   things a real quantum computer would refuse to tell you that this panel shows you for free,
   and say why a real device can't.
   <details><summary>Answer</summary>A real device can't hand you the amplitudes themselves (only
   measurement outcomes), and it can't repeat a "run" deterministically the way `run()` does here
   — every real measurement is a fresh probabilistic sample, and even preparing the "same" state
   twice is subject to NISQ-era gate error the simulator doesn't have.</details>

2. Two people disagree about a quantum computing headline: one says "this proves quantum
   computers are now faster than classical computers at everything," the other says "this is
   meaningless PR." Using §0.2's Sycamore example as a model, what's wrong with each claim?
   <details><summary>Answer</summary>The first overgeneralizes a narrow, specific result to "at
   everything" — Sycamore's speedup was on one contrived problem, not a general one, and §0.4
   says explicitly that quantum computers aren't universally faster. The second dismisses a real,
   verifiable technical result (IBM disputed the *comparison*, not that Sycamore did something
   classically impractical) just because the framing was contested.</details>

3. Why does this book cap circuits at 8 qubits in the app, rather than, say, 50?
   <details><summary>Answer</summary>A state vector for `n` qubits holds 2ⁿ complex numbers; going
   from 8 to 16 qubits multiplies that by 256, and by 50 qubits the vector no longer fits in any
   computer's memory. `CircuitBuilder.maxQubits` keeps the simulator inside the range a classical
   machine can represent exactly — the same exponential wall §0.2 describes.</details>

## Acknowledgement

This chapter's shape — its historical arc, its "what it is / what it is not" framing, and its
closing key-terms glossary — is adapted from Brian Enochson's article
["Our Quantum Future — Part 1: Quantum Computing Introduction"](https://brianenochson.medium.com/our-quantum-future-part-1-quantum-computing-introduction-f03aa4fc5f7f)
(Medium, Dec 2025), already listed as reference 2 in [`../SwiftQiskit/README.md`](../../../SwiftQiskit/README.md).
The prose, the SwiftQiskit- and SwiftQiskitApp-specific framing throughout, and every
cross-reference to this book's own chapters are original to this book.

---
[Contents](../../INTRODUCTION.md) · [Chapter 1 →](01-Setup.md)
