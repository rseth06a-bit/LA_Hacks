import SwiftUI

// --- Model for an agent event ---
struct AgentEvent: Identifiable {
    let id = UUID()
    let agentName: String
    let agentType: AgentType
    let message: String
    let timestamp: Date

    enum AgentType {
        case lab, bed, scheduling
    }
}

// --- Main view ---
struct AgentActivityView: View {
    @State private var events: [AgentEvent] = AgentEvent.mockEvents()
    @State private var isPolling = false
    let timer = Timer.publish(every: 5, on: .main, in: .common).autoconnect()

    var body: some View {
        NavigationView {
            Group {
                if events.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "antenna.radiowaves.left.and.right")
                            .font(.system(size: 40))
                            .foregroundColor(.gray.opacity(0.4))
                        Text("Waiting for agent activity...")
                            .font(.system(size: 15))
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(events) { event in
                                AgentEventRow(event: event)
                                    .transition(.asymmetric(
                                        insertion: .move(edge: .top).combined(with: .opacity),
                                        removal: .opacity
                                    ))
                                Divider()
                                    .padding(.leading, 52)
                            }
                        }
                        .padding(.top, 8)
                    }
                }
            }
            .navigationTitle("Agent Activity")
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 8, height: 8)
                        Text("Live")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.green)
                    }
                }
            }

        }
        .onReceive(timer) { _ in
            pollForNewEvents()
        }
    }

    func pollForNewEvents() {
        Task {
            do {
                let eventDTOs = try await APIService.fetchAgentEvents()
                let newEvents = eventDTOs.map { $0.toAgentEvent() }
                withAnimation(.easeInOut(duration: 0.4)) {
                    events = newEvents.sorted { $0.timestamp > $1.timestamp }
                    if events.count > 50 {
                        events = Array(events.prefix(50))
                    }
                }
            } catch {
                print("Error polling agent events: \(error)")
                // Keep showing mock data if API fails
            }
        }
    }
}

// --- Single event row ---
struct AgentEventRow: View {
    let event: AgentEvent

    static let formatter: RelativeDateTimeFormatter = {
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .full
        return f
    }()

    var dotColor: Color {
        switch event.agentType {
        case .lab: return .green
        case .bed: return .orange
        case .scheduling: return .blue
        }
    }

    var iconName: String {
        switch event.agentType {
        case .lab: return "flask"
        case .bed: return "bed.double"
        case .scheduling: return "calendar"
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {

            // --- Colored icon dot ---
            ZStack {
                Circle()
                    .fill(dotColor.opacity(0.15))
                    .frame(width: 36, height: 36)
                Image(systemName: iconName)
                    .font(.system(size: 14))
                    .foregroundColor(dotColor)
            }

            // --- Agent name + message ---
            VStack(alignment: .leading, spacing: 3) {
                Text(event.agentName)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.primary)
                Text(event.message)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()

            // --- Timestamp ---
            Text(Self.formatter.localizedString(for: event.timestamp, relativeTo: Date()))
                .font(.system(size: 11))
                .foregroundColor(.secondary)
                .padding(.top, 2)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

// --- Mock data for demo ---
extension AgentEvent {
    static func mockEvents() -> [AgentEvent] {
        [
            AgentEvent(agentName: "Lab Results Agent", agentType: .lab,
                message: "CBC for Maria Lopez: 14.2 g/dL — NORMAL (range: 12–16)",
                timestamp: Date().addingTimeInterval(-60)),
            AgentEvent(agentName: "Bed Management Agent", agentType: .bed,
                message: "Bed 4B freed by John Carter. Reassigned to Sofia Reyes.",
                timestamp: Date().addingTimeInterval(-180)),
            AgentEvent(agentName: "Scheduling Agent", agentType: .scheduling,
                message: "Cardiology consult scheduled for James Miller at 2:30 PM.",
                timestamp: Date().addingTimeInterval(-300)),
            AgentEvent(agentName: "Lab Results Agent", agentType: .lab,
                message: "Glucose for David Kim: 210 mg/dL — ABNORMAL (range: 70–100)",
                timestamp: Date().addingTimeInterval(-600)),
            AgentEvent(agentName: "Bed Management Agent", agentType: .bed,
                message: "Bed 2A freed by Anna Scott. No patients in queue — marked available.",
                timestamp: Date().addingTimeInterval(-900)),
        ]
    }

    static func randomMockEvent() -> AgentEvent {
        let events: [(String, AgentType, String)] = [
            ("Lab Results Agent", .lab, "Potassium for Elena Torres: 3.2 mEq/L — ABNORMAL (range: 3.5–5.0)"),
            ("Bed Management Agent", .bed, "Bed 6C freed by Marcus Webb. Reassigned to James Miller."),
            ("Scheduling Agent", .scheduling, "Neurology consult scheduled for Maria Lopez at 4:00 PM."),
            ("Lab Results Agent", .lab, "WBC for Sofia Reyes: 7.8 K/uL — NORMAL (range: 4.5–11.0)"),
            ("Bed Management Agent", .bed, "Bed 1A freed by David Kim. No patients in queue — marked available."),
        ]
        let pick = events.randomElement()!
        return AgentEvent(agentName: pick.0, agentType: pick.1, message: pick.2, timestamp: Date())
    }
}