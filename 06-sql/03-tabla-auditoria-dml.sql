CREATE TABLE auditoria_dml (
    id_auditoria SERIAL PRIMARY KEY,
    nombre_tabla VARCHAR(100) NOT NULL,
    tipo_operacion VARCHAR(10) NOT NULL,
    usuario_bd VARCHAR(100) DEFAULT CURRENT_USER,
    fecha_evento TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    datos_anteriores JSONB,
    datos_nuevos JSONB
);
