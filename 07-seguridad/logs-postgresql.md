# Configuración de Logs PostgreSQL

## Objetivo

Registrar conexiones y sentencias DDL para fines de auditoría.

## Configuración

```sql
SHOW log_connections;
SHOW log_statement;

##Resultado
log_connections = on
log_statement = ddl

Beneficios
Registro de conexiones.
Seguimiento de cambios estructurales.
Apoyo a auditorías.

