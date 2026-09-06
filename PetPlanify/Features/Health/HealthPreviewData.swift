import Foundation

/// Development examples only. Production state is loaded by PetPlanifyStore.
enum HealthPreviewData {
    static var sample: HealthData {
        let now = Date.now
        var data = HealthData()
        data.weights = (0..<6).map { index in
            WeightRecord(date: Calendar.current.date(byAdding: .month, value: index - 5, to: now)!, weight: 7.3 - Double(index) / 10)
        }
        data.vaccines = [VaccinationRecord(name: "Vacuna anual", dateAdministered: now.addingTimeInterval(-86_400 * 330), nextDueDate: now.addingTimeInterval(86_400 * 35))]
        return data
    }
}
