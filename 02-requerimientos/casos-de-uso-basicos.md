
## 📂 Casos de Uso Basicos

A continuación se detallan situaciones reales del negocio y cómo actúan las barreras de seguridad.

### 1. Caso de Uso: Operaciones de Atención al Cliente
*   **Actor:** `employee_role`.
*   **Situación:** Consultar el catálogo de planes comerciales.
*   **Control:** El empleado tiene permiso `SELECT` en las tablas de `ventas`, pero no puede ver la columna `tarifa_mensual` o `precio` mediante CLS para evitar negociaciones no autorizadas [19, 22, 23].
*   **Resultado:** El sistema bloquea un `SELECT *` lanzando un error de "Permiso Denegado", obligando al uso de columnas permitidas [24, 25].

### 2. Caso de Uso: Análisis de Tendencias (Business Intelligence)
*   **Actor:** `analyst_role`.
*   **Situación:** Generar un reporte de ventas sin exponer datos personales.
*   **Control:** Uso de **Vistas Seguras**. En lugar de acceder a la tabla base, el analista consulta vistas que enmascaran el **IMEI** o el **Doc_Identidad** [26-28].
*   **Resultado:** Los reportes en herramientas de BI no fallan, pero los datos sensibles aparecen como `****-****-1234` [29].

### 3. Caso de Uso: Privacidad de Recursos Humanos
*   **Actor:** Cualquier miembro del `employee_role`.
*   **Situación:** Intentar consultar el salario de un compañero.
*   **Control:** Política RLS `USING (nombre = current_user)`. La base de datos reescribe la consulta para que el usuario solo vea su propio registro [20, 30, 31].
*   **Resultado:** La consulta devuelve cero registros si el usuario intenta filtrar por un tercero, garantizando aislamiento total [32].

---

## 📊 Resumen de Controles por Rol

| Actividad | `employee_role` | `analyst_role` | `manager_role` |
| :--- | :--- | :--- | :--- |
| **Acceso a PII** | Bloqueado (CLS) | Enmascarado (View) | Permitido |
| **Borrados** | Denegado | Denegado | Denegado |
| **Vistas Seguras** | No requerido | Obligatorio | Opcional |
| **RLS Activo** | Sí (Self-service) | No (Global) | No (Auditoría) |

---

## 🔍 Verificación (Prueba de Fuego)
Para validar estas políticas, se utilizan comandos de diagnóstico y personificación de roles [33-35]:

```sql
-- Verificar matriz de privilegios
\dp clientes.cliente

-- Simular el comportamiento de un empleado
SET ROLE employee_role;
SELECT * FROM rrhh.employee; -- Debería fallar o filtrar filas
RESET ROLE;
