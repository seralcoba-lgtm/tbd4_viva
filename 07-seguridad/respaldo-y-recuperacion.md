## Estrategia de Respaldo y Recuperación (Backup & Restore)

**Objetivo:** Simular un desastre aislando los datos de producción y clonándolos en un entorno limpio para garantizar la continuidad del negocio.

**Procedimiento (ejecutado desde la terminal de WSL):**

1. **Extracción del respaldo (Backup):** Se genera un volcado en formato personalizado (comprimido y optimizado) en la carpeta `/tmp` del contenedor.

```bash
docker exec -t postgres17-recuperado pg_dump -U postgres -F c -b -v -f /tmp/viva_backup.dump Viva
```

2. **Preparación del entorno destino:** Se crea una base de datos en blanco para recibir la información.

```bash
docker exec -it postgres17-recuperado psql -U postgres -c "CREATE DATABASE viva_restore;"
```

3. **Inyección de datos (Restauración):** Se utiliza la herramienta de restauración nativa leyendo el archivo generado previamente.

```bash
docker exec -t postgres17-recuperado pg_restore -U postgres -d viva_restore -v /tmp/viva_backup.dump
```

Primero, se garantizó el aislamiento creando un "lienzo en blanco" con el comando `CREATE DATABASE viva_restore;`.

El parámetro `-d` (`database`) fue la clave aquí: le indicó estrictamente a PostgreSQL que todo el contenido del archivo de respaldo debía desempaquetarse únicamente dentro de la nueva base de datos, cumpliendo con el requerimiento de "Restauración en nueva base" de forma segura.

## Validación de Integridad Post-Restauración

**Objetivo:** Auditar que la migración fue exitosa, comparando la estructura y el volumen de datos.

**Procedimiento:**

1. **Conteo de tablas estructurales:** Confirma que no se perdió ninguna tabla en el esquema público.

```bash
docker exec -it postgres17-recuperado psql -U postgres -d viva_restore -c "
SELECT count(*) AS total_tablas_restauradas
FROM information_schema.tables
WHERE table_schema = 'public';"
```

`information_schema.tables`. Al filtrar por `table_schema = 'public'`, se pidió a la base de datos que devolviera el número exacto de tablas que existen. Si la base original Viva tenía 45 tablas, esta consulta debía devolver exactamente 45 en `viva_restore`. Esto prueba que el "esqueleto" se restauró completo.

2. **Conteo de registros (filas por tabla):** Verifica que los datos internos de cada tabla coincidan con la base original.

```bash
docker exec -it postgres17-recuperado psql -U postgres -d viva_restore -c "
SELECT relname AS nombre_tabla, n_live_tup AS cantidad_registros
FROM pg_stat_user_tables
ORDER BY n_live_tup DESC;"
```

Utilizamos la vista interna de estadísticas de PostgreSQL `pg_stat_user_tables`. La columna `n_live_tup` (Number of Live Tuples) guarda el conteo exacto de las filas o registros vivos en cada tabla. Al ordenar esto con `ORDER BY n_live_tup DESC`, se genera un reporte inmediato y auditable de cuántos registros tiene cada tabla.
# Respaldo y Recuperación

## Backup Lógico de la Base de Datos

Se realizó un respaldo lógico completo de la base de datos Viva mediante la herramienta `pg_dump`.

```bash
pg_dump -U postgres -Fc Viva -f /tmp/Viva.backup
```

Verificación realizada:

```bash
ls -lh /tmp/Viva.backup
```

Resultado:

```text
-rw-r--r-- 1 root root 115K Jun 3 14:22 /tmp/Viva.backup
```

El archivo generado contiene la estructura y los datos de la base de datos.

---

## Backup de Roles Globales

Se realizó el respaldo de usuarios, roles y privilegios utilizando `pg_dumpall`.

```bash
pg_dumpall -U postgres --globals-only > roles_globales.sql
```

Verificación realizada:

```bash
ls -lh roles_globales.sql
```

Resultado:

```text
-rw-rw-r-- 1 max max 2.5K Jun 3 14:31 roles_globales.sql
```

Este respaldo permite recuperar la configuración de usuarios, roles y permisos del servidor PostgreSQL.

---
Se implementaron correctamente los mecanismos de respaldo y recuperación mediante la generación de un backup lógico de la base de datos y un respaldo de roles globales. Estas acciones garantizan la disponibilidad de la información y facilitan la recuperación ante posibles fallos o pérdidas de dat
