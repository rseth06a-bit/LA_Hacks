import Foundation

struct Bed: Identifiable, Codable {
    let id: String
    let room: String
    let status: String
    let patient: String?

    var isOccupied: Bool { status == "Occupied" }

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case room, status, patient
    }
}
