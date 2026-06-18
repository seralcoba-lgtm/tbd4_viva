# Política de Auditoría

## 1. Objetivo

Establecer los lineamientos para el registro, monitoreo, conservación y revisión de eventos relevantes dentro de la base de datos Viva, garantizando la trazabilidad de las operaciones realizadas sobre la información institucional.

---

# 2. Alcance

La presente política aplica a todos los usuarios, roles, esquemas y objetos administrados dentro de la base de datos PostgreSQL 17 del sistema Viva.

Incluye actividades realizadas sobre los esquemas:

* clientes
* finanzas
* rrhh
* ventas
* auditoria

---

# 3. Mecanismos de Auditoría Implementados

## 3.1 Auditoría DML

Se registran automáticamente las operaciones:

* INSERT
* UPDATE
* DELETE

realizadas sobre las tablas auditadas mediante triggers.

La información es almacenada en:

```text
auditoria.auditoria_dml
```

incluyendo:

* Usuario responsable.
* Fecha y hora del evento.
* Tabla afectada.
* Tipo de operación.
* Datos anteriores.
* Datos nuevos.

---

## 3.2 Auditoría DDL

Se registran modificaciones estructurales realizadas sobre la base de datos, incluyendo:

* CREATE
* ALTER
* DROP

mediante Event Triggers configurados en PostgreSQL.

---

## 3.3 Auditoría Avanzada mediante pgAudit

La extensión pgAudit se encuentra configurada para registrar:

```text
read, write, ddl, role
```

permitiendo auditar:

* Consultas de lectura.
* Operaciones de escritura.
* Cambios estructurales.
* Gestión de roles y privilegios.

---

# 4. Conservación de Registros

Los registros de auditoría deben mantenerse disponibles para análisis y revisión de incidentes de seguridad.

La información almacenada en las tablas de auditoría y archivos de log deberá conservarse de acuerdo con las políticas institucionales de respaldo y recuperación.

---

# 5. Acceso a la Información de Auditoría

El acceso a los registros de auditoría se encuentra restringido a:

* Administradores de Base de Datos.
* Responsables de Seguridad.
* Personal autorizado para actividades de control y supervisión.

Los usuarios operativos no podrán modificar ni eliminar registros de auditoría.

---

# 6. Monitoreo y Revisión

Los registros de auditoría deberán revisarse periódicamente para identificar:

* Accesos no autorizados.
* Cambios estructurales no planificados.
* Modificaciones de datos sensibles.
* Actividades sospechosas.
* Errores operativos.

---

# 7. Responsabilidades

## Administrador de Base de Datos

* Mantener operativos los mecanismos de auditoría.
* Supervisar la generación de logs.
* Verificar la integridad de los registros.

## Responsable de Seguridad

* Revisar eventos relevantes.
* Analizar incidentes detectados.
* Validar el cumplimiento de las políticas establecidas.

---

# 8. Cumplimiento

El incumplimiento de esta política podrá ser considerado una violación de las normas de seguridad y deberá ser reportado para su análisis y tratamiento correspondiente.

---

# 9. Beneficios

* Trazabilidad completa de operaciones.
* Detección temprana de incidentes.
* Evidencia para auditorías internas.
* Control de cambios estructurales.
* Fortalecimiento de la seguridad de la información.
