# Semana 1: Fundamentos y Hardening Inicial en PostgreSQL

## Proyecto: Base de datos `Viva`

Este documento presenta la evidencia técnica correspondiente a la **Semana 1: Fundamentos y Hardening Inicial** del proyecto de seguridad en PostgreSQL.
El objetivo principal de esta etapa fue aplicar configuraciones iniciales de seguridad, restringir accesos de red, endurecer el archivo `pg_hba.conf`, crear roles separados por función, revocar permisos públicos y documentar el checklist de controles aplicados.

---

## 1. Instalación y configuración de red

PostgreSQL se encuentra instalado y ejecutándose dentro de un entorno Docker, utilizando la base de datos principal llamada `Viva`.

Uno de los parámetros revisados fue:

```sql
SHOW listen_addresses;
```

Este parámetro define desde qué interfaces de red PostgreSQL acepta conexiones.

### Resultado inicial observado

```sql
SHOW listen_addresses;
```

Resultado:

```text
listen_addresses
------------------
*
```

El valor `*` significa que PostgreSQL escucha conexiones desde todas las interfaces de red disponibles.
Esto permite conexiones locales y también conexiones externas, siempre que el firewall, Docker, Azure y `pg_hba.conf` lo permitan.

Desde el punto de vista de hardening, una configuración más restrictiva sería:

```conf
listen_addresses = '127.0.0.1'
```

Con esta configuración, PostgreSQL solo acepta conexiones desde la misma máquina, reduciendo la exposición de la base de datos frente a accesos externos no autorizados.

### Evidencia


![Configuración de listen_addresses](imagenes/Captura%20de%20pantalla%202026-06-21%20222833.png)
![Configuración de listen\_addresses](imagenes/Captura%20de%20pantalla%202026-06-22%20173744.png)

### Justificación

La revisión de `listen_addresses` permite controlar la exposición de PostgreSQL a la red.
Para un entorno seguro, se recomienda limitar la escucha a `127.0.0.1` cuando la aplicación y la base de datos se encuentran en el mismo servidor.
Si la aplicación Laravel/Filament necesita conectarse desde otro entorno, puede utilizarse `*`, pero acompañado de reglas estrictas en `pg_hba.conf`, autenticación segura y control mediante firewall.

---

## 2. Hardening del archivo `pg_hba.conf`

El archivo `pg_hba.conf` controla las reglas de autenticación de PostgreSQL.
Su nombre significa **PostgreSQL Host-Based Authentication**, es decir, autenticación basada en host.

Este archivo define:

| Campo      | Descripción                                  |
| ---------- | -------------------------------------------- |
| `TYPE`     | Tipo de conexión: local, host, hostssl, etc. |
| `DATABASE` | Base de datos a la que aplica la regla.      |
| `USER`     | Usuario o rol al que aplica la regla.        |
| `ADDRESS`  | Dirección IP permitida.                      |
| `METHOD`   | Método de autenticación utilizado.           |

### Configuración observada inicialmente

```conf
# TYPE  DATABASE        USER            ADDRESS                 METHOD

local   all             all                                     trust

# IPv4 local connections:
host    all             all             127.0.0.1/32            trust

# IPv6 local connections:
host    all             all             ::1/128                 trust

# Allow replication connections from localhost, by a user with the
# replication privilege.
local   replication     all                                     trust
host    replication     all             127.0.0.1/32            trust
host    replication     all             ::1/128                 trust
```

### Problema identificado

El método `trust` permite que un usuario se conecte sin contraseña cuando la conexión coincide con la regla.
Esto representa un riesgo de seguridad, porque cualquier usuario del entorno permitido podría intentar ingresar a la base de datos sin autenticación real.

### Cambio aplicado o recomendado

Se reemplaza `trust` por `scram-sha-256`:

```conf
local   all             all                                     scram-sha-256
host    all             all             127.0.0.1/32            scram-sha-256
host    all             all             ::1/128                 scram-sha-256

local   replication     all                                     scram-sha-256
host    replication     all             127.0.0.1/32            scram-sha-256
host    replication     all             ::1/128                 scram-sha-256
```

### Significado de `scram-sha-256`

| Término | Significado                                        |
| ------- | -------------------------------------------------- |
| `SCRAM` | Salted Challenge Response Authentication Mechanism |
| `SHA`   | Secure Hash Algorithm                              |
| `256`   | Longitud criptográfica de 256 bits                 |

`scram-sha-256` es un método moderno de autenticación que exige contraseña y evita el uso de contraseñas en texto plano.

### Evidencia

