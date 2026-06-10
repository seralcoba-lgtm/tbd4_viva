
# TG4 - Seguridad en Base de Datos PostgreSQL

## Proyecto de Hardening y Seguridad en PostgreSQL

**Base de datos:** `Viva`
**Motor:** PostgreSQL 17
**Entorno:** Docker
**Contenedor:** `postgres17-recuperado`
**Objetivo:** Implementar controles de seguridad en PostgreSQL por capas, aplicando hardening inicial, control de acceso, seguridad por objeto, auditoría, monitoreo, backup y recuperación.

---

# 1. Introducción

Este proyecto implementa una solución integral de seguridad sobre una base de datos PostgreSQL orientada a una empresa de telecomunicaciones. La base de datos se encuentra dividida en diferentes esquemas funcionales:

* `clientes`
* `ventas`
* `finanzas`
* `rrhh`

La seguridad se aplicó mediante:

* Configuración segura de acceso.
* Autenticación con `scram-sha-256`.
* Control de conexiones mediante `listen_addresses` y `pg_hba.conf`.
* Creación de roles por responsabilidad.
* Restricción de permisos por esquema, tabla y vista.
* Seguridad a nivel de filas con RLS.
* Vistas seguras para proteger columnas sensibles.
* Auditoría de operaciones.
* Monitoreo de consultas y sesiones.
* Backup y recuperación de la base de datos.

---

# 2. Estructura del proyecto

```text
tg4-seguridad-postgresql/
│
├── README.md
├── SEGURIDAD.md
│
├── scripts/
│   ├── semana1_hardening.sql
│   ├── semana2_control_acceso.sql
│   ├── semana3_auditoria_monitoreo.sql
│   ├── semana4_backup_restore.sql
│   └── setup_seguridad.sql
│
├── evidencias/
│   ├── semana1/
│   ├── semana2/
│   ├── semana3/
│   └── semana4/
│
├── backups/
│   ├── viva_backup.sql
│   └── viva_backup.dump
│
└── docs/
    ├── matriz_roles_privilegios.md
    ├── politica_auditoria.md
    └── politica_backup_recuperacion.md
```

---

# 3. Comandos básicos para ejecutar PostgreSQL en Docker

## 3.1 Ingresar al contenedor

```bash
docker exec -it postgres17-recuperado bash
```

## 3.2 Ingresar a PostgreSQL

```bash
docker exec -it postgres17-recuperado psql -U postgres -d Viva
```

## 3.3 Ejecutar un script SQL

```bash
docker exec -i postgres17-recuperado psql -U postgres -d Viva < scripts/setup_seguridad.sql
```

## 3.4 Salir de PostgreSQL

```sql
\q
```

---

# SEMANA 1: Fundamentos y Hardening Inicial

## 4. Objetivo de la Semana 1

Aplicar configuraciones iniciales de seguridad en PostgreSQL para reducir la exposición de la base de datos, controlar conexiones, fortalecer la autenticación y crear roles base.

---

## 4.1 Archivos principales de configuración

PostgreSQL utiliza dos archivos importantes para la seguridad inicial:

| Archivo           | Función                                                                        |
| ----------------- | ------------------------------------------------------------------------------ |
| `postgresql.conf` | Configura el comportamiento general del servidor                               |
| `pg_hba.conf`     | Controla quién puede conectarse, desde dónde y con qué método de autenticación |

Para consultar su ubicación:

```sql
SHOW config_file;
SHOW hba_file;
SHOW data_directory;
```

---

## 4.2 Configuración de `listen_addresses`

El parámetro `listen_addresses` define en qué direcciones IP PostgreSQL acepta conexiones.

Ejemplo seguro:

```conf
listen_addresses = 'localhost'
```

También puede configurarse como:

```conf
listen_addresses = '127.0.0.1'
```

Esto significa que PostgreSQL solo acepta conexiones locales.

Si se configura así:

```conf
listen_addresses = '*'
```

PostgreSQL escuchará en todas las interfaces de red disponibles. Esta opción permite conexiones externas, pero debe usarse con mucho cuidado y acompañarse de reglas estrictas en `pg_hba.conf`, firewall y Docker.

## Explicación técnica

`listen_addresses` define por dónde PostgreSQL escucha conexiones.

* `localhost`: solo permite conexiones locales.
* `127.0.0.1`: solo permite conexiones desde la misma máquina mediante IPv4.
* `*`: permite que PostgreSQL escuche en todas las interfaces de red.

## Ver configuración actual

```sql
SHOW listen_addresses;
```

Desde Docker:

```bash
docker exec -it postgres17-recuperado psql -U postgres -d Viva -c "SHOW listen_addresses;"
```

---

## 4.3 Configuración de `pg_hba.conf`

El archivo `pg_hba.conf` controla:

* Qué usuarios pueden conectarse.
* A qué bases de datos pueden acceder.
* Desde qué direcciones IP.
* Qué método de autenticación deben usar.

Estructura general:

```conf
TYPE    DATABASE    USER    ADDRESS    METHOD
```

Configuración aplicada:

```conf
# TYPE  DATABASE        USER            ADDRESS                 METHOD

local   all             all                                     scram-sha-256
host    all             all             127.0.0.1/32            scram-sha-256
host    all             all             ::1/128                 scram-sha-256

local   replication     all                                     scram-sha-256
host    replication     all             127.0.0.1/32            scram-sha-256
host    replication     all             ::1/128                 scram-sha-256
```

## Explicación de cada regla

