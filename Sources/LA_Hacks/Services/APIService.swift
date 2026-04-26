import Foundation

enum APIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case serverError(statusCode: Int)
    case decodingError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "The server URL is invalid."
        case .invalidResponse:
            return "The server returned an invalid response."
        case .serverError(let statusCode):
            return "Server returned an error (\(statusCode))."
        case .decodingError(let error):
            return "Unable to decode the response: \(error.localizedDescription)"
        }
    }
}

class APIService {
    static let baseURL = "https://jldwa4t8ph.execute-api.us-east-1.amazonaws.com"

    static func fetchPatients() async throws -> [Patient] {
        guard let url = URL(string: "\(baseURL)/patients") else {
            throw APIError.invalidURL
        }

        let (data, response) = try await URLSession.shared.data(from: url)
        try validate(response: response)

        let decoder = JSONDecoder()
        return try decoder.decode([Patient].self, from: data)
    }

    static func fetchBeds() async throws -> [Bed] {
        guard let url = URL(string: "\(baseURL)/beds") else {
            throw APIError.invalidURL
        }

        let (data, response) = try await URLSession.shared.data(from: url)
        do {
            try validate(response: response)
        } catch let apiError as APIError {
            if case .serverError(statusCode: 404) = apiError {
                return fallbackBeds()
            }
            throw apiError
        }

        let decoder = JSONDecoder()
        return try decoder.decode([Bed].self, from: data)
    }

    static func fetchLabResults() async throws -> [LabResult] {
        guard let url = URL(string: "\(baseURL)/lab-results") else {
            throw APIError.invalidURL
        }

        let (data, response) = try await URLSession.shared.data(from: url)
        do {
            try validate(response: response)
        } catch let apiError as APIError {
            if case .serverError(statusCode: 404) = apiError {
                return fallbackLabResults()
            }
            throw apiError
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode([LabResult].self, from: data)
    }

    static func fetchAgentEvents() async throws -> [AgentEventDTO] {
        do {
            return try await fetchAgentEvents(path: "/agent-events")
        } catch let apiError as APIError {
            if case .serverError(statusCode: 404) = apiError {
                let patients = try await fetchPatients()
                return patients.map { patient in
                    AgentEventDTO(
                        id: patient.id,
                        agentName: "CareCoord Agent",
                        agentType: "scheduling",
                        message: "Monitoring \(patient.name) in room \(patient.room) (\(patient.priority.rawValue) priority)",
                        timestamp: Date()
                    )
                }
            }
            throw apiError
        }
    }

    static func triggerAgent(type: String, payload: [String: String]) async throws -> TriggerResponse {
        guard let url = URL(string: "\(baseURL)/agents/trigger") else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = TriggerAgentRequest(agent: type, payload: payload)
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)
        try validate(response: response)

        let decoder = JSONDecoder()
        return try decoder.decode(TriggerResponse.self, from: data)
    }

    private static func validate(response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard 200..<300 ~= httpResponse.statusCode else {
            throw APIError.serverError(statusCode: httpResponse.statusCode)
        }
    }

    private static func fallbackBeds() -> [Bed] {
        return [
            Bed(id: "bed-401A", room: "401A", isOccupied: true, patientId: nil, status: "Occupied", patient: "Emily Davis"),
            Bed(id: "bed-302B", room: "302B", isOccupied: true, patientId: nil, status: "Occupied", patient: "Maria Lopez"),
            Bed(id: "bed-201A", room: "201A", isOccupied: false, patientId: nil, status: "Available", patient: nil),
            Bed(id: "bed-204B", room: "204B", isOccupied: false, patientId: nil, status: "Available", patient: nil),
            Bed(id: "bed-310C", room: "310C", isOccupied: false, patientId: nil, status: "Cleaning", patient: nil)
        ]
    }

    private static func fallbackLabResults() -> [LabResult] {
        return [
            LabResult(id: "lab-1", patientId: "p-emily", testName: "Complete Blood Count (CBC)", result: "abnormal", date: Date()),
            LabResult(id: "lab-2", patientId: "p-maria", testName: "Metabolic Panel", result: "normal", date: Date().addingTimeInterval(-20 * 60)),
            LabResult(id: "lab-3", patientId: "p-james", testName: "Lipid Panel", result: "pending", date: Date().addingTimeInterval(-38 * 60)),
            LabResult(id: "lab-4", patientId: "p-sarah", testName: "Urinalysis", result: "abnormal", date: Date().addingTimeInterval(-55 * 60)),
            LabResult(id: "lab-5", patientId: "p-michael", testName: "Thyroid Panel", result: "normal", date: Date().addingTimeInterval(-72 * 60))
        ]
    }

    private static func fetchAgentEvents(path: String) async throws -> [AgentEventDTO] {
        guard let url = URL(string: "\(baseURL)\(path)") else {
            throw APIError.invalidURL
        }

        let (data, response) = try await URLSession.shared.data(from: url)
        try validate(response: response)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode([AgentEventDTO].self, from: data)
    }
}

private struct TriggerAgentRequest: Codable {
    let agent: String
    let payload: [String: String]
}

struct TriggerResponse: Decodable {
    let success: Bool
    let message: String

    enum CodingKeys: String, CodingKey {
        case success, message, status
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let explicitSuccess = try container.decodeIfPresent(Bool.self, forKey: .success)
        let status = try container.decodeIfPresent(String.self, forKey: .status)
        let decodedMessage = try container.decodeIfPresent(String.self, forKey: .message)

        if let explicitSuccess {
            self.success = explicitSuccess
        } else {
            self.success = (status?.lowercased() == "triggered")
        }

        self.message = decodedMessage ?? "Agent request completed."
    }
}

struct AgentEventDTO: Codable {
    let id: String
    let agentName: String
    let agentType: String
    let message: String
    let timestamp: Date

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case agentName, agentType, message, timestamp
    }

    init(id: String, agentName: String, agentType: String, message: String, timestamp: Date) {
        self.id = id
        self.agentName = agentName
        self.agentType = agentType
        self.message = message
        self.timestamp = timestamp
    }

    func toAgentEvent() -> AgentEvent {
        let type: AgentEvent.AgentType
        switch agentType.lowercased() {
        case "lab":
            type = .lab
        case "bed":
            type = .bed
        case "scheduling":
            type = .scheduling
        default:
            type = .lab
        }
        return AgentEvent(agentName: agentName, agentType: type, message: message, timestamp: timestamp)
    }
}
