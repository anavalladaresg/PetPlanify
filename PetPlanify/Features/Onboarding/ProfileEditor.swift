import SwiftUI
import PhotosUI

struct ProfileEditor: View {
    @Environment(PetPlanifyStore.self) private var store
    @State private var draft = PetProfile()
    @State private var weight = ""
    @State private var lowerWeight = ""
    @State private var upperWeight = ""
    @State private var approximateAge = ""
    @State private var exactBirthday = true
    @State private var photoData: Data?
    @State private var removePhoto = false
    @State private var error: String?
    @State private var photoLoading = false
    @State private var loaded = false
    var body: some View {
        CareForm(title: "Editar perfil", onSave: save, saveDisabled: photoLoading) {
            ProfileIdentityFields(draft: $draft, photoData: $photoData, removePhoto: $removePhoto, isLoadingPhoto: $photoLoading, existingPhotoURL: store.profilePhotoURL())
            ProfileBasicFields(draft: $draft, exactBirthday: $exactBirthday, approximateAge: $approximateAge, weight: $weight, unit: store.snapshot.preferences.weightUnit)
            Section("Referencia veterinaria opcional") {
                Text("Introduce únicamente el rango que te haya indicado tu profesional veterinario.").font(.subheadline).foregroundStyle(AppTheme.secondaryInk)
                TextField("Peso mínimo (\(store.snapshot.preferences.weightUnit.symbol))", text: $lowerWeight).decimalEntry()
                TextField("Peso máximo (\(store.snapshot.preferences.weightUnit.symbol))", text: $upperWeight).decimalEntry()
                TextField("Microchip", text: Binding(get: { draft.microchip ?? "" }, set: { draft.microchip = $0.isEmpty ? nil : $0 }))
                TextField("Clínica veterinaria", text: Binding(get: { draft.primaryVeterinaryClinic ?? "" }, set: { draft.primaryVeterinaryClinic = $0.isEmpty ? nil : $0 }))
            }
            if let error { Section { Text(error).foregroundStyle(.red) } }
        }.onAppear {
            guard !loaded else { return }; loaded = true
            draft = store.snapshot.pet
            exactBirthday = draft.birthDate != nil
            approximateAge = draft.ageMonths().map(String.init) ?? ""
            let unit = store.snapshot.preferences.weightUnit
            weight = store.currentWeight.map { AppFormat.number(unit.fromKilograms($0)) } ?? ""
            lowerWeight = draft.healthyWeightRange.map { AppFormat.number(unit.fromKilograms($0.lower)) } ?? ""
            upperWeight = draft.healthyWeightRange.map { AppFormat.number(unit.fromKilograms($0.upper)) } ?? ""
        }
    }
    private func save() async -> Bool {
        let unit = store.snapshot.preferences.weightUnit
        guard let value = ProfileValidation.prepare(draft, weight: weight, unit: unit, exactBirthday: exactBirthday, approximateAge: approximateAge) else {
            error = String(localized: "Revisa el nombre, la edad y el peso. Puedes escribir decimales con coma."); return false
        }
        var profile = value
        if !lowerWeight.isEmpty || !upperWeight.isEmpty {
            guard let lower = AppFormat.parseNumber(lowerWeight), let upper = AppFormat.parseNumber(upperWeight), lower < upper,
                  AppFormat.validWeight(unit.kilograms(from: lower)), AppFormat.validWeight(unit.kilograms(from: upper)) else {
                error = String(localized: "Indica un rango de peso positivo, con el mínimo menor que el máximo."); return false
            }
            profile.healthyWeightRange = WeightRange(lower: unit.kilograms(from: lower), upper: unit.kilograms(from: upper))
        } else { profile.healthyWeightRange = nil }
        return await store.saveProfile(profile, photoData: photoData, removePhoto: removePhoto, onboarding: false)
    }
}

