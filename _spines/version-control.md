# Version Control & GitHub Spine

Version control is not a layer — it's the substrate every layer commits through and the platform every gate runs on. This spine doesn't duplicate the layer rules; it shows **where git and the GitHub platform bite in each layer**, and owns the cross-cutting concerns no single layer can: **signing**, **the host-side protection configuration**, the **repository hygiene & community-health files**, and **package publishing**.

## Where it bites, layer by layer

| Layer | Git/GitHub obligation | Lives in |
|---|---|---|
| 02 Product | Issues use templates that force a problem statement and scope check; the PR template carries the definition-of-done | `01-context/issue-templates/`, `stacks/<preset>/ci/PULL_REQUEST_TEMPLATE.md` |
| 04 Build | Conventional Commits + `<type>/<slug>` branch names (commit-msg + pre-commit hooks); **signed commits/tags** (below); secrets never committed | `04-build/git-standards.md`, `04-build/secrets-config.md`, this spine |
| 05 Verification | Every PR job is a **required check**, and merges require them green + up-to-date; **require signed commits** (below) | `05-verification/ci-pipeline.md`, this spine |
| 06 Delivery | Versioning scheme (CalVer apps / SemVer libs), changelog generated from commits, tag-triggered GitHub Releases, **package publishing** (below) | `06-delivery/release-process.md`, this spine |
| 07 Operations | Released artifacts carry provenance/SBOM that travels with the tag/package | `04-build/supply-chain.md`, `07-operations/audit-log-retention.md` |
| 08 Maintenance | Dependency updates arrive as grouped, Conventional-Commit PRs on a cadence | `08-maintenance/dependency-updates.md`, `stacks/<preset>/dependabot.yml` |
| 00 Governance | This repo's own git/GitHub model (a deliberate, documented deviation) | `00-governance/repo-operating-model.md` |

## Commit & tag signing — owned here

1. **Commits and tags on the protected branch are signed and show GitHub "Verified".** Signing proves *who* authored a commit; an unsigned history lets anyone with push access forge authorship. Use **SSH signing** (simplest — reuse an SSH key), **GPG**, or **keyless Sigstore** (`gitsign`) where CI is the signer and there is no long-lived key to leak. The injected `scripts/configure-signing.sh` sets `commit.gpgsign`/`tag.gpgsign` true, `gpg.format`, and the signing key, and registers the public key on GitHub.
2. **Signing is enforced server-side, not by honor system.** Branch protection's **"require signed commits"** rejects unsigned pushes to the protected branch (`scripts/setup-branch-protection.sh` enables it). Local `commit.gpgsign` without the server rule is a convenience, not a guarantee.
3. **Release tags are annotated *and* signed, and immutable once pushed.** A release tag is the identity a deploy, changelog, and provenance bind to (`06-delivery/release-process.md`, `04-build/supply-chain.md`), so it must not move. The tag-protection ruleset over `refs/tags/v*` requires signatures and blocks deletion + non-fast-forward — a published tag can never be silently re-pointed.

## GitHub-platform configuration — owned here

4. **Repository protection is applied as code, not clicked.** `scripts/setup-branch-protection.sh` (injected, idempotent) is the reproducible host-side step the bootstrap itself cannot perform: it derives the required-check list straight from `pr.yml` (so it never drifts), enables required signatures, and creates the `protect-version-tags` ruleset. Re-run it whenever the job set changes.
5. **No bypass, for anyone.** Admin enforcement is on (solo means you are the admin and so is every agent run); force-push and deletion are blocked on the default branch and on version tags. An escape hatch for you is an escape hatch for a compromised token.

## Repository hygiene & community-health files — owned here

