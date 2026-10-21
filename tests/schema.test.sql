-- pgTAP Schema Tests for Incident Retrieval Schema Repair
-- Run via: npm test (uses pg_prove)
-- Requires: pgTAP and pgvector extensions available in the test database.

BEGIN;
SELECT plan(20);

-- ============================================================
-- TABLE EXISTENCE
-- ============================================================
SELECT has_table('incidents', 'incidents table exists');
SELECT has_table('incident_chunks', 'incident_chunks table exists');

-- ============================================================
-- COLUMN TYPES
-- ============================================================
SELECT col_type_is('incident_chunks', 'id', 'bigint', 'incident_chunks.id is BIGINT (BIGSERIAL)');
SELECT col_type_is('incident_chunks', 'incident_id', 'bigint', 'incident_chunks.incident_id is BIGINT FK');
SELECT col_type_is('incident_chunks', 'chunk_text', 'text', 'incident_chunks.chunk_text is TEXT');
SELECT col_type_is('incident_chunks', 'embedding', 'vector(1536)', 'incident_chunks.embedding is vector(1536) not TEXT');
SELECT col_type_is('incident_chunks', 'team_id', 'bigint', 'incident_chunks.team_id filter metadata exists as BIGINT');
SELECT col_type_is('incident_chunks', 'severity', 'text', 'incident_chunks.severity filter metadata exists as TEXT');
SELECT col_type_is('incident_chunks', 'created_at', 'timestamp with time zone', 'incident_chunks.created_at is TIMESTAMPTZ');

-- ============================================================
-- NOT NULL
-- ============================================================
SELECT col_not_null('incident_chunks', 'incident_id', 'incident_id is NOT NULL');
SELECT col_not_null('incident_chunks', 'chunk_text', 'chunk_text is NOT NULL');
SELECT col_not_null('incident_chunks', 'embedding', 'embedding is NOT NULL');
SELECT col_not_null('incident_chunks', 'team_id', 'team_id is NOT NULL');
SELECT col_not_null('incident_chunks', 'severity', 'severity is NOT NULL');
SELECT col_not_null('incident_chunks', 'created_at', 'created_at is NOT NULL');

-- ============================================================
-- FOREIGN KEY
-- ============================================================
SELECT fk_ok('incident_chunks', 'incident_id', 'incidents', 'id', 'incident_chunks.incident_id references incidents.id');

-- ============================================================
-- INDEXES
-- ============================================================
SELECT has_index('incident_chunks', 'idx_incident_chunks_embedding', 'ANN vector index on embedding exists');
SELECT has_index('incident_chunks', 'idx_incident_chunks_incident_id', 'B-tree index on incident_id exists');

-- ============================================================
-- REJECTED SHAPE MUST BE REMOVED
-- ============================================================
SELECT hasnt_column('incidents', 'embedding', 'rejected single embedding column on incidents must be removed');

-- ============================================================
-- BEHAVIOURAL: ON DELETE CASCADE
-- ============================================================
INSERT INTO incidents (id, title, description, team_id, severity)
  VALUES (900001, 'seed', 'seed body', 1, 'P1');
INSERT INTO incident_chunks (incident_id, chunk_text, embedding, team_id, severity)
  VALUES (900001, 'seed chunk', array_fill(0::real, ARRAY[1536])::vector, 1, 'P1');
DELETE FROM incidents WHERE id = 900001;
SELECT is(
  (SELECT count(*) FROM incident_chunks WHERE incident_id = 900001),
  0::bigint,
  'deleting an incident cascades and removes its chunks (ON DELETE CASCADE)'
);

SELECT * FROM finish();
ROLLBACK;
