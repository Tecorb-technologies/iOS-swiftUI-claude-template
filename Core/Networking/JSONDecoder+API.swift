import Foundation

extension JSONDecoder {
    /// Default decoder for API and mock payloads: `snake_case` keys map to `camelCase`, dates parse
    /// as ISO-8601. Created fresh per use so it never needs to be shared across concurrency domains.
    static var apiDefault: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
