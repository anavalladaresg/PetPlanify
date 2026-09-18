import SwiftUI

struct OnboardingView: View {
    @Environment(PetPlanifyStore.self) private var store
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var step = 0
    @State private var draft = PetProfile()
    @State private var photoData: Data?
    @State private var removePhoto = false
    @State private var exactBirthday = true
    @State private var approximateAge = ""
    @State private var weight = ""
    @State private var error: String?
    @State private var saving = false
    @State private var photoLoading = false
    @AppStorage("petplanify.apple.displayName") private var displayName = ""
    var body: some View {
        VStack(spacing: 0) {
            if step == 0 {
                GeometryReader { proxy in
                    ZStack {
                        Circle()
                            .fill(AppTheme.greenSoft.opacity(0.34))
                            .frame(width: 260, height: 260)
                            .offset(x: proxy.size.width * 0.38, y: -proxy.size.height * 0.28)
                        Circle()
                            .fill(AppTheme.orangeSoft.opacity(0.30))
                            .frame(width: 220, height: 220)
                            .offset(x: -proxy.size.width * 0.40, y: proxy.size.height * 0.30)
                        Image(systemName: "pawprint.fill")
                            .font(.system(size: 92))
                            .foregroundStyle(AppTheme.green.opacity(0.08))
                            .rotationEffect(.degrees(-18))
                            .offset(x: proxy.size.width * 0.34, y: proxy.size.height * 0.25)
                        ScrollView {
                            VStack(spacing: 22) {
                                DogPoseIllustration(pose: .sitting)
                                    .frame(width: 140, height: 116)
                                Text("PetPlanify")
                                    .font(.system(size: 42, weight: .semibold, design: .serif))
                                    .accessibilityAddTraits(.isHeader)
                                Text(welcomeSubtitle).font(.title2).fontDesign(.serif)
                                Text("Un lugar para recordar sus cuidados, guardar su historia y acompañar cada aprendizaje.")
                                    .multilineTextAlignment(.center).foregroundStyle(AppTheme.secondaryInk)
                                VStack(spacing: 8) {
                                    Button { next() } label: {
                                        HStack(spacing: 14) {
                                            Image(systemName: "sparkle")
                                                .font(.caption.weight(.bold))
                                            Text("Empezar")
                                                .font(.title3.weight(.bold))
                                            Image(systemName: "sparkle")
                                                .font(.caption.weight(.bold))
                                        }
                                        .frame(minWidth: 180, minHeight: 52)
                                    }
                                    .buttonStyle(.borderedProminent)
                                    .tint(AppTheme.green)
                                    .disabled(saving || photoLoading)
                                    .accessibilityIdentifier("onboarding.next")

                                }
                            }
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.horizontal, 30)
                            .padding(.vertical, 24)
                            .frame(maxWidth: 500)
                            .frame(maxWidth: .infinity)
                            .frame(minHeight: max(0, proxy.size.height - 24), alignment: .center)
                        }
                    }
                }
            } else if step < 3 {
                ZStack {
                    Circle().fill(AppTheme.greenSoft.opacity(0.18)).frame(width: 260).offset(x: 180, y: -300)
                    Circle().fill(AppTheme.orangeSoft.opacity(0.16)).frame(width: 220).offset(x: -190, y: 280)
                    Group {
                    if step == 1 {
                        Form {
                            Section {
                                ProfileIdentityFields(draft: $draft, photoData: $photoData, removePhoto: $removePhoto, isLoadingPhoto: $photoLoading)
                            } header: {
                                Text("Conozcamos a tu perro")
                                    .font(.title3.weight(.semibold))
                                    .foregroundStyle(AppTheme.ink)
                            }
                            Section {
                                ProfileBasicFields(draft: $draft, exactBirthday: $exactBirthday, approximateAge: $approximateAge, weight: $weight, unit: .kilograms, weightRequired: false)
                            } header: {
                                Text("Su edad y peso")
                                    .font(.title3.weight(.semibold))
                                    .foregroundStyle(AppTheme.ink)
                            }
                            if let error { Text(error).foregroundStyle(AppTheme.orange) }
                        }
                        .formStyle(.grouped)
                        .scrollContentBackground(.hidden)
                        .scrollDismissesKeyboard(.interactively)
                    } else {
                        ScrollView {
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Revisa su perfil")
                                    .font(.title3.weight(.semibold))
                                Text("Todo listo para empezar a cuidar de \(draft.name.isEmpty ? "tu perro" : draft.name).")
                                    .foregroundStyle(AppTheme.secondaryInk)
                                reviewRow("Nombre", draft.name)
                                reviewRow("Raza", draft.breed.isEmpty ? "Sin indicar" : draft.breed)
                                reviewRow("Edad", draft.ageDescription().isEmpty ? "Sin indicar" : draft.ageDescription())
                                reviewRow("Peso", weight.isEmpty ? "Sin indicar" : "\(weight) kg")
                                if let microchip = draft.microchip, !microchip.isEmpty { reviewRow("Microchip", microchip) }
                                if let error { Text(error).foregroundStyle(AppTheme.orange) }
                            }
                            .padding(24)
                        }
                    }
                    }
                    .appSurface(cornerRadius: AppTheme.heroRadius, elevated: true)
                    .padding(.horizontal, 18)
                }
                .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), removal: .move(edge: .leading).combined(with: .opacity)))
            } else {
                ScrollView {
                    VStack(spacing: 18) {
                        if photoData != nil {
                            PetAvatarView(size: 104, imageData: photoData)
                        } else {
                            DogPoseIllustration(pose: .sitting).frame(width: 120, height: 100)
                        }
                        Text("Todo listo para \(draft.name)").font(.title).fontDesign(.serif).multilineTextAlignment(.center)
                            .accessibilityAddTraits(.isHeader)
                        Text([draft.breed, draft.ageDescription()].filter { !$0.isEmpty }.joined(separator: " · "))
                            .foregroundStyle(AppTheme.secondaryInk)
                        Text("Ya puedes configurar la alimentación, añadir registros de salud, elegir trucos y crear recordatorios.")
                            .multilineTextAlignment(.center)
                        if let error { Text(error).foregroundStyle(.red) }
                    }
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(30).frame(maxWidth: 500).frame(maxWidth: .infinity)
                }
            }
            Group {
                if step > 0 {
                    footerLayout {
                    Button { error = nil; step -= 1 } label: {
                        Text("Atrás").frame(minHeight: 44)
                    }.disabled(saving)
                    if !dynamicTypeSize.isAccessibilitySize { Spacer() }
                    Button { next() } label: {
                        HStack(spacing: 8) {
                            if saving { ProgressView().controlSize(.small).accessibilityHidden(true) }
                            Text(saving ? "Guardando…" : step == 3 ? "Entrar en PetPlanify" : "Continuar")
                                .fontWeight(.semibold)
                                .multilineTextAlignment(.center)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .frame(maxWidth: dynamicTypeSize.isAccessibilitySize ? .infinity : nil)
                    }
                    .buttonStyle(.borderedProminent).controlSize(.large)
                    .tint(AppTheme.green)
                    .frame(minWidth: 156, minHeight: 48)
                    .disabled(saving || photoLoading).accessibilityIdentifier("onboarding.next")
                }
                }
            }
            .padding(.horizontal, 22).padding(.vertical, 16)
            .background(AppTheme.surface)
            .overlay(alignment: .top) { Divider() }
        }
        .appCanvas()
        .animation(.easeInOut(duration: 0.32), value: step)
        .accessibilityIdentifier("onboarding.screen")
        #if os(macOS)
        .frame(minWidth: 460, minHeight: 560)
        #endif
    }
    private var footerLayout: AnyLayout {
        dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(spacing: 10))
            : AnyLayout(HStackLayout(spacing: 16))
    }
    private var welcomeSubtitle: String {
        let firstName = displayName
            .split(whereSeparator: { $0.isWhitespace })
            .first
            .map(String.init) ?? ""
        return firstName.isEmpty ? "Qué alegría verte." : "Qué alegría verte, \(firstName)."
    }
    @ViewBuilder
    private func reviewRow(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title).foregroundStyle(AppTheme.secondaryInk)
            Spacer(minLength: 12)
            Text(value).fontWeight(.semibold).multilineTextAlignment(.trailing)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
        .background(AppTheme.surface.opacity(0.72), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
    private func next() {
        error = nil
        if step == 1 && draft.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            error = String(localized: "Indica su nombre para continuar."); return
        }
        if step == 2 {
            let profileResult = ProfileValidation.prepare(draft, weight: weight, unit: .kilograms, exactBirthday: exactBirthday, approximateAge: approximateAge, weightRequired: false)
            guard let valid = profileResult.profile else {
                error = profileResult.error
                return
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

#Preview { OnboardingView().environment(PetPlanifyStore(storage: CloudKitPersistenceService(), loaded: true)) }
