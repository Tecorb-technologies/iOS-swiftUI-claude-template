import Foundation

/// `APIClient` backed by bundled dummy JSON.
///
/// Returns the contents of `<endpoint.mockResource>.json` from `bundle`, decoded into the requested
/// type. This is the app's active client until a real backend exists (see `.claude/project.json`
/// `backend`); swapping to `LiveAPIClient` is a one-line change at the composition root.
///
/// `@unchecked Sendable`: the only stored non-`Sendable` value is `Bundle`, which is used read-only
/// (thread-safe resource lookup). The decoder is created per request, not shared.
struct MockAPIClient: APIClient, @unchecked Sendable {
    private let bundle: Bundle
    private let artificialDelay: Duration

    init(bundle: Bundle = .main, artificialDelay: Duration = .milliseconds(1200)) {
        self.bundle = bundle
        self.artificialDelay = artificialDelay
    }

    func request<Response: Decodable>(_ endpoint: Endpoint, as _: Response.Type) async throws -> Response {
        // Simulate latency so loading states are exercised in the running app and previews.
        if artificialDelay > .zero {
            try? await Task.sleep(for: artificialDelay)
        }

        guard let url = bundle.url(forResource: endpoint.mockResource, withExtension: "json") else {
            throw APIError.mockResourceMissing(endpoint.mockResource)
        }

        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder.apiDefault.decode(Response.self, from: data)
        } catch let error as DecodingError {
            throw APIError.decodingFailed(String(describing: error))
        } catch {
            throw APIError.transport(error.localizedDescription)
        }
    }
}
