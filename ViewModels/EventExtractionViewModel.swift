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
    var errorDictado: SpeechRecognitionError?
    private let speech = SpeechRecognitionService()

    var estaDictando: Bool { speech.estaGrabando }

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
    
    /// Inicia el dictado tras comprobar permisos y disponibilidad (RF-30, RF-31).
    func alternarDictado() async {
        if speech.estaGrabando {
            speech.detener()
            return
        }

        do {
            try await speech.prepararse()
            try speech.iniciar()
            observarTranscripcion()
        } catch let error as SpeechRecognitionError {
            errorDictado = error
        } catch {
            errorDictado = .falloDeReconocimiento
        }
    }

    /// Vuelca la transcripción en el campo de texto mientras se dicta (RF-26, RF-27).
    /// Vuelca la transcripción en el campo de texto mientras se dicta (RF-26, RF-27).
    private func observarTranscripcion() {
        Task { @MainActor in
            var ultimoTexto = ""
            while speech.estaGrabando {
                if !speech.transcripcion.isEmpty {
                    ultimoTexto = speech.transcripcion
                    textoEntrada = ultimoTexto   // RF-27
                }
                try? await Task.sleep(for: .milliseconds(150))
            }
            if !speech.transcripcion.isEmpty {
                ultimoTexto = speech.transcripcion
            }
            textoEntrada = ultimoTexto
        }
    }
    /// TEMPORAL: prueba la agenda con eventos fijos, sin llamar al LLM de extracción.
    /// Borrar cuando haya API key configurada.
    
}
