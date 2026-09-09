# An Introduction to Quantum Computing, with SwiftQiskitApp

A book-length walkthrough of quantum computing, taught through this app and its underlying
simulator, [SwiftQiskit](../SwiftQiskit). It teaches the physics first and the Swift second:
every claim in every chapter is something you can run yourself and see for real, either by
tapping gates onto the app's grid or by running a few lines of `SwiftQiskitCore` code.

This is not a reference manual — [Docs/Tutorial.md](Docs/Tutorial.md) and
[Docs/Help.md](Docs/Help.md) already cover *how to use the app*. This is *what quantum
computing is*, using the app and the package as the running example.

> **Work in progress.** Most chapters below are still stubs (summary and section headings only,
> no prose yet) — see the Status column in the chapter table. Completion is targeted,
> optimistically, for late 2027.

## Who this is for

Anyone who uses Swift and Xcode and has an interest in quantum physics and how mathematical
modeling can be used to describe quantum computing — wanting to understand qubits, gates,
entanglement, and the handful of famous algorithms (Deutsch, Grover, Shor, teleportation, VQE,
…) by building and running small circuits rather than by reading equations alone. Terms are
explained before they're used; linear algebra is introduced as needed in Chapter 2.

## Three ways to run everything

Every chapter shows its examples in whichever of these apply, and says so with an **app badge**
(below):

1. **The app (`SwiftQiskitApp`)** — tap gates onto the circuit grid, watch the state vector and
   Bloch spheres update live. Good for anything the gate palette can express: see
   [Docs/Tutorial.md](Docs/Tutorial.md) for the controls.
2. **A playground page** — open `../SwiftQiskit/Playgrounds.playground` in Xcode, pick the page
   named in the chapter's table, and run it. This is where the chapters' code originates; the
   playground's own `PlaygroundDocs/NN…HELP.md` guide is the answer key.
3. **Plain code** — `import SwiftQiskitCore` and write a few lines directly (in a Swift file, a
   playground, or via the `RunCodeSnippet` tool). This is the only option for anything beyond the
   app's fixed gate set — custom matrices via `apply(_:)`, mid-circuit measurement, density
   matrices — and every such chapter says so explicitly.

**Setup note:** this app depends on `../SwiftQiskit` as a sibling folder (a relative-path Swift
package). If you're reading this from a checkout where that folder is missing, package
resolution will fail — see [README.md](README.md) → Requirements.

## Conventions

- **Qubit 0 is the most-significant (leftmost) bit** in every ket — `|q0 q1 q2…⟩` — matching both
  the package and the app.
- Math is plain Unicode in running text (`|ψ⟩`, `θ`, `⊗`, `√2`, `⟨ψ|X|ψ⟩`), never LaTeX, so it
  reads the same in a terminal, a `.md` viewer, or GitHub.