| Regla                                             | Función                                                |
| ------------------------------------------------- | ------------------------------------------------------ |
| `local all all scram-sha-256`                     | Permite conexiones locales usando autenticación segura |
| `host all all 127.0.0.1/32 scram-sha-256`         | Permite conexiones TCP/IP solo desde localhost IPv4    |
| `host all all ::1/128 scram-sha-256`              | Permite conexiones TCP/IP solo desde localhost IPv6    |
| `local replication all scram-sha-256`             | Permite replicación local con autenticación segura     |
| `host replication all 127.0.0.1/32 scram-sha-256` | Permite replicación desde localhost IPv4               |
| `host replication all ::1/128 scram-sha-256`      | Permite replicación desde localhost IPv6               |

---

## 4.4 Función de `scram-sha-256`

`scram-sha-256` es un método moderno de autenticación de contraseñas en PostgreSQL.

Su función es validar que el usuario realmente conoce su contraseña sin usar métodos débiles como `trust`, `password` o `md5`.

Comparación:

| Método          | Descripción                            | Seguridad      |
| --------------- | -------------------------------------- | -------------- |
| `trust`         | Permite conexión sin contraseña        | Muy inseguro   |
| `password`      | Envía contraseña de forma menos segura | No recomendado |
| `md5`           | Método antiguo basado en MD5           | Menos seguro   |
| `scram-sha-256` | Método moderno y fuerte                | Recomendado    |

Verificar método de cifrado:

```sql
SHOW password_encryption;
```

Configurar SCRAM para nuevas contraseñas:

```sql
ALTER SYSTEM SET password_encryption = 'scram-sha-256';
SELECT pg_reload_conf();
```

Actualizar contraseña de usuarios para que se almacenen con SCRAM:

```sql
ALTER USER analista_ventas WITH PASSWORD 'Analista123*';
ALTER USER "admin-role" WITH PASSWORD 'Admin123*';
```

---

## 4.5 Recargar configuración

Después de modificar `pg_hba.conf`, se debe recargar la configuración:

```sql
SELECT pg_reload_conf();
```

Desde Docker:

```bash
docker exec -it postgres17-recuperado psql -U postgres -d Viva -c "SELECT pg_reload_conf();"
```

También puede reiniciarse el contenedor:

```bash
docker restart postgres17-recuperado
```

---

## 4.6 Roles creados

Listado de roles:

```sql
\du
```

Roles identificados:

| Rol               | Tipo              | Función                               |
| ----------------- | ----------------- | ------------------------------------- |
| `postgres`        | Superusuario      | Administración completa de PostgreSQL |
| `admin-role`      | Usuario con login | Usuario administrativo general        |
| `admin_clientes`  | Rol sin login     | Administración del esquema `clientes` |
| `admin_finanzas`  | Rol sin login     | Administración del esquema `finanzas` |
| `admin_rrhh`      | Rol sin login     | Administración del esquema `rrhh`     |
| `admin_ventas`    | Rol sin login     | Administración del esquema `ventas`   |
| `analista_ventas` | Usuario con login | Usuario para análisis comercial       |
| `analyst_role`    | Rol sin login     | Permisos de lectura y análisis        |
| `employee_role`   | Rol sin login     | Permisos limitados para empleados     |
| `manager_role`    | Rol sin login     | Permisos amplios para gerencia        |
| `rol_lectura`     | Rol sin login     | Permisos generales de solo lectura    |

---

## 4.7 Diferencia entre usuarios y roles sin login

Los roles con `Cannot login` no pueden conectarse directamente a la base de datos. Funcionan como grupos de permisos.

Ejemplo:

```sql
GRANT analyst_role TO analista_ventas;
```

Esto significa que el usuario `analista_ventas` puede conectarse y heredar permisos del rol `analyst_role`.

---

## 4.8 Rol `postgres`

El rol `postgres` tiene:

```text
Superuser, Create role, Create DB, Replication, Bypass RLS
```

Esto significa que puede:

* Crear bases de datos.
* Crear roles.
* Administrar permisos.
* Realizar replicación.
* Saltarse las políticas RLS.

Por seguridad, este rol debe usarse solo para administración y no para operaciones normales.

---

## 4.9 Checklist Semana 1

| Control                                         | Estado   |
| ----------------------------------------------- | -------- |
| Identificación de `postgresql.conf`             | Aplicado |
| Identificación de `pg_hba.conf`                 | Aplicado |
| Configuración de `listen_addresses`             | Aplicado |
| Autenticación con `scram-sha-256`               | Aplicado |
| Creación de roles por responsabilidad           | Aplicado |
| Separación de roles con login y sin login       | Aplicado |
| Recarga de configuración con `pg_reload_conf()` | Aplicado |

---

# SEMANA 2: Control de Acceso y Seguridad por Objeto

## 5. Objetivo de la Semana 2

Implementar seguridad por roles, esquemas, tablas, vistas y políticas RLS, aplicando el principio de mínimo privilegio.

---

## 5.1 Esquemas protegidos

La base de datos está organizada en los siguientes esquemas:

| Esquema    | Función                                                          |
| ---------- | ---------------------------------------------------------------- |
| `clientes` | Gestión de clientes, líneas telefónicas, dispositivos y consumos |
| `ventas`   | Gestión de planes, paquetes, promociones y bonos                 |
| `finanzas` | Gestión de facturas, recargas, préstamos y pagos                 |
| `rrhh`     | Gestión de empleados y perfiles laborales                        |

---

