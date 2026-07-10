---
name: docs-sync
description: Scans README.md, CHANGELOG.md, CLAUDE.md, and /docs for references to code that changed since the last doc update, patches stale sections in place, and adds new sections for new public APIs/screens/commands. Use on explicit /docs-sync invocation, or automatically after a Stop hook detects a merged feature. Never invents functionality that doesn't exist in code — every claim in a patched doc must trace to an actual file/symbol.
---

# docs-sync

Keeps this project's own docs (not third-party API references — those are covered by `api-reference`) truthful against the current code. Project-specific by necessity: it needs to know this repo's doc layout, which is CLAUDE.md's "Status"/"Architecture" sections (filled in at bootstrap), README.md, CHANGELOG.md, and anything under `/docs` (e.g. `architecture-diagrams`' output).

## Workflow

1. **Find what changed.** `git diff <last-doc-sync-marker-or-base-branch>...HEAD --stat` to see changed files since the last sync. If no marker exists yet, use the most recent commit that touched a doc file as the baseline.
2. **Find what the docs currently claim.** Grep README.md/CHANGELOG.md/CLAUDE.md/`docs/**` for references to file paths, type names, command names, or feature names that appear in the diff.
3. **Reconcile.** For each doc reference to changed code:
   - If the code changed in a way that makes the doc claim wrong (a renamed type, a removed command, a changed folder), patch that section in place.
   - If new code adds a public API surface, a new screen, or a new command with no corresponding doc section, add one — in the style of the surrounding doc, not a generic template.
   - If a doc claim still matches the code, leave it untouched — don't rewrite prose that's still accurate just to "freshen" it.
4. **Mark every changed section.** Leave an inline `<!-- updated by docs-sync -->` marker immediately after each section docs-sync patched or added, so a human reviewer can spot AI-authored edits at a glance.
5. **Never invent.** Every functional claim added to a doc must trace to an actual file, type, or command that exists right now — if you can't point to the code backing a claim, don't add the claim. This applies especially to CHANGELOG.md entries and README feature lists, where the temptation to describe "intended" behavior instead of "actual" behavior is highest.

## What NOT to touch

CLAUDE.md sections 3 onward (folder structure, build/test/lint commands, `.claude/` extension architecture table, quality gates) are stable template documentation per this repo's own CLAUDE.md note — only sections 1–2 ("Status", "Architecture") get filled in with real per-project values, and only at bootstrap time, not by docs-sync. Don't let docs-sync "helpfully" rewrite the stable template sections.

## Triggering

- **Explicit**: `/docs-sync` — run the full workflow against the current diff-since-last-sync.
- **Automatic**: after a Stop hook detects a merged feature (a PR merge, a feature branch merged to main) — run the same workflow scoped to that merge's diff. If no such hook exists yet in this repo, note that to the developer rather than silently skipping the automatic path.

## Output

Report a summary of sections patched/added, each with the specific code reference that justified the change — this is what a reviewer checks against, not just "docs updated."
