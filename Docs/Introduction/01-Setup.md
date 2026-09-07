# Chapter 1 — Setup and Orientation

> What you need installed, how the app and the playground relate to each other, and how to read
> the rest of this book — its chapter structure, its app badges, and its "run it yourself" habit.

| | |
|---|---|
| Playground page | — |
| Library APIs | `import SwiftQiskitCore` |
| Prerequisites | none |

## 1.1 What you'll need
Xcode 27, the two sibling checkouts (`SwiftQiskitApp` and `SwiftQiskit` side by side), and the
package-resolution gotcha if they aren't.

## 1.2 A five-minute tour of the app
Palette / grid / results panes, pointing at `Docs/Tutorial.md` rather than repeating it.

## 1.3 A five-minute tour of the playground
`00TOC`, the `NNName` page-numbering convention, where `PlaygroundDocs/` guides live.

## 1.4 How to read this book
Chapter anatomy (summary, at-a-glance table, sections, "Build it in the app", "Run it in code",
exercises), the ● ◐ ○ app badge, and the "every number here is real" verification habit.

## Build it in the app
● Launch the app once, place a single `H` gate, and confirm the State Vector panel updates —
this is the "does everything work" smoke test before Chapter 3 begins for real.

## Run it in code

```swift
import SwiftQiskitCore
// confirms the module imports and a circuit runs
```

## Try it yourself

1. Open both `SwiftQiskitApp.xcodeproj` and `../SwiftQiskit/Playgrounds.playground` and confirm
   both build.
   <details><summary>Answer</summary>If the playground fails with a package-resolution error,
   check that `SwiftQiskit` sits next to `SwiftQiskitApp` on disk.</details>

---
[Contents](../../INTRODUCTION.md) · [Chapter 2 →](02-ComplexAndMatrices.md)
