-- =====================================================================
-- 03. Funciones y procedimientos almacenados
--     Consultas avanzadas (CA1-CA5) y multitabla (CM1-CM5)
-- =====================================================================
USE gestion_investigacion;

DROP FUNCTION  IF EXISTS fn_tipo_producto;
DROP FUNCTION  IF EXISTS fn_proyectos_activos;
DROP FUNCTION  IF EXISTS fn_puntaje_revista;
DROP FUNCTION  IF EXISTS fn_fin_vigente;
DROP PROCEDURE IF EXISTS sp_ca1_productividad_proyectos;
DROP PROCEDURE IF EXISTS sp_ca2_proyectos_sobre_promedio;
DROP PROCEDURE IF EXISTS sp_ca3_ultimo_producto_proyecto;
DROP PROCEDURE IF EXISTS sp_ca4_valoracion_revistas;
DROP PROCEDURE IF EXISTS sp_ca5_estado_proyectos;
DROP PROCEDURE IF EXISTS sp_cm1_equipo_proyecto;
DROP PROCEDURE IF EXISTS sp_cm2_carga_profesores;
DROP PROCEDURE IF EXISTS sp_cm3_estudiantes_por_proyecto;
DROP PROCEDURE IF EXISTS sp_cm4_cobertura_lineas;
DROP PROCEDURE IF EXISTS sp_cm5_catalogo_productos;

DELIMITER $$

-- ---------------------------------------------------------------------
-- Funciones
-- ---------------------------------------------------------------------
CREATE FUNCTION fn_tipo_producto(p_id_producto INT UNSIGNED)
RETURNS VARCHAR(30) READS SQL DATA
BEGIN
    DECLARE v_tipo VARCHAR(30);
    SELECT t.descripcion_tipo INTO v_tipo
      FROM productos pr
      JOIN tipo_pro t ON t.id_tipo = pr.id_tipo
     WHERE pr.id_producto = p_id_producto;
    RETURN IFNULL(v_tipo, 'No existe');
END$$

CREATE FUNCTION fn_proyectos_activos(p_id_profesor INT UNSIGNED)
RETURNS INT READS SQL DATA
BEGIN
    DECLARE v_total INT DEFAULT 0;
    SELECT COUNT(*) INTO v_total
      FROM proyecto_profesor pp
      JOIN proyecto_investigacion p ON p.id_proyecto = pp.id_proyecto
     WHERE pp.id_profesor = p_id_profesor
       AND pp.resolucion_salida IS NULL
       AND p.resolucion_consejo_uni_cierre IS NULL;
    RETURN v_total;
END$$

CREATE FUNCTION fn_puntaje_revista(p_quartil VARCHAR(2))
RETURNS DECIMAL(4,2) DETERMINISTIC
BEGIN
    RETURN CASE p_quartil
               WHEN 'Q1' THEN 1.00
               WHEN 'Q2' THEN 0.80
               WHEN 'Q3' THEN 0.60
               WHEN 'Q4' THEN 0.40
               ELSE 0.20
           END;
END$$

CREATE FUNCTION fn_fin_vigente(p_fin DATE, p_prorroga DATE)
RETURNS DATE DETERMINISTIC
BEGIN
    RETURN IFNULL(p_prorroga, p_fin);
END$$

-- ---------------------------------------------------------------------
-- CA1. Productividad de los proyectos por tipo de producto
--      (funciones agregadas y agrupamiento complejo WITH ROLLUP)
-- ---------------------------------------------------------------------
CREATE PROCEDURE sp_ca1_productividad_proyectos()
BEGIN
    SELECT CASE WHEN r.acronimo IS NULL THEN 'TOTAL UEB' ELSE r.acronimo END AS proyecto,
           CASE WHEN r.acronimo IS NULL THEN '-'
                WHEN r.tipo IS NULL     THEN 'Subtotal'
                ELSE r.tipo END                                   AS tipo_producto,
           r.cantidad
      FROM (SELECT p.acronimo, t.descripcion_tipo AS tipo, COUNT(*) AS cantidad
              FROM productos pr
              JOIN proyecto_investigacion p ON p.id_proyecto = pr.id_proyecto
              JOIN tipo_pro t               ON t.id_tipo     = pr.id_tipo
             GROUP BY p.acronimo, t.descripcion_tipo WITH ROLLUP) r;
END$$

-- ---------------------------------------------------------------------
-- CA2. Proyectos con presupuesto mayor al promedio (subconsulta)
-- ---------------------------------------------------------------------
CREATE PROCEDURE sp_ca2_proyectos_sobre_promedio()
BEGIN
    SELECT p.acronimo,
           p.presupuesto,
           ROUND((SELECT AVG(presupuesto) FROM proyecto_investigacion), 2) AS promedio_ueb,
           ROUND(p.presupuesto - (SELECT AVG(presupuesto)
                                    FROM proyecto_investigacion), 2)    AS diferencia
      FROM proyecto_investigacion p
     WHERE p.presupuesto > (SELECT AVG(presupuesto) FROM proyecto_investigacion)
     ORDER BY p.presupuesto DESC;
