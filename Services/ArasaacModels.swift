import Foundation

/// A pictogram as returned by the ARASAAC API.
nonisolated struct ArasaacPictogramDTO: Codable {
    let id: Int
    let keywords: [ArasaacKeywordDTO]
    let schematic: Bool
    let aac: Bool

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case keywords, schematic, aac
    }

    /// Primary term associated with this pictogram, if any.
    var primaryTerm: String? {
        keywords.first?.keyword
    }
}

nonisolated struct ArasaacKeywordDTO: Codable {
    let keyword: String
}
