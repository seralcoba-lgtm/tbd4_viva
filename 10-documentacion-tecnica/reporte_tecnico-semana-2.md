# Semana 2: Control de acceso y seguridad por objeto en PostgreSQL

## Proyecto: Base de datos `Viva`

Este documento presenta la evidencia técnica correspondiente a la **Semana 2: Control de acceso y seguridad por objeto** del proyecto de seguridad en PostgreSQL.

El objetivo principal de esta semana fue demostrar la aplicación de controles de acceso a nivel de esquemas, tablas, columnas, filas y vistas seguras. Además, se documenta una matriz de privilegios y un script SQL reproducible para evidenciar la configuración aplicada.

---

# 1. Esquemas y privilegios por tabla

## Objetivo

Demostrar que la base de datos `Viva` se encuentra organizada en esquemas separados por área funcional y que los privilegios fueron asignados de forma granular por rol y tabla.

La base de datos se encuentra dividida en los siguientes esquemas:

| Esquema     | Área funcional   | Descripción                                                                   |
| ----------- | ---------------- | ----------------------------------------------------------------------------- |
| `clientes`  | Clientes         | Contiene información de clientes, líneas telefónicas, dispositivos y consumo. |
| `ventas`    | Ventas           | Contiene planes, paquetes, promociones y registros comerciales.               |
| `finanzas`  | Finanzas         | Contiene facturas, recargas, préstamos, pagos y presupuesto.                  |
| `rrhh`      | Recursos Humanos | Contiene información de empleados.                                            |
| `seguridad` | Seguridad        | Contiene tablas relacionadas con asignación de usuarios y control de acceso.  |

---

## Consulta para evidenciar esquemas

```sql
SELECT schema_name AS esquema
FROM information_schema.schemata
WHERE schema_name IN ('clientes', 'ventas', 'finanzas', 'rrhh', 'seguridad')
ORDER BY schema_name;
```

## Evidencia

![Esquemas separados por área](./imagenes/Captura%20de%20pantalla%202026-06-22%20190009.png)

---

## Consulta para evidenciar tablas por esquema

```sql
SELECT 
    schemaname AS esquema,
    tablename AS tabla
FROM pg_tables
WHERE schemaname IN ('clientes', 'ventas', 'finanzas', 'rrhh', 'seguridad')
ORDER BY schemaname, tablename;
```

## Evidencia

![Tablas por esquema](./imagenes/Captura%20de%20pantalla%202026-06-22%20190020.png)

---

## Consulta para evidenciar privilegios por rol y tabla

```sql
SELECT 
    grantee AS rol,
    table_schema AS esquema,
    table_name AS tabla,
    string_agg(privilege_type, ', ' ORDER BY privilege_type) AS privilegios
FROM information_schema.role_table_grants
WHERE table_schema IN ('clientes', 'ventas', 'finanzas', 'rrhh', 'seguridad')
GROUP BY grantee, table_schema, table_name
ORDER BY table_schema, table_name, grantee;
```

## Evidencia

![Matriz de privilegios por rol y tabla](./imagenes/Captura%20de%20pantalla%202026-06-22%20190112.png)

---

## Análisis de privilegios obtenidos

La consulta generó una matriz de privilegios con **87 registros**, donde se observa la asignación granular de permisos por rol, esquema y tabla.

### Esquema `clientes`

El rol `admin_clientes` posee permisos completos sobre tablas como:

* `cliente`
* `cliente_corporativo`
* `consumo`
* `consumo_paquete`
* `dispositivo`
* `linea_telefonica`

Los permisos asignados a `admin_clientes` incluyen:

```text
DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE
```

Esto demuestra que `admin_clientes` administra únicamente el área de clientes.

Otros permisos observados:

| Rol             | Objeto                                   | Permiso            | Interpretación                                        |
| --------------- | ---------------------------------------- | ------------------ | ----------------------------------------------------- |
| `rol_lectura`   | Tablas del esquema `clientes`            | `SELECT`           | Puede consultar, pero no modificar.                   |
| `manager_role`  | `cliente`, `cliente_corporativo`         | `UPDATE`           | Puede actualizar información específica.              |
| `employee_role` | `cliente_corporativo`, `consumo_paquete` | `INSERT`, `UPDATE` | Puede realizar operaciones limitadas.                 |
| `laravel_gui`   | Vistas de clientes                       | `SELECT`           | La interfaz Laravel consulta vistas seguras.          |
| `analyst_role`  | `vw_dispositivos_seguros`                | `SELECT`           | El analista consulta datos protegidos mediante vista. |

