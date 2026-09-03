import Foundation

nonisolated struct Pictograma: Identifiable {
    let id: Int              // El ID del pictograma en ARASAAC
    let urlImagen: URL       // Swift tiene un tipo URL propio, no es solo un String
    let textoAsociado: String
}
