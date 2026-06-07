// db/schema.ts — copied from the preset's project-config/ by new-project.sh.
// Governing doc: 03-design/data-modeling.md. Drizzle (postgres) schema starter.
// Conventions encoded below (change deliberately, keep them consistent):
//   - Table/column names: plural table, snake_case columns (rule 1).
//   - Surrogate PK, system-generated (rule 4): defaultRandom() ships a UUIDv4
//     today; prefer a time-sortable UUIDv7 default once your Postgres/driver
//     exposes one (uuidv7()) — UUIDv7 is the documented preference.
//   - created_at / updated_at: timestamptz, DB-defaulted, one mechanism
//     everywhere (rule 7). updated_at uses $onUpdate so the data layer is the
//     single writer of the bump.
//   - Soft delete is a PER-TABLE EXPLICIT decision (rule 8): users below uses
//     HARD delete (no deleted_at). Add `deleted_at` only on tables where history
//     or recovery matters — and then every read path must filter null.

import { sql } from 'drizzle-orm';
import { pgTable, text, timestamp, uuid } from 'drizzle-orm/pg-core';

export const users = pgTable('users', {
  id: uuid('id').primaryKey().defaultRandom(), // see UUIDv7 note above
  email: text('email').notNull().unique(), // natural key gets a unique constraint, not PK status (rule 4)
  created_at: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
  updated_at: timestamp('updated_at', { withTimezone: true })
    .notNull()
    .defaultNow()
    .$onUpdate(() => sql`now()`),
  // No deleted_at: this table uses hard delete (data-modeling.md rule 8).
});
