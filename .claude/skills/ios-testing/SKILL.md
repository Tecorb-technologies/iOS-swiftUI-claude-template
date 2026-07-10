---
name: ios-testing
description: Swift Testing conventions for Tecorb iOS apps — naming, Arrange-Act-Assert structure, how ViewModels are unit tested with mocked services, and the rule that every new ViewModel/service needs tests (no coverage percentage gate). Use whenever adding a new ViewModel or service, writing a unit test, or reviewing whether new code has adequate test coverage.
---

# Tecorb Unit Testing Conventions

Tecorb apps use **Swift Testing** (`@Test`/`#expect`), not XCTest, for new unit tests — see `apple-skills:swift-testing` and `apple-skills:guide-swift-testing` for the framework's API mechanics and migration notes. This skill is the house convention on top: what gets tested, how it's structured, and where it lives.

## The rule: no % gate, but every new ViewModel/service needs tests

There's no enforced line/branch coverage percentage. The rule is simpler and non-negotiable: a new `@Observable` ViewModel or a new service/store type (`networking-layer`, `persistence-layer`) ships with tests, in `Tests/UnitTests/<FeatureName>/`, mirroring the `Features/`/`Core/` structure. A PR adding a ViewModel with zero tests is incomplete, regardless of overall project coverage numbers.

## Structure: Arrange-Act-Assert

```swift
@Test
func loadPopulatesProfileOnSuccess() async {
    // Arrange
    let mockService = MockProfileService(result: .success(.preview))
    let viewModel = ProfileViewModel(service: mockService)

    // Act
    await viewModel.load(userID: "123")

    // Assert
    #expect(viewModel.profile == .preview)
    #expect(viewModel.error == nil)
    #expect(viewModel.isLoading == false)
}
```

Keep the three sections visually separated (blank line or comment) even when one section is a single line — this makes it immediately obvious what's being set up vs. exercised vs. checked, especially in a longer test.

## Naming

`<methodOrBehavior><ExpectedOutcome><Condition>` — e.g. `loadPopulatesProfileOnSuccess`, `loadSetsErrorOnNetworkFailure`, `addThrowsWhenDuplicateID`. The name alone should tell you what broke without opening the test body.

## Testing a ViewModel — what to cover

For any async-loading ViewModel, cover at minimum: the success path (per `ui-states-checklist`'s populated state), a typed-error failure path (per `networking-layer`'s `APIError`), and — if the ViewModel has one — the loading-flag transition (`isLoading` true during the call, false after, on both success and failure paths).

```swift
@Test
func loadSetsErrorOnNetworkFailure() async {
    let mockService = MockProfileService(result: .failure(APIError.offline))
    let viewModel = ProfileViewModel(service: mockService)

    await viewModel.load(userID: "123")

    #expect(viewModel.error as? APIError == .offline)
    #expect(viewModel.profile == nil)
}
```

## Testing a service/store — what to cover

Test against the protocol's contract with a real (not mocked) implementation where feasible — e.g. a `PersistenceStore` test uses an in-memory `ModelContainer` (per `persistence-layer`), not a further mock, since the store itself is the thing under test. Cover the happy path and at least one failure/edge case (empty result, duplicate insert, decode failure).

## Fixtures

Don't hand-roll model literals inline in every test — use the shared builders from `test-data-builders` (`.preview`, `.mock(...)` style factories) so fixture shape changes propagate from one place.

## Parameterized tests for variant coverage

When the same behavior needs checking across several inputs (e.g. every `APIError` case maps to the right user-facing state), use Swift Testing's `@Test(arguments:)` rather than copy-pasting near-identical test functions:

```swift
@Test(arguments: [APIError.offline, .unauthorized, .badResponse(statusCode: 500)])
func loadSetsErrorForEachFailureCase(error: APIError) async {
    let viewModel = ProfileViewModel(service: MockProfileService(result: .failure(error)))
    await viewModel.load(userID: "123")
    #expect(viewModel.error as? APIError == error)
}
```
