---
name: ui-testing
description: XCUITest conventions for Tecorb iOS apps — accessibility-identifier-based selectors only (never index-based), the page-object pattern per screen, and how to add a new end-to-end UI test flow. Use whenever adding a new UITests flow, adding an accessibilityIdentifier to a View for testability, or reviewing a UI test for brittle selectors.
---

# Tecorb UI Testing Conventions

For XCUITest API mechanics (element queries, waiting patterns, `@MainActor` requirements under Swift 6, assertions, screenshots), use `apple-skills:xcuitest`. This skill is the house convention: selector strategy and file organization.

## Selectors: accessibility identifiers only — do

```swift
// In the View:
TextField("Email", text: $email)
    .accessibilityIdentifier("login.emailField")

Button("Sign In") { signIn() }
    .accessibilityIdentifier("login.signInButton")
```

```swift
// In the UI test / page object:
app.textFields["login.emailField"].tap()
app.buttons["login.signInButton"].tap()
```

Identifiers are namespaced `<screen>.<element>` so they stay unique and greppable across the whole app as it grows.

## Selectors: index/label-based — don't

```swift
// Don't: index-based — breaks the instant element order changes, and gives no signal
// about what actually broke when it fails.
app.buttons.element(boundBy: 2).tap()

// Don't: matching on visible label text — breaks under localization (see `localization`)
// and on any copy change, even a copy change with zero behavioral impact.
app.buttons["Sign In"].tap()
```

A UI test that fails because marketing changed a button's copy from "Sign In" to "Log In" is a false positive costing review time for no real regression — identifier-based selectors don't have this failure mode.

## Page-object pattern

One page object per screen, exposing the screen's elements and user-facing actions — tests read like a script of user intent, not raw `XCUIElement` calls:

```swift
struct LoginScreen {
    let app: XCUIApplication

    var emailField: XCUIElement { app.textFields["login.emailField"] }
    var signInButton: XCUIElement { app.buttons["login.signInButton"] }

    func signIn(email: String, password: String) {
        emailField.tap()
        emailField.typeText(email)
        app.secureTextFields["login.passwordField"].tap()
        app.secureTextFields["login.passwordField"].typeText(password)
        signInButton.tap()
    }
}

@Test
func signInWithValidCredentialsShowsHome() {
    let app = XCUIApplication()
    app.launch()
    LoginScreen(app: app).signIn(email: "test@tecorb.com", password: "correct-password")
    #expect(app.staticTexts["home.welcomeLabel"].waitForExistence(timeout: 5))
}
```

Page objects live in `UITests/PageObjects/<Screen>Screen.swift`; test flows live in `UITests/<Flow>Tests.swift`.

## Adding a new UI test flow

1. Add `accessibilityIdentifier`s to every element the flow interacts with or asserts on, if they aren't already there — this is a code change to the View, not just the test.
2. Add or extend the relevant page object(s).
3. Write the test as a sequence of page-object calls plus assertions, using `waitForExistence`/expectations rather than fixed `sleep`-style delays.
4. Use launch arguments (e.g. `--uitesting-mock-network`) to point the app at a mock backend state for the flow rather than depending on real network/backend data — see `test-data-builders` for how fixture states are structured for this.

## Reviewing a UI test

Flag any `element(boundBy:)`, label-text matcher, or hardcoded `sleep`/`Thread.sleep` — these are the three most common sources of a UI test suite that's flaky or breaks on unrelated changes.
