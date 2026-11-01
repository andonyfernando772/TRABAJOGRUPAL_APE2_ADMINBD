-- =====================================================================
-- APE 2 - Consultas y pruebas (ejecutar DESPUÉS de APE2_instalacion.sql)
-- En phpMyAdmin: seleccionar la base gestion_investigacion, pestaña SQL,
-- copiar UNA consulta o UN bloque de prueba a la vez y pulsar Continuar.
-- =====================================================================
USE gestion_investigacion;

-- =====================================================================
-- 5. EJECUCIÓN DE LAS CONSULTAS (apartados 2 y 3)
-- =====================================================================
-- Consultas avanzadas (solución A, elegida)
CALL sp_ca1_productividad_proyectos();
CALL sp_ca2_proyectos_sobre_promedio();
CALL sp_ca3_ultimo_producto_proyecto();
CALL sp_ca4_valoracion_revistas();
CALL sp_ca5_estado_participaciones(60);

-- Consultas multitabla
CALL sp_cm1_equipo_proyecto(NULL);
CALL sp_cm2_carga_profesores();
CALL sp_cm3_productos_por_proyecto();
CALL sp_cm4_cobertura_lineas();
CALL sp_cm5_catalogo_productos();


-- =====================================================================
-- 6. SOLUCIONES ALTERNATIVAS DE LAS CONSULTAS AVANZADAS (solución B)
-- =====================================================================
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


-- =====================================================================
-- 7. PRUEBAS DE CONTROL DE CALIDAD (apartado 6)
-- =====================================================================
-- Las pruebas que DEBEN dar error están comentadas (un error detiene la
-- importación). Para las capturas, ejecútelas en la pestaña SQL una por
-- una y EN ESTE ORDEN, quitando el "-- " del inicio.

-- P01 | Quinto investigador en SATCLIMA -> ERROR 1644 (trigger de validación)
-- INSERT INTO proyecto_profesor (id_proyecto, id_profesor, inicio_pro) VALUES (2, 12, '2026-10-29');

-- P02 | Segundo director en PLATINV -> ERROR 1644 (trigger de validación)
-- INSERT INTO proyecto_profesor (id_proyecto, id_profesor, inicio_pro) VALUES (1, 3, '2026-10-29');

-- P03 | Héctor Sánchez ya está en 2 proyectos -> ERROR 1644 (trigger de validación)
SELECT fn_proyectos_activos(7, '2026-10-29') AS proyectos_activos_hector;
-- INSERT INTO proyecto_profesor (id_proyecto, id_profesor, inicio_pro) VALUES (3, 7, '2026-10-29');

-- P04 | Inserción válida: Fausto Escobar entra a DATABOL
INSERT INTO proyecto_profesor (id_proyecto, id_profesor, inicio_pro)
VALUES (5, 13, '2026-10-29');
CALL sp_cm1_equipo_proyecto(5);

-- P05 | Una participación terminada no bloquea: Gabriela Mora entra a IOTAGRO
INSERT INTO proyecto_profesor (id_proyecto, id_profesor, inicio_pro, fin_pro)
VALUES (3, 8, '2026-11-01', '2027-10-31');
SELECT id_proyecto, id_profesor, inicio_pro, fin_pro
  FROM proyecto_profesor WHERE id_profesor = 8;

-- P06 | Fecha de fin anterior a la de inicio -> ERROR 4025 (CHECK ck_pp_fechas)
-- UPDATE proyecto_profesor SET fin_pro = '2020-01-01' WHERE id_proyecto = 5 AND id_profesor = 13;

-- P07 | Auditoría UPDATE
UPDATE proyecto_investigacion SET presupuesto = 11500.00 WHERE id_proyecto = 5;
SELECT id_auditoria, id_proyecto, operacion,
       SUBSTRING_INDEX(datos_anteriores, '; ', -1) AS antes,
       SUBSTRING_INDEX(datos_nuevos, '; ', -1) AS despues, usuario, fecha_hora
  FROM auditoria_proyecto;

-- P08 | Auditoría DELETE dentro de una transacción que luego se revierte
START TRANSACTION;
DELETE FROM proyecto_investigacion WHERE id_proyecto = 4;
SELECT id_auditoria, id_proyecto, operacion,
       LEFT(datos_anteriores, 55) AS datos_anteriores, usuario
  FROM auditoria_proyecto WHERE operacion = 'DELETE';
ROLLBACK;
SELECT COUNT(*) AS proyectos_despues_del_rollback FROM proyecto_investigacion;

-- P09 | Registro histórico
UPDATE proyecto_profesor SET fin_pro = '2027-06-30'
 WHERE id_proyecto = 3 AND id_profesor = 9;
SELECT id_historial, id_proyecto, id_profesor, fin_anterior, fin_nuevo, usuario
  FROM historial_participacion;

-- P10 | Tabla resumen: 0 -> 2 -> 1
SELECT id_proyecto, total_productos FROM resumen_proyecto WHERE id_proyecto = 5;
INSERT INTO productos (id_proyecto, titulo, num_secuencia)
VALUES (5, 'Portal de datos abiertos de la provincia Bolívar', 1);
INSERT INTO productos (id_proyecto, titulo, num_secuencia)
VALUES (5, 'Producto de prueba', 2);
SELECT id_proyecto, total_productos FROM resumen_proyecto WHERE id_proyecto = 5;
DELETE FROM productos WHERE id_proyecto = 5 AND num_secuencia = 2;
SELECT id_proyecto, total_productos FROM resumen_proyecto WHERE id_proyecto = 5;

-- P11 | Consistencia del resumen frente al conteo real
SELECT r.id_proyecto, r.total_productos AS resumen,
       (SELECT COUNT(*) FROM productos p WHERE p.id_proyecto = r.id_proyecto) AS conteo_real,
       IF(r.total_productos = (SELECT COUNT(*) FROM productos p
                               WHERE p.id_proyecto = r.id_proyecto), 'OK', 'NO COINCIDE') AS verificacion
  FROM resumen_proyecto r;

-- P12 | Secuencia de producto repetida -> ERROR 1062 (UNIQUE uq_producto_secuencia)
-- INSERT INTO productos (id_proyecto, titulo, num_secuencia) VALUES (5, 'Producto duplicado', 1);

-- Incidencia #9 corregida: Error #2014: Commands out of sync al ejecutar el script completo. Solución: separar el script en APE2_instalacion.sql (sin CALL, se importa de una vez) y APE2_consultas_y_pruebas.sql (se ejecuta consulta por consulta).