struct ProfileIdentityFields: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Binding var draft: PetProfile
    @Binding var photoData: Data?
    @Binding var removePhoto: Bool
    @Binding var isLoadingPhoto: Bool
    var existingPhotoURL: URL?
    @State private var selection: PhotosPickerItem?
    @State private var error: String?
    var body: some View {
        Section("Su identidad") {
            identityLayout {
                PetAvatarView(size: 68, photoURL: removePhoto ? nil : existingPhotoURL, imageData: photoData)
                VStack(alignment: .leading, spacing: 2) {
                    PhotosPicker(selection: $selection, matching: .images, photoLibrary: .shared()) {
                        Label("Elegir foto", systemImage: "photo")
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(minHeight: 44)
                    }
                    .buttonStyle(.borderless)
                    .disabled(isLoadingPhoto).accessibilityIdentifier("profile.photo.select")
                    if photoData != nil || (existingPhotoURL != nil && !removePhoto) {
                        Button(role: .destructive) { photoData = nil; selection = nil; removePhoto = true } label: {
                            Text("Quitar foto")
                                .fixedSize(horizontal: false, vertical: true)
                                .frame(minHeight: 44)
                        }.buttonStyle(.borderless)
                    }
                    if isLoadingPhoto { ProgressView("Cargando foto…") }
                }
            }
            if let error { Text(error).foregroundStyle(.red) }
            TextField("Nombre", text: $draft.name).accessibilityIdentifier("profile.name")
            Picker("Especie", selection: $draft.species) {
                Text("Perro").tag("Perro")
                Text("Gato").tag("Gato")
                Text("Otra").tag("Otra")
            }
            TextField("Raza (opcional)", text: $draft.breed)
        }
        .onChange(of: selection) { _, value in
            guard let value else { return }
            isLoadingPhoto = true
            Task {
                do {
                    guard let data = try await value.loadTransferable(type: Data.self), data.count <= 50 * 1024 * 1024 else { throw StorageError.attachmentTooLarge }
                    photoData = data; removePhoto = false; error = nil
                } catch { self.error = String(localized: "No se ha podido cargar la foto. Prueba con otra imagen.") }
                isLoadingPhoto = false
            }
        }
    }
    private var identityLayout: AnyLayout {
        dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 12))
            : AnyLayout(HStackLayout(spacing: 16))
    }
}

struct ProfileBasicFields: View {
    @Binding var draft: PetProfile
    @Binding var exactBirthday: Bool
    @Binding var approximateAge: String
    @Binding var weight: String
    let unit: WeightUnit
    var body: some View {
        Section("Datos básicos") {
            Toggle("Conozco su fecha de nacimiento", isOn: $exactBirthday)
            if exactBirthday {
                DatePicker("Nacimiento", selection: Binding(get: { draft.birthDate ?? Date.now }, set: { draft.birthDate = $0 }), in: ...Date.now, displayedComponents: .date)
                    .onAppear { if draft.birthDate == nil { draft.birthDate = .now } }
            } else {
                TextField("Edad aproximada en meses", text: $approximateAge)
                    #if os(iOS)
                    .keyboardType(.numberPad)
                    #endif
                Text("Un año son 12 meses.").font(.caption).foregroundStyle(AppTheme.secondaryInk)
            }
            Picker("Sexo", selection: $draft.sex) { ForEach(PetSex.allCases) { Text($0.title).tag($0) } }
            TextField("Peso actual (\(unit.symbol))", text: $weight).decimalEntry().accessibilityIdentifier("profile.weight")
        }
    }
}

enum ProfileValidation {
    static func prepare(_ draft: PetProfile, weight: String, unit: WeightUnit, exactBirthday: Bool, approximateAge: String) -> PetProfile? {
        var value = draft
        value.name = value.name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.name.isEmpty, let number = AppFormat.parseNumber(weight), AppFormat.validWeight(unit.kilograms(from: number)) else { return nil }
        value.currentWeight = unit.kilograms(from: number)
        if exactBirthday {
            guard let birthday = value.birthDate, birthday <= .now else { return nil }
            value.approximateAgeMonths = nil
        } else {
            guard let months = Int(approximateAge), (0...1_200).contains(months) else { return nil }
            value.birthDate = nil; value.approximateAgeMonths = months; value.ageReferenceDate = .now
        }
        return value
    }
}
