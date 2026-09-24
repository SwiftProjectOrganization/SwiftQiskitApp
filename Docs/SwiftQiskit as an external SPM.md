# SwiftQiskit as an external SPM dependency

Status: executed. Scope grew beyond the original proposal below — see "What actually shipped"
at the end for the parts that changed during execution, including all three items originally
marked out of scope.

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

Decisions taken at proposal time: remote **version-tagged** dependency (not a branch
dependency, not a single shared workspace); the module name stays `SwiftQiskitCore`, with a
rename to `SwiftQiskit` marked out of scope. **The rename was later brought into scope and
executed** — see "What actually shipped."

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

**Executed via Xcode's UI, not a hand-edit.** A direct edit to `project.pbxproj` was attempted
first and blocked — Xcode holds this file open while the project is open, and editing it
externally risks corrupting Xcode's in-memory state. Instead: remove the package dependency in
Xcode's Package Dependencies pane, then re-add it via **+** with the GitHub URL and version
rule. This took several passes in practice — Xcode's UI does not clean up after itself
reliably:

- The first add attempt set `repositoryURL` to a local filesystem path instead of the GitHub
  URL (apparently auto-filled from a recent local reference), and used
  `upToNextMajorVersion` instead of `upToNextMinorVersion`.
- Removing and re-adding a package dependency leaves the *old* `XCSwiftPackageProductDependency`
  object behind in the target's `packageProductDependencies` list, with no `package =` field
  and no `PBXBuildFile` wiring it into the Frameworks build phase. This happened on every
  remove/re-add cycle. It is inert — confirmed by a successful build each time — but is a
  latent, currently-unremovable piece of cruft in `project.pbxproj`. Xcode's own "Frameworks,
  Libraries, and Embedded Content" list under the target's General tab does *not* show it as a
  duplicate, so there is no UI path found to clean it up; it was left in place.

The version rule (`upToNextMinorVersion` from `0.1.0`, not `upToNextMajorVersion`) matters
because SwiftPM reads `.upToNextMajor(from: "0.1.0")` literally as `0.1.0..<1.0.0` — there is
no special-casing for pre-1.0 versions the way some other package ecosystems do (confirmed via
`DocumentationSearch`). Routine package changes become patch bumps (`0.1.1`, …) and are picked
up automatically; deliberate breaks become `0.2.0` and require an explicit range edit.

Verified with `BuildProject` and `RunAllTests` (scheme `SwiftQiskitApp`, 22 tests, all passing).

**After this step the immediate problem is already gone**: only WalkDemo still holds a local
reference, so both projects can be open at once. Do step 4 in a fresh Xcode window.

### 4. Convert `SwiftQiskitWalkDemo` (new `project.xcproj` text format)

The remote-package syntax for the new format was not covered by Apple's documentation
(`DocumentationSearch` returned only classic-format guidance), and this was the only project on
disk in that format — so there was no local example to mirror. Done through the UI:

1. Opened `SwiftQiskitWalkDemo.xcodeproj`, deleted the `Packages` group's `../SwiftQiskit`
   child, added the remote package via **+** → GitHub URL → **Up to Next Minor Version** from
   `0.1.0` → added the `SwiftQiskit` product to the `SwiftQiskitWalkDemo` target.
