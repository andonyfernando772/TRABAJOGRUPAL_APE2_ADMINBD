-- =====================================================================
-- APE 2 - Administración de Bases de Datos
-- Script 03: Funciones y procedimientos almacenados
--   Literal 2: consultas avanzadas  -> sp_ca1 ... sp_ca5
--   Literal 3: consultas multitabla -> sp_cm1 ... sp_cm5
-- SGBD: MariaDB 10.11 / MySQL 8
-- =====================================================================
USE gestion_investigacion;

DROP FUNCTION  IF EXISTS fn_tipo_producto;
DROP FUNCTION  IF EXISTS fn_puntaje_revista;
DROP FUNCTION  IF EXISTS fn_proyectos_activos;
DROP FUNCTION  IF EXISTS fn_meses_participacion;
DROP PROCEDURE IF EXISTS sp_ca1_productividad_proyectos;
DROP PROCEDURE IF EXISTS sp_ca2_proyectos_sobre_promedio;
DROP PROCEDURE IF EXISTS sp_ca3_ultimo_producto_proyecto;
DROP PROCEDURE IF EXISTS sp_ca4_valoracion_revistas;
DROP PROCEDURE IF EXISTS sp_ca5_estado_participaciones;
DROP PROCEDURE IF EXISTS sp_cm1_equipo_proyecto;
DROP PROCEDURE IF EXISTS sp_cm2_carga_profesores;
DROP PROCEDURE IF EXISTS sp_cm3_productos_por_proyecto;
DROP PROCEDURE IF EXISTS sp_cm4_cobertura_lineas;
DROP PROCEDURE IF EXISTS sp_cm5_catalogo_productos;

DELIMITER $$

-- ---------------------------------------------------------------------
-- FUNCIONES
-- ---------------------------------------------------------------------

-- F1. Devuelve el tipo de un producto revisando en qué subtipo está.
CREATE FUNCTION fn_tipo_producto(p_id_producto INT UNSIGNED)
RETURNS VARCHAR(20)
READS SQL DATA
BEGIN
    IF EXISTS (SELECT 1 FROM revista  WHERE id_producto = p_id_producto) THEN RETURN 'Revista';  END IF;
    IF EXISTS (SELECT 1 FROM congreso WHERE id_producto = p_id_producto) THEN RETURN 'Congreso'; END IF;
    IF EXISTS (SELECT 1 FROM libro    WHERE id_producto = p_id_producto) THEN RETURN 'Libro';    END IF;
    IF EXISTS (SELECT 1 FROM patentes WHERE id_producto = p_id_producto) THEN RETURN 'Patente';  END IF;
    RETURN 'Sin clasificar';
END$$

-- F2. Puntaje referencial de un artículo según el cuartil de la revista.
--     Q1 = 1 punto ... revista regional (sin cuartil) = 0.20 puntos.
CREATE FUNCTION fn_puntaje_revista(p_quartil VARCHAR(2))
RETURNS DECIMAL(4,2)
DETERMINISTIC
BEGIN
    RETURN CASE p_quartil
               WHEN 'Q1' THEN 1.00
               WHEN 'Q2' THEN 0.80
               WHEN 'Q3' THEN 0.60
               WHEN 'Q4' THEN 0.40
               ELSE 0.20
           END;
END$$

-- F3. Número de proyectos en los que un profesor está activo en una fecha.
CREATE FUNCTION fn_proyectos_activos(p_id_profesor INT UNSIGNED, p_fecha DATE)
RETURNS INT
READS SQL DATA
BEGIN
    DECLARE v_total INT DEFAULT 0;
    SELECT COUNT(*) INTO v_total
      FROM proyecto_profesor
     WHERE id_profesor = p_id_profesor
       AND inicio_pro <= p_fecha
       AND (fin_pro IS NULL OR fin_pro >= p_fecha);
    RETURN v_total;
END$$

-- F4. Meses de participación (si no tiene fecha de fin se cuenta hasta hoy).
CREATE FUNCTION fn_meses_participacion(p_inicio DATE, p_fin DATE)
RETURNS INT
NOT DETERMINISTIC
BEGIN
    RETURN TIMESTAMPDIFF(MONTH, p_inicio, IFNULL(p_fin, CURDATE()));
