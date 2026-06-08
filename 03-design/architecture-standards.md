# Architecture Standards

Layering, dependency direction, and module boundaries — the rules that keep a codebase navigable as it grows. The concrete directory names are a stack/project choice (recorded in the project's architecture map); the direction rules are not.

## Layering

1. Three conceptual layers, whatever the directories are called:
   - **Interface** — UI components, route handlers, CLI entries. Translates the outside world to domain calls.
   - **Domain** — business logic, validation schemas, types. Knows nothing about HTTP, rendering, or storage.
   - **Infrastructure** — persistence, external services, framework plumbing.
2. **Dependencies point inward:** interface → domain ← infrastructure. The domain imports neither.
3. Cross-cutting concerns (logging, config) are imported from a single module each, not re-implemented per layer.

## Module boundaries

4. A module's public surface is its index/entry; reaching into another module's internals (deep imports) is a boundary violation — enforced by the lint config's restricted-import rules.
5. Shared code is extracted **on the second use, by the third use** — duplication twice is cheaper than a wrong abstraction.
6. Each module owns its data shape: other modules consume its exported types/schemas, never re-declare them (see `03-design/api-contract-design.md`).
7. Circular dependencies are defects, not style issues: break the cycle by extracting the shared piece downward.

## Change rules

8. A new component, boundary, or external dependency updates the project's architecture map in the same PR (`01-context/architecture-map.template.md`, `_spines/documentation.md`).
9. Architectural decisions — new layer, new service, new boundary — get an ADR before the implementing PR.
10. Frameworks live at the edges: domain logic that imports the framework is domain logic you can't test cheaply or move (the testing strategy depends on this rule).

## Layer-review prompts

The lint only catches deep relative imports; full layering is review-carried. Apply these to every diff (reviewer or agent):

- Does any domain module import interface or infrastructure? (Rule 2 — the domain imports neither.)
- Does new code reach into another module's internals instead of its entry/index? (Rule 4.)
- Did a new boundary, component, or external dependency update the architecture map? (Rule 8.)
- Is framework code creeping inward past the edges into domain logic? (Rule 10.)

## Standards basis

- **Clean Architecture — the Dependency Rule** (R. C. Martin): source-code dependencies point only inward; an inner circle names nothing from an outer one. This is the literal basis of rules 2 and 10 (frameworks at the edges) — the domain is the inner circle and imports neither interface nor infrastructure.
- **Hexagonal / Ports & Adapters** (A. Cockburn, 2005): the application core is reached only through ports, with adapters at the boundary; isomorphic to Clean's rings. Grounds the "interface/infrastructure are adapters around an untouched domain" framing.
- **C4 model** (Simon Brown, https://c4model.com): hierarchical Context → Container → Component → Code views as the model-as-code description of structure. The architecture map (rule 8) is the project's C4-style Component/Container record; new boundaries update it in the same PR.
- **12-Factor App** (https://12factor.net): III (config in the environment), IV (backing services as attached resources) underpin rule 12's single config/single cross-cutting module and the "infrastructure at the edge" placement.
- **ADR** (Architecture Decision Records, M. Nygard): one immutable record per significant decision — basis for rule 9 (an ADR precedes the implementing PR).

## Enforcement
- Mechanism: lint rule
- Config: stacks/nextjs-default/lint-config/biome.json (restricted-imports rules blocking deep relative cross-module imports)
- Fallback if unenforceable: n/a — import-boundary violations are lint-enforced; layer placement judgment is reviewable via the architecture map, which the CI docs-check forces to stay current.

## Bootstrap
- What new-project.sh injects for this standard: the lint config with restricted-import rules, plus `docs/architecture-map.md` for recording the project's concrete layering.
