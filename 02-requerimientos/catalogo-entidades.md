--------------------------------------------------------------------------------
# 📖 Catálogo de Entidades: Esquema `clientes`

Este documento describe las entidades que conforman el esquema `clientes` de la base de datos **Viva**. Este esquema es el núcleo de la información del abonado y requiere las medidas más estrictas de **Defensa en Profundidad** debido a la alta concentración de datos sensibles (PII).

## 🛡️ Estrategia de Seguridad del Esquema
*   **Dueño del Esquema:** `admin_clientes` [2, 4].
*   **Principio Aplicado:** Mínimo Privilegio (PoLP).
*   **Controles:** Seguridad a Nivel de Columna (CLS) para ocultar identificadores y Vistas Seguras para analistas [3, 5].

---

## 📋 Listado de Entidades

### 1. `clientes.cliente`
Es la tabla maestra que contiene la información legal de las personas naturales.
*   **Propósito:** Almacenar los datos de identidad y contacto de los usuarios.
*   **Columnas Críticas:**
    *   `id_cliente`: Identificador único (PK).
    *   `doc_identidad`: Número de documento (DNI/CI). **[PII - Protegido con CLS]** [6].
    *   `email`: Correo electrónico personal. **[PII - Protegido con CLS]** [6].
    *   `nombre`, `apellidos`, `direccion`, `fecha_registro`.
*   **Hardening:** Se ha revocado el acceso al `doc_identidad` para el `employee_role` para prevenir el robo de identidad [6, 7].

### 2. `clientes.cliente_corporativo`
Extensión de la tabla cliente para representar personas jurídicas y empresas.
*   **Propósito:** Gestión de cuentas empresariales y B2B.
*   **Columnas Críticas:**
    *   `nit`: Identificador tributario. **[Sensible]** [8].
    *   `razon_social`, `sector`, `num_empleado`.
    *   `contacto_principal`: Nombre del enlace directo con la empresa. **[Confidencial]** [8].
*   **Hardening:** Acceso restringido al contacto principal para evitar fugas de clientes VIP hacia la competencia [8, 9].

### 3. `clientes.dispositivo`
Registro del hardware vinculado a las líneas telefónicas activas.
*   **Propósito:** Inventario de equipos y validación técnica.
*   **Columnas Críticas:**
    *   `IMEI`: Identificador internacional de equipo móvil. **[Crítico]** [8, 10].
    *   `marca`, `modelo`, `id_linea` (FK).
*   **Hardening:** El IMEI se encuentra enmascarado mediante la vista `vw_dispositivos_seguros` para el rol de analista, mostrando solo los últimos 4 dígitos [11, 12].

### 4. `clientes.linea_telefonica`
Entidad que representa el servicio activo asignado a un cliente.
*   **Propósito:** Vincular al abonado con un número, modalidad y plan comercial.
*   **Columnas:**
    *   `id_linea`: Identificador único (PK).
    *   `numero_telefonico`: Número asignado (Unique).
    *   `fecha_activacion`, `estado` (Activo, Suspendido, etc.).
    *   `id_cliente`, `id_modalidad`, `id_plan` (FKs).

### 5. `clientes.consumo`
Registro histórico del uso de servicios (Voz, SMS, Datos).
*   **Propósito:** Proporcionar la base para la facturación y el análisis de comportamiento.
*   **Columnas Críticas:**
    *   `monto_asociado`: El costo monetario del consumo. **[Financiero - Sensible]** [13, 14].
    *   `minutos_usados`, `datos_mb_usados`, `destino_numeros`, `fecha_consumo`.
*   **Hardening:** El `costo_asociado` es invisible para roles operativos básicos para evitar la manipulación de saldos [13, 14].

### 6. `clientes.consumo_paquete`
Detalle técnico del uso de recursos provenientes específicamente de bolsas o paquetes adquiridos.
*   **Propósito:** Seguimiento granular del agotamiento deMB o minutos de paquetes prepago/postpago.
*   **Columnas:**
    *   `id_consumo` (PK), `id_adquisicion` (FK).
    *   `cantidad_aplicada`, `consumo_generado`.
    *   `fecha_hora_inicio_consumo`, `fecha_hora_final_consumo`.

---

## 🔒 Matriz de Acceso Rápido (Esquema Clientes)