---

### Esquema `finanzas`

El rol `admin_finanzas` posee permisos completos sobre tablas como:

* `bolsillo`
* `budget`
* `factura`
* `pago_prestamo`
* `prestamo`
* `recarga`

Otros permisos observados:

| Rol            | Objeto                        | Permiso                                             | Interpretación                        |
| -------------- | ----------------------------- | --------------------------------------------------- | ------------------------------------- |
| `rol_lectura`  | Tablas y vistas financieras   | `SELECT`                                            | Consulta sin modificación.            |
| `manager_role` | `budget`                      | `INSERT`, `UPDATE`                                  | Puede gestionar presupuestos.         |
| `analyst_role` | `pago_prestamo`               | `SELECT`                                            | Puede analizar pagos de préstamos.    |
| `laravel_gui`  | `budget` y vistas financieras | `SELECT`, `INSERT`, `UPDATE`, `DELETE` según objeto | Permisos necesarios para la interfaz. |

---

### Esquema `rrhh`

El rol `admin_rrhh` posee permisos completos sobre la tabla `employee` y vistas relacionadas.

Otros permisos observados:

| Rol             | Objeto                      | Permiso                      | Interpretación                         |
| --------------- | --------------------------- | ---------------------------- | -------------------------------------- |
| `employee_role` | `employee`                  | `SELECT`                     | Permite consulta limitada a empleados. |
| `manager_role`  | `employee`                  | `INSERT`, `SELECT`, `UPDATE` | Permite gestión parcial de RRHH.       |
| `rol_lectura`   | `employee` y vistas         | `SELECT`                     | Acceso de solo lectura.                |
| `laravel_gui`   | `vw_info_publica_empleados` | `SELECT`                     | Consulta desde la interfaz.            |

---

### Esquema `seguridad`

El rol `admin_seguridad` posee permisos completos sobre la tabla `usuario_linea`.

Esta tabla es importante porque relaciona usuarios con líneas telefónicas, lo cual permite aplicar políticas RLS basadas en `CURRENT_USER`.

| Rol               | Objeto          | Permiso            | Interpretación                                         |
| ----------------- | --------------- | ------------------ | ------------------------------------------------------ |
| `admin_seguridad` | `usuario_linea` | Permisos completos | Administra reglas de seguridad y asignación de líneas. |
| `employee_role`   | `usuario_linea` | `SELECT`           | Consulta necesaria para políticas RLS.                 |

---

### Esquema `ventas`

El rol `admin_ventas` posee permisos completos sobre tablas como:

* `bono_promocional`
* `linea_plan`
* `modalidad`
* `paquete`
* `paquete_adquirido`
* `plan`
* `plan_corporativo`
* `promocion`
* `promocion_aplicada`

Otros permisos observados:

| Rol             | Objeto                                      | Permiso  | Interpretación                                   |
| --------------- | ------------------------------------------- | -------- | ------------------------------------------------ |
| `rol_lectura`   | Tablas y vistas de ventas                   | `SELECT` | Consulta sin modificación.                       |
| `manager_role`  | `modalidad`, `paquete`, `plan`, `promocion` | `UPDATE` | Puede modificar objetos comerciales específicos. |
| `employee_role` | `linea_plan`, `promocion_aplicada`          | `SELECT` | Consulta operativa limitada.                     |
| `analyst_role`  | `bono_promocional`                          | `SELECT` | Consulta para análisis comercial.                |
| `laravel_gui`   | Vistas de ventas                            | `SELECT` | Consulta desde la interfaz Laravel/Filament.     |

---

## Conclusión del punto 1

La base de datos `Viva` cumple con el criterio de **esquemas y privilegios por tabla**, ya que los objetos están organizados por área funcional y los permisos fueron asignados de forma granular.

Los roles administrativos tienen permisos completos únicamente sobre su área correspondiente, mientras que los roles funcionales poseen permisos limitados según sus responsabilidades.

---

# 2. Seguridad por columna

## Objetivo

Demostrar que se aplican permisos a nivel de columna para evitar que usuarios no autorizados consulten datos sensibles.

La seguridad por columna permite otorgar permisos únicamente sobre columnas específicas de una tabla, ocultando información sensible como salarios, documentos, direcciones, correos o identificadores personales.

---

## Ejemplo aplicado sobre la tabla `rrhh.employee`

