SHOW shared_preload_libraries;

CREATE EXTENSION IF NOT EXISTS pgaudit;

SELECT extname
FROM pg_extension
WHERE extname = 'pgaudit';
