## Documentación de Política de Continuidad de Negocio

Como lineamiento rector para el manejo de los datos en el Proyecto Viva, se establecen los siguientes parámetros oficiales de recuperación ante desastres:

| Métrica | Definición del Proyecto | Significado Práctico |
| --- | --- | --- |
| RPO (Recovery Point Objective) | 24 horas | El sistema tolerará una pérdida máxima de un día de trabajo. Los respaldos completos (`pg_dump`) se programarán diariamente a la medianoche. |
| RTO (Recovery Time Objective) | 2 horas | Es el tiempo máximo permitido para restaurar la base de datos (`pg_restore`) y levantar el contenedor Docker en caso de un fallo total del servidor. |
| Retención de backups | 7 días | Los archivos físicos de respaldo se conservarán en el sistema por una semana. El día 8, se eliminará el backup del día 1 para optimizar el almacenamiento en disco. |

**Simulación PITR bajo demanda:** Para recuperaciones críticas al segundo exacto (Point-in-Time Recovery), se dependerá de la configuración futura de los archivos WAL (Write-Ahead Logging) combinados con los respaldos base.

