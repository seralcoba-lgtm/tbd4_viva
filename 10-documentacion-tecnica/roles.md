# Documentación de roles de la base de datos `Viva`

## 1. Objetivo de la separación de roles

La base de datos `Viva` implementa una separación de roles por función para cumplir con el principio de mínimo privilegio.
Esto significa que cada usuario o grupo de usuarios recibe únicamente los permisos necesarios para cumplir su tarea dentro del sistema.

La configuración diferencia entre:

* **Roles con LOGIN:** usuarios que pueden iniciar sesión en PostgreSQL.
* **Roles NOLOGIN:** roles de grupo usados para agrupar permisos.
* **Roles administrativos por área:** roles encargados de esquemas específicos.
* **Roles funcionales:** roles para empleados, analistas, gerencia y lectura.
* **Superusuario:** reservado únicamente para administración general de PostgreSQL.

---

## 2. Tabla general de roles

| Rol / Usuario            | Tipo    | Superusuario | Puede crear BD | Puede crear roles | Pertenece a       | Propósito dentro de la base de datos                                                                                                                                                         |
| ------------------------ | ------- | -----------: | -------------: | ----------------: | ----------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `postgres`               | LOGIN   |           Sí |             Sí |                Sí | No aplica         | Superusuario principal de PostgreSQL. Se utiliza solo para tareas administrativas críticas, mantenimiento, restauración, backup y configuración general.                                     |
| `admin_clientes`         | NOLOGIN |           No |             No |                No | No aplica         | Rol administrativo del esquema `clientes`. Agrupa permisos relacionados con la administración de datos de clientes, líneas telefónicas, dispositivos y consumo.                              |
| `admin_finanzas`         | NOLOGIN |           No |             No |                No | No aplica         | Rol administrativo del esquema `finanzas`. Agrupa permisos relacionados con facturas, recargas, préstamos, pagos y presupuestos.                                                             |
| `admin_rrhh`             | NOLOGIN |           No |             No |                No | No aplica         | Rol administrativo del esquema `rrhh`. Agrupa permisos relacionados con empleados y datos internos de recursos humanos.                                                                      |
| `admin_seguridad`        | NOLOGIN |           No |             No |                No | No aplica         | Rol administrativo del esquema `seguridad`. Se utiliza para controlar objetos relacionados con usuarios, asignaciones de líneas y reglas de seguridad.                                       |
| `admin_ventas`           | NOLOGIN |           No |             No |                No | No aplica         | Rol administrativo del esquema `ventas`. Agrupa permisos sobre planes, paquetes, promociones y relaciones comerciales.                                                                       |
| `admin-role`             | LOGIN   |           No |             No |                No | No registrado     | Usuario o rol administrativo general. Actualmente tiene capacidad de inicio de sesión, pero no posee privilegios globales como superusuario, creación de bases de datos o creación de roles. |
| `rol_lectura`            | NOLOGIN |           No |             No |                No | No aplica         | Rol de grupo para permisos de solo lectura. Sirve como base para usuarios o roles que únicamente necesitan consultar información sin modificar datos.                                        |
| `manager_role`           | NOLOGIN |           No |             No |                No | `rol_lectura`     | Rol funcional para gerencia. Hereda permisos de lectura desde `rol_lectura` y puede recibir permisos adicionales para supervisión y control.                                                 |
| `analyst_role`           | NOLOGIN |           No |             No |                No | No aplica         | Rol de grupo para analistas. Permite consultar información necesaria para análisis, reportes y revisión de datos sin otorgar privilegios administrativos.                                    |
| `employee_role`          | NOLOGIN |           No |             No |                No | No aplica         | Rol de grupo para empleados. Se usa para aplicar permisos limitados y políticas RLS que restringen la información visible según el usuario conectado.                                        |
| `analista_ventas`        | LOGIN   |           No |             No |                No | `analyst_role`    | Usuario final con acceso de analista. Hereda permisos desde `analyst_role` para consultar información relacionada con análisis de ventas.                                                    |
| `sergio_analista`        | LOGIN   |           No |             No |                No | `analyst_role`    | Usuario final de tipo analista. Recibe permisos del rol `analyst_role`, manteniendo separación entre usuario real y permisos funcionales.                                                    |
| `empleado_306`           | LOGIN   |           No |             No |                No | `employee_role`   | Usuario final de empleado. Sus permisos están limitados por `employee_role` y por políticas de seguridad a nivel de fila, permitiendo ver solo datos autorizados.                            |
| `empleado_307`           | LOGIN   |           No |             No |                No | `employee_role`   | Usuario final de empleado. Hereda permisos de `employee_role` y se usa para demostrar control de acceso por usuario.                                                                         |
| `gerente_general`        | LOGIN   |           No |             No |                No | `manager_role`    | Usuario final de gerencia. Hereda permisos desde `manager_role`, utilizado para funciones de supervisión y consulta ampliada.                                                                |
| `walter_admin_seguridad` | LOGIN   |           No |             No |                No | `admin_seguridad` | Usuario administrador del área de seguridad. Hereda permisos del rol `admin_seguridad` para gestionar objetos relacionados con control de acceso.                                            |
| `walter_admin_ventas`    | LOGIN   |           No |             No |                No | `admin_ventas`    | Usuario administrador del área de ventas. Hereda permisos del rol `admin_ventas` para administrar objetos del esquema `ventas`.                                                              |
| `walter_lectura`         | LOGIN   |           No |             No |                No | `rol_lectura`     | Usuario limitado de solo lectura. Se utiliza para validar que un usuario pueda consultar información permitida sin modificar estructuras ni datos.                                           |
| `laravel_gui`            | LOGIN   |           No |             No |                No | No registrado     | Usuario de conexión para la aplicación Laravel/Filament. Debe utilizarse con permisos controlados para que la interfaz gráfica acceda únicamente a los objetos necesarios.                   |

