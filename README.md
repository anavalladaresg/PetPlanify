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

The application currently includes adaptive navigation and completed `Inicio`,
`Alimentación`, `Salud`, `Entrenamiento`, `Evolución`, `Recordatorios`, and
`Notas` dashboards backed by mock data. `Ajustes` remains a clean placeholder.
Persistence and cloud features are intentionally out of scope for now.

GitHub is intentionally used as lightweight source control and remote backup:
normal development happens directly on `main` with small descriptive commits.
