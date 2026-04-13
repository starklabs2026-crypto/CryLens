import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var appState: AppState

    @State private var babies: [Baby] = []
    @State private var showAddBaby = false
    @State private var newBabyName = ""
    @State private var newBabyDOB = Date()
    @State private var isAdding = false
    @State private var errorMessage: String?

    private let coral = Color(hex: "FF6B6B")

    var body: some View {
        NavigationStack {
            List {
                // User info
                if let user = appState.currentUser {
                    Section {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(user.name)
                                .font(.headline)
                            Text(user.email ?? "")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }

                // Babies
                Section(header: Text("My Babies")) {
                    if babies.isEmpty {
                        Text("No babies added yet")
                            .foregroundStyle(.secondary)
                            .font(.subheadline)
                    } else {
                        ForEach(babies) { baby in
                            HStack {
                                Text(baby.name)
                                    .font(.headline)
                                Spacer()
                                Text(ageString(from: baby.dob))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .onDelete(perform: deleteBabies)
                    }

                    Button {
                        showAddBaby = true
                    } label: {
                        Label("Add Baby", systemImage: "plus.circle.fill")
                            .foregroundStyle(coral)
                    }
                }

                // Account
                Section(header: Text("Account")) {
                    Button(role: .destructive) {
                        appState.logout()
                    } label: {
                        Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                }
            }
            .navigationTitle("Profile")
            .task { await loadBabies() }
            .sheet(isPresented: $showAddBaby) {
                addBabySheet
            }
        }
    }

    // MARK: - Add Baby Sheet

    private var addBabySheet: some View {
        NavigationStack {
            Form {
                Section("Baby Details") {
                    TextField("Name", text: $newBabyName)
                    DatePicker("Date of Birth", selection: $newBabyDOB, displayedComponents: .date)
                }

                if let errorMessage {
                    Text(errorMessage).foregroundStyle(.red).font(.caption)
                }
            }
            .navigationTitle("Add Baby")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showAddBaby = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { Task { await addBaby() } }
                        .disabled(newBabyName.isEmpty || isAdding)
                }
            }
        }
    }

    // MARK: - Helpers

    private func loadBabies() async {
        do {
            babies = try await APIService.shared.getBabies()
        } catch {}
    }

    private func addBaby() async {
        isAdding = true
        let dobString = ISO8601DateFormatter().string(from: newBabyDOB)
        do {
            let baby = try await APIService.shared.createBaby(name: newBabyName, dob: dobString)
            await MainActor.run {
                babies.append(baby)
                newBabyName = ""
                newBabyDOB = Date()
                isAdding = false
                showAddBaby = false
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                isAdding = false
            }
        }
    }

    private func deleteBabies(at offsets: IndexSet) {
        // Remove locally for now — backend delete not in spec
        babies.remove(atOffsets: offsets)
    }

    private func ageString(from dob: String) -> String {
        let iso = ISO8601DateFormatter()
        guard let date = iso.date(from: dob) else { return "" }
        let comps = Calendar.current.dateComponents([.year, .month, .day], from: date, to: Date())
        if let y = comps.year, y > 0 { return "\(y)y" }
        if let m = comps.month, m > 0 { return "\(m)mo" }
        if let d = comps.day { return "\(d)d" }
        return ""
    }
}