## 5.2 Views creadas

Las views funcionan como una capa de seguridad entre el usuario y las tablas reales. Permiten mostrar solo ciertas columnas o filas, evitando exponer datos sensibles.

## Views del esquema `ventas`

```sql
\dv ventas.*
```

| View                               | Función                                   |
| ---------------------------------- | ----------------------------------------- |
| `ventas.vw_planes_vigentes`        | Muestra planes activos o vigentes         |
| `ventas.vw_promociones_operativas` | Muestra promociones vigentes u operativas |

### `ventas.vw_planes_vigentes`

Esta vista muestra información de planes disponibles, ocultando datos que no son necesarios para el usuario final.

Columnas:

* `id_plan`
* `nombre_plan`
* `tipo_plan`
* `minutos_incluidos`
* `sms_incluidos`
* `datos_mb_incluidos`
* `activo`

### `ventas.vw_promociones_operativas`

Esta vista permite consultar promociones operativas.

Columnas:

* `id_promocion`
* `nombre`
* `descripcion`
* `tipo_de_beneficio`
* `fecha_inicio`
* `fecha_fin`

---

## Views del esquema `finanzas`

```sql
\dv finanzas.*
```

| View                                    | Función                                                   |
| --------------------------------------- | --------------------------------------------------------- |
| `finanzas.vw_recarga_segura`            | Muestra recargas sin exponer campos financieros sensibles |
| `finanzas.vw_resumen_facturacion_linea` | Resume facturación por línea telefónica                   |

### `finanzas.vw_recarga_segura`

Columnas:

* `id_recarga`
* `id_linea`
* `fecha_recarga`
* `monto`

Esta vista no expone campos como `medio_recarga`, `genera_factura` o `salario_resultante`.

### `finanzas.vw_resumen_facturacion_linea`

Columnas:

* `id_linea`
* `cantidad_facturas`
* `inversion_total_base`
* `promedio_intereses`

Esta vista sirve para análisis financiero resumido.

---

## Views del esquema `rrhh`

```sql
\dv rrhh.*
```

| View                             | Función                                        |
| -------------------------------- | ---------------------------------------------- |
| `rrhh.vw_info_publica_empleados` | Muestra información pública del empleado       |
| `rrhh.vw_perfiles_empleados`     | Muestra perfiles laborales sin exponer salario |

### `rrhh.vw_info_publica_empleados`

Columnas:

* `id`
* `nombre`
* `puesto`

Esta vista protege información sensible como el salario.

### `rrhh.vw_perfiles_empleados`

Columnas:

* `id`
* `nombre`
* `puesto`

Sirve para consultar información funcional de empleados sin acceder directamente a la tabla `rrhh.employee`.

---

## Views del esquema `clientes`

```sql
\dv clientes.*
```

| View                               | Función                                  |
| ---------------------------------- | ---------------------------------------- |
| `clientes.vw_analisis_clientes`    | Muestra datos de clientes para análisis  |
| `clientes.vw_dispositivos_seguros` | Muestra dispositivos protegiendo el IMEI |

### `clientes.vw_analisis_clientes`

Columnas:

* `id_cliente`
* `tipo_cliente`
* `nombre`
* `apellidos`
* `direccion`
* `fecha_registro`

### `clientes.vw_dispositivos_seguros`

Columnas:

* `id_dispositivo`
* `id_linea`
* `marca`
* `modelo`
* `imei_protegido`

La columna `imei_protegido` evita mostrar el IMEI completo del dispositivo.

---

## 5.3 Restricción de permisos sobre views

Primero se revocan permisos públicos:

```sql
REVOKE ALL ON ventas.vw_planes_vigentes FROM PUBLIC;
REVOKE ALL ON ventas.vw_promociones_operativas FROM PUBLIC;

REVOKE ALL ON finanzas.vw_recarga_segura FROM PUBLIC;
REVOKE ALL ON finanzas.vw_resumen_facturacion_linea FROM PUBLIC;

REVOKE ALL ON rrhh.vw_info_publica_empleados FROM PUBLIC;
REVOKE ALL ON rrhh.vw_perfiles_empleados FROM PUBLIC;

REVOKE ALL ON clientes.vw_analisis_clientes FROM PUBLIC;
REVOKE ALL ON clientes.vw_dispositivos_seguros FROM PUBLIC;
```

Luego se otorgan permisos específicos:

```sql
GRANT SELECT ON ventas.vw_planes_vigentes TO employee_role, analyst_role, manager_role;
GRANT SELECT ON ventas.vw_promociones_operativas TO employee_role, analyst_role, manager_role;

GRANT SELECT ON finanzas.vw_recarga_segura TO employee_role, manager_role;
GRANT SELECT ON finanzas.vw_resumen_facturacion_linea TO analyst_role, manager_role;

GRANT SELECT ON rrhh.vw_info_publica_empleados TO employee_role, manager_role;
GRANT SELECT ON rrhh.vw_perfiles_empleados TO employee_role, manager_role;

GRANT SELECT ON clientes.vw_analisis_clientes TO analyst_role, manager_role;
GRANT SELECT ON clientes.vw_dispositivos_seguros TO employee_role, analyst_role, manager_role;
```

---

# 6. Row Level Security - RLS

## 6.1 ¿Qué es RLS?

RLS significa `Row Level Security` o seguridad a nivel de filas.

Permite que diferentes usuarios consulten la misma tabla, pero vean diferentes registros según su rol o condición.

Ejemplo:

