# SwiftQiskitApp

**SwiftQiskitApp** is a SwiftUI app for building quantum circuits by tapping gates onto a
grid (circuit)  instead of writing code.

Place gates, watch the state vector update live, then measure
with as many shots as you like and see a histogram of the outcomes. Display the Bloch sphere(s)
 (final and after each step) and a tensor network representation.

 It is intended as a "get familiar" tool for playing around with
quantum circuits. SwiftQiskit playgrounds allow you to go a few steps further, but soon e.g. Julia's Yao (see reference 5) will be a better option.

> This app is a thin front end. All quantum simulation — state vectors, gates, measurement —
> is implemented by the [SwiftQiskit](https://github.com/SwiftProjectOrganization/SwiftQiskit)
> package; this repo contributes only the UI and a small model that replays placed gates onto a
> `QuantumCircuit`.

---

## Requirements

- Xcode 27, macOS 27 / iOS 27.
- No local setup beyond that — Xcode resolves the `SwiftQiskit` package dependency from GitHub
  automatically. A sibling checkout of
  [SwiftQiskit](https://github.com/SwiftProjectOrganization/SwiftQiskit) is only needed if you
  want to browse its playground pages (see `Docs/Introduction/01-Setup.md`).

## Getting started

1. Open `SwiftQiskitApp.xcodeproj` in Xcode.
2. Pick a run destination — **My Mac**, or an iOS device/simulator.
3. Run (⌘R). The app opens on an empty 2-qubit circuit.

See [Docs/Tutorial.md](Docs/Tutorial.md) for a full walkthrough that builds and measures a
Bell state.

---

## Features

- **Gate palette** — Hadamard/Pauli (`H X Y Z`), phase (`S S† T T†`), rotations
  (`P RX RY RZ`, each with a θ parameter), the two-qubit `CX` (CNOT), `CZ` and `SWAP`, and the
  two-qubit rotations `RZZ RXX RYY` (each with a θ parameter).
- **Tap-to-place** — arm a gate in the palette, then tap a wire to place it. Multi qubit gates need multiple taps in the same column: `CX` distinguishes control from target, while
  `CZ`, `SWAP` and `RZZ`/`RXX`/`RYY` treat the two taps the same way.
- **Live state vector** — recomputed on every change, no explicit "run" step.
- **Measure** — choose a shot count (1–10,000) and see a bar-chart histogram of the results.
- **1–8 qubits**, adjustable with a stepper; shrinking the count drops gates that no longer fit.
- **θ editor** — tap a placed parameterized gate to open a popover with a 0–2π slider.
- **Bloch sphere display** — a **Display** button opens a Bloch-sphere view: every qubit's
  final state at once, one chosen qubit's state after each column, a tensor-network diagram
  of the circuit, or a rotatable 3D sphere you orbit by dragging.

## Layouts

| Layout | Platforms | Description |
|---|---|---|
| Regular | macOS, iPad | Three-pane: gate palette, circuit grid, and live results side by side |
| Compact | iPhone | Full-bleed circuit grid with a horizontal gate strip below; results open in a sheet |

## Project structure

```text
SwiftQiskitApp/
├── SwiftQiskitApp/
│   ├── CircuitModel.swift
│   ├── CircuitLayout.swift
│   ├── CircuitWiresView.swift
│   ├── CircuitGridView.swift
│   ├── GateTileView.swift
│   ├── GatePaletteView.swift
│   ├── ParameterPopover.swift
│   ├── ResultsView.swift
│   ├── HistogramView.swift
│   ├── BlochSphereView.swift
│   ├── Bloch3DSphereView.swift
│   ├── BlochDisplayView.swift
│   ├── CircuitBuilderView.swift
│   ├── CompactBuilderView.swift
│   ├── ContentView.swift
│   └── SwiftQiskitAppApp.swift
├── SwiftQiskitAppTests/
│   ├── CircuitBuilderTests.swift
│   ├── CircuitLayoutTests.swift
│   ├── BlochVectorTests.swift
│   └── Bloch3DProjectionTests.swift
├── Docs/
│   ├── Tutorial.md
│   ├── Help.md
│   └── Todo.md
├── README.md
└── CLAUDE.md
```

## Testing

Run via ⌘U or the `RunAllTests` MCP tool under the `SwiftQiskitApp` scheme — 37 tests total,
using the Swift `Testing` framework (not XCTest).

---

## Documentation

- [INTRODUCTION.md](INTRODUCTION.md) — a 27-chapter, book-length introduction to quantum
  computing (plus a Chapter 0 opener) taught through this app and the SwiftQiskit playgrounds,
  chapter by chapter, from qubits and gates through the named algorithms (Deutsch, Grover, the
  QFT, Shor, teleportation, error correction, the CHSH inequality, ...) and on to noise,
  tomography, and VQE.
- [Docs/Introduction](Docs/Introduction) — contains the actual chapters.
- [Docs/Tutorial.md](Docs/Tutorial.md) — how to use the app, step by step.
- [Docs/Help.md](Docs/Help.md) — implementation reference, extension guide, troubleshooting.
- [Docs/Todo.md](Docs/Todo.md) — status and roadmap.
- [Templates/README.md](Templates/README.md) — an Xcode project template for starting a new
  quantum-algorithm demo app, prefilled with a worked example.
- [CLAUDE.md](CLAUDE.md) — guidance for Claude Code working in this repo.

For everything about the simulator itself — the gate set, Dirac notation, tensor products,
and the playground pages that teach quantum computing algorithm by algorithm — see the
[SwiftQiskit](https://github.com/SwiftProjectOrganization/SwiftQiskit) package (a sibling
checkout is convenient for browsing these but not required to build this app):

- [/SwiftQiskit/README.md](https://github.com/SwiftProjectOrganization/SwiftQiskit/README.md)

## Status

v1 scope: no persistence, no undo, no drag-and-drop. See [Docs/Todo.md](Docs/Todo.md) for the
full roadmap.

---

## References

1. [Ali Nasser](https://github.com/a360n/SwiftQiskit) - The parent repository for SwiftQiskit.
2. [Quantum Computing for everyone](https://www.amazon.com/Quantum-Computing-Everyone-Mit-Press/dp/0262539535/ref=sr_1_1?crid=2FZXZMKUHTCMY&dib=eyJ2IjoiMSJ9.P7qqxqmMDjw-ATyR5LpVdh5xPQ4Y0b2Dzmdh3sxSRGv9O0zg3c4tC3cxXmuFSARdd16gdrlAtvEt4sjIXeZS4pYp3-V78bvNcF2QvOz5I8GsSjxKQvXwCqZE3pb_p8kHyldF_pJ2hZW2HNzJmFYV_MWw4BFvDKddzLBrDhMzSWEH8F_MRHIb2nt27dEMEVnUZNOByHEF6ZmBu_-HunbuU8Z7zWhQF2AvZUFBhHNOtHU.JVmku_grNC3YTp28qmqeX5hDii-RdfSijIAJlmX2gGE&dib_tag=se&keywords=chris+bernhardt%2C+quantum+computing+for+everyone&qid=1790170950&sprefix=Chris+Bern%2Caps%2C224&sr=8-1) - Good starting book.
3. [Medium](https://medium.com/@brianenochson/our-quantum-future-part-1-quantum-computing-introduction-f03aa4fc5f7f) - Short introductions, part 1 to 4.
4. [Quantum Mechanics](https://www.amazon.com/Quantum-Mechanics-Theoretical-Leonard-Susskind-ebook/dp/B00FD36G1Q?ref_=ast_author_dp_rw&th=1&psc=1&dib=eyJ2IjoiMSJ9.RkHbIvheK8CPtFzsBgBe7r23a7uhLIlprKHFiYC4BOCvoD6WBdvaQA79CYfZj1_xwUNgGM2xOFd-NGea4XGiB8p7tZll3hdPz1B1IWaIf9jLZuA7h2hoqtpM43Ebaii5rpmm3tHvNMEoAEbVniy-PWV35vm2I2ePmaG4bFhykzpwVySzN3XKJPylPmR4lL1GdKme919H-EXrNmLDhJZ7p8eEeOHQzQIdUK8zwBuPWQY.BXHnclSf8mfD4zk9Rtha8_j22VdyFHEKXfjT5yVZ2Ew&dib_tag=AUTHOR) - Leonard Susskind's lectures at Stanford, many years ago, triggered my interest.
5. [Yao](https://yaoquantum.org) - For me, a Julia supporter, a great next step.
6. [Quantum Computing made simple](https://www.amazon.com/Quantum-Computing-Made-Simple-Plain-English/dp/B0FWYKVRJN) - Another good introductory book.
