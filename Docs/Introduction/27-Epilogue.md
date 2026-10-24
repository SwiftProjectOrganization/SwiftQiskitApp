# Chapter 27 — Epilogue: Where to Go Next

> A short close: what this book covered, what it deliberately left out, and where to go for
> more — inside the SwiftQiskit, SwiftQiskitApp and SwiftQiskitPlaygrounds repos and beyond them.

| | |
|---|---|
| Playground page | — |
| Library APIs | — |
| Prerequisites | Chapters 1–26 |

## 27.1 What this book covered
A one-paragraph recap tying Parts I–III together, including Chapter 26's tensor-diagram view
of a circuit.

## 27.2 What it left out, on purpose
Controlled rotations and open (fire-on-`0`) controls in the palette, performance at scale, and
real hardware noise models beyond Chapter 21's toy channels. See the package's own
`STATUSandTODO.md`.

## 27.3 Where to go inside these repos
`../../../SwiftQiskit/Tests/` for the algebraic ground truth every chapter's claims were checked
against; `Docs/Todo.md` (this app) and `STATUSandTODO.md` (the package) for open roadmap items,
including several — controlled rotations, a density-matrix view in the app — that would upgrade this book's ◐/○ badges to
● if implemented.

## 27.4 Where to go beyond them
Pointers to further reading on the topics Chapters 17, 21, and 23 only introduced (Shor's
algorithm's number-theoretic side, open quantum systems, variational quantum eigensolvers on
real hardware).

## Build it in the app
— No new material; revisit any earlier chapter's app badge and try upgrading a ◐ to a ● using a
decomposition from that chapter's "Build it in the app" section.

## Run it in code

```swift
import SwiftQiskit
// no new code — this chapter is a map back to what came before
```

## Try it yourself

1. Pick one ◐ or ○ chapter and sketch what would need to change in `SwiftQiskit` or the app
   to make it ●.
   <details><summary>Answer</summary>Common answers: a mid-circuit-measurement API (Chapters
   18, 19), a density-matrix view in the app (Chapter 21; the package already has `DensityMatrix`), or a matrix-entry UI in the app (Chapters 2, 17,
   25).</details>

2. `INTRODUCTION.md` lists three ways to run the book's examples (the app, the playgrounds, plain code). Pick one chapter and name which of the
   three you would use to check its numbers, and why.
   <details><summary>Answer</summary>Any answer that matches the badge works: a ● chapter's
   steps can be checked in the app, while a ◐ or ○ chapter's code-only parts need the
   playground page or a plain Swift file with `import SwiftQiskit`.</details>

3. Which chapters would change if the app gained mid-circuit measurement?
   <details><summary>Answer</summary>Chapters 18 (teleportation) and 19 (error correction),
   whose corrections are applied coherently to every branch instead of conditioned on a
   measured result.</details>

---
[← Chapter 26](26-TensorDiagrams.md) · [Contents](../../INTRODUCTION.md)
