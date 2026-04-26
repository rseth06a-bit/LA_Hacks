import Foundation

struct Patient: Identifiable, Codable {
    let id: String
    let name: String
    let room: String
    let status: PatientStatus
    let priority: PatientPriority

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case name, room, status, priority
    }
}

enum PatientStatus: String, Codable {
    case admitted = "Admitted"
    case pendingDischarge = "Pending Discharge"
    case discharged = "Discharged"
}

enum PatientPriority: String, Codable {
    case high = "High"
    case medium = "Medium"
    case low = "Low"
}