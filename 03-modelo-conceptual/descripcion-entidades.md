
# 📂 Descripción de Entidades: Esquema `clientes`

Este documento detalla la estructura lógica y el propósito de las entidades que conforman el esquema `clientes`. El diseño está orientado a la protección de la **Información de Identificación Personal (PII)** y la gestión eficiente de los abonados y sus consumos.

---

## 📋 Catálogo de Tablas (6 Entidades)

### 1. `clientes.cliente`
Es la tabla maestra que almacena los datos básicos de las personas naturales que contratan servicios.
*   **Propósito:** Identificar de forma única a cada abonado y almacenar sus datos de contacto.
*   **Atributos Críticos:** 
    *   `id_cliente` (SERIAL): Llave primaria subrogada.
    *   `doc_identidad` (UNIQUE): Documento legal del usuario (Protegido por CLS).
    *   `email`: Correo electrónico personal (Protegido por CLS).
*   **Restricciones:** Posee una restricción de unicidad en `doc_identidad` para evitar registros duplicados.

### 2. `clientes.cliente_corporativo`
Extensión de la tabla cliente para el segmento de negocios y empresas (B2B).
*   **Propósito:** Gestionar la información tributaria y de contacto de personas jurídicas.
*   **Relación:** Vinculada 1:1 con `clientes.cliente`.
*   **Atributos Críticos:** `nit` (Identificador tributario) y `contacto_principal`.

### 3. `clientes.linea_telefonica`
Entidad central que representa el servicio activo contratado por el cliente.
*   **Propósito:** Vincular al abonado con un número telefónico, un plan comercial y una modalidad.
*   **Vínculos Externos:** Referencia a `ventas.plan` y `ventas.modalidad`.
*   **Atributos Clave:** `numero_telefonico` (UNIQUE) y `estado` (Activo/Inactivo/Suspendido).

### 4. `clientes.dispositivo`
Inventario de hardware (teléfonos/módems) vinculados a las líneas telefónicas.
*   **Propósito:** Rastrear el equipo físico utilizado por el cliente para fines de soporte y seguridad.
*   **Atributos Críticos:** `imei` (UNIQUE), identificador internacional de equipo móvil que es tratado como dato sensible.

### 5. `clientes.consumo`
Historial transaccional del tráfico generado por cada línea.
*   **Propósito:** Registrar el uso de voz, SMS y datos para fines de facturación y reportería.
*   **Atributos Clave:** `tipo_consumo`, `minutos_usados`, `datos_mb_usados` y `costo_asociado` (restringido para roles operativos).
*   **Relación:** Se vincula con `finanzas.bolsillo` para el descuento de saldos.

### 6. `clientes.consumo_paquete`
Detalle técnico del agotamiento de recursos específicos provenientes de bolsas o paquetes comprados.
*   **Propósito:** Proporcionar granularidad sobre cómo se consumen los beneficios de los paquetes adquiridos.
*   **Relación:** Vinculada directamente a `ventas.paquete_adquirido`.

---

## 🛠️ Resumen de Integridad y Relaciones

| Entidad | Tipo de Identificador | Relación Principal |
| :--- | :--- | :--- |
| `cliente` | SERIAL (PK) | Base para todas las demás tablas. |
| `cliente_corporativo` | INTEGER (PK/FK) | Especialización de `cliente`. |
| `linea_telefonica` | SERIAL (PK) | Eje central entre `clientes` y `ventas`. |
| `dispositivo` | SERIAL (PK) | Depende de `linea_telefonica`. |
| `consumo` | SERIAL (PK) | Vincula el uso con `finanzas`. |
| `consumo_paquete` | SERIAL (PK) | Detalle de uso de adquisiciones de `ventas`. |

---

## 🔍 Verificación Estructural
Para consultar la definición técnica de estas tablas desde la terminal `psql`, utilice el comando de descripción:
```sql
-- Ejemplo para la tabla cliente
\d clientes.cliente
```
# 📂 Descripción de Entidades: Esquema `finanzas`

Este documento describe la estructura lógica y la finalidad de las entidades que componen el esquema `finanzas`. El diseño está orientado a garantizar la **Integridad Transaccional**, la **Inmutabilidad de los Registros** y la confidencialidad de los balances corporativos [4, 5].

---

## 📋 Catálogo de Tablas (6 Entidades)

### 1. `finanzas.factura`
Es el registro legal de los cobros emitidos por los servicios de telecomunicaciones prestados.
*   **Propósito:** Sustentar legalmente los ingresos y proporcionar una base para la auditoría fiscal [3, 4].
*   **Atributos Críticos:** 
    *   `id_factura` (SERIAL): Llave primaria única.
    *   `monto_base`: Valor neto del servicio facturado.
    *   `ci_nit`: Documento tributario del cliente (Dato PII protegido) [6, 7].
*   **Hardening:** Se implementa **Row Level Security (RLS)** para que los empleados solo visualicen facturas vinculadas a su gestión o sucursal [8, 9].

