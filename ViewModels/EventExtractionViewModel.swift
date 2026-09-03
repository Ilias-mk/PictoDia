// EventExtractionViewModel.swift
import Foundation

/// Gestiona el estado de la pantalla de entrada: texto, carga, errores y eventos extraídos.
@MainActor
@Observable
final class EventExtractionViewModel {

    var textoEntrada: String = ""
    var eventos: [Evento] = []
    var mensajeError: String?
    var estaCargando: Bool = false

    private let service: EventExtractionService

    init(service: EventExtractionService = EventExtractionService()) {
        self.service = service
    }

    /// RF-02: el envío solo se habilita si hay texto real (ignorando espacios).
    var puedeEnviar: Bool {
        !textoEntrada.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !estaCargando
    }

    /// Invoca la extracción de eventos y actualiza el estado según el resultado.
    func extraer() async {
        guard puedeEnviar else { return }

        estaCargando = true
        mensajeError = nil
        eventos = []

        do {
            eventos = try await service.extraerEventos(desde: textoEntrada)
        } catch let error as EventExtractionError {
            mensajeError = error.errorDescription   // RF-05 y RF-06
        } catch {
            mensajeError = "Ha ocurrido un error inesperado."
        }

        estaCargando = false
    }
}//
//  EventExtractionViewModel.swift
//  PictoDia
//
//  Created by Ilias Mohamed on 2026-09-03.
//

