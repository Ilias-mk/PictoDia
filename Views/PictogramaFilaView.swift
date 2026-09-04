import SwiftUI

/// Una fila de la agenda: número de paso, pictograma y texto del evento (RF-16).
struct PictogramaFilaView: View {
    let pictograma: Pictograma
    let numero: Int

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("\(numero)")
                    .font(.subheadline)
                    .foregroundStyle(.tertiary)
                Spacer()
            }

            if let url = pictograma.urlImagen {
                AsyncImage(url: url) { imagen in
                    imagen.resizable().scaledToFit()
                } placeholder: {
                    ProgressView()
                }
                .frame(width: 160, height: 160)
            } else {
                // RF-13: ícono genérico cuando no hay pictograma disponible
                Image(systemName: "questionmark.square.dashed")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 160, height: 160)
                    .foregroundStyle(.secondary)
            }

            Text(pictograma.textoAsociado)
                .font(.title2)
                .fontWeight(.medium)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
        )
    }
}
