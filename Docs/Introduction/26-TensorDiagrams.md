# Chapter 26 — Tensor Diagrams

> A second way to read a circuit: not as one big 2ⁿ×2ⁿ matrix replayed step by step, but as a
> graph of small local tensors wired together. `TensorNetwork` builds that graph from any
> `QuantumCircuit`, `contract()` evaluates it from nothing but those small pieces, and agreeing
> with `run()`'s full-matrix answer is an honest cross-check between two independent routes to
> the same state.

| | |
|---|---|
| Playground page | [`23TensorNetwork`](../../../SwiftQiskit/PlaygroundDocs/23TENSORNETWORKHELP.md) |
| In the app | ● — every example below uses palette gates (`h`, `cx`, `p`, `rzz`), and Display → Tensor draws the diagram live |
| Library APIs | `TensorNetwork(_:)`, `.nodes`/`.edges`/`.columns`, `TensorNetwork.Node.kind/qubits/column/tensor`, `TensorNetwork.Kind.input/gate(_:)/output`, `.contract()`, `QuantumCircuit.run()`, `TensorNetworkView(_:title:)` |
| Prerequisites | Chapters 11, 12, 16, 24 |

## 26.1 A circuit as a diagram

Every chapter so far that touched multiple qubits has read a circuit the same way:
`QuantumCircuit.run()` builds each gate's full embedded matrix — `H ⊗ I₂` for `h(0)` on two
qubits, the whole 4×4 or 8×8 or 2ⁿ×2ⁿ thing — and multiplies the state vector through them one
gate at a time. Chapter 11 showed exactly how that embedding works and why its cost grows as
`2ⁿ`. A **tensor network** is a different, and for large circuits far cheaper, way to describe
the same computation: instead of embedding each gate into the full register before multiplying,
keep every gate as its own small *local* tensor and record only the wiring that says which
qubits it touches.

Three pieces make up the diagram:

- A qubit **wire** is a bond-dimension-2 edge — it carries one qubit's two basis values from one
  node to the next.
- A k-qubit gate is a rank-2k tensor **node**: k incoming legs, k outgoing legs, and a small
  2^k×2^k tensor — `H`'s is 2×2, `CX`'s is 4×4 — never the full 2ⁿ×2ⁿ matrix `run()` would embed
  it into.
- Every qubit's starting `|0⟩` is a small **cap** on the far left of its wire, with nothing
  feeding into it; the final, unconsumed leg on the right of each wire is an open **output**.

`TensorNetwork(_:)` builds exactly this graph from a `QuantumCircuit`'s recorded operations:
one `.input` node per qubit at column 0, one `.gate` node per operation (named after the gate —
`"H"`, `"CX"`, `"RZ(0.700)"`, …), and one `.output` node per qubit at the end. Nodes are laid out
ASAP: a gate's `column` is one more than the latest column already reached on any qubit it
touches, so two gates on disjoint qubits can land in the same column even though they were
recorded one after another.

## 26.2 Local tensors vs. embedded matrices

The difference from Chapter 11's `⊗` is worth being precise about, because both routes compute
the same thing. `h(0)` on a 2-qubit circuit multiplies the state vector by the 4×4 matrix
`H ⊗ I₂`. A tensor-network node for that same `h(0)` carries only `H` itself — a 2×2 matrix —
plus the label "this tensor's one leg is qubit 0." `contract()` (§26.7) applies that 2×2 tensor
directly to the two amplitudes that differ only in qubit 0's value, for every setting of the
other qubits, and never builds the 4×4 (or, on a bigger register, 2ⁿ×2ⁿ) embedded matrix at all.
For one gate on a small circuit this is a wash; it is also exactly the idea that lets real
tensor-network simulators scale past where embedding every gate into the full state space would
run out of memory.

## 26.3 A Bell pair

The simplest network is `h(0); cx(0,1)`:

```swift
let bell = QuantumCircuit(qubits: 2)
bell.h(0)
bell.cx(0, 1)
let bellNetwork = TensorNetwork(bell)
print(bellNetwork.nodes.count, bellNetwork.edges.count)
```

```text
6 5
```

Counting by hand confirms it: 2 `.input` nodes, 1 `.gate("H")` node, 1 `.gate("CX")` node, 2
`.output` nodes — 6 nodes. Edges are wire *segments*, not qubits: q0 runs input → H → CX →
output (2 segments), q1 runs input → CX → output (1 segment, since `h(0)` never touches q1) —
2 + 1 + 1 + 1 = 5 edges in total.

## 26.4 A non-adjacent CX (GHZ)

