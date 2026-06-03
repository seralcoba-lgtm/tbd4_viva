## Implementación de Auditoría Estructural (Event Trigger DDL)

**Objetivo:** Registrar de manera automática cualquier modificación en la estructura de la base de datos (creación, alteración o eliminación de tablas) para identificar qué usuario realizó el cambio y en qué momento.

**Procedimiento:**

1. Ingresar a la consola interactiva de la base de datos Viva:

```bash
docker exec -it postgres17-recuperado psql -U postgres -d Viva
```

2. Crear la tabla de bitácora para almacenar los logs de auditoría:

```sql
CREATE TABLE public.log_auditoria_ddl (
    id SERIAL PRIMARY KEY,
    usuario TEXT DEFAULT current_user,
    fecha TIMESTAMP WITH TIME ZONE DEFAULT now(),
    tag_comando TEXT,
    tipo_objeto TEXT,
    nombre_objeto TEXT
);
```

Creamos la tabla `log_auditoria_ddl` para que sirviera como un libro de registro (bitácora).

3. Crear la función recolectora de eventos:

```sql
CREATE OR REPLACE FUNCTION public.funcion_auditar_ddl()
RETURNS event_trigger AS $$
DECLARE
    r RECORD;
BEGIN
    FOR r IN SELECT * FROM pg_event_trigger_ddl_commands() LOOP
        INSERT INTO public.log_auditoria_ddl (tag_comando, tipo_objeto, nombre_objeto)
        VALUES (tg_tag, r.object_type, r.object_identity);
    END LOOP;
END;
$$ LANGUAGE plpgsql;
```

El código `CREATE EVENT TRIGGER ... ON ddl_command_end` instruyó a PostgreSQL 17 para que se quede esperando a que cualquier usuario ejecute un comando estructural. Al terminar (`_end`) de ejecutarse el comando, el trigger llama a nuestra función. La función usa la herramienta interna `pg_event_trigger_ddl_commands()` para capturar exactamente quién hizo el cambio, qué tipo de objeto afectó y lo inserta en nuestra tabla de log.

4. Vincular la función a un Trigger de Evento (Event Trigger):

```sql
CREATE EVENT TRIGGER trigger_auditoria_ddl
ON ddl_command_end
EXECUTE FUNCTION public.funcion_auditar_ddl();
```

## Monitoreo de Rendimiento

**Objetivo:** Identificar consultas lentas que degradan el rendimiento del servidor, haciendo un cálculo matemático con el tiempo.

**Procedimiento:**

- Identificar consultas lentas (más de 5 segundos de ejecución):

```sql
SELECT
    pid,
    user,
    now() - query_start AS duracion,
    query,
    state
FROM pg_stat_activity
WHERE state != 'idle'
  AND (now() - query_start) > interval '5 seconds'
ORDER BY duracion DESC;
```

En nuestro script usamos la fórmula `now() - query_start`. Esto resta la hora actual (`now()`) menos la hora en que empezó la consulta, dándonos la duración exacta de ejecución.

Filtramos usando `WHERE state != 'idle'`, lo que descarta a los usuarios que están conectados pero no están haciendo nada.

Añadimos la condición `> interval '5 seconds'`, cumpliendo la directiva de atrapar específicamente a las sesiones "lentas" (aquellas atascadas procesando durante más de 5 segundos).

## Monitoreo y Resolución de Bloqueos (Deadlocks)

**Objetivo:** Detectar/eliminar bloqueos entre transacciones que congelan la aplicación. Identificar la raíz de estos embotellamientos usando una función específica de PostgreSQL.

**Procedimiento:**

1. Detectar bloqueos (Deadlocks):

```sql
SELECT
    pid,
    pg_blocking_pids(pid) AS bloqueado_por,
    now() - query_start AS tiempo_espera,
    query AS consulta_congelada
FROM pg_stat_activity
WHERE cardinality(pg_blocking_pids(pid)) > 0;
```

Utilizamos la función `pg_blocking_pids(pid)` en nuestra consulta de monitoreo. Esta es una función nativa de Postgres que, al pasarle el ID del proceso (PID) de un usuario que está esperando, te devuelve una lista de los PIDs de los usuarios que lo están bloqueando.

Al filtrar con `WHERE cardinality(pg_blocking_pids(pid)) > 0`, obligamos a la base de datos a mostrarnos únicamente a las víctimas del bloqueo y a sus culpables.

2. Resolver bloqueos (matar el proceso problemático): Reemplazar `PID_BLOQUEADOR` por el número de proceso identificado en la consulta anterior.

```sql
SELECT pg_terminate_backend(PID_BLOQUEADOR);
```

Una vez identificado el culpable, se utilizó `pg_terminate_backend(PID_BLOQUEADOR)`, que es el equivalente a forzar el cierre de esa sesión conflictiva, resolviendo así el atasco o deadlock y liberando el flujo de trabajo del contenedor.

# Gestión de Sesiones y Monitoreo de PostgreSQL

## Consulta de Sesiones Activas

Para identificar las conexiones activas en la base de datos se utilizó la vista del sistema `pg_stat_activity`.

```sql
SELECT pid, usename, datname, state, query
FROM pg_stat_activity;
```

Esta consulta permitió visualizar los procesos activos, los usuarios conectados y las consultas ejecutadas en la base de datos Viva.

---

## Cancelación de Sesiones

Se realizó la cancelación de una sesión utilizando la función `pg_cancel_backend()`.

```sql
SELECT pg_cancel_backend(4143);
```

Resultado obtenido:

```text
t
```

La respuesta `t` (true) indica que la consulta asociada a la sesión fue cancelada exitosamente.

---

## Terminación de Sesiones

Se realizó la finalización completa de una sesión mediante la función `pg_terminate_backend()`.

```sql
SELECT pg_terminate_backend(4143);
```

Resultado obtenido:

```text
t
```

La respuesta `t` (true) confirma que la sesión fue terminada correctamente y eliminada de la lista de conexiones activas.

---

## Activación de pg_stat_statements

Se verificó que el módulo de monitoreo estuviera habilitado.

```sql
SHOW shared_preload_libraries;
```

Resultado:

```text
pg_stat_statements
```

Esto confirma que PostgreSQL tiene habilitada la extensión necesaria para recopilar estadísticas de ejecución de consultas.

---

## Identificación de Consultas Costosas

Se ejecutó la siguiente consulta:

```sql
SELECT query,
       calls,
       total_exec_time,
       mean_exec_time
FROM pg_stat_statements
ORDER BY total_exec_time DESC
LIMIT 5;
```

Resultados obtenidos:

| Consulta                                          | Calls | Tiempo Total (ms) |
| ------------------------------------------------- | ----- | ----------------- |
| CREATE DATABASE viva_restore                      | 1     | 31.160266         |
| CREATE EXTENSION IF NOT EXISTS pg_stat_statements | 1     | 7.535217          |
| Consulta de índices del catálogo                  | 43    | 4.466104          |
| Consulta de atributos de tablas                   | 44    | 4.034244          |
| Consulta de descripciones                         | 1     | 2.976242          |

La consulta con mayor tiempo de ejecución fue `CREATE DATABASE viva_restore`, registrando aproximadamente 31.16 ms.
