import Foundation
import Observation

/// Drives the Home screen. `@MainActor` because it publishes UI state; `@Observable` so SwiftUI
/// tracks `state` reads automatically.
@MainActor
@Observable
final class HomeViewModel {
    enum State: Equatable {
        case loading
        case loaded(HomeFeed)
        case failed(String)
    }

    private(set) var state: State = .loading

    private let service: HomeService

    init(service: HomeService) {
        self.service = service
    }

    func load() async {
        state = .loading
        do {
            let feed = try await service.loadHomeFeed()
            state = .loaded(feed)
        } catch {
            state = .failed(Self.message(for: error))
        }
    }

    /// Re-fetches without dropping to the skeleton state, so existing content stays on screen under
    /// the system pull-to-refresh spinner. Backs the `.refreshable` on the feed.
    func refresh() async {
        do {
            let feed = try await service.loadHomeFeed()
            state = .loaded(feed)
        } catch {
            state = .failed(Self.message(for: error))
        }
    }

    private static func message(for error: Error) -> String {
        guard let apiError = error as? APIError else {
            return "Something went wrong. Please try again."
        }
        switch apiError {
        case .mockResourceMissing:
            return "Couldn't find the home content."
        case let .requestFailed(statusCode):
            return "The server responded with an error (\(statusCode))."
        case .decodingFailed:
            return "We couldn't read the home content."
        case .invalidURL, .transport:
            return "Check your connection and try again."
        }
    }
}