La tabla `rrhh.employee` contiene información de empleados, incluyendo la columna `salario`, considerada sensible.

Estructura de la tabla:

```sql
\d rrhh.employee
```

Columnas principales:

| Columna   | Descripción                | Sensibilidad |
| --------- | -------------------------- | ------------ |
| `id`      | Identificador del empleado | Baja         |
| `nombre`  | Nombre del empleado        | Media        |
| `puesto`  | Cargo o función            | Media        |
| `salario` | Salario del empleado       | Alta         |

---

## Configuración de permisos por columna

Para restringir el acceso al salario, se puede revocar el permiso general sobre la tabla y otorgar acceso solo a columnas permitidas.

```sql
REVOKE SELECT ON rrhh.employee FROM employee_role;

GRANT SELECT (id, nombre, puesto)
ON rrhh.employee
TO employee_role;
```

Con esto, el rol `employee_role` puede consultar:

```sql
SELECT id, nombre, puesto
FROM rrhh.employee;
```

Pero no puede consultar:

```sql
SELECT salario
FROM rrhh.employee;
```

---

## Evidencia de configuración

![Configuración de seguridad por columna](imagenes/semana2_seguridad_columna_grant.png)

---

## Prueba funcional con usuario limitado

Conexión con usuario empleado:

```bash
sudo docker exec -it postgres-viva psql -U empleado_306 -d Viva
```

Consulta permitida:

```sql
SELECT id, nombre, puesto
FROM rrhh.employee;
```

Consulta restringida:

```sql
SELECT salario
FROM rrhh.employee;
```

Resultado esperado:

```text
ERROR: permission denied for table employee
```

o un error de permiso relacionado con la columna restringida.

## Evidencia

![Prueba de restricción por columna](imagenes/semana2_seguridad_columna_prueba.png)

---

## Conclusión del punto 2

La seguridad por columna permite proteger datos sensibles dentro de una tabla sin impedir el acceso completo a la información no sensible.
En este caso, el usuario empleado puede consultar datos básicos, pero no puede acceder a la columna `salario`.

---

# 3. Row Level Security RLS

## Objetivo

Demostrar que la base de datos utiliza **Row Level Security**, también conocida como RLS, para filtrar registros según el usuario conectado.

RLS permite que diferentes usuarios consulten la misma tabla, pero vean únicamente las filas autorizadas para ellos.

---

## Tabla utilizada para la demostración

Se utiliza la tabla:

```text
finanzas.recarga
```

Esta tabla contiene registros de recargas asociados a líneas telefónicas.

También se utiliza la tabla:

```text
seguridad.usuario_linea
```

Esta tabla relaciona usuarios con líneas telefónicas permitidas.

---

## Verificación de políticas RLS

Consulta utilizada:

```sql
SELECT
    schemaname,
    tablename,
    policyname,
    roles,
    cmd,
    qual
FROM pg_policies
WHERE schemaname IN ('clientes', 'ventas', 'finanzas', 'rrhh', 'seguridad')
ORDER BY schemaname, tablename, policyname;
```

## Evidencia

![Políticas RLS configuradas](imagenes/semana2_rls_policies.png)

---

## Política RLS sobre `finanzas.recarga`

La política utilizada permite que un empleado vea únicamente las recargas asociadas a las líneas asignadas a su usuario.

Ejemplo de política:

```sql
CREATE POLICY policy_employee_recarga_por_usuario
ON finanzas.recarga
FOR SELECT
TO employee_role
USING (
    EXISTS (
        SELECT 1
        FROM seguridad.usuario_linea ul
        WHERE ul.usuario = CURRENT_USER
          AND ul.id_linea = recarga.id_linea
    )
);
```

La condición utiliza:

```sql
CURRENT_USER
```

Esto permite que PostgreSQL identifique al usuario conectado y filtre los registros según la relación existente en `seguridad.usuario_linea`.

---

## Verificación de asignación de líneas por usuario

```sql
SELECT *
FROM seguridad.usuario_linea
WHERE usuario IN ('empleado_306', 'empleado_307');
```

## Evidencia

![Asignación de líneas por usuario](imagenes/semana2_usuario_linea.png)

---

## Prueba con `empleado_306`

Conexión:

```bash
sudo docker exec -it postgres-viva psql -U empleado_306 -d Viva
```

Consulta:

