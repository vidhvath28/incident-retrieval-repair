-- migrations/001_retrieval_schema.sql (CURRENT — BROKEN)
--
-- Incident retrieval storage for the "similar past incidents" AI feature.
-- This draft has intentional errors. Fix it to match the retrieval spec in
-- the assignment question. When you are done, all 20 pgTAP tests must pass.

-- MISSING: CREATE EXTENSION IF NOT EXISTS vector;
--          The vector(n) type and the HNSW index come from the pgvector
--          extension. Without it, vector(1536) does not exist.

CREATE TABLE incidents (
  id          BIGSERIAL PRIMARY KEY,
  title       TEXT NOT NULL,
  description TEXT NOT NULL,
  team_id     BIGINT NOT NULL,
  severity    TEXT NOT NULL CHECK (severity IN ('P1','P2','P3','P4')),
  status      TEXT NOT NULL CHECK (status IN ('open','ack','resolved','closed')) DEFAULT 'open',
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE incident_chunks (
  id          SERIAL PRIMARY KEY,                 -- wrong: should be BIGSERIAL
  incident_id INTEGER REFERENCES incidents(id),   -- wrong: wrong type, missing NOT NULL, missing ON DELETE
  chunk_text  TEXT,                               -- wrong: missing NOT NULL
  embedding   TEXT,                               -- wrong: should be vector(1536) NOT NULL, not TEXT
  -- MISSING: team_id   BIGINT NOT NULL   (denormalised filter metadata)
  -- MISSING: severity  TEXT   NOT NULL   (denormalised filter metadata)
  created_at  TIMESTAMP DEFAULT now()             -- wrong: should be TIMESTAMPTZ NOT NULL
);

-- BUG: single embedding bolted onto incidents — rejected shape.
-- An incident's long, multi-paragraph description must be split into several
-- chunks, each with its own vector. One embedding per incident is the wrong
-- model. Remove this line; embeddings live per-chunk in incident_chunks.
ALTER TABLE incidents ADD COLUMN embedding TEXT;  -- wrong: remove entirely

-- MISSING: ANN index on incident_chunks.embedding
--          CREATE INDEX idx_incident_chunks_embedding
--            ON incident_chunks USING hnsw (embedding vector_cosine_ops);

-- MISSING: B-tree index on incident_chunks.incident_id
--          CREATE INDEX idx_incident_chunks_incident_id
--            ON incident_chunks (incident_id);