| Tabla | `employee_role` | `analyst_role` | `manager_role` |
| :--- | :--- | :--- | :--- |
| `cliente` | SELECT (Sin PII) | SELECT (Vía Vista) | SELECT (Full) |
| `dispositivo` | SELECT (Sin IMEI) | SELECT (Enmascarado) | SELECT (Full) |
| `consumo` | SELECT/INSERT | SELECT | SELECT |
| `linea_telefonica` | SELECT/INSERT | SELECT | SELECT/UPDATE |
--------------------------------------------------------------------------------
# 💰 Catálogo de Entidades: Esquema `finanzas`

Este documento detalla las entidades que conforman el esquema `finanzas` de la base de datos **Viva**. Este esquema gestiona todas las transacciones monetarias, créditos y balances, por lo que su seguridad es crítica para la integridad financiera de la organización.

## 🛡️ Estrategia de Seguridad del Esquema
*   **Dueño del Esquema:** `admin_finanzas` [1, 2].
*   **Principio Aplicado:** Aislamiento de dominios y Mínimo Privilegio (PoLP).
*   **Controles:** Seguridad a Nivel de Columna (CLS) para ocultar saldos reales y Seguridad a Nivel de Fila (RLS) para limitar la visibilidad de facturas [3, 4].

---

## 📋 Listado de Entidades

### 1. `finanzas.factura`
Documentos legales de cobro por servicios prestados.
*   **Propósito:** Registrar la emisión de facturas y estados de pago.
*   **Columnas Críticas:**
    *   `id_factura`: Identificador único (PK).
    *   `ci_nit`: Identificador tributario del cliente. **[Sensible]**.
    *   `monto_base`, `intereses`: Datos financieros protegidos contra modificaciones [5].
*   **Hardening:** Implementa **RLS** para que los empleados operativos solo puedan visualizar las facturas asignadas a su área o gestión específica [3].

### 2. `finanzas.bolsillo`
Segmentación detallada del saldo del usuario en diferentes recursos.
*   **Propósito:** Controlar el remanente de crédito, minutos y datos del abonado.
*   **Columnas Críticas:**
    *   `credito_regular`, `credito_promo`: Saldos monetarios reales. **[Crítico]**.
    *   `saldo`: Monto total consolidado [6].
*   **Hardening:** Se aplica **CLS** para revocar el acceso a las columnas de saldo real al `employee_role`, permitiéndoles ver solo si la línea cuenta con recursos pero no los montos base exactos [4].

### 3. `finanzas.budget`
Gestión de presupuestos corporativos y planificación interna.
*   **Propósito:** Almacenar proyecciones de ingresos y límites de gastos por periodos.
*   **Columnas Críticas:**
    *   `sales`, `expenses`: Valores estratégicos de la empresa. **[Estratégico]**.
    *   `notes`: Notas confidenciales de la gerencia [7].
*   **Hardening:** Acceso totalmente denegado para `employee_role`. Solo visible para analistas y gerencia mediante permisos específicos [4, 8].

### 4. `finanzas.prestamo`
Registro de adelantos de saldo y créditos otorgados a clientes.
*   **Propósito:** Seguimiento de deudas activas y cargos financieros aplicados.
*   **Columnas Críticas:**
    *   `monto_prestado`, `monto_total_pagar`: Valores de deuda. **[Alto Riesgo]**.
    *   `estado_prestamo`: Indica si la deuda ha sido saneada [9].
*   **Hardening:** Se restringe el permiso de `UPDATE` sobre los montos para evitar la alteración maliciosa de deudas por parte de roles operativos [10].

### 5. `finanzas.pago_prestamo`
Comprobantes de amortización de préstamos realizados por los usuarios.
*   **Propósito:** Registrar las transacciones de pago para disminuir el saldo deudor.
*   **Columnas:**
    *   `id_pago_prestamo` (PK), `id_prestamo` (FK).
    *   `monto_pagado`, `medio_pago`, `comprobante` [11].
*   **Hardening:** Permiso de solo inserción (`INSERT`) para roles operativos para mantener la trazabilidad de los pagos sin permitir la edición de registros históricos [12].

### 6. `finanzas.recarga`
Historial de abonos de saldo realizados a las líneas telefónicas.
*   **Propósito:** Auditoría de ingresos inmediatos por prepago o pagos postpago.
*   **Columnas Críticas:**
    *   `monto`: Valor de la recarga.
    *   `salario_resultante`: El saldo del cliente tras la operación. **[Sensible]** [6].
