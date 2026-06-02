
# 🛡️ Requerimientos de Seguridad: Esquema `clientes`

Este documento describe la estrategia de endurecimiento (*hardening*) y los controles de acceso técnico implementados para proteger la integridad y confidencialidad de los datos de los abonados en la base de datos **"Viva"**.

## 🏛️ 1. Arquitectura de Control de Acceso

Siguiendo el **Principio de Mínimo Privilegio (PoLP)**, el acceso se gestiona mediante roles grupales con el atributo `NOLOGIN` (Cannot login), actuando como plantillas de permisos heredables [1-4].

*   **Dueño del Esquema:** `admin_clientes` (Rol administrativo responsable de la gestión de objetos) [5-7].
*   **Aislamiento:** Se ha revocado el acceso al esquema `public` para obligar a los usuarios a operar exclusivamente en sus áreas autorizadas [8-11].

---

## 🔐 2. Seguridad a Nivel de Columna (CLS)

Se aplica **Seguridad Quirúrgica** en tablas con alta concentración de datos **PII** e información financiera sensible. El acceso total se revoca inicialmente para luego otorgar permisos explícitos solo en columnas no críticas [12-15].

### 📋 Implementación Técnica (`employee_role`)

Para el personal operativo, se restringen identificadores legales y costos para prevenir el robo de identidad y fraudes [16-18]:

| Tabla | Columnas Protegidas (Ocultas) | Justificación |
| :--- | :--- | :--- |
| `cliente` | `doc_identidad`, `email` | Protección de Datos PII [13, 16, 19]. |
| `cliente_corporativo` | `nit`, `contacto_principal` | Confidencialidad estratégica B2B [16]. |
| `dispositivo` | `imei` | Identificador único de hardware sensible [13, 18, 20]. |
| `consumo` | `costo_asociado` | Prevención de manipulación de saldos [13, 20, 21]. |

---

## 👁️ 3. Vistas Seguras (Enmascaramiento)

Para el rol `analyst_role`, se utilizan **Vistas Seguras** en lugar de CLS directo. Esto permite que las herramientas de Business Intelligence realicen `SELECT *` sin fallos de permiso, visualizando datos anonimizados [22-25].

*   **Ejemplo (`vw_dispositivos_seguros`):** El analista visualiza el IMEI enmascarado (ej. `****-****-1234`) para análisis de tendencias sin exponer el dato real [23, 24].

---

## 🛡️ 4. Seguridad a Nivel de Fila (RLS)

Se habilita **RLS** para garantizar que los datos sean filtrados dinámicamente según la identidad del usuario en sesión [26-28].

*   **Habilitación:** `ALTER TABLE clientes.cliente ENABLE ROW LEVEL SECURITY;` [29].
*   **Política:** En tablas transaccionales, el acceso se limita a que los usuarios solo visualicen registros vinculados a su propia gestión o sucursal [2, 29, 30].

---

## 🔍 5. Auditoría y Verificación

Para auditar el estado de la seguridad, se utilizan comandos de diagnóstico de PostgreSQL [31-33]:

```sql
-- 1. Verificar privilegios por columna (ACL)
\dp clientes.cliente;

-- 2. Realizar la "Prueba de Fuego" (Personificación)
SET ROLE employee_role;
SELECT doc_identidad FROM clientes.cliente; -- Debe fallar (Permiso Denegado)
SELECT nombre FROM clientes.cliente;        -- Debe funcionar
RESET ROLE;
```

# 💰 Requerimientos de Seguridad: Esquema `finanzas`

Este documento detalla los controles de seguridad y endurecimiento (*hardening*) aplicados al esquema `finanzas`. El objetivo primordial es prevenir el fraude financiero, asegurar la inmutabilidad de los registros de pago y proteger la información presupuestaria estratégica [3, 4].

## 🏛️ 1. Arquitectura de Control de Acceso (PoLP)

Siguiendo el **Principio de Mínimo Privilegio (PoLP)**, el esquema es gestionado por un rol administrativo estructural y operado por roles de negocio con el atributo `NOLOGIN` [5, 6].

*   **Dueño del Esquema:** `admin_finanzas` (Responsable de la integridad de los objetos) [7, 8].
*   **Aislamiento:** Se ha revocado el acceso al esquema `public` para evitar que usuarios no autorizados interactúen con tablas financieras [1, 9].
*   **Acceso Inicial:** Cualquier rol requiere el permiso `USAGE` sobre el esquema `finanzas` antes de realizar consultas [10, 11].

---

## 🔐 2. Seguridad a Nivel de Columna (CLS)

Se aplica **Seguridad Quirúrgica** para ocultar saldos reales y estados crediticios a roles que solo realizan tareas operativas de registro [12, 13].

### 📋 Restricciones para `employee_role`
Para evitar la manipulación o filtración de capital acumulado, se aplican las siguientes restricciones [14]:

