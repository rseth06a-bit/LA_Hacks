import Foundation

class APIService {
    static let baseURL = "https://jldwa4t8ph.execute-api.us-east-1.amazonaws.com"

    // MARK: - Fetch Patients
    static func fetchPatients() async throws -> [Patient] {
        guard let url = URL(string: "\(baseURL)/patients") else {
            throw URLError(.badURL)
        }

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        let decoder = JSONDecoder()
        return try decoder.decode([Patient].self, from: data)
    }

    // MARK: - Fetch Beds
    static func fetchBeds() async throws -> [Bed] {
        guard let url = URL(string: "\(baseURL)/beds") else {
            throw URLError(.badURL)
        }

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        let decoder = JSONDecoder()
        return try decoder.decode([Bed].self, from: data)
    }

    // MARK: - Fetch Lab Results
    static func fetchLabResults() async throws -> [LabResult] {
        guard let url = URL(string: "\(baseURL)/lab-results") else {
            throw URLError(.badURL)
        }

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode([LabResult].self, from: data)
    }

    // MARK: - Fetch Agent Events
    static func fetchAgentEvents() async throws -> [AgentEventDTO] {
        guard let url = URL(string: "\(baseURL)/agent-events") else {
            throw URLError(.badURL)
        }

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode([AgentEventDTO].self, from: data)
    }

    // MARK: - Trigger Agent
    static func triggerAgent(agentType: String, payload: [String: String]) async throws {
        guard let url = URL(string: "\(baseURL)/agents/trigger") else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = ["agent": agentType, "payload": payload]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (_, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
    }

}

// MARK: - Response Models
struct TriggerResponse: Codable {
    let success: Bool
    let message: String
}

