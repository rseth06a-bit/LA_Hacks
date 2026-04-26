import SwiftUI

struct DashboardView: View {
    @State private var patients: [Patient] = []
    @State private var beds: [Bed] = []
    @State private var labResults: [LabResult] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var actionMessage: String?
    @State private var showingAlert = false
    @State private var selectedTab = 0
    @State private var activeFlow: PatientActionFlow?

    enum PatientActionFlow: Identifiable {
        case lab(Patient)
        case transfer(Patient)

        var id: String {
            switch self {
            case .lab(let patient): return "lab-\(patient.id)"
            case .transfer(let patient): return "transfer-\(patient.id)"
            }
        }
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            patientsTab
                .tabItem { Label("Patients", systemImage: "person.3") }
                .tag(0)

            BedsView(beds: beds, patients: patients)
                .tabItem { Label("Beds", systemImage: "bed.double") }
                .tag(1)

            LabResultsView(labResults: labResults, patients: patients)
                .tabItem { Label("Lab", systemImage: "flask") }
                .tag(2)

            AgentActivityView()
                .tabItem { Label("Activity", systemImage: "waveform.path.ecg") }
                .tag(3)
        }
        .task {
            await loadAllData()
        }
        .sheet(item: $activeFlow) { flow in
            switch flow {
            case .lab(let patient):
                LabFlowSheet(patient: patient) { selectedTest in
                    await triggerScheduling(for: patient, testType: selectedTest)
                }
            case .transfer(let patient):
                TransferFlowSheet(patient: patient) { await triggerTransfer(for: patient) }
            }
        }
        .alert(isPresented: $showingAlert) {
            Alert(
                title: Text("Agent Trigger"),
                message: Text(actionMessage ?? "Action completed."),
                dismissButton: .default(Text("OK"))
            )
        }
    }

    private var patientsTab: some View {
        NavigationView {
            Group {
                if isLoading {
                    ProgressView("Loading patients...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let errorMessage {
                    VStack(spacing: 16) {
                        Text("Unable to load patients")
                            .font(.title3.weight(.semibold))
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        Button("Retry") {
                            Task { await loadAllData() }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("\(patients.count) active patients")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 14)

                            ForEach(patients) { patient in
                                PatientCardView(
                                    patient: patient,
                                    onRequestLab: { activeFlow = .lab(patient) },
                                    onTransferBed: { activeFlow = .transfer(patient) },
                                    onScheduleAppointment: {
                                        Task {
                                            await triggerScheduling(for: patient, testType: "Follow-up Appointment")
                                        }
                                    }
                                )
                                .padding(.horizontal, 10)
                            }
                        }
                        .padding(.top, 12)
                    }
                }
            }
            .background(Color(nsColor: .windowBackgroundColor))
            .navigationTitle("Patients")
            .toolbar {
                ToolbarItem(placement: .navigation) {
                    Button(action: { Task { await loadAllData() } }) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
        }
    }

    private func loadAllData() async {
        isLoading = true
        errorMessage = nil
        do {
            patients = try await APIService.fetchPatients()
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
            return
        }

        do {
            beds = try await APIService.fetchBeds()
        } catch {
            beds = []
        }

        do {
            labResults = try await APIService.fetchLabResults()
        } catch {
            labResults = []
        }
        isLoading = false
    }

    private func triggerScheduling(for patient: Patient, testType: String) async {
        do {
            let payload: [String: String] = [
                "patient_id": patient.id,
                "patient_name": patient.name,
                "test_type": testType,
                "priority": patient.priority.rawValue
            ]
            let response = try await APIService.triggerAgent(type: "scheduling", payload: payload)
            actionMessage = response.message
            await loadAllData()
        } catch {
            actionMessage = "Unable to trigger scheduling flow: \(error.localizedDescription)"
        }
        showingAlert = true
    }

    private func triggerTransfer(for patient: Patient) async {
        do {
            let payload: [String: String] = [
                "patient_id": patient.id,
                "patient_name": patient.name,
                "current_room": patient.room
            ]
            let response = try await APIService.triggerAgent(type: "bed", payload: payload)
            actionMessage = response.message
            await loadAllData()
        } catch {
            actionMessage = "Unable to trigger bed flow: \(error.localizedDescription)"
        }
        showingAlert = true
    }
}

private struct LabFlowSheet: View {
    let patient: Patient
    let onConfirm: (String) async -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTest = "Complete Blood Count (CBC)"
    @State private var stage = 0
    private let tests = ["Complete Blood Count (CBC)", "Metabolic Panel", "Lipid Panel", "Urinalysis", "Thyroid Panel", "Liver Function Test"]

    var body: some View {
        VStack(spacing: 16) {
            if stage == 0 {
                Text("Choose Lab Test")
                    .font(.headline)
                Picker("Test", selection: $selectedTest) {
                    ForEach(tests, id: \.self) { Text($0).tag($0) }
                }
                .pickerStyle(.menu)
                .frame(maxWidth: .infinity, alignment: .leading)
                Button("Find Available Slots") {
                    stage = 1
                    Task {
                        try? await Task.sleep(nanoseconds: 1_200_000_000)
                        stage = 2
                    }
                }
                .buttonStyle(.borderedProminent)
            } else if stage == 1 {
                ProgressView()
                Text("Finding available slots...")
                    .font(.headline)
                Text("Checking lab availability")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            } else {
                Text("Select Time Slot")
                    .font(.headline)
                VStack(alignment: .leading, spacing: 8) {
                    Text("Today 2:30 PM - Lab Wing B")
                    Text("Today 4:00 PM - Lab Wing A")
                    Text("Tomorrow 9:00 AM - Lab Wing B")
                }
                .font(.subheadline)
                .frame(maxWidth: .infinity, alignment: .leading)
                Button("Confirm Booking") {
                    Task {
                        await onConfirm(selectedTest)
                        dismiss()
                    }
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(20)
        .frame(width: 320)
    }
}

private struct TransferFlowSheet: View {
    let patient: Patient
    let onConfirm: () async -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var stage = 0

    var body: some View {
        VStack(spacing: 16) {
            if stage == 0 {
                Image(systemName: "bed.double.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.blue)
                Text("Transfer Bed")
                    .font(.headline)
                Text("\(patient.name) • Room \(patient.room)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Button("Find Available Beds") {
                    stage = 1
                    Task {
                        try? await Task.sleep(nanoseconds: 1_200_000_000)
                        stage = 2
                    }
                }
                .buttonStyle(.borderedProminent)
            } else if stage == 1 {
                ProgressView()
                Text("Scanning availability...")
                    .font(.headline)
                Text("Checking occupancy and cleaning status")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            } else {
                Text("Select Destination")
                    .font(.headline)
                VStack(alignment: .leading, spacing: 8) {
                    Text("Room 205A - Available now")
                    Text("Room 310B - In 20 min")
                }
                .font(.subheadline)
                .frame(maxWidth: .infinity, alignment: .leading)
                Button("Confirm Transfer") {
                    Task {
                        await onConfirm()
                        dismiss()
                    }
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(20)
        .frame(width: 320)
    }
}
