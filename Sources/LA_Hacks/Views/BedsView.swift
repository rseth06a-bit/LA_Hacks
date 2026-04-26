import SwiftUI

struct BedsView: View {
    let beds: [Bed]
    let patients: [Patient]

    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    ForEach(beds) { bed in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(bed.room)
                                    .font(.headline)
                                Spacer()
                                Text(statusLabel(for: bed))
                                    .font(.caption.weight(.semibold))
                                    .foregroundColor(statusColor(for: bed))
                            }

                            Text(patientName(for: bed))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(nsColor: .textBackgroundColor))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                .padding(12)
            }
            .background(Color(nsColor: .windowBackgroundColor))
            .navigationTitle("Beds")
        }
    }

    private func patientName(for bed: Bed) -> String {
        if let fallbackPatient = bed.patient, !fallbackPatient.isEmpty {
            return fallbackPatient
        }

        guard
            let patientId = bed.patientId,
            let patient = patients.first(where: { $0.id == patientId })
        else {
            return statusLabel(for: bed).lowercased() == "occupied" ? "Assigned patient" : "Available"
        }
        return patient.name
    }

    private func statusLabel(for bed: Bed) -> String {
        if let status = bed.status, !status.isEmpty {
            return status
        }
        return bed.isOccupied ? "Occupied" : "Available"
    }

    private func statusColor(for bed: Bed) -> Color {
        switch statusLabel(for: bed).lowercased() {
        case "occupied":
            return .blue
        case "cleaning":
            return .orange
        default:
            return .green
        }
    }
}
