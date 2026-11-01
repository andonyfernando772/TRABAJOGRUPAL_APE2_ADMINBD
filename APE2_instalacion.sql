-- =====================================================================
-- APE 2 - ADMINISTRACIÓN DE BASES DE DATOS (UEB)
-- Script de INSTALACIÓN: crea la base gestion_investigacion completa
--   1. Modelo físico   2. Datos de prueba
--   3. Funciones y procedimientos   4. Triggers y tablas de apoyo
--
-- phpMyAdmin: pestaña IMPORTAR (o SQL) -> este archivo -> Continuar.
-- No contiene CALL ni SELECT de resultados, por eso se ejecuta de una vez.
-- Las consultas y pruebas están en el archivo APE2_consultas_y_pruebas.sql
-- y se ejecutan una por una en la pestaña SQL.
-- =====================================================================

-- =====================================================================
-- 1. MODELO FÍSICO (script original del equipo)
-- =====================================================================
DROP DATABASE IF EXISTS gestion_investigacion;
CREATE DATABASE gestion_investigacion
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;
USE gestion_investigacion;

CREATE TABLE linea_investigacion (
  id_linea      INT UNSIGNED NOT NULL AUTO_INCREMENT,
  nombre_linea  VARCHAR(150) NOT NULL,
  descriptores  TEXT,
  PRIMARY KEY (id_linea),
  UNIQUE KEY uq_linea_nombre (nombre_linea)
) ENGINE=InnoDB;

CREATE TABLE profesores (
  id_profesor           INT UNSIGNED NOT NULL AUTO_INCREMENT,
  nombre                VARCHAR(150) NOT NULL,
  telefono              VARCHAR(20),
  cargo                 VARCHAR(100) NOT NULL,
  departamento_facultad VARCHAR(150) NOT NULL,
  PRIMARY KEY (id_profesor)
) ENGINE=InnoDB;

CREATE TABLE proyecto_investigacion (
  id_proyecto     INT UNSIGNED NOT NULL AUTO_INCREMENT,
  nombre_proyecto VARCHAR(200) NOT NULL,
  acronimo        VARCHAR(30) NOT NULL,
  presupuesto     DECIMAL(14,2) UNSIGNED NOT NULL DEFAULT 0.00,
  descripcion     TEXT,
  PRIMARY KEY (id_proyecto),
  UNIQUE KEY uq_proyecto_acronimo (acronimo)
) ENGINE=InnoDB;

