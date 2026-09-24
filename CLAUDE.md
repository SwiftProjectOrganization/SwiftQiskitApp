# CLAUDE.md

Guidance for Claude Code when working in this repository.

## Overview

SwiftQiskitApp is a SwiftUI front-end for building and running quantum circuits by tapping
gates onto a grid instead of writing code. All quantum simulation (state vectors, gates,
measurement) lives in the `SwiftQiskit` package; this app contributes only the UI and
a small front-end model that replays placed gates onto a `QuantumCircuit`. This app is the
package's only SwiftUI front-end — the package used to ship a duplicate (`SwiftQiskitGUI`),
which was removed once it had drifted behind this app with no offsetting benefit to
maintaining two copies.

## Relationship to the SwiftQiskit package

This project depends on **`SwiftQiskit` as a remote package**, pinned "Up to Next Minor
Version" from `0.1.0`
(`https://github.com/SwiftProjectOrganization/SwiftQiskit.git`). No sibling checkout is
required to build or run this app — Xcode resolves the dependency from GitHub into its own
cache. The library product and module are both named `SwiftQiskit`:

```swift
import SwiftQiskit
```

A sibling `SwiftQiskit` checkout is still useful for reading the playground pages and
`PlaygroundDocs/*HELP.md` this project's `INTRODUCTION.md` and `Docs/Introduction/` draw from
(see `Docs/Introduction/01-Setup.md`), but it is no longer a build requirement.

**Editing the package in tandem with this app:** package edits don't reach this app until
they're committed, tagged, and pulled in via File > Packages > Update to Latest Package
Versions. For tandem development, drag a local `../SwiftQiskit` checkout into this project's
workspace — a local package overrides a remote dependency of the same name, restoring instant
edits. Remove the override when done.

## Build, Run & Test

Prefer the `xcode-tools` MCP tools: `BuildProject`, `RunProject`, `RunAllTests`.

- One shared scheme: **`SwiftQiskitApp`**. Its test plan includes all tests (unlike the
  package's `SwiftQiskit` scheme, which has an empty test plan) — no scheme-switching needed.
- Eligible run destinations: **My Mac**, iOS devices/simulators.
- Deployment target 27.0 across macOS/iOS; `SWIFT_VERSION = 5.0`.

## Targets

| Target | Product type | Notes |
|---|---|---|
| `SwiftQiskitApp` | Application | `com.robertgoedman.SwiftQiskitApp`; App Sandbox enabled, read-only user-selected file access |
| `SwiftQiskitAppTests` | Unit Test Bundle | Swift `Testing` framework; 22 tests across 4 files |

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
| `BlochVector.swift` | Single-qubit Bloch coordinates from a `StateVector`; `init(_:qubit:)` computes a reduced (partial-trace) vector for one qubit of a multi-qubit state |
| `BlochSphereView.swift` | 2D oblique-projection `Canvas` drawing of one `BlochVector` |
| `Bloch3DSphereView.swift` | Rotatable, perspective-projected 3D `Canvas` drawing of one `BlochVector`; drag to orbit the camera |
| `BlochDisplayView.swift` | Final/Steps/3D segmented view showing a grid, a column-by-column row of `BlochSphereView`s, or an orbitable `Bloch3DSphereView`; opened via the "Display" button |
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
  `buildCircuit(throughColumn:)` replays only a prefix (columns `0...throughColumn`, or none
  for `-1`) — the only way to get intermediate states, since `QuantumCircuit`'s own operation
  list is private and can't be stepped.
- `ResultsView.body` calls `builder.buildCircuit().run()` on **every render** — the state
  vector shown is always fresh, not cached.
- `CircuitLayout` is the single geometry source (`center(column:qubit:)`, `wireY(_:)`,
  `wireXRange(columns:)`, `canvasSize(columns:qubits:)`) shared by `CircuitWiresView` (drawn
  first, behind everything) and `CircuitGridView` (interactive cells on top) — so the two
  layers can't drift apart.
- **"Display" button** (`CircuitBuilderView`/`CompactBuilderView`) opens `BlochDisplayView` in
  a sheet, mirroring how Results is presented. `BlochVector(_ state:, qubit:)` produces a
  reduced Bloch vector by summing over the other qubits' basis configurations (a partial
  trace) — entangled qubits render with `|r| < 1`, a shorter arrow inside the sphere. This is
  vendored from `SwiftQiskit/Playgrounds.playground/Sources/BlochVector.swift` /
  `BlochSphereView.swift` / `Bloch3DView.swift`, which aren't importable (playground `Sources/`
  isn't an SPM target). The 3D mode's camera math lives in `Bloch3DProjection`, a pure struct
  pulled out of `Bloch3DSphereView` so its perspective projection is unit-testable
  (`Bloch3DProjectionTests.swift`) independent of the `Canvas`/`DragGesture` view code.

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
- **Liquid Glass:** favor Liquid Glass materials wherever the UI supports them — e.g.
  `.glassEffect()`/`GlassEffectContainer` on floating or interactive surfaces (gate palette,
  tiles, popovers, toolbars) instead of plain materials or opaque backgrounds. Consult the
  `xcode-integration:swiftui-whats-new-27` skill or `DocumentationSearch` for current API
  names before using them, since Liquid Glass is newer than training data for older models.

