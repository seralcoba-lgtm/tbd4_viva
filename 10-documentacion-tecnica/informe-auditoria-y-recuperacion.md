# Informe Técnico de Auditoría y Recuperación

## Entorno Utilizado

### Sistema Operativo

Debian GNU/Linux (Trixie)

### Motor de Base de Datos

PostgreSQL 17.10

### Plataforma

Docker

### Base de Datos

Viva

---

# Auditoría Implementada

## Logs Nativos

Se configuró PostgreSQL para registrar conexiones y eventos relevantes mediante los mecanismos nativos de logging.

### Configuración aplicada

```sql
SHOW log_connections;
SHOW log_statement;
SHOW logging_collector;
```

### Resultado

```text
log_connections = on
log_statement = ddl
logging_collector = on
```

La configuración permite registrar conexiones a la base de datos, cambios estructurales y almacenar físicamente los eventos en archivos de log.

---

## Auditoría mediante pgAudit

Se implementó la extensión pgAudit para fortalecer el registro de actividades realizadas sobre la base de datos.

### Verificación de la extensión

```sql
SELECT extname
FROM pg_extension
WHERE extname='pgaudit';
```

### Resultado

```text
pgaudit
```

### Configuración

```sql
SHOW pgaudit.log;
```

### Resultado

```text
read, write, ddl, role
```

La configuración permite auditar:

* Operaciones de lectura (SELECT)
* Operaciones de escritura (INSERT, UPDATE y DELETE)
* Operaciones DDL (CREATE, ALTER y DROP)
* Gestión de roles y privilegios

---

## Auditoría DML

Se implementó un mecanismo de auditoría mediante triggers para registrar cambios realizados sobre tablas críticas del sistema.

### Componentes Implementados

* Tabla: auditoria.auditoria_dml
* Trigger: trg_auditoria_cliente
* Trigger: trg_auditoria_dml_recarga
* Almacenamiento de cambios mediante JSONB

### Operaciones Auditadas

* INSERT
* UPDATE
* DELETE

### Información Registrada

* Usuario de base de datos
* Fecha y hora del evento
* Tabla afectada
* Tipo de operación
* Datos anteriores
* Datos nuevos

La implementación utiliza las funciones:

```sql
to_jsonb(OLD)
to_jsonb(NEW)
```

permitiendo conservar el estado previo y posterior de cada modificación.

---

## Auditoría DDL

Se implementó auditoría estructural mediante Event Triggers para registrar modificaciones realizadas sobre objetos de la base de datos.

### Event Triggers Activos

* trg_audit_ddl
* pgaudit_ddl_command_end
* pgaudit_sql_drop

Estos mecanismos permiten registrar eventos CREATE, ALTER y DROP ejecutados sobre la base de datos.

---

# Monitoreo

Se utilizaron herramientas nativas de PostgreSQL para monitorear actividad, rendimiento y bloqueos.

### Herramientas utilizadas

* pg_stat_activity
* pg_stat_statements
* pg_blocking_pids()

### Capacidades implementadas

* Identificación de consultas lentas.
* Monitoreo de sesiones activas.
* Detección de bloqueos.
* Identificación de consultas costosas.
* Gestión y terminación de sesiones.

---

# Recuperación y Respaldo

## PITR (Point In Time Recovery)

Se implementó recuperación a un punto específico en el tiempo utilizando WAL (Write Ahead Log).

### Configuración utilizada

```text
wal_level = replica
archive_mode = on
archive_command configurado
```

Esta configuración permite reconstruir el estado de la base de datos hasta un instante específico mediante la aplicación secuencial de archivos WAL.

---

## Política de Respaldo

La estrategia de respaldo contempla:

* Respaldo completo semanal.
* Archivado continuo de WAL.
* Almacenamiento persistente de respaldos.
* Procedimientos de recuperación documentados.

---

# Objetivos de Recuperación

## RPO (Recovery Point Objective)

15 minutos.

Representa la pérdida máxima aceptable de información en caso de incidente.

## RTO (Recovery Time Objective)

60 minutos.

Representa el tiempo máximo estimado para restaurar completamente el servicio.

---

# Resultados Obtenidos

* Implementación de auditoría nativa mediante logs PostgreSQL.
* Implementación de auditoría avanzada mediante pgAudit.
* Implementación de auditoría DML con triggers y JSONB.
* Implementación de auditoría DDL mediante Event Triggers.
* Monitoreo de rendimiento y sesiones activas.
* Detección y resolución de bloqueos.
* Configuración de recuperación PITR mediante WAL.
* Definición de políticas de respaldo y objetivos de recuperación.
