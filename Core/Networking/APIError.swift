import Foundation

/// Typed errors surfaced by any `APIClient`. Feature ViewModels map these onto user-facing
/// error states (see the ui-states-checklist).
enum APIError: Error, Equatable {
    case invalidURL
    case requestFailed(statusCode: Int)
    case decodingFailed(String)
    case mockResourceMissing(String)
    case transport(String)
}
