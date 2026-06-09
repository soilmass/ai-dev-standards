# Per-Page Quality Baseline

A site is not its home page. **Every route the site ships — not the home page, not the first N pages, not "the important ones" — meets the same quality bar.** This standard removes per-page quality variance: a legal page, a deep nested article, and the marketing landing page are held to one identical floor. The single most common multi-page failure mode is a strong home page hiding weak interior pages — a bar that samples only the first few routes certifies a site it never actually inspected.

The bar has four parts: an accessibility floor, a heading-structure rule, a unique-and-bounded text-metadata rule, and a complete-metadata rule. Each is stated as a flat per-route obligation with no exceptions for "secondary" pages.

## 1. The accessibility floor — identical on every route

1. Every route meets the accessibility bar defined in `05-verification/a11y-perf-gates.md` (WCAG 2.2 AA): the Lighthouse accessibility category at or above its score floor (CAL-C03), **and zero axe-core violations of `serious` or `critical` impact**. A `moderate`/`minor` axe finding is logged for paydown, not a release blocker; a `serious`/`critical` one blocks. There is no "home page is AA, interior pages are best-effort" — the floor is route-independent.
2. The gate that enforces this runs across **every sitemap route**, not only the home page — see `05-verification/a11y-perf-gates.md` § "Route coverage". A page that exists but is never crawled is a page whose accessibility is unverified, which this standard treats as failing.
3. The non-machine-decidable half of WCAG (focus order, alt-text meaning, keyboard traps, the composite-widget contracts in `03-design/ui-accessibility-patterns.md`) is held to the same per-route bar via the self-review checklist — reviewed for each route's distinct content, not assumed to carry over from the home page.

## 2. Exactly one `<h1>`, no skipped levels — on every route

4. Every route has **exactly one** `<h1>`, and it names that page's primary subject (not the site name on every page). Zero `<h1>`s leaves the page without a document title for assistive technology; two or more destroys the single-outline contract AT and search engines rely on.
5. Heading levels descend without gaps: an `<h3>` never appears before an `<h2>` exists in the outline above it. Skipped levels (`<h1>` → `<h3>`) are a WCAG 1.3.1 structure defect and a Lighthouse `heading-order` failure — flagged on the route where they occur, not waived because the home page's outline is clean.
6. Headings describe structure, not styling. A heading chosen for its font size rather than its place in the outline is a violation even when it renders correctly.

## 3. A unique, bounded `<title>` and meta description — per route

7. Every route ships a **non-empty, page-unique** `<title>` and `<meta name="description">`. "Unique" means no two routes share the same string — a templated title that resolves identically across pages (e.g. the bare site name on every route) fails this rule. Search engines and tab/bookmark UIs use these to disambiguate pages; duplicates make distinct pages indistinguishable.
8. The `<title>` length sits in the band **30–60 characters** (CAL-C17). Below the floor it under-describes the page; above the ceiling it is truncated in search results and browser tabs, so the disambiguating tail is lost.
9. The meta description length sits in the band **70–160 characters** (CAL-C16). Too short wastes the snippet; too long is truncated mid-sentence in the result listing.
10. These bands are per-route obligations: a page whose title or description falls outside the band fails on that route regardless of how the rest of the site scores. The Lighthouse SEO category's `document-title` and `meta-description` audits are the per-route presence gate; the length bands and cross-route uniqueness are the additional bar this standard adds on top.

## 4. Complete metadata — per route

11. Every route declares a **canonical URL** (`<link rel="canonical">`) pointing at the route's own absolute URL — never a single site-wide canonical that collapses every page onto the home page (a self-inflicted duplicate-content and indexing defect).
12. Every route declares complete **Open Graph** metadata (`og:title`, `og:description`, `og:url`, `og:image`, `og:type`) and **Twitter Card** metadata (`twitter:card`, and the title/description/image it needs for the chosen card type). Per-page OG/Twitter values are page-specific, not the site-wide defaults stamped on every route — a shared social card on a deep page misrepresents what is being shared. The referenced `og:image` must resolve (200, not 404); social-image cohesion and `sizes`/format correctness are owned by `03-design/graphics-asset-cohesion.md`.
13. The route's language is declared (`<html lang>`) and its viewport meta is present — both are per-route document properties Lighthouse SEO/accessibility audit on the route they render on.

