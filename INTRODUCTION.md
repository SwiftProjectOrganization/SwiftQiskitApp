# An Introduction to Quantum Computing, with SwiftQiskitApp ("the App")

A book-length walkthrough of quantum computing, taught through this App, its underlying
simulator ([SwiftQiskit](https://github.com/SwiftProjectOrganization/SwiftQiskit)), the playgrounds in [SwiftQiskitPlaygrounds](https://github.com/SwiftProjectOrganization/SwiftQiskitPlaygrounds) and standalone applications, possibly
generated from playground templates, e.g. [SwiftQiskitWalkDemo](https://github.com/SwiftProjectOrganization/SwiftQiskitWalkDemo).

It teaches the underlying quantum computing math, how to confirm the math using the simulator and finally Swift if the App can't express it.

> **Work in progress.** Most chapters need substantial updates. Completion is targeted,
> optimistically, for late 2027.

## Who this is for

Anyone who uses Swift and Xcode and has an interest in quantum physics and how mathematical
modeling can be used to describe quantum computing — wanting to understand qubits, gates,
entanglement and a handful of famous algorithms (Deutsch, Grover, Shor, teleportation, VQE,
…) by building and running small circuits rather than by reading equations alone.

## Three ways to run everything

1. **The App (`SwiftQiskitApp`)** — tap gates onto the circuit grid, watch the state vector and
   Bloch spheres update live. Good for anything the gate palette can express: see
   [Docs/Tutorial.md](Docs/Tutorial.md) for the controls.
2. **The Playgrounds (`SwiftQiskitPlaygrounds`)** open the Xcode project (or clone
   [SwiftQiskitPlaygrounds](https://github.com/SwiftProjectOrganization/SwiftQiskitPlaygrounds)),
   build the `PlaygroundDeps` scheme on My Mac, then run a page. It uses `SwiftQiskit` as a
   remote package, like the App, so it needs no `SwiftQiskit` checkout. It contains one page per chapter
   (`01Matrices` through `26TensorDiagrams`, plus `50StateVectorCPU`); it is a starting
   point for new users to experiment with the SwiftQiskit library and Swift.
3. **Plain code** — `import SwiftQiskit` and write a few lines directly (in a Swift file or an
   app). This is a good option for anything beyond the app's fixed gate set. See
   [SwiftQiskitWalkDemo](https://github.com/SwiftProjectOrganization/SwiftQiskitWalkDemo) for an
   example.

## Conventions

- **Qubit 0 is the most-significant (leftmost) bit** in every ket — `|q0 q1 q2…⟩` — matching both
  the package and the app.
- Math is plain Unicode in running text (`|ψ⟩`, `θ`, `⊗`, `√2`, `⟨ψ|X|ψ⟩`), never LaTeX, so it
  reads the same in a terminal, a `.md` viewer, or GitHub.
- **App badge**, next to each chapter:
  **●** Full (every step is tappable in the app as described),
  **◐** Partial (some steps are tappable; the rest — and exactly what's missing — are called out),
  **○** Not expressible (the chapter is code-only; the app's gate palette
  can't reach it).
- **Statistical results jitter.** Anything from `measure(shots:)` is probabilistic — printed
  counts are one real run, not an exact ratio you should expect to reproduce bit-for-bit.
- Each chapter lists **Prerequisites** by chapter number, not by assumed background — you can
  always jump back.

## The chapters

| # | Title | App | Status | Source |
|---|---|---|---|---|
| 0 | [What Quantum Computing Is, and Why Simulate It](Docs/Introduction/00-Introduction.md) | — | v1 | — |
| 1 | [Setup and Orientation](Docs/Introduction/01-Setup.md) | ● | v1 | — |
| 2 | [Complex Numbers and Matrices in Swift](Docs/Introduction/02-ComplexAndMatrices.md) | ○ | draft | `Math/Complex.swift`, `Math/Matrix.swift`, `Quantum/Dirac.swift` |
| 3 | [Qubits: Amplitudes and Probabilities](Docs/Introduction/03-Qubits.md) | ● | draft | [`03Qubits`](../SwiftQiskitPlaygrounds/SwiftQiskitPlaygrounds.playground/Pages/03Qubits.xcplaygroundpage) |
| 4 | [Dirac Notation and Expectation Values](Docs/Introduction/04-DiracNotation.md) | ◐ | draft | [`03Qubits`](../SwiftQiskitPlaygrounds/SwiftQiskitPlaygrounds.playground/Pages/03Qubits.xcplaygroundpage), [`04Dirac`](../SwiftQiskitPlaygrounds/SwiftQiskitPlaygrounds.playground/Pages/04Dirac.xcplaygroundpage) |
| 5 | [The Bloch Sphere in 2D, and Its Projections](Docs/Introduction/05-BlochSphere2D.md) | ◐ | draft | [`06BlochSpheres`](../SwiftQiskitPlaygrounds/SwiftQiskitPlaygrounds.playground/Pages/06BlochSpheres.xcplaygroundpage) |
| 6 | [The Bloch Sphere in 3D: θ and φ](Docs/Introduction/06-BlochSphere3D.md) | ● | draft | [`06BlochSpheres`](../SwiftQiskitPlaygrounds/SwiftQiskitPlaygrounds.playground/Pages/06BlochSpheres.xcplaygroundpage) |
| 7 | [Gates](Docs/Introduction/07-Gates.md) | ◐ | draft | [`07Gates`](../SwiftQiskitPlaygrounds/SwiftQiskitPlaygrounds.playground/Pages/07Gates.xcplaygroundpage) |
| 8 | [Phase, Interference, and Why Z Hides](Docs/Introduction/08-Interference.md) | ● | draft | [`07Gates`](../SwiftQiskitPlaygrounds/SwiftQiskitPlaygrounds.playground/Pages/07Gates.xcplaygroundpage) §4, [`03Qubits`](../SwiftQiskitPlaygrounds/SwiftQiskitPlaygrounds.playground/Pages/03Qubits.xcplaygroundpage) |
| 9 | [Measurement, Shots and Statistics](Docs/Introduction/09-Measurement.md) | ● | draft | `Quantum/SimulationResult.swift` |
| 10 | [Superposition Across a Register](Docs/Introduction/10-Superposition.md) | ● | draft | [`10Superposition`](../SwiftQiskitPlaygrounds/SwiftQiskitPlaygrounds.playground/Pages/10Superposition.xcplaygroundpage) |
| 11 | [Tensor Products and Composite Systems](Docs/Introduction/11-TensorProducts.md) | ◐ | draft | [`11TensorProducts`](../SwiftQiskitPlaygrounds/SwiftQiskitPlaygrounds.playground/Pages/11TensorProducts.xcplaygroundpage) |
| 12 | [Entanglement: Bell and GHZ](Docs/Introduction/12-Entanglement.md) | ● | draft | [`12Entanglement`](../SwiftQiskitPlaygrounds/SwiftQiskitPlaygrounds.playground/Pages/12Entanglement.xcplaygroundpage) |
| 13 | [Oracles and Phase Kickback: Deutsch's Algorithm](Docs/Introduction/13-Deutsch.md) | ● | draft | [`13Deutsch`](../SwiftQiskitPlaygrounds/SwiftQiskitPlaygrounds.playground/Pages/13Deutsch.xcplaygroundpage) |
| 14 | [Deutsch–Jozsa and Bernstein–Vazirani](Docs/Introduction/14-DeutschJozsa.md) | ● | draft | [`14DeutschJozsa`](../SwiftQiskitPlaygrounds/SwiftQiskitPlaygrounds.playground/Pages/14DeutschJozsa.xcplaygroundpage) |
| 15 | [Grover's Search](Docs/Introduction/15-Grover.md) | ● | draft | [`15Grover`](../SwiftQiskitPlaygrounds/SwiftQiskitPlaygrounds.playground/Pages/15Grover.xcplaygroundpage) |
| 16 | [The Quantum Fourier Transform and Phase Estimation](Docs/Introduction/16-QFT.md) | ● | draft | [`16QFT`](../SwiftQiskitPlaygrounds/SwiftQiskitPlaygrounds.playground/Pages/16QFT.xcplaygroundpage) |
| 17 | [Shor's Algorithm, Compiled](Docs/Introduction/17-Shor.md) | ◐ | draft | [`17Shor`](../SwiftQiskitPlaygrounds/SwiftQiskitPlaygrounds.playground/Pages/17Shor.xcplaygroundpage) |
| 18 | [Teleportation and Superdense Coding](Docs/Introduction/18-Teleportation.md) | ◐ | draft | [`18Teleportation`](../SwiftQiskitPlaygrounds/SwiftQiskitPlaygrounds.playground/Pages/18Teleportation.xcplaygroundpage) |
| 19 | [Quantum Error Correction](Docs/Introduction/19-ErrorCorrection.md) | ● | draft | [`19ErrorCorrection`](../SwiftQiskitPlaygrounds/SwiftQiskitPlaygrounds.playground/Pages/19ErrorCorrection.xcplaygroundpage) |
| 20 | [Bell Tests: The CHSH Inequality](Docs/Introduction/20-CHSH.md) | ● | draft | [`20CHSH`](../SwiftQiskitPlaygrounds/SwiftQiskitPlaygrounds.playground/Pages/20CHSH.xcplaygroundpage) |
| 21 | [Noise, Density Matrices and Channels](Docs/Introduction/21-Noise.md) | ◐ | draft | [`21Noise`](../SwiftQiskitPlaygrounds/SwiftQiskitPlaygrounds.playground/Pages/21Noise.xcplaygroundpage) |
| 22 | [State Tomography](Docs/Introduction/22-Tomography.md) | ◐ | draft | [`22Tomography`](../SwiftQiskitPlaygrounds/SwiftQiskitPlaygrounds.playground/Pages/22Tomography.xcplaygroundpage) |
| 23 | [Variational Algorithms: VQE](Docs/Introduction/23-VQE.md) | ◐ | draft | [`23VQE`](../SwiftQiskitPlaygrounds/SwiftQiskitPlaygrounds.playground/Pages/23VQE.xcplaygroundpage) |
| 24 | [Hamiltonian Simulation and Trotter Error](Docs/Introduction/24-Trotter.md) | ◐ | draft | [`24Trotter`](../SwiftQiskitPlaygrounds/SwiftQiskitPlaygrounds.playground/Pages/24Trotter.xcplaygroundpage) |
| 25 | [Discrete-Time Quantum Walks](Docs/Introduction/25-QuantumWalks.md) | ◐ | draft | [`25QuantumWalks`](../SwiftQiskitPlaygrounds/SwiftQiskitPlaygrounds.playground/Pages/25QuantumWalks.xcplaygroundpage) |
| 26 | [Tensor Diagrams](Docs/Introduction/26-TensorDiagrams.md) | ● | draft | [`26TensorDiagrams`](../SwiftQiskitPlaygrounds/SwiftQiskitPlaygrounds.playground/Pages/26TensorDiagrams.xcplaygroundpage) |
| 27 | [Epilogue: Where to Go Next](Docs/Introduction/27-Epilogue.md) | — | stub | — |

Status moves `stub` → `draft` → `done` as each chapter is written; this table is the single
progress tracker (see [Docs/Introduction/AUTHORING.md](Docs/Introduction/AUTHORING.md) for the
per-chapter workflow).

## Reading paths

- **Foundations** (0–12) — what quantum computing is, then everything you need before any named
  algorithm: qubits, gates, phase, measurement, tensor products, entanglement.
- **Algorithms** (13–20) — the classic results: Deutsch/Deutsch–Jozsa, Grover, the QFT, Shor,
  teleportation, error correction, and the CHSH inequality's link to entanglement.
- **Beyond pure states** (21–26) — where the state-vector simulator's assumptions start to show:
  noise and density matrices, tomography, variational methods, Trotterized simulation, quantum
  walks, and reading a circuit as a tensor network instead of a sequence of full matrices.

## Related documentation

- [README.md](README.md), [Docs/Tutorial.md](Docs/Tutorial.md), [Docs/Help.md](Docs/Help.md) —
  the app itself, not the physics.
- [Docs/Introduction/AUTHORING.md](Docs/Introduction/AUTHORING.md) — chapter template, style
  rules, and verification workflow for anyone (human or Claude) writing the next chapter.
