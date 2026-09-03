import Foundation

nonisolated struct Pictograma: Identifiable {
    let id: Int              // El ID del pictograma en ARASAAC
    let urlImagen: URL?      // Ahora opcional: nil cuando es el ícono genérico
    let textoAsociado: String
    let esGenerico: Bool     // RF-13: true si no se encontró pictograma real
}