```sql
ALTER TABLE ventas.plan ENABLE ROW LEVEL SECURITY;
```

Una policy tiene esta forma:

```sql
CREATE POLICY nombre_policy
ON esquema.tabla
FOR SELECT
TO rol
USING (condicion);
```

---

# 7. Policies implementadas

## 7.1 Policies del esquema `ventas`

### Tabla `ventas.bono_promocional`

Policy:

```sql
POLICY "policy_analyst_bonos" FOR SELECT
TO analyst_role
USING ((fecha_expiracion > now()))
```

Función:

El rol `analyst_role` solo puede ver bonos promocionales que no han expirado.

---

### Tabla `ventas.linea_plan`

Policies:

```sql
POLICY "policy_employee_lineas" FOR SELECT
TO employee_role
USING ((activo = true))
```

```sql
POLICY "policy_manager_lineas"
TO manager_role
USING (true)
```

Función:

| Rol             | Acceso                      |
| --------------- | --------------------------- |
| `employee_role` | Solo líneas de plan activas |
| `manager_role`  | Todas las líneas            |

---

### Tabla `ventas.paquete`

Policies:

```sql
POLICY "policy_employee_active_paquetes" FOR SELECT
TO employee_role
USING ((activo = true))
```

```sql
POLICY "policy_read_all_paquetes" FOR SELECT
TO analyst_role, manager_role
USING (true)
```

Función:

| Rol             | Acceso                |
| --------------- | --------------------- |
| `employee_role` | Solo paquetes activos |
| `analyst_role`  | Todos los paquetes    |
| `manager_role`  | Todos los paquetes    |

---

### Tabla `ventas.paquete_adquirido`

Policies:

```sql
POLICY "policy_employee_restricted" FOR SELECT
TO employee_role
USING (
  id_linea IN (
    SELECT linea_plan.id_linea
    FROM ventas.linea_plan
    WHERE linea_plan.activo = true
  )
)
```

```sql
POLICY "policy_manager_full_access" FOR SELECT
TO manager_role
USING (true)
```

Función:

El empleado solo puede ver paquetes adquiridos por líneas activas. El gerente puede ver todos los registros.

---

### Tabla `ventas.plan`

Policies:

```sql
POLICY "policy_employee_active_plans" FOR SELECT
TO employee_role
USING ((activo = true))
```

```sql
POLICY "policy_read_all_catalogs" FOR SELECT
TO analyst_role, manager_role
USING (true)
```

Función:

| Rol             | Acceso              |
| --------------- | ------------------- |
| `employee_role` | Solo planes activos |
| `analyst_role`  | Todos los planes    |
| `manager_role`  | Todos los planes    |

---

### Tabla `ventas.plan_corporativo`

Policy:

```sql
POLICY "policy_manager_corp"
TO manager_role
USING (true)
```

Función:

Solo el rol `manager_role` tiene acceso completo a planes corporativos.

---

### Tabla `ventas.promocion`

Policy:

```sql
POLICY "policy_promociones_vigentes" FOR SELECT
TO employee_role
USING (((now() >= fecha_inicio) AND (now() <= fecha_fin)))
```

Función:

El empleado solo puede ver promociones vigentes según la fecha actual.

---

### Tabla `ventas.promocion_aplicada`

Policy:

```sql
POLICY "policy_aplicaciones_activas" FOR SELECT
TO employee_role
USING ((fecha_expiracion > now()))
```

Función:

El empleado solo puede ver promociones aplicadas que todavía no expiraron.

---

## 7.2 Policies del esquema `finanzas`

### Tabla `finanzas.factura`

Policies:

```sql
POLICY "policy_employee_factura_limit" FOR SELECT
TO employee_role
USING ((fecha_emision > (now() - '30 days'::interval)))
```

```sql
POLICY "policy_manager_finanzas_all"
TO manager_role
USING (true)
```

```sql
POLICY "policy_manager_ventas" FOR SELECT
TO manager_role
USING (true)
```

Función:

| Rol             | Acceso                               |
| --------------- | ------------------------------------ |
| `employee_role` | Solo facturas de los últimos 30 días |
| `manager_role`  | Todas las facturas                   |

Observación:

Existen dos policies para `manager_role` con `USING (true)`. Ambas dan acceso completo, por lo que podrían considerarse redundantes.

---

### Tabla `finanzas.pago_prestamo`

Policies:

```sql
POLICY "policy_analyst_read_finanzas" FOR SELECT
TO analyst_role
USING (true)
```

```sql
POLICY "policy_manager_finanzas_all"
TO manager_role
USING (true)
```

Función:

Analistas y gerentes pueden consultar todos los pagos de préstamos.

---

### Tabla `finanzas.prestamo`

Policies:

```sql
POLICY "policy_analyst_read_finanzas" FOR SELECT
TO analyst_role
USING (true)
```

```sql
POLICY "policy_manager_finanzas_all"
TO manager_role
USING (true)
```

Función:

Analistas y gerentes pueden consultar todos los préstamos.

---

### Tabla `finanzas.recarga`

Policies:

```sql
POLICY "policy_employee_recarga_valida" FOR SELECT
TO employee_role
USING ((genera_factura = true))
```

```sql
POLICY "policy_manager_finanzas_all"
TO manager_role
USING (true)
```

Función:

| Rol             | Acceso                            |
| --------------- | --------------------------------- |
| `employee_role` | Solo recargas que generan factura |
| `manager_role`  | Todas las recargas                |

---

## 7.3 Policies del esquema `clientes`

