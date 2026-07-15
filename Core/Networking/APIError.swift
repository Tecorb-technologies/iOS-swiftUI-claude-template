import Foundation

/// Typed errors that cross the `APIClient` boundary — callers never see raw
/// `URLError`/`DecodingError`.
enum APIError: Error, Equatable {
    case badResponse(statusCode: Int)
    case decoding(underlying: String)
    case unauthorized
    case offline
}
