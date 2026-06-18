# Matriz de Roles

## Objetivo

Definir los roles implementados en PostgreSQL para garantizar la separación de funciones, el principio de mínimo privilegio y el control de acceso a los distintos esquemas de la base de datos Viva.

---

# Roles Identificados

La siguiente consulta permitió identificar los roles existentes en la base de datos:

```sql
SELECT rolname
FROM pg_roles
ORDER BY rolname;
```

Roles encontrados:

* admin_clientes
* admin_finanzas
* admin_rrhh
* admin_seguridad
* admin_ventas
* analista_ventas
* gerente_general
* rol_lectura
* walter_admin_seguridad
* walter_admin_ventas
* walter_lectura
* empleado_306
* empleado_307
* postgres

---

# Matriz de Acceso por Dominio

| Rol             | Clientes             | Finanzas             | RRHH                 | Ventas               | Auditoría            |
| --------------- | -------------------- | -------------------- | -------------------- | -------------------- | -------------------- |
| admin_clientes  | Administración total | No                   | No                   | No                   | Lectura              |
| admin_finanzas  | No                   | Administración total | No                   | No                   | Lectura              |
| admin_rrhh      | No                   | No                   | Administración total | No                   | Lectura              |
| admin_ventas    | No                   | No                   | No                   | Administración total | Lectura              |
| admin_seguridad | Lectura              | Lectura              | Lectura              | Lectura              | Administración       |
| analista_ventas | No                   | No                   | No                   | Lectura              | No                   |
| gerente_general | Lectura              | Lectura              | Lectura              | Lectura              | No                   |
| rol_lectura     | Lectura              | Lectura              | Lectura              | Lectura              | No                   |
| postgres        | Administración total | Administración total | Administración total | Administración total | Administración total |

---

# Principio de Mínimo Privilegio

La configuración fue diseñada siguiendo el principio de mínimo privilegio, otorgando únicamente los permisos necesarios para el desempeño de cada función.

Los usuarios administrativos poseen privilegios únicamente sobre los esquemas correspondientes a su área funcional, evitando accesos innecesarios a información de otros dominios.

---

# Separación de Funciones

La separación de funciones se implementó mediante esquemas independientes:

* clientes
* finanzas
* rrhh
* ventas
* auditoria

Cada esquema posee responsables específicos y privilegios asignados según sus competencias.

---

# Roles de Auditoría

El esquema de auditoría almacena información relacionada con:

* Auditoría DML
* Auditoría DDL
* Registros generados por pgAudit

El acceso administrativo a esta información se encuentra restringido a los responsables de seguridad y administración de base de datos.

---

# Beneficios

* Reducción del riesgo de acceso indebido.
* Control granular de permisos.
* Trazabilidad de actividades.
* Separación de responsabilidades.
* Cumplimiento de buenas prácticas de seguridad.
