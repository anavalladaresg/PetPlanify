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

The application has five focused areas: `Inicio`, `Alimentación`, `Salud`,
`Entrenamiento`, and `Ajustes`. Weight history belongs to Health, behavior
observations belong to Training, and reminders live in a compact global view.
Health includes internal and external deworming alongside vaccines,
medication, veterinary visits, and their linked documents. The iPhone
composition uses native navigation and full-width mobile layouts.

All current application data remains mock data. Progressive onboarding,
functional forms, persistence, and physical-device iPhone validation are
planned for future phases.

GitHub is intentionally used as lightweight source control and remote backup:
normal development happens directly on `main` with small descriptive commits.