### Tabla `clientes.cliente`

Policies:

```sql
POLICY "policy_analyst_read" FOR SELECT
TO analyst_role
USING (true)
```

```sql
POLICY "policy_employee_view" FOR SELECT
TO employee_role
USING ((antiguedad_dias > 0))
```

```sql
POLICY "policy_manager_all"
TO manager_role
USING (true)
```

Función:

| Rol             | Acceso                            |
| --------------- | --------------------------------- |
| `analyst_role`  | Todos los clientes                |
| `employee_role` | Clientes con antigüedad mayor a 0 |
| `manager_role`  | Todos los clientes                |

La tabla también tiene un trigger de auditoría:

```sql
trg_auditoria_cliente AFTER INSERT OR DELETE OR UPDATE
ON clientes.cliente
FOR EACH ROW
EXECUTE FUNCTION fn_auditoria_dml()
```

---

### Tabla `clientes.cliente_corporativo`

Policy:

```sql
POLICY "policy_manager_all"
TO manager_role
USING (true)
```

Función:

Solo el gerente tiene acceso completo a clientes corporativos.

---

### Tabla `clientes.consumo`

Policies:

```sql
POLICY "policy_analyst_read" FOR SELECT
TO analyst_role
USING (true)
```

```sql
POLICY "policy_employee_consumo" FOR SELECT
TO employee_role
USING (
  id_adquisicion IN (
    SELECT paquete_adquirido.id_adquisicion
    FROM ventas.paquete_adquirido
    WHERE paquete_adquirido.estado = 'ACTIVO'
  )
)
```

```sql
POLICY "policy_manager_all"
TO manager_role
USING (true)
```

Función:

| Rol             | Acceso                                     |
| --------------- | ------------------------------------------ |
| `analyst_role`  | Todos los consumos                         |
| `employee_role` | Solo consumos asociados a paquetes activos |
| `manager_role`  | Todos los consumos                         |

---

### Tabla `clientes.linea_telefonica`

Policy:

```sql
POLICY "policy_manager_all"
TO manager_role
USING (true)
```

Función:

Solo el gerente tiene acceso completo a las líneas telefónicas.

---

## 7.4 Policies del esquema `rrhh`

### Tabla `rrhh.employee`

Policies:

```sql
POLICY "policy_employee_self_service" FOR SELECT
TO employee_role
USING ((nombre = CURRENT_USER))
```

```sql
POLICY "policy_manager_audit_access" FOR SELECT
TO manager_role
USING (true)
```

Función:

| Rol             | Acceso                  |
| --------------- | ----------------------- |
| `employee_role` | Solo su propio registro |
| `manager_role`  | Todos los empleados     |

Observación:

La policy `policy_employee_self_service` funciona correctamente si el valor de la columna `nombre` coincide con el nombre del usuario conectado en PostgreSQL.

---

# 8. Consultas de verificación Semana 2

## 8.1 Ver todas las policies

```sql
SELECT 
    schemaname,
    tablename,
    policyname,
    roles,
    cmd,
    qual
FROM pg_policies
WHERE schemaname IN ('ventas', 'finanzas', 'clientes', 'rrhh')
ORDER BY schemaname, tablename, policyname;
```

## 8.2 Ver si RLS está activo

```sql
SELECT 
    schemaname,
    tablename,
    rowsecurity
FROM pg_tables
WHERE schemaname IN ('ventas', 'finanzas', 'clientes', 'rrhh')
ORDER BY schemaname, tablename;
```

## 8.3 Ver roles creados

```sql
\du
```

## 8.4 Ver views creadas

```sql
\dv ventas.*
\dv finanzas.*
\dv rrhh.*
\dv clientes.*
```

## 8.5 Ver definición de una view

```sql
SELECT pg_get_viewdef('ventas.vw_planes_vigentes'::regclass, true);
```

---

# SEMANA 3: Auditoría y Monitoreo

## 9. Objetivo de la Semana 3

Implementar mecanismos para registrar, revisar y monitorear eventos relevantes dentro de la base de datos.

Se busca evidenciar:

* Logs de conexión.
* Logs de operaciones DDL.
* Registro de eventos DML.
* Identificación de sesiones lentas.
* Detección de bloqueos.
* Uso de `pg_stat_statements`.

---

## 9.1 Configuración de logs

Consultar configuración actual:

```sql
SHOW logging_collector;
SHOW log_connections;
SHOW log_disconnections;
SHOW log_statement;
SHOW log_min_duration_statement;
```

Configuración recomendada:

```sql
ALTER SYSTEM SET logging_collector = 'on';
ALTER SYSTEM SET log_connections = 'on';
ALTER SYSTEM SET log_disconnections = 'on';
ALTER SYSTEM SET log_statement = 'ddl';
ALTER SYSTEM SET log_min_duration_statement = 1000;

SELECT pg_reload_conf();
```

Explicación:

| Parámetro                           | Función                                           |
| ----------------------------------- | ------------------------------------------------- |
| `logging_collector`                 | Activa recolección de logs                        |
| `log_connections`                   | Registra conexiones entrantes                     |
| `log_disconnections`                | Registra desconexiones                            |
| `log_statement = 'ddl'`             | Registra operaciones DDL como CREATE, ALTER, DROP |
| `log_min_duration_statement = 1000` | Registra consultas que duren más de 1 segundo     |

---

## 9.2 Auditoría DML con trigger

Tabla de auditoría:

