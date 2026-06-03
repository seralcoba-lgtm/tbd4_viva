# Evidencias de Pruebas

## Prueba INSERT

Resultado registrado:

- tipo_operacion = INSERT
- datos_anteriores = NULL
- datos_nuevos = Registro creado

## Prueba UPDATE

Resultado registrado:

- tipo_operacion = UPDATE
- datos_anteriores = Valores anteriores
- datos_nuevos = Valores actualizados

Ejemplo observado:

- Email anterior: juan@gmail.com
- Email nuevo: juan_actualizado@gmail.com

## Prueba DELETE

Resultado registrado:

- tipo_operacion = DELETE
- datos_anteriores = Registro eliminado
- datos_nuevos = NULL

## Conclusión

Las operaciones INSERT, UPDATE y DELETE fueron registradas correctamente mediante el mecanismo de auditoría implementado con triggers y la función fn_auditoria_dml().
