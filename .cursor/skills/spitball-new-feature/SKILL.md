---
name: spitball-new-feature
description: >-
  Brainstorms and stress-tests new feature ideas for wsl-builds before implementation: grounds in repo docs and Cursor rules, applies a short evaluation rubric, flags convention conflicts, suggests refinements and alternatives. Use when the user wants to explore an idea—e.g. "I'd like to add", "I'm thinking of doing", "considering", "new feature", "brainstorm", "spitball", "should we", "what if we", "idea for", or similar phrasing—and early design or scope discussion is more appropriate than coding immediately.
---

# Spitball new feature (wsl-builds)

Use this skill for **ideation and early scope**, not for shipping code, unless the user explicitly asks to implement afterward.

## Guardrails

- Default to **read-only** exploration of the repository. Do **not** edit files, create branches, or run commands that mutate state unless the user clearly asks to implement or run something.
- Give **direct feedback** when an idea is weak, redundant with existing behavior, or poor cost/benefit—politely but plainly.

## Workflow

1. **Ground in the repo (read-only)**  
   - Read **in full** repo root [`README.md`](../../../README.md) and [`CONTRIBUTING.md`](../../../CONTRIBUTING.md).  
   - If the idea targets a particular build, read that [`builds/<name>/README.md`](../../../builds) (and only what is relevant).  
   - Skim rule files that constrain design: at least [`.cursor/rules/bash-component-patterns.mdc`](../../rules/bash-component-patterns.mdc). When the idea touches the root Build List or end-user prose in `README.md`, read [`.cursor/rules/readme-user-facing.mdc`](../../rules/readme-user-facing.mdc). For doc-heavy ideas, read [`.cursor/rules/documentation-style.mdc`](../../rules/documentation-style.mdc). If the idea would touch `./test/run-tests.sh`, Bats, Docker harness, or `wsl-builds.conf` handling, skim [`test/README.md`](../../../test/README.md) and the **Harness vs user config** notes in [`.cursor/rules/project-context.mdc`](../../rules/project-context.mdc).

2. **Restate the request**  
   - Short paraphrase of what the user wants.  
   - List **assumptions** you are making.  
   - List **open questions** where the request is underspecified.

3. **Structured feedback (rubric)**  
   For each dimension below, give a few concise bullets and an optional **confidence** (low / medium / high) for that row when the idea is fuzzy.  
   - **User / problem fit** — who benefits, how often, is the pain real.  
   - **Alignment** — fit with wsl-builds architecture (builder, `builds/<name>/`, components, `src/`, one focused thing per component).  
   - **Implementation difficulty** — rough effort, unknowns, integration points.  
   - **Risk** — breaking changes, security, data loss, WSL/Ubuntu constraints.  
   - **Test / CI impact** — Bats in Docker, harness config, user-visible strings that tests assert on.  
   - **Maintenance** — dependencies, ongoing ownership, doc drift.  
   - **Scope** — smallest viable slice vs full solution.  
   - Optional **Overall** — one-sentence takeaway.

4. **Conflicts with repo conventions**  
   Include a subsection **Conflicts with repo conventions** (or state **None apparent**). When there is a conflict, name the convention and point to the relevant path—e.g. component/dispatch pattern, root Build List rules, `wsl-builds.conf` / `Dockerfile.dockerignore` anchoring, documentation-style (no bold around inline code in prose), contributor test expectations.

5. **Refinements and alternatives**  
   - Offer **one to three refinements** that narrow scope, reduce risk, or improve fit.  
   - Offer **alternatives** when useful; label each as **common pattern** (industry-wide) vs **fits this repo** where that distinction matters.

6. **Close the loop**  
   End by asking the user to choose:  
   - **(A)** More follow-up questions in this chat, or  
   - **(B)** Structured scoping next—goals, non-goals, success criteria, explicit out-of-scope items, constraints, and a rough acceptance sketch—still **without** implementing unless they ask.
