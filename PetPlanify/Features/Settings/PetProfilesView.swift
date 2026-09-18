import SwiftUI
#if os(macOS)
import AppKit
#else
import UIKit
#endif

struct PetProfilesView: View {
    @Environment(PetPlanifyStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var addingPet = false
    @State private var petToDelete: UUID?
    @State private var familyMemberToDelete: UUID?
    @State private var invitationToRevoke: UUID?
    @State private var generatingInvitation = false
    @State private var copiedTransfer = false

    var body: some View {
        NavigationStack {
            List {
                Section("Mascotas") {
                    ForEach(store.availablePets) { pet in
                        Button {
                            Task {
                                if await store.selectPet(pet.id) { dismiss() }
                            }
                        } label: {
                            HStack(spacing: AppTheme.Space.md) {
                                PetAvatarView(size: 42, photoURL: pet.id == store.snapshot.pet.id ? store.profilePhotoURL() : nil)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(pet.name.isEmpty ? "Sin nombre" : pet.name).font(.body.weight(.medium))
                                    Text([pet.species, pet.breed].filter { !$0.isEmpty }.joined(separator: " · "))
                                        .font(.caption).foregroundStyle(AppTheme.secondaryInk)
                                }
                                Spacer()
                                if pet.id == store.snapshot.pet.id {
                                    Image(systemName: "checkmark.circle.fill").foregroundStyle(AppTheme.green)
                                }
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .contextMenu {
                            if store.availablePets.count > 1 {
                                Button("Eliminar mascota", role: .destructive) { petToDelete = pet.id }
                            }
                        }
                    }
                    Button("Añadir mascota", systemImage: "plus") { addingPet = true }
                }

                Section("Familia") {
                    Label("Invita a familiares para compartir las mascotas y sus cuidados mediante iCloud.", systemImage: "person.2.fill")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.secondaryInk)
                        .fixedSize(horizontal: false, vertical: true)

                    Button("Invitar a alguien", systemImage: "person.badge.plus") {
                        generatingInvitation = true
                        Task {
                            _ = await store.createFamilyInvitation()
                            generatingInvitation = false
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(AppTheme.training)
                    .disabled(generatingInvitation)

                    if let invitation = store.snapshot.familyInvitations.sorted(by: { $0.createdAt > $1.createdAt }).first {
                        invitationCard(invitation)
                    }

                    if store.snapshot.familyMembers.isEmpty {
                            Text("Los miembros compartidos aparecerán aquí cuando haya invitaciones activas en iCloud.")
                            .font(.subheadline).foregroundStyle(AppTheme.secondaryInk)
                    }
                    ForEach(store.snapshot.familyMembers) { member in
                        HStack {
                            Image(systemName: "person.2.fill").foregroundStyle(AppTheme.green)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(member.name).font(.body.weight(.medium))
                                Text("\(member.role.title) · Desde \(AppFormat.date(member.createdAt))")
                                    .font(.caption).foregroundStyle(AppTheme.secondaryInk)
                            }
                            Spacer()
                            Picker("Rol", selection: Binding(
                                get: { member.role },
                                set: { role in Task { _ = await store.update { snapshot in
                                    guard let index = snapshot.familyMembers.firstIndex(where: { $0.id == member.id }) else { return }
                                    snapshot.familyMembers[index].role = role
                                } } }
                            )) {
                                ForEach(FamilyMemberRole.allCases) { Text($0.title).tag($0) }
                            }
                            .labelsHidden()
                            Button("Eliminar", systemImage: "trash", role: .destructive) { familyMemberToDelete = member.id }
                                .labelStyle(.iconOnly)
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .appCanvas()
            .navigationTitle("Mascotas y familia")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cerrar") { dismiss() } }
            }
        }
        .careSheet()
        .sheet(isPresented: $addingPet) { AddPetView() }
        .confirmationDialog("¿Eliminar esta mascota?", isPresented: Binding(get: { petToDelete != nil }, set: { if !$0 { petToDelete = nil } }), titleVisibility: .visible) {
            Button("Eliminar", role: .destructive) {
                guard let id = petToDelete else { return }
                Task { _ = await store.removePet(id); petToDelete = nil }
            }
            Button("Cancelar", role: .cancel) { petToDelete = nil }
        } message: {
            Text("Se eliminarán su perfil y todos sus registros de salud, alimentación, entrenamiento y recordatorios.")
        }
        .confirmationDialog("¿Eliminar este familiar?", isPresented: Binding(get: { familyMemberToDelete != nil }, set: { if !$0 { familyMemberToDelete = nil } }), titleVisibility: .visible) {
            Button("Eliminar", role: .destructive) {
                guard let id = familyMemberToDelete else { return }
                Task { _ = await store.removeFamilyMember(id); familyMemberToDelete = nil }
            }
            Button("Cancelar", role: .cancel) { familyMemberToDelete = nil }
        }
        .confirmationDialog("¿Invalidar este código?", isPresented: Binding(get: { invitationToRevoke != nil }, set: { if !$0 { invitationToRevoke = nil } }), titleVisibility: .visible) {
            Button("Invalidar código", role: .destructive) {
                guard let id = invitationToRevoke else { return }
                Task { _ = await store.revokeFamilyInvitation(id); invitationToRevoke = nil }
            }
            Button("Cancelar", role: .cancel) { invitationToRevoke = nil }
        } message: {
            Text("El código dejará de estar disponible para nuevas incorporaciones.")
        }
    }

    private func invitationCard(_ invitation: FamilyInvitation) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Space.md) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Código de invitación").font(.caption).foregroundStyle(AppTheme.secondaryInk)
                    Text(invitation.code).font(.title2.bold().monospaced()).textSelection(.enabled)
                }
                Spacer()
                StatusBadge(
                    title: invitation.effectiveStatus.title,
                    symbol: "eye.fill",
                    tint: AppTheme.reminder
                )
            }
            Text("Caduca el \(AppFormat.dateTime(invitation.expiresAt)). Comparte este código con la persona invitada para que se una a tu familia en iCloud.")
                .font(.caption).foregroundStyle(AppTheme.secondaryInk)
                .fixedSize(horizontal: false, vertical: true)
            ViewThatFits(in: .horizontal) {
                HStack(spacing: AppTheme.Space.sm) { invitationActions(invitation) }
                VStack(alignment: .leading, spacing: AppTheme.Space.sm) { invitationActions(invitation) }
            }
            if copiedTransfer {
                Label("Transferencia copiada", systemImage: "checkmark.circle.fill")
                    .font(.caption.weight(.semibold)).foregroundStyle(AppTheme.green)
            }
        }
        .padding(AppTheme.Space.lg)
        .background(AppTheme.trainingSoft.opacity(0.58), in: RoundedRectangle(cornerRadius: AppTheme.compactRadius, style: .continuous))
    }

