# Definición de RPO y RTO

## Recovery Point Objective (RPO)

Valor definido: 15 minutos

### Interpretación

La pérdida máxima aceptable de información es de 15 minutos.

En caso de incidente, la organización acepta perder como máximo los datos generados durante los últimos 15 minutos.

## Recovery Time Objective (RTO)

Valor definido: 60 minutos

### Interpretación

El sistema debe volver a estar operativo en un tiempo máximo de 60 minutos después de una falla.

## Retención de Información

- Backups completos: 30 días.
- Archivos WAL: 15 días.
- Registros de auditoría: 90 días.

## Beneficios

- Control de disponibilidad.
- Planificación de recuperación.
- Gestión eficiente de respaldos.
