# PetPlanify

PetPlanify is a native SwiftUI companion for organizing the everyday care of a pet.

## Requirements

- Xcode 27
- iOS 27 or macOS 27

Open `PetPlanify.xcodeproj` in Xcode and run the shared `PetPlanify` scheme on
My Mac. iPhone validation is intentionally reserved for the final
physical-device testing phase.

Unsigned command-line builds:

```sh
xcodebuild -project PetPlanify.xcodeproj -scheme PetPlanify \
  -destination "platform=macOS" CODE_SIGNING_ALLOWED=NO build
```

The application has six focused areas: `Inicio`, `Alimentación`, `Salud`,
`Entrenamiento`, `Evolución`, and `Ajustes`. Notes are lightweight contextual
observations, while reminders live in their related feature and in a compact
reminder view. Gallery is not part of PetPlanify.

All current application data remains mock data. Persistence and physical-device
iPhone validation are planned for future phases.

GitHub is intentionally used as lightweight source control and remote backup:
normal development happens directly on `main` with small descriptive commits.
