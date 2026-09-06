# PetPlanify

Native, Spanish-language SwiftUI app for a pet's food plan, health history and
training. Supports **iPhone (iOS 27)** and **native Mac (macOS 27)** with Xcode 27.
No iPad-specific experience, Catalyst, backend, account, analytics or advertising.

The five areas are **Inicio, Alimentación, Salud, Entrenamiento and Ajustes**.
Progressive onboarding creates a real profile with optional photo. Food plans,
weight, vaccines, deworming, medication, veterinary visits and linked documents
are editable. Training includes 19 original reward-based guides, custom tricks,
progress and behavior observations. Global reminders support optional local
notifications, category preferences and advance notice.

## Local data

One observable store owns a Codable schema-v1 snapshot. `LocalSnapshotStorage`
uses the app's Application Support directory, under `PetPlanify/`:

- `PetPlanify.json`: current state; atomic writes after confirmed mutations.
- `PetPlanify.backup.json`: previous valid state, used for corruption recovery.
- `Attachments/`: managed photos and documents; no external path dependencies.
- `Recovery/`: damaged originals and preserved pre-import state, when applicable.

I/O runs in storage actors. A failed save keeps the previous published state.
Unknown future schemas remain untouched. Previews use in-memory storage without
notifications, iCloud or real Application Support access.

Export/import uses a `.petplanify` package containing a manifest, snapshot and
attachments, with size, path, linkage and SHA-256 validation. Import shows a
summary and requires confirmation before replacing data; it preserves the old
local directory. Reset also requires confirmation and returns to onboarding.

## Optional iCloud

The coordinated file provider and conflict-choice interface are implemented.
Synchronization is user-triggered in Settings and local storage always works.
The current project has **no configured iCloud capability/container**; cross-device
sync remains unverified. See [validation and device handoff](VALIDATION.md) for
the exact Apple configuration. No CloudKit database is used.

## Build and tests

```sh
xcodebuild -project PetPlanify.xcodeproj -scheme PetPlanify \
  -configuration Debug -destination 'platform=macOS' \
  CODE_SIGNING_ALLOWED=NO build
swift test
```

When the system developer directory points to Command Line Tools, set
`DEVELOPER_DIR` to the installed Xcode app's `Contents/Developer` directory.
The native Swift Testing package target covers storage, recovery, import safety,
domain derivation and a complete disposable store/relaunch flow.

A Debug-only launch argument, `--petplanify-validation-directory`, accepts a
`PetPlanify…` directory under `/tmp` or the system temporary directory. It isolates
manual development data and disables external services. It is absent in Release.

**iOS validation intentionally deferred by Ana until the final physical-device testing phase.**
No iPhone Simulator was used. See [VALIDATION.md](VALIDATION.md) for the remaining
hands-on checks. App-icon slots are prepared; final artwork is not supplied.
