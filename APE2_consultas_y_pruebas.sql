-- =====================================================================
-- APE 2 - Consultas y pruebas (ejecutar UNA POR UNA en la pestaña SQL)
-- =====================================================================
USE gestion_investigacion;

-- Consultas avanzadas (solución A)
CALL sp_ca1_productividad_proyectos();
CALL sp_ca2_proyectos_sobre_promedio();
CALL sp_ca3_ultimo_producto_proyecto();
CALL sp_ca4_valoracion_revistas();
CALL sp_ca5_estado_proyectos(60);

-- Consultas multitabla
CALL sp_cm1_equipo_proyecto(NULL);
CALL sp_cm2_carga_profesores();
CALL sp_cm3_estudiantes_por_proyecto();
CALL sp_cm4_cobertura_lineas();
CALL sp_cm5_catalogo_productos();


-- CA1-B. Tabla cruzada con SUM(CASE ...) y UNION ALL para el total
SELECT p.acronimo AS proyecto,
       SUM(CASE WHEN pr.id_tipo = 1 THEN 1 ELSE 0 END) AS revistas,
       SUM(CASE WHEN pr.id_tipo = 2 THEN 1 ELSE 0 END) AS congresos,
       SUM(CASE WHEN pr.id_tipo = 3 THEN 1 ELSE 0 END) AS libros,
       SUM(CASE WHEN pr.id_tipo = 4 THEN 1 ELSE 0 END) AS patentes,
       COUNT(*) AS total
  FROM productos pr
  JOIN proyecto_investigacion p ON p.id_proyecto = pr.id_proyecto
 GROUP BY p.acronimo
UNION ALL
SELECT 'TOTAL UEB',
       SUM(id_tipo = 1), SUM(id_tipo = 2), SUM(id_tipo = 3), SUM(id_tipo = 4), COUNT(*)
  FROM productos;

-- CA2-B. Tabla derivada con el promedio unida con CROSS JOIN
SELECT p.acronimo, p.presupuesto,
       ROUND(a.promedio, 2)                 AS promedio_ueb,
       ROUND(p.presupuesto - a.promedio, 2) AS diferencia
  FROM proyecto_investigacion p
 CROSS JOIN (SELECT AVG(presupuesto) AS promedio FROM proyecto_investigacion) a
 WHERE p.presupuesto > a.promedio
 ORDER BY p.presupuesto DESC;

-- CA3-B. Tabla derivada con GROUP BY + JOIN
SELECT p.acronimo, pr.num_secuencia,
       LEFT(pr.titulo_publicacion, 50) AS titulo,
       t.descripcion_tipo              AS tipo
  FROM productos pr
  JOIN (SELECT id_proyecto, MAX(num_secuencia) AS ultima
          FROM productos
         GROUP BY id_proyecto) m
    ON m.id_proyecto = pr.id_proyecto AND m.ultima = pr.num_secuencia
  JOIN proyecto_investigacion p ON p.id_proyecto = pr.id_proyecto
  JOIN tipo_pro t               ON t.id_tipo     = pr.id_tipo
 ORDER BY p.acronimo;

-- CA4-B. Uso de la función almacenada fn_puntaje_revista
SELECT p.acronimo,
       COUNT(*)                            AS articulos,
       SUM(fn_puntaje_revista(r.quartil))  AS puntaje_total,
       IF(SUM(fn_puntaje_revista(r.quartil)) >= 1, 'Cumple 1 punto', 'No cumple') AS evaluacion
  FROM publicacion_revista r
  JOIN productos pr             ON pr.id_producto = r.id_producto
  JOIN proyecto_investigacion p ON p.id_proyecto  = pr.id_proyecto
 GROUP BY p.acronimo
 ORDER BY puntaje_total DESC;

-- CA5-B. Meses calculados con DATEDIFF / 30 frente a TIMESTAMPDIFF
SELECT acronimo,
       inicio_pro,
       LEAST(CURDATE(), fn_fin_vigente(fin_pro, prorroga))                                   AS hasta,
       FLOOR(DATEDIFF(LEAST(CURDATE(), fn_fin_vigente(fin_pro, prorroga)), inicio_pro) / 30) AS meses_b,
       TIMESTAMPDIFF(MONTH, inicio_pro, LEAST(CURDATE(), fn_fin_vigente(fin_pro, prorroga))) AS meses_a
  FROM proyecto_investigacion
 ORDER BY acronimo;

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
