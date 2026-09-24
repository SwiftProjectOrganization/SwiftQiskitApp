# ___PACKAGENAME___

Generated from the **Quantum Algorithm App** Xcode template. A multiplatform SwiftUI app
prefilled with a discrete-time quantum walk — ported from
`SwiftQiskit/Playgrounds.playground/Pages/22Walk.xcplaygroundpage`. See "Add the SwiftQiskit
package" below before building — the template does not add it automatically.

## Layout

- `QuantumWalk.swift` — the algorithm itself. Pure math over SwiftQiskit's `Matrix` and
  `StateVector`; no SwiftUI import, so it can be reasoned about and tested independent of the
  view layer.
- `AlgorithmModel.swift` — the view model. `@MainActor @Observable`, holding the algorithm's
  inputs (`steps`, `symmetricCoin`) and recomputing its outputs (`quantumDistribution`,
  `classicalDistribution`, `quantumSigma`, `classicalSigma`) on `didSet`.
- `DistributionChartView.swift` — plots the two distributions with Swift Charts.
- `ContentView.swift` — controls (a steps stepper, a coin toggle), the chart, and a σ summary.
- `___PACKAGENAME___App.swift` — the `@main` entry point.
- `___PACKAGENAME___Tests/AlgorithmTests.swift` — checks the walk's invariants: the shift
  operator is unitary, distributions stay normalized, the classical walk is diffusive
  (σ/√t ≈ 1), the quantum walk is ballistic (σ grows faster), and the `|+i⟩` coin gives a
  distribution symmetric about the start site while `|0⟩` does not.

## Porting a different SwiftQiskit playground algorithm

1. Replace `QuantumWalk.swift` with a plain struct wrapping the target playground page's
   math — see `SwiftQiskit/PlaygroundDocs/*PLAN.md` for the derivation behind each page, and
   `SwiftQiskit/Playgrounds.playground/Pages/` for the runnable original.
2. Update `AlgorithmModel`'s inputs and outputs to match the new algorithm's parameters and
   results.
3. Adjust `DistributionChartView` — rename it if the new algorithm doesn't produce a
   distribution over discrete positions (e.g. a VQE energy sweep is a single curve over a
   continuous parameter, not two histograms).
4. Update `ContentView`'s controls and narration.
5. Update `AlgorithmTests` to check the new algorithm's invariants — usually the same
   assertions the playground page's own "Expected:" comments describe.

## Add the SwiftQiskit package

The template does not wire up the `SwiftQiskit` package dependency automatically — add it once,
by hand, after generating the project:

1. Select the project in the navigator, then the project (not target) → **Package Dependencies**.
2. Click **+**, enter `https://github.com/SwiftProjectOrganization/SwiftQiskit.git`.
3. Choose **Up to Next Minor Version**, starting at `0.1.0`.
4. Add the `SwiftQiskit` product to both the app target and the test target.
