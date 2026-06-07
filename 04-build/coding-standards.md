# Coding Standards

Language-agnostic rules for all production code. Concrete lint/format settings are a stack choice — the active preset's lint config is the executable form of this doc; where the two could disagree, the config wins and this doc gets patched.

## Naming & structure

1. Names come from the project glossary (`docs/glossary.md`) — one concept, one name, at every layer.
2. Functions do one thing at one level of abstraction. If a name needs "and", split it.
3. Keep functions small enough to read without scrolling; extract when a block needs an explanatory comment to be understood.
4. No dead code, commented-out code, or speculative abstractions ("might need it later"). Delete; git remembers.
5. Module boundaries follow the dependency direction rules in `03-design/architecture-standards.md`.

## Correctness habits

6. Make illegal states unrepresentable: prefer narrow types/enums over booleans-and-strings; parse, don't validate twice.
7. Prefer immutability: reassignment and shared mutable state are the exception and need a reason.
8. Handle errors at the boundary that can act on them; never swallow one silently. No empty catch blocks.
9. All external input is validated at the boundary before use (schema validation per the stack's validation library).
10. No magic values: name constants where the value carries meaning.

## Comments & formatting

11. Comments explain *why*, not *what*. If the *what* needs a comment, rewrite the code first.
12. Formatting is never discussed in review: the formatter's output is canonical, enforced by the pre-commit hook and CI.
13. Production code does not ship debug output (console/print logging outside the structured logger — see `07-operations/observability.md`).

## For AI agents specifically

14. Match the surrounding file's idiom (naming, error style, comment density) — consistency beats personal style.
15. Never introduce a new pattern when an existing one fits; search first (see `00-governance/agent-operating-rules.md` §4).
16. Never weaken lint config, type strictness, or suppress diagnostics (`ignore` pragmas) to make a check pass; fix the code or raise the rule's validity as a question.

## Enforcement
- Mechanism: lint rule
- Config: stacks/nextjs-default/lint-config/biome.json
- Fallback if unenforceable: n/a — rules 1–13 are enforced or reviewable via the lint config; agent-habit rules 14–16 are covered by the self-review checklist's standing items.

## Bootstrap
- What new-project.sh injects for this standard: the preset's lint config (`biome.json`) copied to the project root, wired into pre-commit (lint-staged) and CI (lint job).
