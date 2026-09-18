import SwiftUI

struct BreedSelector: View {
    let species: String
    @Binding var breed: String
    @State private var presented = false

    var body: some View {
        Button {
            presented = true
        } label: {
            LabeledContent("Raza") {
                HStack(spacing: AppTheme.Space.sm) {
                    Text(breed.isEmpty ? "Sin indicar" : breed)
                        .foregroundStyle(breed.isEmpty ? AppTheme.secondaryInk : AppTheme.ink)
                        .lineLimit(1)
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(AppTheme.secondaryInk)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $presented) {
            BreedSelectionSheet(species: species, breed: $breed)
        }
    }
}

private struct BreedSelectionSheet: View {
    let species: String
    @Binding var breed: String
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var customBreed = ""

    private var options: [String] { BreedCatalog.options(for: species) }
    private var filtered: [String] {
        guard !searchText.isEmpty else { return options }
        return options.filter { $0.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        NavigationStack {
            List {
                Button("No indicar") { breed = ""; dismiss() }
                ForEach(filtered, id: \.self) { option in
                    Button {
                        if option == "Otro" { customBreed = options.contains(breed) ? "" : breed }
                        else { breed = option; dismiss() }
                    } label: {
                        HStack {
                            Text(option).foregroundStyle(AppTheme.ink)
                            Spacer()
                            if breed == option { Image(systemName: "checkmark").foregroundStyle(AppTheme.green) }
                        }
                    }
                    .buttonStyle(.plain)
                }
                if options.contains("Otro") {
                    Section("Otro") {
                        TextField("Escribe la raza", text: $customBreed)
                        Button("Usar esta raza") {
                            breed = customBreed.trimmingCharacters(in: .whitespacesAndNewlines)
                            dismiss()
                        }
                        .disabled(customBreed.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Buscar raza")
            .navigationTitle("Seleccionar raza")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cerrar") { dismiss() } } }
        }
        .careSheet()
        .onAppear {
            if !breed.isEmpty && !options.contains(breed) { customBreed = breed }
        }
    }
}

enum BreedCatalog {
    static func options(for species: String) -> [String] {
        let base = [
                "Akita Inu", "Beagle", "Bichón maltés", "Border Collie", "Boxer",
                "Bulldog francés", "Can de Palleiro", "Caniche", "Chihuahua", "Cocker Spaniel", "Dachshund",
                "Dálmata", "Galgo español", "Golden Retriever", "Labrador Retriever",
                "Mestizo / sin raza definida", "Pastor alemán", "Pastor belga", "Pastor de Shetland",
                "Podenco", "Pomerania", "Rottweiler", "Schnauzer", "Shiba Inu", "Teckel",
                "West Highland White Terrier", "Yorkshire Terrier", "Otro"
            ]
        return base.sorted { $0.localizedStandardCompare($1) == .orderedAscending }
    }
}
