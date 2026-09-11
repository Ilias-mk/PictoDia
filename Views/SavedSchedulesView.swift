import SwiftUI

/// List of saved schedules (RF-35, RF-36, RF-37).
struct SavedSchedulesView: View {

    @State private var viewModel = SavedSchedulesViewModel()

    var body: some View {
        ZStack {
            AppBackground(circleScale: 2.1)

            VStack(spacing: 20) {
                Text("Sparade scheman")
                    .font(.system(size: 30, weight: .regular, design: .serif))
                    .foregroundStyle(.black)
                    .padding(.top, 28)

                if viewModel.schedules.isEmpty {
                    Spacer()
                    Text("Du har inga sparade scheman än.")
                        .font(.footnote)
                        .foregroundStyle(Color(white: 0.45))
                    Spacer()
                } else {
                    List {
                        ForEach(viewModel.schedules) { schedule in
                            NavigationLink {
                                ScheduleView(pictograms: schedule.pictograms, allowsSaving: false)   // RF-36
                            } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(schedule.name)
                                        .foregroundStyle(.black)
                                    Text(schedule.savedAt, style: .date)
                                        .font(.caption)
                                        .foregroundStyle(Color(white: 0.5))
                                }
                            }
                            .listRowBackground(Color(white: 0.96))
                        }
                        .onDelete { viewModel.delete(at: $0) }   // RF-37
                    }
                    .scrollContentBackground(.hidden)
                }
            }
        }
        .onAppear { viewModel.load() }
    }
}
