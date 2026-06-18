# Simulación de Recuperación a Punto en el Tiempo (PITR)

## Objetivo

Implementar la infraestructura necesaria para recuperar la base de datos hasta un momento específico utilizando archivos WAL.

## Configuración Aplicada

### Nivel WAL

```sql
SHOW wal_level;
```

Resultado:

```text
replica
```

### Archivado WAL

```sql
SHOW archive_mode;
```

Resultado:

```text
on
```

### Comando de Archivado

```sql
SHOW archive_command;
```

Resultado:

```text
cp %p /var/lib/postgresql/data/backup_wal/%f
```

## Generación de WAL

```sql
SELECT pg_switch_wal();
```

Resultado:

```text
0/2306848
```
Evidencia

Archivo WAL generado:

000000010000000000000002

Ubicación:

/var/lib/postgresql/data/backup_wal

## Validación

La generación exitosa del archivo WAL confirmó el correcto funcionamiento del mecanismo de archivado continuo configurado en PostgreSQL.

La ejecución de:

SELECT pg_switch_wal();

forzó el cierre del segmento WAL activo y la creación de un nuevo archivo WAL, permitiendo verificar que el proceso de archivado se encontraba operativo.

La presencia del archivo:

000000010000000000000002

en el directorio configurado para archivado constituyó evidencia de que la infraestructura necesaria para PITR se encontraba correctamente implementada.

## Procedimiento Teórico de Recuperación

1. Restaurar una copia base de la base de datos.
2. Restaurar los archivos WAL archivados.
3. Configurar el parámetro recovery_target_time.
4. Iniciar PostgreSQL en modo recuperación.
5. Aplicar secuencialmente los archivos WAL.
6. Recuperar la base de datos hasta el instante solicitado.
7. Validar la integridad de la información restaurada.


## Conclusión

La infraestructura necesaria para PITR fue configurada y validada mediante el archivado exitoso de archivos WAL.
