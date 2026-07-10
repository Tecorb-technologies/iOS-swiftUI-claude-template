---
name: mobile-secure-storage
description: Audits Keychain vs UserDefaults usage in this app's Swift code, flags sensitive data (tokens, PII, credentials) stored unencrypted, and checks Data Protection entitlement levels. Use whenever adding code that persists a token/credential/PII value, or when reviewing a diff that touches UserDefaults, Keychain, SwiftData, or a file written to disk.
---

# Mobile Secure Storage (iOS/Swift-specific)

For the full generic MASVS-STORAGE control mapping and MASTG test procedure (applies to Android too), use the `secure-storage-audit` skill installed alongside this one. This skill is the Swift/Xcode-specific version scoped to this codebase's actual storage call sites — `Core/Persistence` (per `persistence-layer`) and any raw `UserDefaults`/Keychain use.

## The rule

- **Keychain** (`Security` framework, or a thin wrapper over it) — auth tokens, refresh tokens, passwords, any credential. Never `UserDefaults`, never a SwiftData model, never a plain file.
- **UserDefaults** — non-sensitive user preferences only (theme, feature flags, last-viewed tab). Never a token, password, or PII field.
- **SwiftData** (per `persistence-layer`) — structured app data. If a `@Model` type has a field that's a credential/token, that's a storage violation regardless of the on-disk file protection class — move it to Keychain instead of relying on Data Protection alone.

## Do

```swift
// A thin Keychain wrapper — protocol + live + mock per the networking-layer pattern,
// so ViewModels don't call Security framework APIs directly.
protocol CredentialStoring: Sendable {
    func save(token: String, for account: String) throws
    func loadToken(for account: String) throws -> String?
}

struct KeychainCredentialStore: CredentialStoring {
    func save(token: String, for account: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: account,
            kSecValueData as String: Data(token.utf8),
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        SecItemDelete(query as CFDictionary)
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else { throw KeychainError.unhandled(status: status) }
    }
}
```

## Don't

```swift
// Don't: auth token in UserDefaults — readable from an unencrypted plist on a
// jailbroken/compromised device, and included in unencrypted device backups.
UserDefaults.standard.set(authToken, forKey: "authToken")

// Don't: PII/credential field on a SwiftData @Model with no Keychain involvement.
@Model
final class UserSession {
    var authToken: String   // should not exist on a @Model at all
}
```

## Data Protection entitlement

Check the Keychain accessibility attribute matches the data's sensitivity — `kSecAttrAccessibleWhenUnlockedThisDeviceOnly` (or the `*ThisDeviceOnly` variant generally) for anything that shouldn't survive a device migration/backup restore onto different hardware; plain `kSecAttrAccessibleWhenUnlocked` if cross-device-via-backup restore is actually desired for that specific value. Absence of an explicit `kSecAttrAccessible` value (relying on the SDK default) is itself a flag — the accessibility level should be a deliberate choice per credential, not a default.

## Auditing a diff

```bash
grep -rn 'UserDefaults' Features/ Core/ | grep -i 'token\|password\|secret\|credential\|apikey'
grep -rn '@Model' Core/Persistence/Models/ -A 5 | grep -i 'token\|password\|secret'
grep -rn 'kSecAttrAccessible' Core/   # confirm every Keychain write sets one explicitly
```

Any hit on the first two greps is a finding to report, not to silently "fix" by moving to Keychain without confirming the actual sensitivity and access-pattern requirements with the developer first — the fix has behavioral implications (biometric gating, backup inclusion) that a search-and-replace would get wrong.
