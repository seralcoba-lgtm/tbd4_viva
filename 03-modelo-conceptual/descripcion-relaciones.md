
# 🔗 Descripción de Relaciones: Esquema `clientes`

Este documento describe la arquitectura de vínculos e integridad referencial del esquema `clientes`. El diseño garantiza que cada abonado, línea y registro de consumo esté debidamente conectado, permitiendo la trazabilidad total del servicio en la base de datos **"Viva"**.

## 📑 Resumen de Relaciones Principales

### 1. Extensión de Identidad (1:1)
*   **`cliente` ↔ `cliente_corporativo`**: 
    *   **Vínculo:** `clientes.cliente_corporativo(id_cliente)` es una Llave Primaria (PK) que actúa simultáneamente como Llave Foránea (FK) hacia `clientes.cliente(id_cliente)`.
    *   **Lógica:** Permite extender la información de una persona natural hacia una entidad legal (B2B) de forma opcional.

### 2. Propiedad del Servicio (1:N)
*   **`cliente` ↔ `linea_telefonica`**: 
    *   **Vínculo:** `clientes.linea_telefonica(id_cliente)` referencia a `clientes.cliente(id_cliente)`.
    *   **Lógica:** Un cliente puede ser titular de múltiples líneas telefónicas. La relación es mandatoria para la línea; no existen líneas "huérfanas" sin un titular responsable.

### 3. Auditoría de Hardware (1:N)
*   **`linea_telefonica` ↔ `dispositivo`**: 
    *   **Vínculo:** `clientes.dispositivo(id_linea)` referencia a `clientes.linea_telefonica(id_linea)`.
    *   **Lógica:** Mantiene el registro de los equipos físicos (IMEI) vinculados a una línea. Un cliente puede cambiar de equipo, generando un historial de dispositivos por línea.

### 4. Trazabilidad de Tráfico (1:N)
*   **`linea_telefonica` ↔ `consumo`**: 
    *   **Vínculo:** La relación se realiza a través del saldo en `finanzas.bolsillo`, vinculando el tráfico de red con el responsable de la línea.
    *   **Lógica:** Cada registro de consumo (voz, datos o SMS) debe estar anclado a una línea activa para su correcta tasación.

### 5. Detalle de Adquisiciones (1:N)
*   **`paquete_adquirido` ↔ `consumo_paquete`**: 
    *   **Vínculo:** `clientes.consumo_paquete(id_adquisicion)` referencia a `ventas.paquete_adquirido(id_adquisicion)`.
    *   **Lógica:** Relación técnica que desglosa cómo se agotan los recursos específicos de una bolsa o paquete comprado por el usuario.

---

## 🏗️ Vínculos Inter-Esquema (Cross-Schema)

El esquema `clientes` actúa como el eje central de la base de datos, conectándose con las áreas comercial y financiera:

| Tabla Origen | Columna FK | Tabla Destino (Esquema) | Propósito |
| :--- | :--- | :--- | :--- |
| `linea_telefonica` | `id_plan` | `ventas.plan` | Asignar beneficios tarifarios. |
| `linea_telefonica` | `id_modalidad` | `ventas.modalidad` | Definir tipo de contrato (Prepago/Postpago). |
| `consumo` | `id_bolsillo` | `finanzas.bolsillo` | Descontar saldo tras el uso. |
| `consumo_paquete` | `id_adquisicion` | `ventas.paquete_adquirido` | Validar vigencia de bolsas compradas. |

---

## 🛠️ Reglas de Integridad Técnica

1.  **Llaves Subrogadas:** Se utilizan tipos `SERIAL` en las PK para garantizar que las relaciones no se rompan si cambian datos de negocio (como el número telefónico o documento de identidad).
2.  **Restricciones de Borrado:** Para proteger la integridad, se aplican restricciones que impiden eliminar un `cliente` si existen `lineas_telefonicas` activas asociadas.
3.  **Seguridad por Columna (CLS):** Aunque las tablas están relacionadas, los roles operativos (`employee_role`) tienen restringido el acceso a columnas de unión que contengan datos sensibles como el `IMEI` o `doc_identidad` para cumplir con el **PoLP**.

---

## 🔍 Comandos de Verificación
Para auditar las llaves foráneas y restricciones desde `psql`:
```sql
-- Ver llaves foráneas que referencian a la tabla cliente
\d clientes.cliente

-- Ver relaciones de la tabla de líneas
\d clientes.linea_telefonica
```
---------------------------------------------------------------------------------------
# 🔗 Descripción de Relaciones: Esquema `finanzas`

Este documento describe la arquitectura de vínculos e integridad referencial del esquema `finanzas`. El diseño está orientado a la **Trazabilidad Monetaria**, asegurando que cada transacción financiera esté vinculada de forma obligatoria a una línea de servicio y, cuando corresponda, a un plan comercial [1, 2].

## 📑 Resumen de Relaciones Principales

