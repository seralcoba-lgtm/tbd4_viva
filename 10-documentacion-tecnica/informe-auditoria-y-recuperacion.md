# Informe Técnico de Auditoría y Recuperación

## Entorno Utilizado

### Sistema Operativo

Debian GNU/Linux (Trixie)

### Motor de Base de Datos

PostgreSQL 17.10

### Plataforma

Docker

## Auditoría Implementada

### Logs Nativos

Configuración aplicada:

```sql
SHOW log_connections;
SHOW log_statement;
```

Resultado:

```text
log_connections = on
log_statement = ddl
```

### pgAudit

Configurado mediante:

```text
shared_preload_libraries = 'pg_stat_statements,pgaudit'
```

Extensión instalada:

```sql
CREATE EXTENSION pgaudit;
```

### Auditoría DML

Implementación:

- Tabla auditoria_dml.
- Función fn_auditoria_dml().
- Trigger trg_auditoria_cliente.

Operaciones auditadas:

- INSERT
- UPDATE
- DELETE

## Recuperación y Respaldo

### PITR

Configurado mediante:

- wal_level = replica
- archive_mode = on
- archive_command configurado

### Política de Respaldo

- Respaldo completo semanal.
- Archivado continuo de WAL.

### RPO y RTO

- RPO: 15 minutos
- RTO: 60 minutos

## Conclusiones

Se implementaron mecanismos de auditoría, trazabilidad y recuperación de información utilizando herramientas nativas de PostgreSQL y la extensión pgAudit.

Las pruebas realizadas demostraron el correcto funcionamiento de la auditoría DML y la generación de archivos WAL necesarios para recuperación PITR.
