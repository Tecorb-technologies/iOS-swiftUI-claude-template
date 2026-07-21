#if DEBUG
    import Foundation

    extension HomeFeed {
        /// Sample payload for previews and tests — mirrors `home_feed.json`.
        static let preview = HomeFeed(
            greeting: Greeting(
                title: "Good evening, Dana",
                subtitle: "Thursday, July 17 · all calm today"
            ),
            primarySectionTitle: "Today · Your family",
            familyStatus: FamilyStatus(
                tag: "Family status",
                timeframe: "This week",
                headline: "A calm, creative week for your family.",
                members: [
                    Member(
                        id: "emma",
                        name: "Emma",
                        note: "Calm week — creative & school topics",
                        status: .calm,
                        trend: [3, 4, 3.5, 5, 5.5, 7, 8]
                    ),
                    Member(
                        id: "jake",
                        name: "Jake",
                        note: "A couple of late-night sessions worth a look",
                        status: .watch,
                        trend: [4, 3.7, 5.2, 5.5, 3, 5, 8, 6.8]
                    ),
                ],
                footnote: "Patterns, not surveillance",
                actionTitle: "Full picture"
            ),
            familyWin: FamilyWin(
                tag: "Family win",
                headline: "Emma read more than she gamed this week.",
                subtitle: "That's two weeks in a row.",
                actionTitle: "Celebrate"
            ),
            supportingSectionTitle: "Supporting content",
            todaysStep: TodaysStep(
                tag: "Today's step",
                progressLabel: "Day 6 of 14",
                stepNumber: 6,
                totalSteps: 14,
                title: "Set your family's evening screen rhythm",
                subtitle: "A 2-minute read on winding down before bed.",
                actionTitle: "Start step"
            ),
            video: VideoItem(
                badge: "Watch · 5 min",
                title: "Talking to kids about what they see online",
                source: "From the Permission library",
                actionTitle: "Play video"
            ),
            utilities: [
                Utility(
                    id: "refer",
                    kind: .refer,
                    title: "Refer a family",
                    subtitle: "Invite friends — it's free for them too.",
                    actionTitle: "Share"
                ),
                Utility(
                    id: "reward",
                    kind: .reward,
                    title: "Send a reward",
                    subtitle: "ASK points for a job well done.",
                    actionTitle: "Open"
                ),
            ],
            resources: ResourceLibrary(
                title: "Resources library",
                subtitle: "Articles & guides — always free",
                actionTitle: "Browse"
            )
        )
    }

    /// `HomeService` that returns the in-memory sample synchronously — for previews/tests without a bundle.
    struct PreviewHomeService: HomeService {
        var feed: HomeFeed = .preview

        func loadHomeFeed() async throws -> HomeFeed {
            feed
        }
    }
#endif
