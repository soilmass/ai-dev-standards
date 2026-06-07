// tests/unit/validation.example.test.ts — copied by new-project.sh.
// Governing docs: 04-build/testing-strategy.md (unit tier: validation schemas)
// and 02-product/acceptance-criteria.md (every criterion tests the unhappy path,
// not just the happy one). This demonstrates the boundary-validation pattern:
// a Zod schema is asserted for BOTH the accept case and explicit reject cases.
// Replace the inline schema with the real one under test (e.g. a Server Action's
// input schema imported from your app); keep the accept + reject structure.

import { describe, expect, it } from 'vitest';
import { z } from 'zod';

const signUpSchema = z.object({
  email: z.string().email(),
  age: z.number().int().min(18),
});

describe('signUpSchema', () => {
  it('accepts a valid payload', () => {
    const result = signUpSchema.safeParse({ email: 'ada@example.com', age: 36 });
    expect(result.success).toBe(true);
  });

  it('rejects a malformed email (unhappy path)', () => {
    const result = signUpSchema.safeParse({ email: 'not-an-email', age: 36 });
    expect(result.success).toBe(false);
    if (!result.success) {
      expect(result.error.issues[0]?.path).toEqual(['email']);
    }
  });

  it('rejects an out-of-range value (unhappy path)', () => {
    const result = signUpSchema.safeParse({ email: 'ada@example.com', age: 12 });
    expect(result.success).toBe(false);
  });

  it('rejects a missing required field (unhappy path)', () => {
    const result = signUpSchema.safeParse({ email: 'ada@example.com' });
    expect(result.success).toBe(false);
  });
});
