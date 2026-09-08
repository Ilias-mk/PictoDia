import SwiftUI
import UIKit
/// Pantalla de entrada: el cuidador describe el plan del día.
struct EventoInputView: View {

    @State private var viewModel = EventExtractionViewModel()

    var body: some View {
        NavigationStack {
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
                    .scaleEffect(1.9)
                    .ignoresSafeArea()

                VStack(alignment: .center, spacing: 24) {
                    Spacer()
                    Text("Dagens plan")
                        .font(.system(size: 36, weight: .regular, design: .serif))
                        .padding(.top, 24)

                    HStack(spacing: 12) {
                        TextField("T.ex. frukost, sedan skola...", text: $viewModel.textoEntrada, axis: .vertical)
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color(.secondarySystemBackground))
                            )
                            .lineLimit(3, reservesSpace: true)

                        Button {
                            Task { await viewModel.alternarDictado() }
                        } label: {
                            Image(systemName: viewModel.estaDictando ? "stop.circle.fill" : "mic.fill")
                                .font(.title2)
                                .foregroundStyle(viewModel.estaDictando ? .red : .primary)
                                .frame(width: 52, height: 52)
                                .background(Circle().fill(.white).shadow(color: .black.opacity(0.08), radius: 8, y: 2))
                        }
                    }
                    Button {
                        Task { await viewModel.generarAgenda() }
                    } label: {
                        Text("SKAPA SCHEMA")
                            .font(.footnote)
                            .fontWeight(.medium)
                            .tracking(1.2)
                            .foregroundStyle(viewModel.puedeEnviar ? .primary : .tertiary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(
                                Capsule()
                                    .fill(.white)
                                    .shadow(color: .black.opacity(viewModel.puedeEnviar ? 0.08 : 0), radius: 12, y: 4)
                            )
                    }
                    .disabled(!viewModel.puedeEnviar)   // RF-02

                    
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)

                    if viewModel.estaCargando {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    }

                    if let mensaje = viewModel.mensajeError {
                        Text(mensaje)
                            .foregroundStyle(.red)
                            .font(.callout)
                    }

                  Spacer()
                }
                .padding(28)
            }
            .navigationDestination(isPresented: $viewModel.mostrandoAgenda) {
                AgendaView(pictogramas: viewModel.pictogramas)
            }
            .alert(
                "Dictado no disponible",
                isPresented: Binding(
                    get: { viewModel.errorDictado != nil },
                    set: { if !$0 { viewModel.errorDictado = nil } }
                ),
                presenting: viewModel.errorDictado
            ) { error in
                if error.ofreceAjustes {
                    Button("Ir a Ajustes") {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)   // RF-30
                        }
                    }
                }
                Button("Entendido", role: .cancel) { }
            } message: { error in
                Text(error.errorDescription ?? "")
            }
        }
    }
}

#Preview {
    EventoInputView()
}