## Testing

- `SwiftQiskitAppTests/CircuitBuilderTests.swift` (9 tests) — Bell-state replay via
  `buildCircuit()`, occupied/out-of-range placement rejection, qubit-count clamping and
  gate-dropping on shrink, `updateTheta`, `clear`, `measure(shots:)` populating `lastResult`,
  and a qubit-count shrink discarding a prior measurement.
- `SwiftQiskitAppTests/CircuitLayoutTests.swift` (3 tests) — pure `CircuitLayout` geometry:
  center spacing, `wireY` agreement with `center`, `canvasSize` growth in each dimension.
- `SwiftQiskitAppTests/BlochVectorTests.swift` (7 tests) — single-qubit Bloch coordinates for
  `H`/`X`/`H+S`, the Bell state's maximally-entangled reduced vectors (`|r| == 0` on both
  qubits), reduced-vector isolation between qubits, and `buildCircuit(throughColumn:)` prefix
  replay.
- `SwiftQiskitAppTests/Bloch3DProjectionTests.swift` (3 tests) — pure `Bloch3DProjection`
  geometry: pole projection direction, near- vs far-hemisphere perspective scale, the
  silhouette-scale formula.
- Swift **`Testing`** framework (`import Testing`, `@Test`, `#expect`), not XCTest.
- Run via `RunAllTests` or ⌘U under the `SwiftQiskitApp` scheme — all 22 tests are in its
  test plan (no scheme-switching gotcha, unlike the package).

## Writing style

The user prefers a sober writing style — plain, measured prose, no hype, no exclamation marks,
no sales-pitch framing. Applies to prose written for this project: `INTRODUCTION.md` chapters,
`Docs/`, `README.md`, commit messages, and PR descriptions.

## Documentation index

- `README.md` — project overview, getting started, features.
- `INTRODUCTION.md` — a 26-chapter introduction to quantum computing (plus a Chapter 0 opener)
  built on this app and the SwiftQiskit playgrounds; each chapter lives in `Docs/Introduction/`.
  Working on a chapter starts by reading `Docs/Introduction/AUTHORING.md` (template, style rules,
  verification workflow) before touching the chapter file itself.
- `Docs/Tutorial.md` — how to use the app (build/measure a Bell state, GHZ state, etc.).
- `Docs/Help.md` — implementation reference, extension guide, troubleshooting.
- `Docs/Todo.md` — status and roadmap.
- `Docs/SwiftQiskit as an external SPM.md` — record of replacing the local `../SwiftQiskit` path
  dependency with a version-tagged remote one (executed), so this app and `SwiftQiskitWalkDemo`
  can be open in Xcode at the same time; also documents the `SwiftQiskitCore` → `SwiftQiskit`
  rename and the removal of the package's duplicate `SwiftQiskitGUI` target, both done as part
  of the same change.
- `Templates/README.md` — an Xcode project template ("Quantum Algorithm App") with a worked
  quantum-walk example for starting a new algorithm-demo app (the `SwiftQiskit` package
  dependency itself is a manual post-generation step, per that template's own README.md);
  see `Docs/TemplatesPlan.md` for the design.
- `../SwiftQiskit/CLAUDE.md`, `../SwiftQiskit/README.md` — the simulator itself: gate tables,
  Dirac notation, playground pages. Consult these for anything about *what the gates compute*
  rather than *how the app is built*.
