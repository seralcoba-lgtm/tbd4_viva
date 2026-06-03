# Implementación de pgAudit

## Objetivo

Implementar auditoría avanzada utilizando la extensión pgAudit para registrar actividades realizadas en PostgreSQL.

## Instalación

Se instaló el paquete:

```bash
postgresql-17-pgaudit
```

## Configuración

Archivo:

```text
postgresql.conf
```

Parámetro configurado:

```conf
shared_preload_libraries = 'pg_stat_statements,pgaudit'
```

## Creación de la extensión

```sql
CREATE EXTENSION pgaudit;
```

## Verificación

```sql
SELECT extname
FROM pg_extension
WHERE extname = 'pgaudit';
```

Resultado:

```text
pgaudit
```

## Beneficios

- Auditoría detallada de actividades.
- Trazabilidad de operaciones ejecutadas.
- Apoyo a controles de seguridad.
