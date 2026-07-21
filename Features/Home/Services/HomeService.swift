import Foundation

/// Loads the Home screen payload. ViewModels depend on this protocol, not a concrete client, so
/// the screen can be driven by the bundled dummy JSON today and a live REST backend later.
protocol HomeService: Sendable {
    func loadHomeFeed() async throws -> HomeFeed
}

/// Default implementation backed by the app's `APIClient`. With `MockAPIClient` (the current
/// composition-root default) this decodes `home_feed.json`; with `LiveAPIClient` it would hit the
/// real `/home` endpoint — no change needed here or at the call site.
struct LiveHomeService: HomeService {
    private let client: APIClient

    init(client: APIClient) {
        self.client = client
    }

    func loadHomeFeed() async throws -> HomeFeed {
        try await client.request(.homeFeed)
    }
}

extension Endpoint {
    static let homeFeed = Endpoint(path: "/home", mockResource: "home_feed")
}