Chapter 12 built the 3-qubit GHZ state with `h(0); cx(0,1); cx(0,2)` — the second `cx`'s legs
are q0 and q2, skipping q1 entirely even though q1 sits between them on the page:

```swift
let ghz = QuantumCircuit(qubits: 3)
ghz.h(0)
ghz.cx(0, 1)
ghz.cx(0, 2)
let ghzNetwork = TensorNetwork(ghz)
print(ghzNetwork.nodes.count, ghzNetwork.edges.count, ghzNetwork.columns)
if let secondCX = ghzNetwork.nodes.first(where: { node in
    if case .gate("CX") = node.kind { return node.qubits == [0, 2] }
    return false
}) {
    print(secondCX.qubits, secondCX.column)
}
```

```text
9 8 5
[0, 2] 3
```

In the live view (and in `TensorNetworkView` generally), a multi-qubit gate's box spans every
row between the lowest and highest qubit it touches — here, rows q0 through q2 — with q1's wire
drawn crossing that box *dashed*, to show it passes through without being one of the gate's two
legs. That is the diagram's way of drawing exactly what Chapter 12's matrix-level description
already said: this `cx` is a 4×4 tensor on q0 and q2 alone, embedded as `CX ⊗ I₂` with q1's
identity factor invisible in the embedding and now, here, invisible as a *leg* too.

## 26.5 `rzz` unfolds into `cx; rz; cx`

Chapter 24 introduced the exact identity `ZZ(θ) = cx; rz(θ); cx` for Hamiltonian terms that
commute. `QuantumCircuit.rzz(_:_:_:)` is built from exactly that identity (via the general
`pauliRotation` machinery), so its tensor network isn't one node — it's three:

```swift
let zz = QuantumCircuit(qubits: 2)
zz.rzz(0.7, 0, 1)
let zzNetwork = TensorNetwork(zz)
let zzGateNames = zzNetwork.nodes.compactMap { node -> String? in
    guard case .gate(let name) = node.kind else { return nil }
    return name
}
print(zzNetwork.nodes.count, zzNetwork.edges.count)
print(zzGateNames)
```

```text
7 7
["CX", "RZ(0.700)", "CX"]
```

Three gate nodes (plus 2 inputs and 2 outputs = 7 total), each named after the actual
low-level gate it unfolds into — the diagram doesn't know or care that the circuit builder calls
it `rzz`; it only ever sees the three primitive operations the circuit actually recorded. `RXX`
and `RYY` unfold the same way but with a basis change bolted on either side — `RXX(θ)` as
`H,H; CX; RZ; CX; H,H` (7 nodes), `RYY(θ)` with an `S†,H` / `H,S` change of basis on both qubits
around the same `CX; RZ; CX` core (11 nodes) — since `X` and `Y` each need rotating into the `Z`
basis before the identity from Chapter 24 applies, and back out afterward.

## 26.6 A 2-qubit QFT ladder

Chapter 16 built the controlled-phase gate `CP(θ)` entirely from `p` and `cx`:
`p(θ/2,c); cx(c,t); p(−θ/2,t); cx(c,t); p(θ/2,t)` — five primitive gates for one `CP`. A 2-qubit
QFT (no final swap needed on two qubits) is `h(0); CP(π/2,0,1); h(1)`:

```swift
func cp(_ theta: Double, control: Int, target: Int, on circuit: QuantumCircuit) {
    circuit.p(theta / 2, control)
    circuit.cx(control, target)
    circuit.p(-theta / 2, target)
    circuit.cx(control, target)
    circuit.p(theta / 2, target)
}

let qft = QuantumCircuit(qubits: 2)
qft.h(0)
cp(.pi / 2, control: 0, target: 1, on: qft)
qft.h(1)
let qftNetwork = TensorNetwork(qft)
print(qftNetwork.nodes.count, qftNetwork.edges.count, qftNetwork.columns)
```

```text
11 11 9
```

2 inputs + 2 `h` + 5 `CP`-derived gates + 2 outputs = 11 nodes, end to end — the diagram makes
the "five gates per controlled-phase" cost from Chapter 16 visible as five separate boxes
in a row, rather than a single opaque `CP` label.

## 26.7 Contraction

`contract()` turns the diagram back into a `StateVector`: starting from `|0…0⟩`, it walks the
`.gate` nodes in the order the circuit recorded them and applies **only** each node's own small
tensor to the legs it names, gathering the amplitudes that match every value of the target
qubits, multiplying by the local tensor, and scattering the result back — the same gather/apply/
scatter idea `QuantumCircuit`'s single-qubit embedding uses, generalized to an arbitrary target
set, and never once building a full 2ⁿ×2ⁿ matrix. Every example above printed
`contract()` against `circuit.run()`'s max amplitude error, and every one came back `0.00e+00`
(machine precision) — agreement between a method that only ever sees small local pieces and one
that only ever sees full embedded matrices, which is a genuinely independent check of both, not
the same arithmetic read twice.