```sql
SELECT current_user;

SELECT id_recarga, id_linea, fecha_recarga, monto
FROM finanzas.recarga
ORDER BY id_linea
LIMIT 10;
```

## Evidencia

![RLS con empleado\_306](imagenes/semana2_rls_empleado306.png)

---

## Prueba con `empleado_307`

Conexión:

```bash
sudo docker exec -it postgres-viva psql -U empleado_307 -d Viva
```

Consulta:

```sql
SELECT current_user;

SELECT id_recarga, id_linea, fecha_recarga, monto
FROM finanzas.recarga
ORDER BY id_linea
LIMIT 10;
```

## Evidencia

![RLS con empleado\_307](imagenes/semana2_rls_empleado307.png)

---

## Resultado esperado

Los usuarios `empleado_306` y `empleado_307` consultan la misma tabla `finanzas.recarga`, pero observan registros distintos según las líneas asignadas a cada uno.

Esto demuestra que RLS está funcionando correctamente.

---

## Conclusión del punto 3

La base de datos `Viva` cumple con el criterio de Row Level Security, ya que se habilitó RLS y se crearon políticas funcionales basadas en `CURRENT_USER`.

Esto permite restringir el acceso a filas específicas según el usuario conectado.

---

# 4. Vistas seguras

## Objetivo

Demostrar que se crearon vistas seguras para exponer únicamente datos permitidos, evitando que usuarios no autorizados accedan directamente a las tablas base.

Las vistas seguras permiten mostrar información filtrada, resumida o enmascarada.

---

## Vistas seguras existentes

La base de datos cuenta con varias vistas organizadas por esquema:

| Esquema    | Vista                          | Propósito                                                        |
| ---------- | ------------------------------ | ---------------------------------------------------------------- |
| `clientes` | `vw_analisis_clientes`         | Expone información general para análisis de clientes.            |
| `clientes` | `vw_dispositivos_seguros`      | Muestra dispositivos con datos protegidos como IMEI enmascarado. |
| `finanzas` | `v_recarga_publica`            | Expone información pública de recargas.                          |
| `finanzas` | `vw_recarga_segura`            | Muestra información limitada de recargas.                        |
| `finanzas` | `vw_resumen_facturacion_linea` | Presenta resumen de facturación por línea.                       |
| `rrhh`     | `vw_info_publica_empleados`    | Muestra información pública de empleados sin salario.            |
| `rrhh`     | `vw_perfiles_empleados`        | Expone perfiles básicos de empleados.                            |
| `ventas`   | `vw_planes_vigentes`           | Muestra planes activos o vigentes.                               |
| `ventas`   | `vw_promociones_operativas`    | Muestra promociones operativas.                                  |

---

## Consulta para listar vistas

```sql
SELECT 
    table_schema AS esquema,
    table_name AS vista
FROM information_schema.views
WHERE table_schema IN ('clientes', 'ventas', 'finanzas', 'rrhh')
ORDER BY table_schema, table_name;
```

## Evidencia

![Listado de vistas seguras](imagenes/semana2_vistas_seguras.png)

---

## Ejemplo de vista segura: `clientes.vw_dispositivos_seguros`

Esta vista permite consultar información de dispositivos, pero protege el IMEI mediante una columna enmascarada llamada `imei_protegido`.

Consulta:

```sql
SELECT *
FROM clientes.vw_dispositivos_seguros
LIMIT 5;
```

## Evidencia

![Vista dispositivos seguros](imagenes/semana2_vista_dispositivos_seguros.png)

---

## Prueba de acceso con usuario autorizado a la vista

Conexión con usuario analista:

```bash
sudo docker exec -it postgres-viva psql -U analista_ventas -d Viva
```

Consulta permitida:

```sql
SELECT *
FROM clientes.vw_dispositivos_seguros
LIMIT 5;
```

## Evidencia

![Usuario consulta vista segura](imagenes/semana2_usuario_consulta_vista.png)

---

## Prueba de restricción a la tabla base

El mismo usuario intenta consultar directamente la tabla base:

```sql
SELECT *
FROM clientes.dispositivo
LIMIT 5;
```

Resultado esperado:

```text
ERROR: permission denied for table dispositivo
```

o:

```text
ERROR: permission denied for schema clientes
```

## Evidencia

![Usuario sin acceso directo a tabla base](imagenes/semana2_vista_acceso_directo_denegado.png)

---

## Conclusión del punto 4

