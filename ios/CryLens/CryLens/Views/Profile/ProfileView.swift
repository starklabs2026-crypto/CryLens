import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var appState: AppState

    @State private var babies: [Baby] = []
    @State private var showAddBaby = false
    @State private var newBabyName = ""
    @State private var newBabyDOB = Date()
    @State private var isAdding = false
    @State private var addError: String?

    // Edit baby state
    @State private var editingBaby: Baby?
    @State private var editName = ""
    @State private var editDOB = Date()
    @State private var isSavingEdit = false
    @State private var editError: String?

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
                            if let email = user.email, !email.isEmpty {
                                Text(email)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
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
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(baby.name).font(.headline)
                                    Text(ageString(from: baby.dob))
                                        .font(.caption).foregroundStyle(.secondary)
                                }
                                Spacer()
                                Button {
                                    startEditing(baby)
                                } label: {
                                    Image(systemName: "pencil.circle")
                                        .foregroundStyle(coral)
                                        .font(.title3)
                                }
                                .buttonStyle(.plain)
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
            .sheet(isPresented: $showAddBaby) { addBabySheet }
            .sheet(item: $editingBaby) { _ in editBabySheet }
        }
    }

    // MARK: - Add Baby Sheet

    private var addBabySheet: some View {
        NavigationStack {
            Form {
                Section("Baby Details") {
                    TextField("Name", text: $newBabyName)
                    DatePicker("Date of Birth", selection: $newBabyDOB,
                               in: ...Date(), displayedComponents: .date)
                }
                if let addError {
                    Text(addError).foregroundStyle(.red).font(.caption)
                }
            }
            .navigationTitle("Add Baby")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showAddBaby = false
                        newBabyName = ""; addError = nil
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { Task { await addBaby() } }
                        .disabled(newBabyName.isEmpty || isAdding)
                }
            }
        }
    }

    // MARK: - Edit Baby Sheet

    private var editBabySheet: some View {
        NavigationStack {
            Form {
                Section("Baby Details") {
                    TextField("Name", text: $editName)
                    DatePicker("Date of Birth", selection: $editDOB,
                               in: ...Date(), displayedComponents: .date)
                }
                if let editError {
                    Text(editError).foregroundStyle(.red).font(.caption)
                }
            }
            .navigationTitle("Edit Baby")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { editingBaby = nil; editError = nil }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { Task { await saveEdit() } }
                        .disabled(editName.isEmpty || isSavingEdit)
                }
            }
        }
    }

    // MARK: - Helpers

    private func loadBabies() async {
        do { babies = try await APIService.shared.getBabies() } catch {}
    }

    private func addBaby() async {
        isAdding = true; addError = nil
        let dobString = ISO8601DateFormatter().string(from: newBabyDOB)
        do {
            let baby = try await APIService.shared.createBaby(name: newBabyName, dob: dobString)
            await MainActor.run {
                babies.append(baby)
                newBabyName = ""; newBabyDOB = Date()
                isAdding = false; showAddBaby = false
            }
        } catch {
            await MainActor.run { addError = error.localizedDescription; isAdding = false }
        }
    }

    private func startEditing(_ baby: Baby) {
        editName = baby.name
        editDOB = ISO8601DateFormatter().date(from: baby.dob) ?? Date()
        editError = nil
        editingBaby = baby
    }

    private func saveEdit() async {
        guard let baby = editingBaby else { return }
        isSavingEdit = true; editError = nil
        let dobString = ISO8601DateFormatter().string(from: editDOB)
        do {
            let updated = try await APIService.shared.updateBaby(id: baby.id, name: editName, dob: dobString)
            await MainActor.run {
                if let idx = babies.firstIndex(where: { $0.id == baby.id }) {
                    babies[idx] = updated
                }
                isSavingEdit = false
                editingBaby = nil
            }
        } catch {
            await MainActor.run { editError = error.localizedDescription; isSavingEdit = false }
        }
    }

    private func deleteBabies(at offsets: IndexSet) {
        let toDelete = offsets.map { babies[$0] }
        babies.remove(atOffsets: offsets)
        Task {
            for baby in toDelete {
                try? await APIService.shared.deleteBaby(id: baby.id)
            }
        }
    }

    private func ageString(from dob: String) -> String {
        let iso = ISO8601DateFormatter()
        guard let date = iso.date(from: dob) else { return dob }
        let comps = Calendar.current.dateComponents([.year, .month, .day], from: date, to: Date())
        if let y = comps.year, y > 0 { return "\(y) yr\(y == 1 ? "" : "s") old" }
        if let m = comps.month, m > 0 { return "\(m) mo old" }
        if let d = comps.day { return "\(d) day\(d == 1 ? "" : "s") old" }
        return ""
    }
}