- **App badge**, next to each chapter: **●** Full (every step is tappable in the app as described),
  **◐** Partial (some steps are tappable; the rest — and exactly what's missing — are called out),
  **○** Not expressible (the chapter is code-only; the app's fixed single/two-qubit gate palette
  can't reach it).
- **Statistical results jitter.** Anything from `measure(shots:)` is probabilistic — printed
  counts are one real run, not an exact ratio you should expect to reproduce bit-for-bit.
- Each chapter lists **Prerequisites** by chapter number, not by assumed background — you can
  always jump back.

## The chapters

| # | Title | App | Status | Source |
|---|---|---|---|---|
| 0 | [What Quantum Computing Is, and Why Simulate It](Docs/Introduction/00-Introduction.md) | — | draft | — |
| 1 | [Setup and Orientation](Docs/Introduction/01-Setup.md) | ● | draft | — |
| 2 | [Complex Numbers and Matrices in Swift](Docs/Introduction/02-ComplexAndMatrices.md) | ○ | done | `Math/Complex.swift`, `Math/Matrix.swift`, `Quantum/Dirac.swift` |
| 3 | [Qubits: Amplitudes and Probabilities](Docs/Introduction/03-Qubits.md) | ● | done | [`01Qubits`](../SwiftQiskit/PlaygroundDocs/01QUBITSHELP.md) |
| 4 | [Dirac Notation and Expectation Values](Docs/Introduction/04-DiracNotation.md) | ◐ | done | [`01Qubits`](../SwiftQiskit/PlaygroundDocs/01QUBITSHELP.md), [`08Dirac`](../SwiftQiskit/PlaygroundDocs/08DIRACHELP.md) |
| 5 | [The Bloch Sphere in 2D, and Its Projections](Docs/Introduction/05-BlochSphere2D.md) | ◐ | stub | [`02Bloch2d`](../SwiftQiskit/PlaygroundDocs/02BLOCH2DHELP.md), [`03Bloch2dProjection`](../SwiftQiskit/PlaygroundDocs/03BLOCH2DPROJECTIONHELP.md) |
| 6 | [The Bloch Sphere in 3D: θ and φ](Docs/Introduction/06-BlochSphere3D.md) | ○ | stub | [`04Bloch3d`](../SwiftQiskit/PlaygroundDocs/04BLOCH3DHELP.md) |
| 7 | [Single-Qubit Gates, One at a Time](Docs/Introduction/07-SingleQubitGates.md) | ● | stub | [`05Gates`](../SwiftQiskit/PlaygroundDocs/05GATESHELP.md) |
| 8 | [Phase, Interference, and Why Z Hides](Docs/Introduction/08-Interference.md) | ● | stub | [`05Gates`](../SwiftQiskit/PlaygroundDocs/05GATESHELP.md) §4, [`01Qubits`](../SwiftQiskit/PlaygroundDocs/01QUBITSHELP.md) |
| 9 | [Measurement, Shots and Statistics](Docs/Introduction/09-Measurement.md) | ● | stub | `Quantum/SimulationResult.swift` |
| 10 | [Superposition Across a Register](Docs/Introduction/10-Superposition.md) | ● | stub | [`06Superposition`](../SwiftQiskit/PlaygroundDocs/06SUPERPOSITIONHELP.md) |
| 11 | [Tensor Products and Composite Systems](Docs/Introduction/11-TensorProducts.md) | ◐ | stub | [`09Tensor`](../SwiftQiskit/PlaygroundDocs/09TENSORHELP.md) |
| 12 | [Entanglement: Bell and GHZ](Docs/Introduction/12-Entanglement.md) | ● | stub | [`07Entanglement`](../SwiftQiskit/PlaygroundDocs/07ENTANGLEMENTHELP.md) |
| 13 | [Oracles and Phase Kickback: Deutsch's Algorithm](Docs/Introduction/13-Deutsch.md) | ● | stub | [`10DeutschExample`](../SwiftQiskit/PlaygroundDocs/10DEUTSCHHELP.md) |
| 14 | [Deutsch–Jozsa and Bernstein–Vazirani](Docs/Introduction/14-DeutschJozsa.md) | ● | stub | [`17DeutschJozsa`](../SwiftQiskit/PlaygroundDocs/17DEUTSCHJOZSAHELP.md) |
| 15 | [Grover's Search](Docs/Introduction/15-Grover.md) | ◐ | stub | [`11GroverExample`](../SwiftQiskit/PlaygroundDocs/11GROVERHELP.md) |
| 16 | [The Quantum Fourier Transform and Phase Estimation](Docs/Introduction/16-QFT.md) | ◐ | stub | [`16QFT`](../SwiftQiskit/PlaygroundDocs/16QFTHELP.md) |
| 17 | [Shor's Algorithm, Compiled](Docs/Introduction/17-Shor.md) | ○ | stub | [`12ShorExample`](../SwiftQiskit/PlaygroundDocs/12SHORHELP.md) |
| 18 | [Teleportation and Superdense Coding](Docs/Introduction/18-Teleportation.md) | ◐ | stub | [`13Teleportation`](../SwiftQiskit/PlaygroundDocs/13TELEPORTATIONHELP.md) |
| 19 | [Quantum Error Correction](Docs/Introduction/19-ErrorCorrection.md) | ◐ | stub | [`14ErrorCorrection`](../SwiftQiskit/PlaygroundDocs/14ERRORCORRECTIONHELP.md) |
| 20 | [Bell Tests: The CHSH Inequality](Docs/Introduction/20-CHSH.md) | ◐ | stub | [`15CHSH`](../SwiftQiskit/PlaygroundDocs/15CHSHHELP.md) |
| 21 | [Noise, Density Matrices and Channels](Docs/Introduction/21-Noise.md) | ○ | stub | [`19Noise`](../SwiftQiskit/PlaygroundDocs/19NOISEHELP.md) |
| 22 | [State Tomography](Docs/Introduction/22-Tomography.md) | ◐ | stub | [`20Tomography`](../SwiftQiskit/PlaygroundDocs/20TOMOGRAPHYHELP.md) |
| 23 | [Variational Algorithms: VQE](Docs/Introduction/23-VQE.md) | ◐ | stub | [`18VQE`](../SwiftQiskit/PlaygroundDocs/18VQEHELP.md) |
| 24 | [Hamiltonian Simulation and Trotter Error](Docs/Introduction/24-Trotter.md) | ◐ | stub | [`21Trotter`](../SwiftQiskit/PlaygroundDocs/21TROTTERHELP.md) |
| 25 | [Discrete-Time Quantum Walks](Docs/Introduction/25-QuantumWalks.md) | ○ | stub | [`22Walk`](../SwiftQiskit/PlaygroundDocs/22WALKHELP.md) |
| 26 | [Epilogue: Where to Go Next](Docs/Introduction/26-Epilogue.md) | — | stub | — |

Status moves `stub` → `draft` → `done` as each chapter is written; this table is the single
progress tracker (see [Docs/Introduction/AUTHORING.md](Docs/Introduction/AUTHORING.md) for the
per-chapter workflow).

## Reading paths

- **Foundations** (0–12) — what quantum computing is, then everything you need before any named
  algorithm: qubits, gates, phase, measurement, tensor products, entanglement.
- **Algorithms** (13–20) — the classic results: Deutsch/Deutsch–Jozsa, Grover, the QFT, Shor,
  teleportation, error correction, and the CHSH inequality's link to entanglement.
- **Beyond pure states** (21–25) — where the state-vector simulator's assumptions start to show:
  noise and density matrices, tomography, variational methods, Trotterized simulation, and
  quantum walks.

## Related documentation

- [README.md](README.md), [Docs/Tutorial.md](Docs/Tutorial.md), [Docs/Help.md](Docs/Help.md) —
  the app itself, not the physics.
- [../SwiftQiskit/README.md](../SwiftQiskit/README.md) and its `PlaygroundDocs/` — the simulator
  and the original 22 playground pages this introduction is built from.
- [Docs/Introduction/AUTHORING.md](Docs/Introduction/AUTHORING.md) — chapter template, style
  rules, and verification workflow for anyone (human or Claude) writing the next chapter.
