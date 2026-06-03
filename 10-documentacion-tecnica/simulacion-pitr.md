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

## Evidencia

Archivo WAL generado:

```text
000000010000000000000002
```

Ubicación:

```text
/var/lib/postgresql/data/backup_wal
```

## Procedimiento Teórico de Recuperación

1. Restaurar una copia base de la base de datos.
2. Restaurar los archivos WAL archivados.
3. Configurar recovery_target_time.
4. Iniciar PostgreSQL en modo recuperación.
5. Recuperar la base hasta el instante solicitado.

## Conclusión

La infraestructura necesaria para PITR fue configurada y validada mediante el archivado exitoso de archivos WAL.
