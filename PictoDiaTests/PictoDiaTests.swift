import XCTest
@testable import PictoDia

/// Cliente falso que devuelve datos o errores predefinidos, sin salir a internet.
struct ClienteFalso: NetworkClient {
    var datosADevolver: Data?
    var errorALanzar: Error?

    func enviar(_ request: URLRequest) async throws -> Data {
        if let error = errorALanzar { throw error }
        return datosADevolver ?? Data()
    }
}

final class EventExtractionServiceTests: XCTestCase {

    /// Construye una respuesta de la API con el JSON que el LLM devolvería.
    private func respuestaAPI(conJSON json: String) -> Data {
        let escapado = json.replacingOccurrences(of: "\"", with: "\\\"")
        return """
        {"content": [{"type": "text", "text": "\(escapado)"}]}
        """.data(using: .utf8)!
    }

    func testExtraeEventosOrdenados() async throws {
        let json = """
        {"eventos": [{"descripcion": "Läkarbesök", "ordenSugerido": 1}, {"descripcion": "Frukost", "ordenSugerido": 0}]}
        """
        let cliente = ClienteFalso(datosADevolver: respuestaAPI(conJSON: json))
        let service = EventExtractionService(cliente: cliente)

        let eventos = try await service.extraerEventos(desde: "Vi ska till läkaren, men först frukost")

        XCTAssertEqual(eventos.count, 2)
        XCTAssertEqual(eventos[0].descripcion, "Frukost")   // RF-04: orden inferido
        XCTAssertEqual(eventos[1].descripcion, "Läkarbesök")
    }

    func testLanzaSinConexionCuandoFallaLaRed() async {
        let cliente = ClienteFalso(errorALanzar: URLError(.notConnectedToInternet))
        let service = EventExtractionService(cliente: cliente)

        do {
            _ = try await service.extraerEventos(desde: "Frukost sedan skola")
            XCTFail("Debería haber lanzado sinConexion")
        } catch {
            XCTAssertEqual(error as? EventExtractionError, .sinConexion) // RF-06
        }
    }

    func testLanzaSinEventosCuandoLaListaVieneVacia() async {
        let cliente = ClienteFalso(datosADevolver: respuestaAPI(conJSON: #"{"eventos": []}"#))
        let service = EventExtractionService(cliente: cliente)

        do {
            _ = try await service.extraerEventos(desde: "asdfgh")
            XCTFail("Debería haber lanzado sinEventosDetectados")
        } catch {
            XCTAssertEqual(error as? EventExtractionError, .sinEventosDetectados) // RF-05
        }
    }

    func testRecortaAMaximoSieteEventos() async throws {
        let eventosJSON = (0..<10).map { #"{"descripcion": "Evento \#($0)", "ordenSugerido": \#($0)}"# }.joined(separator: ", ")
        let cliente = ClienteFalso(datosADevolver: respuestaAPI(conJSON: #"{"eventos": [\#(eventosJSON)]}"#))
        let service = EventExtractionService(cliente: cliente)

        let eventos = try await service.extraerEventos(desde: "En lång dag")

        XCTAssertEqual(eventos.count, 7) // RF-07 / RF-08
    }
}
