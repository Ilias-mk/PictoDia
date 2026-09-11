import SwiftUI

/// Visual schedule: vertical pictogram sequence in chronological order (RF-15, RF-17).
struct ScheduleView: View {
    let pictograms: [Pictogram]
    /// False when showing an already-saved schedule: it can't be saved again.
    var allowsSaving: Bool = true

    @State private var askingName = false
    @State private var confirmingOverwrite = false
    @State private var limitWarning = false
    @State private var name = ""
    @State private var saved = false

    private let store = ScheduleStore()

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 24) {
                ForEach(Array(pictograms.enumerated()), id: \.element.id) { index, pictogram in
                    PictogramRowView(pictogram: pictogram, number: index + 1)

                    if pictogram.id != pictograms.last?.id {
                        Image(systemName: "arrow.down")
                            .foregroundStyle(.secondary)
                    }
                }

                if allowsSaving {
                    Button {
                        name = ""
                        askingName = true
                    } label: {
                        Text(saved ? "SPARAT" : "SPARA SCHEMA")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .tracking(1.2)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(Capsule().fill(Color(.secondarySystemBackground)))
                    }
                    .padding(.top, 24)   // RF-32
                }

                Text("Pictograms: ARASAAC (Government of Aragón), author Sergio Palao. CC BY-NC-SA.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.top, 32)
            }
            .padding()
        }
        .navigationTitle("Dagens schema")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Namn på schemat", isPresented: $askingName) {
            TextField("T.ex. Skoldag", text: $name)
            Button("Avbryt", role: .cancel) { }
            Button("Spara") { attemptSave() }   // RF-33
        }
        .alert("Namnet finns redan", isPresented: $confirmingOverwrite) {
            Button("Avbryt", role: .cancel) { }
            Button("Skriv över") { save() }      // RF-34
        } message: {
            Text("Vill du ersätta det sparade schemat med detta?")
        }
        .alert("Max antal nått", isPresented: $limitWarning) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Du har \(ScheduleStore.maxSchedules) sparade scheman. Ta bort ett för att spara ett nytt.")   // RF-39
        }
    }

    /// Decides between saving, asking for confirmation, or warning about the limit.
    private func attemptSave() {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        if store.limitReached(for: trimmed) {
            limitWarning = true
        } else if store.nameExists(trimmed) {
            confirmingOverwrite = true
        } else {
            save()
        }
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        store.save(SavedSchedule(name: trimmed, pictograms: pictograms))
        saved = true
    }
}