### 2. `finanzas.bolsillo`
Segmentación detallada del capital y recursos disponibles asociados a la línea de un usuario.
*   **Propósito:** Gestionar los diferentes tipos de saldo (crédito regular, bonificaciones y saldos promocionales) [10].
*   **Atributos Críticos:** `credito_regular`, `credito_promo` y `saldo` total acumulado.
*   **Hardening:** Se aplica **Seguridad a Nivel de Columna (CLS)** para ocultar los saldos reales al `employee_role`, permitiendo solo la visualización de datos de gestión operativa [10].

### 3. `finanzas.recarga`
Historial transaccional de los abonos de capital realizados por los usuarios.
*   **Propósito:** Registrar cada ingreso de dinero y el canal utilizado (App, punto físico, etc.) [4, 11].
*   **Atributo Sensible:** `salario_resultante`, que indica el balance final tras la operación (Protegido por CLS) [10].
*   **Integridad:** Esta tabla es de **solo inserción** para roles operativos para garantizar que el historial financiero no sea alterado [4, 12].

### 4. `finanzas.prestamo`
Gestión de adelantos de saldo otorgados a abonados con balance agotado.
*   **Propósito:** Controlar el otorgamiento de crédito, intereses aplicados y el estado de la deuda (Pendiente/Pagado) [4, 13].
*   **Atributos Clave:** `monto_prestado` e `interes_aplicado`.

### 5. `finanzas.pago_prestamo`
Registro granular de las amortizaciones realizadas por los clientes para liquidar sus préstamos.
*   **Propósito:** Vincular los pagos realizados con las deudas pendientes para mantener el balance de cuentas por cobrar [4, 14].
*   **Integridad:** Se prohíbe el uso de `DELETE` y `UPDATE` sobre esta tabla para asegurar la inmutabilidad de la evidencia de pago [4].

### 6. `finanzas.budget`
Contiene la planificación estratégica, proyecciones de ingresos y límites de gastos aprobados.
*   **Propósito:** Servir como base para la toma de decisiones gerenciales y el control presupuestario [4, 15].
*   **Hardening Crítico:** Acceso **Denegado Total** para el `employee_role`. Solo el `manager_role` y el `analyst_role` (vía vistas seguras) pueden consultar esta información [4, 15].

---

## 🛠️ Resumen de Integridad y Propiedad

| Entidad | Tipo de PK | Hardening Principal |
| :--- | :--- | :--- |
| `factura` | SERIAL | RLS (Filtro por vendedor/sucursal) |
| `bolsillo` | SERIAL | CLS (Saldos ocultos para operativos) |
| `recarga` | SERIAL | Inmutabilidad (No UPDATE/DELETE) |
| `pago_prestamo`| SERIAL | Relación mandatoria con `prestamo` |
| `budget` | N/A | Aislamiento Total (Acceso Restringido) |

---

## 🔍 Verificación Estructural
Para auditar la definición técnica y los privilegios de estas tablas desde la terminal `psql`, utilice:
```sql
-- Listar tablas y dueños del esquema finanzas
\dt finanzas.*

-- Verificar privilegios detallados (ACL)
\dp finanzas.bolsillo
```
# 📂 Descripción de Entidades: Esquema `ventas`

Este documento describe la estructura lógica y el propósito de las entidades que conforman el catálogo maestro de servicios y adquisiciones comerciales de **Viva**. El diseño se centra en la **Integridad del Catálogo** y la protección de la **Confidencialidad de Precios**.

---

## 📋 Catálogo de Tablas (9 Entidades)

### 1. `ventas.plan`
Catálogo maestro de planes tarifarios disponibles para el mercado (Prepago, Postpago e Híbrido).
*   **Propósito:** Definir los beneficios base (minutos, SMS, datos) y el costo mensual de cada plan comercial.
*   **Atributo Sensible:** `tarifa_mensual` (Protegido por CLS para roles operativos).
*   **Identificador:** `id_plan` (SERIAL PK).

### 2. `ventas.paquete`
Definición de bolsas de recursos adicionales (ej. "Paquetitos") que el usuario puede adquirir de forma ad-hoc.
*   **Propósito:** Almacenar la oferta de servicios suplementarios y su vigencia.
*   **Atributo Sensible:** `precio` (Protegido por CLS).
*   **Relación:** Vinculado a una línea telefónica para ofertas personalizadas.

### 3. `ventas.paquete_adquirido`
Registro transaccional de las compras de paquetes realizadas por los abonados.
*   **Propósito:** Rastrear el consumo de bolsas compradas y el tiempo de expiración.
*   **Atributos Sensibles:** `saldo_inicial_min`, `saldo_inicial_datos` y `saldo_inicial` (Ocultos para soporte mediante CLS).

