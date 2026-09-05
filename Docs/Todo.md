# Status and TODO

Project status and roadmap for SwiftQiskitApp.

## Project Status

**SwiftQiskitApp is v1: a working circuit builder, front-end only.**

- All quantum simulation is delegated to the `SwiftQiskit` package (currently v0.1,
  experimental — its API may change under this app).
- The UI supports placing/removing gates, live state-vector display, and shot-based
  measurement with a histogram.
- No persistence, undo, or drag-and-drop yet.

## What Works (v1)

- Gate palette: `H X Y Z` (Pauli/Hadamard), `S S† T T†` (phase), `P RX RY RZ` (rotations,
  each with a θ parameter), `CX` (two-qubit CNOT).
- Tap-to-arm-then-tap-cell placement; CX's two-tap control→target flow.
- θ editor popover for parameterized gates (0–2π slider).
- Qubit count 1–8, adjustable via stepper; shrinking drops out-of-range gates.
- Live state vector (amplitudes + probabilities), recomputed on every change.
- Shot-based `measure(shots:)` with a bar-chart histogram.
- Two layouts: 3-pane regular (macOS/iPad) and compact full-bleed (iPhone).
- 2D Bloch-sphere display (`BlochDisplayView`, opened via a **Display** button): a grid of
  every qubit's final-state sphere, or a column-by-column row for one chosen qubit.
- 17 unit tests (`CircuitBuilderTests`, `CircuitLayoutTests`, `BlochVectorTests`) covering the
  model, geometry, and Bloch-vector math.

## Roadmap

- [ ] Persistence — save/load a built circuit between launches.
- [ ] Export — as Swift source (`circuit.h(0); circuit.cx(0,1)`, etc.), JSON, or an image of
      the diagram.
- [ ] Undo/redo for gate placement, deletion, and qubit-count changes.
- [ ] Drag-and-drop gate placement as an alternative to tap-to-arm-then-tap-cell.
- [ ] More gates once `SwiftQiskitCore` supports them (CZ, SWAP, Toffoli) — see the package's
      own `STATUSandTODO.md` for its roadmap.
- [ ] Gate-count / circuit-depth readout alongside the state vector.
- [x] A Bloch-sphere view, covering multi-qubit circuits — `BlochVector`/`BlochSphereView`
      were ported from the package playground's `Sources/` folder (not importable as-is) into
      the app, plus a new reduced (partial-trace) `BlochVector` init for qubits beyond the
      first. Promoting these into a shared `SwiftQiskitViews` package target instead of
      vendoring them remains open — see "De-duplicate" below.
- [ ] 3D Bloch sphere / rotatable view, following the package playground's `Bloch3DView`.
- [ ] iPad-specific layout polish (currently shares the macOS 3-pane layout as-is).
- [ ] Verify visionOS support — currently builds (`xros`/`xrsimulator` are in
      `SUPPORTED_PLATFORMS`) but has never been run or tested on that platform.
- [ ] UI tests via XCUIAutomation (current tests only cover the model/geometry, not views).
- [ ] VoiceOver and Dynamic Type accessibility audit.
- [ ] Performance check at high qubit counts (8 qubits → 256×256 matrices per gate; the
      package's Core is not performance-optimized — see its own roadmap).
- [ ] De-duplicate against `SwiftQiskitGUI` in the `SwiftQiskit` package, whose UI this app's
      source closely mirrors — consider extracting a shared module if the drift becomes a
      maintenance problem. `SwiftQiskitGUI` does not yet have the Bloch-sphere Display button
      that this app has, a deliberate divergence so far.

## Known limitations

- No undo on `Clear` or on a qubit-count shrink that drops gates.
- The state vector is recomputed on every render rather than cached/invalidated — fine at
  current scale, worth revisiting if it becomes a performance issue at high qubit counts.
- `measure(shots:)` replays the full circuit per shot in the package's simulator; very high
  shot counts at high qubit counts may be slow (see the package's own notes on this in
  `PlaygroundDocs/12SHORHELP.md`).
