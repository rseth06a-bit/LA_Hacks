import Foundation

class APIService {
    static let baseURL = "YOUR_API_GATEWAY_URL"

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
        return try decoder.decode([LabResult].self, from: data)
    }

    // MARK: - Trigger Agent
    static func triggerAgent(agentAddress: String) async throws -> TriggerResponse {
        guard let url = URL(string: "\(baseURL)/trigger-agent") else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = ["agentAddress": agentAddress]
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        let decoder = JSONDecoder()
        return try decoder.decode(TriggerResponse.self, from: data)
    }
}

// MARK: - Response Models
struct TriggerResponse: Codable {
    let success: Bool
    let message: String
}