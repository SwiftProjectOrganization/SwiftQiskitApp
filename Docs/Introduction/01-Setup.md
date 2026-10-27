# Chapter 1 — Setup and Orientation

> What you need installed, how the app and the playground relate to each other, and a first,
> real circuit — built by tapping and confirmed by running actual Swift — before Chapter 2
> starts teaching the math behind it.

| | |
|---|---|
| Playground page | — |
| In the app | ● — this chapter is the app's own tour: every control it names is on screen |
| Library APIs | `import SwiftQiskit` |
| Prerequisites | Chapter 0 |

## 1.1 What you'll need

- **Xcode 27**, targeting macOS 27 / iOS 27.
- **Nothing else, to build the app.** `SwiftQiskitApp` depends on `SwiftQiskit` as a remote
  Swift package (a version-pinned GitHub URL, not a local path), so Xcode resolves it
  automatically the first time you open or build the project — no sibling checkout, no manual
  setup.
- **At least one sibling checkout is worth having anyway.** This book's second way of running examples,
  §1.3 below, is `using the SwiftQiskitPlaygrounds/Playgrounds/`. Put a `SwiftQiskitPlayground`
checkout next to `SwiftQiskitApp` on disk if you want to follow those links locally — the app doesn't
need it, but you'll want it for the playgrounds.
- **A second sibling checkout is worth as well:** By checking out SwiftQiskit you can occasionally look
at the complete API documentation, the summary tables in its README and also a large number of test
routines. 

## 1.2 A five-minute tour of the app

Launch `SwiftQiskitApp` and you'll see three panes on macOS, iPad or iPhone Duo (rearranged into a
compact layout on iPhone — more on that below):

| Panel | What it's for |
|---|---|
| **Gates** (left) | Tap a gate button to *arm* it; it highlights. Sections are Pauli/Hadamard (`H X Y Z`), Phase (`S S† T T†`), Rotation (`P RX RY RZ`, each with a θ parameter), Variable multi-qubit (`CX CY CZ`), Fixed multi-qubit (`SWAP Toffoli`), and Two-qubit rotation (`RZZ RXX RYY`, each with a θ parameter). |
| **Circuit** (center) | A grid, one horizontal wire per qubit. Tap an empty cell to place the armed gate there. The **Qubits** stepper (1–8 — shrinking it drops any placed gates that no longer fit) and the **Clear**, **Results**, **Measure** and **Display** buttons sit in a floating bar at the bottom of the window. |
| **State Vector** (right) | Live amplitudes and probabilities for the circuit as currently built, recomputed on every change with no explicit "run" step, with a separate **Measurement** section below it holding the **Shots** stepper, the **Measure** button and the histogram. |

There is some overlap in functionality in the toolbar at the bottom of the screen. This comes in handy when using circuits with 4 to 8 qubits. Inthat case the State vector gets pretty long and the same is true for measurements.

A **Display** button in the bottom bar opens the Bloch-sphere views of the circuit (Final, Steps, Tensor and 3D) — the same
sheet §0.3 pointed at for seeing entanglement directly. Tapping a placed parameterized tile
(`P`, `RX`, `RY`, `RZ`, `RZZ`, `RXX` or `RYY`) opens a popover with a θ slider from 0 to 2π. Tapping a placed `CX`, `CY` or `CZ` opens a **Controls** popover for adding extra controls.

On iPhone, the same controls move into a compact layout: the circuit grid fills the screen with
the gate strip pinned below it, the **Qubits** stepper sits top-left, and **Clear**, **Results**, **Measure** and **Display**
sit top-right, with Results, Measurement and Display each opening in a sheet. Every control above still exists; only the arrangement
changes.

This is the five-minute version. For the full control-by-control reference, see[` Docs/Tutorial.md`](../Tutorial.md) and [`Docs/Help.md`](../Help.md) — this book won't repeat
what they already cover well.

## 1.3 A five-minute tour of the SwiftQiskitPlayground project

The second way to run this book's examples is `../SwiftQiskitPlaygrounds/SwiftQiskitPlaygrounds`, opened in
Xcode. Please see the [README](https://github.com/SwiftProjectOrganization/SwiftQiskitPlaygrounds/Readme.md) there.

1. Open `SwiftQiskitPlaygrounds.xcodeproj`.
2. Select the `PlaygroundDeps` scheme (My Mac) and build. It links `SwiftQiskit` and
   `SwiftQiskitViews`, which the pages import.
3. Open a page under `SwiftQiskitPlaygrounds.playground/Pages/` and run it.

It has one page per chapter (`01Matrices` through `26TensorDiagrams`, plus `50StateVectorCPU`).
Like the app, it uses `SwiftQiskit` as a remote package (currently 0.9.0), so it needs no
sibling checkout of `SwiftQiskit`.

## 1.4 Running code on its own

Another way is to run plain Swift:` import SwiftQiskit` in a scratch file, a playground, or via the `RunCodeSnippet` tool, and
write a few lines directly. This chapter's own "Run it in code" section below is the smallest possible example of that.

There is also a template system that helps in generating stand-alone Swift apps, e.g. see SwiftQiskitWalkDemo. Or generate such an 
app through AI options such as Claude Code + Sonnet.

## Build it in the app

● Full. This is the "does everything work" smoke test before Chapter 3 begins teaching amplitudes
for real:

1. **Launch the app.** It opens on the default 2-qubit circuit (`q0`, `q1`), empty.
2. **Arm the Hadamard.** In the palette's **"Pauli / Hadamard"** section, tap **H** — it
   highlights.
3. **Place it.** Tap the first empty cell in the `q0` row. An `H` tile appears there.
4. **Read the State Vector panel.** It now lists two states, `|00⟩` and `|10⟩`, each at
   probability ≈ 0.500 (amplitude ≈ 0.707). Because `q0` is the *leftmost* bit in every label,
   it's the first character that's split here, not the second.
5. **Open Display.** Tap **Display**; `q0`'s Bloch-sphere arrow sits on the `+x` equator — the
   geometric picture of the superposition you just read numerically in step 4.

## Run it in code

The smallest possible circuit that proves the module imports and actually runs — one qubit,
one Hadamard:

```swift
import SwiftQiskit

let circuit = QuantumCircuit(qubits: 1)
circuit.h(0)
let finalState = circuit.run()
print(finalState)
```

Actual output from running this snippet:

```text
|0⟩: 0.7071067811865475
|1⟩: 0.7071067811865475
```

Both amplitudes are √2⁄2 ≈ 0.707, matching the ≈ 0.500-probability split you saw in the app's
State Vector panel in step 4 above — same circuit, same result, two different ways of running it.

## Try it yourself

1. Open `SwiftQiskitApp.xcodeproj` on a machine with no `SwiftQiskit` checkout anywhere on disk and confirm it still builds.
2. Open `SwiftQiskitPlaygrounds.xcodeproj` and confirm it builds too by running a playground.
3. Open SwiftQiskit and take a look at its README.

```text
```text
Note: Inside Xcode markdown formatting is not always correct. On Github or in a tool such as Clearly the formatting is fine.
```
```
   
---
[← Chapter 0](00-Introduction.md) · [Contents](../../INTRODUCTION.md) · [Chapter 2 →](02-ComplexAndMatrices.md)