CREATE TABLE proyecto_linea (
  id_linea    INT UNSIGNED NOT NULL,
  id_proyecto INT UNSIGNED NOT NULL,
  PRIMARY KEY (id_linea, id_proyecto),
  CONSTRAINT fk_pl_linea FOREIGN KEY (id_linea)
    REFERENCES linea_investigacion (id_linea)
    ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_pl_proyecto FOREIGN KEY (id_proyecto)
    REFERENCES proyecto_investigacion (id_proyecto)
    ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE proyecto_profesor (
  id_proyecto INT UNSIGNED NOT NULL,
  id_profesor INT UNSIGNED NOT NULL,
  inicio_pro  DATE NOT NULL,
  fin_pro     DATE NULL,
  PRIMARY KEY (id_proyecto, id_profesor),
  CONSTRAINT fk_pp_proyecto FOREIGN KEY (id_proyecto)
    REFERENCES proyecto_investigacion (id_proyecto)
    ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_pp_profesor FOREIGN KEY (id_profesor)
    REFERENCES profesores (id_profesor)
    ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT ck_pp_fechas CHECK (fin_pro IS NULL OR fin_pro >= inicio_pro)
) ENGINE=InnoDB;

CREATE TABLE productos (
  id_producto  INT UNSIGNED NOT NULL AUTO_INCREMENT,
  id_proyecto  INT UNSIGNED NOT NULL,
  titulo       VARCHAR(255) NOT NULL,
  num_secuencia INT UNSIGNED NOT NULL,
  PRIMARY KEY (id_producto),
  UNIQUE KEY uq_producto_secuencia (id_proyecto, num_secuencia),
  CONSTRAINT fk_prod_proyecto FOREIGN KEY (id_proyecto)
    REFERENCES proyecto_investigacion (id_proyecto)
    ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE libro (
  id_libro          INT UNSIGNED NOT NULL AUTO_INCREMENT,
  id_producto       INT UNSIGNED NOT NULL,
  isbn              VARCHAR(17) NOT NULL,
  editorial         VARCHAR(150) NOT NULL,
  lugar_publicacion VARCHAR(150),
  fecha_publicacion DATE NOT NULL,
  total_paginas     INT UNSIGNED,
  PRIMARY KEY (id_libro),
  UNIQUE KEY uq_libro_producto (id_producto),
  UNIQUE KEY uq_libro_isbn (isbn),
  CONSTRAINT fk_libro_producto FOREIGN KEY (id_producto)
    REFERENCES productos (id_producto)
    ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE congreso (
  id_congreso          INT UNSIGNED NOT NULL AUTO_INCREMENT,
  id_producto          INT UNSIGNED NOT NULL,
  tipo_congreso        VARCHAR(80) NOT NULL,
  fecha_inicio         DATE NOT NULL,
  fecha_fin            DATE NOT NULL,
  lugar_evento         VARCHAR(150) NOT NULL,
  pais                 VARCHAR(80) NOT NULL,
  editorial_actas      VARCHAR(150),
  entidad_organizadora VARCHAR(150),
  tipo_participacion   VARCHAR(80) NOT NULL,
  ambito               ENUM('Local','Nacional','Internacional') NOT NULL DEFAULT 'Nacional',
  PRIMARY KEY (id_congreso),
  UNIQUE KEY uq_congreso_producto (id_producto),
  CONSTRAINT fk_congreso_producto FOREIGN KEY (id_producto)
    REFERENCES productos (id_producto)
    ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT ck_congreso_fechas CHECK (fecha_fin >= fecha_inicio)
) ENGINE=InnoDB;

CREATE TABLE patentes (
  num_registro       VARCHAR(40) NOT NULL,
  id_producto        INT UNSIGNED NOT NULL,
  estado             ENUM('Solicitada','Concedida','Denegada','Caducada') NOT NULL DEFAULT 'Solicitada',
  pais_registro      VARCHAR(80) NOT NULL,
  fecha_concesion    DATE NULL,
  clasificacion_inter VARCHAR(50),
  num_solicitud      VARCHAR(40) NOT NULL,
  fecha_solicitud    DATE NOT NULL,
  PRIMARY KEY (num_registro),
  UNIQUE KEY uq_patente_producto (id_producto),
  CONSTRAINT fk_patente_producto FOREIGN KEY (id_producto)
    REFERENCES productos (id_producto)
    ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT ck_patente_fechas CHECK (fecha_concesion IS NULL OR fecha_concesion >= fecha_solicitud)
) ENGINE=InnoDB;

CREATE TABLE revista (
  id_revista    INT UNSIGNED NOT NULL AUTO_INCREMENT,
  id_producto   INT UNSIGNED NOT NULL,
  nombre_revista VARCHAR(200) NOT NULL,
  editorial     VARCHAR(150) NOT NULL,
  volumen       VARCHAR(20) NOT NULL,
  pagina_inicio INT UNSIGNED,
  pagina_fin    INT UNSIGNED,
  quartil       ENUM('Q1','Q2','Q3','Q4') NULL,
  url           VARCHAR(500),
  doi           VARCHAR(150),
  issn          CHAR(9),
  e_issn        CHAR(9),
  PRIMARY KEY (id_revista),
  UNIQUE KEY uq_revista_producto (id_producto),
  UNIQUE KEY uq_revista_doi (doi),
  CONSTRAINT fk_revista_producto FOREIGN KEY (id_producto)
    REFERENCES productos (id_producto)
    ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT ck_revista_paginas CHECK (pagina_fin IS NULL OR pagina_fin >= pagina_inicio),
  CONSTRAINT ck_revista_issn CHECK (issn IS NOT NULL OR e_issn IS NOT NULL)
) ENGINE=InnoDB;


-- =====================================================================
-- 2. INSERCIÓN DE DATOS DE PRUEBA
-- =====================================================================
-- Líneas de investigación (dominio TIC y líneas con las que se colabora)
INSERT INTO linea_investigacion (nombre_linea, descriptores) VALUES
('Desarrollo de software', 'Ingeniería de software; Aplicaciones web; Aplicaciones móviles'),
('Inteligencia artificial y ciencia de datos', 'Aprendizaje automático; Visión por computador; Análisis de datos'),
('Redes y telecomunicaciones', 'Redes de datos; VoIP; Internet de las cosas'),
('Seguridad de la información', 'Ciberseguridad; Criptografía; Auditoría informática'),
('Sistemas de información y bases de datos', 'SGBD relacional; Bases de datos temporales; Inteligencia de negocios'),
('Producción agropecuaria sostenible', 'Agronomía; Clima; Agricultura de precisión'),
('Emprendimiento e innovación', 'Gestión empresarial; Modelos de negocio; Innovación tecnológica');

-- Profesores
INSERT INTO profesores (nombre, telefono, cargo, departamento_facultad) VALUES
('Carlos Andrés Villacrés Ramos',   '0991234501', 'Director',            'Facultad de Ciencias Administrativas, Gestión Empresarial e Informática'),
('María Fernanda Gavilanes Silva',  '0991234502', 'Director',            'Facultad de Ciencias Administrativas, Gestión Empresarial e Informática'),
('Luis Alberto Chimbo Yánez',       '0991234503', 'Director',            'Facultad de Ciencias Agropecuarias, Recursos Naturales y del Ambiente'),
('Ana Lucía Arellano Torres',       '0991234504', 'Director subrogante', 'Facultad de Ciencias Administrativas, Gestión Empresarial e Informática'),
('Jorge Patricio Naranjo Coloma',   '0991234505', 'Director subrogante', 'Facultad de Ciencias Administrativas, Gestión Empresarial e Informática'),
('Diana Carolina Pazmiño Llerena',  '0991234506', 'Director subrogante', 'Facultad de Ciencias Agropecuarias, Recursos Naturales y del Ambiente'),
('Héctor Iván Sánchez Barragán',    '0991234507', 'Investigador',        'Facultad de Ciencias Administrativas, Gestión Empresarial e Informática'),
('Gabriela Estefanía Mora Lema',    '0991234508', 'Investigador',        'Facultad de Ciencias Administrativas, Gestión Empresarial e Informática'),
('Ramiro Javier Guamán Ortiz',      '0991234509', 'Investigador',        'Facultad de Ciencias Administrativas, Gestión Empresarial e Informática'),
('Paola Alexandra Salazar Vega',    '0991234510', 'Investigador',        'Facultad de Ciencias Agropecuarias, Recursos Naturales y del Ambiente'),
('Edison Fabricio Lombeida Pilco',  '0991234511', 'Investigador',        'Facultad de Ciencias Agropecuarias, Recursos Naturales y del Ambiente'),
('Verónica Isabel Coello Ruiz',     '0991234512', 'Investigador',        'Facultad de Ciencias Administrativas, Gestión Empresarial e Informática'),
('Fausto Rodrigo Escobar Núñez',    '0991234513', 'Investigador',        'Facultad de Ciencias de la Educación, Sociales, Filosóficas y Humanísticas');

-- Proyectos de investigación
INSERT INTO proyecto_investigacion (nombre_proyecto, acronimo, presupuesto, descripcion) VALUES
('Plataforma web para la gestión de la investigación universitaria', 'PLATINV', 18500.00, 'Desarrollar un sistema web para registrar proyectos, investigadores y productos de investigación de la UEB.'),
('Análisis de imágenes satelitales para el monitoreo del clima en Bolívar', 'SATCLIMA', 32000.00, 'Aplicar técnicas de inteligencia artificial sobre imágenes satelitales para analizar el clima de la provincia.'),
('Red IoT para el monitoreo de cultivos andinos', 'IOTAGRO', 24750.00, 'Implementar sensores conectados en red para medir humedad y temperatura en cultivos.'),
('Modelo de ciberseguridad para gobiernos autónomos descentralizados', 'CIBERGAD', 12000.00, 'Proponer un modelo de seguridad de la información para los GAD de la provincia Bolívar.'),
('Repositorio de datos abiertos de la provincia Bolívar', 'DATABOL', 9800.00, 'Construir un repositorio de datos abiertos con información socioeconómica de la provincia.');

-- Líneas que abarca cada proyecto (proyecto_linea)
INSERT INTO proyecto_linea (id_linea, id_proyecto) VALUES
(1,1),(5,1),
(2,2),(6,2),(3,2),
(3,3),(6,3),
(4,4),
(5,5),(2,5);

-- Participación de profesores (director + máximo 4 investigadores)
INSERT INTO proyecto_profesor (id_proyecto, id_profesor, inicio_pro, fin_pro) VALUES
-- Proyecto 1 PLATINV
(1, 1, '2025-03-01', NULL),
(1, 4, '2025-03-01', NULL),
(1, 7, '2025-03-01', NULL),
(1, 8, '2025-04-15', '2026-02-28'),
(1, 12,'2025-03-01', NULL),
-- Proyecto 2 SATCLIMA
(2, 2, '2024-09-01', NULL),
(2, 5, '2024-09-01', NULL),
(2, 10,'2024-09-01', NULL),
(2, 9, '2024-10-01', NULL),
(2, 11,'2025-01-10', NULL),
-- Proyecto 3 IOTAGRO
(3, 3, '2025-06-01', NULL),
(3, 6, '2025-06-01', NULL),
(3, 11,'2025-06-01', NULL),
(3, 9, '2025-06-01', '2026-12-15'),
-- Proyecto 4 CIBERGAD (proyecto ya finalizado)
(4, 1, '2023-02-01', '2024-01-31'),
(4, 5, '2023-02-01', '2024-01-31'),
(4, 8, '2023-02-01', '2024-01-31'),
-- Proyecto 5 DATABOL
(5, 2, '2026-01-05', NULL),
(5, 4, '2026-01-05', NULL),
(5, 7, '2026-01-05', '2026-11-30');
-- El profesor 13 (Fausto Escobar) no participa en ningún proyecto.

-- Productos (resultados) de los proyectos
INSERT INTO productos (id_proyecto, titulo, num_secuencia) VALUES
(1, 'Arquitectura de un sistema web para la gestión de proyectos de investigación', 1),
(1, 'Gestión de la investigación universitaria con software libre', 2),
(1, 'Evaluación de usabilidad de una plataforma de investigación universitaria', 3),
(2, 'Clasificación de cobertura vegetal con imágenes satelitales en Bolívar', 1),
(2, 'Modelo predictivo de precipitaciones con redes neuronales', 2),
(2, 'Método de procesamiento de imágenes satelitales para zonas andinas', 3),
(2, 'Inteligencia artificial aplicada al clima andino', 4),
(3, 'Sensores de bajo costo para la agricultura de precisión', 1),
(3, 'Dispositivo IoT para medir la humedad del suelo', 2),
(4, 'Diagnóstico de seguridad de la información en GAD cantonales', 1),
(4, 'Buenas prácticas de ciberseguridad para gobiernos locales', 2);
-- El proyecto 5 (DATABOL) todavía no tiene productos.

-- Subtipos de producto
INSERT INTO revista (id_producto, nombre_revista, editorial, volumen, pagina_inicio, pagina_fin, quartil, url, doi, issn, e_issn) VALUES
(1, 'Revista Ibérica de Sistemas e Tecnologias de Informação', 'AISTI', '45', 112, 125, 'Q3', 'https://www.risti.xyz', '10.17013/risti.45.112-125', '1646-9895', NULL),
(4, 'Remote Sensing', 'MDPI', '17', 1, 22, 'Q1', 'https://www.mdpi.com/journal/remotesensing', '10.3390/rs17010001', NULL, '2072-4292'),
(5, 'Revista Ciencia UNEMI', 'Universidad Estatal de Milagro', '18', 45, 58, NULL, 'https://ojs.unemi.edu.ec', '10.29076/issn.2528-7737vol18iss47.2025pp45-58p', '1390-4272', '2528-7737'),
(8, 'Computers and Electronics in Agriculture', 'Elsevier', '230', 101, 115, 'Q2', 'https://www.sciencedirect.com/journal/computers-and-electronics-in-agriculture', '10.1016/j.compag.2025.101', '0168-1699', NULL),
(10,'Revista Tecnológica ESPOL', 'ESPOL', '36', 70, 84, 'Q4', 'https://rte.espol.edu.ec', '10.37815/rte.v36n1.2024', '0257-1749', '1390-3659');

INSERT INTO congreso (id_producto, tipo_congreso, fecha_inicio, fecha_fin, lugar_evento, pais, editorial_actas, entidad_organizadora, tipo_participacion, ambito) VALUES
(3, 'Congreso científico', '2026-05-20', '2026-05-22', 'Guaranda', 'Ecuador', 'Editorial UEB', 'Universidad Estatal de Bolívar', 'Ponencia', 'Nacional'),
(11,'Conferencia', '2024-10-08', '2024-10-11', 'Lima', 'Perú', 'IEEE', 'IEEE Sección Perú', 'Artículo en actas', 'Internacional');

INSERT INTO libro (id_producto, isbn, editorial, lugar_publicacion, fecha_publicacion, total_paginas) VALUES
(2, '978-9942-0000-1-1', 'Editorial UEB', 'Guaranda', '2026-03-10', 186),
(7, '978-9942-0000-2-8', 'Editorial UEB', 'Guaranda', '2025-11-20', 240);

INSERT INTO patentes (num_registro, id_producto, estado, pais_registro, fecha_concesion, clasificacion_inter, num_solicitud, fecha_solicitud) VALUES
('SENADI-2025-0457', 6, 'Concedida', 'Ecuador', '2026-04-18', 'G06T 7/00', 'SOL-2025-0457', '2025-05-02'),
('SENADI-2026-0112', 9, 'Solicitada', 'Ecuador', NULL, 'A01G 25/16', 'SOL-2026-0112', '2026-02-14');


-- =====================================================================
-- 3. FUNCIONES Y PROCEDIMIENTOS ALMACENADOS (apartados 2, 3 y 4)
-- =====================================================================
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


-- =====================================================================
-- 4. TRIGGERS Y TABLAS DE APOYO (apartado 5)
-- =====================================================================
DROP TABLE IF EXISTS auditoria_proyecto;
DROP TABLE IF EXISTS historial_participacion;
DROP TABLE IF EXISTS resumen_proyecto;

CREATE TABLE auditoria_proyecto (
    id_auditoria     INT UNSIGNED NOT NULL AUTO_INCREMENT,
    id_proyecto      INT UNSIGNED NOT NULL,
    operacion        ENUM('UPDATE','DELETE') NOT NULL,
    datos_anteriores TEXT,
    datos_nuevos     TEXT,
    usuario          VARCHAR(100) NOT NULL,
    fecha_hora       DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id_auditoria)
) ENGINE=InnoDB;

CREATE TABLE historial_participacion (
    id_historial    INT UNSIGNED NOT NULL AUTO_INCREMENT,
    id_proyecto     INT UNSIGNED NOT NULL,
    id_profesor     INT UNSIGNED NOT NULL,
    inicio_anterior DATE,
    fin_anterior    DATE,
    inicio_nuevo    DATE,
    fin_nuevo       DATE,
    usuario         VARCHAR(100) NOT NULL,
    fecha_cambio    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id_historial)
) ENGINE=InnoDB;

CREATE TABLE resumen_proyecto (
    id_proyecto          INT UNSIGNED NOT NULL,
    total_productos      INT UNSIGNED NOT NULL DEFAULT 0,
    ultima_actualizacion DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id_proyecto),
    CONSTRAINT fk_resumen_proyecto FOREIGN KEY (id_proyecto)
        REFERENCES proyecto_investigacion (id_proyecto)
        ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB;

-- Carga inicial del resumen con los datos que ya existen
INSERT INTO resumen_proyecto (id_proyecto, total_productos)
SELECT p.id_proyecto, COUNT(pr.id_producto)
  FROM proyecto_investigacion p
  LEFT JOIN productos pr ON pr.id_proyecto = p.id_proyecto
 GROUP BY p.id_proyecto;

DROP TRIGGER IF EXISTS trg_validar_participacion;
DROP TRIGGER IF EXISTS trg_auditoria_proyecto_upd;
DROP TRIGGER IF EXISTS trg_auditoria_proyecto_del;
DROP TRIGGER IF EXISTS trg_historial_participacion;
DROP TRIGGER IF EXISTS trg_resumen_producto_ins;
DROP TRIGGER IF EXISTS trg_resumen_producto_del;

DELIMITER $$

-- ---------------------------------------------------------------------
-- T1. VALIDACIÓN DE DATOS (BEFORE INSERT en proyecto_profesor)
-- Reglas de la UEB:
--   a) Un proyecto tiene un solo Director y un solo Director subrogante.
--   b) Máximo 4 investigadores por proyecto (el subrogante es uno de ellos).
--   c) Un profesor participa como máximo en 2 proyectos al mismo tiempo.
-- ---------------------------------------------------------------------
CREATE TRIGGER trg_validar_participacion
BEFORE INSERT ON proyecto_profesor
FOR EACH ROW
BEGIN
    DECLARE v_cargo          VARCHAR(100);
    DECLARE v_mismo_cargo    INT DEFAULT 0;
    DECLARE v_investigadores INT DEFAULT 0;

    SELECT cargo INTO v_cargo FROM profesores WHERE id_profesor = NEW.id_profesor;

    -- a) Director y director subrogante únicos por proyecto
    IF v_cargo IN ('Director', 'Director subrogante') THEN
        SELECT COUNT(*) INTO v_mismo_cargo
          FROM proyecto_profesor pp
          JOIN profesores pf ON pf.id_profesor = pp.id_profesor
         WHERE pp.id_proyecto = NEW.id_proyecto
           AND pf.cargo = v_cargo
           AND (pp.fin_pro IS NULL OR pp.fin_pro >= NEW.inicio_pro);
        IF v_mismo_cargo >= 1 THEN
            SIGNAL SQLSTATE '45000'
               SET MESSAGE_TEXT = 'El proyecto ya tiene un profesor activo con ese cargo (Director o Director subrogante).';
        END IF;
    END IF;

    -- b) Máximo 4 investigadores (incluye al director subrogante)
    IF v_cargo <> 'Director' THEN
        SELECT COUNT(*) INTO v_investigadores
          FROM proyecto_profesor pp
          JOIN profesores pf ON pf.id_profesor = pp.id_profesor
         WHERE pp.id_proyecto = NEW.id_proyecto
           AND pf.cargo <> 'Director'
           AND (pp.fin_pro IS NULL OR pp.fin_pro >= NEW.inicio_pro);
        IF v_investigadores >= 4 THEN
            SIGNAL SQLSTATE '45000'
               SET MESSAGE_TEXT = 'El proyecto ya tiene 4 investigadores activos, que es el máximo permitido.';
        END IF;
    END IF;

    -- c) Máximo 2 proyectos simultáneos por profesor
    IF fn_proyectos_activos(NEW.id_profesor, NEW.inicio_pro) >= 2 THEN
        SIGNAL SQLSTATE '45000'
           SET MESSAGE_TEXT = 'El profesor ya participa en 2 proyectos al mismo tiempo, que es el máximo permitido.';
    END IF;
