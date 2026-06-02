
--------------------------------------------------------------------------------
📂 Escenarios y Casos de Uso de Seguridad
Esta sección detalla cómo los diferentes roles interactúan con la base de datos Viva bajo las restricciones de seguridad implementadas (RLS, CLS y Vistas Seguras).
1. Caso de Uso: Atención al Cliente (Operaciones Diarias)
Actor: employee_role (Personal Operativo).
Objetivo: Consultar información del cliente para gestionar un reclamo o servicio.
Control de Seguridad: Seguridad a Nivel de Columna (CLS).
Interacción Técnica:
El empleado intenta: SELECT * FROM clientes.cliente;.
Resultado: ERROR (Permiso Denegado). El sistema bloquea el asterisco porque intenta acceder a la columna protegida doc_identidad (PII)
.
El empleado debe ejecutar: SELECT nombre, apellidos, email FROM clientes.cliente;.
Resultado: ÉXITO. Solo accede a los datos necesarios para la gestión operativa sin exponer el documento de identidad
.
2. Caso de Uso: Análisis de Dispositivos (Business Intelligence)
Actor: analyst_role (Analista de Datos).
Objetivo: Identificar los modelos de teléfonos más vendidos para un reporte en PowerBI.
Control de Seguridad: Vistas Seguras con Enmascaramiento.
Interacción Técnica:
El analista consulta la vista: SELECT * FROM clientes.vw_dispositivos_seguros;.
Resultado: El campo imei aparece transformado (ej: ****-****-1234).
Beneficio: Se permite el análisis de tendencias por marca y modelo sin exponer identificadores únicos de hardware que podrían ser usados de forma maliciosa
.
3. Caso de Uso: Auditoría Estratégica de Nómina
Actor: manager_role (Gerente de Área).
Objetivo: Revisar los salarios del departamento de ventas para aprobar bonos.
Control de Seguridad: Privilegios de Supervisión Controlados.
Interacción Técnica:
Un usuario real (ej. director_comercial) que hereda de manager_role ejecuta: SELECT nombre, salario FROM rrhh.employee;.
Resultado: ÉXITO. A diferencia de los otros roles, el gerente tiene visibilidad sobre la columna salario debido a su función estratégica
.
Restricción Adicional: Si el gerente intenta ejecutar DELETE FROM rrhh.employee;, el sistema arroja Permiso Denegado, ya que solo el superusuario puede realizar borrados masivos en tablas maestras
.
4. Caso de Uso: Privacidad del Empleado (Autogestión)
Actor: Usuario individual (miembro de employee_role).
Objetivo: Consultar sus propios datos personales en el esquema de Recursos Humanos.
Control de Seguridad: Seguridad a Nivel de Fila (RLS).
Interacción Técnica:
El empleado "juan_perez" ejecuta: SELECT * FROM rrhh.employee;.
Resultado Dinámico: El motor de PostgreSQL aplica automáticamente el filtro USING (nombre = current_user). Juan solo ve su propia fila
.
Resultado: Si Juan intenta buscar los datos de su jefe, el resultado será de cero filas, garantizando el aislamiento total de datos sensibles entre compañeros
.

--------------------------------------------------------------------------------
📊 Resumen de Controles por Rol
Rol
Esquemas Permitidos
Restricción Clave
Herramienta Principal
employee_role
Clientes, Ventas, Finanzas
No ve PII ni saldos iniciales
CLS Nativo (GRANT selectivo)
analyst_role
Clientes, Ventas, Finanzas
Datos enmascarados/anonimizados
Vistas Seguras (CREATE VIEW)
manager_role
Todos los esquemas
Visibilidad total, pero sin borrado
Privilegios de Tabla (TLS)
rol_lectura
Todos los esquemas
No puede insertar ni modificar nada
Privilegio SELECT Global

--------------------------------------------------------------------------------
🔍 Verificación de los Casos (Prueba de Fuego)
Para validar cualquiera de estos casos en el entorno de desarrollo, utiliza el comando de personificación:
-- Simular el comportamiento de un empleado
SET ROLE employee_role;
SELECT * FROM clientes.cliente; -- Debería fallar
SELECT nombre FROM clientes.cliente; -- Debería funcionar
RESET ROLE;
