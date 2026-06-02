
# 🔗 Cardinalidades y Opcionalidades: Esquema `clientes`

Este documento describe las relaciones lógicas entre las entidades del esquema `clientes` y sus vínculos con los esquemas de `ventas` y `finanzas`. El diseño sigue las reglas de **Integridad Referencial** para asegurar que cada registro de consumo o dispositivo esté correctamente vinculado a un abonado legítimo [1, 2].

## 📌 Definiciones de Relación
*   **Cardinalidad:** Indica el número de instancias de una entidad que pueden asociarse con otra (ej. 1:1, 1:N).
*   **Opcionalidad:** Indica si la existencia de una relación es obligatoria (Mandatoria) o no para que el registro sea válido.

---

## 📊 Matriz de Relaciones del Esquema

### 1. `cliente` ↔ `cliente_corporativo` (1:1)
*   **Cardinalidad:** Un `cliente` puede ser una persona natural o extenderse como una entidad legal.
*   **Opcionalidad:** Es **Opcional**. Solo los clientes del segmento B2B tienen un registro correspondiente en `cliente_corporativo` [3, 4].
*   **Vínculo:** `cliente_corporativo.id_cliente` es tanto Llave Primaria (PK) como Llave Foránea (FK) hacia `cliente.id_cliente`.

### 2. `cliente` ↔ `linea_telefonica` (1:N)
*   **Cardinalidad:** Un `cliente` puede poseer una o varias líneas telefónicas (ej. personal, trabajo).
*   **Opcionalidad:** **Mandatoria para la línea**. No puede existir una línea sin un dueño asignado (`id_cliente` NOT NULL) [5, 6].

### 3. `linea_telefonica` ↔ `dispositivo` (1:N)
*   **Cardinalidad:** Una `linea_telefonica` puede haber sido utilizada en múltiples dispositivos (historial de IMEI), pero un registro de `dispositivo` físico apunta a la línea activa actual [5, 7].
*   **Opcionalidad:** **Mandatoria para el dispositivo**. Todo hardware debe estar vinculado a una línea y a un cliente para ser rastreable.

### 4. `linea_telefonica` ↔ `consumo` (1:N)
*   **Cardinalidad:** Una línea genera múltiples registros de tráfico (Voz, Datos, SMS) a lo largo del tiempo [4, 8].
*   **Opcionalidad:** **Opcional para la línea** (una línea nueva puede tener cero consumos), pero **Mandatoria para el consumo** (todo tráfico debe pertenecer a una línea a través de su `bolsillo`) [4].

### 5. `paquete_adquirido` ↔ `consumo_paquete` (1:N)
*   **Cardinalidad:** Una compra de paquete (`paquete_adquirido`) puede generar múltiples reducciones granulares de saldo conforme el usuario navega o habla [9, 10].
*   **Opcionalidad:** **Mandatoria**. Un registro de `consumo_paquete` no tiene sentido sin una adquisición previa que le dé soporte legal y técnico.

---

## 🗺️ Diagrama Lógico de Cardinalidad (Resumen)

| Entidad Origen | Entidad Destino | Cardinalidad | Opcionalidad (Origen:Destino) |
| :--- | :--- | :--- | :--- |
| `cliente` | `cliente_corporativo` | 1:1 | Opcional : Mandatoria |
| `cliente` | `linea_telefonica` | 1:N | Opcional : Mandatoria |
| `linea_telefonica` | `dispositivo` | 1:N | Opcional : Mandatoria |
| `linea_telefonica` | `linea_plan` | 1:N | Mandatoria : Mandatoria |
| `bolsillo` | `consumo` | 1:N | Opcional : Mandatoria |
| `paquete_adquirido` | `consumo_paquete` | 1:N | Opcional : Mandatoria |

---

