
# 📖 Diccionario de Datos: Esquema `clientes`

Este documento detalla la estructura técnica y los controles de seguridad aplicados a las entidades del esquema `clientes` en la base de datos **Viva**. La arquitectura sigue el **Principio de Mínimo Privilegio (PoLP)** para proteger la **Información de Identificación Personal (PII)** [1, 2].

## 🛡️ Resumen de Hardening del Esquema
*   **Propietario:** `admin_clientes` (Rol con atributo `NOLOGIN`) [3, 4].
*   **Aislamiento:** El acceso al esquema `public` ha sido revocado para garantizar la segregación de funciones [5, 6].
*   **Controles de Columna (CLS):** Restricción nativa de columnas sensibles para roles operativos [2, 7].

---

## 📋 Detalle de Entidades (6 Tablas)

### 1. Tabla: `clientes.cliente`
Contiene la información maestra de los abonados naturales.

| Columna | Tipo de Dato | Restricción | Descripción | Sensibilidad |
| :--- | :--- | :--- | :--- | :--- |
| `id_cliente` | `SERIAL` | PK | ID único del cliente. | Pública |
| `tipo_cliente` | `VARCHAR(50)` | - | Categoría (Prepago/Postpago). | Pública |
| `nombre` | `VARCHAR(100)` | - | Nombres del abonado. | Pública |
| `apellidos` | `VARCHAR(100)` | - | Apellidos del abonado. | Pública |
| `doc_identidad` | `VARCHAR(20)` | Unique | Documento de identidad (DNI/CI). | **Crítica (PII)** |
| `email` | `VARCHAR(100)` | - | Correo electrónico personal. | **Crítica (PII)** |
| `direccion` | `TEXT` | - | Domicilio registrado. | Alta |
| `fecha_registro`| `DATE` | - | Fecha de alta en el sistema. | Baja |
| `antiguedad_dias`| `INTEGER` | - | Días desde el registro. | Baja |

> **Control CLS:** Se ha revocado el acceso a `doc_identidad` y `email` para el `employee_role` [8, 9].

---

### 2. Tabla: `clientes.cliente_corporativo`
Extensión para la gestión de cuentas empresariales y B2B.

| Columna | Tipo de Dato | Restricción | Descripción | Sensibilidad |
| :--- | :--- | :--- | :--- | :--- |
| `id_cliente` | `INTEGER` | PK, FK | Relación con `clientes.cliente`. | Pública |
| `razon_social` | `VARCHAR(150)` | - | Nombre legal de la empresa. | Pública |
| `nit` | `VARCHAR(20)` | - | Identificador tributario. | **Crítica** |
| `sector` | `VARCHAR(100)` | - | Rubro industrial. | Media |
| `num_empleado` | `INTEGER` | - | Cantidad de líneas vinculadas. | Media |
| `contacto_principal`| `VARCHAR(100)`| - | Persona de enlace autorizada. | **Alta** |

> **Hardening:** El `nit` y `contacto_principal` están restringidos para evitar fuga de información estratégica [9, 10].

---

### 3. Tabla: `clientes.dispositivo`
Inventario de hardware vinculado a las líneas activas.

| Columna | Tipo de Dato | Restricción | Descripción | Sensibilidad |
| :--- | :--- | :--- | :--- | :--- |
| `id_dispositivo`| `SERIAL` | PK | Identificador único del equipo. | Pública |
| `id_linea` | `INTEGER` | FK | Referencia a la línea activa. | Pública |
| `id_cliente` | `INTEGER` | FK | Referencia al dueño del equipo. | Pública |
| `imei` | `VARCHAR(20)` | Unique | ID internacional de equipo móvil. | **Crítica** |
| `marca` | `VARCHAR(50)` | - | Fabricante del hardware. | Baja |
| `modelo` | `VARCHAR(50)` | - | Modelo específico del equipo. | Baja |

> **Hardening:** El `imei` se enmascara mediante vistas seguras para el `analyst_role` [11, 12].

---

### 4. Tabla: `clientes.linea_telefonica`
Entidad que vincula al abonado con el servicio comercial.

| Columna | Tipo de Dato | Restricción | Descripción | Sensibilidad |
| :--- | :--- | :--- | :--- | :--- |
| `id_linea` | `SERIAL` | PK | Identificador único de línea. | Pública |
| `id_cliente` | `INTEGER` | FK | Dueño de la línea. | Pública |
| `id_modalidad` | `INTEGER` | FK | Relación con modalidad de contrato.| Pública |
| `id_plan` | `INTEGER` | FK | Plan comercial asignado. | Pública |
| `numero_telefonico`| `VARCHAR(15)` | Unique | Número de teléfono asignado. | Pública |
| `fecha_activacion`| `DATE` | - | Inicio del servicio. | Baja |
| `estado` | `VARCHAR(20)` | - | Estado (Activa, Suspendida, etc.).| Media |

