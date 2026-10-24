# SwiftQiskitApp — help & reference

Implementation reference, extension guide, and troubleshooting for SwiftQiskitApp. The
user-facing walkthrough (how to actually use the app) is [Tutorial.md](Tutorial.md); this
document is its companion — how it's built, not how to drive it.

## Why a separate front-end model exists

`QuantumCircuit` (in the `SwiftQiskit` package) keeps its operation list private/internal and has no notion of columns. That's enough to
`run()`/`measure(shots:)`, but not enough to draw or edit a circuit diagram after the fact:
there's nothing public to inspect. So the app keeps its own record of *placed* gates
(`CircuitModel.swift`) and replays them onto a fresh `QuantumCircuit` whenever it needs to
run. No `SwiftQiskit` changes were needed for this feature.

## File map (`SwiftQiskitApp/`)

| File | Contents |
|---|---|
| `CircuitModel.swift` | `GateKind`, `PlacedGate`, `CircuitBuilder` — the model, no SwiftUI import |
| `CircuitLayout.swift` | Pure geometry — turns `(column, qubit)` into points shared by the wire layer and the interactive gate layer so they can't drift apart |
| `CircuitWiresView.swift` | Background `Canvas` layer: one horizontal wire per qubit, plus a vertical connector between any two-qubit gate's two qubits |
| `CircuitBuilderView.swift` | Regular-width (macOS/iPad) layout: palette, grid, and a results/measurement pane that hides below `widePaneThreshold` (672 pt); a floating Liquid Glass bottom bar holds the Qubits stepper and Clear/Results/Measure/Display; takes `builder`/`armedGate` from `ContentView` |
| `CompactBuilderView.swift` | iPhone-compact layout (`#if os(iOS)`): full-bleed grid + horizontal gate strip; Qubits stepper top-left, Clear/Results/Measure/Display grouped top-right, each panel in a sheet |
| `GatePaletteView.swift` | Gate buttons, grouped by category; arms a `GateKind`; `.sidebar` (macOS/iPad) or `.strip` (iPhone) layout |
| `CircuitGridView.swift` | The qubit-wire grid; tap-to-place and the CX two-tap state machine |
| `GateTileView.swift` | `GateTileView` (a placed single-qubit tile, either qubit of a symmetric two-qubit rotation, a CX or CY control, CY's target as a boxed Y, or any qubit of a CZ), `CXTargetView` (the ⊕ half of a CX only), `SwapMarkView` (SWAP's ×), `EmptyCellView` |
| `ParameterPopover.swift` | θ slider for `.p/.rx/.ry/.rz/.rzz/.rxx/.ryy` tiles; `ControlsPopover`, the stepper that adds or removes a CX/CY/CZ's controls |
| `ResultsView.swift` | Live state vector only |
| `MeasurementView.swift` | Shots stepper, Measure button and histogram; reads `builder.shots`/`lastResult` |
| `HistogramView.swift` | Bar chart of `SimulationResult` counts |
| `BlochSphereView.swift` | 2D oblique-projection `Canvas` drawing of one `BlochVector` (from the package's `SwiftQiskitViews`) |
| `Bloch3DSphereView.swift` | Rotatable, perspective-projected 3D `Canvas` drawing of one `BlochVector`; drag to orbit |
| `BlochDisplayView.swift` | Final/Steps/Tensor/3D segmented view: a grid of every qubit's sphere, a column-by-column row for one chosen qubit, a `TensorNetworkView` diagram, or an orbitable 3D sphere |
| `ContentView.swift` | Owns the `CircuitBuilder` and `armedGate` state; picks `CircuitBuilderView` vs. `CompactBuilderView` by size class on iOS |
| `SwiftQiskitAppApp.swift` | `@main App`; sets a minimum/default window size on macOS |

## The model (`CircuitModel.swift`)

```swift
public enum GateKind: Equatable, Hashable {
    case h, x, y, z, s, sdg, t, tdg
    case p(Double), rx(Double), ry(Double), rz(Double)
    case cx, cy, cz, swap
    case rzz(Double), rxx(Double), ryy(Double)
    // .symbol, .qubitSpan (1, or 2 for .cx/.cy/.cz/.swap/.rzz/.rxx/.ryy), .isControlled (true only
    // for .cx/.cy/.cz), .isParameterized, .theta, .withTheta(_:)
}

public struct PlacedGate: Identifiable, Equatable {
    public let id: UUID
    public var kind: GateKind
    public var qubits: [Int]   // 1 entry, or 2 or more: controls + [target] for .cx/.cy/.cz (target
                                // last), an unordered pair for .swap/.rzz/.rxx/.ryy
    public var column: Int
    // controls (qubits.dropLast()), target (qubits.last)
}

@MainActor
@Observable public final class CircuitBuilder {
    public static let minQubits = 1, maxQubits = 8
    public var qubitCount: Int   // clamped 1...8; shrinking drops now-out-of-range gates
    public var gates: [PlacedGate]
    public var shots: Int        // default 1000
    public var lastResult: SimulationResult?   // cleared by clear() and by a qubitCount change

    public func place(_ kind: GateKind, qubits: [Int], column: Int) -> Bool  // false if out of range or occupied
    public func remove(id: UUID)
    public func canAddControl(id: UUID) -> Bool
    public func addControl(id: UUID, qubit: Int) -> Bool   // inserts before the target
    public func removeLastControl(id: UUID)                // no-op at one control
    public func updateTheta(id: UUID, theta: Double)
    public func clear()
    public func measure()   // runs `shots` measurements and stores lastResult
    public func buildCircuit() -> QuantumCircuit   // sorts by column, replays onto a fresh circuit
    public func buildCircuit(throughColumn: Int) -> QuantumCircuit   // prefix replay; -1 = empty circuit
}
```

`CircuitBuilder` is `@Observable` (not `ObservableObject`/`@Published`) — this project avoids
the Combine framework, and `@Observable` is the modern replacement. It's also `@MainActor`,
matching the project's `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` build setting; it's only
ever touched from view code (or from `@MainActor`-annotated tests).

`qubitCount`'s clamp-and-filter lives in its own `didSet`, written carefully to avoid infinite
recursion: it only re-assigns `qubitCount` (which would re-trigger `didSet`) when the clamped
value actually differs from the current one, and returns immediately after so the
gate-filtering line only runs once, against the already-clamped value.

## Interaction model (`CircuitGridView.swift`)

Placement is tap-to-arm-then-tap-cell, not drag-and-drop (v1 scope — see "Not implemented"
below):

- Single-qubit gate armed → tapping any empty cell calls
  `builder.place(kind, qubits: [qubit], column: column)` immediately.
- Any span-2 gate (`.cx`, `.cy`, `.cz`, `.swap`, `.rzz`, `.rxx`, `.ryy`) armed → the **first** tap on an empty cell
  sets `pendingControl = (column, qubit)` (view-local `@State`, not part of `CircuitBuilder`
  — it's ephemeral UI state, not circuit data). The **second** tap must be in the *same
  column*, a *different* qubit row; it commits `builder.place(armed, qubits: [first, second],
  column:)`. A tap that breaks either rule resets `pendingControl` to the new cell rather than
  erroring. For `.cx`/`.cy`/`.cz` the two taps are control-then-target; for
  `.swap`/`.rzz`/`.rxx`/`.ryy` the two qubits play the same role, so which one is tapped first
  doesn't matter.
- **Adding controls.** Tapping a placed CX/CY/CZ opens `ControlsPopover`. **+** closes it and sets
  `addingControlTo` (view-local `@State`) to that gate's id; free cells in the gate's column then
  show a dashed ring. The next tap calls `builder.addControl(id:qubit:)` on that cell, or simply
  cancels the mode if the cell is not free. **−** calls `removeLastControl(id:)`.
  `CircuitBuilder.apply(_:to:)` replays one control as `cx`/`cy`/`cz` and more as
  `mcx`/`mcy`/`mcz`.
- Every qubit a `PlacedGate` touches gets its own `GateTileView` (`CircuitGridView` builds one per
  cell). `GateTileView` picks the glyph: a dot for a control, `CXTargetView` (the ⊕ glyph) for a
  `.cx` target, a boxed `Y` for a `.cy` target, a dot for either qubit of a `.cz`, `SwapMarkView`
  for `.swap`, and the same symbol and θ popover on both qubits of a symmetric rotation
  (`.rzz`/`.rxx`/`.ryy`). Deleting works from any of them.
- The grid sits on two layers sharing one `CircuitLayout`: `CircuitWiresView` (a `Canvas`)
  draws the horizontal qubit wires and the vertical connector between any two-qubit gate's two
  qubits *behind* everything, and `CircuitGridView` `.position()`s labels/cells on top from the
  same `center(column:qubit:)` geometry, so the two layers can't drift apart. Boxed tiles
  (every single-qubit gate, both qubits of `.rzz`/`.rxx`/`.ryy`, and `.cy`'s target) paint an opaque backing
  (`GateTileView.boxedBackground`) so they read clearly over the wire; CX's ⊕ and
  `EmptyCellView`'s pending-control marker are transparent rings instead (control dots are filled circles), so the wire shows
  through.

## Geometry (`CircuitLayout.swift`)

| Property | Default | Purpose |
|---|---|---|
| `cellSize` | 44 | Width/height of each grid cell |
| `columnSpacing` | 8 | Horizontal gap between columns |
| `rowSpacing` | 16 | Vertical gap between qubit rows |
| `labelWidth` | 32 | Space reserved for the `q0`/`q1`/... labels |
| `labelGap` | 8 | Gap between labels and the first column |
| `padding` | 16 | Outer margin on all sides |

API: `center(column:qubit:) -> CGPoint`, `wireY(_:) -> CGFloat`,
`wireXRange(columns:) -> ClosedRange<CGFloat>`, `canvasSize(columns:qubits:) -> CGSize`.

## Results pipeline (`ResultsView.swift`)

- `ResultsView.body` calls `builder.buildCircuit().run()` fresh on **every render** — there is
  no caching, so the state vector shown is always current.
- Amplitudes with probability ≤ 1e-9 are filtered out of the displayed list (floating-point
  noise from gate composition, not genuinely occupied states).
- Binary state labels come from `String.leftPadding` (in the package's
  `Utils/String+Padding.swift`), zero-padded to `builder.qubitCount` digits.
- `HistogramView` scales each bar to `maxBarHeight` proportional to the largest count in the
  `SimulationResult`.
- Shots and the histogram live in `MeasurementView`, which reads `builder.shots` and
  `builder.lastResult`. On wide windows it is stacked under `ResultsView` in the right-hand
  pane; below `widePaneThreshold` the pane is hidden and both open as sheets from the bottom bar
  (or the top-right toolbar group on iPhone). The **Measure** button calls `builder.measure()` and
  then presents the Measurement sheet.

## Bloch sphere display (`BlochVector`, `BlochSphereView.swift`, `Bloch3DSphereView.swift`, `BlochDisplayView.swift`, `TensorNetworkView`)

Opened via the **Display** button (in the bottom bar on macOS/iPad, in the top-right toolbar
group on iPhone), mirroring how `ResultsView` is presented as a sheet.

- `BlochVector` maps a single-qubit state to Bloch coordinates: `x = 2·Re(ᾱβ)`,
  `y = 2·Im(ᾱβ)`, `z = |α|² − |β|²`, with `theta = acos(z)`, `phi = atan2(y, x)`.
- `init(_ state:, qubit:)` handles the multi-qubit case: since `BlochVector(_ state:)` alone
  `precondition`s `state.dimension == 2` (and would crash otherwise), this overload sums over
  every basis configuration of the *other* qubits — a partial trace — to get qubit `k`'s
  reduced vector. Entangled qubits have `|r| < 1` (a shorter arrow, drawn inside the sphere,
  not on its surface); both `BlochSphereView` and `Bloch3DSphereView`'s readouts append `|r|`
  whenever it's not ≈1 so a short arrow reads as entanglement, not a bug.
- `BlochSphereView` is a pure `Canvas`/`Path` drawing (no data access) — an oblique orthographic
  projection with `x` foreshortened toward the viewer, `y` right, `z` up.
- `Bloch3DSphereView` orbits a genuine perspective camera around a fixed sphere instead: drag
  the canvas to change the camera's azimuth/elevation (nothing about the state moves). Its
  projection math is a separate pure struct, `Bloch3DProjection`
  (`azimuth`/`elevation`/`cameraDistance` in, a projected `CGPoint` + depth out), so the camera
  geometry is unit-testable without a live `Canvas`.
- `BlochDisplayView` has four modes: **Final** shows a `LazyVGrid` of every qubit's sphere from
  `builder.buildCircuit().run()`; **Steps** shows one chosen qubit across every column, via
  `builder.buildCircuit(throughColumn:)` for each prefix (index `-1` is "Start", the initial
  `|0…0⟩` state); **Tensor** shows `TensorNetworkView(TensorNetwork(builder.buildCircuit()))`,
  a circuit-aligned diagram with one node per input/gate/output and one edge per wire segment;
  **3D** shows one chosen qubit's final state in the orbitable `Bloch3DSphereView`. Sphere
  cards use `.glassEffect(in:)`/`GlassEffectContainer`.
- **Origin of the code:** `BlochVector` is imported from the package's `SwiftQiskitViews`
  product (since `0.2.0`); this app no longer carries its own copy. `BlochSphereView` and
  `Bloch3DSphereView` are this app's own views, originally ported from the playground sources.
  Package `0.8.1` ships public `BlochSphereView` and `Bloch3DView` in `SwiftQiskitViews`; the
  app's same-named types take precedence where both are visible.
  `TensorNetwork`/`TensorNetworkView` are not ported either — they're used directly from the
  package's `SwiftQiskit`/`SwiftQiskitViews` products (added in `0.3.0`), so this app has no
  tensor-network code of its own.

## Extending

**Adding a new gate kind:**
1. Add a case to `GateKind` in `CircuitModel.swift`, plus its `symbol`/`qubitSpan` (and
   `theta`/`withTheta` if parameterized).
2. Add the matching case in `CircuitBuilder.apply(_:to:)`, calling the corresponding
   `QuantumCircuit` method (a controlled gate also calls its `mc*` variant when it has more
   than one control).
3. Add it to the appropriate group in `GatePaletteView`'s `sections` array.

Mostly no changes needed elsewhere — `CircuitGridView`/`GateTileView` render a `GateKind`
generically via `.symbol`/`.qubitSpan`/`.isControlled`. A new span-2 gate is symmetric
(both placed qubits render a tile, like `.rzz`/`.rxx`/`.ryy`) unless it distinguishes
control from target, in which case add it to `isControlled`'s switch. `GateTileView` and
`GatePaletteView` special-case `.cx`, `.cy`, `.cz` and `.swap` for their glyphs, so a new
controlled gate would draw its target as a plain dot until given a case there.

**Adding a chart type / result view:** follow `HistogramView.swift`'s pattern (a small,
stateless `View` taking a value type, not the whole `CircuitBuilder`) and wire it into
`MeasurementView.swift` (where `HistogramView` is used).

## Not implemented (v1 scope)

- **No drag-and-drop.** Tap-to-arm-then-tap-cell was chosen over `onDrag`/`dropDestination`
  for simplicity; revisit if it feels clunky in practice.
- **No persistence.** Closing the app discards the circuit; there's no save/load/export.
- **No undo.** `Clear` and qubit-count shrinking are immediate and irreversible within a
  session.
- **No mid-circuit or partial measurement** — a limitation of the underlying `QuantumCircuit`,
  not something the app UI could add on its own.

## Testing

`SwiftQiskitAppTests/CircuitBuilderTests.swift` covers `CircuitBuilder`'s logic only (no view
tests — SwiftUI views aren't unit-testable here): Bell-state replay via `buildCircuit()`,
occupied/out-of-range placement rejection, qubit-count clamping and gate-dropping on shrink,
`updateTheta`, `clear`, `measure()` populating `lastResult`, a qubit-count shrink
discarding a prior measurement, and RZZ/RXX/RYY replay across non-adjacent qubits checked
entrywise against a directly built `QuantumCircuit` using the same `rzz`/`rxx`/`ryy` calls
(RZZ additionally checked against the `cx;rz;cx` identity), plus `updateTheta` and
occupied-cell rejection for RZZ, multi-control CX/CY/CZ (`addControl`/`removeLastControl`
against `ccx`/`mcx`/`mcy`, rejections, shrink), SWAP and CZ/CCZ replay (CCZ checked against `h; ccx; h`), and an 8-qubit
timing guard. `CircuitLayoutTests.swift` covers the pure `CircuitLayout`
geometry: center spacing, `wireY` agreement with `center`, and `canvasSize` growth in each
dimension independently. `BlochVectorTests.swift` covers `BlochVector`'s math: single-qubit
coordinates for `H`/`X`/`H+S`, the Bell state's reduced vectors collapsing to the origin on
both qubits (`|r| == 0`, the entanglement signature), reduced-vector isolation between
independent qubits, and `buildCircuit(throughColumn:)` prefix replay. `Bloch3DProjectionTests.swift`
covers the pure `Bloch3DProjection` camera math: pole projection direction, near- vs
far-hemisphere perspective scale, and the silhouette-scale formula. Run via ⌘U or
`RunAllTests` under the `SwiftQiskitApp` scheme — all 41 tests are included in its test plan
(unlike the package's plain `SwiftQiskit` scheme, whose test plan has no test targets — a
pre-existing gotcha over there, not here).

## Troubleshooting

- **Tapping a gate button does nothing.** Check whether it's already armed (tinted with the
  accent color) — tapping an armed gate again disarms it instead of re-arming it.
- **Tapping a grid cell does nothing.** Nothing is armed, or that qubit is already occupied
  at that column — occupied cells render a tile, not the empty-cell hit target, so if you
  see a tile there, that's why.
- **A two-qubit gate (CX, CZ, SWAP, …) won't place.** Both taps must land in the *same column*; a stray tap elsewhere resets
  the pending control rather than placing the gate. Check for the orange ring to confirm a
  control is pending before the second tap.
- **State Vector panel looks stale.** It shouldn't — `ResultsView.body` calls
  `builder.buildCircuit().run()` fresh on every render. If it really doesn't update, that's a
  bug, not expected behavior.
- **"Package SwiftQiskit not found" / dependency resolution fails.** The app depends on
  `SwiftQiskit` as a remote package — check network access to GitHub, or try File ▸ Packages ▸
  Reset Package Caches followed by Resolve Package Versions.
- **Measure gives a different split every time.** Expected; `measure(shots:)` is
  probabilistic, same as everywhere in the `SwiftQiskit` package — re-run or raise the shot
  count for a tighter distribution.
