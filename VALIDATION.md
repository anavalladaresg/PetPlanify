# Development validation — 6 September 2026

## Implemented

- Five native areas: iPhone TabView and Mac NavigationSplitView.
- Welcome → identity/photo → birth date or approximate age, sex and weight → summary.
  Optional setup suggestions disappear when completed or dismissed.
- Shared `@MainActor @Observable PetPlanifyStore`; snapshot schema 1; persistent UUIDs.
- Multiple pet workspaces with automatic migration from the original single-pet snapshot;
  active-pet switching preserves separate care records. Local family profiles support
  responsible, caregiver and read-only roles.
- Editable profile, resized app-owned JPEG, metric canonical storage, kg/lb display,
  system/light/dark appearance and Spanish localization.
- Food plans and balanced meal schedules, plan history, editable transitions and observations.
- Weight chart and history; vaccine, internal/external deworming, medication and visit
  CRUD; health calendar with administered/upcoming vaccine and deworming dates, color
  legend and direct editing from a selected event; manual assessments/follow-ups; native
  PDF/image import and Quick Look; document rename, unlink/relink and removal. Destructive
  actions request confirmation.
- 19 built-in trick guides, category/difficulty filters, selected progress/status/notes,
  custom trick CRUD and behavior observation CRUD. SF Symbols are replaceable by assets.
- Linked and custom reminders; complete/reopen; stable notification identifiers;
  permission requested only when enabled; actual UserNotifications scheduling/cancellation.
- Atomic local save, previous valid backup, corruption recovery, future-schema protection,
  transactional package restore, path validation and managed attachment cleanup.
- iCloud Documents entitlement and container identifier are configured, with coordinated
  package transfer and explicit conflict choices. No server.

Code remains feature-oriented under `App`, `Core` (models, persistence, storage,
notifications, formatting, theme, components, preview data), and the six feature
folders including Onboarding. There are no daily/session tracking, standalone
Gallery, Notes or Reminder modules. Evolution is presented from Inicio as a
read-only summary of the existing care records.

## Evidence and limits

| Check | Result |
|---|---|
| Baseline macOS unsigned build | Passed with Xcode 27 beta |
| Final macOS Debug build | Passed |
| Native Swift Testing | 25 tests passed |
| Store integration | Create/edit pet, food, weight, vaccine, both deworming kinds, medication, visit/document, trick/progress/custom trick, observation, reminder/completion and preferences persist across fresh store instances |
| Backup integration | Package export/restore, preserved previous files, tamper/incomplete rejection, traversal/symlink rejection and reset passed with temporary data |
| Failure behavior | Failed save leaves published state unchanged; concurrent mutations retain all records; corrupted primary recovery and future schemas tested |
| Localization | Native compiler extraction/synchronization; catalogue parsed as JSON with Spanish source language |
| iPhone source | Reviewed navigation, safe areas, adaptive sheets, number/date entry, PhotosPicker, file importer, accessibility and appearance; no Simulator commands used |
| Mac app launch | Development build launched with isolated temporary-data argument |
| Mac visual/click-through review | Not completed: Computer Use repeatedly reported missing Accessibility/Screen Recording permission. No claim of tested layout, VoiceOver, native picker interaction or actual GUI relaunch |
| Actual notification delivery | Not exercised; no notification spam. Pure schedule eligibility, advance time, completion and identifiers tested |
| iCloud cross-device operation | Unverified: container registration, signing and two-device transfer still require Apple Developer/device testing |

Only the pre-existing AppIntents metadata-extraction warning remains in the Mac
build (the app does not use AppIntents). Swift tests do not touch production data.
GUI first-launch, photo selection, document preview and native import/export panels
still require hands-on verification; the corresponding persistence operations pass
the integration test. Light/dark colors are explicit adaptive palette choices;
the primary/secondary/green/orange text colors have computed contrast ratios of
4.71:1–14.22:1 against the card surface in both modes. Native controls, actual
rendering and Dynamic Type behavior still need an on-device check.

## iCloud setup for Ana

For device testing with a Personal Team, use the Debug configuration for the
iPhone target. It intentionally uses `PetPlanify/PetPlanify.Development.entitlements`
without iCloud capabilities, so the app can be installed and tested locally.
The iCloud row will remain unavailable until the app is signed with a team that
supports the configured container. Release keeps the full iCloud entitlements.

1. In Apple Developer, create/select the iCloud container
   `iCloud.com.anavalladares.PetPlanify` for both supported platforms.
2. The repository now contains `PetPlanify/PetPlanify.entitlements` with **iCloud
   Documents**, the container identifier and the ubiquity key-value store identifier.
3. Use the intended Apple Developer team and regenerate the relevant provisioning
   profiles. No Developer Portal/container changes were made by this development run.
4. With the same Apple account on Mac and iPhone, verify upload/download, offline
   fallback, conflict choices, attachment integrity and retained pre-restore backups.
   A locally queued upload is shown as “Sincronizando” until confirmed uploaded.

References: [Apple iCloud configuration](https://developer.apple.com/documentation/xcode/configuring-icloud-services)
and [container requirements](https://developer.apple.com/documentation/foundation/filemanager/url(forubiquitycontaineridentifier:)).
Training copy is original and follows the principles of
[Dogs Trust reward-based training](https://www.dogstrust.org.uk/dog-advice/training/techniques/positive-reinforcement-training-with-rewards).

## Physical iPhone checklist

**iOS validation intentionally deferred by Ana until the final physical-device testing phase.**

- Onboarding; exact/approximate age; choose, replace and remove photo.
- All five tabs; scroll/safe areas; large text, VoiceOver and light/dark/system modes.
- Profile, food plan/schedule/transition, weight and kg/lb formatting with decimal comma.
- Vaccine, both deworming kinds, medication finish/history, visits and follow-ups.
- Attach/preview/rename/unlink/delete a disposable PDF/image.
- Health calendar: move between months, distinguish vaccine/deworming colors, select a
  day and edit the original record from its event.
- Library filters/guides, selected progress, custom trick CRUD and observations.
- Bell reminders, complete/reopen, edit/delete custom reminder; permission denial,
  advance time, actual notification delivery and rescheduling after a date changes.
- Terminate/reopen and verify all data survives.
- Export package with photo/documents; import confirmation/restore; reject invalid copy;
  reset only disposable data after exporting a backup.
- If configured, iCloud transfer/conflicts and offline operation.

Final marketing icon artwork remains to be supplied; the asset structure is ready.
