CREATE TABLE cliente (
    id_cliente SERIAL PRIMARY KEY,
    tipo_cliente VARCHAR(20),
    nombre VARCHAR(100),
    apellidos VARCHAR(100),
    doc_identidad VARCHAR(30),
    email VARCHAR(100),
    direccion VARCHAR(200),
    fecha_registro DATE,
    antiguedad_dias INTEGER
);

CREATE TRIGGER trg_auditoria_cliente
AFTER INSERT OR UPDATE OR DELETE
ON cliente
FOR EACH ROW
EXECUTE FUNCTION fn_auditoria_dml();