```sql
CREATE SCHEMA IF NOT EXISTS auditoria;

CREATE TABLE IF NOT EXISTS auditoria.auditoria_dml (
    id_auditoria SERIAL PRIMARY KEY,
    esquema TEXT,
    tabla TEXT,
    operacion TEXT,
    usuario TEXT,
    fecha TIMESTAMP DEFAULT now(),
    datos_anteriores JSONB,
    datos_nuevos JSONB
);
```

Función de auditoría:

```sql
CREATE OR REPLACE FUNCTION fn_auditoria_dml()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO auditoria.auditoria_dml(
            esquema, tabla, operacion, usuario, datos_nuevos
        )
        VALUES (
            TG_TABLE_SCHEMA, TG_TABLE_NAME, TG_OP, current_user, to_jsonb(NEW)
        );
        RETURN NEW;

    ELSIF TG_OP = 'UPDATE' THEN
        INSERT INTO auditoria.auditoria_dml(
            esquema, tabla, operacion, usuario, datos_anteriores, datos_nuevos
        )
        VALUES (
            TG_TABLE_SCHEMA, TG_TABLE_NAME, TG_OP, current_user, to_jsonb(OLD), to_jsonb(NEW)
        );
        RETURN NEW;

    ELSIF TG_OP = 'DELETE' THEN
        INSERT INTO auditoria.auditoria_dml(
            esquema, tabla, operacion, usuario, datos_anteriores
        )
        VALUES (
            TG_TABLE_SCHEMA, TG_TABLE_NAME, TG_OP, current_user, to_jsonb(OLD)
        );
        RETURN OLD;
    END IF;

    RETURN NULL;
END;
$$ LANGUAGE plpgsql;
```

Trigger aplicado sobre la tabla `clientes.cliente`:

```sql
CREATE TRIGGER trg_auditoria_cliente
AFTER INSERT OR UPDATE OR DELETE
ON clientes.cliente
FOR EACH ROW
EXECUTE FUNCTION fn_auditoria_dml();
```

---

## 9.3 Pruebas de auditoría DML

### INSERT

```sql
INSERT INTO clientes.cliente(
    tipo_cliente, nombre, apellidos, doc_identidad, email, direccion, fecha_registro, antiguedad_dias
)
VALUES (
    'Natural', 'Prueba', 'Auditoria', '99999999', 'prueba@mail.com', 'Zona Central', CURRENT_DATE, 1
);
```

### UPDATE

```sql
UPDATE clientes.cliente
SET direccion = 'Nueva dirección de prueba'
WHERE doc_identidad = '99999999';
```

### DELETE

```sql
DELETE FROM clientes.cliente
WHERE doc_identidad = '99999999';
```

### Consultar auditoría

```sql
SELECT *
FROM auditoria.auditoria_dml
ORDER BY fecha DESC
LIMIT 10;
```

---

## 9.4 Monitoreo de sesiones activas

```sql
SELECT 
    pid,
    usename,
    datname,
    state,
    query,
    now() - query_start AS duracion
FROM pg_stat_activity
WHERE state <> 'idle'
ORDER BY duracion DESC;
```

Esta consulta permite identificar sesiones activas o consultas que llevan mucho tiempo ejecutándose.

---

## 9.5 Cancelar una consulta lenta

Primero se identifica el `pid`:

```sql
SELECT 
    pid,
    usename,
    query,
    now() - query_start AS duracion
FROM pg_stat_activity
WHERE state = 'active';
```

Luego se cancela:

```sql
SELECT pg_cancel_backend(pid);
```

Si es necesario finalizar la sesión:

```sql
SELECT pg_terminate_backend(pid);
```

---

## 9.6 Simulación de bloqueo

Sesión 1:

```sql
BEGIN;

UPDATE clientes.cliente
SET direccion = 'Bloqueo prueba'
WHERE id_cliente = 1;
```

Sesión 2:

```sql
UPDATE clientes.cliente
SET direccion = 'Intento bloqueado'
WHERE id_cliente = 1;
```

Consulta para detectar bloqueos:

```sql
SELECT 
    blocked_locks.pid AS blocked_pid,
    blocked_activity.usename AS blocked_user,
    blocking_locks.pid AS blocking_pid,
    blocking_activity.usename AS blocking_user,
    blocked_activity.query AS blocked_statement,
    blocking_activity.query AS blocking_statement
FROM pg_catalog.pg_locks blocked_locks
JOIN pg_catalog.pg_stat_activity blocked_activity
    ON blocked_activity.pid = blocked_locks.pid
JOIN pg_catalog.pg_locks blocking_locks
    ON blocking_locks.locktype = blocked_locks.locktype
    AND blocking_locks.database IS NOT DISTINCT FROM blocked_locks.database
    AND blocking_locks.relation IS NOT DISTINCT FROM blocked_locks.relation
    AND blocking_locks.page IS NOT DISTINCT FROM blocked_locks.page
    AND blocking_locks.tuple IS NOT DISTINCT FROM blocked_locks.tuple
    AND blocking_locks.virtualxid IS NOT DISTINCT FROM blocked_locks.virtualxid
    AND blocking_locks.transactionid IS NOT DISTINCT FROM blocked_locks.transactionid
    AND blocking_locks.classid IS NOT DISTINCT FROM blocked_locks.classid
    AND blocking_locks.objid IS NOT DISTINCT FROM blocked_locks.objid
    AND blocking_locks.objsubid IS NOT DISTINCT FROM blocked_locks.objsubid
    AND blocking_locks.pid != blocked_locks.pid
JOIN pg_catalog.pg_stat_activity blocking_activity
    ON blocking_activity.pid = blocking_locks.pid
WHERE NOT blocked_locks.granted;
```

