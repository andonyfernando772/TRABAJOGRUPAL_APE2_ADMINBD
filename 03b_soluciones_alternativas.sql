-- =====================================================================
-- APE 2 - Script 03b: Soluciones alternativas (solución B) de las
-- consultas avanzadas. Se usan para comparar con la solución elegida
-- (solución A, implementada en los procedimientos sp_ca1 ... sp_ca5).
-- =====================================================================
USE gestion_investigacion;

-- CA1-B. Tabla cruzada con SUM(CASE ...) (una columna por tipo) + UNION
--        para el total general.
SELECT p.acronimo AS proyecto,
       SUM(CASE WHEN r.id_revista   IS NOT NULL THEN 1 ELSE 0 END) AS revistas,
       SUM(CASE WHEN c.id_congreso  IS NOT NULL THEN 1 ELSE 0 END) AS congresos,
       SUM(CASE WHEN l.id_libro     IS NOT NULL THEN 1 ELSE 0 END) AS libros,
       SUM(CASE WHEN pa.num_registro IS NOT NULL THEN 1 ELSE 0 END) AS patentes,
       COUNT(*) AS total
  FROM productos pr
  JOIN proyecto_investigacion p ON p.id_proyecto = pr.id_proyecto
  LEFT JOIN revista r   ON r.id_producto  = pr.id_producto
  LEFT JOIN congreso c  ON c.id_producto  = pr.id_producto
  LEFT JOIN libro l     ON l.id_producto  = pr.id_producto
  LEFT JOIN patentes pa ON pa.id_producto = pr.id_producto
 GROUP BY p.acronimo
UNION ALL
SELECT 'TOTAL UEB',
       (SELECT COUNT(*) FROM revista), (SELECT COUNT(*) FROM congreso),
       (SELECT COUNT(*) FROM libro),   (SELECT COUNT(*) FROM patentes),
       (SELECT COUNT(*) FROM productos);

-- CA2-B. Tabla derivada con el promedio unida con CROSS JOIN.
SELECT p.acronimo, LEFT(p.nombre_proyecto, 45) AS nombre_proyecto, p.presupuesto,
       ROUND(a.promedio, 2) AS promedio_ueb,
       ROUND(p.presupuesto - a.promedio, 2) AS diferencia
  FROM proyecto_investigacion p
 CROSS JOIN (SELECT AVG(presupuesto) AS promedio FROM proyecto_investigacion) a
 WHERE p.presupuesto > a.promedio
 ORDER BY p.presupuesto DESC;

-- CA3-B. Tabla derivada con GROUP BY + MAX() y JOIN (sin correlación).
SELECT p.acronimo, pr.num_secuencia, LEFT(pr.titulo, 50) AS titulo,
       fn_tipo_producto(pr.id_producto) AS tipo
  FROM productos pr
  JOIN (SELECT id_proyecto, MAX(num_secuencia) AS ultima
          FROM productos GROUP BY id_proyecto) u
    ON u.id_proyecto = pr.id_proyecto AND u.ultima = pr.num_secuencia
  JOIN proyecto_investigacion p ON p.id_proyecto = pr.id_proyecto
 ORDER BY p.acronimo;

-- CA3-C. Función de ventana ROW_NUMBER() (MariaDB 10.2+ / MySQL 8+).
SELECT acronimo, num_secuencia, titulo, tipo
  FROM (SELECT p.acronimo, pr.num_secuencia, LEFT(pr.titulo, 50) AS titulo,
               fn_tipo_producto(pr.id_producto) AS tipo,
               ROW_NUMBER() OVER (PARTITION BY pr.id_proyecto
                                  ORDER BY pr.num_secuencia DESC) AS fila
          FROM productos pr
          JOIN proyecto_investigacion p ON p.id_proyecto = pr.id_proyecto) x
 WHERE fila = 1
 ORDER BY acronimo;

-- CA4-B. Usar la función almacenada fn_puntaje_revista en lugar del CASE.
SELECT p.acronimo,
       COUNT(*) AS articulos,
       SUM(r.quartil IS NOT NULL) AS alto_impacto,
       SUM(r.quartil IS NULL)     AS regionales,
       SUM(fn_puntaje_revista(r.quartil)) AS puntaje_total
  FROM revista r
  JOIN productos pr ON pr.id_producto = r.id_producto
  JOIN proyecto_investigacion p ON p.id_proyecto = pr.id_proyecto
 GROUP BY p.acronimo
 ORDER BY puntaje_total DESC;

-- CA5-B. Meses calculados con DATEDIFF()/30 (aproximado).
SELECT p.acronimo, pf.nombre AS profesor,
       FLOOR(DATEDIFF(IFNULL(pp.fin_pro, CURDATE()), pp.inicio_pro) / 30) AS meses_aprox,
       TIMESTAMPDIFF(MONTH, pp.inicio_pro, IFNULL(pp.fin_pro, CURDATE()))  AS meses_exactos
  FROM proyecto_profesor pp
  JOIN proyecto_investigacion p ON p.id_proyecto  = pp.id_proyecto
  JOIN profesores pf            ON pf.id_profesor = pp.id_profesor
 HAVING meses_aprox <> meses_exactos;
