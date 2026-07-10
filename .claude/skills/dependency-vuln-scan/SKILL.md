---
name: dependency-vuln-scan
description: Runs a Swift Package Manager dependency audit (swift package show-dependencies plus a vulnerability database check) and flags outdated or abandoned packages. Use whenever a new SPM dependency is added to Package.swift/an Xcode project's package references, periodically as a standing check, or when reviewing a diff that touches Package.resolved.
---

# SPM Dependency Vulnerability Scan

This repo is SPM-only (per `tecorb-ios-architecture`) — this skill audits that specific dependency graph. There's no CocoaPods `Podfile.lock`/Carthage `Cartfile.resolved` to scan unless the project has a documented, confirmed exception to the SPM-only policy.

## Enumerate the dependency graph

```bash
swift package show-dependencies --format json
```

Run from the repo root (or the relevant package directory if this is a multi-package workspace). This lists every direct and transitive dependency with its resolved version — the actual input to the vulnerability check, not just what's declared in `Package.swift`.

## Vulnerability check

Cross-reference each resolved package+version against a vulnerability database:

```bash
# GitHub's advisory database covers many Swift packages that mirror/wrap known CVEs;
# for packages without a GitHub Security Advisory, check the OSV database directly.
gh api graphql -f query='{ securityVulnerabilities(package: "<package-name>", first: 10) { nodes { advisory { summary severity } vulnerableVersionRange } } }'
curl -s "https://api.osv.dev/v1/query" -d '{"package":{"name":"<package-name>","ecosystem":"SwiftPM"}}'
```

Report every match with the advisory summary, severity, and whether the resolved version in `Package.resolved` actually falls in the vulnerable range — a package with a known CVE in an old version that this project has already moved past isn't a live finding.

## Outdated/abandoned package heuristics

For each dependency, check (via `gh repo view <owner>/<repo> --json pushedAt,archivedAt` or the package's GitHub page):
- **Archived** — an explicit, hard flag. An archived dependency gets no further security fixes ever.
- **No commits/releases in 12+ months** on a security-relevant dependency (networking, crypto, parsing) — a softer flag worth raising, less urgent for a dependency with a small, stable, rarely-changing surface (e.g. a pure-Swift data structure library).
- **Resolved version is several major versions behind latest** — not itself a vulnerability, but worth surfacing since it usually means accumulated unpatched issues and a harder eventual upgrade.

## Adding a new dependency — checklist

Before a new package lands in `Package.swift`:
1. Run the vulnerability check above against the version being pinned.
2. Check it's actively maintained (not archived, reasonable recent activity for its risk profile).
3. Confirm the license is compatible with distribution (flag anything GPL/AGPL or otherwise non-permissive for App Store distribution — raise it, don't assume it's fine).
4. Pin an exact version or a tight range (`.upToNextMinor`) rather than `.upToNextMajor` for anything security-sensitive (crypto, networking, auth) — a major-version auto-upgrade on a sensitive dependency should be a deliberate, reviewed bump, not silent.

## Reporting

List findings as: package name, resolved version, finding (CVE/archived/stale), severity, and recommended action (upgrade to X, replace, or accept-with-justification if no fix exists yet and the exposure is low). Don't silently bump a dependency version to "fix" a finding without confirming the newer version doesn't introduce a breaking API change — that's a separate, reviewable change.
