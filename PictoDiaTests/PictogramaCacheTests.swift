import XCTest
@testable import PictoDia

final class PictogramaCacheTests: XCTestCase {

    /// UserDefaults aislado, para no tocar los reales de la app.
    private var defaults: UserDefaults!
    private var cache: UserDefaultsPictogramaCache!

    override func setUp() {
        super.setUp()
        let nombre = "test-\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: nombre)!
        cache = UserDefaultsPictogramaCache(defaults: defaults)
    }

    func testDevuelveNilCuandoNuncaSeBusco() {
        XCTAssertNil(cache.obtener(para: "frukost"))
    }

    func testGuardaYRecuperaUnID() {
        cache.guardar(.encontrado(id: 4626), para: "frukost")

        XCTAssertEqual(cache.obtener(para: "frukost"), .encontrado(id: 4626))   // RF-18
    }

    func testNormalizaMayusculasYEspacios() {
        cache.guardar(.encontrado(id: 4626), para: "frukost")

        XCTAssertEqual(cache.obtener(para: "  FRUKOST "), .encontrado(id: 4626))   // RF-20
    }

    func testGuardaResultadoNegativo() {
        cache.guardar(.noHayPictograma, para: "xyzabc")

        XCTAssertEqual(cache.obtener(para: "xyzabc"), .noHayPictograma)   // RF-22
    }

    func testDistingueNegativoDeNoBuscado() {
        cache.guardar(.noHayPictograma, para: "xyzabc")

        XCTAssertNotNil(cache.obtener(para: "xyzabc"))     // sí está cacheado
        XCTAssertNil(cache.obtener(para: "otracosa"))      // nunca se buscó
    }

    func testPersisteEntreInstancias() {
        cache.guardar(.encontrado(id: 999), para: "skola")

        let otraInstancia = UserDefaultsPictogramaCache(defaults: defaults)

        XCTAssertEqual(otraInstancia.obtener(para: "skola"), .encontrado(id: 999))   // RF-23
    }
}//
//  PictogramaCacheTests.swift
//  PictoDia
//
//  Created by Ilias Mohamed on 2026-09-04.
//

