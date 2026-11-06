-- =====================================================================
-- 03b. Soluciones B de las consultas avanzadas (comparación con la A)
-- =====================================================================
USE gestion_investigacion;

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
