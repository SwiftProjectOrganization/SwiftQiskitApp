# Xcode project template: "Quantum Algorithm App"

## Context

Each playground page in `../SwiftQiskit/Playgrounds.playground/Pages/` (22Walk, 18VQE, 15CHSH, …)
is a self-contained algorithm study that ends with a `PlaygroundPage.setLiveView(...)` chart.
Turning one of those into a real app today means hand-rolling a new Xcode project, re-adding the
`../SwiftQiskit` package reference, re-copying the chart view out of the playground's `Sources/`
(which isn't an importable SPM target), and rebuilding the same parameter-controls/results shell
every time.

The goal is a **File > New > Project** template that does all of that in one step: a multiplatform
SwiftUI app with SwiftQiskit already linked, a pure algorithm file, an `@Observable` model, a chart,
and a passing test suite — prefilled with a working port of playground 22Walk as the worked example.

Decisions already made: **project template** (not a file template), **local `../SwiftQiskit` path
reference** (matching this project's existing wiring), **discrete-time quantum walk** as the example.

## Research findings that shape the design

- Xcode project templates *can* wire up a Swift package. `Xcode3Core` exposes exactly one hook —
  `addPackageReferenceForPath:toGroup:` — driven by the `IsPackageReference` / `LinkPackageProducts`
  / `Path` keys in a `TemplateInfo.plist` `Definitions` entry. There is **no remote-URL key**.
  Reference implementation:
  `/Applications/Xcode.app/Contents/Developer/Library/Xcode/Templates/Project Templates/MultiPlatform/Application/Packages Foveated Streaming App.xctemplate/TemplateInfo.plist`
- Ancestor chain to inherit for a multiplatform SwiftUI app:
  `com.apple.dt.unit.multiPlatform.app.SwiftUI` (→ `applicationBase.SwiftUI` → `applicationBase`).
  It already supplies `Assets.xcassets`, app sandbox settings, Info.plist keys, and the
  `___PACKAGENAME:identifier___App.swift` + `ContentView.swift` nodes (under the `storageType = None`
  unit) that this template will **override by redeclaring nodes of the same name**.
- The unit-test component is a thin shim, `com.apple.dt.unit.multiPlatform.app.SwiftUI.tests.unit`
  (`MultiPlatform/Base/Multiplatform SwiftUI App Testing Bundle.xctemplate`), easy to subclass and
  add one extra test-file node to.
- The package *product* is `SwiftQiskit`; the *module* is `SwiftQiskitCore` — so
  `LinkPackageProducts = ["SwiftQiskit"]` but generated source says `import SwiftQiskitCore`.
- `SwiftQiskit` has a GitHub remote but **no tags**, which is why the local-path choice is the sound
  one here.

## Repo layout to add

```
SwiftQiskitApp/Templates/
├── README.md                                     # what this is, how to install, how to add an algorithm
├── install.sh                                    # symlinks into ~/Library/Developer/Xcode/Templates/
└── SwiftQiskit/                                  # folder name = category header in the New Project sheet
    ├── Quantum Algorithm App.xctemplate/
    │   ├── TemplateInfo.plist
    │   ├── App.swift
    │   ├── ContentView.swift
    │   ├── AlgorithmModel.swift
    │   ├── QuantumWalk.swift
    │   ├── DistributionChartView.swift
    │   └── README.md
    └── Quantum Algorithm App Tests.xctemplate/
        ├── TemplateInfo.plist
        └── AlgorithmTests.swift
```

`install.sh` creates `~/Library/Developer/Xcode/Templates/` (it does not exist yet on this machine)
and symlinks `SwiftQiskit` into it, so edits to the repo are live without reinstalling.

## `Quantum Algorithm App.xctemplate/TemplateInfo.plist`

- `Kind = Xcode.Xcode3.ProjectTemplateUnitKind`, `Concrete = true`,
  `Identifier = com.robertgoedman.swiftqiskit.quantumAlgorithmApp`,
  `Ancestors = [com.apple.dt.unit.multiPlatform.app.SwiftUI]`,
  `NameOfInitialFileForEditor = ContentView.swift`.
- `Definitions` / `Nodes` overriding the ancestor and adding the new files:

  | Node | Path | Notes |
  |---|---|---|
  | `___PACKAGENAME:identifier___App.swift` | `App.swift` | overrides ancestor |
  | `ContentView.swift` | `ContentView.swift` | overrides ancestor |
  | `AlgorithmModel.swift` | `AlgorithmModel.swift` | new |
  | `QuantumWalk.swift` | `QuantumWalk.swift` | new |
  | `DistributionChartView.swift` | `DistributionChartView.swift` | new |
  | `README.md` | `README.md` | `TargetIdentifiers = []` so it isn't compiled |
  | `SwiftQiskit` | `../SwiftQiskit` | the package reference, below |

- The package reference definition:

  ```xml
  <key>SwiftQiskit</key>
  <dict>
      <key>IsPackageReference</key><true/>
      <key>IsTopLevel</key><true/>
      <key>Path</key><string>../SwiftQiskit</string>
      <key>LinkPackageProducts</key><array><string>SwiftQiskit</string></array>
      <key>TargetIdentifiers</key>
      <array>
          <string>com.apple.dt.applicationTarget</string>
          <string>com.apple.dt.applicationUnitTestBundleTarget</string>
      </array>
  </dict>
  ```

  The test bundle is listed too, because the generated tests use `Matrix`/`Ket` directly, not just
  `@testable import`.

- `Targets[0].SharedSettings` to match this project's settings:
  `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`, `SWIFT_APPROACHABLE_CONCURRENCY = YES`,
  `SUPPORTED_PLATFORMS = "iphoneos iphonesimulator macosx"`, `IPHONEOS/MACOSX_DEPLOYMENT_TARGET = 27.0`.
- `testingSystem` option redeclared with `Default = "Swift Testing"`, its `Swift Testing` unit pointing
  at the local component `com.robertgoedman.swiftqiskit.quantumAlgorithmApp.tests` instead of Apple's.

`Quantum Algorithm App Tests.xctemplate` is `Concrete = false`, ancestor
`com.apple.dt.unit.multiPlatform.app.SwiftUI.tests.unit`, adding one node
`___PACKAGENAME:identifier___AlgorithmTests.swift` → `AlgorithmTests.swift`. Additive only, so it does
not need to know Apple's own test-file node name.

## Generated source design

Three-layer split — this is the part that makes swapping in 18VQE a one-file change.

**`QuantumWalk.swift`** — pure, no SwiftUI, no observation. Direct port of
`Pages/22Walk.xcplaygroundpage/Contents.swift` sections 1–4: `buildShift()` as a permutation `Matrix`,
`U = S * (H ⊗ I)`, `initialState(coin:)`, `positionDistribution(_:)`, `classicalStep(_:)`, and the
cyclic-coordinate-aware `signedOffset` / `stddevSigned` (keep the playground's comment explaining why
raw indices give the wrong variance across the 0/15 wrap). Wrapped in a `struct QuantumWalk` that
builds the step operator once in `init(siteCount: Int = 16)`.

**`AlgorithmModel.swift`** — `@MainActor @Observable final class AlgorithmModel`: inputs `steps` and
`symmetricCoin` (|0⟩ vs `StateVector.plusI`), outputs `quantumDistribution`, `classicalDistribution`,
`quantumSigma`, `classicalSigma`, refreshed by an explicit `recompute()` on `didSet`. Explicit
recompute rather than computed properties (the pattern `ResultsView` uses today) because a real
algorithm port — a VQE optimizer sweep — is not cheap enough to redo every render; the file comment
says so and marks where to make `recompute()` async.

**`DistributionChartView.swift`** — Swift Charts (`LineMark`/`PointMark`, two series: quantum orange,
classical blue, x = signed offset from the start site, y = probability). Deviation worth naming: the
playgrounds hand-roll `CHSHChartView` on `Canvas` (142 lines) because playground `Sources/` can't
import much; in an app target Swift Charts is ~30 lines and brings axes and a legend for free.

**`ContentView.swift`** — title, a short paragraph of narration, a controls panel (steps `Slider`
1...7, coin `Toggle`), the chart, and a σ-comparison row showing ballistic vs. diffusive spreading.
Controls panel gets `.glassEffect()` per the Liquid Glass rule in `CLAUDE.md`; confirm the current API
spelling with the `xcode-integration:swiftui-whats-new-27` skill before writing it.

**`App.swift`** — mirrors `SwiftQiskitApp/SwiftQiskitAppApp.swift:8`, including the `#if os(macOS)`
`minWidth`/`defaultSize`/`windowResizability` block.

**`AlgorithmTests.swift`** — Swift `Testing`, mirroring the assertions the playground prints as
"Expected:" comments: `S†S = I` to within 1e-12; each distribution sums to 1; classical σ/√t == 1 at
every t; quantum σ at t=7 exceeds classical; the `|+i⟩` coin is symmetric at every mirrored pair
(1↔15, 3↔13, 5↔11, 7↔9) while the `|0⟩` coin is not.

**`README.md`** (inside the generated project) — how to point the app at a different playground page:
replace `QuantumWalk.swift`, adjust the four `AlgorithmModel` outputs, relabel the chart.

## Docs

Add `Templates/` to the Documentation index in `CLAUDE.md` and one line to the repo `README.md`.
Prose follows the sober style rule in `CLAUDE.md`.

## Risk and fallback

The one genuinely unverified step is whether `Path = ../SwiftQiskit` — a package reference pointing
*outside* the generated project directory, with no matching directory inside the `.xctemplate` — is
accepted. Apple's only example copies a package folder it ships. Verify this first (step 2 below).

If Xcode rejects it, fall back to Apple's proven shim pattern: ship
`Packages/SwiftQiskitLocal/{Package.swift, Sources/SwiftQiskitLocal/Exports.swift}` in the template,
with `.package(path: "../../../SwiftQiskit")` and `@_exported import SwiftQiskitCore`, and
`LinkPackageProducts = ["SwiftQiskit"]`. That is byte-for-byte the shape of
`Packages Foveated Streaming App.xctemplate`, so it is known to work; it just adds one indirection.

## Steps

1. Create `Templates/SwiftQiskit/Quantum Algorithm App.xctemplate/TemplateInfo.plist` and
   `install.sh`; run the install.
2. **Verify the package reference early**, before writing any Swift: with only stub `App.swift` /
   `ContentView.swift` nodes, generate a throwaway project at `/Users/rob/Projects/Swift/_TemplateCheck`
   and confirm `project.pbxproj` contains an `XCLocalSwiftPackageReference` with
   `relativePath = ../SwiftQiskit` (compare `SwiftQiskitApp.xcodeproj/project.pbxproj:580-591`).
   Switch to the shim fallback here if it fails.
3. Write `QuantumWalk.swift`, porting from the playground page.
4. Write `AlgorithmModel.swift`, `DistributionChartView.swift`, `ContentView.swift`, `App.swift`.
5. Add the tests component template and `AlgorithmTests.swift`.
6. Write `Templates/README.md` and the generated project's `README.md`; update `CLAUDE.md` and the
   repo `README.md` index entries.

## Verification

- `./Templates/install.sh`, relaunch Xcode, confirm a **SwiftQiskit** section with **Quantum Algorithm
  App** appears in File > New > Project.
- Generate `WalkDemo` as a sibling of `SwiftQiskit` (`/Users/rob/Projects/Swift/WalkDemo`).
- Build for **My Mac** and an iOS simulator via `BuildProject`; run via `RunProject` and drag the steps
  slider — the quantum curve should go two-peaked and outspread the classical hump by t=7.
- ⌘U / `RunAllTests` in the generated project: all assertions pass.
- Re-generate once in a directory that is *not* a sibling of `SwiftQiskit` and confirm the failure is a
  clear "missing package" error, then document that requirement in `Templates/README.md`.
- Delete the scratch projects.

## Later extension (not in this change)

The `Algorithm:` popup is the natural next step: a `Type = popup` option in `TemplateInfo.plist` whose
units swap `QuantumWalk.swift` for `VQE.swift` / `CHSH.swift`, each with its own `AlgorithmModel`
outputs — one template covering several playground pages.
