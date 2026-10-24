# SwiftQiskitApp — tutorial & usage guide

A hands-on walkthrough of SwiftQiskitApp: building `QuantumCircuit`s by tapping gates onto a
grid instead of writing Swift. This document is the *how to use it* guide; for the app's
architecture, extension points, and troubleshooting, see the companion
[Help.md](Help.md).

## Launching the app

- **Xcode:** open `SwiftQiskitApp.xcodeproj`, select a run destination (**My Mac**, or an iOS
  device/simulator), then Run (⌘R).
- The app opens with the default 2-qubit circuit (rows `q0`, `q1`), empty.

## The panels (regular layout: macOS, iPad)

| Panel | What it's for |
|---|---|
| **Gates** (left) | Tap a gate button to *arm* it (it highlights). |
| **Circuit** (center) | A grid, one wire per qubit, drawn as a real horizontal line. Tap an empty cell to place the armed gate there. |
| **State Vector and Measurement** (right) | Live amplitudes/probabilities for the circuit as currently built, with a **Measurement** section below it: a **Shots** stepper, a **Measure** button and the resulting histogram. |

A floating bar at the bottom of the window holds the **Qubits** stepper and four buttons:
**Clear**, **Results**, **Measure** and **Display**. **Display** opens a sheet with a
Bloch-sphere view of the circuit — see "Viewing Bloch spheres" below.

When the window is narrower than 672 pt (an iPad in Split View; a Mac window can't get that
narrow), the right-hand pane is hidden and **Results** opens the state vector in a sheet.
**Measure** always takes a measurement and then opens the Measurement sheet, at any width.

On iPhone (compact layout) the same controls are rearranged: the circuit grid fills the
screen with the gate strip pinned below it; the **Qubits** stepper is in the top-left toolbar,
and **Clear**, **Results**, **Measure** and **Display** are grouped at the top right. Results,
Measurement and Display each open in a sheet.

Full control-by-control reference is in [Help.md](Help.md).

## Walkthrough: build and measure a Bell state

This builds the classic `h(0); cx(0, 1)` circuit by tapping instead of writing code.

1. **Launch the app.** It opens with the default 2-qubit circuit (rows `q0`, `q1`), empty.

2. **Place the Hadamard.** In the palette's "Pauli / Hadamard" section, tap **H** — it
   highlights (armed). Tap the first empty cell in the `q0` row. An `H` tile appears there.

   The State Vector panel updates immediately: two states are listed, `|00⟩` and `|10⟩`,
   each with probability ≈ 0.500 (amplitude ≈ 0.707). `q0` is the leftmost bit, so it's the
   *first* character of the label that's split, not the second.

3. **Place the CX.** Tap **CX** in the "Multi-qubit" section to arm it. Tap the `q0` cell in
   the *next* empty column — an orange ring appears there, marking it as the pending control.
   Tap the `q1` cell in that *same* column. The `q0` cell now shows a filled dot (control) and
   the `q1` cell shows a circle-plus (⊕, target), joined by a vertical line connecting the two.

   The State Vector panel now shows only two states: `|00⟩` and `|11⟩`, each with
   probability ≈ 0.500 — the Bell state.

4. **Measure it.** Set the **Shots** stepper in the Measurement section to whatever you like
   (default 1000) and tap **Measure**. A bar chart appears, with counts split roughly evenly
   between `00` and `11` and (statistically) nothing elsewhere. If the right-hand pane is
   hidden, tap **Measure** in the bottom bar instead; the histogram opens in a sheet, where
   the Shots stepper is also available.

Re-tapping **Measure** re-samples — expect the split to jitter around 50/50, not land on it
exactly; `measure(shots:)` is probabilistic.

## Viewing Bloch spheres

Tap **Display** to open a Bloch-sphere view of the circuit, with four modes:

- **Final** shows one sphere per qubit, for the circuit's current final state.
- **Steps** shows a single chosen qubit's sphere after each column, so you can watch it move
  gate by gate. Pick the qubit with the segmented control above the row (hidden if there's
  only one qubit).
- **Tensor** shows the circuit as a tensor-network diagram instead of a sphere: one node per
  `|0⟩` input, one per gate, one per open output leg, wired together by the qubit each edge
  carries — the same circuit, read as a graph rather than a trajectory on a sphere (see Chapter
  26 of `INTRODUCTION.md`).
- **3D** shows a single chosen qubit's final-state sphere as a rotatable 3D wireframe — drag
  the sphere to orbit the camera around it. Useful for reading an angle that the fixed 2D
  projection foreshortens (see Chapter 6 of `INTRODUCTION.md`).

