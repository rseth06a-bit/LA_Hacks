import Foundation

struct Patient: Identifiable, Codable {
    let id: String
    let name: String
    let room: String
    let age: Int?
    let status: PatientStatus
    let priority: PatientPriority
    let physician: String?

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case name, room, age, status, priority, physician
    }
}

enum PatientStatus: String, Codable {
    case admitted = "admitted"
    case pendingDischarge = "pending_discharge"
    case discharged = "discharged"

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let value = try container.decode(String.self).lowercased()

        switch value {
        case "admitted":
            self = .admitted
        case "pending discharge", "pending_discharge":
            self = .pendingDischarge
        case "discharged":
            self = .discharged
        default:
            self = .admitted
        }
    }
}

enum PatientPriority: String, Codable {
    case high = "high"
    case medium = "medium"
    case low = "low"

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let value = try container.decode(String.self).lowercased()

        switch value {
        case "high":
            self = .high
        case "medium":
            self = .medium
        case "low":
            self = .low
        default:
            self = .medium
        }
    }
}