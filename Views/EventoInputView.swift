// EventoInputView.swift
import SwiftUI

/// Pantalla mínima de verificación: entrada de texto y lista de eventos extraídos.
struct EventoInputView: View {

    @State private var viewModel = EventExtractionViewModel()

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {

            Text("Beskriv dagens plan")
                .font(.headline)

            TextField("T.ex. frukost, sedan skola...", text: $viewModel.textoEntrada, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(3, reservesSpace: true)

            Button("Skapa schema") {
                Task { await viewModel.extraer() }
            }
            .buttonStyle(.borderedProminent)
            .disabled(!viewModel.puedeEnviar)   // RF-02

            if viewModel.estaCargando {
                ProgressView()
            }

            if let mensaje = viewModel.mensajeError {
                Text(mensaje)
                    .foregroundStyle(.red)
                    .font(.callout)
            }

            List(viewModel.eventos) { evento in
                Text(evento.descripcion)
            }
            .listStyle(.plain)

            Spacer()
        }
        .padding()
    }
}

#Preview {
    EventoInputView()
}//
//  EventoInputView.swift
//  PictoDia
//
//  Created by Ilias Mohamed on 2026-09-03.
//

