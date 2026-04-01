# Alcance del Proyecto - Sistema de Gestión de Telecomunicaciones

## 1. Alcance Funcional

### 1.1 Gestión de Clientes

| Elemento | Incluido | Descripción |
|----------|----------|-------------|
| Clientes Individuales | ✅ | Registro de datos personales: nombre, documento de identidad, email, dirección |
| Clientes Corporativos | ✅ | Registro de empresas: razón social, NIT, sector, número de empleados, contacto principal |
| Antigüedad de Cliente | ✅ | Cálculo automático basado en fecha de registro, influye en elegibilidad de servicios |
| Múltiples Líneas por Cliente | ✅ | Un cliente puede tener una o varias líneas telefónicas asociadas |
| Clientes Inactivos | ⚠️ | Solo registro histórico; no se incluye proceso de reactivación en esta fase |

### 1.2 Gestión de Líneas Telefónicas

| Elemento | Incluido | Descripción |
|----------|----------|-------------|
| Registro de Líneas | ✅ | Número telefónico, fecha activación, estado, modalidad (prepago/postpago) |
| Historial de Planes por Línea | ✅ | Registro de cambios de plan con fechas de inicio y fin |
| Estado de Línea | ✅ | Activa, Suspendida, Bloqueada, Cancelada |
| Saldo de Línea Prepago | ✅ | Control de saldo actual y transacciones de recarga |
| Saldo de Línea Postpago | ⚠️ | Se maneja mediante facturación; crédito consumido se registra |

### 1.3 Gestión de Recursos y Consumos

| Elemento | Incluido | Descripción |
|----------|----------|-------------|
| Tipos de Recurso | ✅ | Catálogo extensible: minutos, SMS, datos, roaming, redes sociales, etc. |
| Consumo de Llamadas | ✅ | Registro de duración, destino, costo, origen del recurso |
| Consumo de SMS | ✅ | Registro de cantidad, destino, costo, origen del recurso |
| Consumo de Datos | ✅ | Registro de MB consumidos, destino, costo, origen del recurso |
| Priorización de Consumo | ✅ | Algoritmo: bonos → paquetes por prioridad → saldo base |
| Bloqueo de Saldo | ✅ | Para consumos de larga duración (llamadas) |

### 1.4 Gestión de Paquetes y Promociones

| Elemento | Incluido | Descripción |
|----------|----------|-------------|
| Catálogo de Paquetes | ✅ | Definición de paquetes con múltiples componentes de recursos |
| Composición Flexible | ✅ | Paquetes pueden incluir cualquier combinación de recursos |
| Compra de Paquetes | ✅ | Registro de adquisición con fecha, vigencia y saldos |
| Expiración Automática | ✅ | Paquetes expiran automáticamente al superar vigencia |
| Promociones | ✅ | Definición de promociones con reglas (doble carga, bonos) |
| Aplicación de Promociones | ✅ | Registro de aplicación de promociones a líneas |

### 1.5 Gestión de Recargas y Préstamos

| Elemento | Incluido | Descripción |
|----------|----------|-------------|
| Recargas Prepago | ✅ | Registro de monto, fecha, medio de recarga, código confirmación |
| Medios de Recarga | ✅ | Tarjeta física, app móvil, banca digital, puntos de venta |
| Préstamo de Saldo | ✅ | Solicitud, aprobación, monto, intereses, estado |
| Elegibilidad de Préstamos | ✅ | Basada en antigüedad del cliente |
| Pago de Préstamos | ✅ | Registro de pagos parciales o totales |

### 1.6 Gestión de Facturación

| Elemento | Incluido | Descripción |
|----------|----------|-------------|
| Planes de Servicio | ✅ | Definición de planes individuales y corporativos |
| Facturación Mensual | ✅ | Generación automática por ciclo de facturación |
| Consumo Extra | ✅ | Registro de consumo fuera del plan incluido |
| Planes Corporativos Compartidos | ✅ | Pool de recursos compartido entre múltiples líneas |
| Historial de Facturas | ✅ | Almacenamiento de facturas emitidas |

## 2. Alcance No Funcional

| Aspecto | Nivel Requerido | Descripción |
|---------|-----------------|-------------|
| Rendimiento | Alto | Consultas de saldo < 100ms, soporte para miles de transacciones/segundo |
| Disponibilidad | 99.9% | Sistema debe estar operativo 24/7 |
| Escalabilidad | Horizontal | Posibilidad de agregar nodos a medida que crece la base de usuarios |
| Consistencia | ACID | Operaciones transaccionales con integridad referencial |
| Auditoría | Completa | Trazabilidad de todas las operaciones de modificación de saldo |
| Seguridad | Alta | Control de acceso por roles (administrador, agente, cliente) |
| Capacidad de Almacenamiento | Terabytes | Estimación de crecimiento: 100GB por millón de usuarios activos |

## 3. Entregables del Proyecto

### 3.1 Documentación
- [x] Análisis del problema (problema-mejorado.md)
- [x] Alcance del proyecto (alcance.md)
- [x] Objetivos (objetivos.md)
- [x] Supuestos y restricciones (supuestos-y-restricciones.md)
- [x] Reglas de negocio (reglas-del-negocio.md)
- [x] Modelo conceptual (DER)
- [x] Diccionario de datos

### 3.2 Artefactos Técnicos
- [ ] Script DDL completo (creación de tablas)
- [ ] Script de constraints (PK, FK, CHECK)
- [ ] Script de índices
- [ ] Script de triggers
- [ ] Script de vistas
- [ ] Consultas principales (queries)
- [ ] Procedimientos almacenados críticos

## 4. Fuera de Alcance

Los siguientes elementos NO están incluidos en la fase actual del proyecto:

| Elemento | Razón |
|----------|-------|
| Desarrollo de interfaz de usuario (UI) | Enfoque actual es base de datos; UI será fase posterior |
| Integración con switches telefónicos | Requiere desarrollo separado con equipos de red |
| App móvil para clientes | Fase de implementación de aplicaciones |
| Pasarela de pagos en línea | Depende de terceros y requerimientos de seguridad |
| Chatbots y atención al cliente automatizada | Fuera del alcance del modelo de datos |
| Sistema de reporting y BI | Fase separada de analítica |
| Migración de datos existentes | Depende de análisis de calidad de datos actuales |
| Alta disponibilidad con clustering | Fase de infraestructura |


