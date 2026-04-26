import SwiftUI

struct DashboardView: View {
    @State private var patients: [Patient] = []
    @State private var beds: [Bed] = []
    @State private var labResults: [LabResult] = []
    @State private var isLoadingPatients = false
    @State private var isLoadingBeds = false
    @State private var isLoadingLabResults = false
    @State private var selectedPatient: Patient?

    var body: some View {
        TabView {
            // Patients Tab
            NavigationView {
                ZStack {
                    if isLoadingPatients {
                        ProgressView("Loading Patients...")
                    } else {
                        List(patients) { patient in
                            PatientCardView(
                                patient: patient,
                                onRequestLab: { selectedPatient = patient },
                                onTransferBed: { selectedPatient = patient }
                            )
                            .onTapGesture {
                                selectedPatient = patient
                            }
                        }
                        .listStyle(.plain)
                    }
                }
                .navigationTitle("Patients")
                .refreshable {
                    await fetchPatients()
                }
            }
            .tabItem {
                Label("Patients", systemImage: "person.3")
            }
            .task {
                await fetchPatients()
            }
            .sheet(item: $selectedPatient) { patient in
                PatientDetailView(patient: patient)
            }

            // Beds Tab
            NavigationView {
                ZStack {
                    if isLoadingBeds {
                        ProgressView("Loading Beds...")
                    } else {
                        List(beds) { bed in
                            BedRowView(bed: bed)
                        }
                        .listStyle(.plain)
                    }
                }
                .navigationTitle("Beds")
                .refreshable {
                    await fetchBeds()
                }
            }
            .tabItem {
                Label("Beds", systemImage: "bed.double")
            }
            .task {
                await fetchBeds()
            }

            // Lab Results Tab
            NavigationView {
                ZStack {
                    if isLoadingLabResults {
                        ProgressView("Loading Lab Results...")
                    } else {
                        List(labResults) { result in
                            LabResultRowView(result: result)
                        }
                        .listStyle(.plain)
                    }
                }
                .navigationTitle("Lab Results")
                .refreshable {
                    await fetchLabResults()
                }
            }
            .tabItem {
                Label("Lab Results", systemImage: "testtube.2")
            }
            .task {
                await fetchLabResults()
            }

            // Agent Activity Tab
            AgentActivityView()
                .tabItem {
                    Label("Activity", systemImage: "waveform")
                }
        }
    }

    private func fetchPatients() async {
        isLoadingPatients = true
        defer { isLoadingPatients = false }
        do {
            patients = try await APIService.fetchPatients()
        } catch {
            print("Error fetching patients: \(error)")
        }
    }

    private func fetchBeds() async {
        isLoadingBeds = true
        defer { isLoadingBeds = false }
        do {
            beds = try await APIService.fetchBeds()
        } catch {
            print("Error fetching beds: \(error)")
        }
    }

    private func fetchLabResults() async {
        isLoadingLabResults = true
        defer { isLoadingLabResults = false }
        do {
            labResults = try await APIService.fetchLabResults()
        } catch {
            print("Error fetching lab results: \(error)")
        }
    }
}

// MARK: - Supporting Views
struct BedRowView: View {
    let bed: Bed

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("Room \(bed.room)")
                    .font(.headline)
                Text(bed.isOccupied ? "Occupied" : "Available")
                    .font(.subheadline)
                    .foregroundColor(bed.isOccupied ? .red : .green)
                if let patientId = bed.patient {
                    Text("Patient ID: \(patientId)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
            Circle()
                .fill(bed.isOccupied ? Color.red : Color.green)
                .frame(width: 12, height: 12)
        }
        .padding(.vertical, 8)
    }
}

struct LabResultRowView: View {
    let result: LabResult

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(result.test)
                    .font(.headline)
                Spacer()
                Text(result.status)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Text("Patient ID: \(result.patient)")
                .font(.caption)
                .foregroundColor(.secondary)
            Text(result.timestamp ?? "No date")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
    }
}