2. Read back `project.xcproj` to confirm and record the resulting shape (see "Confirmed
   `project.xcproj` remote-package syntax" below).

**The same orphan pattern from step 3 recurred here**, plus a visible one: the top-level
`"packages"` array and the `package-product-members` entry gained the remote reference
correctly on the first try (URL and version rule were both right immediately — unlike the
pbxproj case), but the old `Packages` group in `"files"` still listed
`{ "path": "../SwiftQiskit" }` as a child, and `package-product-members` kept both the old
entry (no `"package"` key) and the new one. The stale group was visible in the Project
Navigator (unlike the invisible pbxproj orphan) and was removed via "Remove Reference" in
Xcode; the orphaned `package-product-members` entry was left in place, same as step 3 — it has
no `PBXBuildFile`-equivalent wiring and the build succeeds either way.

Verified: `xcodebuild -project SwiftQiskitWalkDemo.xcodeproj -scheme SwiftQiskitWalkDemo build`,
and again against a fresh `git clone` into `/tmp` after publishing (step 4b) — both succeeded.

Also deleted the stray **0-byte file named `SwiftQiskit`** at the WalkDemo repo root — step 5
explains where it came from.

#### Confirmed `project.xcproj` remote-package syntax

```json
"packages": [
  {
    "kind": "remote",
    "repository": "https://github.com/SwiftProjectOrganization/SwiftQiskit.git",
    "version": {
      "up-to-next-minor-version": "0.1.0"
    }
  }
],
```

and the target's product-member entry:

```json
"package-product-members": [
  {
    "package": "SwiftQiskit",
    "product-name": "SwiftQiskit",
    "build-phase": { "build-phase": "frameworks" }
  }
]
```

(`"package"` is the package's `repository`-inferred name, matched by string, not an object ID
the way the classic pbxproj format works.)

### 4b. Publish `SwiftQiskitWalkDemo`

Not in the original proposal — this project had no git remote at all
(`git remote -v` was empty; one local "Initial Commit"). Converting it to a remote package
dependency only fixes the workspace-lock problem for someone who already has both repos
checked out; publishing it is what makes it independently clonable and gives it parity with
every other repo in the org.

- Replaced the empty `.gitignore` with the same one `SwiftQiskitApp` uses.
- `gh repo create SwiftProjectOrganization/SwiftQiskitWalkDemo --public`, matching the org's
  convention (`SwiftQiskit`, `SwiftQiskitApp`, `SwiftStan*` are all public).
- Pushed, then verified with a genuinely fresh `git clone` into `/tmp` + `xcodebuild` — this is
  the real test that the repo is publishable, since a build against an already-resolved local
  checkout doesn't prove anything about a stranger's first clone.

### 5. Fix the project template

**Could not be fixed as originally proposed.** Searched Apple's own bundled Xcode templates
(`/Applications/Xcode.app/.../Templates/`) for any precedent of a *remote* package reference in
a `.xctemplate`'s `TemplateInfo.plist`. Found exactly one Apple template using
`IsPackageReference` (`Packages Foveated Streaming App.xctemplate`), and its `Path` still points
to a package folder bundled *inside* the template — not a URL. `DocumentationSearch` found
nothing either. This old template format appears to have no supported way to declare a remote
package reference at all, or if it does, the syntax isn't discoverable without a live Xcode
build to test against (which a template's static plist provides no way to iterate on safely: a
wrong key name is silently ignored rather than erroring, so a broken template would only be
discovered when someone later generates a project from it and finds no package).

Given that risk, `Templates/SwiftQiskit/Quantum Algorithm App.xctemplate/TemplateInfo.plist` was
changed to **ship with no package reference at all**, rather than guess:

- Removed the `SwiftQiskit` `Definitions` entry entirely (the `IsPackageReference` dict that
  used `Path = ../SwiftQiskit`), and its corresponding `Nodes` array entry. That `Nodes` entry
  was also the root cause of the empty 0-byte `SwiftQiskit` file that appeared in WalkDemo's
  root — Xcode's template engine created a filesystem node for it even though it wasn't a real
  source file — so removing it fixes that too.
- Updated the template's `Description` and the generated project's own `README.md` to add an
  "Add the SwiftQiskit package" section with the exact manual steps (URL, version rule, which
  targets) — the same steps used in step 3/4 above.
- Updated `Templates/README.md` to match.

This means using the template now requires one manual step it didn't before. Revisit if a
future Xcode version documents remote package template keys.

### 6. Documentation

The relative-path dependency is asserted in a fair number of places:

| File | What changes |
|---|---|
| `CLAUDE.md` | "Relationship to the SwiftQiskit package" — drop "the checkout must sit next to this folder or package resolution fails"; state the remote URL and version range; add the tandem-development escape hatch (below) |
| `README.md:16,107` | A sibling checkout is no longer a prerequisite |
| `Docs/Help.md:222` | The troubleshooting entry about a missing sibling checkout is obsolete |
| `Docs/Introduction/01-Setup.md:16-24,116-127` | Substantive: "Two sibling checkouts on disk" is no longer a requirement, and **the exercise at 122-127 turns on renaming the `../SwiftQiskit` folder** — its premise and its answer both need rewriting. The `import SwiftQiskitCore` vs. product-name `SwiftQiskit` distinction at 22-24 was expected to remain — it did not, since the module got renamed too (see "What actually shipped"); that whole paragraph was removed rather than kept |
| `Templates/README.md:9,29` and the template's own `README.md:39` | Remote reference, not relative path |
| `Docs/TemplatesPlan.md:16,78,87,157,163,173-174` | Records "local `../SwiftQiskit` path" as a decision; note that it was superseded rather than rewriting the history |

Prose follows the project's sober style — plain, measured, no hype.

Cross-repo links such as `Docs/Help.md:176-177` and the `Docs/Introduction/*.md` links into
`../../../SwiftQiskit/PlaygroundDocs/` still assume a sibling checkout. They stay valid for
anyone who has one; what changes is that a sibling checkout becomes *optional* — needed to read
the playgrounds, not to build the apps. State that once in `01-Setup.md` rather than editing
roughly twenty link tables.

### 7. Commit `Package.resolved`

Confirmed trackable in both repos: the `.gitignore:31` rule is `.swiftpm/` (leading dot), which
does **not** match `xcshareddata/swiftpm/` (confirmed with `git check-ignore -v`). Both
`Package.resolved` files pin `"version" : "0.1.0"` at revision `d87caa4…` and are committed.
WalkDemo's did not appear until after a build/save cycle in Xcode — its
`xcshareddata/swiftpm/` directory existed but was empty immediately after adding the package.

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

## Verification — what was actually run

1. `swift build && swift test` in `SwiftQiskit` — passed, 57 tests.
2. `git ls-remote --tags origin` — confirmed `0.1.0` on the remote.
3. `BuildProject` + `RunAllTests` on `SwiftQiskitApp` — 22 passing tests (not 20 — that was a
   stale count in `CLAUDE.md`, corrected as part of this change; see "What actually shipped").
4. `xcodebuild … build` on `SwiftQiskitWalkDemo` — passed, both against the working copy and
   against a fresh `/tmp` clone of the newly-published repo.
5. **The acceptance test:** confirmed both `SwiftQiskitApp.xcodeproj` and
   `SwiftQiskitWalkDemo.xcodeproj` build and run from separate Xcode windows without either
   greying out the package or reporting it open elsewhere.
6. Not run — moot, since the template no longer references the package at all (step 5).
7. Not run separately — superseded by the fresh-clone test in step 4, which is strictly
   stronger (it proves the app builds with no local `SwiftQiskit` checkout anywhere on the
   machine's expected path, not just a temporarily-moved one).

## What actually shipped (beyond the original proposal)

The three items this document originally marked out of scope were folded in before execution,
because doing them first turned out to make the core change *cheaper*, not more expensive: the
rename touches fewer files if the duplicate GUI target is deleted first (it imported the old
module name too), and deleting that target removes the `unsafeFlags` blocker that step 1 above
worked around, making step 1 unnecessary. See `git log` on both repos for the actual commits;
in outline:

- **Renamed `SwiftQiskitCore` → `SwiftQiskit`** (module now matches the product name — the
  `import SwiftQiskitCore` vs. product-name-`SwiftQiskit` gotcha this document and `CLAUDE.md`
  used to describe no longer exists). Done *before* tagging `0.1.0`, since the rename is a
  breaking API change and a version-tagged dependency is a poor place to discover that.
- **Deleted the `SwiftQiskitGUI` target** (and its tests, and `SwiftQiskitDocs/GUIHELP.md` /
  `GUITUTORIAL.md`) from the `SwiftQiskit` package instead of keeping it in sync with
  `SwiftQiskitApp`. Diffing all 12 overlapping files first: 8 were byte-identical apart from a
  header comment, and the 4 that had drifted were all strictly behind the app (missing the
  Bloch-sphere `BlochDisplayView`, an older `CircuitModel`, no measurement-model refactor). No
  test coverage was lost — the app's own test suite is a superset. This also removed
  `Package.swift`'s only `.unsafeFlags(["-parse-as-library"])` use, which step 1 above exists to
  work around; with the target gone, step 1's `main.swift` rename became unnecessary.
- **Raised the package's platform floor** to macOS 27 / iOS 27 (was macOS 14 / iOS 17), matching
  both consumer apps. This became optional once the GUI target moved out of the package — the
  package itself no longer needs Liquid Glass APIs — but was done anyway to make the declared
  floor match what every actual consumer requires. Used the string form (`.macOS("27.0")`), not
  `.macOS(.v27)`: that enum case doesn't exist under `swift-tools-version: 5.9`, and bumping the
  tools version to reach it would also change the default Swift concurrency mode — an unrelated
  risk not worth taking in the same change.
- **Published `SwiftQiskitWalkDemo`** to `github.com/SwiftProjectOrganization/SwiftQiskitWalkDemo`
  as a public repo (see step 4b above) — it previously had no remote at all.

`CLAUDE.md` (this repo and the package's) and the roughly thirty other `.md` files listed in
step 6 above were updated for both the SPM change and these four items together, in one pass,
rather than twice.
