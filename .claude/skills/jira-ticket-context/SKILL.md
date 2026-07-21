---
name: jira-ticket-context
description: Fetches a Jira ticket's full context (title, description, acceptance criteria, comments, labels, status) via the atlassian MCP server when a developer references it by key (e.g. PROJ-123), Jira URL, or name/description, presents it in chat for explicit confirmation or edits, then uses it as the working spec to hand off implementation to ios-swiftui-engineer. Auto-triggers on a ticket-key-shaped token, a Jira URL, or a clear description of a specific ticket (e.g. "pull up PROJ-123", "let's implement the login bug ticket", "what's the spec for the onboarding story") when the developer's intent is to start or review that ticket's work now — not when a ticket ID merely appears in passing (a commit reference, "this relates to PROJ-100 but we already fixed that"). Prefer the explicit /jira-task command when intent is ambiguous.
---

# Jira Ticket Context

Pulls a Jira ticket's full context through the `atlassian` MCP server and turns it into a working spec for a coding task, mirroring how `design-to-code`/`figma-screen` pull Figma context: connect → fetch → present for review → hand off to implementation and verification agents.

Run this flow in order — don't skip the connectivity check or the confirmation gate:

1. **Ensure the atlassian MCP is connected.** Confirm `.mcp.json` has an `atlassian` server. If it isn't connected, tell the developer to run `claude mcp add --transport http atlassian https://mcp.atlassian.com/v1/mcp/authv2 --scope project` then `/mcp → atlassian → Authenticate`, and stop until it's connected — don't fabricate ticket content without live Jira data.

2. **Resolve the ticket reference.** If it matches a ticket-key pattern (`^[A-Z][A-Z0-9]{1,9}-\d+$`) or is a Jira URL containing one, call `getJiraIssue` directly with that key. Otherwise treat it as free text and call `searchJiraIssuesUsingJql` (or `search`); if multiple candidates come back, use `AskUserQuestion` to let the developer pick the right one — never guess which ticket was meant.

3. **Fetch full details.** Pull title, description, status, labels, and comments from the issue response. Acceptance criteria commonly live either inline in the description or in an instance-specific custom field — check both. If genuinely not found, say so explicitly rather than inventing criteria.

4. **Check/set the write-back mode.** Read `.claude/jira-integration.json` (shape `{"writeBack": boolean}`, committed to the repo as a team-level policy — not gitignored). If the file doesn't exist yet, ask once via `AskUserQuestion`:
   - **Read-only** — only ever call Jira fetch/search tools. Never call `transitionJiraIssue` or `addCommentToJiraIssue`, under any circumstance.
   - **Write-back** — additionally: auto-transition the ticket's status when work begins (step 6), and draft-then-confirm a completion comment (step 10).

   Persist the answer to `.claude/jira-integration.json` so future invocations don't re-ask.

5. **Present for review — this is the "editable form."** Claude Code's CLI has no literal form UI; print the fetched fields (title, description, acceptance criteria, labels, status, comments) as formatted chat text and explicitly ask the developer to confirm as-is or describe edits/corrections. Do not proceed to implementation until they give explicit go-ahead — mirrors `bootstrap-ios.md`'s "print a readable summary and ask for explicit confirmation before changing anything" pattern.

6. **If write-back mode is enabled, transition the ticket.** Look up the right transition (commonly "In Progress") via `getTransitionsForJiraIssue`, then call `transitionJiraIssue`. In read-only mode, skip this step entirely.

7. **Implement.** Hand off to the `ios-swiftui-engineer` agent to build the feature under `Features/<FeatureName>/{Views,ViewModels,Models}` (infer `FeatureName` from the ticket if the developer didn't supply one), using the confirmed ticket content — acceptance criteria included — as the working spec and definition of done.

8. **Test.** Hand off to the `test-engineer` agent to write tests covering the ticket's acceptance criteria, mirroring the feature path under `Tests/`.

9. **Verify before done.** Run `swift-code-reviewer` for an architecture/correctness review and `ios-build-test-runner` for a real build + test pass. Don't declare the ticket done until both are clean.

10. **If write-back mode is enabled, offer a completion comment.** Draft a short summary of what was implemented, show it to the developer, and only call `addCommentToJiraIssue` after explicit approval or edits. In read-only mode, skip this step — just report completion in chat as usual.

## Known gaps

- Acceptance criteria field location varies per Jira instance (inline in description vs. a custom field) — this skill checks both common spots but can't guarantee coverage of every custom-field naming scheme.
- `transitionJiraIssue`/`addCommentToJiraIssue` are listed under `permissions.ask` in `.claude/settings.json`, not `allow`, regardless of write-back mode — so Claude Code's own permission prompt is always the final gate on an actual mutating call, even when write-back mode says "automatic." Write-back mode controls *whether the skill ever attempts the call*, not whether Claude Code prompts for it.
