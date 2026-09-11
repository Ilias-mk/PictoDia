import SwiftUI

/// Lets the caregiver write and save a description of the person.
struct ProfileView: View {

    @State private var text: String = ""
    @State private var saved = false
    private let store = ProfileStore()

    var body: some View {
        ZStack {
            AppBackground(circleScale: 2.1)

            VStack(spacing: 20) {
                Text("Profil")
                    .font(.system(size: 32, weight: .regular, design: .serif))
                    .foregroundStyle(.black)

                Text("Beskriv vad den som arbetar med barnet behöver veta.")
                    .font(.footnote)
                    .foregroundStyle(Color(white: 0.45))
                    .multilineTextAlignment(.center)

                TextEditor(text: $text)
                    .scrollContentBackground(.hidden)
                    .padding(12)
                    .frame(height: 260)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color(white: 0.94))
                    )
                    .foregroundStyle(.black)

                Button {
                    store.save(text)
                    saved = true
                } label: {
                    Text(saved ? "SPARAT" : "SPARA")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .tracking(1.2)
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            Capsule()
                                .fill(.white)
                                .shadow(color: .black.opacity(0.08), radius: 12, y: 4)
                        )
                }
            }
            .padding(28)
        }
        .onAppear { text = store.load() }
        .onChange(of: text) { saved = false }
    }
}
