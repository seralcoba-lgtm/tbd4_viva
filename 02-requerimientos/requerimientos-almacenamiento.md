 
# 💾 Requerimientos de Almacenamiento: Esquema `clientes`

Este documento detalla las especificaciones de almacenamiento, persistencia y estructura de datos para el esquema `clientes` de la base de datos **"Viva"**, ejecutada sobre **PostgreSQL 17** en un entorno de contenedores **Docker** sobre **WSL2** [3, 4].

## 🏗️ Infraestructura de Almacenamiento

### 1. Directorio de Datos (Data Directory)
El corazón de la base de datos se encuentra en la ruta interna estándar del contenedor, donde residen las tablas, índices y archivos de configuración (`postgresql.conf` y `pg_hba.conf`) [5, 6].
*   **Ruta Interna:** `/var/lib/postgresql/data/` [7].

### 2. Persistencia y Volúmenes
Para garantizar que los registros de los clientes no se pierdan al reiniciar o eliminar el contenedor, se requiere el uso de **Volúmenes de Docker** [8].
*   **Configuración:** Se vincula una carpeta del host (WSL2/Windows) con el directorio interno de Postgres para asegurar la durabilidad de los datos [9].

---

## 📊 Estructura Lógica y Tipos de Datos

El esquema consta de **6 tablas** diseñadas para soportar desde pequeñas cargas hasta terabytes de información, optimizadas mediante el uso de llaves subrogadas (`SERIAL`) [10, 11].

| Tabla | Tipo de Almacenamiento Principal | Descripción de Columnas Clave |
| :--- | :--- | :--- |
| `cliente` | Datos Maestros (PII) | `id_cliente` (SERIAL), `nombre`, `apellidos`, `doc_identidad` (UNIQUE) [2]. |
| `cliente_corporativo` | Extensión B2B | `id_cliente` (FK), `razon_social`, `nit` (UNIQUE), `contacto_principal` [12]. |
| `dispositivo` | Inventario Hardware | `id_dispositivo` (SERIAL), `imei` (UNIQUE), `marca`, `modelo` [13]. |
| `linea_telefonica` | Transaccional/Estado | `id_linea` (SERIAL), `numero_telefonico` (UNIQUE), `estado` [14]. |
| `consumo` | Historial de Tráfico | `id_consumo` (SERIAL), `fecha_consumo`, `minutos_usados`, `datos_mb_usados` [15]. |
| `consumo_paquete` | Detalle Granular | `id_consumo` (SERIAL), `cantidad_aplicada`, `consumo_generado` [16]. |

---

## 🔑 Integridad y Llaves de Almacenamiento

### 1. Llaves Primarias (PK)
Todas las tablas utilizan el tipo de dato `SERIAL` o `INTEGER` para generar identificadores únicos automáticos, lo que garantiza la **Integridad de Entidad** sin exponer datos de negocio en los índices físicos [10, 17].

### 2. Llaves Foráneas (FK) y Relaciones
El almacenamiento está optimizado mediante relaciones que vinculan los esquemas para evitar la redundancia [18, 19].
*   **Dependencia Central:** La tabla `linea_telefonica` actúa como el eje, referenciando a `clientes.cliente`, `ventas.modalidad` y `ventas.plan` [14].
*   **Consumo:** La tabla `consumo` vincula el tráfico con `finanzas.bolsillo` y `ventas.paquete_adquirido` [15].

### 3. Restricciones de Almacenamiento (Constraints)
*   **UNIQUE:** Aplicado en `doc_identidad`, `imei` y `numero_telefonico` para prevenir duplicidad de registros sensibles [2, 13, 14].
*   **NOT NULL:** Obligatorio en llaves primarias y campos de identidad para asegurar la consistencia del DAR (Data At Rest) [20, 21].

---

## ⚙️ Parámetros de Configuración Críticos