END$$

-- ---------------------------------------------------------------------
-- LITERAL 2: CONSULTAS AVANZADAS
-- ---------------------------------------------------------------------

-- CA1. Funciones agregadas + agrupamiento complejo (WITH ROLLUP)
-- Problema: cuántos productos de cada tipo genera cada proyecto, con
-- subtotal por proyecto y total general de la universidad.
CREATE PROCEDURE sp_ca1_productividad_proyectos()
BEGIN
    SELECT CASE WHEN r.acronimo IS NULL THEN 'TOTAL UEB' ELSE r.acronimo END AS proyecto,
           CASE WHEN r.acronimo IS NULL THEN '-'
                WHEN r.tipo IS NULL     THEN 'Subtotal'
                ELSE r.tipo END                                     AS tipo_producto,
           r.cantidad
      FROM (SELECT t.acronimo, t.tipo, COUNT(*) AS cantidad
              FROM (SELECT p.acronimo, fn_tipo_producto(pr.id_producto) AS tipo
                      FROM productos pr
                      JOIN proyecto_investigacion p ON p.id_proyecto = pr.id_proyecto) t
             GROUP BY t.acronimo, t.tipo WITH ROLLUP) r;
END$$

-- CA2. Subconsulta (no correlacionada)
-- Problema: qué proyectos tienen un presupuesto mayor al promedio de la
-- universidad y por cuánto lo superan.
CREATE PROCEDURE sp_ca2_proyectos_sobre_promedio()
BEGIN
    SELECT p.acronimo,
           LEFT(p.nombre_proyecto, 45) AS nombre_proyecto,
           p.presupuesto,
           ROUND((SELECT AVG(presupuesto) FROM proyecto_investigacion), 2) AS promedio_ueb,
           ROUND(p.presupuesto - (SELECT AVG(presupuesto)
                                    FROM proyecto_investigacion), 2)    AS diferencia
      FROM proyecto_investigacion p
     WHERE p.presupuesto > (SELECT AVG(presupuesto) FROM proyecto_investigacion)
     ORDER BY p.presupuesto DESC;
END$$

-- CA3. Consulta correlacionada
-- Problema: cuál es el último producto (mayor número de secuencia) que ha
-- registrado cada proyecto.
CREATE PROCEDURE sp_ca3_ultimo_producto_proyecto()
BEGIN
    SELECT p.acronimo,
           pr.num_secuencia,
           LEFT(pr.titulo, 50)              AS titulo,
           fn_tipo_producto(pr.id_producto) AS tipo
      FROM productos pr
      JOIN proyecto_investigacion p ON p.id_proyecto = pr.id_proyecto
     WHERE pr.num_secuencia = (SELECT MAX(x.num_secuencia)
                                 FROM productos x
                                WHERE x.id_proyecto = pr.id_proyecto)
     ORDER BY p.acronimo;
END$$

-- CA4. Expresiones CASE + agregadas
-- Problema: valorar la producción en revistas de cada proyecto separando
-- revistas de alto impacto (Q1-Q4) y revistas regionales (sin cuartil).
CREATE PROCEDURE sp_ca4_valoracion_revistas()
BEGIN
    SELECT p.acronimo,
           COUNT(r.id_revista)                                          AS articulos,
           SUM(CASE WHEN r.quartil IS NOT NULL THEN 1 ELSE 0 END)       AS alto_impacto,
           SUM(CASE WHEN r.quartil IS NULL     THEN 1 ELSE 0 END)       AS regionales,
           SUM(CASE r.quartil WHEN 'Q1' THEN 1.00 WHEN 'Q2' THEN 0.80
                              WHEN 'Q3' THEN 0.60 WHEN 'Q4' THEN 0.40
                              ELSE 0.20 END)                            AS puntaje_total,
           CASE WHEN SUM(CASE r.quartil WHEN 'Q1' THEN 1.00 WHEN 'Q2' THEN 0.80
                                       WHEN 'Q3' THEN 0.60 WHEN 'Q4' THEN 0.40
                                       ELSE 0.20 END) >= 1
                THEN 'Cumple 1 punto' ELSE 'No cumple' END              AS evaluacion
      FROM revista r
      JOIN productos pr             ON pr.id_producto = r.id_producto
      JOIN proyecto_investigacion p ON p.id_proyecto  = pr.id_proyecto
     GROUP BY p.acronimo
     ORDER BY puntaje_total DESC;