*   **Hardening:** La columna `salario_resultante` está protegida mediante **CLS** para evitar que personal de ventas vea el capital acumulado del cliente [4].

---

## 🔒 Matriz de Acceso Rápido (Esquema Finanzas)

| Tabla | `employee_role` | `analyst_role` | `manager_role` |
| :--- | :--- | :--- | :--- |
| `factura` | SELECT (RLS) / INSERT | SELECT | SELECT |
| `bolsillo` | Sin Acceso | SELECT | SELECT |
| `budget` | Sin Acceso | SELECT | SELECT/UPDATE |
| `recarga` | INSERT / SELECT (Sin Saldo) | SELECT | SELECT |
| `prestamo` | SELECT / INSERT | SELECT | SELECT |

--------------------------------------------------------------------------------
# 📈 Catálogo de Entidades: Esquema `ventas`

Este documento detalla las entidades que conforman el esquema `ventas` de la base de datos **Viva**. Este esquema actúa como el catálogo maestro de servicios y productos, por lo que su integridad y confidencialidad son vitales para la estrategia comercial de la organización.

## 🛡️ Estrategia de Seguridad del Esquema
*   **Dueño del Esquema:** `admin_ventas` [1].
*   **Principio Aplicado:** Aislamiento de dominios y Mínimo Privilegio (PoLP) [2, 3].
*   **Controles:** Seguridad a Nivel de Columna (CLS) para ocultar precios estratégicos y tarifas a roles operativos [4, 5].

---

## 📋 Listado de Entidades

### 1. `ventas.plan`
Catálogo maestro de planes tarifarios (Postpago, Prepago, Híbrido).
*   **Propósito:** Definir los planes disponibles y sus recursos incluidos [6].
*   **Columnas Críticas:**
    *   `id_plan`: Identificador único (PK) [7].
    *   `tarifa_mensual`: Costo base del plan. **[Estratégico - Protegido con CLS]** [8, 9].
    *   `minutos_incluidos`, `datos_mb_incluidos`, `activo`.
*   **Hardening:** Se oculta la `tarifa_mensual` al `employee_role` para evitar negociaciones o filtraciones de precios base no autorizadas [4, 9].

### 2. `ventas.paquete`
Definición de bolsas de recursos adicionales que los usuarios pueden adquirir.
*   **Propósito:** Gestionar la oferta de paquetes de datos, voz y combos [10].
*   **Columnas Críticas:**
    *   `precio`: Valor de venta del paquete. **[Estratégico - Protegido con CLS]** [5, 11].
    *   `nombre_paquete`, `minutos_incluidos`, `datos_mb_incluidos`, `vigencia_dias`.
*   **Hardening:** El acceso al `precio` está restringido mediante CLS para roles operativos básicos [4, 5].

### 3. `ventas.paquete_adquirido`
Registro transaccional de los paquetes comprados por las líneas telefónicas.
*   **Propósito:** Seguimiento de la vigencia y saldos de paquetes activos [12].
*   **Columnas Críticas:**
    *   `saldo_inicial_min`, `saldo_inicial_datos`, `saldo_inicial`: Valores originales de compra. **[Sensible - Protegido con CLS]** [9, 13].
    *   `saldo_restante_min`, `saldo_restante_datos`: Remanente actual para el usuario.
*   **Hardening:** Se ocultan los saldos iniciales al personal operativo; solo deben visualizar el saldo restante para tareas de soporte [8, 9].

### 4. `ventas.promocion`
Reglas de negocio para beneficios temporales y ofertas especiales.
*   **Propósito:** Definir las condiciones y valores de las campañas promocionales [14].
*   **Columnas Críticas:**
    *   `valor_beneficio`: Monto o porcentaje del descuento/regalo. **[Estratégico - Protegido con CLS]** [15, 16].
    *   `fecha_inicio`, `fecha_fin`, `tipo_de_beneficio`.
*   **Hardening:** La visibilidad del `valor_beneficio` se restringe para evitar la manipulación de campañas por personal no autorizado [16].

### 5. `ventas.modalidad`
Define los tipos de contrato bajo los cuales opera una línea.
*   **Propósito:** Categorizar el servicio (ej. Prepago, Postpago) [17].
*   **Columnas:** `id_modalidad` (PK), `nombre`, `descripcion` [18].
*   **Seguridad:** Información de catálogo pública para todos los roles con permiso `SELECT` [16, 19].

