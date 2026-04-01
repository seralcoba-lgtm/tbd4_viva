# Reglas de Negocio - Sistema de Gestión de Telecomunicaciones

## 1. Reglas de Gestión de Clientes

### 1.1 Registro de Clientes

| ID | Regla | Descripción | Implementación |
|----|-------|-------------|----------------|
| RC-001 | Unicidad de documento | El documento de identidad (CI/NIT) debe ser único en la tabla CLIENTE | UNIQUE constraint |
| RC-002 | Tipos de cliente | Los clientes pueden ser 'Individual' o 'Corporativo' | ENUM constraint |
| RC-003 | Antigüedad automática | La antigüedad se calcula como días entre fecha_registro y fecha actual | Campo calculado o función |
| RC-004 | Datos corporativos obligatorios | Si tipo_cliente = 'Corporativo', debe existir registro en CLIENTE_CORPORATIVO | Trigger o validación aplicación |

### 1.2 Gestión de Líneas

| ID | Regla | Descripción | Implementación |
|----|-------|-------------|----------------|
| RL-001 | Múltiples líneas | Un cliente puede tener una o más líneas asociadas | Relación 1:N CLIENTE-LINEA |
| RL-002 | Unicidad de número | El número de teléfono debe ser único en todo el sistema | UNIQUE constraint |
| RL-003 | Estado de línea | La línea puede estar: Activa, Suspendida, Bloqueada, Cancelada | ENUM constraint |
| RL-004 | Línea con modalidad | Toda línea debe tener una modalidad asignada (Prepago/Postpago) | FK NOT NULL |
| RL-005 | Línea con cliente | Toda línea debe pertenecer a un cliente | FK NOT NULL |


## 2. Reglas de Gestión de Saldos y Consumos

### 2.1 Control de Saldos

| ID | Regla | Descripción | Implementación |
|----|-------|-------------|----------------|
| RS-001 | Saldo no negativo | El saldo de una línea prepago no puede ser negativo | CHECK constraint o trigger |
| RS-002 | Bolsillo por recurso | Cada línea tiene un bolsillo por cada tipo de recurso | Relación 1:N LINEA-BOLSILLO |
| RS-003 | Concurrencia optimista | Actualizaciones de saldo requieren control de versión | Campo version en BOLSILLO |
| RS-004 | Bloqueo para llamadas | Llamadas de larga duración bloquean saldo estimado | Tabla BLOQUEO_SALDO |

### 2.2 Priorización de Consumo

| ID | Regla | Descripción | Implementación |
|----|-------|-------------|----------------|
| RC-005 | Orden de consumo | Los recursos se consumen en orden: Bonos → Paquetes → Saldo Base | Algoritmo en sp_consumir_recurso |
| RC-006 | Prioridad intra-paquetes | Los paquetes con menor prioridad_numérica se consumen primero | Campo prioridad en PAQUETE_ADQUIRIDO |
| RC-007 | FIFO entre paquetes | Para igual prioridad, consume primero el que expira antes | ORDER BY fecha_expiracion ASC |
| RC-008 | Consumo parcial | Un consumo puede descontarse de múltiples fuentes | Tabla CONSUMO_PAQUETE para trazabilidad |

### 2.3 Registro de Consumos

| ID | Regla | Descripción | Implementación |
|----|-------|-------------|----------------|
| RC-009 | Consumo atómico | Cada llamada, SMS o sesión de datos genera un registro en CONSUMO | Proceso transaccional |
| RC-010 | Trazabilidad de origen | Cada consumo debe registrar de qué recurso se descontó | Campo origen_recurso en CONSUMO |
| RC-011 | Cantidad consumida | cantidad_consumida ≤ cantidad_solicitada | CHECK constraint |
| RC-012 | Costo por unidad | El costo_unitario se define por tipo de recurso y vigencia | JOIN con tarifas actuales |


## 3. Reglas de Gestión de Paquetes

### 3.1 Catálogo de Paquetes

