-- migrations/001_retrieval_schema.sql
-- Retrieval storage for "similar past incidents". incidents is the source of
-- truth; incident_chunks is derived data (chunked + embedded incident text).

-- pgvector provides the vector type and the HNSW index access method.
CREATE EXTENSION IF NOT EXISTS vector;

CREATE TABLE incidents (
  id          BIGSERIAL PRIMARY KEY,
  title       TEXT NOT NULL,
  description TEXT NOT NULL,          -- the text that gets chunked + embedded
  team_id     BIGINT NOT NULL,
  severity    TEXT NOT NULL CHECK (severity IN ('P1','P2','P3','P4')),
  status      TEXT NOT NULL CHECK (status IN ('open','ack','resolved','closed')) DEFAULT 'open',
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE incident_chunks (
  id          BIGSERIAL PRIMARY KEY,
  incident_id BIGINT NOT NULL REFERENCES incidents(id) ON DELETE CASCADE,  -- a chunk has no meaning without its incident
  chunk_text  TEXT NOT NULL,          -- the source text that was embedded
  embedding   vector(1536) NOT NULL,  -- one vector per chunk
  team_id     BIGINT NOT NULL,        -- denormalised filter metadata (copied from incidents)
  severity    TEXT NOT NULL,          -- denormalised filter metadata (copied from incidents)
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ANN index for the "3 most similar past incidents" query run on every incident open.
CREATE INDEX idx_incident_chunks_embedding
  ON incident_chunks USING hnsw (embedding vector_cosine_ops);

-- "All chunks of this incident": cascade deletes and re-embedding.
CREATE INDEX idx_incident_chunks_incident_id
  ON incident_chunks (incident_id);