### 4. `ventas.promocion`
Catálogo de reglas de negocio para campañas de beneficios temporales (ej. Duplica Carga).
*   **Propósito:** Definir los valores de beneficios, horarios y fechas de vigencia de las campañas.
*   **Atributo Sensible:** `valor_beneficio` (Protegido por CLS).

### 5. `ventas.modalidad`
Tabla de referencia que define los tipos de contrato.
*   **Propósito:** Clasificar las líneas en categorías legales (ej. Prepago, Postpago, Corporativo).

### 6. `ventas.plan_corporativo`
Extensión especializada para la gestión de cuentas empresariales (B2B).
*   **Propósito:** Controlar cupos compartidos y recursos distribuidos entre múltiples empleados de una empresa.
*   **Relación:** Vincula `ventas.plan` con `clientes.cliente_corporativo`.

### 7. `ventas.linea_plan`
Historial cronológico de la relación entre una línea y sus planes tarifarios.
*   **Propósito:** Registrar migraciones de planes y motivos de cambio para auditoría comercial.

### 8. `ventas.promocion_aplicada`
Registro de activación de beneficios específicos en las líneas de los clientes.
*   **Propósito:** Documentar cuándo y bajo qué condiciones un abonado accedió a una oferta especial.

### 9. `ventas.bono_promocional`
Detalle granular de los recursos extra entregados tras la aplicación de una promoción.
*   **Propósito:** Identificar qué recurso específico (MB, Minutos) fue abonado como regalo.

---

## 🛡️ Resumen de Integridad y Hardening

| Entidad | Tipo de Identificador | Hardening Principal |
| :--- | :--- | :--- |
| `plan`, `paquete` | SERIAL (PK) | CLS (Precios ocultos para operativos) |
| `promocion` | SERIAL (PK) | CLS (Valor de beneficio oculto) |
| `paquete_adquirido` | SERIAL (PK) | CLS (Saldos iniciales restringidos) |
| `modalidad` | SERIAL (PK) | Catálogo de solo lectura |
| `plan_corporativo` | INTEGER (PK/FK) | Aislamiento B2B |

---

## 🔍 Verificación Estructural
Para consultar la definición técnica y los dueños de estas tablas desde la terminal `psql`, utilice:
```sql
-- Listar tablas y dueños del esquema ventas
\dt ventas.*

-- Verificar columnas y restricciones de una tabla específica
\d ventas.paquete
```

# 📂 Descripción de Entidades: Esquema `rrhh`

Este documento detalla la estructura lógica y técnica del esquema de Recursos Humanos. El diseño está orientado al **Aislamiento Total** de la información sensible del personal y a la implementación de un modelo de "Autogestión Segura" para los empleados de **Viva**.

---

## 📋 Detalle de la Entidad Principal

### 1. `rrhh.employee`
Es la tabla maestra que centraliza el padrón de trabajadores de la organización.
*   **Propósito:** Almacenar la identidad, el cargo y la compensación económica de cada colaborador.
*   **Aislamiento:** Esta tabla reside en un esquema dedicado cuyo dueño es `admin_rrhh`, segregando estos datos de los procesos comerciales y de clientes [2, 3].

#### 📊 Estructura Técnica de Columnas
| Columna | Tipo de Dato | Restricción | Descripción |
| :--- | :--- | :--- | :--- |
| `id` | `INTEGER` | PK | Identificador único del trabajador (Secuencia automática) [4]. |
| `nombre` | `TEXT` | UNIQUE | Nombre completo del empleado. Se usa como clave para políticas RLS [4]. |
| `puesto` | `TEXT` | - | Cargo o función jerárquica dentro de la empresa [4]. |
| `salario` | `NUMERIC` | **Crítica** | Monto de remuneración mensual (Protegido por CLS) [4, 5]. |

---

## 🛡️ Hardening y Reglas de Negocio

La entidad `employee` no es una tabla convencional; su acceso está condicionado por técnicas de **Seguridad Quirúrgica**:

1.  **Seguridad a Nivel de Columna (CLS):** La columna `salario` es invisible para el `employee_role`. El personal solo puede consultar su `id`, `nombre` y `puesto` [6, 7].
2.  **Seguridad a Nivel de Fila (RLS):** Se aplica la política de "Self-Service", donde el motor de la base de datos filtra los registros para que un empleado solo pueda visualizar la fila que coincida con su usuario de sesión (`USING (nombre = current_user)`) [8, 9].
3.  **Inmutabilidad:** Se restringen los permisos de `DELETE` y `TRUNCATE` para evitar la eliminación accidental o maliciosa de registros de personal [10, 11].

---

## 🔍 Verificación Estructural
Para auditar la definición técnica y los privilegios aplicados a esta entidad desde la terminal `psql`, utilice:

```sql
-- Ver detalle de columnas, tipos e índices
\d rrhh.employee

-- Verificar el dueño de la tabla (Debe ser admin_rrhh)
\dt rrhh.employee

-- Comprobar privilegios granulares (ACL) por columna
\dp rrhh.employee