    @ViewBuilder
    private func invitationActions(_ invitation: FamilyInvitation) -> some View {
        Button("Copiar código", systemImage: "doc.on.doc") { copy(invitation.code) }
            .disabled(invitation.effectiveStatus != .active)
        Button("Generar nuevo", systemImage: "arrow.clockwise") {
            generatingInvitation = true
            Task { _ = await store.createFamilyInvitation(); generatingInvitation = false }
        }
        .disabled(generatingInvitation)
        Button("Invalidar", systemImage: "xmark.circle", role: .destructive) { invitationToRevoke = invitation.id }
            .disabled(invitation.effectiveStatus != .active)
    }

    private func copy(_ code: String) {
        #if os(macOS)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(code, forType: .string)
        #else
        UIPasteboard.general.string = code
        #endif
        copiedTransfer = true
    }
}

struct AddPetView: View {
    @Environment(PetPlanifyStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var breed = ""
    @State private var microchip = ""

    var body: some View {
        CareForm(title: "Añadir mascota", onSave: save, saveDisabled: name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, symbol: "pawprint.fill") {
            Section("Identidad") {
                TextField("Nombre", text: $name)
                BreedSelector(species: "Perro", breed: $breed)
                TextField("Número de microchip (opcional)", text: $microchip)
            }
            Section {
                Text("Desde aquí puedes añadir su peso, alimentación, salud, entrenamiento y recordatorios.")
                    .font(.subheadline).foregroundStyle(AppTheme.secondaryInk)
            }
        }
    }

    private func save() async -> Bool {
        let trimmedMicrochip = microchip.trimmingCharacters(in: .whitespacesAndNewlines)
        let profile = PetProfile(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            species: "Perro",
            breed: breed.trimmingCharacters(in: .whitespacesAndNewlines),
            microchip: trimmedMicrochip.isEmpty ? nil : trimmedMicrochip
        )
        return await store.addPet(profile)
    }
}

struct PetSwitcher: View {
    @Environment(PetPlanifyStore.self) private var store
    @State private var showingProfiles = false

    var body: some View {
        Menu {
            Section("Cambiar mascota") {
                ForEach(store.availablePets) { pet in
                    Button {
                        Task { _ = await store.selectPet(pet.id) }
                    } label: {
                        Label(pet.name.isEmpty ? "Sin nombre" : pet.name, systemImage: pet.id == store.snapshot.pet.id ? "checkmark" : "pawprint")
                    }
                }
            }
            Divider()
            Button("Gestionar mascotas y familia", systemImage: "person.2") { showingProfiles = true }
        } label: {
            Label(store.snapshot.pet.name.isEmpty ? "Mascota" : store.snapshot.pet.name, systemImage: "pawprint.fill")
        }
        .accessibilityIdentifier("pet.switcher")
        .sheet(isPresented: $showingProfiles) { PetProfilesView() }
    }
}
