import Foundation

enum HTTPMethod: String, Sendable {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
}

/// Describes a single REST endpoint.
///
/// `mockResource` names the bundled JSON file `MockAPIClient` returns for this endpoint (without the
/// `.json` extension). `LiveAPIClient` ignores it and builds a real request from `path`/`method`/`queryItems`.
struct Endpoint: Sendable {
    let path: String
    let method: HTTPMethod
    let queryItems: [URLQueryItem]
    let mockResource: String

    init(
        path: String,
        method: HTTPMethod = .get,
        queryItems: [URLQueryItem] = [],
        mockResource: String
    ) {
        self.path = path
        self.method = method
        self.queryItems = queryItems
        self.mockResource = mockResource
    }
}
