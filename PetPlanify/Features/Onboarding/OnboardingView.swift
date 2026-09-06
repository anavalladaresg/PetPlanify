import SwiftUI

struct OnboardingView: View {
    @Environment(PetPlanifyStore.self) private var store
    @State private var step = 0
    @State private var draft = PetProfile()
    @State private var photoData: Data?
    @State private var removePhoto = false
    @State private var exactBirthday = true
    @State private var approximateAge = ""
    @State private var weight = ""
    @State private var error: String?
    @State private var saving = false
    var body: some View {
        VStack(spacing: 0) {
            if step == 0 {
                ScrollView {
                    VStack(spacing: 22) {
                        PetAvatarView(size: 112).padding(.top, 44)
                        Text("PetPlanify").font(.largeTitle.weight(.semibold)).fontDesign(.serif)
                        Text("Su cuidado, con calma.").font(.title2).fontDesign(.serif)
                        Text("Un lugar para recordar sus cuidados, guardar su historia y acompañar cada aprendizaje.")
                            .multilineTextAlignment(.center).foregroundStyle(AppTheme.secondaryInk)
                    }.padding(30).frame(maxWidth: 500).frame(maxWidth: .infinity)
                }
            } else if step < 3 {
                Form {
                    if step == 1 {
                        ProfileIdentityFields(draft: $draft, photoData: $photoData, removePhoto: $removePhoto)
                    } else {
                        ProfileBasicFields(draft: $draft, exactBirthday: $exactBirthday, approximateAge: $approximateAge, weight: $weight, unit: .kilograms)
                    }
                    if let error { Text(error).foregroundStyle(.red) }
                }.formStyle(.grouped).scrollContentBackground(.hidden)
            } else {
                ScrollView {
                    VStack(spacing: 18) {
                        PetAvatarView(size: 104, imageData: photoData)
                        Text("Todo listo para \(draft.name)").font(.title).fontDesign(.serif).multilineTextAlignment(.center)
                        Text("\(draft.breed) · \(draft.ageDescription())").foregroundStyle(AppTheme.secondaryInk)
                        Text("Después podrás configurar la alimentación, añadir registros de salud, elegir trucos y crear recordatorios. A tu ritmo.")
                            .multilineTextAlignment(.center)
                        if let error { Text(error).foregroundStyle(.red) }
                    }.padding(30).frame(maxWidth: 500).frame(maxWidth: .infinity)
                }
            }
            HStack {
                if step > 0 { Button("Atrás") { error = nil; step -= 1 }.disabled(saving) }
                Spacer()
                Button(step == 0 ? "Empezar" : step == 3 ? "Entrar en PetPlanify" : "Continuar") {
                    next()
                }.buttonStyle(.borderedProminent).controlSize(.large).disabled(saving).accessibilityIdentifier("onboarding.next")
            }.padding(22)
        }
        .appCanvas()
        .accessibilityIdentifier("onboarding.screen")
        #if os(macOS)
        .frame(minWidth: 460, minHeight: 560)
        #endif
    }
    private func next() {
        error = nil
        if step == 1 && draft.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            error = String(localized: "Indica su nombre para continuar."); return
        }
        if step == 2 {
            guard let valid = ProfileValidation.prepare(draft, weight: weight, unit: .kilograms, exactBirthday: exactBirthday, approximateAge: approximateAge) else {
                error = String(localized: "Revisa la fecha o edad y escribe un peso válido."); return
            }
            draft = valid
        }
        if step < 3 { step += 1 }
        else {
            saving = true
            Task {
                if !(await store.saveProfile(draft, photoData: photoData, removePhoto: false, onboarding: true)) { error = store.message }
                saving = false
            }
        }
    }
}

#Preview { OnboardingView().environment(PetPlanifyStore(storage: InMemorySnapshotStorage(), loaded: true)) }
