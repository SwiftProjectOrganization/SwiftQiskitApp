# SwiftQiskitApp — help & reference

Implementation reference, extension guide, and troubleshooting for SwiftQiskitApp. The
user-facing walkthrough (how to actually use the app) is [Tutorial.md](Tutorial.md); this
document is its companion — how it's built, not how to drive it.

## Why a separate front-end model exists

`QuantumCircuit` (in the `SwiftQiskit` package) records each operation as only the resulting
full-dimension `Matrix` — no gate name, no target qubit, no column. That's enough to
`run()`/`measure(shots:)`, but not enough to draw or edit a circuit diagram after the fact:
there's nothing to inspect. So the app keeps its own record of *placed* gates
(`CircuitModel.swift`) and replays them onto a fresh `QuantumCircuit` whenever it needs to
run. No `SwiftQiskitCore` changes were needed for this feature.

## File map (`SwiftQiskitApp/`)

| File | Contents |
|---|---|
| `CircuitModel.swift` | `GateKind`, `PlacedGate`, `CircuitBuilder` — the model, no SwiftUI import |
| `CircuitLayout.swift` | Pure geometry — turns `(column, qubit)` into points shared by the wire layer and the interactive gate layer so they can't drift apart |
| `CircuitWiresView.swift` | Background `Canvas` layer: one horizontal wire per qubit, plus a vertical connector between a CX gate's control and target |
| `CircuitBuilderView.swift` | Regular-width (macOS/iPad) 3-pane layout; takes `builder`/`armedGate` from `ContentView` |
| `CompactBuilderView.swift` | iPhone-compact layout (`#if os(iOS)`): full-bleed grid + horizontal gate strip, results in a sheet |
| `GatePaletteView.swift` | Gate buttons, grouped by category; arms a `GateKind`; `.sidebar` (macOS/iPad) or `.strip` (iPhone) layout |
| `CircuitGridView.swift` | The qubit-wire grid; tap-to-place and the CX two-tap state machine |
| `GateTileView.swift` | `GateTileView` (a placed single-qubit or CX-control tile), `CXTargetView` (the ⊕ half of a CX), `EmptyCellView` |
| `ParameterPopover.swift` | θ slider for `.p/.rx/.ry/.rz` tiles |
| `ResultsView.swift` | Live state vector + shots/Measure/histogram |
| `HistogramView.swift` | Bar chart of `SimulationResult` counts |
| `ContentView.swift` | Owns the `CircuitBuilder` and `armedGate` state; picks `CircuitBuilderView` vs. `CompactBuilderView` by size class on iOS |
| `SwiftQiskitAppApp.swift` | `@main App`; sets a minimum/default window size on macOS |

## The model (`CircuitModel.swift`)

