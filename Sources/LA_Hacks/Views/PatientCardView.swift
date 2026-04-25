import SwiftUI

struct PatientCardView: View {
    let patient: Patient
    var onRequestLab: () -> Void
    var onTransferBed: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {

            // --- Top row: name + room ---
            HStack {
                Text(patient.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                Spacer()
                Text(patient.room)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }

            // --- Badges: status + priority ---
            HStack(spacing: 8) {
                StatusBadge(status: patient.status)
                PriorityBadge(priority: patient.priority)
            }

            Divider()

            // --- Action buttons ---
            HStack(spacing: 12) {
                Button(action: onRequestLab) {
                    Label("Request Lab", systemImage: "flask")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.blue.opacity(0.5), lineWidth: 1)
                        )
                }

                Button(action: onTransferBed) {
                    Label("Transfer Bed", systemImage: "bed.double")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.4), lineWidth: 1)
                        )
                }
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 2)
    }
}

// --- Status badge ---
struct StatusBadge: View {
    let status: PatientStatus

    var label: String {
        switch status {
        case .admitted: return "Admitted"
        case .pendingDischarge: return "Pending Discharge"
        case .discharged: return "Discharged"
        }
    }

    var color: Color {
        switch status {
        case .admitted: return .blue
        case .pendingDischarge: return .orange
        case .discharged: return .green
        }
    }

    var body: some View {
        Text(label)
            .font(.system(size: 11, weight: .medium))
            .foregroundColor(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.12))
            .cornerRadius(6)
    }
}

// --- Priority badge ---
struct PriorityBadge: View {
    let priority: PatientPriority

    var label: String {
        switch priority {
        case .high: return "High"
        case .medium: return "Medium"
        case .low: return "Low"
        }
    }

    var color: Color {
        switch priority {
        case .high: return .red
        case .medium: return .orange
        case .low: return .gray
        }
    }

    var body: some View {
        Text(label)
            .font(.system(size: 11, weight: .medium))
            .foregroundColor(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.12))
            .cornerRadius(6)
    }
}