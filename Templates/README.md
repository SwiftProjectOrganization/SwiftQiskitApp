# SwiftQiskit Xcode templates

An Xcode project template for turning a SwiftQiskit playground algorithm into a real app,
instead of hand-wiring the package reference and view scaffolding every time.

## What's here

- **Quantum Algorithm App** — a multiplatform SwiftUI app template. It links the local
  `../SwiftQiskit` package the same way `SwiftQiskitApp.xcodeproj` does, and comes prefilled
  with a working example: a discrete-time quantum walk (ported from
  `SwiftQiskit/Playgrounds.playground/Pages/22Walk.xcplaygroundpage`), split into a pure
  algorithm file, an `@Observable` view model, a Swift Charts view, and a unit test suite.
- **Quantum Algorithm App Tests** — the unit test bundle component the app template uses.
  Not user-facing; Xcode instantiates it automatically when you create the app.

## Install

```sh
./install.sh
```

This symlinks `Templates/SwiftQiskit/` into `~/Library/Developer/Xcode/Templates/`. Restart
Xcode, then look for a **SwiftQiskit** section in File > New > Project. The symlink means
edits to the templates in this repo take effect without reinstalling.

## Requirement: sibling checkout

Like `SwiftQiskitApp` itself, a project generated from this template references the
`SwiftQiskit` package at the relative path `../SwiftQiskit`. Create the new project as a
sibling of your `SwiftQiskit` checkout — e.g. if `SwiftQiskit` lives in
`~/Projects/Swift/SwiftQiskit`, create the new project in `~/Projects/Swift/<NewApp>`. If
package resolution fails in the generated project, this is almost always why.

## Porting a different playground algorithm

The generated project's own `README.md` (`Quantum Algorithm App.xctemplate/README.md`, copied
into every project this template creates) covers this in more detail, but in short:

1. Replace `QuantumWalk.swift` with the math from the playground page you want, as a plain
   struct with no SwiftUI import — see `PlaygroundDocs/*PLAN.md` in `SwiftQiskit` for the
   derivation behind each page.
2. Update `AlgorithmModel`'s inputs and outputs to match.
3. Adjust `DistributionChartView` (rename it too, if the new algorithm doesn't produce a
   distribution) and `ContentView`'s controls.
4. Update `AlgorithmTests` to check the new algorithm's invariants instead.
