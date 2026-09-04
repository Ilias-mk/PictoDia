import Foundation

/// Gestiona el estado de la pantalla: texto, carga, errores, eventos y agenda visual.
@MainActor
@Observable
final class EventExtractionViewModel {

    var textoEntrada: String = ""
    var eventos: [Evento] = []
    var pictogramas: [Pictograma] = []
    var mensajeError: String?
    var estaCargando: Bool = false
    var mostrandoAgenda: Bool = false

    private let service: EventExtractionService
    private let builder: AgendaBuilder

    init(service: EventExtractionService = EventExtractionService(),
         builder: AgendaBuilder = AgendaBuilder()) {
        self.service = service
        self.builder = builder
    }

    /// RF-02: el envío solo se habilita si hay texto real (ignorando espacios).
    var puedeEnviar: Bool {
        !textoEntrada.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !estaCargando
    }

    /// Extrae los eventos y construye la agenda visual completa.
    func generarAgenda() async {
        guard puedeEnviar else { return }

        estaCargando = true
        mensajeError = nil
        eventos = []
        pictogramas = []

        do {
            let extraidos = try await service.extraerEventos(desde: textoEntrada)
            eventos = extraidos
            pictogramas = try await builder.construir(desde: extraidos)
        } catch let error as EventExtractionError {
            mensajeError = error.errorDescription      // RF-05, RF-06
        } catch let error as PictogramaError {
            mensajeError = error.errorDescription      // RF-14
            eventos = []                               // sin resultados parciales
        } catch {
            mensajeError = "Ha ocurrido un error inesperado."
        }
        mostrandoAgenda = !pictogramas.isEmpty
        estaCargando = false
    }
    
    /// TEMPORAL: prueba la agenda con eventos fijos, sin llamar al LLM de extracción.
    /// Borrar cuando haya API key configurada.
    func generarAgendaDePrueba() async {
        estaCargando = true
        mensajeError = nil
        pictogramas = []

        let eventosFijos = [
            Evento(orden: 0, descripcion: "Frukost", horaAproximada: nil),
            Evento(orden: 1, descripcion: "Skola", horaAproximada: nil),
            Evento(orden: 2, descripcion: "Läkare", horaAproximada: nil),
            Evento(orden: 3, descripcion: "Hem", horaAproximada: nil)
        ]

        do {
            eventos = eventosFijos
            pictogramas = try await builder.construir(desde: eventosFijos)
        } catch let error as PictogramaError {
            mensajeError = error.errorDescription
        } catch {
            mensajeError = "Ha ocurrido un error inesperado."
        }
        mostrandoAgenda = !pictogramas.isEmpty
        estaCargando = false
    }
}
