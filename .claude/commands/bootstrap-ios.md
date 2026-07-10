---
description: Explicitly (re-)run the Tecorb iOS bootstrap flow — asks project-context questions and generates the app-specific scaffold, or safely re-applies changes to an already-bootstrapped project.
argument-hint: "[--force] [--field=value ...]"
---

Read and follow `.claude/skills/tecorb-ios-bootstrap/SKILL.md` — its Q&A and generation workflow is the source of truth, don't duplicate it here. This command is the explicit, developer-invoked entry point (as opposed to the skill's automatic first-use trigger), with these additional guards:

## No arguments, `.claude/project.json` already exists

Print the current answers from `.claude/project.json` in a readable summary and ask for explicit confirmation before changing anything. Do not silently regenerate `project.yml`/xcconfig/CLAUDE.md sections — treat any change as something the developer reviews first.

## `--force`

Re-run the skill's Q&A, but pre-fill each question with its current value from `.claude/project.json` so the developer can press-enter-to-keep or type a new value — don't make them re-answer all seven questions to fix one.

## `--field=value` (e.g. `--field=ci.target=github-actions`)

Update just that field (dotted path into the `project.json` schema) without running the full Q&A, then regenerate only the files that field affects (see the "Consumers" mapping in the skill/plan — e.g. changing `ci.target` only touches the CI workflow file and the relevant `.claude/settings.json` allowlist entries, not `project.yml`).

## Overwrite protection

Before overwriting any file tagged `// GENERATED-BY-BOOTSTRAP` (e.g. `App/<AppName>App.swift`), diff its current content against what bootstrap would generate. If it's been hand-edited beyond the tag, show the diff and ask before overwriting — never clobber hand-written app code silently.

## `.claude/project.json` missing

No existing answers to guard — just run the skill's flow from scratch, same as the auto-trigger path.
