-- =====================================================================
-- APE 2 - Script 05: Pruebas de integración y control de calidad
-- Cada bloque @@ es un caso de prueba que se ejecuta por separado.
-- =====================================================================
-- @@ P01 | Regla 4 investigadores | Agregar un 5.º investigador a SATCLIMA (debe FALLAR)
INSERT INTO proyecto_profesor (id_proyecto, id_profesor, inicio_pro)
VALUES (2, 12, '2026-10-29');
-- @@ P02 | Director único | Agregar un segundo Director a PLATINV (debe FALLAR)
INSERT INTO proyecto_profesor (id_proyecto, id_profesor, inicio_pro)
VALUES (1, 3, '2026-10-29');
-- @@ P03 | Máximo 2 proyectos | Héctor Sánchez ya está en 2 proyectos y se intenta agregarlo a IOTAGRO (debe FALLAR)
SELECT fn_proyectos_activos(7, '2026-10-29') AS proyectos_activos_hector;
INSERT INTO proyecto_profesor (id_proyecto, id_profesor, inicio_pro)
VALUES (3, 7, '2026-10-29');
-- @@ P04 | Inserción válida | Fausto Escobar (sin proyectos) entra a DATABOL (debe PASAR)
INSERT INTO proyecto_profesor (id_proyecto, id_profesor, inicio_pro)
VALUES (5, 13, '2026-10-29');
CALL sp_cm1_equipo_proyecto(5);
-- @@ P05 | Participación pasada no bloquea | Gabriela Mora (su proyecto ya terminó) entra a IOTAGRO (debe PASAR)
INSERT INTO proyecto_profesor (id_proyecto, id_profesor, inicio_pro, fin_pro)
VALUES (3, 8, '2026-11-01', '2027-10-31');
SELECT id_proyecto, id_profesor, inicio_pro, fin_pro
  FROM proyecto_profesor WHERE id_profesor = 8;
-- @@ P06 | CHECK del modelo físico | Fecha de fin anterior a la de inicio (debe FALLAR)
UPDATE proyecto_profesor SET fin_pro = '2020-01-01'
 WHERE id_proyecto = 5 AND id_profesor = 13;
-- @@ P07 | Auditoría UPDATE | Se cambia el presupuesto de DATABOL
UPDATE proyecto_investigacion SET presupuesto = 11500.00 WHERE id_proyecto = 5;
SELECT id_auditoria, id_proyecto, operacion,
       SUBSTRING_INDEX(datos_anteriores, '; ', -1) AS antes,
       SUBSTRING_INDEX(datos_nuevos, '; ', -1) AS despues, usuario, fecha_hora
  FROM auditoria_proyecto;
-- @@ P08 | Auditoría DELETE | Se elimina CIBERGAD dentro de una transacción y luego se revierte
START TRANSACTION;
DELETE FROM proyecto_investigacion WHERE id_proyecto = 4;
SELECT id_auditoria, id_proyecto, operacion,
       LEFT(datos_anteriores, 55) AS datos_anteriores, usuario
  FROM auditoria_proyecto WHERE operacion = 'DELETE';
ROLLBACK;
SELECT COUNT(*) AS proyectos_despues_del_rollback FROM proyecto_investigacion;
-- @@ P09 | Registro histórico | Se amplía la fecha de fin de Ramiro Guamán en IOTAGRO
UPDATE proyecto_profesor SET fin_pro = '2027-06-30'
 WHERE id_proyecto = 3 AND id_profesor = 9;
SELECT id_historial, id_proyecto, id_profesor, fin_anterior, fin_nuevo, usuario
  FROM historial_participacion;
-- @@ P10 | Tabla resumen | Se registra el primer producto de DATABOL y luego se elimina uno de prueba
SELECT id_proyecto, total_productos
  FROM resumen_proyecto WHERE id_proyecto = 5;
INSERT INTO productos (id_proyecto, titulo, num_secuencia)
VALUES (5, 'Portal de datos abiertos de la provincia Bolívar', 1);
INSERT INTO productos (id_proyecto, titulo, num_secuencia)
VALUES (5, 'Producto de prueba', 2);
SELECT id_proyecto, total_productos
  FROM resumen_proyecto WHERE id_proyecto = 5;
DELETE FROM productos WHERE id_proyecto = 5 AND num_secuencia = 2;
SELECT id_proyecto, total_productos
  FROM resumen_proyecto WHERE id_proyecto = 5;
-- @@ P11 | Consistencia | El resumen coincide con el conteo real de productos
SELECT r.id_proyecto, r.total_productos AS resumen,
       (SELECT COUNT(*) FROM productos p WHERE p.id_proyecto = r.id_proyecto) AS conteo_real,
       IF(r.total_productos = (SELECT COUNT(*) FROM productos p
                               WHERE p.id_proyecto = r.id_proyecto), 'OK', 'NO COINCIDE') AS verificacion
  FROM resumen_proyecto r;
-- @@ P12 | Integridad | Secuencia de producto repetida en el mismo proyecto (debe FALLAR por UNIQUE)
INSERT INTO productos (id_proyecto, titulo, num_secuencia)
VALUES (5, 'Producto duplicado', 1);
