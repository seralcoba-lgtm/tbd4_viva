ALTER SYSTEM SET log_connections = 'on';
ALTER SYSTEM SET log_statement = 'ddl';

SELECT pg_reload_conf();
