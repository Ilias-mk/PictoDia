import SwiftUI

/// Pantalla de bienvenida para el cuidador. Estilo cálido: no la ve la persona con autismo.
struct WelcomeView: View {

    @AppStorage("haVistoBienvenida") private var haVistoBienvenida = false
    @State private var mostrandoApp = false

    var body: some View {
        if haVistoBienvenida {
            EventoInputView()
        } else {
            contenidoBienvenida
        }
    }

    private var contenidoBienvenida: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.98, green: 0.85, blue: 0.72),
                    Color(red: 0.96, green: 0.72, blue: 0.55),
                    Color(red: 0.95, green: 0.75, blue: 0.78)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            Circle()
                .fill(.white)
                .scaleEffect(1.6)
                .ignoresSafeArea()

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
                    haVistoBienvenida = true
                    mostrandoApp = true
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
        }
        .fullScreenCover(isPresented: $mostrandoApp) {
            EventoInputView()
        }
    }
}

#Preview {
    WelcomeView()
}