![Configuración de listen\_addresses](imagenes/Captura%20de%20pantalla%202026-06-21%20223050.png)
![Configuración de listen\_addresses](imagenes/Captura%20de%20pantalla%202026-06-22%20173929.png)



### Explicación de reglas

| Regla                                             | Explicación                                                       |
| ------------------------------------------------- | ----------------------------------------------------------------- |
| `local all all scram-sha-256`                     | Toda conexión local por socket Unix requiere contraseña segura.   |
| `host all all 127.0.0.1/32 scram-sha-256`         | Toda conexión IPv4 desde localhost requiere autenticación segura. |
| `host all all ::1/128 scram-sha-256`              | Toda conexión IPv6 desde localhost requiere autenticación segura. |
| `local replication all scram-sha-256`             | La replicación local también requiere autenticación segura.       |
| `host replication all 127.0.0.1/32 scram-sha-256` | La replicación desde IPv4 local requiere contraseña.              |
| `host replication all ::1/128 scram-sha-256`      | La replicación desde IPv6 local requiere contraseña.              |

---

## 3. Creación de roles separados por función

Se implementó una separación de roles para cumplir con el principio de mínimo privilegio.
La base de datos diferencia entre usuarios reales con `LOGIN` y roles de grupo `NOLOGIN`.

Los roles `NOLOGIN` agrupan permisos, mientras que los usuarios con `LOGIN` heredan esos permisos según su función.

### Consulta utilizada para listar membresías

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

### Resultado documentado

| Usuario o rol            | Tipo    | Pertenece a rol de grupo |
| ------------------------ | ------- | ------------------------ |
| `analista_ventas`        | LOGIN   | `analyst_role`           |
| `empleado_306`           | LOGIN   | `employee_role`          |
| `empleado_307`           | LOGIN   | `employee_role`          |
| `gerente_general`        | LOGIN   | `manager_role`           |
| `manager_role`           | NOLOGIN | `rol_lectura`            |
| `sergio_analista`        | LOGIN   | `analyst_role`           |
| `walter_admin_seguridad` | LOGIN   | `admin_seguridad`        |
| `walter_admin_ventas`    | LOGIN   | `admin_ventas`           |
| `walter_lectura`         | LOGIN   | `rol_lectura`            |

### Evidencia

![Membresía de usuarios y roles](![Listado de roles con \du+](imagenes/Captura%20de%20pantalla%202026-06-22%20180443.png))

---

## 4. Tabla general de roles de la base de datos

La siguiente tabla documenta los roles principales encontrados en la base de datos `Viva`.

| Rol / Usuario            | Tipo    | Superusuario | Crea BD | Crea roles | Propósito                                                                                                                |
| ------------------------ | ------- | ------------ | ------- | ---------- | ------------------------------------------------------------------------------------------------------------------------ |
| `postgres`               | LOGIN   | Sí           | Sí      | Sí         | Superusuario principal. Se reserva para tareas críticas de administración, backup, restauración y configuración general. |
| `admin_clientes`         | NOLOGIN | No           | No      | No         | Rol administrativo para objetos del esquema `clientes`.                                                                  |
| `admin_finanzas`         | NOLOGIN | No           | No      | No         | Rol administrativo para objetos del esquema `finanzas`.                                                                  |
| `admin_rrhh`             | NOLOGIN | No           | No      | No         | Rol administrativo para objetos del esquema `rrhh`.                                                                      |
| `admin_seguridad`        | NOLOGIN | No           | No      | No         | Rol administrativo para objetos del esquema `seguridad`.                                                                 |
| `admin_ventas`           | NOLOGIN | No           | No      | No         | Rol administrativo para objetos del esquema `ventas`.                                                                    |
| `analyst_role`           | NOLOGIN | No           | No      | No         | Rol de grupo para analistas. Permite consulta de información para reportes y análisis.                                   |
| `employee_role`          | NOLOGIN | No           | No      | No         | Rol de grupo para empleados. Se usa con permisos limitados y políticas RLS.                                              |
| `manager_role`           | NOLOGIN | No           | No      | No         | Rol de grupo para gerencia. Hereda permisos de lectura desde `rol_lectura`.                                              |
| `rol_lectura`            | NOLOGIN | No           | No      | No         | Rol base para usuarios con acceso de solo lectura.                                                                       |
| `analista_ventas`        | LOGIN   | No           | No      | No         | Usuario final de análisis de ventas. Hereda permisos desde `analyst_role`.                                               |
| `sergio_analista`        | LOGIN   | No           | No      | No         | Usuario analista. Hereda permisos desde `analyst_role`.                                                                  |
| `empleado_306`           | LOGIN   | No           | No      | No         | Usuario empleado con acceso limitado mediante `employee_role`.                                                           |
| `empleado_307`           | LOGIN   | No           | No      | No         | Usuario empleado con acceso limitado mediante `employee_role`.                                                           |
| `gerente_general`        | LOGIN   | No           | No      | No         | Usuario de gerencia. Hereda permisos desde `manager_role`.                                                               |
| `walter_admin_seguridad` | LOGIN   | No           | No      | No         | Usuario administrador del área de seguridad. Hereda permisos desde `admin_seguridad`.                                    |
| `walter_admin_ventas`    | LOGIN   | No           | No      | No         | Usuario administrador del área de ventas. Hereda permisos desde `admin_ventas`.                                          |
| `walter_lectura`         | LOGIN   | No           | No      | No         | Usuario limitado de solo lectura. Hereda permisos desde `rol_lectura`.                                                   |
| `laravel_gui`            | LOGIN   | No           | No      | No         | Usuario técnico usado por Laravel/Filament para conectarse a la base de datos.                                           |
| `admin-role`             | LOGIN   | No           | No      | No         | Usuario o rol administrativo general sin privilegios globales.                                                           |