Solución:

```sql
SELECT pg_terminate_backend(blocking_pid);
```

O confirmar la transacción en la sesión bloqueadora:

```sql
COMMIT;
```

---

## 9.7 Activación de `pg_stat_statements`

Crear extensión:

```sql
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;
```

Verificar:

```sql
SELECT * FROM pg_extension;
```

Consultar top 5 consultas más costosas:

```sql
SELECT 
    query,
    calls,
    total_exec_time,
    mean_exec_time,
    rows
FROM pg_stat_statements
ORDER BY total_exec_time DESC
LIMIT 5;
```

---

## 9.8 Checklist Semana 3

| Control                       | Estado   |
| ----------------------------- | -------- |
| Logs de conexión activados    | Aplicado |
| Logs DDL activados            | Aplicado |
| Auditoría DML implementada    | Aplicado |
| Trigger de auditoría creado   | Aplicado |
| Consulta de sesiones lentas   | Aplicado |
| Detección de bloqueos         | Aplicado |
| `pg_stat_statements` activado | Aplicado |

---

# SEMANA 4: Backup, Recuperación y Entrega Final

## 10. Objetivo de la Semana 4

Implementar respaldo y recuperación de la base de datos, validar la restauración y consolidar la documentación técnica del proyecto.

---

## 10.1 Backup lógico en formato SQL

```bash
docker exec -t postgres17-recuperado pg_dump -U postgres -d Viva > backups/viva_backup.sql
```

Este archivo contiene la estructura y datos de la base de datos.

---

## 10.2 Backup en formato custom

```bash
docker exec -t postgres17-recuperado pg_dump -U postgres -d Viva -F c -f /tmp/viva_backup.dump
docker cp postgres17-recuperado:/tmp/viva_backup.dump backups/viva_backup.dump
```

El formato custom permite restaurar usando `pg_restore`.

---

## 10.3 Backup de roles y permisos globales

```bash
docker exec -t postgres17-recuperado pg_dumpall -U postgres --globals-only > backups/globals_roles.sql
```

Este respaldo guarda roles, usuarios y permisos globales.

---

## 10.4 Restauración desde archivo SQL

Crear una base nueva:

```bash
docker exec -it postgres17-recuperado createdb -U postgres Viva_restore
```

Restaurar:

```bash
docker exec -i postgres17-recuperado psql -U postgres -d Viva_restore < backups/viva_backup.sql
```

---

## 10.5 Restauración desde formato custom

Copiar backup al contenedor:

```bash
docker cp backups/viva_backup.dump postgres17-recuperado:/tmp/viva_backup.dump
```

Crear base:

```bash
docker exec -it postgres17-recuperado createdb -U postgres Viva_restore
```

Restaurar:

```bash
docker exec -it postgres17-recuperado pg_restore -U postgres -d Viva_restore /tmp/viva_backup.dump
```

---

## 10.6 Validación de restauración

Verificar tablas:

```sql
\dt clientes.*
\dt ventas.*
\dt finanzas.*
\dt rrhh.*
```

Verificar roles:

```sql
\du
```

Verificar views:

```sql
\dv ventas.*
\dv finanzas.*
\dv clientes.*
\dv rrhh.*
```

Verificar policies:

```sql
SELECT 
    schemaname,
    tablename,
    policyname,
    roles,
    cmd,
    qual
FROM pg_policies
WHERE schemaname IN ('ventas', 'finanzas', 'clientes', 'rrhh')
ORDER BY schemaname, tablename, policyname;
```

Verificar auditoría:

```sql
SELECT *
FROM auditoria.auditoria_dml
ORDER BY fecha DESC
LIMIT 10;
```

---

# 11. Política de Backup y Recuperación

## 11.1 RPO

El RPO define la cantidad máxima de información que se puede perder en caso de incidente.

Para este proyecto:

```text
RPO = 24 horas
```

Esto significa que se debe realizar al menos un backup diario.

## 11.2 RTO

El RTO define el tiempo máximo esperado para restaurar el servicio.

Para este proyecto:

```text
RTO = 1 hora
```

Esto significa que la base de datos debe poder restaurarse en máximo una hora después de un incidente.

## 11.3 Estrategia de backup

| Tipo de backup             | Frecuencia               | Herramienta                 |
| -------------------------- | ------------------------ | --------------------------- |
| Backup lógico SQL          | Diario                   | `pg_dump`                   |
| Backup custom              | Semanal                  | `pg_dump -F c`              |
| Backup de roles            | Cada cambio de seguridad | `pg_dumpall --globals-only` |
| Validación de restauración | Semanal                  | `pg_restore`                |

---

# 12. Matriz de privilegios

| Rol               | Esquema    | Acceso principal                   |
| ----------------- | ---------- | ---------------------------------- |
| `postgres`        | Todos      | Administración total               |
| `admin_clientes`  | `clientes` | Administración del módulo clientes |
| `admin_finanzas`  | `finanzas` | Administración financiera          |
| `admin_rrhh`      | `rrhh`     | Administración de recursos humanos |
| `admin_ventas`    | `ventas`   | Administración comercial           |
| `analyst_role`    | Varios     | Lectura para análisis              |
| `employee_role`   | Varios     | Lectura restringida por RLS        |
| `manager_role`    | Varios     | Acceso amplio para supervisión     |
| `rol_lectura`     | Varios     | Solo lectura                       |
| `analista_ventas` | `ventas`   | Usuario de análisis de ventas      |

