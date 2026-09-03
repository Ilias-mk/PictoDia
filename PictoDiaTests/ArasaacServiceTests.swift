import XCTest
@testable import PictoDia

/// Cliente falso que responde distinto según el idioma que pida la URL.
struct ClienteFalsoPorIdioma: NetworkClient {
    var respuestaSueco: Data
    var respuestaIngles: Data

    func enviar(_ request: URLRequest) async throws -> Data {
        let url = request.url?.absoluteString ?? ""
        return url.contains("/sv/") ? respuestaSueco : respuestaIngles
    }
}

final class ArasaacServiceTests: XCTestCase {

    private let listaVacia = "[]".data(using: .utf8)!

    private func lista(conID id: Int, keyword: String) -> Data {
        """
        [{"_id": \(id), "keywords": [{"keyword": "\(keyword)"}], "schematic": false, "aac": true}]
        """.data(using: .utf8)!
    }

    func testDevuelveResultadosEnSueco() async throws {
        let cliente = ClienteFalsoPorIdioma(
            respuestaSueco: lista(conID: 4626, keyword: "frukost"),
            respuestaIngles: listaVacia
        )
        let service = ArasaacService(cliente: cliente)

        let resultado = try await service.buscarCandidatos(para: "frukost")

        XCTAssertEqual(resultado.count, 1)          // RF-10
        XCTAssertEqual(resultado.first?.id, 4626)
    }

    func testHaceFallbackAInglesCuandoSuecoVieneVacio() async throws {
        let cliente = ClienteFalsoPorIdioma(
            respuestaSueco: listaVacia,
            respuestaIngles: lista(conID: 999, keyword: "breakfast")
        )
        let service = ArasaacService(cliente: cliente)

        let resultado = try await service.buscarCandidatos(para: "frukost")

        XCTAssertEqual(resultado.first?.id, 999)    // RF-11
    }

    func testDevuelveVacioCuandoNoHayEnNingunIdioma() async throws {
        let cliente = ClienteFalsoPorIdioma(respuestaSueco: listaVacia, respuestaIngles: listaVacia)
        let service = ArasaacService(cliente: cliente)

        let resultado = try await service.buscarCandidatos(para: "xyzabc")

        XCTAssertTrue(resultado.isEmpty)            // habilita RF-13
    }

    func testLanzaFalloDeRedCuandoFallaLaPeticion() async {
        let cliente = ClienteFalso(errorALanzar: URLError(.timedOut))
        let service = ArasaacService(cliente: cliente)

        do {
            _ = try await service.buscarCandidatos(para: "frukost")
            XCTFail("Debería haber lanzado falloDeRed")
        } catch {
            XCTAssertEqual(error as? PictogramaError, .falloDeRed)   // RF-14
        }
    }
}//
//  ArasaacServiceTests.swift
//  PictoDia
//
//  Created by Ilias Mohamed on 2026-09-03.
//