END$$

-- ---------------------------------------------------------------------
-- T2. AUDITORÍA (AFTER UPDATE y AFTER DELETE en proyecto_investigacion)
-- Guarda quién cambió o eliminó un proyecto, cuándo y qué datos tenía.
-- ---------------------------------------------------------------------
CREATE TRIGGER trg_auditoria_proyecto_upd
AFTER UPDATE ON proyecto_investigacion
FOR EACH ROW
BEGIN
    INSERT INTO auditoria_proyecto (id_proyecto, operacion, datos_anteriores, datos_nuevos, usuario)
    VALUES (OLD.id_proyecto, 'UPDATE',
            CONCAT('nombre=', OLD.nombre_proyecto, '; acronimo=', OLD.acronimo, '; presupuesto=', OLD.presupuesto),
            CONCAT('nombre=', NEW.nombre_proyecto, '; acronimo=', NEW.acronimo, '; presupuesto=', NEW.presupuesto),
            CURRENT_USER());
END$$

CREATE TRIGGER trg_auditoria_proyecto_del
AFTER DELETE ON proyecto_investigacion
FOR EACH ROW
BEGIN
    INSERT INTO auditoria_proyecto (id_proyecto, operacion, datos_anteriores, datos_nuevos, usuario)
    VALUES (OLD.id_proyecto, 'DELETE',
            CONCAT('nombre=', OLD.nombre_proyecto, '; acronimo=', OLD.acronimo, '; presupuesto=', OLD.presupuesto),
            NULL,
            CURRENT_USER());