END$$

-- ---------------------------------------------------------------------
-- CA3. Último producto registrado por cada proyecto (consulta correlacionada)
-- ---------------------------------------------------------------------
CREATE PROCEDURE sp_ca3_ultimo_producto_proyecto()
BEGIN
    SELECT p.acronimo,
           pr.num_secuencia,
           LEFT(pr.titulo_publicacion, 50)  AS titulo,
           fn_tipo_producto(pr.id_producto) AS tipo
      FROM productos pr
      JOIN proyecto_investigacion p ON p.id_proyecto = pr.id_proyecto
     WHERE pr.num_secuencia = (SELECT MAX(x.num_secuencia)
                                 FROM productos x
                                WHERE x.id_proyecto = pr.id_proyecto)
     ORDER BY p.acronimo;
END$$

-- ---------------------------------------------------------------------
-- CA4. Valoración de las publicaciones en revistas (expresiones CASE)
-- ---------------------------------------------------------------------
CREATE PROCEDURE sp_ca4_valoracion_revistas()
BEGIN
    SELECT p.acronimo,
           COUNT(r.id_revista)                                    AS articulos,
           SUM(CASE WHEN r.quartil IS NOT NULL THEN 1 ELSE 0 END) AS alto_impacto,
           SUM(CASE WHEN r.quartil IS NULL     THEN 1 ELSE 0 END) AS regionales,
           SUM(CASE r.quartil WHEN 'Q1' THEN 1.00 WHEN 'Q2' THEN 0.80
                              WHEN 'Q3' THEN 0.60 WHEN 'Q4' THEN 0.40
                              ELSE 0.20 END)                      AS puntaje_total,
           CASE WHEN SUM(CASE r.quartil WHEN 'Q1' THEN 1.00 WHEN 'Q2' THEN 0.80
                                       WHEN 'Q3' THEN 0.60 WHEN 'Q4' THEN 0.40
                                       ELSE 0.20 END) >= 1
                THEN 'Cumple 1 punto' ELSE 'No cumple' END        AS evaluacion
      FROM publicacion_revista r
      JOIN productos pr             ON pr.id_producto = r.id_producto
      JOIN proyecto_investigacion p ON p.id_proyecto  = pr.id_proyecto
     GROUP BY p.acronimo
     ORDER BY puntaje_total DESC;
END$$

-- ---------------------------------------------------------------------
-- CA5. Estado de ejecución de los proyectos (funciones de fecha)
-- ---------------------------------------------------------------------
CREATE PROCEDURE sp_ca5_estado_proyectos(IN p_dias_aviso INT)
BEGIN
    SELECT p.acronimo,
           DATE_FORMAT(p.inicio_pro, '%d/%m/%Y')                          AS inicio,
           DATE_FORMAT(fn_fin_vigente(p.fin_pro, p.prorroga), '%d/%m/%Y') AS fin_vigente,
           IF(p.prorroga IS NULL, 'No', 'Sí')                             AS prorroga,
           TIMESTAMPDIFF(MONTH, p.inicio_pro,
                         LEAST(CURDATE(), fn_fin_vigente(p.fin_pro, p.prorroga))) AS meses_ejecucion,
           GREATEST(DATEDIFF(fn_fin_vigente(p.fin_pro, p.prorroga), CURDATE()), 0) AS dias_restantes,
           CASE WHEN p.resolucion_consejo_uni_cierre IS NOT NULL THEN 'Cerrado'
                WHEN fn_fin_vigente(p.fin_pro, p.prorroga) < CURDATE() THEN 'Vencido sin cierre'
                WHEN fn_fin_vigente(p.fin_pro, p.prorroga)
                     <= DATE_ADD(CURDATE(), INTERVAL p_dias_aviso DAY) THEN 'Por finalizar'
                ELSE 'En ejecución' END                                   AS estado
      FROM proyecto_investigacion p
     ORDER BY FIELD(estado, 'Vencido sin cierre', 'Por finalizar', 'En ejecución', 'Cerrado'),
              dias_restantes;
END$$

-- ---------------------------------------------------------------------
-- CM1. Equipo actual de un proyecto (INNER JOIN de 3 tablas)
-- ---------------------------------------------------------------------
CREATE PROCEDURE sp_cm1_equipo_proyecto(IN p_id_proyecto INT UNSIGNED)
BEGIN
    SELECT p.acronimo, pp.cargo, pf.nombre, pf.telefono, pp.resolucion_ingreso
      FROM proyecto_investigacion p
     INNER JOIN proyecto_profesor pp ON pp.id_proyecto = p.id_proyecto
     INNER JOIN profesores pf        ON pf.id_profesor = pp.id_profesor
     WHERE (p_id_proyecto IS NULL OR p.id_proyecto = p_id_proyecto)
       AND pp.resolucion_salida IS NULL
       AND p.resolucion_consejo_uni_cierre IS NULL
     ORDER BY p.acronimo, pp.cargo, pf.nombre;