---

## 3. Relación entre usuarios y roles de grupo

| Usuario o rol miembro    | Tipo    | Rol de grupo asignado | Explicación                                                                   |
| ------------------------ | ------- | --------------------- | ----------------------------------------------------------------------------- |
| `analista_ventas`        | LOGIN   | `analyst_role`        | Usuario analista que hereda permisos de consulta y análisis.                  |
| `sergio_analista`        | LOGIN   | `analyst_role`        | Usuario analista adicional con los mismos permisos funcionales de análisis.   |
| `empleado_306`           | LOGIN   | `employee_role`       | Usuario empleado con acceso limitado y controlado por políticas de seguridad. |
| `empleado_307`           | LOGIN   | `employee_role`       | Usuario empleado con acceso restringido según su rol funcional.               |
| `gerente_general`        | LOGIN   | `manager_role`        | Usuario gerente que hereda permisos del rol gerencial.                        |
| `manager_role`           | NOLOGIN | `rol_lectura`         | El rol de gerencia hereda permisos base de lectura desde `rol_lectura`.       |
| `walter_admin_seguridad` | LOGIN   | `admin_seguridad`     | Usuario administrador del área de seguridad.                                  |
| `walter_admin_ventas`    | LOGIN   | `admin_ventas`        | Usuario administrador del área de ventas.                                     |
| `walter_lectura`         | LOGIN   | `rol_lectura`         | Usuario de solo lectura para pruebas de acceso limitado.                      |

---

## 4. Clasificación funcional de roles

### Roles administrativos por esquema

| Rol               | Esquema asociado | Función                                                                              |
| ----------------- | ---------------- | ------------------------------------------------------------------------------------ |
| `admin_clientes`  | `clientes`       | Administración de objetos relacionados con clientes, líneas, consumo y dispositivos. |
| `admin_finanzas`  | `finanzas`       | Administración de objetos financieros como facturas, recargas, préstamos y pagos.    |
| `admin_rrhh`      | `rrhh`           | Administración de objetos relacionados con empleados y recursos humanos.             |
| `admin_seguridad` | `seguridad`      | Administración de objetos de seguridad, usuarios y asignaciones internas.            |
| `admin_ventas`    | `ventas`         | Administración de planes, paquetes, promociones y ventas.                            |

