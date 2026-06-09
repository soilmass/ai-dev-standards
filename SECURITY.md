# Security Policy

This is a standards / documentation library — markdown, shell scripts, and config
templates. It ships no runtime service. A "security issue" here means a flaw in an
**injected config or helper** that would weaken a bootstrapped project (a hook that
fails open, a CI gate that doesn't gate, a generated config that leaks, a helper
that sends the wrong API request) or a vulnerability in the library's own tooling.

## Reporting

Report privately — do **not** open a public issue or pull request:

- **Preferred:** GitHub → **Security → Advisories → "Report a vulnerability"** on
  this repository (private vulnerability reporting).
- **Otherwise:** contact the maintainer through their GitHub profile.

Please name the affected file or script and explain how it weakens a consuming
project. Allow a reasonable window to fix before public disclosure, and do not
include real secrets or credentials in your report.