---

### 5. Tabla: `clientes.consumo`
Historial de tráfico de voz, SMS y datos.

| Columna | Tipo de Dato | Restricción | Descripción | Sensibilidad |
| :--- | :--- | :--- | :--- | :--- |
| `id_consumo` | `SERIAL` | PK | ID de la transacción de uso. | Pública |
| `id_bolsillo` | `INTEGER` | FK | Relación con saldos financieros. | Pública |
| `id_adquisicion`| `INTEGER` | FK | Vínculo con paquete comprado. | Pública |
| `fecha_consumo` | `TIMESTAMP` | - | Momento exacto del uso. | Media |
| `tipo_consumo` | `VARCHAR(50)` | - | Voz, SMS o Datos. | Media |
| `minutos_usados`| `INTEGER` | - | Cantidad de tiempo/unidades. | Baja |
| `datos_mb_usados`| `NUMERIC` | - | Megabytes consumidos. | Baja |
| `costo_asociado`| `NUMERIC` | - | Valor monetario del consumo. | **Alta** |

> **Control CLS:** `costo_asociado` es invisible para `employee_role` para prevenir fraudes en saldos [13, 14].

---

### 6. Tabla: `clientes.consumo_paquete`
Detalle técnico del agotamiento de recursos de bolsas específicas.

| Columna | Tipo de Dato | Restricción | Descripción | Sensibilidad |
| :--- | :--- | :--- | :--- | :--- |
| `id_consumo` | `SERIAL` | PK | ID técnico del detalle. | Pública |
| `id_adquisicion`| `INTEGER` | FK | Vínculo con la compra original. | Pública |
| `cantidad_aplicada`| `NUMERIC`| - | Recurso descontado de la bolsa. | Baja |
| `consumo_generado`| `NUMERIC` | - | Valor técnico del tráfico. | Baja |

---

## 🔒 Matriz de Privilegios

| Rol | Permiso General | Restricción Crítica (CLS) |
| :--- | :--- | :--- |
| **`rol_lectura`** | `SELECT` | Acceso a columnas sin PII [15, 16]. |
| **`employee_role`** | `SELECT`, `INSERT` | Bloqueo de `doc_identidad`, `email`, `imei`, `costo_asociado` [8, 17]. |
| **`analyst_role`** | `SELECT` (Vistas) | Datos enmascarados (ej: IMEI parcial) [11, 18]. |

--------------------------------------------------------------------------------
# 💰 Diccionario de Datos: Esquema `finanzas`

Este documento describe la arquitectura técnica y los controles de seguridad aplicados a las entidades del esquema `finanzas`. Dado que este esquema gestiona transacciones monetarias y saldos, la seguridad se basa en la **Inmutabilidad de Datos** y el **Aislamiento Total** de presupuestos estratégicos [2-4].

## 🛡️ Resumen de Hardening del Esquema
*   **Propietario:** `admin_finanzas` (Rol con atributo `NOLOGIN`) [5, 6].
*   **Controles de Fila (RLS):** Activado en tablas transaccionales para limitar la visibilidad de facturas según el usuario [7, 8].
*   **Controles de Columna (CLS):** Restricción de acceso a saldos acumulados y montos de deuda para roles operativos [3, 9].

---

## 📋 Detalle de Entidades (6 Tablas)

### 1. Tabla: `finanzas.factura`
Registro legal de cobros emitidos por servicios de telecomunicaciones.

| Columna | Tipo de Dato | Restricción | Descripción | Sensibilidad |
| :--- | :--- | :--- | :--- | :--- |
| `id_factura` | `SERIAL` | PK | Identificador único de factura. | Pública |
| `id_linea` | `INTEGER` | FK | Relación con la línea telefónica. | Pública |
| `ci_nit` | `VARCHAR(20)` | - | Documento tributario del cliente. | **Crítica (PII)** |
| `monto_base` | `NUMERIC(10,2)` | - | Monto neto de la factura. | Alta |
| `fecha_emision` | `DATE` | - | Fecha de generación del cobro. | Media |
| `intereses` | `NUMERIC(10,2)` | - | Recargos por mora aplicados. | Alta |

> **Hardening:** Implementa **RLS** para que los empleados solo visualicen facturas vinculadas a su gestión o sucursal [7].

---

### 2. Tabla: `finanzas.bolsillo`
Segmentación detallada del capital y recursos disponibles en la línea del usuario.

