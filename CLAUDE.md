# CLAUDE.md

Guidance for Claude Code when working in this repository.

## Overview

SwiftQiskitApp is a SwiftUI front-end for building and running quantum circuits by tapping
gates onto a grid instead of writing code. All quantum simulation (state vectors, gates,
measurement) lives in the sibling `SwiftQiskit` package; this app contributes only the UI and
a small front-end model that replays placed gates onto a `QuantumCircuit`.

## Relationship to the SwiftQiskit package

This project depends on a **local Swift package at `../SwiftQiskit`** (a relative-path SPM
dependency — the checkout must sit next to this folder or package resolution fails). The
library *product* is named `SwiftQiskit` but the *module* is `SwiftQiskitCore`:

```swift
import SwiftQiskitCore
```

**Duplication gotcha:** this app's 13 source files are a near-identical copy of
`SwiftQiskit/Sources/SwiftQiskitGUI/` (the package's own SwiftPM-executable version of the
same UI, documented in `SwiftQiskit/SwiftQiskitDocs/GUIHELP.md`). The two copies can drift.
When fixing a bug or adding a feature here, consider whether the same change applies to
`SwiftQiskitGUI` and note in your summary if you only fixed one side.

## Build, Run & Test

Prefer the `xcode-tools` MCP tools: `BuildProject`, `RunProject`, `RunAllTests`.

- One shared scheme: **`SwiftQiskitApp`**. Its test plan includes all tests (unlike the
  package's `SwiftQiskit` scheme, which has an empty test plan) — no scheme-switching needed.
- Eligible run destinations: **My Mac**, iOS devices/simulators. visionOS is a supported
  build platform (`SUPPORTED_PLATFORMS` includes `xros`/`xrsimulator`) but is **untested** —
  treat it as build-only until someone verifies it on-device.
- Deployment target 27.0 across macOS/iOS/visionOS; `SWIFT_VERSION = 5.0`.

## Targets

| Target | Product type | Notes |
|---|---|---|
| `SwiftQiskitApp` | Application | `com.robertgoedman.SwiftQiskitApp`; App Sandbox enabled, read-only user-selected file access |
| `SwiftQiskitAppTests` | Unit Test Bundle | Swift `Testing` framework; 10 tests across 2 files |

## File map (`SwiftQiskitApp/`)

| File | Contents |
|---|---|
| `CircuitModel.swift` | `GateKind`, `PlacedGate`, `CircuitBuilder` — the model, no SwiftUI import |
| `CircuitLayout.swift` | Pure geometry — turns `(column, qubit)` into points shared by the wire layer and the interactive gate layer |
| `CircuitWiresView.swift` | Background `Canvas` layer: one horizontal wire per qubit, plus a vertical connector for CX gates |
| `CircuitBuilderView.swift` | Regular-width (macOS/iPad) 3-pane layout: palette, grid, results |
| `CompactBuilderView.swift` | iPhone-compact layout (`#if os(iOS)`): full-bleed grid + horizontal gate strip, results in a sheet |
| `GatePaletteView.swift` | Gate buttons, grouped by category; arms a `GateKind`; `.sidebar` or `.strip` layout |
| `CircuitGridView.swift` | The qubit-wire grid; tap-to-place and the CX two-tap state machine |
| `GateTileView.swift` | `GateTileView` (a placed single-qubit or CX-control tile), `CXTargetView`, `EmptyCellView` |
| `ParameterPopover.swift` | θ slider for `.p/.rx/.ry/.rz` tiles |
| `ResultsView.swift` | Live state vector + shots/Measure/histogram |
| `HistogramView.swift` | Bar chart of `SimulationResult` counts |
| `ContentView.swift` | Owns the `CircuitBuilder` and `armedGate` state; picks `CircuitBuilderView` vs. `CompactBuilderView` by size class on iOS |
| `SwiftQiskitAppApp.swift` | `@main App`; sets a minimum/default window size on macOS |

## Architecture & data flow

- `ContentView` owns the single source of truth: `@State private var builder = CircuitBuilder(...)`
  and `@State private var armedGate: GateKind?`. Both child layouts share this state so
  switching between regular/compact layouts (e.g. rotating an iPad) doesn't lose the circuit.
- `CircuitBuilder` (`@MainActor @Observable`) keeps its own `[PlacedGate]` record — the
  package's `QuantumCircuit` only stores the resulting full-dimension matrices, with no gate
  identity or column metadata, so there's nothing to inspect or redraw from it directly.
  `buildCircuit()` sorts placed gates by column and replays them onto a fresh `QuantumCircuit`.
- `ResultsView.body` calls `builder.buildCircuit().run()` on **every render** — the state
  vector shown is always fresh, not cached.
- `CircuitLayout` is the single geometry source (`center(column:qubit:)`, `wireY(_:)`,
  `wireXRange(columns:)`, `canvasSize(columns:qubits:)`) shared by `CircuitWiresView` (drawn
  first, behind everything) and `CircuitGridView` (interactive cells on top) — so the two
  layers can't drift apart.

## Conventions & gotchas

- **Qubit indexing:** qubit 0 is the most-significant (leftmost) bit — same convention as the
  package.
- **No Combine:** `CircuitBuilder` is `@Observable`, not `ObservableObject`/`@Published`, per
  this project's style rules (avoid Combine; prefer modern Swift concurrency/observation).
  The project sets `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`, so `CircuitBuilder` and its
  test suite (`CircuitBuilderTests`) are both `@MainActor`-isolated.
- **`qubitCount` clamp-and-filter** lives in its own `didSet` on `CircuitBuilder`, written to
  avoid infinite recursion: it only re-assigns `qubitCount` (which would re-trigger `didSet`)
  when the clamped value differs from the current one, and returns immediately after so the
  gate-filtering line runs once, against the already-clamped value. Range is 1...8
  (`CircuitBuilder.minQubits`/`.maxQubits`); shrinking silently drops gates that no longer fit.
- **`measure(shots:)` is probabilistic** — expect the histogram split to jitter between runs,
  not land on an exact ratio.
- **No persistence, no undo, no drag-and-drop** — see `Docs/Todo.md` for the roadmap.
- Style: 4-space indent, PascalCase types, camelCase members, no force unwrapping.

## Testing

- `SwiftQiskitAppTests/CircuitBuilderTests.swift` (7 tests) — Bell-state replay via
  `buildCircuit()`, occupied/out-of-range placement rejection, qubit-count clamping and
  gate-dropping on shrink, `updateTheta`, `clear`.
- `SwiftQiskitAppTests/CircuitLayoutTests.swift` (3 tests) — pure `CircuitLayout` geometry:
  center spacing, `wireY` agreement with `center`, `canvasSize` growth in each dimension.
- Swift **`Testing`** framework (`import Testing`, `@Test`, `#expect`), not XCTest.
- Run via `RunAllTests` or ⌘U under the `SwiftQiskitApp` scheme — all 10 tests are in its
  test plan (no scheme-switching gotcha, unlike the package).

## Documentation index

- `README.md` — project overview, getting started, features.
- `Docs/Tutorial.md` — how to use the app (build/measure a Bell state, GHZ state, etc.).
- `Docs/Help.md` — implementation reference, extension guide, troubleshooting.
- `Docs/Todo.md` — status and roadmap.
- `../SwiftQiskit/CLAUDE.md`, `../SwiftQiskit/README.md` — the simulator itself: gate tables,
  Dirac notation, playground pages. Consult these for anything about *what the gates compute*
  rather than *how the app is built*.