END$$

-- ---------------------------------------------------------------------
-- CM2. Carga y disponibilidad de los profesores (LEFT JOIN)
-- ---------------------------------------------------------------------
CREATE PROCEDURE sp_cm2_carga_profesores()
BEGIN
    SELECT pf.nombre,
           COUNT(pp.id_proyecto)                                     AS proyectos_activos,
           IFNULL(GROUP_CONCAT(p.acronimo ORDER BY p.acronimo SEPARATOR ', '), '-') AS proyectos,
           CASE WHEN COUNT(pp.id_proyecto) = 0 THEN 'Disponible'
                WHEN COUNT(pp.id_proyecto) = 1 THEN 'Puede tomar 1 más'
                ELSE 'Límite alcanzado' END                          AS disponibilidad
      FROM profesores pf
      LEFT JOIN (proyecto_profesor pp
                 INNER JOIN proyecto_investigacion p
                         ON p.id_proyecto = pp.id_proyecto
                        AND p.resolucion_consejo_uni_cierre IS NULL)
             ON pp.id_profesor = pf.id_profesor
            AND pp.resolucion_salida IS NULL
     GROUP BY pf.id_profesor, pf.nombre
     ORDER BY proyectos_activos DESC, pf.nombre;
END$$

-- ---------------------------------------------------------------------
-- CM3. Estudiantes que participan en cada proyecto (LEFT JOIN)
-- ---------------------------------------------------------------------
CREATE PROCEDURE sp_cm3_estudiantes_por_proyecto()
BEGIN
    SELECT p.acronimo,
           COUNT(e.id_estudiante)                                       AS estudiantes,
           IFNULL(GROUP_CONCAT(e.nombres_est ORDER BY e.nombres_est SEPARATOR ', '), '-') AS nombres,
           IF(COUNT(e.id_estudiante) = 0, 'Sin estudiantes', 'Con estudiantes') AS observacion
      FROM proyecto_investigacion p
      LEFT JOIN estudiante e ON e.id_proyecto = p.id_proyecto
     GROUP BY p.id_proyecto, p.acronimo
     ORDER BY estudiantes DESC, p.acronimo;
END$$

-- ---------------------------------------------------------------------
-- CM4. Cobertura de las líneas de investigación (RIGHT JOIN)
-- ---------------------------------------------------------------------
CREATE PROCEDURE sp_cm4_cobertura_lineas()
BEGIN
    SELECT l.nombre_linea,
           (SELECT COUNT(*) FROM linea_profesor lp
             WHERE lp.id_linea = l.id_linea)                         AS profesores,
           COUNT(p.id_proyecto)                                      AS proyectos,
           IFNULL(GROUP_CONCAT(p.acronimo ORDER BY p.acronimo SEPARATOR ', '), 'Ninguno') AS acronimos,
           IFNULL(SUM(p.presupuesto), 0)                             AS presupuesto_linea
      FROM proyecto_investigacion p
      JOIN proyecto_linea pl           ON pl.id_proyecto = p.id_proyecto
     RIGHT JOIN linea_investigacion l  ON l.id_linea     = pl.id_linea
     GROUP BY l.id_linea, l.nombre_linea
     ORDER BY proyectos DESC, l.nombre_linea;
END$$

-- ---------------------------------------------------------------------
-- CM5. Catálogo completo de productos (JOIN de 7 tablas)
-- ---------------------------------------------------------------------
CREATE PROCEDURE sp_cm5_catalogo_productos()
BEGIN
    SELECT p.acronimo,
           pr.num_secuencia                    AS sec,
           LEFT(pr.titulo_publicacion, 40)     AS titulo,
           t.descripcion_tipo                  AS tipo,
           LEFT(COALESCE(CONCAT(r.nombre_revista, IFNULL(CONCAT(' (', r.quartil, ')'), ' (Regional)')),
                         CONCAT(c.nombre_congreso, ' - ', c.ambito),
                         CONCAT(l.editorial, ' - ISBN ', l.isbn),
                         CONCAT(pa.num_registro, ' - ', pa.estado)), 55) AS medio,
           IFNULL(CAST(COALESCE(c.fecha_inicio, l.fecha_publicacion, pa.fecha_solicitud) AS CHAR),
                  'No registra')               AS fecha
      FROM productos pr
     INNER JOIN proyecto_investigacion p ON p.id_proyecto  = pr.id_proyecto
     INNER JOIN tipo_pro t               ON t.id_tipo      = pr.id_tipo
      LEFT JOIN publicacion_revista r    ON r.id_producto  = pr.id_producto
      LEFT JOIN publicacion_congreso c   ON c.id_producto  = pr.id_producto
      LEFT JOIN libro l                  ON l.id_producto  = pr.id_producto
      LEFT JOIN patentes pa              ON pa.id_producto = pr.id_producto
     ORDER BY p.acronimo, pr.num_secuencia;
END$$

DELIMITER ;
