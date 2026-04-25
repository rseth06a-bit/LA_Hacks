import Foundation

struct LabResult: Identifiable, Codable {
    let id: String
    let patientId: String
    let testName: String
    let result: String
    let date: Date

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case patientId, testName, result, date
    }
}