END$$

-- CA5. Funciones de fecha + CASE
-- Problema: saber el estado de cada participación y cuántos días le quedan,
-- para planificar reemplazos antes de que un investigador salga.
CREATE PROCEDURE sp_ca5_estado_participaciones(IN p_dias_aviso INT)
BEGIN
    SELECT p.acronimo,
           pf.nombre                                         AS profesor,
           pf.cargo,
           DATE_FORMAT(pp.inicio_pro, '%d/%m/%Y')            AS inicio,
           IFNULL(DATE_FORMAT(pp.fin_pro, '%d/%m/%Y'), 'Sin fecha') AS fin,
           TIMESTAMPDIFF(MONTH, pp.inicio_pro, IFNULL(pp.fin_pro, CURDATE())) AS meses,
           CASE WHEN pp.fin_pro IS NULL THEN 'Indefinido'
                ELSE GREATEST(DATEDIFF(pp.fin_pro, CURDATE()), 0) END AS dias_restantes,
           CASE WHEN pp.fin_pro < CURDATE() THEN 'Finalizada'
                WHEN pp.fin_pro <= DATE_ADD(CURDATE(), INTERVAL p_dias_aviso DAY) THEN 'Por finalizar'
                ELSE 'Activa' END                            AS estado
      FROM proyecto_profesor pp
      JOIN proyecto_investigacion p ON p.id_proyecto  = pp.id_proyecto
      JOIN profesores pf            ON pf.id_profesor = pp.id_profesor
     ORDER BY FIELD(estado, 'Por finalizar', 'Activa', 'Finalizada'), p.acronimo;
END$$

-- ---------------------------------------------------------------------
-- LITERAL 3: CONSULTAS MULTITABLA
-- ---------------------------------------------------------------------

-- CM1. INNER JOIN (3 tablas)
-- Problema: conocer el equipo actual (director, subrogante e investigadores)
-- de un proyecto. Si se envía NULL se listan todos los proyectos.
CREATE PROCEDURE sp_cm1_equipo_proyecto(IN p_id_proyecto INT UNSIGNED)
BEGIN
    SELECT p.acronimo, pf.cargo, pf.nombre, pf.telefono, pp.inicio_pro
      FROM proyecto_investigacion p
     INNER JOIN proyecto_profesor pp ON pp.id_proyecto = p.id_proyecto
     INNER JOIN profesores pf        ON pf.id_profesor = pp.id_profesor
     WHERE (p_id_proyecto IS NULL OR p.id_proyecto = p_id_proyecto)
       AND (pp.fin_pro IS NULL OR pp.fin_pro >= CURDATE())
     ORDER BY p.acronimo,
              FIELD(pf.cargo, 'Director', 'Director subrogante', 'Investigador'),
              pf.nombre;
END$$

-- CM2. LEFT JOIN
-- Problema: carga de cada profesor (en cuántos proyectos está activo hoy),
-- incluyendo a los profesores que no participan en ningún proyecto.
CREATE PROCEDURE sp_cm2_carga_profesores()
BEGIN
    SELECT pf.nombre,
           pf.cargo,
           COUNT(pp.id_proyecto)                         AS proyectos_activos,
           IFNULL(GROUP_CONCAT(p.acronimo ORDER BY p.acronimo SEPARATOR ', '), '-') AS proyectos,
           CASE WHEN COUNT(pp.id_proyecto) = 0 THEN 'Disponible'
                WHEN COUNT(pp.id_proyecto) = 1 THEN 'Puede tomar 1 más'
                ELSE 'Límite alcanzado (2)' END          AS disponibilidad
      FROM profesores pf
      LEFT JOIN proyecto_profesor pp
             ON pp.id_profesor = pf.id_profesor
            AND (pp.fin_pro IS NULL OR pp.fin_pro >= CURDATE())
      LEFT JOIN proyecto_investigacion p ON p.id_proyecto = pp.id_proyecto
     GROUP BY pf.id_profesor, pf.nombre, pf.cargo
     ORDER BY proyectos_activos DESC, pf.nombre;
