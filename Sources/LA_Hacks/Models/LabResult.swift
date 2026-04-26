import Foundation

struct LabResult: Identifiable, Codable {
    let id: String
    let patient: String
    let test: String
    let status: String
    let timestamp: String?

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case patient, test, status, timestamp
    }
}
