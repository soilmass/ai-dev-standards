#!/usr/bin/env bash
# Site-integrity gate — the enforcement mechanism for 03-design/multi-page-site-coherence.md.
#
# Given a BUILT + SERVED site (Next.js production server, `next start`), this crawls
# every internal page reachable from the start URL and FAILS the build on any of:
#   (a) a broken internal / nav / footer link (any non-2xx/3xx, i.e. a 404 etc.);
#   (b) header / footer / nav that differ across pages (chrome must be identical —
#       it is what makes a multi-page site feel like one site, not six pages);
#   (c) a sitemap ↔ routes mismatch (a URL in /sitemap.xml that 404s, or a crawled
#       page that the sitemap omits);
#   (d) a breadcrumb / "parent" pointer aimed at a missing page.
#
# Dependency-light by design: curl for fetching, node (already required by the
# Next.js toolchain) for HTML parsing. No Playwright, no crawler library — this
# runs against the SSR/SSG HTML the server returns, which is the link surface
# search engines and no-JS clients see.
#
# Allowed-404 budget is ZERO (CAL-F01): a single broken internal link fails CI.
# A multi-page site whose own nav 404s is broken, full stop — see the audit that
# motivated this gate (three site-wide 404s shipped to a "passing" build).
#
# Usage (from the project root, against a running server):
#   bash scripts/check-site-integrity.sh http://localhost:3000
# CI wires it after `next start`; see ci/pr.yml (job: site-integrity).
set -uo pipefail

readonly BASE_URL="${1:-${SITE_BASE_URL:-http://localhost:3000}}"
# Allowed broken-internal-link budget. Keep == CAL-F01 in 00-governance/calibration.md
# and == ci/pr.yml ALLOWED_404. Raising it weakens the gate — do not.
readonly ALLOWED_404="${ALLOWED_404:-0}"
# Page cap so a misconfigured site (or an accidental infinite link graph) can't
# make the gate run unbounded. Generous for a marketing/docs site.
readonly MAX_PAGES="${MAX_PAGES:-200}"

command -v curl >/dev/null 2>&1 || { echo "FATAL: curl not found" >&2; exit 2; }
command -v node >/dev/null 2>&1 || { echo "FATAL: node not found" >&2; exit 2; }

# Normalize: strip any trailing slash from the base so joins are predictable.
origin="${BASE_URL%/}"

# Confirm the server is actually up before crawling — a connection failure here
# is an operator/CI error (server not started), reported distinctly from a 404.
if ! curl -fsS -o /dev/null --max-time 10 "$origin/" 2>/dev/null; then
  echo "FATAL: cannot reach $origin/ — start the production server first" >&2
  echo "       (e.g. 'next build && next start -p <port>', then pass the URL)." >&2
  exit 2
fi

workdir="$(mktemp -d)"
trap 'rm -rf "$workdir"' EXIT

fail=0
violate() { echo "  ✗ $1" >&2; fail=1; }

# fetch <path> -> writes body to $workdir/page.html, echoes the HTTP status code.
# Follows no redirects itself (curl -L off) so we can SEE a 3xx; the link checker
# treats 2xx/3xx as healthy and 4xx/5xx as broken.
fetch_status() {
  local path="$1" out="$2"
  curl -s -o "$out" -w '%{http_code}' --max-time 20 "$origin$path" 2>/dev/null || echo "000"
}

# ---------------------------------------------------------------------------
# Pass 1: BFS crawl from "/", collecting every reachable internal page and the
# normalized chrome (header/nav/footer) signature of each, plus every internal
# link target and its discovered-from page (for the broken-link report).
# ---------------------------------------------------------------------------
declare -A seen          # path -> 1 once crawled
declare -A status_of     # path -> http status
declare -A chrome_of     # path -> chrome signature hash
declare -A linkedfrom    # target-path -> first page that linked to it
queue=("/")
crawled=()

