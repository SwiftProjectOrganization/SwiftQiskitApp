# Chapter 26 — Epilogue: Where to Go Next

> A short close: what this book covered, what it deliberately left out, and where to go for
> more — inside these two repos and beyond them.

| | |
|---|---|
| Playground page | — |
| Library APIs | — |
| Prerequisites | Chapters 1–25 |

## 26.1 What this book covered
A one-paragraph recap tying Parts I–III together.

## 26.2 What it left out, on purpose
Multi-qubit gate decompositions beyond CX (Toffoli, SWAP, CZ as first-class gates — see the
package's own `STATUSandTODO.md`), performance at scale, and real hardware noise models beyond
Chapter 21's toy channels.

## 26.3 Where to go inside these repos
`../SwiftQiskit/Tests/` for the algebraic ground truth every chapter's claims were checked
against; `Docs/Todo.md` (this app) and `STATUSandTODO.md` (the package) for open roadmap items,
including several — a 3D Bloch view, more gates — that would upgrade this book's ◐/○ badges to
● if implemented.

## 26.4 Where to go beyond them
Pointers to further reading on the topics Chapters 17, 21, and 23 only introduced (Shor's
algorithm's number-theoretic side, open quantum systems, variational quantum eigensolvers on
real hardware).

## Build it in the app
— No new material; revisit any earlier chapter's app badge and try upgrading a ◐ to a ● using a
decomposition from that chapter's "Build it in the app" section.

## Run it in code

```swift
import SwiftQiskitCore
// no new code — this chapter is a map back to what came before
```

## Try it yourself

1. Pick one ◐ or ○ chapter and sketch what would need to change in `SwiftQiskitCore` or the app
   to make it ●.
   <details><summary>Answer</summary>Common answers: a mid-circuit-measurement API (Chapters
   18, 19), a density-matrix type (Chapter 21), or a matrix-entry UI in the app (Chapters 2, 17,
   25).</details>

---
[← Chapter 25](25-QuantumWalks.md) · [Contents](../../INTRODUCTION.md)
