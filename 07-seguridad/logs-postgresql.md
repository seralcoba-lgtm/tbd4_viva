# Configuración de Logs Nativos en PostgreSQL

## Objetivo

Implementar mecanismos de auditoría básica mediante los logs nativos de PostgreSQL para registrar conexiones y cambios estructurales en la base de datos.

## Configuración Aplicada

Se habilitaron los siguientes parámetros:

```sql
ALTER SYSTEM SET log_connections = 'on';
ALTER SYSTEM SET log_statement = 'ddl';
```

## Verificación

```sql
SHOW log_connections;
SHOW log_statement;
```

Resultado:

```text
log_connections = on
log_statement = ddl
```

## Beneficios

* Registro de conexiones a la base de datos.
* Seguimiento de operaciones DDL.
* Apoyo en tareas de auditoría y seguridad.

