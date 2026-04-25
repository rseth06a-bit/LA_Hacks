import SwiftUI

struct PatientDetailView: View {
    let patient: Patient
    @State private var actionMessage: String = ""
    @State private var showingAlert = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {

                // --- Header ---
                VStack(alignment: .leading, spacing: 8) {
                    Text(patient.name)
                        .font(.system(size: 24, weight: .bold))
                    HStack(spacing: 8) {
                        StatusBadge(status: patient.status)
                        PriorityBadge(priority: patient.priority)
                    }
                    Text("Room \(patient.room)")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 2)

                // --- Actions ---
                VStack(spacing: 12) {
                    Button(action: requestLab) {
                        HStack {
                            Image(systemName: "flask")
                            Text("Request Lab Results")
                                .font(.system(size: 15, weight: .medium))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.blue)
                        .cornerRadius(10)
                    }

                    Button(action: transferBed) {
                        HStack {
                            Image(systemName: "bed.double")
                            Text("Transfer Bed")
                                .font(.system(size: 15, weight: .medium))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.gray)
                        .cornerRadius(10)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Patient Detail")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Agent Triggered", isPresented: $showingAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(actionMessage)
        }
    }

    func requestLab() {
        actionMessage = "Lab results agent has been triggered for \(patient.name)."
        showingAlert = true
    }

    func transferBed() {
        actionMessage = "Bed management agent has been triggered for \(patient.name) in room \(patient.room)."
        showingAlert = true
    }
}