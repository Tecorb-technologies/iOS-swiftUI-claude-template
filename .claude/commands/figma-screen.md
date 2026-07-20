---
description: Build a SwiftUI screen from a Figma frame — pulls design context, reconciles tokens against Core/DesignSystem, generates View + ViewModel + tests.
argument-hint: "<figma-frame-url-or-node> [FeatureName]"
---

Build a SwiftUI screen from the Figma frame in `$ARGUMENTS`. `$1` is the Figma frame URL or node; `$2` is the optional `FeatureName` (infer a sensible one from the design if omitted).

Run this flow in order — don't skip the design read or the token reconciliation:

1. **Ensure the figma MCP is connected.** Confirm `.mcp.json` has a `figma` server. If it isn't connected, tell the developer to run `claude mcp add --transport http figma https://mcp.figma.com/mcp --scope project` then `/mcp → figma → Authenticate`, and stop until it's connected — don't guess pixel values without live design data.
2. **Pull design context.** Call `get_design_context` on the frame/node for structure, layout, and variables, and `get_variable_defs` for the raw token values. Use `get_screenshot` only as a visual sanity check.
3. **Check Code Connect.** Call `get_code_connect_map` for this file; if it returns mappings, plan to reuse the mapped `Core/DesignSystem` components rather than rebuilding them.
4. **Implement.** Hand off to the `ios-swiftui-engineer` agent to build the screen under `Features/<FeatureName>/{Views,ViewModels,Models}`, following the `design-to-code` skill — map-don't-invent every spacing/color/type value against `Core/DesignSystem/{Spacing,ColorTokens,Typography}.swift`, and surface any flagged mismatch instead of inlining it. Treat Figma's reference code as structure and values only; write idiomatic SwiftUI.
5. **Test.** Hand off to the `test-engineer` agent to write unit tests for the ViewModel and a snapshot test for the View, mirroring the feature path under `Tests/`.
6. **Verify before done.** Run `swift-code-reviewer` for an architecture/correctness review and `ios-build-test-runner` for a real build + test pass. Don't declare the screen done until both are clean.
