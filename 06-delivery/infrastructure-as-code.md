# Infrastructure as Code

Any infrastructure beyond a managed PaaS — DNS, object storage, queues, IAM roles, networks, the database instance itself — is code, and gets the same rigor as application code: declarative, reviewed, versioned, scanned. Click-ops is undocumented, unreviewable, and drifts. The stack presets target managed/serverless hosting, so this is **reference-only until a project provisions its own infrastructure**; when it does, these rules apply.

## Declare, review, version

1. **Infrastructure is declarative code in the repo, not console clicks.** Use a declarative IaC tool (Terraform/OpenTofu, Pulumi, or the platform's equivalent); the desired state lives in version control, and the console is for reading, not changing. Anything created by hand is drift waiting to bite.
2. **Plan before apply, and review the plan like a diff.** Every change produces a `plan` (the exact create/modify/**destroy** set) that is reviewed before `apply` — a `destroy` on a stateful resource is the IaC equivalent of an unsafe migration. Apply runs from CI with the same least-privilege, provenance, and audit trail as an app deploy (`04-build/supply-chain.md`), never from a laptop with god credentials.
3. **Changes flow through the same git discipline.** IaC PRs follow `_spines/version-control.md` (review, required checks); the plan is posted on the PR so the reviewer sees the blast radius before merge.

## State, secrets, drift

4. **State is remote, locked, and encrypted — never local, never in git.** The state file is the source of truth for what exists; store it in a locking remote backend so two applies can't race, encrypt it at rest, and restrict access. A state file in the repo is both a corruption risk and a secret leak.
5. **Secrets never live in state or in `.tf` files.** State stores resource attributes in **plaintext**, including generated passwords; source secrets from the secret manager / boot-validated env (`04-build/secrets-config.md`), mark them sensitive, and keep them out of committed IaC source.
6. **Drift is detected, not discovered during an incident.** A scheduled `plan` in CI surfaces out-of-band changes (someone clicked something, or a resource was modified externally); reconcile drift deliberately. Pair this with **IaC security scanning** (misconfiguration linting — e.g. public buckets, open security groups) as a CI gate, the infra analogue of the dependency/supply-chain gates.

## Standards basis

- **Terraform / OpenTofu and Pulumi** (developer.hashicorp.com/terraform; opentofu.org; pulumi.com) — declarative desired-state infrastructure, the `plan`/`apply` model, and remote locking state backends: the basis for rules 1–2, 4. (Named as the canonical tools; the specific choice is a per-project ADR, `01-context/adr.template.md`.)
- **Google — Infrastructure as Code & GitOps** (cloud.google.com IaC guidance; "Site Reliability Engineering"/SRE workbook on configuration management) — version-controlled, reviewed, reconciled infrastructure; grounds rules 3 and 6 (drift reconciliation).
- **CIS Benchmarks** and **IaC misconfiguration scanning** (tfsec/checkov/trivy-config category) — the secure-configuration baselines rule 6's scanning gate enforces; complements `_spines/security-privacy.md`.
- **Twelve-Factor — III. Config** and `04-build/secrets-config.md` — the basis for rule 5 (secrets out of state, sourced from the environment/secret manager).

## Enforcement
- Mechanism: none-possible
- Config: n/a — reference only; the IaC tool, state backend, and scanner are per-project (the presets use managed/serverless hosting and ship no IaC).
- Fallback if unenforceable: If this change provisions or modifies infrastructure, it is declarative IaC in the repo with a reviewed plan (no console drift), state is remote/locked/encrypted with no secrets in state or source, and the change passed IaC misconfiguration scanning.

## Bootstrap
- What new-project.sh injects for this standard: nothing — reference only (a project adopting self-managed infrastructure records the IaC tool choice as an ADR and wires its plan/apply + scanning into CI).
