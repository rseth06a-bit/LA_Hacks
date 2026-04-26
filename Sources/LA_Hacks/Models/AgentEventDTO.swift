import Foundation

struct AgentEventDTO: Codable {
    let id: String
    let agentName: String
    let agentType: String
    let message: String
    let timestamp: String

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case agentName = "agent"
        case agentType = "type"
        case message = "action"
        case timestamp
    }

    func toAgentEvent() -> AgentEvent {
        let type: AgentEvent.AgentType
        switch agentType.lowercased() {
        case "lab": type = .lab
        case "bed": type = .bed
        case "scheduling": type = .scheduling
        default: type = .lab
        }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "UTC")

        let date: Date
        if timestamp.contains(".") {
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS"
        } else {
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        }
        date = formatter.date(from: timestamp) ?? Date()

        return AgentEvent(agentName: agentName, agentType: type, message: message, timestamp: date)
    }
}