Para optimizar el almacenamiento y la seguridad en el entorno Docker, se han ajustado los siguientes parámetros en `postgresql.conf` [22, 23]:
*   **`listen_addresses`**: Configurado en `'localhost'` para restringir el acceso a la red local del host [24, 25].
*   **Propiedad del Esquema**: El esquema pertenece al rol `admin_clientes`, delegando la gestión de almacenamiento fuera del superusuario `postgres` [1, 26].

---

## 🔍 Verificación de Almacenamiento
Para auditar la estructura física desde la consola `psql`, utilice:
```sql
-- Listar tablas y dueños del esquema clientes
\dt clientes.*

-- Ver detalle técnico de columnas y tipos de una tabla
\d clientes.cliente
``` [2, 27, 28]
```

# 💾 Requerimientos de Almacenamiento: Esquema `finanzas`

Este documento especifica los requerimientos técnicos de almacenamiento, persistencia e integridad física para el esquema `finanzas`. El sistema opera sobre **PostgreSQL 17** utilizando contenedores **Docker** en un entorno **WSL2** [1, 2].

## 🏗️ Infraestructura y Directorio de Datos

### 1. Ubicación del Corazón de Datos
El directorio principal donde PostgreSQL almacena las tablas, índices y archivos de configuración del esquema financiero reside en la ruta interna del contenedor [3, 4]:
*   **Data Directory:** `/var/lib/postgresql/data/` [5].

### 2. Persistencia Mediante Volúmenes
Para garantizar que los registros financieros (facturas, recargas y préstamos) no se eliminen si se borra el contenedor, es mandatorio el uso de **Volúmenes de Docker** [6, 7].
*   **Configuración:** Se vincula un directorio persistente del host con el `data_directory` de Postgres para asegurar la durabilidad de los datos ante reinicios o actualizaciones del motor [6, 8].

---

## 📊 Estructura Lógica de Almacenamiento

El esquema se compone de **6 tablas** optimizadas para la integridad transaccional y el ahorro de espacio mediante tipos de datos precisos como `NUMERIC` y `DECIMAL` [9, 10].

| Tabla | Tipo de Almacenamiento | Columnas Clave de Almacenamiento |
| :--- | :--- | :--- |
| `bolsillo` | Saldos y Recursos | `id_bolsillo` (PK), `credito_regular`, `saldo` (DECIMAL) [10]. |
| `factura` | Documentos Fiscales | `id_factura` (PK), `monto_base` (DECIMAL), `ci_nit` [11]. |
| `recarga` | Historial de Ingresos | `id_recarga` (PK), `monto`, `salario_resultante` [10]. |
| `prestamo` | Control de Deuda | `id_prestamo` (PK), `monto_prestado`, `monto_total_pagar` [12]. |
| `pago_prestamo` | Amortizaciones | `id_pago_prestamo` (PK), `monto_pagado`, `comprobante` [13]. |
| `budget` | Presupuestos | `sales`, `expenses` (NUMERIC), `notes` (TEXT) [9, 14]. |

---

## 🔐 Endurecimiento del Almacenamiento (Hardening)

### 1. Propiedad de Objetos
Para cumplir con el aislamiento de funciones, la propiedad de todas las tablas financieras ha sido transferida de `postgres` al rol administrativo del área [1, 15]:
*   **Owner:** `admin_finanzas` [16].

### 2. Inmutabilidad de Registros Transaccionales
Como medida de seguridad física contra el fraude, se ha diseñado el almacenamiento para ser **incremental e inmutable** en las tablas de `recarga` y `pago_prestamo`, prohibiendo privilegios de `DELETE` o `UPDATE` sobre los registros históricos para los roles operativos [17-19].

### 3. Integridad Referencial
El almacenamiento está vinculado mediante llaves foráneas (`FK`) para evitar la redundancia y asegurar la consistencia entre esquemas [20, 21].
*   Las facturas y bolsillos dependen físicamente de la existencia de una `id_linea` en el esquema de clientes [11, 22].

---

## 🔍 Comandos de Verificación de Estructura
Para auditar el estado del almacenamiento desde la terminal de `psql`, ejecute [23, 24]:

```sql
-- Verificar el dueño y tamaño de las tablas financieras
\dt+ finanzas.*

