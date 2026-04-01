# Objetivos del Proyecto - Sistema de Gestión de Telecomunicaciones

## 1. Objetivo General

Diseñar e implementar un modelo de base de datos robusto, escalable y eficiente para la gestión integral de servicios de telefonía móvil de Viva, que permita administrar millones de clientes, líneas telefónicas, consumos en tiempo real, paquetes promocionales, recargas, préstamos de saldo y facturación, garantizando integridad de datos, alto rendimiento y trazabilidad completa de operaciones.



## 2. Objetivos Específicos

### 2.1 Modelado de Datos

| # | Objetivo | Métrica de Éxito |
|---|----------|-----------------|
| OE1 | Diseñar un modelo conceptual que represente todas las entidades del negocio y sus relaciones | 100% de entidades identificadas y documentadas |
| OE2 | Normalizar el modelo lógico hasta 3FN para garantizar integridad y reducir redundancia | Cumplimiento de reglas de normalización |
| OE3 | Implementar un modelo de paquetes polimórfico que permita cualquier combinación de recursos | Capacidad de crear paquetes sin modificar estructura de tablas |
| OE4 | Diseñar esquema para clientes corporativos con planes compartidos | Soporte para pooling de recursos entre líneas |

### 2.2 Gestión de Consumo en Tiempo Real

| # | Objetivo | Métrica de Éxito |
|---|----------|-----------------|
| OE5 | Implementar algoritmo de priorización de consumo (bonos → paquetes → saldo base) | Tiempo de procesamiento < 50ms por transacción |
| OE6 | Garantizar consistencia en actualizaciones concurrentes de saldo | Cero conflictos de datos en pruebas de concurrencia |
| OE7 | Soporte para bloqueo de saldo en consumos de larga duración | Capacidad de bloquear saldo para llamadas de hasta 4 horas |
| OE8 | Registrar cada evento de consumo con trazabilidad completa | 100% de consumos registrados con origen de recurso |

### 2.3 Control de Paquetes y Promociones

| # | Objetivo | Métrica de Éxito |
|---|----------|-----------------|
| OE9 | Gestionar ciclo de vida completo de paquetes adquiridos (activo, agotado, expirado) | Procesos automáticos de expiración diarios |
| OE10 | Aplicar promociones de doble carga y bonos según reglas definidas | Aplicación correcta de promociones en horarios específicos |
| OE11 | Mantener histórico de paquetes adquiridos independiente del catálogo | Capacidad de consultar paquetes comprados incluso si se modificó el catálogo |

### 2.4 Facturación y Postpago

| # | Objetivo | Métrica de Éxito |
|---|----------|-----------------|
| OE12 | Generar facturas mensuales automáticas para clientes postpago | Proceso de facturación con 100% de precisión |
| OE13 | Registrar consumo extra fuera del plan incluido | Capacidad de desglose entre consumo base y consumo adicional |
| OE14 | Gestionar planes corporativos con recursos compartidos | Control de consumo acumulado por empresa |

### 2.5 Rendimiento y Escalabilidad

| # | Objetivo | Métrica de Éxito |
|---|----------|-----------------|
| OE15 | Soportar consultas de saldo en menos de 100ms | Tiempo de respuesta en entorno de pruebas con datos simulados |
| OE16 | Procesar miles de transacciones concurrentes por segundo | Pruebas de carga con 10,000 operaciones/segundo |
| OE17 | Diseñar índices optimizados para consultas frecuentes | 95% de consultas críticas con plan de ejecución eficiente |
| OE18 | Mantener integridad referencial mediante constraints apropiados | 100% de relaciones con FK definidas |



## 3. Entregables Asociados por Objetivo

| Objetivo | Entregable |
|----------|------------|
| OE1, OE2, OE3, OE4 | Diagrama Entidad-Relación (DER) |
| OE5, OE6, OE7, OE8 | Procedimiento almacenado `sp_consumir_recurso` |
| OE9, OE10, OE11 | Triggers de expiración y aplicación de promociones |
| OE12, OE13, OE14 | Procedimiento almacenado `sp_generar_facturas` |
| OE15, OE16, OE17 , OE18 | Script de índices y análisis de planes de ejecución |



## 4. Criterios de Aceptación del Proyecto

El proyecto se considerará exitoso cuando:

1. **Modelo validado**: El modelo conceptual aprobado por stakeholders
2. **Scripts funcionales**: Todos los scripts DDL, DML y procedimientos almacenados ejecutables sin errores
3. **Rendimiento aceptable**: Consultas críticas dentro de métricas definidas
4. **Documentación completa**: Todos los archivos de documentación entregados
5. **Cobertura de reglas**: 100% de reglas de negocio documentadas e implementadas
6. **Pruebas exitosas**: Pruebas de integridad y concurrencia superadas
