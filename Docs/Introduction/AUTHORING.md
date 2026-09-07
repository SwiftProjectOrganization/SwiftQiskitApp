# Writing a chapter of INTRODUCTION.md

Read this once before starting any chapter of [../../INTRODUCTION.md](../../INTRODUCTION.md).
It is the only file you need alongside the chapter's own stub and its source playground page.

## Per-chapter checklist

1. Open the chapter's stub in `Docs/Introduction/`, its **Source** page under
   `../SwiftQiskit/Playgrounds.playground/Pages/`, and the matching
   `../SwiftQiskit/PlaygroundDocs/NN…HELP.md` (and `…PLAN.md`, where one exists — pages 09–22).
2. Draft the sections listed in the stub. Follow the page's own structure section-by-section;
   don't reorganize it unless the stub's section list says otherwise.
3. Write "Build it in the app" — see below for what to do at each app-badge level.
4. Write "Run it in code" — every snippet must actually run; see Verification below.
5. Write 2–4 "Try it yourself" exercises with answers in `<details>` blocks.
6. Cross-check every "In the app" claim against `GateKind` in
   `SwiftQiskitApp/CircuitModel.swift` (`h x y z s sdg t tdg p rx ry rz cx`, 1–8 qubits) — don't
   claim a step is tappable if it isn't.
7. Flip the chapter's **Status** cell in `INTRODUCTION.md` from `stub` to `draft`, then to `done`
   once verified.
8. Note in your summary whether the chapter surfaced anything (a bug, a clearer explanation,
   corrected expected output) that should also change `../SwiftQiskit` — per that repo's own
   `CLAUDE.md` duplication gotcha, this app's source is a near-copy of `SwiftQiskitGUI`, and the
   introduction may find things worth fixing on both sides.

## Style rules

- Narrative prose first, code second — teach *why*, then show the Swift that demonstrates it.
- Unicode math in running text: `|ψ⟩`, `θ`, `⊗`, `√2`, `⟨ψ|X|ψ⟩`, `†`. No LaTeX — it doesn't
  render in a playground comment or a plain-text viewer.
- Inside markdown tables, escape kets as `\|0⟩` so the pipe doesn't break the column, exactly as
  `05GATESHELP.md` does.
- Tables always have leading and trailing pipes.
- 4-space indent in code blocks, matching the rest of the repo.
- State every statistical claim as approximate ("roughly half-and-half", "≈ 0.500") — never
  imply `measure(shots:)` output is exactly reproducible.
- Qubit 0 is the most-significant (leftmost) bit — say so again locally if a chapter's bit
  ordering could be misread (this trips people up most in Chapters 10–14, 17).

## "Build it in the app" by badge

- **● Full** — write real tap-by-tap steps in the voice of `Docs/Tutorial.md`'s Bell-state
  walkthrough (arm a gate, tap a cell, name what changes in the State Vector panel).
- **◐ Partial** — write the steps that *are* tappable, then a short paragraph naming exactly
  which capability is missing (a custom matrix via `apply(_:)`, mid-circuit measurement, a
  density matrix, a decomposition the app doesn't do for you) and how to get it in code instead.
  Prefer showing a decomposition that *is* tappable when one exists — e.g. CZ = `h; cx; h`,
  controlled-phase via `p` + `cx`, ZZ(θ) via `cx; rz; cx` — before conceding defeat.
- **○ Not expressible** — one sentence saying why (the app's palette is fixed single/two-qubit
  gates; this needs `apply(_:)` with a hand-built matrix, or a density-matrix simulator the
  package doesn't have), then move straight to "Run it in code."

## Verification workflow

Every snippet pasted into a chapter must have actually been run — never hand-transcribe expected
values from a HELP doc without re-running them, since the point of this book is that every number
is real.

- Use `RunCodeSnippet` with `SwiftQiskitApp/CircuitModel.swift` as the context file (it already
  `import SwiftQiskitCore`) for anything expressible with the public API.
- For Chapters 21–25, the playground pages define their own local helpers (`expm`, the Kraus
  operators, `partialTraceLast`, `entropy`, the VQE `ansatz`/`energy`/`parameterShiftGradient`,
  Trotter's `zzViaGates`/`trotterUnitary`) — these live in the page body, not in
  `SwiftQiskitCore`. Copy the helpers the chapter needs directly into its "Run it in code" block
  so the snippet is self-contained; don't reference the playground file by path.
- Paste the real output beneath each snippet (or inline as a comment), not a value copied from a
  HELP doc — cross-check against the HELP doc as a sanity check, not as the source of truth.
- If a result is probabilistic, run it, paste what you got, and note that a re-run will differ.

## Chapter template

Copy this verbatim for a new chapter file:

```markdown
# Chapter N — Title

> Two-to-four-sentence summary: what the reader will be able to do after this chapter that they
> couldn't before.

| | |
|---|---|
| Playground page | [`NNPageName`](../../../SwiftQiskit/PlaygroundDocs/NNXXXHELP.md) |
| In the app | ● / ◐ / ○ — one clause saying why |
| Library APIs | the `SwiftQiskitCore` types/methods this chapter uses |
| Prerequisites | Chapters X, Y |

## N.1 Section title
One-line intent note (removed once drafted).

## N.2 Section title

## Build it in the app
Tap-by-tap steps, or the ◐/○ explanation — see AUTHORING.md.

## Run it in code

\`\`\`swift
import SwiftQiskitCore
// ...
\`\`\`

Verified output pasted below each snippet.

## Try it yourself

1. Exercise.
   <details><summary>Answer</summary>Answer text.</details>

---
[← Chapter N-1](NN-Previous.md) · [Contents](../../INTRODUCTION.md) · [Chapter N+1 →](NN-Next.md)
```

## Reading order

Chapters build on each other numerically; write and read them 1 → 26. Chapters 1–3 establish
setup and notation that every later chapter assumes without re-explaining.
