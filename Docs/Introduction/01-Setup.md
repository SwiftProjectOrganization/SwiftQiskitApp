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
- **A sibling checkout is worth having anyway.** This book's second way of running examples,
  §1.3 below, is `using the SwiftQiskitPlaygrounds/Playgrounds/`. Put a `SwiftQiskitPlaygorun`
checkout next to `SwiftQiskitApp` on disk if you want to follow those links locally — the app doesn't
need it, but you'll want it for the playgrounds.

## 1.2 A five-minute tour of the app

Launch `SwiftQiskitApp` and you'll see three panes on macOS or iPad (rearranged into a
compact layout on iPhone — more on that below):

| Panel | What it's for |
|---|---|
| **Gates** (left) | Tap a gate button to *arm* it; it highlights. Sections are Pauli/Hadamard (`H X Y Z`), Phase (`S S† T T†`), Rotation (`P RX RY RZ`, each with a θ parameter), Multi-qubit (`CX CY CZ SWAP`), and Two-qubit rotation (`RZZ RXX RYY`, each with a θ parameter). |
| **Circuit** (center) | A grid, one horizontal wire per qubit. Tap an empty cell to place the armed gate there. The **Qubits** stepper (1–8 — shrinking it drops any placed gates that no longer fit) and the **Clear**, **Results**, **Measure** and **Display** buttons sit in a floating bar at the bottom of the window. |
| **State Vector** (right) | Live amplitudes and probabilities for the circuit as currently built, recomputed on every change with no explicit "run" step, with a separate **Measurement** section below it holding the **Shots** stepper, the **Measure** button and the histogram. |

A **Display** button in the bottom bar opens the Bloch-sphere views of the circuit (Final, Steps, Tensor and 3D) — the same
sheet §0.3 pointed at for seeing entanglement directly. Tapping a placed parameterized tile
(`P`, `RX`, `RY`, `RZ`, `RZZ`, `RXX` or `RYY`) opens a popover with a θ slider from 0 to 2π. Tapping a placed `CX`, `CY` or `CZ` opens a **Controls** popover for adding extra controls.

On iPhone, the same controls move into a compact layout: the circuit grid fills the screen with
the gate strip pinned below it, the **Qubits** stepper sits top-left, and **Clear**, **Results**, **Measure** and **Display**
sit top-right, with Results, Measurement and Display each opening in a sheet. Every control above still exists; only the arrangement
changes.

This is the five-minute version. For the full control-by-control reference, see
[`Docs/Tutorial.md`](../Tutorial.md) and [`Docs/Help.md`](../Help.md) — this book won't repeat
what they already cover well.

## 1.3 A five-minute tour of the playground

The second way to run this book's examples is `../SwiftQiskitPlaygrounds/SwiftQiskitPlaygrounds`, opened in
Xcode. Please see the [README] there.

## 1.4 Running code on its own

The third way — the only option once a chapter needs something the app's fixed gate palette
can't express, such as a custom matrix or mid-circuit measurement — is plain Swift:
`import SwiftQiskit` in a scratch file, a playground, or via the `RunCodeSnippet` tool, and
write a few lines directly. This chapter's own "Run it in code" section below is the smallest
possible example of that.

## 1.5 The SwiftQiskitPlaygrounds project

The fourth way is `../SwiftQiskitPlaygrounds`
([GitHub](https://github.com/SwiftProjectOrganization/SwiftQiskitPlaygrounds)), a separate
project that holds playground pages for `SwiftQiskit`. To use it:

1. Open `SwiftQiskitPlaygrounds.xcodeproj`.
2. Select the `PlaygroundDeps` scheme (My Mac) and build. It links `SwiftQiskit` and
   `SwiftQiskitViews`, which the pages import.
3. Open a page under `SwiftQiskitPlaygrounds.playground/Pages/` and run it.

It has one page per chapter (`01Matrices` through `26TensorDiagrams`, plus `50StateVectorCPU`).
Like the app, it uses `SwiftQiskit` as a remote package (currently 0.8.1), so it needs no
sibling checkout of `SwiftQiskit`.

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

1. Open `SwiftQiskitApp.xcodeproj` on a machine with no `SwiftQiskit` checkout anywhere on disk
   and confirm it still builds. Then open `SwiftQiskitPlaygrounds.xcodeproj` and confirm it
   builds too.
   <details><summary>Answer</summary>Both build independently. The app's dependency is a
   version-pinned GitHub URL, so Xcode fetches it into its own cache regardless of what else is
   on disk; the playground lives inside the `SwiftQiskit` repo itself and was never affected by
   where `SwiftQiskitApp` sits.</details>

2. Suppose you're actively editing `SwiftQiskit` and want `SwiftQiskitApp` to pick up your
   changes immediately, before committing or tagging a release. Just having a `../SwiftQiskit`
   checkout on disk isn't enough by itself anymore — why not, and what do you do instead?
   <details><summary>Answer</summary>The app's dependency is declared by URL and version now,
   not by relative path, so Xcode has no reason to look at a sibling folder unless told to.
   Drag the local `../SwiftQiskit` checkout into the app's Xcode workspace as a local package —
   a local package overrides a remote dependency of the same name — to get instant edits back;
   remove the override when you're done.</details>

3. The app's palette includes `T†` (`tdg`). Search the
   playground pages in `SwiftQiskitPlaygrounds` for `tdg(` and find which page calls it.
   <details><summary>Answer</summary>`15Grover` — its 3-qubit CCZ decomposition (Chapter 15
   §15.9) uses `t` and `tdg` around `cx`. It's also a tappable tile in the app.</details>

---
[← Chapter 0](00-Introduction.md) · [Contents](../../INTRODUCTION.md) · [Chapter 2 →](02-ComplexAndMatrices.md)
