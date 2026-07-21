import Foundation

/// Abstraction over the app's backend.
///
/// Feature services depend on this protocol, never a concrete client, so a screen can be driven by
/// `MockAPIClient` (bundled dummy JSON) in previews/tests and `LiveAPIClient` (real REST) in
/// production without changing call sites. `Sendable` so it can be held by `@MainActor` ViewModels
/// and awaited across executors under Swift 6 strict concurrency.
protocol APIClient: Sendable {
    func request<Response: Decodable>(_ endpoint: Endpoint, as type: Response.Type) async throws -> Response
}

extension APIClient {
    /// Type-inferred convenience: `let feed: Feed = try await client.request(.feed)`.
    func request<Response: Decodable>(_ endpoint: Endpoint) async throws -> Response {
        try await request(endpoint, as: Response.self)
    }
}
