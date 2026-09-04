import SwiftUI

/// Pantalla de entrada: el cuidador describe el plan del día.
struct EventoInputView: View {

    @State private var viewModel = EventExtractionViewModel()

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {

                Text("Beskriv dagens plan")
                    .font(.headline)

                TextField("T.ex. frukost, sedan skola...", text: $viewModel.textoEntrada, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(3, reservesSpace: true)

                Button("Skapa schema") {
                    Task { await viewModel.generarAgenda() }
                }
                .buttonStyle(.borderedProminent)
                .disabled(!viewModel.puedeEnviar)   // RF-02

                Button("Testa med fasta händelser") {
                    Task { await viewModel.generarAgendaDePrueba() }
                }
                .buttonStyle(.bordered)

                if viewModel.estaCargando {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                }

                if let mensaje = viewModel.mensajeError {
                    Text(mensaje)
                        .foregroundStyle(.red)
                        .font(.callout)
                }

                if viewModel.pictogramas.isEmpty && !viewModel.estaCargando {
                    VStack(spacing: 12) {
                        Image(systemName: "calendar.badge.clock")
                            .font(.system(size: 48))
                            .foregroundStyle(.tertiary)
                        Text("Beskriv dagens plan för att skapa ett schema")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 40)
                }

                Spacer()
            }
            .padding()
            .navigationTitle("PictoDia")
            .navigationDestination(isPresented: $viewModel.mostrandoAgenda) {
                AgendaView(pictogramas: viewModel.pictogramas)
            }
        }
    }
}

#Preview {
    EventoInputView()
}