Try it on the Bell-state circuit above: in **Final**, both `q0` and `q1` show their arrow
collapsed to the sphere's center (`|r| ≈ 0` in the readout below each sphere) — that's the
visual signature of entanglement. A reduced qubit inside an entangled pair has no single
point on the sphere's surface to call its own. Switch to **Steps** and pick `q0`: you'll see
it start at `|0⟩` (pole), swing out to the `+x` equator after the `H`, then collapse to the
center after the `CX`.

## Other things to try

- **A parameterized gate.** Arm **RX** (under "Rotation (θ = π/2)"; new rotation tiles start at θ = π/2) and place it on a qubit. Tap the
  placed tile again to open a popover with a θ slider (0 to 2π); dragging it updates the
  State Vector panel live.
- **Deleting a gate.** Open the context menu on a placed single-qubit tile (long-press on
  iOS, right-click/⌃-click on macOS) and choose **Delete**. For a CX gate, open the context
  menu on either the control dot or the target ⊕; **Delete** removes the whole gate. Tapping
  a CX opens its controls popover instead (see "A Toffoli gate" below).
- **A SWAP.** Arm **SWAP** (under "Multi-qubit") and tap two different qubits in the same
  column. Both ends are drawn as ×, joined by a vertical line. The two qubits play the same
  role, so the tap order does not matter. Delete works from either end.
- **Growing the circuit.** Use the **Qubits** stepper (1–8) in the bottom bar to add rows. Shrinking it drops
  any placed gates that no longer fit — there's no undo, so note the recipe before shrinking
  if you want to keep it.
- **Clear.** The **Clear** button removes every placed gate but keeps the current qubit count.
- **A 3-qubit GHZ state.** Bump **Qubits** to 3, place `H` on `q0`, then `CX(q0, q1)` and
  `CX(q0, q2)` in the next two columns — the State Vector panel should settle on `|000⟩` and
  `|111⟩` only, each ≈ 0.500.

## A Toffoli gate: adding controls to a CX

A CX can have more than one control. With two controls it is the Toffoli (CCX) gate, which
flips the target only when both controls are `1`. This builds it on three qubits.

1. Set **Qubits** to 3. Arm **X** and place it on `q0` and on `q1` in the first column, so
   both controls start as `1`.
2. Arm **CX**. In the next column tap `q0` (the control), then `q2` (the target). The State
   Vector panel shows only `|111⟩`: the control `q0` is `1`, so `q2` has flipped, and `q1`
   is still `1` from the X gate.
3. Tap the control dot on `q0` (or the target ⊕). A popover opens with a **Controls: 1**
   stepper. Press **+**. The popover closes and the free cells in that column show a dashed
   ring.
4. Tap the `q1` cell in that column. It becomes a second control dot, and the vertical line
   now spans all three qubits. The State Vector panel still shows `|111⟩`, because both
   controls are `1` and the target flips.
5. To see the second control matter, delete the X on `q1` (context menu, **Delete**). With
   `q1` at `0` that control is not satisfied, the target does not flip, and the panel shows
   `|100⟩`.

Press **−** in the popover to remove the most recently added control; the gate then goes back
to a plain CX. A gate can have up to *qubits − 1* controls. The same popover works on **CY** (controlled-Y, whose
target is drawn as a boxed `Y`) and **CZ**; with extra controls they replay as multi-controlled Y and Z. Controls may sit on any free qubit
in the column, not only on adjacent ones. If you shrink **Qubits** so that any of the gate's
qubits no longer exists, the whole gate is dropped.

## Learn more about the underlying quantum mechanics

This app only exercises part of the package's circuit API
(`h/x/y/z/s/sdg/t/tdg/p/rx/ry/rz/cx/cy/cz/swap/rzz/rxx/ryy`, plus `mcx/mcy/mcz` for extra
controls). For
a deeper look at what these gates actually do:

- [07Gates](../../SwiftQiskitPlaygrounds/SwiftQiskitPlaygrounds.playground/Pages/07Gates.xcplaygroundpage)
  — a gentle, gate-by-gate tour (playground page in SwiftQiskitPlaygrounds).
- [12Entanglement](../../SwiftQiskitPlaygrounds/SwiftQiskitPlaygrounds.playground/Pages/12Entanglement.xcplaygroundpage)
  — the Bell state and GHZ state walkthroughs this tutorial mirrors.
