# SwiftQiskitCore as an external SPM dependency

Status: proposed, not yet executed.

## Context

`SwiftQiskitApp` and `SwiftQiskitWalkDemo` both consume `../SwiftQiskit` as a **local,
relative-path** package reference:

- `SwiftQiskitApp.xcodeproj/project.pbxproj:638-643` — `XCLocalSwiftPackageReference`,
  `relativePath = ../SwiftQiskit`
- `SwiftQiskitWalkDemo.xcodeproj/project.xcproj:28-33` — new text project format, a `Packages`
  group whose only child is `{ "path": "../SwiftQiskit" }`

Xcode allows a given local package folder to be open in only one workspace at a time, so
opening the second project greys out the package or reports it as already open elsewhere. The
two apps cannot be worked on simultaneously.

The package is **already a proper SPM package** — `SwiftQiskit/Package.swift` vends a
`SwiftQiskit` library product backed by the `SwiftQiskitCore` target — and it is **already
public** at `github.com/SwiftProjectOrganization/SwiftQiskit` (verified via `gh`, default
branch `main`, local `main` in sync with `origin/main`). What is missing is a **version tag**.
Without one, nothing can depend on it remotely.

Outcome: tag `0.1.0`, switch both apps to a remote version-pinned dependency. Each project
then resolves its own copy into DerivedData and the two become fully independent.

Decisions already taken: remote **version-tagged** dependency (not a branch dependency, not a
single shared workspace); the module name stays **`SwiftQiskitCore`** — renaming it to
`SwiftQiskit` so that `import SwiftQiskit` works would touch 132 files across the three repos
and is deliberately out of scope.

## Blocker to clear first: `unsafeFlags`

SwiftPM **refuses a version-pinned remote dependency on a package that uses `unsafeFlags`**.
`Package.swift:60-63` puts `.unsafeFlags(["-parse-as-library"])` on the `SwiftQiskitGUI`
executable target, and it is load-bearing: `Sources/SwiftQiskitGUI/main.swift:4` declares
`@main`, which is illegal in a file literally named `main.swift` unless the file is parsed as a
library.

The restriction is scoped to targets reachable from the *consumed* product, and the apps
consume `SwiftQiskit` → `SwiftQiskitCore` (no unsafe flags), so it should not bite. Rather than
rely on that, remove the flag outright — SwiftPM applies `-parse-as-library` automatically to an
executable target that has no `main.swift`.

## Steps

Work in `../SwiftQiskit` first, then the two consumers, then the template and docs.

### 1. Remove `unsafeFlags` from the package (repo: `SwiftQiskit`)

- Rename `Sources/SwiftQiskitGUI/main.swift` → `Sources/SwiftQiskitGUI/SwiftQiskitGUIApp.swift`
  (`git mv`; the struct is already named `SwiftQiskitGUIApp`). Contents unchanged.
- In `Package.swift`, drop the `swiftSettings:` block from the `SwiftQiskitGUI` target.
- Verify: `swift build`, `swift build --product SwiftQiskitGUI`, and `swift test` from the
  package root.

### 2. Tag and push `0.1.0` (repo: `SwiftQiskit`)

- Commit step 1, `git tag 0.1.0`, `git push origin main --tags`.
- Confirm with `git ls-remote --tags origin`.

### 3. Convert `SwiftQiskitApp` (classic `project.pbxproj`)

Hand-edit `SwiftQiskitApp.xcodeproj/project.pbxproj` — this format is stable and the change is
two hunks. Keep the existing object IDs so the `packageReferences` entry at line 291 and the
target's package-product dependency stay wired up.

- Replace the `XCLocalSwiftPackageReference` section (lines 638-643) with an
  `XCRemoteSwiftPackageReference` carrying
  `repositoryURL = "https://github.com/SwiftProjectOrganization/SwiftQiskit.git"` and
  `requirement = { kind = upToNextMinorVersion; minimumVersion = 0.1.0; }`.
- Add `package = <that same ID>;` to the `XCSwiftPackageProductDependency` at lines 646-649.
  A local-package product dependency omits that key; a remote one requires it.
- Update the three `/* … */` comments that name the old reference.

`upToNextMinor` rather than `upToNextMajor`, because SwiftPM reads `.upToNextMajor(from:
"0.1.0")` as `0.1.0..<1.0.0` — far too wide for a pre-1.0, actively changing API. Routine
package changes become patch bumps (`0.1.1`, …) and are picked up automatically; deliberate
breaks become `0.2.0` and require an explicit range edit. Widening later is a one-field change.

Verify with `BuildProject` and `RunAllTests` (scheme `SwiftQiskitApp`, 20 tests). The app target
imports only `SwiftQiskitCore`, never `SwiftQiskitGUI`, so no app source changes.

**After this step the immediate problem is already gone**: only WalkDemo still holds a local
reference, so both projects can be open at once. Do step 4 in a fresh Xcode window.

### 4. Convert `SwiftQiskitWalkDemo` (new `project.xcproj` text format)

The remote-package syntax for the new format is not covered by Apple's documentation
(`DocumentationSearch` returns only classic-format guidance), and this is the only project on
disk in that format — so there is no local example to mirror. Do it through the UI, which is
guaranteed to emit correct syntax:

