-- =====================================================================
-- 05. Pruebas de control de calidad (ejecutar una por una, en orden)
--     Las pruebas que terminan en error son intencionales.
-- =====================================================================
USE gestion_investigacion;

-- P01. Trigger 1: se rechaza un quinto investigador en SATCLIMA
INSERT INTO proyecto_profesor (id_proyecto, id_profesor, cargo, resolucion_ingreso)
VALUES (2, 13, 'Investigador', 'RCU-UEB-2026-220');

-- P02. Trigger 1: se rechaza un segundo Director en PLATINV
INSERT INTO proyecto_profesor (id_proyecto, id_profesor, cargo, resolucion_ingreso)
VALUES (1, 3, 'Director', 'RCU-UEB-2026-221');

-- P03. Trigger 1: se rechaza a un profesor que ya está en 2 proyectos activos
INSERT INTO proyecto_profesor (id_proyecto, id_profesor, cargo, resolucion_ingreso)
VALUES (5, 9, 'Investigador', 'RCU-UEB-2026-222');

-- P04. Trigger 1: inserción válida, num_profesores se calcula solo
INSERT INTO proyecto_profesor (id_proyecto, id_profesor, cargo, resolucion_ingreso)
VALUES (5, 13, 'Investigador', 'RCU-UEB-2026-223');
SELECT id_proyecto, id_profesor, cargo, num_profesores, resolucion_ingreso
  FROM proyecto_profesor WHERE id_proyecto = 5;

-- P05. Trigger 1: un proyecto cerrado no admite nuevos profesores
INSERT INTO proyecto_profesor (id_proyecto, id_profesor, cargo, resolucion_ingreso)
VALUES (4, 10, 'Investigador', 'RCU-UEB-2026-224');

-- P06. Modelo físico: la restricción CHECK rechaza una prórroga anterior al fin
UPDATE proyecto_investigacion SET prorroga = '2026-01-01' WHERE id_proyecto = 1;

-- P07. Trigger 2: la modificación de un proyecto queda en la auditoría
UPDATE proyecto_investigacion
   SET presupuesto = 12500.00, prorroga = '2027-03-31'
 WHERE id_proyecto = 5;
SELECT * FROM auditoria_proyecto;

-- P08. Trigger 2: la eliminación queda registrada (se revierte con ROLLBACK)
START TRANSACTION;
DELETE FROM proyecto_investigacion WHERE id_proyecto = 4;
SELECT id_auditoria, id_proyecto, operacion, datos_anteriores, usuario
  FROM auditoria_proyecto WHERE operacion = 'DELETE';
ROLLBACK;

-- P09. Trigger 3: la salida de un investigador queda en el historial
UPDATE proyecto_profesor
   SET resolucion_salida = 'RCU-UEB-2026-230',
       motivo_salida     = 'Licencia por estudios de doctorado'
 WHERE id_proyecto = 1 AND id_profesor = 7;
SELECT * FROM historial_participacion;

-- P10. Trigger 4: el resumen de DATABOL sube al insertar y baja al eliminar
INSERT INTO productos (id_proyecto, id_tipo, titulo_publicacion, num_secuencia) VALUES
(5, 1, 'Datos abiertos y transparencia en la provincia Bolívar', 2),
(5, 3, 'Guía de publicación de datos abiertos para GAD', 3);
DELETE FROM productos WHERE id_proyecto = 5 AND num_secuencia = 3;
SELECT * FROM resumen_proyecto WHERE id_proyecto = 5;

-- P11. Trigger 4: el resumen coincide con el conteo real de productos
SELECT r.id_proyecto, r.total_productos,
       (SELECT COUNT(*) FROM productos pr WHERE pr.id_proyecto = r.id_proyecto) AS conteo_real,
       IF(r.total_productos = (SELECT COUNT(*) FROM productos pr
                                WHERE pr.id_proyecto = r.id_proyecto), 'Coincide', 'Revisar') AS estado
  FROM resumen_proyecto r;

-- P12. Modelo físico: la clave única impide repetir la secuencia de un producto
INSERT INTO productos (id_proyecto, id_tipo, titulo_publicacion, num_secuencia)
VALUES (5, 1, 'Producto con secuencia repetida', 1);

-- P13. Modelo físico: un producto de tipo Libro no puede registrarse como revista
INSERT INTO publicacion_revista (id_producto, nombre_revista, editorial, volumen)
VALUES (2, 'Revista de prueba', 'Editorial UEB', '1');
