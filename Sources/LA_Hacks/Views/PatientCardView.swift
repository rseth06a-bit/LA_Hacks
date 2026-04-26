import SwiftUI

struct PatientCardView: View {
    let patient: Patient
    var onRequestLab: () -> Void
    var onTransferBed: () -> Void
    var onScheduleAppointment: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {

            HStack {
                Text(patient.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.gray.opacity(0.6))
            }

            Text("Room \(patient.room)")
                .font(.system(size: 13))
                .foregroundColor(.secondary)

            HStack(spacing: 8) {
                StatusBadge(status: patient.status)
                PriorityBadge(priority: patient.priority)
            }

            Divider()

            HStack(spacing: 0) {
                Button(action: onRequestLab) {
                    Label("Request Lab", systemImage: "flask")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                }

                Divider()
                    .frame(height: 24)

                Button(action: onTransferBed) {
                    Label("Transfer", systemImage: "arrow.left.arrow.right")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                }
            }

            Divider()

            Button(action: onScheduleAppointment) {
                Label("Schedule Appointment", systemImage: "calendar.badge.plus")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.blue)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .padding(16)
        .background(Color(nsColor: .textBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color(nsColor: .separatorColor), lineWidth: 1)
        )
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