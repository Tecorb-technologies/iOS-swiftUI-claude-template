import Foundation

/// `APIClient` that talks to a real REST backend over `URLSession`.
///
/// Not yet wired to a live base URL — see `.claude/project.json` `backend.baseURLPlaceholder`.
/// `MockAPIClient` is the active client until the backend exists. Stores only `Sendable` values
/// (`URL`, `URLSession`), so it is genuinely `Sendable`.
struct LiveAPIClient: APIClient {
    let baseURL: URL
    let session: URLSession

    init(baseURL: URL, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
    }

    func request<Response: Decodable>(_ endpoint: Endpoint, as _: Response.Type) async throws -> Response {
        var components = URLComponents(
            url: baseURL.appending(path: endpoint.path),
            resolvingAgainstBaseURL: false
        )
        if !endpoint.queryItems.isEmpty {
            components?.queryItems = endpoint.queryItems
        }
        guard let url = components?.url else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue

        let (data, response) = try await session.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw APIError.transport("Non-HTTP response")
        }
        guard 200 ..< 300 ~= http.statusCode else {
            throw APIError.requestFailed(statusCode: http.statusCode)
        }

        do {
            return try JSONDecoder.apiDefault.decode(Response.self, from: data)
        } catch {
            throw APIError.decodingFailed(String(describing: error))
        }
    }
}