## 🛠️ Notas de Integridad de Datos (DAR)
*   **Llaves Subrogadas:** Se utiliza el tipo `SERIAL` para las PKs con el fin de mantener la integridad de identidad sin exponer datos sensibles (como el IMEI o el documento de identidad) en las relaciones [11, 12].
*   **Restricciones UNIQUE:** Las columnas `doc_identidad`, `IMEI` y `numero_telefonico` poseen restricciones de unicidad para evitar colisiones de datos en el almacenamiento físico [11, 13].
*   **Acceso Seguro:** Aunque las relaciones son mandatorias a nivel lógico, el acceso a las columnas de unión (FK) está restringido para el `employee_role` en casos de datos sensibles para cumplir con el **PoLP** [14, 15].

*   
# 🔗 Cardinalidades y Opcionalidades: Esquema `finanzas`

Este documento describe las relaciones lógicas y la integridad referencial del esquema `finanzas`. El diseño garantiza la trazabilidad completa de cada centavo, desde la recarga inicial hasta el pago de deudas y la emisión de facturas legales.

## 📌 Definiciones Aplicadas
*   **Cardinalidad:** El número de registros que se relacionan entre entidades (ej. Una línea puede tener múltiples facturas).
*   **Opcionalidad:** Determina si un registro requiere obligatoriamente de otro para existir (ej. No puede existir un pago sin un préstamo previo).

---

## 📊 Matriz de Relaciones del Esquema

### 1. `linea_telefonica` ↔ `bolsillo` (1:1 / 1:N)
*   **Cardinalidad:** Cada línea telefónica posee un "bolsillo" que centraliza sus saldos (crédito regular y promocional).
*   **Opcionalidad:** **Mandatoria**. Toda línea activa debe tener un registro de saldo asociado para poder operar.
*   **Vínculo:** `bolsillo.id_linea` referencia a `clientes.linea_telefonica`.

### 2. `linea_telefonica` ↔ `factura` (1:N)
*   **Cardinalidad:** Una línea telefónica puede recibir múltiples facturas a lo largo del tiempo (mensualidades, cargos adicionales).
*   **Opcionalidad:** **Opcional para la línea** (una línea nueva puede no tener facturas aún), pero **Mandatoria para la factura**. No se puede emitir un cobro legal sin una línea y un cliente responsable.

### 3. `linea_telefonica` ↔ `recarga` (1:N)
*   **Cardinalidad:** Una línea puede realizar infinitas recargas durante su ciclo de vida.
*   **Opcionalidad:** **Mandatoria para la recarga**. Cada ingreso de dinero debe quedar registrado y vinculado a un número telefónico específico.

### 4. `linea_telefonica` ↔ `prestamo` (1:N)
*   **Cardinalidad:** Una línea puede solicitar diversos préstamos de saldo (usualmente uno a la vez).
*   **Opcionalidad:** **Mandatoria para el préstamo**. El sistema de crédito requiere la identificación de la línea deudora.

### 5. `prestamo` ↔ `pago_prestamo` (1:N)
*   **Cardinalidad:** Un préstamo puede ser cancelado en un solo pago o mediante múltiples abonos parciales.
*   **Opcionalidad:** **Mandatoria**. Un registro de pago es inválido si no referencia a una deuda (ID de préstamo) existente.

---

## 🗺️ Diagrama Lógico de Cardinalidad (Resumen)

| Entidad Origen | Entidad Destino | Cardinalidad | Opcionalidad (Origen:Destino) |
| :--- | :--- | :--- | :--- |
| `linea_telefonica` | `bolsillo` | 1:1 | Mandatoria : Mandatoria |
| `linea_telefonica` | `factura` | 1:N | Opcional : Mandatoria |
| `linea_telefonica` | `recarga` | 1:N | Opcional : Mandatoria |
| `linea_telefonica` | `prestamo` | 1:N | Opcional : Mandatoria |
| `prestamo` | `pago_prestamo` | 1:N | Opcional : Mandatoria |
| `bolsillo` | `consumo` | 1:N | Opcional : Mandatoria |

---

