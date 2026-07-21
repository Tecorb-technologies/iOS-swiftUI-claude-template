---
description: Fetch a Jira ticket's full context via the atlassian MCP and use it as the working spec for a coding task — the explicit, developer-invoked entry point for the jira-ticket-context skill.
argument-hint: "<ticket-key-or-search-text> [FeatureName]"
---

Read and follow `.claude/skills/jira-ticket-context/SKILL.md` — its fetch/review/handoff workflow is the source of truth, don't duplicate it here. This command is the explicit, developer-invoked entry point (as opposed to the skill's automatic reference-detection trigger). `$1` is the Jira ticket key (e.g. `PROJ-123`), a Jira URL, or free text to search for; `$2` is the optional `FeatureName` (infer a sensible one from the ticket if omitted).