-- Confirmar la ruta física del directorio de datos
SHOW data_directory;

-- Verificar restricciones de llaves foráneas e índices
\d finanzas.factura

```

# 💾 Requerimientos de Almacenamiento: Esquema `ventas`

Este documento describe las especificaciones técnicas de almacenamiento, persistencia e integridad física para el esquema `ventas`. El sistema opera sobre **PostgreSQL 17** utilizando contenedores **Docker** en un entorno **WSL2** [4-6].

## 🏗️ Infraestructura y Persistencia

### 1. Directorio de Datos (Data Directory)
PostgreSQL almacena físicamente todos los objetos del esquema `ventas` (tablas, índices y metadatos) en la ruta interna del contenedor [7-9]:
*   **Ruta:** `/var/lib/postgresql/data/`.

### 2. Persistencia Mediante Volúmenes
Para evitar la pérdida de los catálogos comerciales y registros de adquisiciones al eliminar o reiniciar el contenedor, es mandatorio el uso de **Volúmenes de Docker** [10, 11]. 
*   **Configuración:** Se debe vincular una carpeta del host con el directorio de datos interno para garantizar que la información sea duradera y sobreviva al ciclo de vida del contenedor [11].

---

## 📊 Estructura Lógica de Almacenamiento

El esquema se compone de **9 tablas** optimizadas para el rendimiento y la integridad referencial, utilizando llaves subrogadas (`SERIAL`) para minimizar el tamaño de los índices [2, 3, 12].

| Tabla | Tipo de Almacenamiento | Columnas Clave |
| :--- | :--- | :--- |
| `plan` | Catálogo Maestro | `id_plan` (PK), `tarifa_mensual` (NUMERIC), `activo`. |
| `paquete` | Catálogo Maestro | `id_paquete` (PK), `precio` (NUMERIC), `vigencia_dias`. |
| `modalidad` | Catálogo Maestro | `id_modalidad` (PK), `nombre` (VARCHAR). |
| `promocion` | Reglas de Negocio | `id_promocion` (PK), `valor_beneficio` (NUMERIC). |
| `paquete_adquirido` | Transaccional | `id_adquisicion` (PK), `saldo_restante_datos` (NUMERIC). |
| `linea_plan` | Historial | `id_linea_plan` (PK), `fecha_inicio` (DATE). |
| `promocion_aplicada` | Transaccional | `id_aplicacion` (PK), `fecha_expiracion`. |
| `bono_promocional` | Transaccional | `id_bono` (PK), `cantidad` (NUMERIC). |
| `plan_corporativo` | Extensión B2B | `id_plan` (PK/FK), `cupo_compartido` (NUMERIC). |

---

## 🔑 Integridad y Llaves de Almacenamiento

### 1. Llaves Primarias (PK)
Todas las tablas utilizan `SERIAL` o `INTEGER` para garantizar la **Integridad de Entidad**, lo que permite una indexación eficiente basada en números enteros en lugar de cadenas de texto [13-21].

### 2. Integridad Referencial (FK)
El almacenamiento está vinculado físicamente entre esquemas para asegurar la consistencia del DAR (*Data At Rest*) [14, 22, 23]:
*   `linea_plan` y `paquete_adquirido` dependen de la existencia de una `id_linea` en el esquema de **clientes**.
*   `plan_corporativo` referencia directamente a `clientes.cliente_corporativo`.

---

## 🔐 Hardening del Almacenamiento

### 1. Propiedad (Ownership)
Como parte de la estrategia de **Mínimo Privilegio (PoLP)**, la propiedad de todos los objetos ha sido transferida del usuario `postgres` al rol administrativo correspondiente [24-26]:
*   **Owner:** `admin_ventas` (Rol con atributo `NOLOGIN`) [3, 4, 27].

### 2. Restricción de Esquema Público
Se ha revocado el permiso `CREATE` en el esquema `public` para obligar a que cualquier nueva tabla comercial se almacene exclusivamente bajo el esquema `ventas` debidamente autorizado [28-30].

---

## 🔍 Comandos de Verificación
Para auditar la estructura física y la propiedad desde la terminal de `psql`, utilice [31-33]:

```sql
-- Verificar tablas y sus dueños en el esquema ventas
\dt ventas.*