6. **`.gitattributes` normalizes the tree.** `* text=auto eol=lf` forces LF in the repository and on checkout, so a Windows clone never reintroduces CRLF and CI (Linux) never sees a spurious whole-file diff; shell scripts and (where present) the Dockerfile are pinned LF or they won't execute; the lockfile is marked `linguist-generated` and `-diff`; binary assets are declared `binary`.
7. **The GitHub community-health set ships with every project:** `CODEOWNERS` (who must review which paths — pairs with branch protection's code-owner review), `SECURITY.md` (how to report a vulnerability), `CONTRIBUTING.md` (setup + workflow, pointing at `CLAUDE.md` for stack specifics), and `.github/ISSUE_TEMPLATE/` (bug + feature templates with `config.yml` disabling blank issues). The PR template (`stacks/<preset>/ci/`) is the matching contribution gate.
8. **Security disclosure is private and coordinated.** `SECURITY.md` routes vulnerabilities to a private report (GitHub advisory or a contact), never a public issue, and the issue chooser's `config.yml` enforces that routing — the intake half of the breach-handling discipline in `_spines/security-privacy.md` rule 9.

## Package publishing — owned here

9. **Default to private; publishing is a deliberate decision.** An application is never published — its `package.json` carries `"private": true`. Publishing is only for code meant for external consumers (a library or CLI), and adopting it is recorded as an ADR (`01-context/adr.template.md`); it then versions strictly by SemVer (`06-delivery/release-process.md`).
10. **A published package declares exactly its publish surface.** Set `version` (SemVer), `files`/`exports`/`types` (what consumers may import — no dev-only or source files leak), `license` (an SPDX id), `repository`, and `sideEffects`; verify the tarball with `npm pack --dry-run` (and a packaging linter) before release so nothing private ships and nothing public is missing.
11. **Publish from CI, with provenance, over short-lived credentials.** `npm publish --provenance` records a Sigstore-backed attestation binding the package to the exact source commit and build (`04-build/supply-chain.md`); authenticate to the registry via the CI's OIDC/trusted-publishing identity, never a long-lived token committed or pasted into env. Where a token is unavoidable, it is an automation token with 2FA on the account.
12. **The package, its provenance, and its SBOM travel together.** Publishing happens on the release tag; the SBOM and provenance generated at build accompany the artifact (registry attestation or release assets), so a consumer can verify what they install (`04-build/supply-chain.md` rules 9–11). GitHub Packages is the registry option when scope is the org.

## Standards basis

- **Git signing** (`git-scm.com`, `git config commit.gpgsign`/`tag.gpgsign`, `gpg.format ssh|openpgp`) and **GitHub commit-signature verification** (docs.github.com — the "Verified" badge, SSH/GPG signing keys, and the *require signed commits* branch-protection rule): the basis for signing rules 1–3.
- **Sigstore / `gitsign`** (sigstore.dev) — keyless, identity-based signing with short-lived certificates; the CI-signer option in rule 1, the same trust model as the supply-chain attestations.
- **GitHub repository rulesets & branch protection** (docs.github.com) — required status checks, required signatures, tag rulesets (deletion / non-fast-forward / required-signatures), no-admin-bypass; the basis for the platform-configuration rules 4–5 and tag immutability (rule 3).
- **OpenSSF Scorecard** (`Branch-Protection`, `Signed-Releases`, `Token-Permissions`, `Pinned-Dependencies`) — the security-health checks this spine's posture is built to score well on; corroborates protection-as-code, signed releases, and least-privilege CI tokens.
- **gitattributes(5)** (`text`, `eol`, `binary`, `linguist-generated`) and **GitHub community-health files / `linguist`** (docs.github.com) — the basis for hygiene rules 6–8 (line-ending normalization, CODEOWNERS, SECURITY/CONTRIBUTING, issue templates).
- **npm docs — `package.json` (`files`, `exports`, `publishConfig`, `private`) + `npm publish --provenance` + trusted publishing/OIDC** (docs.npmjs.com) and **SLSA v1.0** (slsa.dev) — the basis for publishing rules 9–12; provenance is the npm realization of the supply-chain attestation posture.
- **Semantic Versioning 2.0.0** (semver.org, incl. the `v`-prefix tag note) and **Keep a Changelog 1.1.0** (keepachangelog.com) — versioning and changelog discipline this spine points at, owned in `06-delivery/release-process.md`.
- Builds on `04-build/git-standards.md` (commit/branch rules — owned there), `05-verification/ci-pipeline.md` (required checks), `08-maintenance/dependency-updates.md` (dependency PRs), and `_spines/security-privacy.md` (secrets, disclosure). This spine adds the signing, host-protection, hygiene, and publishing layer on top of them.

## Enforcement
- Mechanism: git hook
- Config: stacks/nextjs-default/hooks/pre-commit + hooks/commit-msg (commit/branch discipline) + stacks/nextjs-default/ci/pr.yml (required checks) — the mechanical subset; the host-side pieces (required checks, required signatures, tag protection) are applied by the injected `scripts/setup-branch-protection.sh` (library source: 01-context/setup-branch-protection.template.sh), and signing by the injected `scripts/configure-signing.sh` (source: 01-context/configure-signing.template.sh). Each layer row above names its own gate.
- Fallback if unenforceable: n/a — commit/branch rules are hook-gated, required checks + signatures + tag protection are branch-protection-gated once the helper is run, and the judgment pieces (community-health files filled, publish surface correct) ride the existing git and security fallback lines in the self-review checklist.

## Bootstrap
- What new-project.sh injects for this standard: the git hooks (`pre-commit`, `commit-msg` + their configs), the CI workflows (`pr.yml`/`nightly.yml`/`release.yml`) and `dependabot.yml`, the PR template, `.gitattributes`, the community-health set (`.github/CODEOWNERS`, `SECURITY.md`, `CONTRIBUTING.md`, `ISSUE_TEMPLATE/`), and the two host-side helpers `scripts/setup-branch-protection.sh` (branch + tag protection + required signatures) and `scripts/configure-signing.sh` (commit/tag signing). Running those two helpers once after the first push is the only manual step.