### 1. Centralización de Saldos (1:1 / 1:N)
*   **`linea_telefonica` ↔ `bolsillo`**: 
    *   **Vínculo:** `finanzas.bolsillo(id_linea)` referencia a `clientes.linea_telefonica(id_linea)`.
    *   **Lógica:** Toda línea activa debe poseer un registro de "bolsillo" para gestionar sus saldos de crédito regular y promocional. Es una relación mandatoria para la operatividad del servicio.

### 2. Sustento de Cobros Legales (1:N)
*   **`linea_telefonica` ↔ `factura`**: 
    *   **Vínculo:** `finanzas.factura(id_linea)` referencia a `clientes.linea_telefonica(id_linea)`.
    *   **Lógica:** Permite asociar múltiples documentos fiscales a un solo abonado a lo largo del tiempo.

### 3. Trazabilidad de Ingresos (1:N)
*   **`linea_telefonica` ↔ `recarga`**: 
    *   **Vínculo:** `finanzas.recarga(id_linea)` referencia a `clientes.linea_telefonica(id_linea)`.
    *   **Lógica:** Cada registro de ingreso de dinero debe quedar anclado a un número telefónico específico para actualizar el `salario_resultante`.

### 4. Control de Deuda y Pagos (1:N)
*   **`prestamo` ↔ `pago_prestamo`**: 
    *   **Vínculo:** `finanzas.pago_prestamo(id_prestamo)` referencia a `finanzas.prestamo(id_prestamo)`.
    *   **Lógica:** Un préstamo puede ser liquidado mediante uno o varios abonos. La relación es mandatoria; no pueden existir pagos "huérfanos" sin una deuda de origen.

---

## 🏗️ Vínculos Inter-Esquema (Cross-Schema)

El esquema financiero se integra con las áreas comercial y operativa para validar tarifas y descontar recursos:

| Tabla Origen | Columna FK | Tabla Destino (Esquema) | Propósito |
| :--- | :--- | :--- | :--- |
| `factura` | `id_plan` | `ventas.plan` | Aplicar la tarifa mensual correcta al cobro [2]. |
| `consumo` | `id_bolsillo` | `finanzas.bolsillo` | Descontar saldo/minutos tras el uso del servicio. |
| `pago_prestamo` | `id_prestamo` | `finanzas.prestamo` | Conciliar deudas activas con ingresos. |

---

## 🛠️ Reglas de Integridad Técnica

1.  **Inmutabilidad Transaccional:** Las relaciones en las tablas `recarga` y `pago_prestamo` están protegidas. Aunque existe el vínculo técnico, los roles operativos tienen prohibido realizar `UPDATE` o `DELETE` sobre estas llaves para evitar fraudes financieros.
2.  **Integridad Referencial:** Se aplican restricciones `ON DELETE RESTRICT` en las líneas telefónicas; no se puede eliminar una línea de `clientes` si existen facturas o deudas pendientes en `finanzas`.
3.  **Seguridad Granular (CLS):** A pesar de existir una relación física, el acceso a las columnas de saldo en `bolsillo` está restringido para el `employee_role`, permitiendo solo la navegación técnica necesaria para el soporte [3].

---

## 🔍 Comandos de Verificación
Para auditar las llaves foráneas y restricciones del esquema financiero desde `psql`:
```sql
-- Ver detalles de relaciones de la tabla factura
\d finanzas.factura

-- Verificar vínculos de la tabla de préstamos
\d finanzas.prestamo
```

--------------------------------------------------------------------------------------
# 🔗 Descripción de Relaciones: Esquema `ventas`

Este documento describe la arquitectura de vínculos e integridad referencial del esquema `ventas`. El diseño asegura que toda oferta comercial, paquete o promoción esté técnicamente vinculada a un plan maestro y a una línea de servicio activa para su correcta tasación y auditoría [1].

## 📑 Resumen de Relaciones Principales

### 1. Especialización de Planes (1:1)
*   **`plan` ↔ `plan_corporativo`**: 
    *   **Vínculo:** `ventas.plan_corporativo(id_plan)` es una Llave Primaria que actúa como Llave Foránea (FK) hacia `ventas.plan(id_plan)` [2].
    *   **Lógica:** Permite que un plan base se extienda con atributos específicos para el segmento de empresas (B2B), como el cupo compartido [1, 2].

### 2. Ciclo de Vida de Adquisiciones (1:N)
*   **`paquete` ↔ `paquete_adquirido`**: 
    *   **Vínculo:** `ventas.paquete_adquirido(id_paquete)` referencia a `ventas.paquete(id_paquete)` [3].
    *   **Lógica:** Un paquete definido en el catálogo puede ser comprado múltiples veces por distintos usuarios, manteniendo el registro de saldos iniciales y restantes [3].

*   **`promocion` ↔ `promocion_aplicada`**: 
    *   **Vínculo:** `ventas.promocion_aplicada(id_promocion)` referencia a `ventas.promocion(id_promocion)` [4].
    *   **Lógica:** Una regla promocional del catálogo se aplica de forma masiva o individual a las líneas de los abonados [4].

