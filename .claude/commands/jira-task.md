---
description: Fetch a Jira ticket's full context via the atlassian MCP and use it as the working spec for a coding task — the only entry point for the jira-ticket-context skill; Jira is entirely optional and nothing is fetched unless this command is run.
argument-hint: "<ticket-key-or-search-text> [FeatureName]"
---

Read and follow `.claude/skills/jira-ticket-context/SKILL.md` — its fetch/review/handoff workflow is the source of truth, don't duplicate it here. This command is the *only* way that workflow ever runs: the skill has no independent trigger of its own and is never invoked automatically from something a developer merely mentions in conversation. `$1` is the Jira ticket key (e.g. `PROJ-123`), a Jira URL, or free text to search for; `$2` is the optional `FeatureName` (infer a sensible one from the ticket if omitted).