Las vistas seguras permiten exponer únicamente datos permitidos y restringir el acceso directo a tablas base.
Esto mejora la seguridad porque los usuarios pueden consultar información autorizada sin acceder a columnas sensibles o datos internos completos.

---

# 5. Script SQL reproducible y matriz de privilegios

## Objetivo

Demostrar que la configuración de seguridad puede reproducirse mediante un script SQL y que la matriz de privilegios está documentada de forma clara.

---

## Script SQL reproducible

Se recomienda guardar el script en la siguiente ruta del repositorio:

```text
scripts/semana2_control_acceso.sql
```

El script debe incluir:

* Creación de esquemas.
* Creación de roles.
* Asignación de permisos por esquema.
* Asignación de permisos por tabla.
* Seguridad por columna.
* Activación de RLS.
* Creación de políticas RLS.
* Creación de vistas seguras.
* GRANT sobre vistas.
* Consultas de verificación.

---

## Estructura sugerida del script

```sql
-- ============================================================
-- SEMANA 2: CONTROL DE ACCESO Y SEGURIDAD POR OBJETO
-- Base de datos: Viva
-- ============================================================

-- 1. Esquemas
CREATE SCHEMA IF NOT EXISTS clientes;
CREATE SCHEMA IF NOT EXISTS ventas;
CREATE SCHEMA IF NOT EXISTS finanzas;
CREATE SCHEMA IF NOT EXISTS rrhh;
CREATE SCHEMA IF NOT EXISTS seguridad;

-- 2. Roles funcionales
CREATE ROLE IF NOT EXISTS rol_lectura;
CREATE ROLE IF NOT EXISTS employee_role;
CREATE ROLE IF NOT EXISTS analyst_role;
CREATE ROLE IF NOT EXISTS manager_role;

-- 3. Roles administrativos por área
CREATE ROLE IF NOT EXISTS admin_clientes;
CREATE ROLE IF NOT EXISTS admin_finanzas;
CREATE ROLE IF NOT EXISTS admin_rrhh;
CREATE ROLE IF NOT EXISTS admin_seguridad;
CREATE ROLE IF NOT EXISTS admin_ventas;

-- 4. Permisos por esquema
GRANT USAGE ON SCHEMA clientes TO rol_lectura, employee_role, analyst_role, manager_role;
GRANT USAGE ON SCHEMA ventas TO rol_lectura, employee_role, analyst_role, manager_role;
GRANT USAGE ON SCHEMA finanzas TO rol_lectura, employee_role, analyst_role, manager_role;
GRANT USAGE ON SCHEMA rrhh TO rol_lectura, employee_role, manager_role;
GRANT USAGE ON SCHEMA seguridad TO employee_role, admin_seguridad;

-- 5. Ejemplo de permisos por tabla
GRANT SELECT ON clientes.cliente TO rol_lectura;
GRANT SELECT ON ventas.plan TO rol_lectura;
GRANT SELECT ON finanzas.factura TO rol_lectura;
GRANT SELECT ON rrhh.employee TO rol_lectura;

-- 6. Seguridad por columna
REVOKE SELECT ON rrhh.employee FROM employee_role;
GRANT SELECT (id, nombre, puesto) ON rrhh.employee TO employee_role;

-- 7. RLS
ALTER TABLE finanzas.recarga ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS policy_employee_recarga_por_usuario ON finanzas.recarga;

CREATE POLICY policy_employee_recarga_por_usuario
ON finanzas.recarga
FOR SELECT
TO employee_role
USING (
    EXISTS (
        SELECT 1
        FROM seguridad.usuario_linea ul
        WHERE ul.usuario = CURRENT_USER
          AND ul.id_linea = recarga.id_linea
    )
);

-- 8. Vista segura
CREATE OR REPLACE VIEW clientes.vw_dispositivos_seguros AS
SELECT
    id_dispositivo,
    id_linea,
    marca,
    modelo,
    CONCAT('****', RIGHT(imei, 4)) AS imei_protegido
FROM clientes.dispositivo;

GRANT SELECT ON clientes.vw_dispositivos_seguros TO analyst_role;
```

---

## Evidencia del script

![Script SQL Semana 2](imagenes/semana2_script_sql.png)

---

## Matriz de privilegios resumida

