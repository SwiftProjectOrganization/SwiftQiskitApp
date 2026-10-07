# Status and TODO

Project status and roadmap for SwiftQiskitApp.

## Project Status

**SwiftQiskitApp is v1: a working circuit builder, front-end only.**

- All quantum simulation is delegated to the `SwiftQiskit` package (currently v0.2,
  experimental — its API may change under this app).
- The UI supports placing/removing gates, live state-vector display, and shot-based
  measurement with a histogram.
- No persistence, undo, or drag-and-drop yet.

## What Works (v1)

- Gate palette: `H X Y Z` (Pauli/Hadamard), `S S† T T†` (phase), `P RX RY RZ` (rotations,
  each with a θ parameter), `CX`/`CZ`/`SWAP` (two-qubit), `RZZ RXX RYY` (two-qubit rotations, each
  with a θ parameter).
- Tap-to-arm-then-tap-cell placement; CX's two-tap control→target flow, RZZ/RXX/RYY's
  two-tap flow on an unordered qubit pair.
- Multi-controlled CX and CZ: tapping a placed CX or CZ opens a "Controls: n" stepper popover; **+** adds
  a control on any free qubit in the column, **−** removes the newest. Two controls is the
  Toffoli (CCX), more replay through the package's `mcx`. Delete is in the context menu.
- θ editor popover for parameterized gates (0–2π slider).
- Qubit count 1–8, adjustable via stepper; shrinking drops out-of-range gates.
- Live state vector (amplitudes + probabilities), recomputed on every change.
- Shot-based `measure(shots:)` with a bar-chart histogram.
- Two layouts: 3-pane regular (macOS/iPad) and compact full-bleed (iPhone).
- Bloch-sphere display (`BlochDisplayView`, opened via a **Display** button): a 2D grid of
  every qubit's final-state sphere, a column-by-column row for one chosen qubit, or a rotatable
  3D view (`Bloch3DSphereView`, orbited by dragging).
- 37 unit tests (`CircuitBuilderTests`, `CircuitLayoutTests`, `BlochVectorTests`,
  `Bloch3DProjectionTests`) covering the model, geometry, and Bloch-vector math.

## Roadmap

- [ ] `INTRODUCTION.md` — 27-chapter introduction to quantum computing; chapters are scaffolded
      as stubs in `Docs/Introduction/`, with progress tracked in the Status column of
      `INTRODUCTION.md`'s chapter table, not duplicated here.
- [ ] Persistence — save/load a built circuit between launches.
- [ ] Export — as Swift source (`circuit.h(0); circuit.cx(0,1)`, etc.), JSON, or an image of
      the diagram.
- [ ] Undo/redo for gate placement, deletion, and qubit-count changes.
- [ ] Drag-and-drop gate placement as an alternative to tap-to-arm-then-tap-cell.
- [x] Toffoli and other multi-controlled X gates — done by adding controls to a placed CX,
      using the package's `ccx`/`mcx`.
- [x] CZ and SWAP — package `0.4.0` added `cz`/`mcz`/`swap`; CZ takes extra controls through
      the same popover as CX (CCZ and beyond replay through `mcz`).
- [ ] Multi-controlled versions of other gates (controlled rotations), and mixed
      open/closed controls (a control that fires on `0`).
- [ ] Gate-count / circuit-depth readout alongside the state vector.
- [x] A Bloch-sphere view, covering multi-qubit circuits — `BlochSphereView`
      was ported from the package playground's `Sources/` folder (not importable as-is) into
      the app; `BlochVector` (with the reduced, partial-trace init for qubits beyond the
      first) originally was too, but has since moved to the package's own shared
      `SwiftQiskitViews` product (`0.2.0`) — this app now imports it from there instead of
      vendoring a copy.
- [x] 3D Bloch sphere / rotatable view — `Bloch3DSphereView`, ported from the package
      playground's `Bloch3DView` the same way the 2D view was, added as a third Display mode
      ("3D") alongside Final/Steps.
- [x] Adopt the shared `SwiftQiskitViews` package product for `BlochVector`/`CHSHChartView`,
      replacing this app's own vendored `BlochVector.swift` — done as part of `SwiftQiskit`
      `0.2.0`; the package dependency requirement now starts at `0.2.0`.
- [ ] iPad-specific layout polish (currently shares the macOS 3-pane layout as-is).
- [ ] UI tests via XCUIAutomation (current tests only cover the model/geometry, not views).
- [ ] VoiceOver and Dynamic Type accessibility audit.
- [ ] Performance check at high qubit counts (8 qubits → 256×256 matrices per gate; the
      package's Core is not performance-optimized — see its own roadmap).
- [x] De-duplicate against `SwiftQiskitGUI` — resolved by removing that target from the
      `SwiftQiskit` package rather than extracting a shared module: it had drifted behind this
      app (no Bloch-sphere Display button, an older `CircuitModel`, no measurement-model
      refactor) with no offsetting benefit to keeping two copies in sync. This app is now the
      only SwiftUI front-end for the package.

## Known limitations

- No undo on `Clear` or on a qubit-count shrink that drops gates.
- The state vector is recomputed on every render rather than cached/invalidated — fine at
  current scale, worth revisiting if it becomes a performance issue at high qubit counts.
- `measure(shots:)` replays the full circuit per shot in the package's simulator; very high
  shot counts at high qubit counts may be slow (see the package's own notes on this in
  `PlaygroundDocs/12SHORHELP.md`).
- Name and persistently store circuits.
- 