## 5. No per-page variance — the rule that ties the four together

14. There is **no quality tier below the floor**. Every obligation in §§1–4 applies to every route the site serves to a user or exposes in its sitemap, with no "secondary page" exemption. If a route cannot meet the bar it is fixed or removed from the shipped surface — it is not shipped at a lower grade.
15. A new route inherits the full bar at creation, not at some later hardening pass. Adding a page means adding a page that already meets §§1–4; "we'll do metadata later" is how the interior of a site rots while the home page stays polished.

## Standards basis

- **WCAG 2.2 Level AA** (W3C Recommendation, 12 Dec 2024, https://www.w3.org/TR/WCAG22/): grounds §1 (the AA conformance target, applied per route) and §2 — **1.3.1 Info and Relationships** (programmatic heading structure / outline) and the **2.4.6 Headings and Labels** / **2.4.10 Section Headings** expectations that headings describe their section. WCAG conformance is claimed per-page, which is precisely why the floor cannot be a sampled-subset claim.
- **axe-core impact levels** (Deque, dequeuniversity.com/rules/axe): the `minor`/`moderate`/`serious`/`critical` taxonomy that grounds rule 1's serious+critical-block / moderate+minor-log split — the same severity split the unit-tier axe checks in `05-verification/a11y-perf-gates.md` use.
- **Lighthouse SEO & accessibility audits** (GoogleChrome/lighthouse): `document-title` (a `<title>` exists), `meta-description` (a non-empty description exists), `heading-order` (no skipped heading levels), `html-has-lang`, `crawlable-anchors`, and `link-text` are the per-route audits that mechanize parts of §§1–4; the SEO category floor is CAL-C05, the accessibility floor CAL-C03. Lighthouse audits one URL per run — the multi-route coverage in `05-verification/a11y-perf-gates.md` is what makes "every route" enforceable rather than aspirational.
- **Google Search title-link & snippet guidance** (developers.google.com/search/docs/appearance): titles and meta descriptions are used to generate the result's title link and snippet, and over-long values are truncated in the listing — the basis for the 30–60 / 70–160 character bands (rules 8–9), which are conventional "fits the SERP without truncation, says enough to disambiguate" ranges, not Google-mandated hard limits (Google measures pixels, but character bands are the reviewable proxy).
- **Open Graph protocol** (ogp.me) and **Twitter/X Cards** (developer-grade card markup): the required-property sets in rule 12; `og:image` must resolve to be usable by the consuming platform.
- **rel=canonical** (developers.google.com/search/docs/crawling-indexing/consolidate-duplicate-urls): a per-page self-referential canonical is the documented way to declare the preferred URL for each page; a site-wide canonical to the home page is the named anti-pattern rule 11 forbids.

## Enforcement
- Mechanism: CI job
- Config: stacks/nextjs-default/ci/lighthouserc.json (a11y CAL-C03 + SEO CAL-C05 floors, run per route) + stacks/nextjs-default/ci/pr.yml (Lighthouse job, every sitemap route per `05-verification/a11y-perf-gates.md` § "Route coverage")
- Fallback if unenforceable: n/a — the machine-decidable subset (per-route Lighthouse a11y + SEO floors across every sitemap route, zero serious/critical axe violations, `document-title`/`meta-description`/`heading-order`/`html-has-lang` audits) is CI-gated; the per-route remainder this standard adds — cross-route title/description uniqueness, the 30–60 / 70–160 character bands, exactly-one-`<h1>` naming the page subject, and complete page-specific canonical + OG/Twitter values — rides the per-route accessibility-baseline review the UI standard already carries (`03-design/ui-design-system.md` rule 8, reviewed for each route's distinct content) plus the general "run every item against the full diff" pass in `05-verification/code-review-standard.md`.

## Bootstrap
- What new-project.sh injects for this standard: nothing new beyond the existing `lighthouserc.json` (the a11y + SEO floors) and the PR workflow that runs the Lighthouse gate across every sitemap route — the per-route coverage is a property of how that injected gate is invoked (`05-verification/a11y-perf-gates.md`), not a separate artifact.