| Rol               | Esquema principal           | Tipo de permiso              | Descripción                                      |
| ----------------- | --------------------------- | ---------------------------- | ------------------------------------------------ |
| `admin_clientes`  | `clientes`                  | Completo                     | Administra tablas y vistas del área de clientes. |
| `admin_finanzas`  | `finanzas`                  | Completo                     | Administra tablas y vistas financieras.          |
| `admin_rrhh`      | `rrhh`                      | Completo                     | Administra información de recursos humanos.      |
| `admin_seguridad` | `seguridad`                 | Completo                     | Administra objetos de seguridad.                 |
| `admin_ventas`    | `ventas`                    | Completo                     | Administra objetos comerciales y de ventas.      |
| `rol_lectura`     | Varios esquemas             | `SELECT`                     | Permite consulta sin modificación.               |
| `employee_role`   | Varios esquemas             | Limitado                     | Acceso operativo con RLS y restricciones.        |
| `analyst_role`    | Vistas y tablas específicas | `SELECT`                     | Acceso para análisis.                            |
| `manager_role`    | Tablas específicas          | `SELECT`, `INSERT`, `UPDATE` | Gestión parcial según responsabilidad.           |
| `laravel_gui`     | Vistas y tablas autorizadas | Limitado                     | Usuario técnico para Laravel/Filament.           |

---

## Evidencia de matriz documentada

![Matriz documentada de privilegios](imagenes/semana2_matriz_documentada.png)

---

# Checklist Semana 2

| Criterio                                | Estado                        | Evidencia                                     |
| --------------------------------------- | ----------------------------- | --------------------------------------------- |
| Esquemas separados por área             | Aplicado                      | Captura de esquemas.                          |
| Tablas organizadas por esquema          | Aplicado                      | Captura de tablas por esquema.                |
| GRANT granular por rol y tabla          | Aplicado                      | Matriz de 87 privilegios.                     |
| Seguridad por columna                   | Aplicado/Pendiente de captura | Prueba sobre `rrhh.employee`.                 |
| Restricción de columna sensible         | Aplicado/Pendiente de captura | Error al consultar `salario`.                 |
| RLS habilitado                          | Aplicado                      | Consulta a `pg_policies`.                     |
| Política RLS con `CURRENT_USER`         | Aplicado                      | Política sobre `finanzas.recarga`.            |
| Usuarios ven filas distintas            | Aplicado/Pendiente de captura | Prueba con `empleado_306` y `empleado_307`.   |
| Vistas seguras creadas                  | Aplicado                      | Listado de vistas.                            |
| Usuario accede a vista segura           | Aplicado/Pendiente de captura | Consulta a `vw_dispositivos_seguros`.         |
| Usuario sin acceso directo a tabla base | Aplicado/Pendiente de captura | Error al consultar tabla base.                |
| Script SQL reproducible                 | Aplicado/Pendiente de subir   | Archivo `scripts/semana2_control_acceso.sql`. |
| Matriz rol → objeto → permiso           | Aplicado                      | Matriz documentada en este archivo.           |

---

# Estructura recomendada para GitHub

```text
tbd4_viva/
├── 10-documentacion-tecnica/
│   ├── semana_1_hardening.md
│   ├── semana_2_control_acceso.md
│   └── imagenes/
│       ├── semana2_esquemas.png
│       ├── semana2_tablas_por_esquema.png
│       ├── semana2_matriz_privilegios.png
│       ├── semana2_seguridad_columna_grant.png
│       ├── semana2_seguridad_columna_prueba.png
│       ├── semana2_rls_policies.png
│       ├── semana2_usuario_linea.png
│       ├── semana2_rls_empleado306.png
│       ├── semana2_rls_empleado307.png
│       ├── semana2_vistas_seguras.png
│       ├── semana2_vista_dispositivos_seguros.png
│       ├── semana2_usuario_consulta_vista.png
│       ├── semana2_vista_acceso_directo_denegado.png
│       ├── semana2_script_sql.png
│       └── semana2_matriz_documentada.png
└── scripts/
    └── semana2_control_acceso.sql
```

---

# Conclusión general de Semana 2

Durante la Semana 2 se implementaron y documentaron controles de acceso por objeto en la base de datos `Viva`.

La base cuenta con esquemas separados por área funcional, permisos granulares por rol y tabla, seguridad por columna para proteger datos sensibles, políticas RLS para filtrar registros según el usuario conectado y vistas seguras para exponer únicamente información permitida.

Además, se documentó una matriz de privilegios y se propone un script SQL reproducible para validar y reconstruir la configuración de seguridad aplicada.

Estas medidas fortalecen el principio de mínimo privilegio y permiten controlar el acceso a los datos de manera granular.