### Evidencia del listado de roles

Consulta utilizada:

```sql
\du+
```

![Listado de roles con \du+](imagenes/Captura%20de%20pantalla%202026-06-22%20180828.png)

Consulta utilizada:

```sql
SELECT rolname, rolcanlogin, rolsuper, rolcreatedb, rolcreaterole
FROM pg_roles
WHERE rolname NOT LIKE 'pg_%';
```

![Privilegios globales de roles](imagenes/Captura%20de%20pantalla%202026-06-22%20180902.png)

### Análisis de mínimo privilegio

A partir de la revisión de roles se observa que:

* Solo `postgres` tiene permisos de superusuario.
* Los usuarios finales no tienen permisos `SUPERUSER`.
* Los usuarios finales no tienen permisos `CREATEDB`.
* Los usuarios finales no tienen permisos `CREATEROLE`.
* Los roles funcionales como `employee_role`, `analyst_role`, `manager_role` y `rol_lectura` son `NOLOGIN`.
* Los usuarios reales heredan permisos desde roles de grupo.
* La estructura permite separar responsabilidades por área y función.

---

## 5. Revocación de permisos públicos

Como parte del hardening inicial, se aplicó la revocación de permisos públicos sobre el esquema `public`.

### Comando aplicado

```sql
REVOKE ALL ON SCHEMA public FROM PUBLIC;
```

Este comando elimina los permisos generales que todos los usuarios reciben por medio del grupo implícito `PUBLIC`.

En PostgreSQL, `PUBLIC` representa a todos los usuarios de la base de datos.
Revocar permisos a `PUBLIC` permite evitar que cualquier usuario pueda usar o crear objetos libremente en el esquema `public`.

### Verificación con `\dn+ public`

```sql
\dn+ public
```

Resultado observado:

```text
Name   | Owner             | Access privileges
-------+-------------------+----------------------------------------
public | pg_database_owner | pg_database_owner=UC/pg_database_owner
       |                   | laravel_gui=U/pg_database_owner
```

### Verificación con consulta SQL

```sql
SELECT
    nspname AS esquema,
    nspacl AS permisos
FROM pg_namespace
WHERE nspname = 'public';
```

Resultado observado:

```text
esquema | permisos
--------+-----------------------------------------------------------------------
public  | {pg_database_owner=UC/pg_database_owner,laravel_gui=U/pg_database_owner}
```

### Interpretación

| Valor                  | Significado                                                      |
| ---------------------- | ---------------------------------------------------------------- |
| `U`                    | USAGE: permite usar el esquema.                                  |
| `C`                    | CREATE: permite crear objetos en el esquema.                     |
| `UC`                   | Tiene permisos de uso y creación.                                |
| `pg_database_owner=UC` | El dueño de la base conserva permisos de uso y creación.         |
| `laravel_gui=U`        | El usuario Laravel conserva permiso de uso, pero no de creación. |
| No aparece `PUBLIC`    | Los permisos públicos fueron revocados correctamente.            |

### Evidencia

![Revocación de permisos públicos](imagenes/Captura%20de%20pantalla%202026-06-22%20180958.png)

### Prueba recomendada con usuario limitado

Para demostrar que la revocación funciona, se recomienda ingresar con un usuario limitado:

```bash
sudo docker exec -it postgres-viva psql -U empleado_306 -d Viva
```

Luego intentar crear una tabla en el esquema `public`:

```sql
CREATE TABLE public.prueba_permiso (
    id INT
);
```

El resultado esperado es:

```text
ERROR: permission denied for schema public
```

### Evidencia de prueba con usuario limitado

