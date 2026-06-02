
--------------------------------------------------------------------------------
# Proyecto de Seguridad: Base de Datos Viva (PostgreSQL 17)

Este repositorio contiene la implementación técnica de una estrategia de **Defensa en Profundidad** aplicada a una base de datos de telecomunicaciones denominada **Viva**. El proyecto se centra en el endurecimiento (*hardening*) del sistema mediante el aislamiento de datos y el control de acceso granular.

## 🚀 Entorno Técnico
* **Motor:** PostgreSQL 17
* **Infraestructura:** Contenedores Docker sobre WSL2 (Windows Subsystem for Linux)
* **Arquitectura:** Segregación por esquemas y jerarquía de roles funcionales [1, 2].

## 🛡️ Pilares de Seguridad Implementados

### 1. Gestión de Identidades y Roles (PoLP)
Se ha implementado una arquitectura donde la administración de permisos se gestiona a través de **Roles de Grupo** con el atributo `NOLOGIN` (Cannot login). Esto reduce la superficie de ataque al impedir conexiones directas con roles estructurales [3, 4].

*   **`manager_role`**: Acceso estratégico y de auditoría total [5, 6].
*   **`analyst_role`**: Orientado a Business Intelligence (BI) mediante vistas seguras [7, 8].
*   **`employee_role`**: Personal operativo con permisos restringidos de inserción y lectura [6, 7].
*   **`rol_lectura`**: Perfil de auditoría puramente consultivo [9, 10].

### 2. Aislamiento por Esquemas
Los datos se han organizado en esquemas lógicos, cada uno con un **Dueño (Owner)** administrativo específico, delegando la responsabilidad del superusuario `postgres` a administradores de área [11-13].

| Esquema | Responsabilidad | Dueño |
| :--- | :--- | :--- |
| `clientes` | Información de Identificación Personal (PII) | `admin_clientes` |
| `ventas` | Catálogos de planes, paquetes y promociones | `admin_ventas` |
| `finanzas` | Facturación, recargas y saldos | `admin_finanzas` |
| `rrhh` | Datos sensibles del personal y nómina | `admin_rrhh` |

### 3. Seguridad a Nivel de Fila (RLS)
Se activó el motor de RLS para garantizar que los usuarios solo accedan a los registros que les corresponden. Por ejemplo, en el esquema de ventas, los empleados solo visualizan transacciones activas o asignadas [14, 15].

```sql
-- Ejemplo de política RLS para empleados
CREATE POLICY policy_employee_self_service ON rrhh.employee
    FOR SELECT TO employee_role
    USING (nombre = current_user); -- El usuario solo ve su propia fila