| Tabla | Columnas Protegidas (Ocultas) | Justificación de Seguridad |
| :--- | :--- | :--- |
| `bolsillo` | `credito_regular`, `credito_promo`, `saldo` | Evitar visualización de fondos totales por personal no contable [14]. |
| `recarga` | `salario_resultante` | Ocultar el balance final tras la operación [14]. |
| `budget` | **Acceso Denegado Total** | Información estratégica confidencial solo para gerencia [15, 16]. |

---

## 🛡️ 3. Seguridad a Nivel de Fila (RLS)

Se implementan políticas dinámicas para que los empleados solo tengan visibilidad sobre sus propias gestiones, reduciendo la exposición masiva de datos [17, 18].

*   **Tabla `factura`:** Se habilita RLS para filtrar registros de modo que un vendedor solo vea las facturas emitidas bajo su código (`USING (vendedor_id = current_user)`) [18, 19].
*   **Activación:** `ALTER TABLE finanzas.factura ENABLE ROW LEVEL SECURITY;` [18, 20].

---

## 🧱 4. Integridad Transaccional e Inmutabilidad

Para prevenir el fraude mediante la alteración de deudas o la eliminación de evidencia de ingresos, se aplican restricciones de comando [3, 21]:

*   **Restricción de Borrado:** Se revoca el permiso `DELETE` y `TRUNCATE` en todas las tablas para roles de negocio; solo el dueño o el superusuario pueden depurar registros [3, 16].
*   **Inmutabilidad de Pagos:** En las tablas `pago_prestamo` y `recarga`, el `employee_role` solo posee permisos de `INSERT` y `SELECT`, prohibiendo el uso de `UPDATE` sobre montos ya registrados [22, 23].

---

## 👁️ 5. Vistas Seguras para Análisis (BI)

Para el `analyst_role`, se utilizan **Vistas Seguras** que permiten el uso de `SELECT *` por herramientas de reporte sin exponer datos crudos sensibles [24, 25].
*   **Ejemplo:** Vistas que consolidan ingresos por zona sin mostrar el `ci_nit` completo de los clientes facturados [26, 27].

---

## 🔍 6. Verificación de Hardening

La efectividad de estos requerimientos se audita periódicamente mediante la "Prueba de Fuego" [28, 29]:

```sql
-- Simular sesión de empleado operativo
SET ROLE employee_role;

-- 1. Verificar bloqueo de Budget (Debe dar error de permiso)
SELECT * FROM finanzas.budget; 

-- 2. Verificar CLS en Bolsillo (Debe fallar si se incluye el saldo)
SELECT saldo FROM finanzas.bolsillo; 

-- 3. Verificar inmutabilidad (Debe denegar el borrado)
DELETE FROM finanzas.recarga WHERE id_recarga = 1;

RESET ROLE;
```

# 🛡️ Requerimientos de Seguridad: Esquema `ventas`

Este documento describe los controles de acceso y las medidas de endurecimiento (*hardening*) implementadas para proteger la integridad del catálogo comercial y la confidencialidad de los precios estratégicos en la base de datos **"Viva"**.

## 🏛️ 1. Arquitectura de Control de Acceso (PoLP)

La seguridad se gestiona mediante una estructura jerárquica de roles con el atributo `NOLOGIN` (**Cannot login**), lo que reduce la superficie de ataque al impedir conexiones directas con cuentas estructurales [3, 4].

*   **Dueño del Esquema:** `admin_ventas` (Responsable de la creación y mantenimiento de objetos) [5, 6].
*   **Aislamiento de Dominio:** Se ha revocado el acceso al esquema `public` para obligar a los roles a operar exclusivamente en sus áreas autorizadas [7-9].
*   **Acceso Inicial:** Para interactuar con cualquier tabla, los roles requieren primero el permiso de navegación `USAGE` sobre el esquema `ventas` [10, 11].

---

## 🔐 2. Seguridad a Nivel de Columna (CLS)

Se aplica **Seguridad Quirúrgica** en las tablas que contienen precios y beneficios para evitar filtraciones de información comercial sensible a roles operativos que no necesitan conocer los costos base [12, 13].

### 📋 Implementación para `employee_role`
Para el personal operativo, el acceso se restringe mediante la revocación del `SELECT` total y la concesión de permisos solo en columnas no críticas [14, 15].

| Tabla | Columnas Protegidas (Ocultas) | Justificación de Seguridad |
| :--- | :--- | :--- |
| `paquete` | `precio` | Evitar negociaciones no autorizadas de bolsas de recursos [16]. |
| `plan` | `tarifa_mensual` | Confidencialidad de la estructura de costos de planes tarifarios [17]. |
| `paquete_adquirido`| `saldo_inicial`, `saldo_inicial_min` | El empleado solo debe ver el saldo restante para soporte [17, 18]. |
| `promocion` | `valor_beneficio` | Evitar la manipulación de beneficios monetarios directos [17]. |

---