### 6. `ventas.plan_corporativo`
Extensión de los planes para el segmento de empresas (B2B).
*   **Propósito:** Gestionar recursos compartidos entre múltiples líneas empresariales [20].
*   **Columnas:** `id_plan` (PK), `id_cliente_corp` (FK), `cupo_compartido`, `datos_compartidos` [21].

### 7. `ventas.linea_plan`
Historial de cambios de plan realizados por una línea telefónica.
*   **Propósito:** Auditoría y trazabilidad de migración entre planes tarifarios [17].
*   **Columnas:** `id_linea_plan` (PK), `id_linea` (FK), `id_plan` (FK), `fecha_inicio`, `motivo_cambio` [22].

### 8. `ventas.promocion_aplicada`
Registro de qué promociones específicas se han activado en cada línea.
*   **Propósito:** Controlar la redención de beneficios por parte de los abonados [23].
*   **Columnas:** `id_aplicacion` (PK), `id_promocion` (FK), `id_linea` (FK), `estado` [24].

### 9. `ventas.bono_promocional`
Detalle de los recursos extra (regalos) entregados tras una promoción.
*   **Propósito:** Cuantificar los beneficios otorgados al usuario final [25].
*   **Columnas:** `id_bono` (PK), `id_aplicacion` (FK), `tipo_recurso`, `cantidad` [26].

---

## 🔒 Matriz de Acceso Rápido (Esquema Ventas)

| Tabla | `employee_role` | `analyst_role` | `manager_role` |
| :--- | :--- | :--- | :--- |
| `plan` | SELECT (Sin Tarifa) | SELECT | SELECT/UPDATE |
| `paquete` | SELECT (Sin Precio) | SELECT | SELECT/UPDATE |
| `paquete_adquirido` | SELECT (Solo saldos restantes) | SELECT | SELECT |
| `promocion` | SELECT (Sin Valor Beneficio) | SELECT | SELECT/UPDATE |
| `modalidad` | SELECT (Full) | SELECT | SELECT |

--------------------------------------------------------------------------------
# 👔 Catálogo de Entidades: Esquema `rrhh`

Este documento describe la estructura del esquema `rrhh` en la base de datos **Viva**. Debido a la sensibilidad de la información salarial y de personal, este esquema opera bajo un aislamiento estricto y políticas de acceso dinámicas.

## 🛡️ Estrategia de Seguridad del Esquema
*   **Dueño del Esquema:** `admin_rrhh` [3, 4].
*   **Principio Aplicado:** Aislamiento total y Autogestión (Self-Service) [5, 6].
*   **Controles:** 
    *   **Seguridad a Nivel de Columna (CLS):** Para ocultar la remuneración económica [1, 7].
    *   **Seguridad a Nivel de Fila (RLS):** Para garantizar que los empleados solo accedan a sus propios registros [6, 8].

---

## 📋 Listado de Entidades

### 1. `rrhh.employee`
Tabla principal que centraliza el registro de los trabajadores de la organización [9, 10].
*   **Propósito:** Gestionar el padrón de empleados, sus cargos y compensaciones [1].
*   **Columnas:**
    *   `id`: Identificador único numérico (PK) [11].
    *   `nombre`: Nombre completo del trabajador (utilizado para vinculación con `current_user` en RLS) [6, 11].
    *   `puesto`: Cargo o función jerárquica [11].
    *   `salario`: Monto de remuneración mensual. **[Crítico - Protegido con CLS]** [7, 11].
*   **Hardening:** 
    *   Se aplica **CLS** para revocar el permiso de lectura en la columna `salario` a cualquier rol que no sea de alta gerencia o administración de RRHH [1, 12].
    *   Se activa **RLS** con la política `USING (nombre = current_user)`, lo que obliga al sistema a filtrar las filas de modo que un empleado solo vea su propia información al consultar la tabla [6, 13].

---

## 🔒 Matriz de Acceso Rápido (Esquema RRHH)

| Actor | Permiso en Tabla | Restricción de Fila (RLS) | Restricción de Columna (CLS) |
| :--- | :--- | :--- | :--- |
| **`employee_role`** | SELECT | **Sí (Solo su propia fila)** | **Sí (Oculta Salario)** |
| **`analyst_role`** | Sin Acceso | N/A | Acceso Denegado [5] |
| **`manager_role`** | SELECT | No (Visibilidad Global) | No (Autorizado) [5] |
| **`admin_rrhh`** | ALL | No (Propietario) | No (Control Total) [14] |