extract() {
  # extract <html-file> <mode>
  #   mode=links  -> internal link hrefs, one per line, normalized to path
  #   mode=chrome -> a stable signature of header+nav+footer text+link structure
  node - "$1" "$2" <<'NODE'
const fs = require("fs");
const [file, mode] = [process.argv[2], process.argv[3]];
const html = fs.readFileSync(file, "utf8");

// crude-but-deterministic tag slice: pull the innerHTML of the first matching
// landmark element. Good enough for chrome comparison since the markup is
// server-rendered and identical-by-construction when the layout is shared.
function slice(tag, attrMatch) {
  // matches <tag ...>...</tag>, non-greedy, first occurrence; attrMatch optional
  const re = new RegExp(`<${tag}\\b[^>]*>([\\s\\S]*?)<\\/${tag}>`, "i");
  const m = html.match(re);
  if (!m) return "";
  if (attrMatch && !new RegExp(attrMatch, "i").test(m[0])) return "";
  return m[1];
}

// Navigational links ONLY: the href of <a> anchors. We deliberately do NOT
// follow <link rel=...>, <script src>, <img>, or preload hrefs — those are
// assets, not pages, and crawling them would conflate the asset graph with the
// page graph (false chrome/sitemap findings on .js/.css/.woff2/.svg).
function anchorHrefs(fragment) {
  const out = [];
  const re = /<a\b[^>]*?\bhref\s*=\s*"([^"]*)"/gi;
  let m;
  while ((m = re.exec(fragment)) !== null) out.push(m[1]);
  return out;
}

if (mode === "links") {
  const all = anchorHrefs(html);
  const internal = new Set();
  for (let h of all) {
    if (!h) continue;
    h = h.trim();
    // skip non-navigational and external schemes
    if (h.startsWith("#")) continue;
    if (/^[a-z][a-z0-9+.-]*:/i.test(h) && !h.startsWith("/")) {
      // has a scheme (http:, mailto:, tel:, etc.) — external, skip
      continue;
    }
    if (h.startsWith("//")) continue; // protocol-relative -> external
    if (!h.startsWith("/")) continue; // only absolute-internal paths
    // strip query + fragment for the route-existence check
    h = h.split("#")[0].split("?")[0];
    if (h.length > 1 && h.endsWith("/")) h = h.slice(0, -1); // normalize trailing slash
    if (h === "") h = "/";
    internal.add(h);
  }
  // Trailing newline matters: the bash `while read` consumer drops a final
  // line that has no newline terminator (POSIX), which would silently lose the
  // last-sorted link (e.g. /terms).
  const list = [...internal].sort();
  process.stdout.write(list.length ? list.join("\n") + "\n" : "");
} else if (mode === "chrome") {
  // Header (role=banner or <header>), primary + footer <nav>, and footer
  // (role=contentinfo or <footer>). We compare the LINK STRUCTURE + visible
  // text of the chrome, normalized: this is what "identical across pages" means.
  const header = slice("header") || sliceByRole("banner");
  const footer = slice("footer") || sliceByRole("contentinfo");
  function sliceByRole(role) {
    const re = new RegExp(`<(\\w+)\\b[^>]*role=["']${role}["'][^>]*>([\\s\\S]*?)<\\/\\1>`, "i");
    const m = html.match(re);
    return m ? m[2] : "";
  }
  function chromeSig(fragment) {
    // links (targets) + their anchor text, in document order; whitespace-collapsed.
    const parts = [];
    const re = /<a\b[^>]*href\s*=\s*"([^"]*)"[^>]*>([\s\S]*?)<\/a>/gi;
    let m;
    while ((m = re.exec(fragment)) !== null) {
      const target = m[1].split("#")[0].split("?")[0] || "#";
      const txt = m[2].replace(/<[^>]+>/g, " ").replace(/\s+/g, " ").trim();
      parts.push(`${target}|${txt}`);
    }
    return parts.join("\n");
  }
  // Re-evaluate header/footer now that sliceByRole is defined (hoisting note:
  // function declarations hoist, so the calls above are fine).
  const sig = "HEADER\n" + chromeSig(header) + "\nFOOTER\n" + chromeSig(footer);
  process.stdout.write(sig);
}
NODE
}

while [ "${#queue[@]}" -gt 0 ]; do
  path="${queue[0]}"
  queue=("${queue[@]:1}")
  [ -n "${seen[$path]:-}" ] && continue
  seen[$path]=1

  if [ "${#crawled[@]}" -ge "$MAX_PAGES" ]; then
    echo "  · reached MAX_PAGES=$MAX_PAGES — stopping crawl" >&2
    break
  fi

  out="$workdir/page.html"
  code="$(fetch_status "$path" "$out")"
  status_of[$path]="$code"

  # A page reached by crawling that does not return 2xx is a broken internal link.
  if [[ ! "$code" =~ ^(2[0-9][0-9]|3[0-9][0-9])$ ]]; then
    # reported in the broken-link pass below; don't parse a non-page body
    crawled+=("$path")
    continue
  fi
  crawled+=("$path")

  # Chrome signature for the consistency check (pass 2).
  chrome_of[$path]="$(extract "$out" chrome | node -e 'const s=require("fs").readFileSync(0,"utf8");const c=require("crypto").createHash("sha256").update(s).digest("hex");process.stdout.write(c)')"

  # Enqueue internal links, and record where each was first linked from.
  while IFS= read -r link; do
    [ -z "$link" ] && continue
    [ -z "${linkedfrom[$link]:-}" ] && linkedfrom[$link]="$path"
    [ -z "${seen[$link]:-}" ] && queue+=("$link")
  done < <(extract "$out" links)
