import XCTest

/// Minimal launch smoke so the UI-test target builds and signs in CI.
@MainActor
final class SmokeUITests: XCTestCase {
    func testAppLaunches() {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 10))
    }
}
