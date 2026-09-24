# Chapter 1 — Setup and Orientation

> What you need installed, how the app and the playground relate to each other, and a first,
> real circuit — built by tapping and confirmed by running actual Swift — before Chapter 2
> starts teaching the math behind it.

| | |
|---|---|
| Playground page | — |
| Library APIs | `import SwiftQiskit` |
| Prerequisites | Chapter 0 |

## 1.1 What you'll need

- **Xcode 27**, targeting macOS 27 / iOS 27.
- **Nothing else, to build the app.** `SwiftQiskitApp` depends on `SwiftQiskit` as a remote
  Swift package (a version-pinned GitHub URL, not a local path), so Xcode resolves it
  automatically the first time you open or build the project — no sibling checkout, no manual
  setup.
- **A sibling checkout is worth having anyway.** This book's second way of running examples,
  §1.3 below, is `SwiftQiskit/Playgrounds.playground`, and its `PlaygroundDocs/*HELP.md` guides
  are referenced throughout this book. Put a `SwiftQiskit` checkout next to `SwiftQiskitApp` on
  disk if you want to follow those links locally — the app doesn't need it, but you'll want it
  for the playground.

## 1.2 A five-minute tour of the app

Launch `SwiftQiskitApp` and you'll see three panes on macOS or iPad (rearranged into a
compact layout on iPhone — more on that below):

| Panel | What it's for |
|---|---|
| **Gates** (left) | Tap a gate button to *arm* it; it highlights. Sections are Pauli/Hadamard (`H X Y Z`), Phase (`S S† T T†`), Rotation (`P RX RY RZ`, each with a θ parameter), and Multi-qubit (`CX`). |
| **Circuit** (center) | A grid, one horizontal wire per qubit. Tap an empty cell to place the armed gate there. Has the **Qubits** stepper (1–8 — shrinking it drops any placed gates that no longer fit) and a **Clear** button. |
| **State Vector** (right) | Live amplitudes and probabilities for the circuit as currently built, recomputed on every change with no explicit "run" step, plus a **Measure** button and a shot-count histogram. |

A **Display** button next to **Clear** opens a 2D Bloch-sphere view of the circuit — the same
sheet §0.3 pointed at for seeing entanglement directly. Tapping a placed parameterized tile
(`P`, `RX`, `RY`, or `RZ`) opens a popover with a θ slider from 0 to 2π.

On iPhone, the same controls move into a compact layout: the circuit grid fills the screen with
the gate strip pinned below it, **Qubits** becomes a toolbar menu, and **Results** / **Display**
open in sheets from bottom-bar buttons. Every control above still exists; only the arrangement
changes.

This is the five-minute version. For the full control-by-control reference, see
[`Docs/Tutorial.md`](../Tutorial.md) and [`Docs/Help.md`](../Help.md) — this book won't repeat
what they already cover well.

## 1.3 A five-minute tour of the playground

The second way to run this book's examples is `../SwiftQiskit/Playgrounds.playground`, opened in
Xcode. Two things to know before you run any page:

- **Make the `SwiftQiskit` scheme active first.** Every page sets `buildActiveScheme`, and won't
  run under any other scheme.
- **Start at `00TOC`.** It's a clickable table of contents linking every page, in order, with a
  one-line description of each.

Pages are named with an `NNName` convention — `01Qubits`, `02Bloch2d`, and so on up to `22Walk` —
and each page's own guide lives in `../SwiftQiskit/PlaygroundDocs/NN…HELP.md`. Pages 09–22 also
have a design-notes counterpart, `NN…PLAN.md`. One guide isn't tied to a single page:
`90LIVEVIEWHELP.md` documents the Bloch-sphere and chart types shared across pages via the
playground's own `Sources/` folder. If you're on an Xcode 27 beta and a live-view page misbehaves,
check `../SwiftQiskit/PLAYGROUNDSUPPORT.md` for the current beta workarounds.

## 1.4 Running code on its own

The third way — the only option once a chapter needs something the app's fixed gate palette
can't express, such as a custom matrix or mid-circuit measurement — is plain Swift:
`import SwiftQiskit` in a scratch file, a playground, or via the `RunCodeSnippet` tool, and
write a few lines directly. This chapter's own "Run it in code" section below is the smallest
possible example of that.

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
   and confirm it still builds. Then open `SwiftQiskit/Playgrounds.playground` and confirm it
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

3. The app's palette includes `T†` (`tdg`). Skim the gate table in
   `../SwiftQiskit/README.md` and find which playground page actually calls `tdg(qubit)`.
   <details><summary>Answer</summary>None of them — the gate table notes that `t` is applied
   twice on page 05 to show `T² == S`, but `tdg` isn't exercised on any page. It's tappable in
   the app even though no playground page happens to use it.</details>

---
[← Chapter 0](00-Introduction.md) · [Contents](../../INTRODUCTION.md) · [Chapter 2 →](02-ComplexAndMatrices.md)
