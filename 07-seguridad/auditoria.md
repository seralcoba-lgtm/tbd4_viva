## Implementación de Auditoría Estructural (Event Trigger DDL)

### Objetivo

Registrar de manera automática cualquier modificación en la estructura de la base de datos (creación, alteración o eliminación de objetos) para identificar qué usuario realizó el cambio y en qué momento.

### Procedimiento

Se verificó la existencia de los Event Triggers implementados para auditoría estructural mediante la siguiente consulta:

```sql
SELECT evtname,
       evtevent,
       evtenabled
FROM pg_event_trigger;
```

Resultado obtenido:

```text
trg_audit_ddl           | ddl_command_end | O
pgaudit_ddl_command_end | ddl_command_end | O
pgaudit_sql_drop        | sql_drop        | O
```

La implementación utiliza Event Triggers para capturar automáticamente los cambios estructurales realizados en la base de datos. Cuando un usuario ejecuta operaciones DDL como CREATE, ALTER o DROP, PostgreSQL registra estos eventos y los almacena en la tabla de auditoría estructural correspondiente.

---

## Auditoría mediante pgAudit

### Objetivo

Registrar actividades de lectura, escritura, modificaciones estructurales y administración de roles utilizando la extensión pgAudit integrada con PostgreSQL.

### Verificación de la extensión

```sql
SELECT extname
FROM pg_extension
WHERE extname='pgaudit';
```

Resultado obtenido:

```text
pgaudit
```

La consulta confirma que la extensión pgAudit se encuentra instalada y disponible en la base de datos.

### Configuración de Auditoría

```sql
SHOW pgaudit.log;
```

Resultado obtenido:

```text
read, write, ddl, role
```

Esta configuración permite auditar:

* Operaciones de lectura (SELECT)
* Operaciones de escritura (INSERT, UPDATE, DELETE)
* Cambios estructurales (CREATE, ALTER, DROP)
* Gestión de roles y privilegios

### Verificación de Logs Nativos

```sql
SELECT name, setting
FROM pg_settings
WHERE name IN ('log_connections','log_statement');
```

Resultado obtenido:

```text
log_connections | on
log_statement   | ddl
```

La configuración habilita el registro de conexiones a la base de datos y los cambios estructurales ejecutados sobre los objetos de PostgreSQL.

### Verificación de Almacenamiento de Logs

```sql
SHOW logging_collector;
```

Resultado obtenido:

```text
on
```

La activación de logging_collector permite almacenar físicamente los registros generados por PostgreSQL y pgAudit.

### Evidencia de Archivos de Log

```sql
SELECT *
FROM pg_ls_logdir();
```

Resultado obtenido:

```text
postgresql-2026-06-18_014322.log
```

La existencia de archivos de log confirma que PostgreSQL está almacenando los eventos auditados en archivos físicos para su posterior análisis.

---

## Implementación de Auditoría DML mediante Triggers

### Objetivo

Registrar automáticamente las operaciones INSERT, UPDATE y DELETE realizadas sobre las tablas auditadas, conservando tanto los datos anteriores como los nuevos valores.

### Verificación del Trigger de Auditoría

```sql
SELECT trigger_name,
       event_manipulation,
       event_object_table
FROM information_schema.triggers
WHERE event_object_table = 'recarga';
```

Resultado obtenido:

```text
trg_auditoria_dml_recarga | INSERT | recarga
trg_auditoria_dml_recarga | UPDATE | recarga
trg_auditoria_dml_recarga | DELETE | recarga
```

El trigger registra automáticamente todas las operaciones DML ejecutadas sobre la tabla finanzas.recarga.

### Evidencia de Eventos Auditados

```sql
SELECT id_auditoria,
       nombre_tabla,
       tipo_operacion,
       usuario_bd,
       fecha_evento
FROM auditoria.auditoria_dml
ORDER BY id_auditoria DESC;
```

Los registros almacenados muestran el usuario responsable, la fecha del evento, la tabla afectada y el tipo de operación realizada.

### Uso de JSONB para Registrar Cambios

```sql
SELECT
    datos_anteriores,
    datos_nuevos
FROM auditoria.auditoria_dml
WHERE tipo_operacion='UPDATE'
ORDER BY id_auditoria DESC
LIMIT 1;
```

La implementación utiliza las funciones:

```sql
to_jsonb(OLD)
to_jsonb(NEW)
```

permitiendo almacenar en formato JSONB el estado anterior y posterior de cada registro modificado.

De esta manera es posible reconstruir completamente cualquier cambio realizado sobre los datos auditados.

---

## Monitoreo de Rendimiento

### Objetivo

Identificar consultas lentas que puedan afectar el rendimiento del servidor mediante el cálculo del tiempo de ejecución.

### Procedimiento

```sql
SELECT
    pid,
    usename,
    now() - query_start AS duracion,
    query,
    state
FROM pg_stat_activity
WHERE state <> 'idle'
  AND (now() - query_start) > interval '5 seconds'
ORDER BY duracion DESC;
```

La expresión:

```sql
now() - query_start
```

permite calcular el tiempo exacto de ejecución de una consulta activa.

Se utiliza:

```sql
state <> 'idle'
```

para excluir conexiones inactivas y concentrar el análisis únicamente en procesos que se encuentran ejecutando operaciones.

---

## Monitoreo y Resolución de Bloqueos (Deadlocks)

### Objetivo

Detectar sesiones bloqueadas e identificar el origen de los bloqueos que afectan el funcionamiento de la aplicación.

### Detección de Bloqueos

```sql
SELECT
    pid,
    pg_blocking_pids(pid) AS bloqueado_por,
    now() - query_start AS tiempo_espera,
    query AS consulta_congelada
FROM pg_stat_activity
WHERE cardinality(pg_blocking_pids(pid)) > 0;
```

La función:

```sql
pg_blocking_pids(pid)
```

permite identificar qué procesos están bloqueando a otros procesos activos dentro de PostgreSQL.

### Resolución de Bloqueos

```sql
SELECT pg_terminate_backend(<PID>);
```

Donde `<PID>` corresponde al proceso identificado como responsable del bloqueo.

La terminación del proceso libera los recursos bloqueados y restablece el funcionamiento normal de la aplicación.

---

## Gestión de Sesiones y Monitoreo de PostgreSQL

### Consulta de Sesiones Activas

```sql
SELECT pid,
       usename,
       datname,
       state,
       query
FROM pg_stat_activity;
```

Esta consulta permite visualizar usuarios conectados, estado de las sesiones y consultas ejecutadas en la base de datos.

### Cancelación de Sesiones

```sql
SELECT pg_cancel_backend(<PID>);
```

La función cancela la consulta en ejecución manteniendo activa la conexión del usuario.

### Terminación de Sesiones

```sql
SELECT pg_terminate_backend(<PID>);
```

La función finaliza completamente la sesión seleccionada y libera todos los recursos asociados.

---

## Activación de pg_stat_statements

### Verificación

```sql
SHOW shared_preload_libraries;
```

Resultado obtenido:

```text
pgaudit, pg_stat_statements
```

Este resultado confirma que PostgreSQL tiene habilitadas las extensiones necesarias para auditoría y monitoreo de consultas.

### Identificación de Consultas Costosas

```sql
SELECT query,
       calls,
       total_exec_time,
       mean_exec_time
FROM pg_stat_statements
ORDER BY total_exec_time DESC
LIMIT 5;
```

La vista pg_stat_statements permite identificar las consultas que consumen mayor tiempo de ejecución y facilita la optimización del rendimiento del sistema.
