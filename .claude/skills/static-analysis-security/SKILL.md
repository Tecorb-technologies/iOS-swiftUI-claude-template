---
name: static-analysis-security
description: Wraps a Semgrep pass (via the Semgrep MCP server) with Swift-specific rules for force unwraps on untrusted input, insecure random number generation, hardcoded secrets/API keys, and insecure deserialization. Use whenever reviewing a diff for security issues, before a release, or when asked to run a static security scan over Swift/SwiftUI code.
---

# Static Analysis Security Scan (Semgrep)

Runs Semgrep against this repo's Swift code via the `semgrep` MCP server (registered in this project's MCP config) rather than hand-grepping for each pattern individually — Semgrep's Swift/generic rulesets catch more variants of each issue than a handful of `grep` patterns will. This is a read-only detection pass; it doesn't fix findings automatically (a fix has to account for context Semgrep can't see — see `swift-code-reviewer` for the human-judgment layer).

## Rule categories to run

1. **Force unwraps / force casts / force try on untrusted input** — `.swiftlint.yml` already disallows these outside `Tests/`/`UITests/` at the lint level; this pass specifically looks for the subset that touches data crossing a trust boundary (network response decoding, user input, file/URL contents) where a crash is a genuine security/availability issue, not just a style violation.
2. **Insecure random number generation** — `arc4random()`/`Int.random(in:)`/`drand48` used for anything security-sensitive (token generation, nonce, password reset code). Security-sensitive randomness must come from `SecRandomCopyBytes` or a CSPRNG-backed API, never the general-purpose `random(in:)` family.
3. **Hardcoded secrets/API keys** — string literals matching API-key-shaped patterns (`sk_live_`, `AKIA`, JWT-shaped base64 blobs, etc.) committed directly in Swift source rather than injected via `.xcconfig`/build settings (see `networking-layer`'s base-URL/secrets convention).
4. **Insecure deserialization** — `NSKeyedUnarchiver` without `requiringSecureCoding: true`, or decoding untrusted data with a type that isn't validated against an allow-list of expected classes.

## Running the scan

```
Use the semgrep MCP server's scan tool against this repo, scoped to Swift files
(App/, Features/, Core/, excluding Tests/ and UITests/ where force-unwraps are
permitted by .swiftlint.yml), with rulesets covering: generic secrets detection,
and Swift-specific rules for the four categories above. If no Swift-specific
Semgrep ruleset is available/registered, fall back to the generic secrets +
dangerous-function rulesets and note the reduced Swift-specific coverage explicitly.
```

## Triaging results

Semgrep findings need human triage before being reported as real issues — a force-unwrap on a value the code has already `guard`ed as non-nil three lines above is a false positive Semgrep's pattern matching can miss context for. For each finding:
1. Read the surrounding function to confirm the trust boundary claim actually holds (is this value really untrusted/unvalidated at this point?).
2. Drop findings that are clearly false positives, with a one-line note why.
3. Report the rest with file:line, the specific risk, and a concrete fix suggestion — not just "Semgrep flagged this."

## When to run

- Before a release (part of the `release-checklist` gate).
- On any diff touching decoding of network/file/user-provided data, secret/token handling, or `NSKeyedUnarchiver`/`Codable` boundaries.
- On explicit request for a security scan.

This complements, not replaces, `mobile-secure-storage` and `network-security-review` — those cover storage/network *architecture* conventions; this is pattern-based scanning across the whole diff for the specific code-level bug classes above.
