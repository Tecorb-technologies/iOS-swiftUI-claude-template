---
name: network-security-review
description: Enforces ATS (App Transport Security) configuration, checks for certificate/public-key pinning where the app handles sensitive data, and flags any disabled TLS validation in this app's Swift networking code. Use whenever adding/reviewing Info.plist ATS keys, URLSession/URLSessionDelegate TLS handling code, or Core/Networking changes that touch trust evaluation.
---

# Network Security Review (iOS/Swift-specific)

For the full generic MASVS-NETWORK control mapping and MASTG test procedure, use the `network-security-check` skill installed alongside this one. This skill is the Swift/Xcode-specific version scoped to this codebase's actual `Info.plist` ATS configuration and `Core/Networking` TLS-handling code (see `networking-layer` for the broader API client conventions this sits alongside).

## ATS — do

No `NSAppTransportSecurity` exceptions in `Info.plist` beyond the platform default (all connections require TLS 1.2+, forward secrecy). If a specific domain genuinely needs an exception (a legacy internal service with no near-term TLS upgrade path), scope it to that one domain via `NSExceptionDomains` and require a stated justification/expiry — never `NSAllowsArbitraryLoads: true` app-wide.

## ATS — don't

```xml
<!-- Don't: disables ATS for all connections, app-wide, with no scoping or justification. -->
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
</dict>
```

An `NSAllowsArbitraryLoads` hit in `Info.plist` is a hard flag regardless of context — ask why it's there and whether it can be scoped down or removed, don't assume it's intentional and move on.

## Certificate/public-key pinning

Required for any app handling sensitive data (auth tokens, financial data, health data, PII beyond a name/email) talking to a backend the team controls — not required for calls to well-known third-party APIs where pinning would just create a brittle single point of failure on their cert rotation schedule. Where pinning applies, verify:

```swift
final class PinningURLSessionDelegate: NSObject, URLSessionDelegate {
    func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        guard let trust = challenge.protectionSpace.serverTrust,
              SecTrustEvaluateWithError(trust, nil),
              certificateMatches(trust, pinnedHashes: Self.pinnedPublicKeyHashes) else {
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }
        completionHandler(.useCredential, URLCredential(trust: trust))
    }
}
```

Pin the public key hash, not the leaf certificate — a leaf-cert pin breaks on every cert renewal; a public-key pin survives renewal as long as the key doesn't rotate. Always include a backup pin (the next key in the rotation plan) so a planned key rotation doesn't lock out the app.

## Disabled TLS validation — don't, ever

```swift
// Don't: this disables all trust evaluation. No exceptions — not for local dev,
// not "temporarily," not behind a debug flag that could ship enabled by accident.
func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge,
                 completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
    completionHandler(.useCredential, URLCredential(trust: challenge.protectionSpace.serverTrust!))
}
```

If local development against a self-signed cert is the actual need, use a proper mechanism scoped to `#if DEBUG` and a specific known dev-cert hash — never an unconditional trust-everything delegate that could ship to production.

## Reviewing a diff

```bash
grep -n 'NSAllowsArbitraryLoads' Info.plist* 2>/dev/null
grep -rn 'serverTrust\|URLAuthenticationChallenge\|SecTrust' Core/Networking/
grep -rn 'useCredential.*serverTrust' Core/Networking/   # trust-everything pattern
```