### Roles funcionales

| Rol             | Tipo    | Función                                                                                         |
| --------------- | ------- | ----------------------------------------------------------------------------------------------- |
| `employee_role` | NOLOGIN | Agrupa permisos para usuarios empleados. Se utiliza para aplicar restricciones y políticas RLS. |
| `analyst_role`  | NOLOGIN | Agrupa permisos de consulta para usuarios analistas.                                            |
| `manager_role`  | NOLOGIN | Agrupa permisos para usuarios de gerencia o supervisión.                                        |
| `rol_lectura`   | NOLOGIN | Rol base para usuarios con acceso únicamente de lectura.                                        |

### Usuarios finales

| Usuario                  | Rol asignado         | Función                                                                        |
| ------------------------ | -------------------- | ------------------------------------------------------------------------------ |
| `empleado_306`           | `employee_role`      | Usuario empleado con acceso limitado.                                          |
| `empleado_307`           | `employee_role`      | Usuario empleado con acceso limitado.                                          |
| `analista_ventas`        | `analyst_role`       | Usuario analista de ventas.                                                    |
| `sergio_analista`        | `analyst_role`       | Usuario analista.                                                              |
| `gerente_general`        | `manager_role`       | Usuario de gerencia.                                                           |
| `walter_admin_ventas`    | `admin_ventas`       | Usuario administrador del esquema de ventas.                                   |
| `walter_admin_seguridad` | `admin_seguridad`    | Usuario administrador del esquema de seguridad.                                |
| `walter_lectura`         | `rol_lectura`        | Usuario de solo lectura.                                                       |
| `laravel_gui`            | Sin grupo registrado | Usuario técnico usado por Laravel/Filament para conexión con la base de datos. |

---

## 5. Evidencia de principio de mínimo privilegio

A partir de la revisión de roles se observa que:

* Solo el rol `postgres` posee privilegios de superusuario.
* Los roles funcionales como `employee_role`, `analyst_role`, `manager_role` y `rol_lectura` no tienen LOGIN directo.
* Los roles administrativos por esquema tampoco tienen LOGIN directo.
* Los usuarios reales heredan permisos desde roles de grupo.
* Ningún usuario final tiene permisos de `SUPERUSER`, `CREATEDB` o `CREATEROLE`.
* La separación permite controlar mejor los accesos por área y función.

---

## 6. Consultas usadas como evidencia

### Listar roles y atributos

```sql
\du+
```

### Verificar privilegios globales

```sql
SELECT rolname, rolcanlogin, rolsuper, rolcreatedb, rolcreaterole
FROM pg_roles
WHERE rolname NOT LIKE 'pg_%';
```

### Verificar membresías entre usuarios y roles

```sql
SELECT
    usuario.rolname AS usuario_o_rol,
    CASE
        WHEN usuario.rolcanlogin THEN 'LOGIN'
        ELSE 'NOLOGIN'
    END AS tipo_usuario,
    grupo.rolname AS pertenece_a_rol_grupo
FROM pg_auth_members m
JOIN pg_roles grupo ON grupo.oid = m.roleid
JOIN pg_roles usuario ON usuario.oid = m.member
WHERE usuario.rolname NOT LIKE 'pg_%'
ORDER BY usuario.rolname;
```

---

## 7. Conclusión

La base de datos `Viva` cuenta con una estructura de roles separada por función, lo que fortalece la seguridad interna y facilita la administración de permisos.
La configuración evita el uso innecesario de superusuarios, separa usuarios reales de roles de permisos y permite aplicar controles como RLS, permisos por esquema y acceso limitado según responsabilidades.
