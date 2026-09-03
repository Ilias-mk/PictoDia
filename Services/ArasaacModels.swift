import Foundation

/// Un pictograma tal como lo devuelve la API de ARASAAC.
nonisolated struct ArasaacPictogramDTO: Codable {
    let id: Int
    let keywords: [ArasaacKeywordDTO]
    let schematic: Bool
    let aac: Bool

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case keywords, schematic, aac
    }

    /// Término principal asociado a este pictograma, si existe.
    var terminoPrincipal: String? {
        keywords.first?.keyword
    }
}

nonisolated struct ArasaacKeywordDTO: Codable {
    let keyword: String
}//
//  ArasaacModels.swift
//  PictoDia
//
//  Created by Ilias Mohamed on 2026-09-03.
//