END$$

-- CM3. LEFT JOIN (detecta proyectos sin productos)
-- Problema: cuántos productos ha generado cada proyecto, mostrando también
-- los que todavía no tienen ningún resultado.
CREATE PROCEDURE sp_cm3_productos_por_proyecto()
BEGIN
    SELECT p.acronimo,
           p.presupuesto,
           COUNT(pr.id_producto)                                  AS productos,
           IF(COUNT(pr.id_producto) = 0, 'Sin productos', 'Con productos') AS observacion
      FROM proyecto_investigacion p
      LEFT JOIN productos pr ON pr.id_proyecto = p.id_proyecto
     GROUP BY p.id_proyecto, p.acronimo, p.presupuesto
     ORDER BY productos DESC;
END$$

-- CM4. RIGHT JOIN (+ JOIN de 3 tablas)
-- Problema: qué proyectos trabajan en cada línea de investigación, sin
-- dejar fuera las líneas que todavía no tienen proyectos.
CREATE PROCEDURE sp_cm4_cobertura_lineas()
BEGIN
    SELECT l.nombre_linea,
           COUNT(p.id_proyecto)                                    AS num_proyectos,
           IFNULL(GROUP_CONCAT(p.acronimo ORDER BY p.acronimo SEPARATOR ', '), 'Ninguno') AS proyectos,
           IFNULL(SUM(p.presupuesto), 0)                           AS presupuesto_linea
      FROM proyecto_investigacion p
      JOIN proyecto_linea pl        ON pl.id_proyecto = p.id_proyecto
     RIGHT JOIN linea_investigacion l ON l.id_linea   = pl.id_linea
     GROUP BY l.id_linea, l.nombre_linea
     ORDER BY num_proyectos DESC, l.nombre_linea;
END$$

-- CM5. JOIN de más de tres tablas (6 tablas: INNER + LEFT)
-- Problema: catálogo completo de productos con su proyecto, tipo, medio
-- donde se difundió y fecha, para el reporte anual de investigación.
CREATE PROCEDURE sp_cm5_catalogo_productos()
BEGIN
    SELECT p.acronimo,
           pr.num_secuencia AS sec,
           LEFT(pr.titulo, 40) AS titulo,
           CASE WHEN r.id_revista  IS NOT NULL THEN 'Revista'
                WHEN c.id_congreso IS NOT NULL THEN 'Congreso'
                WHEN l.id_libro    IS NOT NULL THEN 'Libro'
                WHEN pa.num_registro IS NOT NULL THEN 'Patente'
                ELSE 'Sin clasificar' END                            AS tipo,
           COALESCE(CONCAT(r.nombre_revista, IFNULL(CONCAT(' (', r.quartil, ')'), ' (Regional)')),
                    CONCAT(c.entidad_organizadora, ' - ', c.ambito),
                    l.editorial,
                    CONCAT('Registro ', pa.num_registro, ' - ', pa.estado)) AS medio,
           IFNULL(CAST(COALESCE(c.fecha_inicio, l.fecha_publicacion,
                    pa.fecha_solicitud) AS CHAR), 'No registra')     AS fecha
      FROM productos pr
     INNER JOIN proyecto_investigacion p ON p.id_proyecto  = pr.id_proyecto
      LEFT JOIN revista  r               ON r.id_producto  = pr.id_producto
      LEFT JOIN congreso c               ON c.id_producto  = pr.id_producto
      LEFT JOIN libro    l               ON l.id_producto  = pr.id_producto
      LEFT JOIN patentes pa              ON pa.id_producto = pr.id_producto
     ORDER BY p.acronimo, pr.num_secuencia;
END$$

DELIMITER ;

-- Incidencia #1 corregida: Total general de sp_ca1 aparece como "Subtotal". Solución: agrupar en una tabla derivada y calcular las etiquetas en la consulta externa.

-- Incidencia #3 corregida: sp_ca5 muestra días restantes negativos. Solución: usar GREATEST(DATEDIFF(...), 0) y mostrar "Indefinido" cuando no hay fecha de fin.

-- Incidencia #4 corregida: sp_cm5 muestra NULL en la fecha de las revistas. Solución: mostrar "No registra" con IFNULL, sin modificar el modelo.