| Columna | Tipo de Dato | Restricción | Descripción | Sensibilidad |
| :--- | :--- | :--- | :--- | :--- |
| `id_bolsillo` | `SERIAL` | PK | ID técnico del bolsillo. | Pública |
| `id_linea` | `INTEGER` | FK | Línea dueña de los recursos. | Pública |
| `credito_regular`| `NUMERIC(10,2)` | - | Saldo en efectivo principal. | **Crítica** |
| `credito_promo` | `NUMERIC(10,2)` | - | Saldo de bonificaciones. | **Crítica** |
| `saldo` | `NUMERIC(10,2)` | - | Total consolidado disponible. | **Crítica** |

> **Control CLS:** El acceso a esta tabla está **denegado por defecto** para el `employee_role` para prevenir manipulaciones de saldo [2, 9].

---

### 3. Tabla: `finanzas.recarga`
Historial de abonos de capital realizados a las líneas.

| Columna | Tipo de Dato | Restricción | Descripción | Sensibilidad |
| :--- | :--- | :--- | :--- | :--- |
| `id_recarga` | `SERIAL` | PK | Identificador de la transacción. | Pública |
| `monto` | `NUMERIC(10,2)` | - | Valor monetario ingresado. | Alta |
| `medio_recarga` | `VARCHAR(50)` | - | Canal (App, Punto físico, etc.). | Media |
| `salario_resultante`| `NUMERIC(10,2)`| - | Saldo del cliente tras recarga. | **Crítica** |

> **Control CLS:** La columna `salario_resultante` es invisible para personal operativo mediante CLS [9].

---

### 4. Tabla: `finanzas.prestamo`
Gestión de créditos de saldo otorgados a usuarios con balance agotado.

| Columna | Tipo de Dato | Restricción | Descripción | Sensibilidad |
| :--- | :--- | :--- | :--- | :--- |
| `id_prestamo` | `SERIAL` | PK | ID único del crédito. | Pública |
| `monto_prestado` | `NUMERIC(10,2)` | - | Capital entregado al usuario. | Alta |
| `monto_total_pagar`| `NUMERIC(10,2)`| - | Deuda total incluyendo intereses. | Alta |
| `estado_prestamo` | `VARCHAR(20)` | - | Situación (Pendiente, Pagado). | Media |

---

### 5. Tabla: `finanzas.pago_prestamo`
Registro de amortizaciones de deuda realizadas por el cliente.

| Columna | Tipo de Dato | Restricción | Descripción | Sensibilidad |
| :--- | :--- | :--- | :--- | :--- |
| `id_pago_prestamo`| `SERIAL` | PK | ID técnico del abono. | Pública |
| `id_prestamo` | `INTEGER` | FK | Relación con la deuda original. | Pública |
| `monto_pagado` | `NUMERIC(10,2)` | - | Valor abonado a la deuda. | Alta |
| `comprobante` | `VARCHAR(100)` | - | Referencia legal del pago. | Media |

> **Hardening:** Se revoca el permiso de `UPDATE` y `DELETE` para garantizar la inmutabilidad de la evidencia financiera [10].

---

### 6. Tabla: `finanzas.budget`
Planificación y presupuestos estratégicos de la corporación.

| Columna | Tipo de Dato | Restricción | Descripción | Sensibilidad |
| :--- | :--- | :--- | :--- | :--- |
| `sales` | `NUMERIC` | - | Proyecciones de ingresos. | **Estratégica** |
| `expenses` | `NUMERIC` | - | Límites de gasto aprobados. | **Estratégica** |
| `notes` | `TEXT` | - | Comentarios confidenciales. | **Crítica** |

> **Hardening:** Acceso restringido exclusivamente a `manager_role` y `analyst_role` (vía vistas). El personal operativo no tiene USAGE sobre esta tabla [2, 11].

---

## 🔒 Matriz de Privilegios del Esquema

| Rol | `factura` | `recarga` | `pago_prestamo` | `bolsillo` / `budget` |
| :--- | :--- | :--- | :--- | :--- |
| **`rol_lectura`** | `SELECT` | `SELECT` | `SELECT` | `SELECT` |
| **`employee_role`** | `SELECT`, `INSERT` | `SELECT`, `INSERT` | `INSERT` | **Sin Acceso** |
| **`analyst_role`** | `SELECT` | `SELECT` | `SELECT` | `SELECT` (Vistas) |
| **`manager_role`** | `SELECT` | `SELECT` | `SELECT` | `SELECT`, `UPDATE` |

--------------------------------------------------------------------------------
# 📈 Diccionario de Datos: Esquema `ventas`