![Usuario limitado sin permiso en public](imagenes/Captura%20de%20pantalla%202026-06-22%20181053.png)

---

## 6. Evidencia de conexión con usuario limitado

Para validar que existen usuarios sin privilegios administrativos, se realizó una prueba de conexión con un usuario limitado.

Ejemplo de conexión:

```bash
sudo docker exec -it postgres-viva psql -U empleado_306 -d Viva
```

Dentro de PostgreSQL:

```sql
SELECT current_user;
```

Resultado esperado:

```text
current_user
--------------
empleado_306
```

También se puede demostrar que el usuario no puede crear bases de datos:

```sql
CREATE DATABASE prueba_empleado;
```

Resultado esperado:

```text
ERROR: permission denied to create database
```

### Evidencia

![Conexión con usuario limitado](imagenes/Captura%20de%20pantalla%202026-06-22%20182705.png)

---

## 7. Checklist de hardening aplicado

| Control aplicado                          | Estado             | Evidencia                                                       |
| ----------------------------------------- | ------------------ | --------------------------------------------------------------- |
| PostgreSQL instalado correctamente        | Aplicado           | Contenedor PostgreSQL en ejecución.                             |
| Base de datos `Viva` creada y funcional   | Aplicado           | Conexión exitosa mediante `psql`.                               |
| Revisión de `listen_addresses`            | Aplicado           | Captura de `SHOW listen_addresses;`.                            |
| Configuración de red documentada          | Aplicado           | Explicación del valor `*` y recomendación de `127.0.0.1`.       |
| Archivo `pg_hba.conf` revisado            | Aplicado           | Captura del archivo.                                            |
| Método `trust` identificado como inseguro | Aplicado           | Explicación del riesgo de conexiones sin contraseña.            |
| Método `scram-sha-256` documentado        | Aplicado           | Explicación del mecanismo seguro de autenticación.              |
| Roles separados por función               | Aplicado           | Captura de `\du+` y consulta a `pg_roles`.                      |
| Roles de grupo `NOLOGIN`                  | Aplicado           | `employee_role`, `analyst_role`, `manager_role`, `rol_lectura`. |
| Usuarios finales con `LOGIN`              | Aplicado           | `empleado_306`, `empleado_307`, `analista_ventas`, etc.         |
| Usuarios finales sin privilegios globales | Aplicado           | Consulta `rolsuper`, `rolcreatedb`, `rolcreaterole`.            |
| Superusuario reservado para `postgres`    | Aplicado           | Solo `postgres` tiene privilegios administrativos globales.     |
| Permisos públicos revocados               | Aplicado           | `REVOKE ALL ON SCHEMA public FROM PUBLIC;`.                     |
| Verificación del esquema `public`         | Aplicado           | No aparece entrada para `PUBLIC`.                               |
| Usuario limitado probado                  | Pendiente/Aplicado | Captura de conexión con `empleado_306` o `walter_lectura`.      |
| Usuario limitado sin permisos de creación | Pendiente/Aplicado | Captura del error `permission denied`.                          |

---

## 8. Comandos principales utilizados

### Verificar `listen_addresses`

```sql
SHOW listen_addresses;
```

### Modificar `listen_addresses`

```sql
ALTER SYSTEM SET listen_addresses = '127.0.0.1';
```

Después del cambio, reiniciar el contenedor:

```bash
sudo docker restart postgres-viva
```

### Verificar roles

```sql
\du+
```

### Verificar privilegios globales

```sql
SELECT rolname, rolcanlogin, rolsuper, rolcreatedb, rolcreaterole
FROM pg_roles
WHERE rolname NOT LIKE 'pg_%';
```

### Verificar membresías

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

### Revocar permisos públicos

```sql
REVOKE ALL ON SCHEMA public FROM PUBLIC;
```

### Verificar permisos del esquema `public`

```sql
\dn+ public
```

```sql
SELECT
    nspname AS esquema,
    nspacl AS permisos
FROM pg_namespace
WHERE nspname = 'public';
```

---

## 9. Conclusión

Durante la Semana 1 se aplicaron controles iniciales de seguridad sobre PostgreSQL para fortalecer la base de datos `Viva`.

Se revisó la configuración de red mediante `listen_addresses`, se analizó y endureció el archivo `pg_hba.conf`, se documentó la necesidad de reemplazar `trust` por `scram-sha-256`, se verificó la existencia de roles separados por función, se confirmó que los usuarios finales no poseen privilegios administrativos globales y se revocaron permisos públicos sobre el esquema `public`.

Estas acciones permiten cumplir con el principio de mínimo privilegio y reducen la superficie de ataque de la base de datos.
