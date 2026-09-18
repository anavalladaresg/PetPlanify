import Foundation

struct PetPlanifySnapshot: Codable, Sendable, Equatable {
    var schemaVersion = 1
    var pet = PetProfile()
    var nutrition = NutritionData()
    var health = HealthData()
    var training = TrainingData()
    var reminders: [CareReminder] = []
    var preferences = AppPreferences()
    var onboarding = OnboardingState()
    var modifiedAt = Date.now
    /// Full care spaces for all pets. The legacy fields above always represent the active pet.
    var pets: [PetWorkspace] = []
    var activePetID: UUID?
    var familyMembers: [FamilyMember] = []
    var currentFamilyMemberID: UUID?
    var familyInvitations: [FamilyInvitation] = []
    /// Recoverable records removed by the user. Kept in the same local snapshot so
    /// a future CloudKit provider can migrate tombstones without changing views.
    var trash: [DeletedCareRecord] = []

    private enum CodingKeys: String, CodingKey {
        case schemaVersion, pet, nutrition, health, training, reminders, preferences, onboarding, modifiedAt
        case pets, activePetID, familyMembers, currentFamilyMemberID, familyInvitations, trash
    }

    init() { }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        schemaVersion = try container.decodeIfPresent(Int.self, forKey: .schemaVersion) ?? 1
        pet = try container.decodeIfPresent(PetProfile.self, forKey: .pet) ?? PetProfile()
        nutrition = try container.decodeIfPresent(NutritionData.self, forKey: .nutrition) ?? NutritionData()
        health = try container.decodeIfPresent(HealthData.self, forKey: .health) ?? HealthData()
        training = try container.decodeIfPresent(TrainingData.self, forKey: .training) ?? TrainingData()
        reminders = try container.decodeIfPresent([CareReminder].self, forKey: .reminders) ?? []
        preferences = try container.decodeIfPresent(AppPreferences.self, forKey: .preferences) ?? AppPreferences()
        onboarding = try container.decodeIfPresent(OnboardingState.self, forKey: .onboarding) ?? OnboardingState()
        modifiedAt = try container.decodeIfPresent(Date.self, forKey: .modifiedAt) ?? .now
        pets = try container.decodeIfPresent([PetWorkspace].self, forKey: .pets) ?? []
        activePetID = try container.decodeIfPresent(UUID.self, forKey: .activePetID)
        familyMembers = try container.decodeIfPresent([FamilyMember].self, forKey: .familyMembers) ?? []
        currentFamilyMemberID = try container.decodeIfPresent(UUID.self, forKey: .currentFamilyMemberID)
        familyInvitations = try container.decodeIfPresent([FamilyInvitation].self, forKey: .familyInvitations) ?? []
        trash = try container.decodeIfPresent([DeletedCareRecord].self, forKey: .trash) ?? []
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(schemaVersion, forKey: .schemaVersion)
        try container.encode(pet, forKey: .pet)
        try container.encode(nutrition, forKey: .nutrition)
        try container.encode(health, forKey: .health)
        try container.encode(training, forKey: .training)
        try container.encode(reminders, forKey: .reminders)
        try container.encode(preferences, forKey: .preferences)
        try container.encode(onboarding, forKey: .onboarding)
        try container.encode(modifiedAt, forKey: .modifiedAt)
        try container.encode(pets, forKey: .pets)
        try container.encodeIfPresent(activePetID, forKey: .activePetID)
        try container.encode(familyMembers, forKey: .familyMembers)
        try container.encodeIfPresent(currentFamilyMemberID, forKey: .currentFamilyMemberID)
        try container.encode(familyInvitations, forKey: .familyInvitations)
        try container.encode(trash, forKey: .trash)
    }

    mutating func migratePetWorkspaces() {
        guard pets.isEmpty else {
            if activePetID == nil { activePetID = pets.first?.pet.id }
            return
        }
        let workspace = PetWorkspace(pet: pet, nutrition: nutrition, health: health, training: training, reminders: reminders, onboarding: onboarding, modifiedAt: modifiedAt)
        pets = [workspace]
        activePetID = pet.id
    }

    mutating func syncActiveWorkspace() {
        migratePetWorkspaces()
        let workspace = PetWorkspace(pet: pet, nutrition: nutrition, health: health, training: training, reminders: reminders, onboarding: onboarding, modifiedAt: modifiedAt)
        if let index = pets.firstIndex(where: { $0.pet.id == pet.id }) { pets[index] = workspace }
        else if let activePetID, let index = pets.firstIndex(where: { $0.pet.id == activePetID }) { pets[index] = workspace }
        else { pets.append(workspace) }
        activePetID = pet.id
    }

    mutating func loadWorkspace(_ workspace: PetWorkspace) {
        pet = workspace.pet
        nutrition = workspace.nutrition
        health = workspace.health
        training = workspace.training
        reminders = workspace.reminders
        onboarding = workspace.onboarding
        modifiedAt = workspace.modifiedAt
        activePetID = workspace.pet.id
    }

    var currentWeight: Double? {
        health.weights.filter { $0.date <= Date.now }.max { $0.date < $1.date }?.weight ?? pet.currentWeight
    }
}

