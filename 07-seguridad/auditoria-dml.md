# Auditoría DML Mediante Triggers

## Objetivo

Registrar automáticamente las operaciones INSERT, UPDATE y DELETE realizadas sobre las tablas de la base de datos.

## Tabla de Auditoría

```sql
CREATE TABLE auditoria_dml (
    id_auditoria SERIAL PRIMARY KEY,
    nombre_tabla VARCHAR(100) NOT NULL,
    tipo_operacion VARCHAR(10) NOT NULL,
    usuario_bd VARCHAR(100) DEFAULT CURRENT_USER,
    fecha_evento TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    datos_anteriores JSONB,
    datos_nuevos JSONB
);
```

## Función de Auditoría

La función utiliza las variables especiales OLD y NEW para capturar el estado anterior y posterior de los registros.

## Trigger

```sql
CREATE TRIGGER trg_auditoria_cliente
AFTER INSERT OR UPDATE OR DELETE
ON cliente
FOR EACH ROW
EXECUTE FUNCTION fn_auditoria_dml();
```

## Uso de OLD y NEW

### INSERT

- OLD = NULL
- NEW = Registro insertado

### UPDATE

- OLD = Valores anteriores
- NEW = Valores modificados

### DELETE

- OLD = Registro eliminado
- NEW = NULL

## Beneficios

- Seguimiento de cambios realizados.
- Historial de modificaciones.
- Evidencia para auditorías.