END$$

-- ---------------------------------------------------------------------
-- T3. REGISTRO HISTÓRICO (AFTER UPDATE en proyecto_profesor)
-- Cada vez que cambian las fechas de participación de un profesor se
-- guarda cómo estaban antes, para no perder la historia del equipo.
-- ---------------------------------------------------------------------
CREATE TRIGGER trg_historial_participacion
AFTER UPDATE ON proyecto_profesor
FOR EACH ROW
BEGIN
    IF NOT (OLD.inicio_pro <=> NEW.inicio_pro) OR NOT (OLD.fin_pro <=> NEW.fin_pro) THEN
        INSERT INTO historial_participacion
               (id_proyecto, id_profesor, inicio_anterior, fin_anterior, inicio_nuevo, fin_nuevo, usuario)
        VALUES (OLD.id_proyecto, OLD.id_profesor, OLD.inicio_pro, OLD.fin_pro,
                NEW.inicio_pro, NEW.fin_pro, CURRENT_USER());
    END IF;
END$$

-- ---------------------------------------------------------------------
-- T4. ACTUALIZACIÓN AUTOMÁTICA DE TABLA RESUMEN (productos)
-- Mantiene al día el total de productos de cada proyecto.
-- ---------------------------------------------------------------------
CREATE TRIGGER trg_resumen_producto_ins
AFTER INSERT ON productos
FOR EACH ROW
BEGIN
    INSERT INTO resumen_proyecto (id_proyecto, total_productos, ultima_actualizacion)
    VALUES (NEW.id_proyecto, 1, NOW())
    ON DUPLICATE KEY UPDATE total_productos = total_productos + 1,
                            ultima_actualizacion = NOW();
END$$

CREATE TRIGGER trg_resumen_producto_del
AFTER DELETE ON productos
FOR EACH ROW
BEGIN
    UPDATE resumen_proyecto
       SET total_productos = GREATEST(total_productos - 1, 0),
           ultima_actualizacion = NOW()
     WHERE id_proyecto = OLD.id_proyecto;
END$$

DELIMITER ;

-- Incidencia #6 corregida: Error #1305: FUNCTION fn_tipo_producto does not exist. Solución: crear primero las 4 funciones y después los procedimientos, respetando el orden del script APE2_instalacion.sql.

-- Incidencia #7 corregida: Error #1044: acceso denegado a information_schema al crear funciones. Solución: escribir el nombre de la base antes de cada función (gestion_investigacion.fn_...) y quitar la consulta de verificación del script.

-- Incidencia #8 corregida: Error #1304: FUNCTION fn_tipo_producto already exists. Solución: usar DROP FUNCTION IF EXISTS antes de cada CREATE FUNCTION.