---

# 13. Diferencia entre Views y Policies

| Elemento           | Función                                                       |
| ------------------ | ------------------------------------------------------------- |
| View               | Controla qué columnas o datos preparados puede ver un usuario |
| Policy RLS         | Controla qué filas puede ver un usuario                       |
| Rol                | Define permisos según responsabilidad                         |
| `pg_hba.conf`      | Controla quién puede conectarse y cómo                        |
| `listen_addresses` | Define por dónde escucha PostgreSQL                           |
| `scram-sha-256`    | Define autenticación segura de contraseña                     |

Ejemplo:

Una view puede ocultar el IMEI completo:

```sql
SELECT id_dispositivo, marca, modelo, imei_protegido
FROM clientes.vw_dispositivos_seguros;
```

Una policy puede limitar filas:

```sql
USING (activo = true)
```

Esto significa que el usuario solo ve registros activos.

---

# 14. Script maestro de seguridad

Archivo sugerido:

```text
scripts/setup_seguridad.sql
```

Contenido general recomendado:

```sql
-- =====================================================
-- SETUP SEGURIDAD POSTGRESQL - BASE VIVA
-- =====================================================

-- 1. Configuración de password encryption
ALTER SYSTEM SET password_encryption = 'scram-sha-256';

-- 2. Recargar configuración
SELECT pg_reload_conf();

-- 3. Crear roles base
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'employee_role') THEN
        CREATE ROLE employee_role NOLOGIN;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'analyst_role') THEN
        CREATE ROLE analyst_role NOLOGIN;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'manager_role') THEN
        CREATE ROLE manager_role NOLOGIN;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'rol_lectura') THEN
        CREATE ROLE rol_lectura NOLOGIN;
    END IF;
END $$;

-- 4. Revocar permisos públicos
REVOKE ALL ON SCHEMA public FROM PUBLIC;
REVOKE CREATE ON SCHEMA public FROM PUBLIC;

-- 5. Permisos de uso sobre esquemas
GRANT USAGE ON SCHEMA clientes TO employee_role, analyst_role, manager_role;
GRANT USAGE ON SCHEMA ventas TO employee_role, analyst_role, manager_role;
GRANT USAGE ON SCHEMA finanzas TO employee_role, analyst_role, manager_role;
GRANT USAGE ON SCHEMA rrhh TO employee_role, manager_role;

-- 6. Permisos sobre views
GRANT SELECT ON ventas.vw_planes_vigentes TO employee_role, analyst_role, manager_role;
GRANT SELECT ON ventas.vw_promociones_operativas TO employee_role, analyst_role, manager_role;

GRANT SELECT ON finanzas.vw_recarga_segura TO employee_role, manager_role;
GRANT SELECT ON finanzas.vw_resumen_facturacion_linea TO analyst_role, manager_role;

GRANT SELECT ON rrhh.vw_info_publica_empleados TO employee_role, manager_role;
GRANT SELECT ON rrhh.vw_perfiles_empleados TO employee_role, manager_role;

GRANT SELECT ON clientes.vw_analisis_clientes TO analyst_role, manager_role;
GRANT SELECT ON clientes.vw_dispositivos_seguros TO employee_role, analyst_role, manager_role;

-- 7. Activar RLS en tablas principales
ALTER TABLE ventas.plan ENABLE ROW LEVEL SECURITY;
ALTER TABLE ventas.paquete ENABLE ROW LEVEL SECURITY;
ALTER TABLE ventas.linea_plan ENABLE ROW LEVEL SECURITY;
ALTER TABLE ventas.paquete_adquirido ENABLE ROW LEVEL SECURITY;
ALTER TABLE ventas.promocion ENABLE ROW LEVEL SECURITY;
ALTER TABLE ventas.promocion_aplicada ENABLE ROW LEVEL SECURITY;
ALTER TABLE ventas.bono_promocional ENABLE ROW LEVEL SECURITY;

ALTER TABLE finanzas.factura ENABLE ROW LEVEL SECURITY;
ALTER TABLE finanzas.recarga ENABLE ROW LEVEL SECURITY;
ALTER TABLE finanzas.prestamo ENABLE ROW LEVEL SECURITY;
ALTER TABLE finanzas.pago_prestamo ENABLE ROW LEVEL SECURITY;

ALTER TABLE clientes.cliente ENABLE ROW LEVEL SECURITY;
ALTER TABLE clientes.cliente_corporativo ENABLE ROW LEVEL SECURITY;
ALTER TABLE clientes.consumo ENABLE ROW LEVEL SECURITY;
ALTER TABLE clientes.linea_telefonica ENABLE ROW LEVEL SECURITY;

ALTER TABLE rrhh.employee ENABLE ROW LEVEL SECURITY;
```

# 15. Conclusión

El proyecto implementa una arquitectura de seguridad por capas en PostgreSQL. Se protegió el acceso al servidor mediante `listen_addresses`, `pg_hba.conf` y `scram-sha-256`. Se aplicó control de permisos mediante roles y esquemas. Se protegieron datos sensibles con views y se aplicó seguridad a nivel de filas con RLS. Además, se incorporó auditoría, monitoreo y una estrategia de backup y recuperación.

Con esto se cumple el principio de mínimo privilegio, se reduce la exposición de la base de datos y se garantiza que cada rol acceda únicamente a la información necesaria para sus funciones.