## 🛡️ Reglas de Integridad y Hardening
*   **Integridad de Entidad:** Se utilizan llaves primarias (`PK`) de tipo `SERIAL` para asegurar que cada transacción financiera sea única e irrepetible [3].
*   **Integridad Referencial:** Todas las relaciones están protegidas por llaves foráneas (`FK`) que impiden, por ejemplo, borrar una línea telefónica si tiene facturas pendientes o saldos activos [4].
*   **Inmutabilidad:** Las cardinalidades transaccionales (`recarga`, `pago_prestamo`) están diseñadas para ser de "solo inserción" para roles operativos, asegurando que el historial financiero no sea alterado tras su creación [5, 6].

# 🔗 Cardinalidades y Opcionalidades: Esquema `ventas`

Este documento describe las relaciones lógicas y la integridad referencial del esquema `ventas` en la base de datos **Viva**. El diseño asegura que cada transacción comercial (compras, planes y promociones) esté debidamente sustentada por el catálogo maestro y vinculada a una línea de servicio activa.

## 📌 Conceptos de Diseño
*   **Cardinalidad:** Define cuántas instancias de una entidad se relacionan con otra (ej. 1:1, 1:N).
*   **Opcionalidad:** Determina si un registro requiere obligatoriamente de otro para existir (Mandatoria) o si la relación puede no ocurrir (Opcional).

---

## 📊 Matriz de Relaciones del Esquema

### 1. `plan` ↔ `linea_plan` (1:N)
*   **Cardinalidad:** Un plan comercial puede estar asignado a múltiples registros históricos de cambios de plan en diferentes líneas.
*   **Opcionalidad:** **Mandatoria para el historial**. No puede existir un registro en `linea_plan` sin un `id_plan` válido que le dé sustento.
*   **Vínculo:** `linea_plan.id_plan` (FK) → `ventas.plan.id_plan` (PK).

### 2. `paquete` ↔ `paquete_adquirido` (1:N)
*   **Cardinalidad:** Un paquete del catálogo (ej. "Paquetito 1GB") puede ser adquirido infinitas veces por distintos usuarios.
*   **Opcionalidad:** **Mandatoria para la adquisición**. Un registro de compra es inválido si no referencia a un paquete existente del catálogo.
*   **Vínculo:** `paquete_adquirido.id_paquete` (FK) → `ventas.paquete.id_paquete` (PK).

### 3. `promocion` ↔ `promocion_aplicada` (1:N)
*   **Cardinalidad:** Una regla promocional definida en el catálogo puede aplicarse a múltiples líneas telefónicas durante su vigencia.
*   **Opcionalidad:** **Mandatoria para la aplicación**. No se puede aplicar un beneficio sin una promoción base configurada.
*   **Vínculo:** `promocion_aplicada.id_promocion` (FK) → `ventas.promocion.id_promocion` (PK).

### 4. `promocion_aplicada` ↔ `bono_promocional` (1:N)
*   **Cardinalidad:** Una sola activación de promoción puede generar varios bonos de distintos recursos (ej. un bono de MB y un bono de minutos simultáneamente).
*   **Opcionalidad:** **Mandatoria para el bono**. Un bono no puede existir "huérfano"; requiere el sustento legal de una `promocion_aplicada`.
*   **Vínculo:** `bono_promocional.id_aplicacion` (FK) → `ventas.promocion_aplicada.id_aplicacion` (PK).

### 5. `plan` ↔ `plan_corporativo` (1:1)
*   **Cardinalidad:** Relación de especialización. Un plan puede extenderse para tener características de bolsa compartida para empresas.
*   **Opcionalidad:** **Opcional**. Solo los planes destinados al segmento B2B tendrán un registro correspondiente en `plan_corporativo`.

---

## 🗺️ Diagrama Lógico de Cardinalidad (Resumen)

