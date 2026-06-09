# Secrets Promotion

Config and secrets both differ by environment, but they differ in opposite directions: config carries a safe default everywhere and only changes when an environment needs it to; secrets carry no default anywhere and must be supplied per environment or the process refuses to start. This doc owns the cross-**environment** promotion story — which secret each environment needs, how a value moves (or pointedly does not move) between local, preview, and production, and how rotation keeps them from silently diverging. The boot-validated schema and the rotation-as-remediation mechanics are owned by `04-build/secrets-config.md`; this doc references that machinery and governs what flows across the environment boundary, not how a single environment validates itself.

## A. Defaults vs. secrets

1. **Config has a safe default in source; a secret never does.** A configuration value that the app can run with unchanged — a timeout, a page size, a feature default — ships its safe value in the repo and is overridden only where an environment diverges. A secret has no in-source value of any kind, not even an empty string or a placeholder that "works" in development; its absence is the only legitimate source-tree state (`04-build/secrets-config.md` rule 6).
2. **The two are declared in the same schema but on opposite footings.** The boot-validated schema (`04-build/secrets-config.md`) carries config as optional-with-default and secrets as required-no-default. A secret that has been given a default to make local startup convenient has been reclassified as config by accident — that is a review violation, because it hides a missing real value behind a fake one.

## B. Per-environment classification

3. **Every secret is classified by which environments need it.** Before a secret is introduced it is recorded against the environment matrix (`06-delivery/deployment-strategy.md` Environments table: Local / Preview / Production) as needed-or-not in each. A secret needed only in production is not silently expected locally; a secret needed everywhere is provisioned everywhere. The classification is the contract the schema and the rotation step both read from.
4. **"Needed in an environment" names the scope, not just the presence.** The classification records not only *whether* an environment needs the secret but *which* credential that environment is entitled to — a non-production, narrowly scoped grant for local and preview; the real, fully scoped grant for production only. Two environments needing "the same secret" almost always means two different credentials behind one schema key, never one shared value.

## C. The production-secret boundary

5. **A real production secret never lands in a local or preview environment.** Production credentials exist only in the production host's settings (`04-build/secrets-config.md` rule 11); they are never copied into a developer's local env file, a preview deploy, a CI variable used by non-production jobs, or a fixture. The blast radius of a leaked credential is the set of places it has ever existed — keeping production values out of every lower environment is what bounds that set to one.
6. **Preview and local use scoped, non-production credentials against non-production data.** Lower environments authenticate to their own sandboxed dependencies with their own least-privilege grants, and they read synthetic or seeded data only — never production data (`06-delivery/deployment-strategy.md` Environments table; `03-design/data-privacy.md`). A preview that needs production-shaped data uses a sanitized, de-identified copy, because pointing a lower environment at the production datastore both leaks production data downward and drags a production credential into a less-trusted environment.
7. **Promotion of a value is a deliberate, narrow act — and for most secrets it is forbidden.** Config defaults flow upward freely because they carry no risk. Secrets do not "promote" the way config does: each environment is provisioned independently with its own value. Where a value genuinely must be identical across environments (a third-party key with no per-environment issuance), that sameness is a recorded decision, not a convenience, and the lowest-trust environment still gets the most-scoped grant the vendor allows.

## D. Rotation across environments

8. **Rotation updates the value in every environment that needs it, in one change.** When a secret is rotated — on schedule, on suspicion, or immediately because it touched git (`_spines/security-privacy.md` rule 3, `04-build/secrets-config.md` rule 8) — the new value is written to each environment its classification names, as a single coordinated change. A rotation that updates production but leaves preview on the old value has created a silent divergence the schema cannot catch, because each environment still validates against its own copy.
9. **Environments must not be able to silently diverge.** The set of environments holding a given secret is governed by its classification (section B), and rotation operates over that whole set. An environment that quietly falls out of sync — kept on a stale value, or never provisioned with a newly required secret — is a configuration drift bug of the same family the deployment flow's no-manual-host-edits rule guards against (`06-delivery/deployment-strategy.md` rule 3).

## E. Failing at boot, not at first request

10. **A missing per-environment secret fails at boot, never at first request.** Each environment's process validates its required secrets against the schema at startup (`04-build/secrets-config.md` rule 2); a secret the environment's classification says it needs, but which is absent or malformed, kills startup with a named error rather than serving traffic until the first request that happens to reach the unconfigured code path. This is what turns an under-provisioned environment into an immediate, loud failure instead of a latent one.
11. **A per-environment misconfiguration is caught where it is introduced, not in production.** Because preview deploys boot the same schema (`06-delivery/deployment-strategy.md` promotion flow), a secret that production will need but that was never classified or provisioned surfaces as a failed preview boot during the PR, not as a production incident after merge. The boundary rules (section C) and the boot-validation rule together mean the only way a secret reaches production is by being correctly classified, scoped, and present in every environment that validated before it.

## Standards basis

- **12-Factor App — Factor III (Config)** (https://12factor.net/config) — strict separation of config from code, with config (including credentials) stored in the environment and varying *only* by environment. The litmus test ("could the codebase be open-sourced without compromising any credentials?") is the basis for section A's no-default-secret rule and for treating each environment's values as independent rather than baked into the artifact.
- **OWASP Secrets Management Cheat Sheet** (https://cheatsheetseries.owasp.org/cheatsheets/Secrets_Management_Cheat_Sheet.html) — keep secrets out of source, scope them to the least privilege and the narrowest environment, isolate non-production from production secrets, and rotate on a defined cadence and on any compromise. Grounds the per-environment classification (section B), the production-secret boundary (section C), and the coordinated rotation across environments (section D); the leak-blast-radius framing of rule 5 follows its "limit exposure" guidance.
- Ties to the layer machinery this doc references but does not duplicate: `04-build/secrets-config.md` owns the boot-validated schema and rotation-first remediation; `06-delivery/deployment-strategy.md` owns the environment matrix and the no-manual-host-edits promotion flow; `03-design/data-privacy.md` owns why lower environments never touch production data.

## Enforcement
- Mechanism: none-possible
- Config: n/a
- Fallback if unenforceable: Confirm no production secret has entered a local or preview environment, that preview/local use scoped non-production credentials against non-production data only, and that any rotated or newly required secret was applied to every environment its classification names so none silently diverge.

## Bootstrap
- What new-project.sh injects for this standard: nothing — reference only (the env schema and per-environment isolation come from `04-build/secrets-config.md`'s bootstrap; this doc governs how values cross the environment boundary).