| ID | Regla | Descripción | Implementación |
|----|-------|-------------|----------------|
| RP-001 | Composición flexible | Un paquete puede tener múltiples componentes de diferentes recursos | Tabla PAQUETE_COMPONENTE |
| RP-002 | Sin duplicados | Un paquete no puede tener dos componentes del mismo tipo de recurso | UNIQUE (id_paquete, id_tipo_recurso) |
| RP-003 | Orden de consumo por paquete | Los componentes se consumen según orden_consumo dentro del paquete | Campo orden_consumo |
| RP-004 | Paquete recurrente | Los paquetes recurrentes se renuevan automáticamente al expirar | Trigger o job programado |

### 3.2 Adquisición de Paquetes

| ID | Regla | Descripción | Implementación |
|----|-------|-------------|----------------|
| RP-005 | Vigencia calculada | fecha_expiracion = fecha_inicio + vigencia_dias | Trigger before insert |
| RP-006 | Estados de adquisición | activo, agotado, expirado, cancelado | ENUM constraint |
| RP-007 | Expiración automática | Paquete cambia a 'expirado' cuando fecha_expiracion < NOW() | Job diario o trigger on select |
| RP-008 | Agotamiento automático | Paquete cambia a 'agotado' cuando todos los saldos_restantes = 0 | Trigger after update |
| RP-009 | Copia de cantidades | Al adquirir, se copian las cantidades originales del catálogo | Trigger before insert |


## 4. Reglas de Gestión de Promociones

### 4.1 Definición de Promociones

| ID | Regla | Descripción | Implementación |
|----|-------|-------------|----------------|
| RPR-001 | Tipos de promoción | Doble carga, bono de saldo, bono de paquete | ENUM tipo_beneficio |
| RPR-002 | Vigencia por fecha | Promoción activa solo entre fecha_inicio y fecha_fin | CHECK constraint o validación aplicación |
| RPR-003 | Vigencia por horario | Promoción aplica solo entre horario_inicio y horario_fin | Validación en aplicación |

### 4.2 Aplicación de Promociones

| ID | Regla | Descripción | Implementación |
|----|-------|-------------|----------------|
| RPR-004 | Aplicación a línea | Una promoción puede aplicarse a múltiples líneas | Tabla PROMOCION_APLICADA |
| RPR-005 | Bono generado | Cada aplicación genera uno o más bonos en BONO_PROMOCIONAL | Trigger after insert |
| RPR-006 | Consumo prioritario | Los bonos se consumen antes que cualquier otro recurso | Prioridad 1 en algoritmo de consumo |
| RPR-007 | Expiración de bono | Los bonos expiran según fecha definida en la promoción | Job diario |


## 5. Reglas de Gestión de Préstamos

| ID | Regla | Descripción | Implementación |
|----|-------|-------------|----------------|
| RPRS-001 | Elegibilidad por antigüedad | Solo clientes con antigüedad ≥ 90 días pueden solicitar préstamo | Validación en sp_solicitar_prestamo |
| RPRS-002 | Un préstamo activo | Una línea no puede tener más de un préstamo en estado 'pendiente' | Validación antes de insertar |
| RPRS-003 | Monto máximo | El préstamo no puede exceder el 50% del promedio de recargas de los últimos 90 días | Cálculo en sp_solicitar_prestamo |
| RPRS-004 | Cálculo de intereses | Interés = monto_prestado * (tasa_interés / 100) | Cálculo automático |
| RPRS-005 | Estado de préstamo | Pendiente, cancelado, vencido | ENUM constraint |
| RPRS-006 | Pago de préstamo | Puede pagarse total o parcialmente | Tabla PAGO_PRESTAMO |


## 6. Reglas de Gestión de Facturación

### 6.1 Planes de Servicio

| ID | Regla | Descripción | Implementación |
|----|-------|-------------|----------------|
| RF-001 | Tipos de plan | Individual, Corporativo | ENUM tipo_plan |
| RF-002 | Plan activo | Solo planes con activo = TRUE pueden ser asignados | Validación |
| RF-003 | Historial de planes | Cada cambio de plan se registra en LINEA_PLAN | Trigger before update |
| RF-004 | Plan corporativo compartido | Puede tener pool de recursos para múltiples líneas | Tabla PLAN_CORPORATIV