Este documento describe la estructura lógica y técnica del esquema `ventas`. Este esquema actúa como el catálogo maestro de servicios y productos de **Viva**, por lo que su seguridad se centra en proteger la **Confidencialidad de Precios** y la **Integridad de las Ofertas Comerciales**.

## 🛡️ Resumen de Hardening del Esquema
*   **Propietario:** `admin_ventas` (Rol con atributo `NOLOGIN`).
*   **Aislamiento de Dominio:** Los roles operativos tienen acceso de solo lectura (Catálogo) para evitar modificaciones no autorizadas en precios o planes.
*   **Controles de Columna (CLS):** Restricción de acceso a tarifas mensuales, precios de paquetes y valores de beneficios promocionales para roles operativos.

---

## 📋 Detalle de Entidades (9 Tablas)

### 1. Tabla: `ventas.plan`
Catálogo maestro de planes tarifarios (Postpago, Prepago, Híbrido).

| Columna | Tipo de Dato | Restricción | Descripción | Sensibilidad |
| :--- | :--- | :--- | :--- | :--- |
| `id_plan` | `SERIAL` | PK | Identificador único del plan. | Pública |
| `nombre_plan` | `VARCHAR(100)` | - | Nombre comercial del plan. | Pública |
| `tarifa_mensual`| `DECIMAL(10,2)`| - | Costo base mensual del servicio. | **Estratégica (CLS)** |
| `minutos_incluidos`| `INTEGER` | - | Bolsa de minutos de voz incluida. | Baja |
| `datos_mb_incluidos`| `INTEGER` | - | Bolsa de datos en MB incluida. | Baja |
| `activo` | `BOOLEAN` | - | Indica si el plan está vigente. | Media |

> **Hardening:** Se ha revocado el acceso a `tarifa_mensual` para el `employee_role` para evitar filtraciones de precios base [4, 5].

---

### 2. Tabla: `ventas.paquete`
Definición de bolsas de recursos adicionales que los usuarios pueden adquirir.

| Columna | Tipo de Dato | Restricción | Descripción | Sensibilidad |
| :--- | :--- | :--- | :--- | :--- |
| `id_paquete` | `SERIAL` | PK | Identificador único del paquete. | Pública |
| `nombre_paquete`| `VARCHAR(100)` | - | Nombre comercial (ej. Paquetito). | Pública |
| `precio` | `DECIMAL(10,2)`| - | Valor de venta del paquete. | **Estratégica (CLS)** |
| `vigencia_dias` | `INTEGER` | - | Duración del paquete tras compra. | Baja |
| `combo` | `BOOLEAN` | - | Indica si incluye múltiples recursos. | Baja |

> **Hardening:** El acceso a la columna `precio` está restringido para roles operativos para evitar negociaciones no autorizadas [4, 6].

---

### 3. Tabla: `ventas.paquete_adquirido`
Registro transaccional de las compras de paquetes realizadas por los usuarios.

| Columna | Tipo de Dato | Restricción | Descripción | Sensibilidad |
| :--- | :--- | :--- | :--- | :--- |
| `id_adquisicion`| `SERIAL` | PK | ID único de la transacción. | Pública |
| `fecha_compra` | `TIMESTAMP` | - | Momento exacto de la adquisición. | Media |
| `saldo_inicial` | `DECIMAL(10,2)`| - | Monto original al momento de compra.| **Alta (CLS)** |
| `saldo_restante_datos`| `DECIMAL(10,2)`| - | MB actuales disponibles para uso. | Media |
| `estado` | `VARCHAR(20)` | - | Situación (Activo, Expirado). | Baja |

> **Hardening:** Los saldos iniciales (`saldo_inicial_...`) están ocultos al personal operativo; solo deben visualizar el remanente para soporte [5, 7].

---

### 4. Tabla: `ventas.promocion`
Reglas de negocio para beneficios temporales y ofertas especiales.

| Columna | Tipo de Dato | Restricción | Descripción | Sensibilidad |
| :--- | :--- | :--- | :--- | :--- |
| `id_promocion` | `SERIAL` | PK | Identificador de la campaña. | Pública |
| `nombre` | `VARCHAR(100)` | - | Nombre de la promoción. | Pública |
| `valor_beneficio`| `DECIMAL(10,2)`| - | Monto o % del beneficio otorgado. | **Estratégica (CLS)** |
| `fecha_inicio` | `DATE` | - | Inicio de vigencia de la campaña. | Media |
| `fecha_fin` | `DATE` | - | Cierre de vigencia de la campaña. | Media |