-- Consultar el tamaño físico de las tablas (en bytes)
SELECT relname, pg_size_pretty(pg_total_relation_size(relid)) 
FROM pg_catalog.pg_statio_user_tables 
WHERE schemaname = 'ventas';

-- Ver detalles técnicos de una tabla específica
\d ventas.plan
```



# 💾 Requerimientos de Almacenamiento: Esquema `rrhh`

Este documento describe las especificaciones técnicas de almacenamiento, persistencia e integridad física para el esquema de Recursos Humanos (`rrhh`) en la base de datos **"Viva"** [1]. El sistema opera sobre **PostgreSQL 17** utilizando contenedores **Docker** en un entorno **WSL2** [2].

## 🏗️ Infraestructura y Persistencia

### 1. Directorio de Datos (Data Directory)
PostgreSQL almacena físicamente todos los objetos del esquema `rrhh` (tablas, índices y archivos de configuración) en la ruta interna estándar del contenedor [3].
*   **Ruta Interna:** `/var/lib/postgresql/data/` [4, 5].

### 2. Persistencia Mediante Volúmenes
Para garantizar que los registros de los empleados y sus datos salariales no se eliminen si se borra o reinicia el contenedor, es mandatorio el uso de **Volúmenes de Docker** [6].
*   **Configuración:** Se debe vincular una carpeta persistente del host (Windows/WSL2) con el `data_directory` interno para asegurar la durabilidad de los registros históricos [6, 7].

---

## 📊 Estructura Lógica de Almacenamiento

El esquema se compone actualmente de **1 tabla maestra** diseñada para el aislamiento total de información sensible de nómina [8, 9].

| Tabla | Tipo de Almacenamiento | Columnas Clave de Almacenamiento |
| :--- | :--- | :--- |
| `employee` | Datos de Personal y Nómina | `id` (PK), `nombre` (TEXT), `puesto` (TEXT), `salario` (NUMERIC) [10]. |

### Detalles Técnicos de Almacenamiento:
*   **`id`**: Almacenado como `INTEGER` con una secuencia automática (`SERIAL`) para garantizar identificadores únicos sin exponer datos de negocio [10].
*   **`nombre` y `puesto`**: Utilizan el tipo `TEXT` para optimizar el almacenamiento de cadenas de longitud variable sin desperdiciar espacio físico [10].
*   **`salario`**: Utiliza el tipo `NUMERIC` para garantizar la precisión decimal necesaria en transacciones financieras y cálculos de nómina [10].

---

## 🔐 Endurecimiento del Almacenamiento (Hardening)

### 1. Propiedad y Aislamiento (Ownership)
La propiedad de la tabla de empleados se ha transferido del superusuario `postgres` al rol administrativo del área para delegar la gestión del almacenamiento de forma segura [9, 11].
*   **Owner:** `admin_rrhh` (Rol con atributo `NOLOGIN`) [12, 13].

### 2. Seguridad en Reposo y Acceso Granular
El almacenamiento está protegido mediante políticas de **Seguridad a Nivel de Fila (RLS)** y **Seguridad a Nivel de Columna (CLS)** para que los registros solo sean accesibles por usuarios autorizados bajo el Principio de Mínimo Privilegio (PoLP) [14-16].

---

## 🔍 Comandos de Verificación
Para auditar la estructura física y la propiedad del almacenamiento desde la consola `psql`, utilice:

```sql
-- Verificar el dueño y la existencia de la tabla en rrhh
\dt rrhh.* [17]

-- Ver detalle técnico de columnas y tipos de datos
\d rrhh.employee [10]

-- Consultar la ruta física confirmada del directorio de datos
SHOW data_directory; [18]
```