| Entidad Origen | Entidad Destino | Cardinalidad | Opcionalidad (Origen:Destino) |
| :--- | :--- | :--- | :--- |
| `plan` | `linea_plan` | 1:N | Opcional : Mandatoria |
| `paquete` | `paquete_adquirido` | 1:N | Opcional : Mandatoria |
| `promocion` | `promocion_aplicada` | 1:N | Opcional : Mandatoria |
| `promocion_aplicada` | `bono_promocional` | 1:N | Opcional : Mandatoria |
| `plan` | `plan_corporativo` | 1:1 | Opcional : Mandatoria |
| `linea_telefonica`* | `paquete_adquirido` | 1:N | Opcional : Mandatoria |

*\*Tabla perteneciente al esquema `clientes`.*

---

## 🛠️ Reglas de Integridad de Datos
*   **Llaves Subrogadas:** Todas las relaciones utilizan identificadores numéricos generados por secuencias (`SERIAL`) para garantizar que la integridad referencial no dependa de nombres comerciales que podrían cambiar [1, 2].
*   **Protección de Catálogo:** Las tablas maestras (`plan`, `paquete`, `modalidad`) son de solo lectura para roles operativos, asegurando que las cardinalidades no se vean alteradas por borrados accidentales de productos vigentes.
*   **Persistencia:** La relación entre líneas telefónicas y sus adquisiciones es **mandatoria**, lo que impide borrar una línea si existen paquetes o promociones vinculadas históricamente.

# 🔗 Cardinalidades y Opcionalidades: Esquema `rrhh`

Este documento describe la estructura de relaciones del esquema de Recursos Humanos (`rrhh`). A diferencia de los esquemas comerciales, `rrhh` opera como un silo de información altamente sensible, donde la integridad se centra en la **Identidad de Entidad** y el vínculo con el sistema de autenticación de la base de datos.

## 📌 Conceptos de Diseño
*   **Integridad de Entidad:** Garantiza que cada empleado sea único e irrepetible mediante llaves primarias [1].
*   **Aislamiento:** El esquema no posee llaves foráneas salientes hacia `ventas` o `finanzas` para evitar el cruce no autorizado de datos personales con datos comerciales [2].

---

## 📊 Matriz de Entidades y Vínculos

### 1. Tabla: `rrhh.employee`
Es la entidad maestra del esquema. Su diseño es atómico para facilitar la aplicación de políticas de seguridad dinámicas.

| Atributo | Cardinalidad | Opcionalidad | Descripción |
| :--- | :--- | :--- | :--- |
| `id` (PK) | 1:1 | **Mandatoria** | Identificador único del trabajador (Integridad de Entidad) [3]. |
| `nombre` | 1:1 | **Mandatoria** | Nombre completo; se utiliza como clave de filtrado para RLS. |
| `puesto` | 1:N | **Mandatoria** | Un puesto puede ser ocupado por múltiples empleados. |
| `salario` | 1:1 | Opcional | Información confidencial de compensación. |

---

## 🔐 Relación Lógica con el Sistema (RLS)

Aunque no existe una tabla física de "Usuarios", el esquema `rrhh` mantiene una **relación funcional 1:1** entre el registro de la tabla y el **Rol de Sesión** de PostgreSQL [4, 5].

*   **Vínculo Lógico:** `rrhh.employee.nombre` ↔ `current_user`.
*   **Cardinalidad:** Un registro de empleado corresponde exactamente a un usuario autenticado en la base de datos.
*   **Opcionalidad:** Mandatoria para el acceso. Si un usuario no tiene un registro coincidente en esta tabla, las políticas de **Row Level Security (RLS)** devolverán un conjunto de resultados vacío, garantizando que nadie vea datos ajenos [6, 7].

---

## 🛠️ Notas de Integridad y Hardening
*   **Llaves Primarias:** Se utiliza un identificador numérico (`INTEGER`) para evitar exponer nombres en los índices internos del motor de base de datos [3].
*   **Restricción de Unicidad:** La columna `nombre` debe ser única para asegurar que el filtrado por `current_user` no genere colisiones entre empleados con el mismo nombre.
*   **Inmutabilidad:** No se permiten relaciones opcionales que dejen registros huérfanos; cada entrada en el esquema debe pertenecer a un empleado activo y debidamente identificado [8].
