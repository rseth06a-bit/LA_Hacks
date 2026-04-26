import Foundation

struct Bed: Identifiable, Codable {
    let id: String
    let room: String
    let isOccupied: Bool
    let patientId: String?
    let status: String?
    let patient: String?

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case room, isOccupied, patientId, status, patient
    }
}