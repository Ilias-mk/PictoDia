import Foundation

/// Orquesta la construcción de la agenda visual, usando caché para evitar llamadas repetidas.
nonisolated struct AgendaBuilder {

    private let arasaac: ArasaacService
    private let seleccion: PictogramaSelectionService
    private let cache: PictogramaCache

    init(arasaac: ArasaacService = ArasaacService(),
         seleccion: PictogramaSelectionService = PictogramaSelectionService(),
         cache: PictogramaCache = UserDefaultsPictogramaCache()) {
        self.arasaac = arasaac
        self.seleccion = seleccion
        self.cache = cache
    }

    /// Devuelve un pictograma por evento, en el mismo orden. Lanza .falloDeRed sin resultados parciales (RF-14).
    func construir(desde eventos: [Evento]) async throws -> [Pictograma] {

        // 1. Separar lo que ya está en caché de lo que hay que buscar (RF-19, RF-21).
        var enCache: [String: ResultadoCache] = [:]
        var pendientes: [Evento] = []

        for evento in eventos {
            if let cacheado = cache.obtener(para: evento.descripcion) {
                enCache[evento.descripcion] = cacheado
            } else {
                pendientes.append(evento)
            }
        }

        // 2. Buscar candidatos solo para los pendientes (RF-21).
        var candidatosPorEvento: [(evento: String, candidatos: [ArasaacPictogramDTO])] = []
        for evento in pendientes {
            let candidatos = try await arasaac.buscarCandidatos(para: evento.descripcion)
            candidatosPorEvento.append((evento: evento.descripcion, candidatos: candidatos))
        }

        // 3. Una sola llamada al LLM, solo si hay algo que elegir (RF-12).
        let elegidos = candidatosPorEvento.isEmpty
            ? [:]
            : try await seleccion.elegir(candidatosPorEvento: candidatosPorEvento)

        // 4. Construir el pictograma de cada evento, en orden.
        return eventos.map { evento in
            if let cacheado = enCache[evento.descripcion] {
                return pictograma(desde: cacheado, para: evento)
            }

            let candidatos = candidatosPorEvento
                .first { $0.evento == evento.descripcion }?
                .candidatos ?? []

            guard !candidatos.isEmpty else {
                cache.guardar(.noHayPictograma, para: evento.descripcion)   // RF-22
                return pictogramaGenerico(para: evento)                     // RF-13
            }

            let idElegido = elegidos[evento.descripcion]
            let dto = candidatos.first { $0.id == idElegido } ?? candidatos[0]

            cache.guardar(.encontrado(id: dto.id), para: evento.descripcion)   // RF-18
            return pictograma(desde: .encontrado(id: dto.id), para: evento)
        }
    }

    /// Construye el pictograma a partir de un resultado (cacheado o recién obtenido).
    private func pictograma(desde resultado: ResultadoCache, para evento: Evento) -> Pictograma {
        switch resultado {
        case .noHayPictograma:
            return pictogramaGenerico(para: evento)
        case .encontrado(let id):
            guard let url = ArasaacService.urlImagen(paraID: id) else {
                return pictogramaGenerico(para: evento)
            }
            return Pictograma(id: id, urlImagen: url, textoAsociado: evento.descripcion, esGenerico: false)
        }
    }

    /// Pictograma de reemplazo cuando no hay ninguno disponible (RF-13).
    private func pictogramaGenerico(para evento: Evento) -> Pictograma {
        Pictograma(
            id: -evento.orden - 1,
            urlImagen: nil,
            textoAsociado: evento.descripcion,
            esGenerico: true
        )
    }
}
