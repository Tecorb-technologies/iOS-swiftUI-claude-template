import Foundation

/// Minimal async/await REST client. The base URL is injected from build
/// settings (`API_BASE_URL`), never hardcoded in source. This is a starting
/// stub — extend it (POST/PUT, retry/backoff on idempotent GETs, auth header
/// injection) per the `networking-layer` skill as real endpoints are added.
struct APIClient: Sendable {
    let baseURL: URL
    let session: URLSession

    init(baseURL: URL, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
    }

    func get<T: Decodable>(_ path: String, as _: T.Type) async throws -> T {
        let url = baseURL.appending(path: path)
        do {
            let (data, response) = try await session.data(from: url)
            guard let http = response as? HTTPURLResponse else {
                throw APIError.badResponse(statusCode: -1)
            }
            switch http.statusCode {
            case 200 ..< 300:
                do {
                    return try JSONDecoder().decode(T.self, from: data)
                } catch {
                    throw APIError.decoding(underlying: String(describing: error))
                }
            case 401:
                throw APIError.unauthorized
            default:
                throw APIError.badResponse(statusCode: http.statusCode)
            }
        } catch let error as APIError {
            throw error
        } catch let urlError as URLError where urlError.code == .notConnectedToInternet {
            throw APIError.offline
        }
    }
}