```swift
public enum GateKind: Equatable, Hashable {
    case h, x, y, z, s, sdg, t, tdg
    case p(Double), rx(Double), ry(Double), rz(Double)
    case cx
    // .symbol, .qubitSpan (1, or 2 for .cx), .isParameterized, .theta, .withTheta(_:)
}

public struct PlacedGate: Identifiable, Equatable {
    public let id: UUID
    public var kind: GateKind
    public var qubits: [Int]   // 1 entry, or [control, target] for .cx
    public var column: Int
}

@MainActor
@Observable public final class CircuitBuilder {
    public var qubitCount: Int   // clamped 1...8; shrinking drops now-out-of-range gates
    public var gates: [PlacedGate]

    public func place(_ kind: GateKind, qubits: [Int], column: Int) -> Bool  // false if out of range or occupied
    public func remove(id: UUID)
    public func updateTheta(id: UUID, theta: Double)
    public func clear()
    public func buildCircuit() -> QuantumCircuit   // sorts by column, replays onto a fresh circuit
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
- `.cx` armed → the **first** tap on an empty cell sets `pendingControl = (column, qubit)`
  (view-local `@State`, not part of `CircuitBuilder` — it's ephemeral UI state, not circuit
  data). The **second** tap must be in the *same column*, a *different* qubit row; it
  commits `builder.place(.cx, qubits: [control, target], column:)`. A tap that breaks
  either rule resets `pendingControl` to the new cell rather than erroring.
- A `PlacedGate` is drawn once, at its "primary" qubit (`gate.qubits.first`) — that's where
  `GateTileView` renders (the symbol, or a filled dot for CX's control). The other qubit(s)
  of a multi-qubit gate render `CXTargetView` (the ⊕ glyph) instead. Deleting works from
  either half.
- The grid sits on two layers sharing one `CircuitLayout`: `CircuitWiresView` (a `Canvas`)
  draws the horizontal qubit wires and the vertical CX control→target connector *behind*
  everything, and `CircuitGridView` `.position()`s labels/cells on top from the same
  `center(column:qubit:)` geometry, so the two layers can't drift apart. Single-qubit tiles
  paint an opaque backing (`GateTileView.boxedBackground`) so they read clearly over the
  wire; CX dots and `EmptyCellView`'s pending-control marker are transparent rings instead,
  so the wire shows through.

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

## Extending

**Adding a new gate kind:**
1. Add a case to `GateKind` in `CircuitModel.swift`, plus its `symbol`/`qubitSpan` (and
   `theta`/`withTheta` if parameterized).
2. Add the matching case in `CircuitBuilder.apply(_:to:)`, calling the corresponding
   `QuantumCircuit` method.
3. Add it to the appropriate group in `GatePaletteView`'s `sections` array.

No changes needed anywhere else — `CircuitGridView`/`GateTileView` render any `GateKind`
generically via `.symbol`/`.qubitSpan`.

**Adding a chart type / result view:** follow `HistogramView.swift`'s pattern (a small,
stateless `View` taking a value type, not the whole `CircuitBuilder`) and wire it into
`ResultsView.swift`.

## Relationship to SwiftQiskitGUI

This app's 13 source files are a near-identical copy of
`../SwiftQiskit/Sources/SwiftQiskitGUI/` — the package's own SwiftPM-executable version of
the same UI (documented in `../SwiftQiskit/SwiftQiskitDocs/GUIHELP.md`). The two copies exist
independently and can drift out of sync; there is currently no shared module between them.
When changing behavior here, consider whether the same change should apply to
`SwiftQiskitGUI`.

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
`updateTheta`, and `clear`. `CircuitLayoutTests.swift` covers the pure `CircuitLayout`
geometry: center spacing, `wireY` agreement with `center`, and `canvasSize` growth in each
dimension independently. Run via ⌘U or `RunAllTests` under the `SwiftQiskitApp` scheme — all
10 tests are included in its test plan (unlike the package's plain `SwiftQiskit` scheme,
whose test plan has no test targets — a pre-existing gotcha over there, not here).

## Troubleshooting

- **Tapping a gate button does nothing.** Check whether it's already armed (tinted with the
  accent color) — tapping an armed gate again disarms it instead of re-arming it.
- **Tapping a grid cell does nothing.** Nothing is armed, or that qubit is already occupied
  at that column — occupied cells render a tile, not the empty-cell hit target, so if you
  see a tile there, that's why.
- **CX won't place.** Both taps must land in the *same column*; a stray tap elsewhere resets
  the pending control rather than placing the gate. Check for the orange ring to confirm a
  control is pending before the second tap.
- **State Vector panel looks stale.** It shouldn't — `ResultsView.body` calls
  `builder.buildCircuit().run()` fresh on every render. If it really doesn't update, that's a
  bug, not expected behavior.
- **"Package SwiftQiskit not found" / dependency resolution fails.** The app depends on
  `../SwiftQiskit` by relative path — check that a `SwiftQiskit` checkout exists as a sibling
  of this repo's folder.
- **Measure gives a different split every time.** Expected; `measure(shots:)` is
  probabilistic, same as everywhere in the `SwiftQiskit` package — re-run or raise the shot
  count for a tighter distribution.
- **visionOS.** The app builds for visionOS (it's in `SUPPORTED_PLATFORMS`) but this has not
  been verified on-device or in the simulator — treat it as unsupported until checked.
