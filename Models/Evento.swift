import Foundation

// En Swift usamos "struct" en vez de "class" para modelos de datos simples.
// Un struct es como una clase de Java, pero se copia por valor (no por referencia).
nonisolated struct Evento: Identifiable {
    let id = UUID()          // UUID genera un identificador único, como usarías un String id en Java
    var orden: Int           // "var" = puede cambiar (como una variable normal en Java)
    var descripcion: String  // "let" = constante (como "final" en Java)
    var horaAproximada: String?  // El "?" significa que puede ser nil (null). Se llama "Optional"
}
