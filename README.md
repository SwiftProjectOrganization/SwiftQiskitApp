# SwiftQiskitApp

**SwiftQiskitApp** is a SwiftUI app for building quantum circuits by tapping gates onto a
grid instead of writing code. Place gates, watch the state vector update live, then measure
with as many shots as you like and see a histogram of the outcomes.

> This app is a thin front end. All quantum simulation — state vectors, gates, measurement —
> is implemented by the [SwiftQiskit](../SwiftQiskit) package; this repo contributes only the
> UI and a small model that replays placed gates onto a `QuantumCircuit`.

---

## Requirements

- Xcode 27, macOS 27 / iOS 27.
- A checkout of **[SwiftQiskit](../SwiftQiskit)** as a sibling folder — the app depends on it
  as a local package at the relative path `../SwiftQiskit`. If package resolution fails,
  check that the two folders sit next to each other.

## Getting started

1. Open `SwiftQiskitApp.xcodeproj` in Xcode.
2. Pick a run destination — **My Mac**, or an iOS device/simulator.
3. Run (⌘R). The app opens on an empty 2-qubit circuit.

See [Docs/Tutorial.md](Docs/Tutorial.md) for a full walkthrough that builds and measures a
Bell state.

---

## Features

- **Gate palette** — Hadamard/Pauli (`H X Y Z`), phase (`S S† T T†`), rotations
  (`P RX RY RZ`, each with a θ parameter), and the two-qubit `CX` (CNOT).
- **Tap-to-place** — arm a gate in the palette, then tap a wire to place it. `CX` needs two
  taps: control, then target, in the same column.
- **Live state vector** — recomputed on every change, no explicit "run" step.
- **Measure** — choose a shot count (1–10,000) and see a bar-chart histogram of the results.
- **1–8 qubits**, adjustable with a stepper; shrinking the count drops gates that no longer fit.
- **θ editor** — tap a placed parameterized gate to open a popover with a 0–2π slider.

## Layouts

| Layout | Platforms | Description |
|---|---|---|
| Regular | macOS, iPad | Three-pane: gate palette, circuit grid, and live results side by side |
| Compact | iPhone | Full-bleed circuit grid with a horizontal gate strip below; results open in a sheet |

visionOS is a supported build platform but is currently **untested** — treat it as build-only
until verified on-device.

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
│   ├── CircuitBuilderView.swift
│   ├── CompactBuilderView.swift
│   ├── ContentView.swift
│   └── SwiftQiskitAppApp.swift
├── SwiftQiskitAppTests/
│   ├── CircuitBuilderTests.swift
│   └── CircuitLayoutTests.swift
├── Docs/
│   ├── Tutorial.md
│   ├── Help.md
│   └── Todo.md
├── README.md
└── CLAUDE.md
```

## Testing

Run via ⌘U or the `RunAllTests` MCP tool under the `SwiftQiskitApp` scheme — 10 tests total,
using the Swift `Testing` framework (not XCTest).

---

## Documentation

- [Docs/Tutorial.md](Docs/Tutorial.md) — how to use the app, step by step.
- [Docs/Help.md](Docs/Help.md) — implementation reference, extension guide, troubleshooting.
- [Docs/Todo.md](Docs/Todo.md) — status and roadmap.
- [CLAUDE.md](CLAUDE.md) — guidance for Claude Code working in this repo.

For everything about the simulator itself — the gate set, Dirac notation, tensor products,
and the playground pages that teach quantum computing algorithm by algorithm — see the
sibling package:

- [../SwiftQiskit/README.md](../SwiftQiskit/README.md)
- [../SwiftQiskit/SwiftQiskitDocs/GUITUTORIAL.md](../SwiftQiskit/SwiftQiskitDocs/GUITUTORIAL.md) /
  [GUIHELP.md](../SwiftQiskit/SwiftQiskitDocs/GUIHELP.md) — the package's own `SwiftQiskitGUI`
  executable, whose UI this app closely mirrors.

## Status

v1 scope: no persistence, no undo, no drag-and-drop. See [Docs/Todo.md](Docs/Todo.md) for the
full roadmap.