done

# ---------------------------------------------------------------------------
# (a) Broken internal/nav/footer links: any internal link target that resolves
#     to a non-2xx/3xx status. We check EVERY discovered target (not just the
#     ones we crawled), since a link discovered on the last page still counts.
#     This category is budgeted by ALLOWED_404 (default 0) — the OTHER checks
#     (chrome/sitemap/breadcrumb) are always fatal, so we report broken links
#     here but only flip `fail` once the count exceeds the budget. That keeps
#     the ALLOWED_404 knob honest: at 0 a single broken link fails; were it
#     ever raised, the exit code would actually track the budget.
# ---------------------------------------------------------------------------
broken_count=0
declare -A checked_target
for target in "${!linkedfrom[@]}"; do
  [ -n "${checked_target[$target]:-}" ] && continue
  checked_target[$target]=1
  code="${status_of[$target]:-}"
  if [ -z "$code" ]; then
    code="$(fetch_status "$target" "$workdir/probe.html")"
    status_of[$target]="$code"
  fi
  if [[ ! "$code" =~ ^(2[0-9][0-9]|3[0-9][0-9])$ ]]; then
    broken_count=$((broken_count + 1))
    echo "  ✗ broken internal link: $target -> HTTP $code (linked from ${linkedfrom[$target]})" >&2
  fi
done

if [ "$broken_count" -gt "$ALLOWED_404" ]; then
  echo "  → $broken_count broken internal link(s); budget is $ALLOWED_404 (CAL-F01)." >&2
  fail=1
fi

# ---------------------------------------------------------------------------
# (b) Header / footer / nav consistency: every successfully-crawled page must
#     share ONE chrome signature. The home page is the reference.
# ---------------------------------------------------------------------------
ref_path=""
ref_sig=""
for path in "${crawled[@]}"; do
  sig="${chrome_of[$path]:-}"
  [ -z "$sig" ] && continue            # non-page (already counted as broken)
  if [ -z "$ref_sig" ]; then
    ref_path="$path"; ref_sig="$sig"; continue
  fi
  if [ "$sig" != "$ref_sig" ]; then
    violate "chrome mismatch: $path has a different header/nav/footer than $ref_path (shared chrome must be identical across pages)"
  fi
done

# ---------------------------------------------------------------------------
# (c) Sitemap ↔ routes coherence: parse /sitemap.xml (Next.js emits it from
#     app/sitemap.ts), and assert (i) every sitemap URL resolves 2xx, and
#     (ii) every crawled page appears in the sitemap. A missing sitemap is a
#     warning (not every site ships one), but a present-and-incoherent one fails.
# ---------------------------------------------------------------------------
sm="$workdir/sitemap.xml"
sm_code="$(fetch_status "/sitemap.xml" "$sm")"
if [[ "$sm_code" =~ ^2[0-9][0-9]$ ]]; then
  # Extract <loc> paths, normalized to origin-relative.
  mapfile -t sitemap_paths < <(node - "$sm" "$origin" <<'NODE'
const fs = require("fs");
const [file, origin] = [process.argv[2], process.argv[3]];
const xml = fs.readFileSync(file, "utf8");
const out = new Set();
const re = /<loc>\s*([^<]+?)\s*<\/loc>/gi;
let m;
while ((m = re.exec(xml)) !== null) {
  let u = m[1].trim();
  if (u.startsWith(origin)) u = u.slice(origin.length);
  try { u = new URL(u, origin).pathname; } catch { /* keep as-is */ }
  if (u.length > 1 && u.endsWith("/")) u = u.slice(0, -1);
  if (u === "") u = "/";
  out.add(u);
}
const sm = [...out].sort();
process.stdout.write(sm.length ? sm.join("\n") + "\n" : "");
NODE
)
  declare -A in_sitemap
  for sp in "${sitemap_paths[@]}"; do
    [ -z "$sp" ] && continue
    in_sitemap[$sp]=1
    code="${status_of[$sp]:-}"
    if [ -z "$code" ]; then code="$(fetch_status "$sp" "$workdir/probe.html")"; fi
    if [[ ! "$code" =~ ^(2[0-9][0-9]|3[0-9][0-9])$ ]]; then
      violate "sitemap↔routes: /sitemap.xml lists $sp but it returns HTTP $code"
    fi
  done
  # Every crawled, healthy page should be discoverable via the sitemap.
  for path in "${crawled[@]}"; do
    [ -z "${chrome_of[$path]:-}" ] && continue   # skip non-pages
    if [ -z "${in_sitemap[$path]:-}" ]; then
      violate "sitemap↔routes: crawlable page $path is absent from /sitemap.xml"
    fi
  done
