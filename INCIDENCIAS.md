# Registro de incidencias – APE 2 (gestion_investigacion)

| # | Incidencia | Causa | Solución | Estado |
|---|---|---|---|---|
| 1 | En `sp_ca1_productividad_proyectos` la fila del total general aparecía como "Subtotal". | Con `WITH ROLLUP` la etiqueta se calculaba en el mismo SELECT y MariaDB no tiene `GROUPING()`. | Agrupar en una tabla derivada y calcular las etiquetas en la consulta externa. | Cerrada |
| 2 | Las tildes se guardaban mal ("MarÃ­a") y los mensajes de los triggers salían como "mÃ¡ximo". | El cliente se conectaba con `latin1` y los datos quedaban con doble codificación. | Ejecutar los scripts en `utf8mb4` (utf-8 en phpMyAdmin) y volver a crear la base. | Cerrada |
| 3 | `sp_ca5_estado_participaciones` mostraba días restantes negativos (-1002). | `DATEDIFF` devuelve negativos cuando la fecha de fin ya pasó. | Usar `GREATEST(DATEDIFF(...), 0)` y "Indefinido" cuando no hay fecha de fin. | Cerrada |
| 4 | `sp_cm5_catalogo_productos` mostraba NULL en la fecha de las revistas. | La tabla `revista` del modelo físico no tiene campo de fecha. | Mostrar "No registra" con `IFNULL`, sin modificar el modelo. | Cerrada |
| 5 | Los títulos largos dificultaban la lectura de los resultados. | `titulo` y `nombre_proyecto` llegan a 255 caracteres. | Mostrarlos resumidos con `LEFT()` en los reportes. | Cerrada |
| 6 | Error #1305: FUNCTION fn_tipo_producto does not exist al ejecutar sp_ca1 en phpMyAdmin. | Se creó el procedimiento antes que las funciones que usa. | Crear primero las 4 funciones y después los procedimientos. | Cerrada |
| 7 | Error #1044: acceso denegado a information_schema al crear las funciones. | La consulta de verificación hizo que phpMyAdmin cambiara de base. | Escribir `gestion_investigacion.` antes de cada función y quitar la consulta del script. | Cerrada |
| 8 | Error #1304: FUNCTION fn_tipo_producto already exists. | Se intentó crear de nuevo una función existente. | Usar `DROP FUNCTION IF EXISTS` antes de cada `CREATE FUNCTION`. | Cerrada |
| 9 | Error #2014: Commands out of sync al ejecutar el script completo en la pestaña SQL. | phpMyAdmin no procesa varias sentencias `CALL` con resultados en una sola ejecución. | Separar en `APE2_instalacion.sql` y `APE2_consultas_y_pruebas.sql`. | Cerrada |
