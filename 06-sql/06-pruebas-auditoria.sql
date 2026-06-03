INSERT INTO cliente (
    tipo_cliente,
    nombre,
    apellidos,
    doc_identidad,
    email,
    direccion,
    fecha_registro,
    antiguedad_dias
)
VALUES (
    'PERSONA',
    'Juan',
    'Perez',
    '12345678',
    'juan@gmail.com',
    'Cochabamba',
    CURRENT_DATE,
    0
);

UPDATE cliente
SET email = 'juan_actualizado@gmail.com'
WHERE id_cliente = 1;

DELETE FROM cliente
WHERE id_cliente = 1;

SELECT *
FROM auditoria_dml
ORDER BY id_auditoria;
