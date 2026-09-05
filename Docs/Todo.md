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
- 10 unit tests (`CircuitBuilderTests`, `CircuitLayoutTests`) covering the model and geometry.

## Roadmap

- [ ] Persistence — save/load a built circuit between launches.
- [ ] Export — as Swift source (`circuit.h(0); circuit.cx(0,1)`, etc.), JSON, or an image of
      the diagram.
- [ ] Undo/redo for gate placement, deletion, and qubit-count changes.
- [ ] Drag-and-drop gate placement as an alternative to tap-to-arm-then-tap-cell.
- [ ] More gates once `SwiftQiskitCore` supports them (CZ, SWAP, Toffoli) — see the package's
      own `STATUSandTODO.md` for its roadmap.
- [ ] Gate-count / circuit-depth readout alongside the state vector.
- [ ] A Bloch-sphere view for single-qubit circuits, reusing the package playground's
      `BlochSphereView` (would need to either depend on the playground's `Sources/` module or
      port the relevant type).
- [ ] iPad-specific layout polish (currently shares the macOS 3-pane layout as-is).
- [ ] Verify visionOS support — currently builds (`xros`/`xrsimulator` are in
      `SUPPORTED_PLATFORMS`) but has never been run or tested on that platform.
- [ ] UI tests via XCUIAutomation (current tests only cover the model/geometry, not views).
- [ ] VoiceOver and Dynamic Type accessibility audit.
- [ ] Performance check at high qubit counts (8 qubits → 256×256 matrices per gate; the
      package's Core is not performance-optimized — see its own roadmap).
- [ ] De-duplicate against `SwiftQiskitGUI` in the `SwiftQiskit` package, whose UI this app's
      source closely mirrors — consider extracting a shared module if the drift becomes a
      maintenance problem.

## Known limitations

- No undo on `Clear` or on a qubit-count shrink that drops gates.
- The state vector is recomputed on every render rather than cached/invalidated — fine at
  current scale, worth revisiting if it becomes a performance issue at high qubit counts.
- `measure(shots:)` replays the full circuit per shot in the package's simulator; very high
  shot counts at high qubit counts may be slow (see the package's own notes on this in
  `PlaygroundDocs/12SHORHELP.md`).
