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
    @State private var events: [AgentEvent] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    let timer = Timer.publish(every: 5, on: .main, in: .common).autoconnect()

    var body: some View {
        NavigationView {
            Group {
                if isLoading && events.isEmpty {
                    VStack(spacing: 16) {
                        ProgressView("Loading agent activity...")
                        Text("Polling CareCoord for live agent events.")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let errorMessage {
                    VStack(spacing: 16) {
                        Text("Unable to load agent activity")
                            .font(.title3.weight(.semibold))
                        Text(errorMessage)
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        Button("Retry") {
                            loadEvents()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if events.isEmpty {
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
                            .fill(events.isEmpty ? Color.gray : Color.green)
                            .frame(width: 8, height: 8)
                        Text(events.isEmpty ? "Disconnected" : "Live")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(events.isEmpty ? .gray : .green)
                    }
                }
            }
        }
        .onAppear {
            loadEvents()
        }
        .onReceive(timer) { _ in
            loadEvents()
        }
    }

    private func loadEvents() {
        Task {
            if events.isEmpty {
                isLoading = true
            }
            errorMessage = nil

            do {
                async let patientsPoll = APIService.fetchPatients()
                _ = try await patientsPoll
                let eventDTOs = try await APIService.fetchAgentEvents()
                let newEvents = eventDTOs.map { $0.toAgentEvent() }.sorted { $0.timestamp > $1.timestamp }

                withAnimation(.easeInOut(duration: 0.4)) {
                    events = newEvents
                    if events.count > 50 {
                        events = Array(events.prefix(50))
                    }
                }
            } catch {
                errorMessage = error.localizedDescription
            }

            isLoading = false
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
            ZStack {
                Circle()
                    .fill(dotColor.opacity(0.15))
                    .frame(width: 36, height: 36)
                Image(systemName: iconName)
                    .font(.system(size: 14))
                    .foregroundColor(dotColor)
            }

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

            Text(Self.formatter.localizedString(for: event.timestamp, relativeTo: Date()))
                .font(.system(size: 11))
                .foregroundColor(.secondary)
                .padding(.top, 2)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}
