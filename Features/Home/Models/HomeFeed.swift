import Foundation

/// The full payload backing the Home screen. Decoded from `home_feed.json` by `MockAPIClient`
/// (see `HomeService`); the shape mirrors what a real `/home` REST endpoint would return.
struct HomeFeed: Codable, Equatable, Sendable {
    let greeting: Greeting
    let primarySectionTitle: String
    let familyStatus: FamilyStatus
    let familyWin: FamilyWin
    let supportingSectionTitle: String
    let todaysStep: TodaysStep
    let video: VideoItem
    let utilities: [Utility]
    let resources: ResourceLibrary
}

struct Greeting: Codable, Equatable, Sendable {
    let title: String
    let subtitle: String
}

struct FamilyStatus: Codable, Equatable, Sendable {
    let tag: String
    let timeframe: String
    let headline: String
    let members: [Member]
    let footnote: String
    let actionTitle: String
}

struct Member: Codable, Equatable, Sendable, Identifiable {
    enum Status: String, Codable, Sendable {
        case calm
        case watch
    }

    let id: String
    let name: String
    let note: String
    let status: Status
    let trend: [Double]
}

struct FamilyWin: Codable, Equatable, Sendable {
    let tag: String
    let headline: String
    let subtitle: String
    let actionTitle: String
}

struct TodaysStep: Codable, Equatable, Sendable {
    let tag: String
    let progressLabel: String
    let stepNumber: Int
    let totalSteps: Int
    let title: String
    let subtitle: String
    let actionTitle: String

    var progress: Double {
        guard totalSteps > 0 else { return 0 }
        return Double(stepNumber) / Double(totalSteps)
    }
}

struct VideoItem: Codable, Equatable, Sendable {
    let badge: String
    let title: String
    let source: String
    let actionTitle: String
}

struct Utility: Codable, Equatable, Sendable, Identifiable {
    enum Kind: String, Codable, Sendable {
        case refer
        case reward
    }

    let id: String
    let kind: Kind
    let title: String
    let subtitle: String
    let actionTitle: String
}

struct ResourceLibrary: Codable, Equatable, Sendable {
    let title: String
    let subtitle: String
    let actionTitle: String
}
