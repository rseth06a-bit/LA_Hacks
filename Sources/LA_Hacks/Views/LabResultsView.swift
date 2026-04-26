import SwiftUI

struct LabResultsView: View {
    let labResults: [LabResult]
    let patients: [Patient]

    var body: some View {
        NavigationView {
            List {
                Section(header: Text("\(labResults.count) recent results")) {
                    ForEach(labResults.sorted(by: { $0.date > $1.date })) { result in
                        HStack(alignment: .top, spacing: 10) {
                            Circle()
                                .fill(resultColor(for: result.result))
                                .frame(width: 8, height: 8)
                                .padding(.top, 5)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(patientName(for: result.patientId))
                                    .font(.headline)
                                Text(result.testName)
                                    .font(.subheadline)
                                Text(result.date, style: .time)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Text(result.result.capitalized)
                                .font(.caption.weight(.semibold))
                                .foregroundColor(resultColor(for: result.result))
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .listStyle(.inset)
            .navigationTitle("Lab Results")
        }
    }

    private func patientName(for patientId: String) -> String {
        if let matched = patients.first(where: { $0.id == patientId }) {
            return matched.name
        }
        switch patientId {
        case "p-emily": return "Emily Davis"
        case "p-maria": return "Maria Lopez"
        case "p-james": return "James Chen"
        case "p-sarah": return "Sarah Williams"
        case "p-michael": return "Michael Brown"
        default: return "Unknown Patient"
        }
    }

    private func resultColor(for value: String) -> Color {
        switch value.lowercased() {
        case "abnormal", "critical":
            return .red
        case "normal":
            return .green
        default:
            return .gray
        }
    }
}
