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

---

## Pgaudit.md

Explica la instalación de pgAudit:

```markdown
# Implementación de pgAudit

## Instalación

Se instaló el paquete:

postgresql-17-pgaudit

## Configuración

shared_preload_libraries = 'pg_stat_statements,pgaudit'

## Verificación

```sql
SELECT extname
FROM pg_extension
WHERE extname='pgaudit';

Resultado:

pgaudit

---

## auditoria-dml.md

```markdown
# Auditoría DML

## Tabla de Auditoría

La tabla auditoria_dml almacena:

- Tabla afectada.
- Tipo de operación.
- Usuario.
- Fecha.
- Estado anterior.
- Estado nuevo.

## Operaciones Auditadas

- INSERT
- UPDATE
- DELETE

## Uso de OLD y NEW

INSERT:
- OLD = NULL
- NEW = Registro insertado

UPDATE:
- OLD = Valores anteriores
- NEW = Valores modificados

DELETE:
- OLD = Registro eliminado
- NEW = NULL

evidencia-pruebas.md

# Evidencias de Pruebas

## INSERT

Resultado:

tipo_operacion = INSERT

datos_anteriores = NULL

datos_nuevos = Registro creado

## UPDATE

Resultado:

tipo_operacion = UPDATE

datos_anteriores = Email anterior

datos_nuevos = Email actualizado

## DELETE

Resultado:

tipo_operacion = DELETE

datos_anteriores = Registro eliminado

datos_nuevos = NULL

## Conclusión

Las operaciones INSERT, UPDATE y DELETE fueron registradas correctamente mediante triggers de auditoría.
