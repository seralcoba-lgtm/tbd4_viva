/*
====================================================
CONFIGURACIÓN PITR (POINT IN TIME RECOVERY)
====================================================
Autor: 
Base de datos: Viva
PostgreSQL: 17.10
====================================================
*/

-- Verificar configuración WAL
SHOW wal_level;

-- Verificar archivado WAL
SHOW archive_mode;

-- Verificar comando de archivado
SHOW archive_command;

-- Forzar cambio de WAL para generar un archivo archivado
SELECT pg_switch_wal();

/*
CONFIGURACIÓN REALIZADA EN postgresql.conf

archive_mode = on

archive_command =
'cp %p /var/lib/postgresql/data/backup_wal/%f'

DIRECTORIO DE ARCHIVADO:

/var/lib/postgresql/data/backup_wal

EVIDENCIA:

Archivo WAL generado:

000000010000000000000002

COMANDO DE VERIFICACIÓN:

ls -lh /var/lib/postgresql/data/backup_wal

RESULTADO:

-rw------- 1 postgres postgres 16M
000000010000000000000002

SIMULACIÓN PITR:

La recuperación a un punto en el tiempo se realizaría
utilizando:

1. Backup base de PostgreSQL.
2. Archivos WAL almacenados en backup_wal.
3. recovery_target_time.
4. Restauración hasta el instante deseado.
*/