enum DeletedCareRecordKind: String, Codable, Sendable {
    case weight, vaccine, deworming, medication, visit
    case nutritionObservation, healthObservation, trainingObservation
    case reminder

    var title: String {
        switch self {
        case .weight: String(localized: "Peso")
        case .vaccine: String(localized: "Vacuna")
        case .deworming: String(localized: "Desparasitación")
        case .medication: String(localized: "Medicación")
        case .visit: String(localized: "Visita veterinaria")
        case .nutritionObservation, .healthObservation, .trainingObservation: String(localized: "Observación")
        case .reminder: String(localized: "Recordatorio")
        }
    }

    var symbol: String {
        switch self {
        case .weight: "scalemass"
        case .vaccine: "syringe"
        case .deworming: "pills"
        case .medication: "cross.vial.fill"
        case .visit: "cross.case.fill"
        case .nutritionObservation: "fork.knife"
        case .healthObservation: "heart.text.square.fill"
        case .trainingObservation: "pawprint.fill"
        case .reminder: "bell.fill"
        }
    }
}

struct DeletedCareRecord: Identifiable, Codable, Equatable, Sendable {
    var id = UUID()
    var originalID: UUID
    var petID: UUID
    var kind: DeletedCareRecordKind
    var title: String
    var deletedAt = Date.now
    var payload: Data
    var sourceKey: String?

    init<Record: Encodable>(record: Record, originalID: UUID, petID: UUID, kind: DeletedCareRecordKind, title: String, sourceKey: String? = nil) throws {
        self.originalID = originalID
        self.petID = petID
        self.kind = kind
        self.title = title
        self.sourceKey = sourceKey
        payload = try JSONEncoder().encode(record)
    }

    func decode<Record: Decodable>(_ type: Record.Type) throws -> Record {
        try JSONDecoder().decode(type, from: payload)
    }
}

struct PetWorkspace: Codable, Sendable, Equatable, Identifiable {
    var id: UUID { pet.id }
    var pet: PetProfile
    var nutrition: NutritionData
    var health: HealthData
    var training: TrainingData
    var reminders: [CareReminder]
    var onboarding: OnboardingState
    var modifiedAt: Date
}

enum FamilyMemberRole: String, Codable, CaseIterable, Identifiable, Sendable {
    case owner, caregiver, viewer
    var id: Self { self }
    var title: String {
        switch self {
        case .owner: String(localized: "Administrador/a")
        case .caregiver: String(localized: "Cuidador/a")
        case .viewer: String(localized: "Solo lectura")
        }
    }
}

struct FamilyMember: Codable, Sendable, Equatable, Identifiable {
    var id = UUID()
    var name: String
    var role: FamilyMemberRole = .caregiver
    var createdAt = Date.now
}