This also hints at why tensor networks are a serious simulation technique and not just an
alternative picture: a circuit whose tensor network stays narrow — few qubits touched by any one
"cut" through the diagram — can sometimes be contracted far more cheaply than 2ⁿ, because the
intermediate gathers above never need to hold a full state vector either. That said, `contract()`
here still allocates a full `StateVector` internally, and for a general circuit the cost of
contracting optimally is itself a hard combinatorial problem — this chapter only shows the
diagram and the identity check, not a faster simulator.

## Build it in the app

Build each example on the grid, then tap **Display** → **Tensor** to see its diagram.

1. **Bell pair.** On a 2-qubit circuit: arm `H`, tap column 0/q0; arm `CX`, tap q0 then q1 in
   column 1. Open Display → Tensor: two wires, an `H` box on q0's wire, a `CX` box spanning both
   wires, `|0⟩` caps on the left, open `q0`/`q1` legs on the right.
2. **Non-adjacent CX (GHZ).** Set qubit count to 3. Arm `H`, tap column 0/q0; arm `CX` twice —
   q0→q1 in column 1, then q0→q2 in column 2. In Tensor mode, the second `CX`'s box spans all
   three wires, with q1's wire crossing it as a dashed line — the diagram's picture of the
   `A ⊗ I₂ ⊗ B`-style skip Chapter 12 described in matrix form.
3. **RZZ.** On a 2-qubit circuit, arm `RZZ`, tap q0 then q1, and set θ with the popover. Tensor
   mode doesn't show one `RZZ` box — it shows the three gates the tile actually compiles down
   to: `CX`, `RZ(θ)`, `CX`, each in its own column, matching §26.5 exactly.
4. **QFT ladder.** On a 2-qubit circuit, build `CP(π/2)` from the Chapter 16 decomposition using
   `P` and `CX` tiles (five tiles: P, CX, P, CX, P), with an `H` tile before and after on q0/q1
   respectively. Tensor mode shows all seven gate boxes end to end.

## Try it yourself

1. Before running it, predict the node and edge count for `h(0); h(1); cx(0,1)` on a 2-qubit
   circuit (note the extra `h(1)`, not in §26.3's example).
   <details><summary>Answer</summary>7 nodes (2 inputs + 2 `H` + 1 `CX` + 2 outputs), 6 edges
   (q0: input→H→CX→output = 3 segments; q1: input→H→CX→output = 3 segments). Running
   `TensorNetwork(_:)` on that circuit confirms `7 6`.</details>

2. §26.1 said gates on disjoint qubits can share a column. For `h(0); h(1)` on a 2-qubit
   circuit, what `column` does each `H` node get, and why?
   <details><summary>Answer</summary>Both get column 1. ASAP scheduling sets a node's column to
   one more than the latest column already reached on *any* qubit it touches; q0 and q1 each
   start at their own `.input` node (column 0), so the `H` on q0 and the `H` on q1 are each one
   past their own single predecessor — column 1 for both, even though the circuit recorded them
   one after the other.</details>

3. §26.5 gave `RXX(θ)`'s unfolding as `H,H; CX; RZ; CX; H,H` (7 gate nodes) and `RYY(θ)`'s as an
   `S†,H` / `H,S` basis change around the same core (11 gate nodes). Why does `RXX` need fewer
   basis-change gates than `RYY`?
   <details><summary>Answer</summary>Rotating the `Z`-basis identity from Chapter 24 into the
   `X` basis takes one gate per qubit going in (`H`) and, since `H` is self-inverse, the same
   `H` again per qubit coming out — 1 + 1 = 2 extra gates per qubit, 4 extra gates total across
   both qubits. Rotating into the `Y` basis takes two gates per qubit going in (`S†` then `H`,
   since no single self-inverse gate maps the `Z` basis to the `Y` basis) and two coming out
   (`H` then `S`) — 2 + 2 = 4 extra gates per qubit, 8 extra gates total. 3 (the shared
   `CX; RZ; CX` core) + 4 = 7 for `RXX`, and 3 + 8 = 11 for `RYY` — exactly the node counts
   above.</details>

---
[← Chapter 25](25-QuantumWalks.md) · [Contents](../../INTRODUCTION.md) · [Chapter 27 →](27-Epilogue.md)
