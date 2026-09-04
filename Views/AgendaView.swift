import SwiftUI

/// Agenda visual: secuencia vertical de pictogramas en orden cronológico (RF-15, RF-17).
struct AgendaView: View {
    let pictogramas: [Pictograma]

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 24) {
                ForEach(Array(pictogramas.enumerated()), id: \.element.id) { indice, pictograma in
                    PictogramaFilaView(pictograma: pictograma, numero: indice + 1)

                    if pictograma.id != pictogramas.last?.id {
                        Image(systemName: "arrow.down")
                            .foregroundStyle(.secondary)
                    }
                }

                Text("Pictogramas: ARASAAC (Gobierno de Aragón), autor Sergio Palao. Licencia CC BY-NC-SA.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.top, 32)
            }
            .padding()
            .navigationTitle("Dagens schema")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}//
//  AgendaView.swift
//  PictoDia
//
//  Created by Ilias Mohamed on 2026-09-03.
//