else
  echo "  · no /sitemap.xml (HTTP $sm_code) — skipping sitemap coherence check" >&2
fi

# ---------------------------------------------------------------------------
# (d) Breadcrumb / parent-pointer validity: any element marked as a breadcrumb
#     (aria-label~="breadcrumb", or BreadcrumbList JSON-LD) whose link targets a
#     path that does not resolve 2xx is a broken parent pointer. Reuses the
#     already-fetched status map.
# ---------------------------------------------------------------------------
for path in "${crawled[@]}"; do
  [ -z "${chrome_of[$path]:-}" ] && continue
  out="$workdir/bc.html"
  # re-fetch (cheap; cached page would be nicer but we kept the crawl streaming)
  fetch_status "$path" "$out" >/dev/null
  mapfile -t bc_targets < <(node - "$out" <<'NODE'
const fs = require("fs");
const html = fs.readFileSync(process.argv[2], "utf8");
const targets = new Set();

// 1) <nav aria-label="...breadcrumb..."> ... </nav>  (case-insensitive contains)
const navRe = /<nav\b([^>]*)>([\s\S]*?)<\/nav>/gi;
let m;
while ((m = navRe.exec(html)) !== null) {
  if (/aria-label\s*=\s*"[^"]*breadcrumb[^"]*"/i.test(m[1])) {
    const hr = /href\s*=\s*"([^"]*)"/gi;
    let h;
    while ((h = hr.exec(m[2])) !== null) targets.add(h[1]);
  }
}
// 2) BreadcrumbList JSON-LD item URLs
const ldRe = /<script\b[^>]*type=["']application\/ld\+json["'][^>]*>([\s\S]*?)<\/script>/gi;
while ((m = ldRe.exec(html)) !== null) {
  try {
    const data = JSON.parse(m[1].trim());
    const nodes = Array.isArray(data) ? data : [data];
    for (const n of nodes) {
      if (n && n["@type"] === "BreadcrumbList" && Array.isArray(n.itemListElement)) {
        for (const li of n.itemListElement) {
          const item = li && (li.item || li["@id"]);
          const url = typeof item === "string" ? item : item && item["@id"];
          if (url) targets.add(url);
        }
      }
    }
  } catch { /* ignore non-JSON ld blocks */ }
}

const out = [];
for (let t of targets) {
  t = (t || "").trim();
  if (!t || t.startsWith("#")) continue;
  // origin-relative only; strip scheme+host if it's our own origin handled by caller
  out.push(t.split("#")[0].split("?")[0]);
}
const bc = [...new Set(out)];
process.stdout.write(bc.length ? bc.join("\n") + "\n" : "");
NODE
)
  for t in "${bc_targets[@]}"; do
    [ -z "$t" ] && continue
    # normalize an absolute URL on our origin to a path
    case "$t" in
      "$origin"*) t="${t#"$origin"}" ;;
      http*://*) continue ;;  # external breadcrumb target — out of scope
    esac
    [ "${t#/}" = "$t" ] && t="/$t"
    [ "${#t}" -gt 1 ] && t="${t%/}"
    code="${status_of[$t]:-}"
    if [ -z "$code" ]; then code="$(fetch_status "$t" "$workdir/probe.html")"; fi
    if [[ ! "$code" =~ ^(2[0-9][0-9]|3[0-9][0-9])$ ]]; then
      violate "breadcrumb/parent on $path points at $t which returns HTTP $code"
    fi
  done
done

# ---------------------------------------------------------------------------
echo "" >&2
echo "crawled ${#crawled[@]} page(s) from $origin" >&2
if [ "$fail" -ne 0 ]; then
  echo "" >&2
  echo "SITE-INTEGRITY FAILED: the site is not internally coherent. A multi-page site" >&2
  echo "whose own links 404 or whose chrome drifts page-to-page is broken — fix the" >&2
  echo "links/chrome, do not raise ALLOWED_404 (03-design/multi-page-site-coherence.md)." >&2
  exit 1
fi
echo "site integrity OK — ${broken_count} broken internal link(s) (budget ${ALLOWED_404}), consistent chrome, sitemap coherent, breadcrumbs valid" >&2
