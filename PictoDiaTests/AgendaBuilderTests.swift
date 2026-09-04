import XCTest
@testable import PictoDia

/// Cliente falso que decide qué devolver según el host de la petición.
struct ClienteFalsoMixto: NetworkClient {
    var respuestaArasaac: Data
    var respuestaLLM: Data
    var errorArasaac: Error?

    func enviar(_ request: URLRequest) async throws -> Data {
        let url = request.url?.absoluteString ?? ""
        if url.contains("arasaac") {
            if let error = errorArasaac { throw error }
            return respuestaArasaac
        }
        return respuestaLLM
    }
}

/// Caché en memoria que además cuenta accesos, para verificar que se usa.
final class CacheFalsa: PictogramaCache {
    private var mapa: [String: ResultadoCache] = [:]
    private(set) var guardados = 0

    init(inicial: [String: ResultadoCache] = [:]) {
        self.mapa = inicial
    }

    func obtener(para evento: String) -> ResultadoCache? {
        mapa[evento.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()]
    }

    func guardar(_ resultado: ResultadoCache, para evento: String) {
        mapa[evento.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()] = resultado
        guardados += 1
    }
}

final class AgendaBuilderTests: XCTestCase {

    private let eventos = [Evento(orden: 0, descripcion: "Frukost", horaAproximada: nil)]

    private func respuestaLLM(_ json: String) -> Data {
        let escapado = json.replacingOccurrences(of: "\"", with: "\\\"")
        return #"{"content": [{"type": "text", "text": "\#(escapado)"}]}"#.data(using: .utf8)!
    }

    private let dosCandidatos = """
    [{"_id": 4626, "keywords": [{"keyword": "frukost"}], "schematic": false, "aac": true},
     {"_id": 7012, "keywords": [{"keyword": "frukost"}], "schematic": true, "aac": false}]
    """.data(using: .utf8)!

    func testConstruyePictogramaConElIdElegidoPorElLLM() async throws {
        let cliente = ClienteFalsoMixto(
            respuestaArasaac: dosCandidatos,
            respuestaLLM: respuestaLLM(#"{"Frukost": 7012}"#)
        )
        let builder = AgendaBuilder(
            arasaac: ArasaacService(cliente: cliente),
            seleccion: PictogramaSelectionService(cliente: cliente),
            cache: CacheFalsa()
        )

        let pictogramas = try await builder.construir(desde: eventos)

        XCTAssertEqual(pictogramas[0].id, 7012)          // RF-12
        XCTAssertFalse(pictogramas[0].esGenerico)
    }

    func testUsaGenericoCuandoNoHayCandidatos() async throws {
        let cliente = ClienteFalsoMixto(
            respuestaArasaac: "[]".data(using: .utf8)!,
            respuestaLLM: respuestaLLM("{}")
        )
        let builder = AgendaBuilder(
            arasaac: ArasaacService(cliente: cliente),
            seleccion: PictogramaSelectionService(cliente: cliente),
            cache: CacheFalsa()
        )

        let pictogramas = try await builder.construir(desde: eventos)

        XCTAssertTrue(pictogramas[0].esGenerico)         // RF-13
        XCTAssertNil(pictogramas[0].urlImagen)
    }

    func testLanzaFalloDeRedSinResultadosParciales() async {
        let cliente = ClienteFalsoMixto(
            respuestaArasaac: Data(),
            respuestaLLM: Data(),
            errorArasaac: URLError(.notConnectedToInternet)
        )
        let builder = AgendaBuilder(
            arasaac: ArasaacService(cliente: cliente),
            seleccion: PictogramaSelectionService(cliente: cliente),
            cache: CacheFalsa()
        )

        do {
            _ = try await builder.construir(desde: eventos)
            XCTFail("Debería haber lanzado falloDeRed")
        } catch {
            XCTAssertEqual(error as? PictogramaError, .falloDeRed)   // RF-14
        }
    }

    /// Si el evento está cacheado, no debe tocar la red en absoluto.
    func testUsaCacheSinLlamarALaRed() async throws {
        let clienteQueFalla = ClienteFalsoMixto(
            respuestaArasaac: Data(),
            respuestaLLM: Data(),
            errorArasaac: URLError(.notConnectedToInternet)
        )
        let cache = CacheFalsa(inicial: ["frukost": .encontrado(id: 4626)])
        let builder = AgendaBuilder(
            arasaac: ArasaacService(cliente: clienteQueFalla),
            seleccion: PictogramaSelectionService(cliente: clienteQueFalla),
            cache: cache
        )

        let pictogramas = try await builder.construir(desde: eventos)

        XCTAssertEqual(pictogramas[0].id, 4626)   // RF-19: resuelto desde caché
        XCTAssertEqual(cache.guardados, 0)        // no reescribió nada
    }

    /// Con eventos mixtos, solo busca los no cacheados.
    func testSoloBuscaLosNoCacheados() async throws {
        let cliente = ClienteFalsoMixto(
            respuestaArasaac: dosCandidatos,
            respuestaLLM: respuestaLLM(#"{"Skola": 4626}"#)
        )
        let cache = CacheFalsa(inicial: ["frukost": .encontrado(id: 111)])
        let builder = AgendaBuilder(
            arasaac: ArasaacService(cliente: cliente),
            seleccion: PictogramaSelectionService(cliente: cliente),
            cache: cache
        )

        let mixtos = [
            Evento(orden: 0, descripcion: "Frukost", horaAproximada: nil),
            Evento(orden: 1, descripcion: "Skola", horaAproximada: nil)
        ]
        let pictogramas = try await builder.construir(desde: mixtos)

        XCTAssertEqual(pictogramas[0].id, 111)    // vino de caché
        XCTAssertEqual(pictogramas[1].id, 4626)   // vino de la red
        XCTAssertEqual(cache.guardados, 1)        // RF-21: solo guardó el nuevo
    }
}
