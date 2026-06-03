CREATE OR REPLACE FUNCTION fn_auditoria_dml()
RETURNS TRIGGER AS
$$
BEGIN

    INSERT INTO auditoria_dml (
        nombre_tabla,
        tipo_operacion,
        usuario_bd,
        fecha_evento,
        datos_anteriores,
        datos_nuevos
    )
    VALUES (
        TG_TABLE_NAME,
        TG_OP,
        CURRENT_USER,
        CURRENT_TIMESTAMP,
        to_jsonb(OLD),
        to_jsonb(NEW)
    );

    IF TG_OP = 'DELETE' THEN
        RETURN OLD;
    ELSE
        RETURN NEW;
    END IF;

END;
$$ LANGUAGE plpgsql;
