# Política de Respaldo

## Objetivo

Garantizar la disponibilidad y recuperación de la información ante fallos operativos, errores humanos o incidentes que afecten la base de datos.

## Estrategia de Respaldo

### Respaldo Completo

Frecuencia:
- Semanal

Horario:
- Domingo 02:00 AM

### Respaldo Incremental

Se realiza mediante el archivado continuo de archivos WAL (Write Ahead Log).

## Almacenamiento

Los respaldos se almacenan en:

- Servidor principal.
- Directorio de respaldo WAL.
- Medio externo para recuperación ante desastres.

## Verificación

- Verificación periódica de integridad.
- Pruebas de restauración mensuales.

## Beneficios

- Protección ante pérdida de información.
- Recuperación rápida del servicio.
- Continuidad operativa.
