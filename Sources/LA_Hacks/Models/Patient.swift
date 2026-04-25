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
    case admitted = "admitted"
    case pendingDischarge = "pending_discharge"
    case discharged = "discharged"
}

enum PatientPriority: String, Codable {
    case high = "high"
    case medium = "medium"
    case low = "low"
}