### 3. Detalle de Beneficios (1:N)
*   **`promocion_aplicada` ↔ `bono_promocional`**: 
    *   **Vínculo:** `ventas.bono_promocional(id_aplicacion)` referencia a `ventas.promocion_aplicada(id_aplicacion)` [5].
    *   **Lógica:** Una sola aplicación de promoción puede generar diversos bonos de recursos (SMS, MB, Minutos) con sus propias fechas de expiración [5].

---

## 🏗️ Vínculos Inter-Esquema (Cross-Schema)

El esquema de ventas provee las reglas de negocio que consumen los esquemas de clientes y finanzas:

| Tabla Origen (Esquema) | Columna FK | Tabla Destino | Propósito |
| :--- | :--- | :--- | :--- |
| `clientes.linea_telefonica` [6] | `id_plan` | `ventas.plan` | Definir los beneficios del servicio activo [7]. |
| `ventas.linea_plan` [8] | `id_linea` | `clientes.linea_telefonica` | Historial de migraciones de plan del cliente [8]. |
| `ventas.plan_corporativo` [2] | `id_cliente_corp` | `clientes.cliente_corporativo` | Vincular planes B2B con empresas [2]. |
| `finanzas.factura` [7] | `id_plan` | `ventas.plan` | Determinar la tarifa mensual a cobrar [7]. |

---

## 🛠️ Reglas de Integridad Técnica

1.  **Protección de Catálogo:** Las tablas de configuración (`plan`, `paquete`, `modalidad`, `promocion`) tienen restricciones que impiden su eliminación si existen transacciones activas asociadas en `paquete_adquirido` o `linea_plan` [9, 10].
2.  **Llaves Subrogadas:** Se utiliza el tipo `SERIAL` para las llaves primarias, asegurando que las relaciones se mantengan estables independientemente de cambios en los nombres comerciales de los planes [7, 11].
3.  **Seguridad por Columna (CLS):** Aunque las tablas están relacionadas físicamente, los roles operativos (`employee_role`) tienen denegado el acceso a las columnas de costos (`precio`, `tarifa_mensual`, `valor_beneficio`) para proteger la estrategia comercial [12, 13].

---

## 🔍 Comandos de Verificación
Para auditar las relaciones y restricciones del catálogo de ventas desde `psql`:
```sql
-- Ver quién referencia a la tabla plan
\d ventas.plan

-- Ver las llaves foráneas de la tabla de paquetes adquiridos
\d ventas.paquete_adquirido
````

-----------------------------------------------------------------------------------
# 🔗 Descripción de Relaciones: Esquema `rrhh`

Este documento describe la arquitectura de vínculos del esquema de Recursos Humanos. Debido a la sensibilidad de la información de nómina y datos personales, este esquema opera bajo un principio de **Aislamiento Total** dentro de la base de datos **"Viva"**.

## 🚫 1. Aislamiento Estructural (Sin FK Externas)

Para garantizar la máxima confidencialidad y cumplir con el endurecimiento (*hardening*) del sistema, el esquema `rrhh` ha sido diseñado con las siguientes restricciones de relación:

*   **Independencia de Dominio:** No existen Llaves Foráneas (FK) que vinculen la tabla `employee` con tablas de los esquemas `ventas`, `finanzas` o `clientes`.
*   **Propósito de Seguridad:** Este diseño impide que usuarios con acceso a reportes comerciales puedan realizar cruces de datos (`JOINs`) para extraer información salarial o privada del personal [2, 3].

---

## 👤 2. Relación Lógica con el Sistema (RLS)

Aunque no existen relaciones físicas con otras tablas, el esquema mantiene una **relación funcional 1:1** crítica con el motor de autenticación de PostgreSQL:

*   **Vínculo Lógico:** `rrhh.employee.nombre` ↔ `current_user`.
*   **Mecánica de Seguridad:** Se utiliza esta relación para aplicar las políticas de **Row Level Security (RLS)**. El sistema intercepta las consultas y valida que el usuario que inició sesión solo pueda ver la fila que coincida con su identidad, habilitando un modelo de "Autogestión Segura".

---

## 🛠️ 3. Integridad de Entidad y Unicidad

Al no depender de llaves externas, la integridad del esquema se centra en la validez interna de su única entidad:

| Tabla | Atributo | Tipo de Vínculo | Descripción |
| :--- | :--- | :--- | :--- |
| `employee` | `id` | **Llave Primaria (PK)** | Garantiza la atomicidad de cada registro de trabajador [4]. |
| `employee` | `nombre` | **Restricción UNIQUE** | Asegura que no existan duplicados para el correcto funcionamiento del filtrado por usuario de sesión. |

---

## 🔍 Comandos de Verificación de Integridad

Para auditar que el aislamiento se mantiene y no se han creado dependencias no autorizadas, utilice:

```sql
-- Verificar que no existen llaves foráneas salientes
\d rrhh.employee

-- Confirmar que el administrador de rrhh es el único con control total
\dt rrhh.employee
