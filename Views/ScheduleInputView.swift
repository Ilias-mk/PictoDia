import SwiftUI
import UIKit

/// Input screen: the caregiver describes the day's plan.
struct ScheduleInputView: View {

    @State private var viewModel = ScheduleViewModel()

    var body: some View {
        ZStack {
            AppBackground(circleScale: 1.9)

            VStack(alignment: .center, spacing: 24) {
                Spacer()

                Text("Dagens plan")
                    .font(.system(size: 36, weight: .regular, design: .serif))
                    .foregroundStyle(.black)

                Text("Berätta kort vad som ska hända idag. Appen delar upp planen i steg och visar den som bilder.")
                    .font(.footnote)
                    .foregroundStyle(Color(white: 0.45))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)

                TextField("T.ex. frukost, sedan skola...", text: $viewModel.inputText, axis: .vertical)
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color(white: 0.94))
                    )
                    .foregroundStyle(.black)
                    .lineLimit(5, reservesSpace: true)

                Button {
                    Task { await viewModel.toggleDictation() }
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: viewModel.isDictating ? "stop.circle.fill" : "mic.fill")
                        Text(viewModel.isDictating ? "STOPPA" : "DIKTERA")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .tracking(1.2)
                    }
                    .foregroundStyle(viewModel.isDictating ? .red : .black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        Capsule()
                            .fill(.white)
                            .shadow(color: .black.opacity(0.08), radius: 12, y: 4)
                    )
                }

                Button {
                    Task { await viewModel.generateSchedule() }
                } label: {
                    Text("SKAPA SCHEMA")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .tracking(1.2)
                        .foregroundStyle(viewModel.canSubmit ? .black : Color(white: 0.6))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            Capsule()
                                .fill(.white)
                                .shadow(color: .black.opacity(viewModel.canSubmit ? 0.08 : 0), radius: 12, y: 4)
                        )
                }
                .disabled(!viewModel.canSubmit)   // RF-02

                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                }

                if let message = viewModel.errorMessage {
                    Text(message)
                        .foregroundStyle(.red)
                        .font(.callout)
                }

                Spacer()
            }
            .padding(28)
        }
        .navigationDestination(isPresented: $viewModel.showingSchedule) {
            ScheduleView(pictograms: viewModel.pictograms)
        }
        .alert(
            "Diktering inte tillgänglig",
            isPresented: Binding(
                get: { viewModel.dictationError != nil },
                set: { if !$0 { viewModel.dictationError = nil } }
            ),
            presenting: viewModel.dictationError
        ) { error in
            if error.offersSettings {
                Button("Öppna inställningar") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)   // RF-30
                    }
                }
            }
            Button("OK", role: .cancel) { }
        } message: { error in
            Text(error.errorDescription ?? "")
        }
    }
}