## 🛡️ 3. Seguridad a Nivel de Fila (RLS)

Se habilita **RLS** para garantizar que los datos transaccionales se filtren dinámicamente según la identidad del usuario conectado [19, 20].

*   **Política de Gestión:** En tablas como `paquete_adquirido` o `promocion_aplicada`, los usuarios solo visualizan los registros vinculados a su propia gestión o área de ventas [21, 22].
*   **Comando de Activación:** `ALTER TABLE ventas.paquete_adquirido ENABLE ROW LEVEL SECURITY;` [20, 23].

---

## 👁️ 4. Vistas Seguras para Análisis (BI)

Para el `analyst_role`, se utilizan **Vistas Seguras** en lugar de CLS directo. Esto permite que las herramientas de reporte realicen `SELECT *` sin fallos de permiso, visualizando datos comerciales anonimizados o enmascarados [24-26].

---

## 🔍 5. Verificación y Auditoría

La efectividad de estas políticas se valida mediante la **"Prueba de Fuego"** (personificación de roles) para confirmar que el sistema bloquea accesos no autorizados [27-29].

```sql
-- 1. Verificar privilegios por columna (ACL)
\dp ventas.paquete;

-- 2. Validar restricción de empleado operativo
SET ROLE employee_role;
SELECT precio FROM ventas.paquete; -- Resultado: ERROR de Permiso Denegado [30].
SELECT nombre_paquete FROM ventas.paquete; -- Resultado: Éxito (Columna permitida).
RESET ROLE;
```

# 🛡️ Requerimientos de Seguridad: Esquema `rrhh`

Este documento describe la estrategia de **Defensa en Profundidad** y el endurecimiento (*hardening*) aplicado al esquema de Recursos Humanos. Debido a la sensibilidad de la nómina y los datos de empleados, este esquema posee el nivel más alto de restricción en la base de datos **"Viva"**.

## 🏛️ 1. Arquitectura de Control de Acceso (PoLP)

El acceso se gestiona bajo el **Principio de Mínimo Privilegio (PoLP)**, aislando los datos de personal del resto de la operación comercial y financiera [3, 4].

*   **Dueño del Esquema:** `admin_rrhh` (Rol administrativo con atributo `NOLOGIN` para evitar accesos directos estructurales) [5, 6].
*   **Aislamiento Total:** El esquema `rrhh` es invisible por defecto para roles como `analyst_role` y `employee_role` en tablas ajenas, evitando el cruce de datos comerciales con información privada [3, 4].
*   **Gestión de Identidades:** Se utilizan roles grupales con `NOLOGIN` como plantillas de permisos que heredan a los usuarios reales con `LOGIN` [7].

---

## 🔐 2. Seguridad a Nivel de Columna (CLS)

Se aplica una "Seguridad Quirúrgica" sobre la tabla `employee` para ocultar la remuneración económica a roles que solo requieren ver la estructura organizacional [1].

### 📋 Implementación para `employee_role`
Para el personal operativo, se revoca el acceso total a la tabla y se otorga permiso selectivo solo en columnas no financieras [1, 8].

| Tabla | Columnas Protegidas (Ocultas) | Justificación de Seguridad |
| :--- | :--- | :--- |
| `employee` | `salario` | Protección de confidencialidad salarial y datos financieros personales [1, 2]. |

> **Nota Técnica:** Cualquier intento de realizar `SELECT *` por un usuario restringido fallará con un error de "Permiso Denegado", obligándolo a listar solo los campos permitidos (`id`, `nombre`, `puesto`) [8].

---

## 🛡️ 3. Seguridad a Nivel de Fila (RLS) - Self-Service

Se implementa **Row Level Security (RLS)** para habilitar un modelo de "Autogestión", donde un empleado solo puede visualizar su propia fila de información personal [2, 9].

*   **Política Aplicada:**
    ```sql
    ALTER TABLE rrhh.employee ENABLE ROW LEVEL SECURITY;

    CREATE POLICY policy_employee_self_service ON rrhh.employee
        FOR SELECT TO employee_role
        USING (nombre = current_user);
    ```
*   **Funcionamiento:** La base de datos intercepta la consulta y añade automáticamente un filtro invisible basado en la identidad de la sesión (`current_user`), garantizando que nadie vea datos de sus colegas [10, 11].

---

## 🔍 4. Verificación de Hardening (Prueba de Fuego)

Para auditar la efectividad de estos requerimientos, se realiza la simulación de personificación [12]:

```sql
-- 1. Simular sesión de un empleado
SET ROLE employee_role;

-- 2. Validar bloqueo de CLS (Debe fallar al intentar ver salario)
SELECT * FROM rrhh.employee; 
-- Resultado esperado: ERROR: permission denied for table employee

-- 3. Validar filtro de RLS (Solo debe devolver el registro propio)
SELECT id, nombre, puesto FROM rrhh.employee;

RESET ROLE;
```