1. Open `SwiftQiskitWalkDemo.xcodeproj`, delete the `Packages` group's `../SwiftQiskit` child.
2. File ▸ Add Package Dependencies…, enter the GitHub URL, choose **Up to Next Minor** from
   `0.1.0`, add the `SwiftQiskit` product to the `SwiftQiskitWalkDemo` target.
3. Read back `project.xcproj` and record the resulting JSON shape in this document, so future
   automated edits to the format have a reference.

Verify: `xcodebuild -project SwiftQiskitWalkDemo.xcodeproj -scheme SwiftQiskitWalkDemo build`.

Also delete the stray **0-byte file named `SwiftQiskit`** at the WalkDemo repo root — step 5
explains where it came from.

### 5. Fix the project template

`Templates/SwiftQiskit/Quantum Algorithm App.xctemplate/TemplateInfo.plist`:

- Line 149: replace `<key>Path</key><string>../SwiftQiskit</string>` with the remote-package
  keys Xcode's own templates use (repository URL plus a version requirement), keeping
  `IsPackageReference`, `LinkPackageProducts`, and `TargetIdentifiers` as they are.
- The `Nodes` array also lists a bare `SwiftQiskit` entry alongside the package *Definition*.
  That is what generated the empty `SwiftQiskit` file in WalkDemo's root — remove it.
- Re-verify by generating a project from the template (`Templates/install.sh` installs it) and
  confirming the new project resolves the package from GitHub with no stray file.

### 6. Documentation

The relative-path dependency is asserted in a fair number of places:

| File | What changes |
|---|---|
| `CLAUDE.md` | "Relationship to the SwiftQiskit package" — drop "the checkout must sit next to this folder or package resolution fails"; state the remote URL and version range; add the tandem-development escape hatch (below) |
| `README.md:16,107` | A sibling checkout is no longer a prerequisite |
| `Docs/Help.md:222` | The troubleshooting entry about a missing sibling checkout is obsolete |
| `Docs/Introduction/01-Setup.md:16-24,116-127` | Substantive: "Two sibling checkouts on disk" is no longer a requirement, and **the exercise at 122-127 turns on renaming the `../SwiftQiskit` folder** — its premise and its answer both need rewriting. Keep the `import SwiftQiskitCore` vs. product-name `SwiftQiskit` distinction at 22-24; that is unchanged and still the common trip-up |
| `Templates/README.md:9,29` and the template's own `README.md:39` | Remote reference, not relative path |
| `Docs/TemplatesPlan.md:16,78,87,157,163,173-174` | Records "local `../SwiftQiskit` path" as a decision; note that it was superseded rather than rewriting the history |

Prose follows the project's sober style — plain, measured, no hype.

Cross-repo links such as `Docs/Help.md:176-177` and the `Docs/Introduction/*.md` links into
`../../../SwiftQiskit/PlaygroundDocs/` still assume a sibling checkout. They stay valid for
anyone who has one; what changes is that a sibling checkout becomes *optional* — needed to read
the playgrounds, not to build the apps. State that once in `01-Setup.md` rather than editing
roughly twenty link tables.

### 7. Commit `Package.resolved`

Xcode will create
`SwiftQiskitApp.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved`. The app's
`.gitignore:31` rule is `.swiftpm/` (leading dot), which does **not** match
`xcshareddata/swiftpm/`, so the file is trackable as-is — commit it in both repos. WalkDemo has
an empty `.gitignore`; no change needed there.

## Ongoing workflow

The cost of this change is that package edits no longer reach the apps instantly. Two modes:

- **Normal:** edit the package, commit, tag a patch bump, push, then File ▸ Packages ▸ Update to
  Latest Package Versions in the app.
- **Tandem editing:** drag the local `../SwiftQiskit` checkout into the app's workspace. A local
  package overrides a remote dependency of the same name (Apple: *Editing a package dependency
  as a local package*), restoring instant edits. Remove it when done. The tradeoff is worth
  stating plainly: while an override is active, that one project holds the local package and the
  original conflict returns for the other — acceptable, because it is now opt-in and temporary
  rather than permanent.

This workflow note belongs in `CLAUDE.md` once the change lands.

## Verification

1. `swift build && swift test` in `SwiftQiskit` after step 1.
2. `git ls-remote --tags origin` shows `0.1.0`.
3. `BuildProject` + `RunAllTests` on `SwiftQiskitApp` (expect 20 passing tests).
4. `xcodebuild … build` on `SwiftQiskitWalkDemo`.
5. **The acceptance test:** open both `SwiftQiskitApp.xcodeproj` and
   `SwiftQiskitWalkDemo.xcodeproj` in Xcode at the same time, build and run both, and confirm
   neither greys out the package or reports it as open elsewhere.
6. Generate a project from the template; confirm it resolves from GitHub with no stray file.
7. Temporarily `mv ../SwiftQiskit /tmp/`, build `SwiftQiskitApp`, confirm it still builds from
   the resolved remote copy, then move it back.

## Out of scope

- Renaming `SwiftQiskitCore` → `SwiftQiskit`.
- The `SwiftQiskitGUI` / `SwiftQiskitApp` source duplication noted in `CLAUDE.md`.
- Giving `SwiftQiskitWalkDemo` a git remote (it has one local "Initial Commit" and no origin).