> **Hardening:** La visibilidad de `valor_beneficio` se restringe para evitar la manipulación de campañas por personal no autorizado [5, 8].

---

### 5. Tabla: `ventas.modalidad`
Define los tipos de contrato bajo los cuales opera una línea.

| Columna | Tipo de Dato | Restricción | Descripción | Sensibilidad |
| :--- | :--- | :--- | :--- | :--- |
| `id_modalidad` | `SERIAL` | PK | ID único de la modalidad. | Pública |
| `nombre` | `VARCHAR(50)` | - | Prepago, Postpago, Híbrido. | Pública |

---

### 🛠️ Otras Entidades del Esquema
*   **`ventas.plan_corporativo`**: Gestión de recursos compartidos para el segmento B2B [9].
*   **`ventas.linea_plan`**: Historial de migración entre planes tarifarios por línea [10].
*   **`ventas.promocion_aplicada`**: Registro de activación de beneficios en líneas específicas [11].
*   **`ventas.bono_promocional`**: Detalle de los recursos extra entregados tras una promoción [12].

---

## 🔒 Matriz de Privilegios del Esquema

| Rol | `plan` / `paquete` | `paquete_adquirido` | `promocion` | Otros Catálogos |
| :--- | :--- | :--- | :--- | :--- |
| **`rol_lectura`** | `SELECT` | `SELECT` | `SELECT` | `SELECT` |
| **`employee_role`** | `SELECT` (Sin Precios) | `SELECT` (Sin Iniciales)| `SELECT` (Sin Valor) | `SELECT` |
| **`analyst_role`** | `SELECT` (Vistas) | `SELECT` | `SELECT` | `SELECT` |
| **`manager_role`** | `SELECT`, `UPDATE` | `SELECT` | `SELECT`, `UPDATE` | `SELECT`, `UPDATE` |

--------------------------------------------------------------------------------
# 👔 Diccionario de Datos: Esquema `rrhh`

Este documento describe la estructura técnica y los controles de seguridad aplicados al esquema de Recursos Humanos. Debido a la naturaleza sensible de la nómina y los datos del personal, este esquema opera bajo el nivel más alto de aislamiento y políticas de acceso dinámicas.

## 🛡️ Resumen de Hardening del Esquema
*   **Propietario:** `admin_rrhh` (Rol con atributo `NOLOGIN`).
*   **Seguridad a Nivel de Fila (RLS):** Implementada para garantizar que los empleados solo visualicen su propia información personal (Self-Service).
*   **Seguridad a Nivel de Columna (CLS):** Restricción nativa en la columna de remuneraciones para proteger la confidencialidad salarial.

---

## 📋 Detalle de Entidades (1 Tabla)

### 1. Tabla: `rrhh.employee`
Entidad principal que almacena el padrón de empleados de la organización.

| Columna | Tipo de Dato | Restricción | Descripción | Sensibilidad |
| :--- | :--- | :--- | :--- | :--- |
| `id` | `INTEGER` | PK | Identificador único del trabajador. | Pública |
| `nombre` | `TEXT` | - | Nombre completo del empleado. | Pública |
| `puesto` | `TEXT` | - | Cargo o función jerárquica. | Pública |
| `salario` | `NUMERIC` | - | Monto de compensación mensual. | **Crítica (CLS)** |

#### 🔐 Políticas de Seguridad Aplicadas:

*   **Control CLS (Columna):** Se ha revocado el acceso total al `employee_role` y se ha otorgado permiso `SELECT` únicamente sobre `id`, `nombre` y `puesto`. La columna `salario` permanece oculta para este rol [1, 3].
*   **Control RLS (Fila):** Se ha habilitado una política de acceso dinámico:
    ```sql
    CREATE POLICY policy_employee_self_service ON rrhh.employee
        FOR SELECT TO employee_role
        USING (nombre = current_user);
    ```
    Esto garantiza que, tras el filtro de columnas, el usuario solo vea el registro que coincida con su identidad de sesión [4].

---

## 🔒 Matriz de Privilegios del Esquema

| Actor | Permiso en Tabla | Restricción de Fila (RLS) | Restricción de Columna (CLS) |
| :--- | :--- | :--- | :--- |
| **`employee_role`** | `SELECT` | **Sí** (Solo su propia fila) | **Sí** (Oculta Salario) |
| **`analyst_role`** | **Sin Acceso** | N/A | Acceso Denegado |
| **`manager_role`** | `SELECT` | No (Visibilidad Global) | No (Autorizado) |
| **`rol_lectura`** | `SELECT` | No (Consultivo) | No (Auditoría) |
| **`admin_rrhh`** | `ALL` | No (Propietario) | No (Control Total) |
