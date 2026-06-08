// instrumentation.ts — copied from the preset's project-config/ by new-project.sh.
// Governing doc: 04-build/secrets-config.md (rule 2: env is validated at BOOT,
// never request time). This register() hook is the boot-validation call site:
// Next.js runs it once at server startup. Calling serverEnv() here makes a
// missing/malformed server var fail startup loudly instead of at first request.
//
// Guard on NEXT_RUNTIME === 'nodejs' so the server-only schema is parsed only in
// the Node runtime — the Edge runtime lacks the full server env, and serverEnv
// must never be imported into client/edge bundles (the values are undefined there
// by design). The import is dynamic so the server-only module is not pulled into
// non-Node runtimes.

export async function register() {
  if (process.env.NEXT_RUNTIME === 'nodejs') {
    const { serverEnv } = await import('./env.schema');
    serverEnv(); // throws on invalid config — fails the boot, points at env.schema.ts
  }
}
