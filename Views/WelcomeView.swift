import SwiftUI

/// Pantalla de bienvenida para el cuidador. Estilo cálido: no la ve la persona con autismo.
struct WelcomeView: View {

    @AppStorage("haVistoBienvenida") private var hasSeenWelcome = false
    @State private var showingApp = false

    var body: some View {
        if hasSeenWelcome {
            MenuView()
        } else {
            welcomeContent
        }
    }

    private var welcomeContent: some View {
        ZStack {
            AppBackground()

            VStack(spacing: 32) {
                HStack(spacing: 8) {
                    Image(systemName: "calendar.badge.clock")
                        .font(.title3)
                    Text("PictoDia")
                        .font(.title3)
                        .fontWeight(.medium)
                }

                Text("Välkommen.\nDagens plan,\ni bilder.")
                    .font(.system(size: 44, weight: .regular, design: .serif))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)

                Button {
                    hasSeenWelcome = true
                    showingApp = true
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "arrow.right")
                        Text("KOM IGÅNG")
                            .font(.footnote)
                            .fontWeight(.medium)
                            .tracking(1.2)
                    }
                    .foregroundStyle(.primary)
                    .padding(.vertical, 18)
                    .padding(.horizontal, 40)
                    .background(
                        Capsule()
                            .fill(.white)
                            .shadow(color: .black.opacity(0.08), radius: 12, y: 4)
                    )
                }
                .padding(.top, 16)
            }
            .padding()
            .foregroundStyle(.black)
        }
        .fullScreenCover(isPresented: $showingApp) {
            MenuView()
        }
    }
}

#Preview {
    WelcomeView()
}
