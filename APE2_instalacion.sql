-- APE 2 - Instalación completa de gestion_investigacion (importar en phpMyAdmin con utf-8)

-- =====================================================================
-- APE 2 - Base de datos gestion_investigacion (UEB)
-- 01. Modelo físico (MariaDB / MySQL) según el modelo E/R y el relacional
-- =====================================================================
DROP DATABASE IF EXISTS gestion_investigacion;
CREATE DATABASE gestion_investigacion
  CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE gestion_investigacion;

-- Línea Investigación
CREATE TABLE linea_investigacion (
  id_linea      INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  nombre_linea  VARCHAR(150) NOT NULL,
  descriptores  TEXT NULL,
  CONSTRAINT uq_linea_nombre UNIQUE (nombre_linea)
) ENGINE=InnoDB;

-- Profesores
CREATE TABLE profesores (
  id_profesor            INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  nombre                 VARCHAR(150) NOT NULL,
  telefono               VARCHAR(20)  NULL,
  departamento_facultad  VARCHAR(150) NOT NULL
) ENGINE=InnoDB;

-- Proyecto Investigación
CREATE TABLE proyecto_investigacion (
  id_proyecto                      INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  nombre_proyecto                  VARCHAR(200) NOT NULL,
  acronimo                         VARCHAR(30)  NOT NULL,
  presupuesto                      DECIMAL(14,2) UNSIGNED NOT NULL DEFAULT 0,
  programa                         VARCHAR(150) NOT NULL,
  descripcion                      TEXT NULL,
  inicio_pro                       DATE NOT NULL,
  fin_pro                          DATE NOT NULL,
  resolucion_consejo_uni_aprobado  VARCHAR(50) NOT NULL,
  resolucion_consejo_uni_cierre    VARCHAR(50) NULL,
  prorroga                         DATE NULL,
  CONSTRAINT uq_proyecto_acronimo UNIQUE (acronimo),
  CONSTRAINT ck_proyecto_fechas   CHECK (fin_pro >= inicio_pro),
  CONSTRAINT ck_proyecto_prorroga CHECK (prorroga IS NULL OR prorroga > fin_pro)
) ENGINE=InnoDB;

-- Relación abarca (Línea N:M Proyecto)
CREATE TABLE proyecto_linea (
  id_linea     INT UNSIGNED NOT NULL,
  id_proyecto  INT UNSIGNED NOT NULL,
  PRIMARY KEY (id_linea, id_proyecto),
  CONSTRAINT fk_pl_linea    FOREIGN KEY (id_linea)    REFERENCES linea_investigacion(id_linea)
    ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_pl_proyecto FOREIGN KEY (id_proyecto) REFERENCES proyecto_investigacion(id_proyecto)
    ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB;

-- Relación desarrolla (Línea M:N Profesores)
CREATE TABLE linea_profesor (
  id_linea     INT UNSIGNED NOT NULL,
  id_profesor  INT UNSIGNED NOT NULL,
  PRIMARY KEY (id_linea, id_profesor),
  CONSTRAINT fk_lp_linea    FOREIGN KEY (id_linea)    REFERENCES linea_investigacion(id_linea)
    ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_lp_profesor FOREIGN KEY (id_profesor) REFERENCES profesores(id_profesor)
    ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB;

-- Relación trabajan (Proyecto M:N Profesores) = proyecto + profesor
CREATE TABLE proyecto_profesor (
  id_proyecto         INT UNSIGNED NOT NULL,
  id_profesor         INT UNSIGNED NOT NULL,
  num_profesores      TINYINT UNSIGNED NULL,
  cargo               ENUM('Director','Director subrogante','Investigador') NOT NULL,
  resolucion_ingreso  VARCHAR(50)  NOT NULL,
  resolucion_salida   VARCHAR(50)  NULL,
  motivo_salida       VARCHAR(200) NULL,
  PRIMARY KEY (id_proyecto, id_profesor),
  CONSTRAINT ck_pp_salida CHECK (resolucion_salida IS NOT NULL OR motivo_salida IS NULL),
  CONSTRAINT fk_pp_proyecto FOREIGN KEY (id_proyecto) REFERENCES proyecto_investigacion(id_proyecto)
    ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_pp_profesor FOREIGN KEY (id_profesor) REFERENCES profesores(id_profesor)
    ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB;

-- Estudiante (relación participan, Proyecto 1:N Estudiante)
CREATE TABLE estudiante (
  id_estudiante          INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  id_proyecto            INT UNSIGNED NOT NULL,
  nombres_est            VARCHAR(150) NOT NULL,
  telefono_est           VARCHAR(20)  NULL,
  departamento_facultad  VARCHAR(150) NOT NULL,
  CONSTRAINT fk_est_proyecto FOREIGN KEY (id_proyecto) REFERENCES proyecto_investigacion(id_proyecto)
    ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB;

-- Tipo_pro (relación genera, Tipo_pro 1:N Productos)
CREATE TABLE tipo_pro (
  id_tipo           TINYINT UNSIGNED PRIMARY KEY,
  descripcion_tipo  VARCHAR(30) NOT NULL,
  CONSTRAINT uq_tipo_descripcion UNIQUE (descripcion_tipo)
) ENGINE=InnoDB;

-- Productos (relación producen, Proyecto 1:N Productos)
CREATE TABLE productos (
  id_producto         INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  id_proyecto         INT UNSIGNED NOT NULL,
  id_tipo             TINYINT UNSIGNED NOT NULL,
  titulo_publicacion  VARCHAR(255) NOT NULL,
  num_secuencia       INT UNSIGNED NOT NULL,
  CONSTRAINT uq_producto_secuencia UNIQUE (id_proyecto, num_secuencia),
  CONSTRAINT uq_producto_tipo      UNIQUE (id_producto, id_tipo),
  CONSTRAINT fk_prod_proyecto FOREIGN KEY (id_proyecto) REFERENCES proyecto_investigacion(id_proyecto)
    ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_prod_tipo     FOREIGN KEY (id_tipo) REFERENCES tipo_pro(id_tipo)
    ON UPDATE CASCADE
) ENGINE=InnoDB;

-- Libro (id_tipo = 3)
CREATE TABLE libro (
  id_libro           INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  id_producto        INT UNSIGNED NOT NULL,
  id_tipo            TINYINT UNSIGNED NOT NULL DEFAULT 3,
  isbn               VARCHAR(17)  NOT NULL,
  titulo_libro       VARCHAR(255) NOT NULL,
  editorial          VARCHAR(150) NOT NULL,
  lugar_publicacion  VARCHAR(150) NULL,
  fecha_publicacion  DATE NOT NULL,
  total_paginas      INT UNSIGNED NULL,
  CONSTRAINT uq_libro_producto UNIQUE (id_producto),
  CONSTRAINT uq_libro_isbn     UNIQUE (isbn),
  CONSTRAINT ck_libro_tipo     CHECK (id_tipo = 3),
  CONSTRAINT fk_libro_producto FOREIGN KEY (id_producto, id_tipo) REFERENCES productos(id_producto, id_tipo)
    ON DELETE CASCADE
) ENGINE=InnoDB;

-- Publicación Congreso (id_tipo = 2)
CREATE TABLE publicacion_congreso (
  id_congreso           INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  id_producto           INT UNSIGNED NOT NULL,
  id_tipo               TINYINT UNSIGNED NOT NULL DEFAULT 2,
  nombre_congreso       VARCHAR(200) NOT NULL,
  tipo_congreso         VARCHAR(80)  NOT NULL,
  fecha_inicio          DATE NOT NULL,
  fecha_fin             DATE NOT NULL,
  lugar_celebracion     VARCHAR(150) NOT NULL,
  pais                  VARCHAR(80)  NOT NULL,
  editorial_actas       VARCHAR(150) NULL,
  entidad_organizadora  VARCHAR(150) NULL,
  tipo_participacion    VARCHAR(80)  NOT NULL,
  ambito                ENUM('Local','Nacional','Internacional') NOT NULL DEFAULT 'Nacional',
  CONSTRAINT uq_congreso_producto UNIQUE (id_producto),
  CONSTRAINT ck_congreso_tipo     CHECK (id_tipo = 2),
  CONSTRAINT ck_congreso_fechas   CHECK (fecha_fin >= fecha_inicio),
  CONSTRAINT fk_congreso_producto FOREIGN KEY (id_producto, id_tipo) REFERENCES productos(id_producto, id_tipo)
    ON DELETE CASCADE
) ENGINE=InnoDB;

-- Patentes (id_tipo = 4)
CREATE TABLE patentes (
  num_registro         VARCHAR(40) PRIMARY KEY,
  id_producto          INT UNSIGNED NOT NULL,
  id_tipo              TINYINT UNSIGNED NOT NULL DEFAULT 4,
  nombre_patente       VARCHAR(200) NOT NULL,
  estado               ENUM('Solicitada','Concedida','Denegada','Caducada') NOT NULL DEFAULT 'Solicitada',
  pais_registro        VARCHAR(80) NOT NULL,
  fecha_concesion      DATE NULL,
  num_solicitud        VARCHAR(40) NOT NULL,
  fecha_solicitud      DATE NOT NULL,
  clasificacion_inter  VARCHAR(50) NULL,
  CONSTRAINT uq_patente_producto UNIQUE (id_producto),
  CONSTRAINT ck_patente_tipo     CHECK (id_tipo = 4),
  CONSTRAINT ck_patente_fechas   CHECK (fecha_concesion IS NULL OR fecha_concesion >= fecha_solicitud),
  CONSTRAINT fk_patente_producto FOREIGN KEY (id_producto, id_tipo) REFERENCES productos(id_producto, id_tipo)
    ON DELETE CASCADE
) ENGINE=InnoDB;

-- Publicación Revista (id_tipo = 1)
CREATE TABLE publicacion_revista (
  id_revista      INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  id_producto     INT UNSIGNED NOT NULL,
  id_tipo         TINYINT UNSIGNED NOT NULL DEFAULT 1,
  nombre_revista  VARCHAR(200) NOT NULL,
  editorial       VARCHAR(150) NOT NULL,
  volumen         VARCHAR(20)  NOT NULL,
  pagina_inicio   INT UNSIGNED NULL,
  pagina_fin      INT UNSIGNED NULL,
  quartil         ENUM('Q1','Q2','Q3','Q4') NULL,
  url             VARCHAR(500) NULL,
  doi             VARCHAR(150) NULL,
  issn            CHAR(9) NULL,
  e_issn          CHAR(9) NULL,
  CONSTRAINT uq_revista_producto UNIQUE (id_producto),
  CONSTRAINT uq_revista_doi      UNIQUE (doi),
  CONSTRAINT ck_revista_tipo     CHECK (id_tipo = 1),
  CONSTRAINT ck_revista_paginas  CHECK (pagina_fin IS NULL OR pagina_fin >= pagina_inicio),
  CONSTRAINT fk_revista_producto FOREIGN KEY (id_producto, id_tipo) REFERENCES productos(id_producto, id_tipo)
    ON DELETE CASCADE
) ENGINE=InnoDB;

-- Tablas de apoyo para los triggers
CREATE TABLE auditoria_proyecto (
  id_auditoria      INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  id_proyecto       INT UNSIGNED NOT NULL,
  operacion         ENUM('UPDATE','DELETE') NOT NULL,
  datos_anteriores  TEXT NULL,
  datos_nuevos      TEXT NULL,
  usuario           VARCHAR(100) NOT NULL,
  fecha_hora        DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE historial_participacion (
  id_historial        INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  id_proyecto         INT UNSIGNED NOT NULL,
  id_profesor         INT UNSIGNED NOT NULL,
  cargo_anterior      VARCHAR(30)  NULL,
  cargo_nuevo         VARCHAR(30)  NULL,
  resolucion_salida   VARCHAR(50)  NULL,
  motivo_salida       VARCHAR(200) NULL,
  usuario             VARCHAR(100) NOT NULL,
  fecha_cambio        DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE resumen_proyecto (
  id_proyecto           INT UNSIGNED PRIMARY KEY,
  total_productos       INT UNSIGNED NOT NULL DEFAULT 0,
  ultima_actualizacion  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_resumen_proyecto FOREIGN KEY (id_proyecto) REFERENCES proyecto_investigacion(id_proyecto)
    ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB;

-- =====================================================================
-- 02. Inserción de datos de prueba
-- =====================================================================
USE gestion_investigacion;

INSERT INTO linea_investigacion (id_linea, nombre_linea, descriptores) VALUES
(1, 'Desarrollo de software', 'Ingeniería de software; Aplicaciones web; Aplicaciones móviles'),
(2, 'Inteligencia artificial y ciencia de datos', 'Aprendizaje automático; Visión por computador; Análisis de datos'),
(3, 'Redes y telecomunicaciones', 'Redes de datos; VoIP; Internet de las cosas'),
(4, 'Seguridad de la información', 'Ciberseguridad; Criptografía; Auditoría informática'),
(5, 'Sistemas de información y bases de datos', 'SGBD relacional; Bases de datos temporales; Inteligencia de negocios'),
(6, 'Producción agropecuaria sostenible', 'Agronomía; Clima; Agricultura de precisión'),
(7, 'Emprendimiento e innovación', 'Gestión empresarial; Modelos de negocio; Innovación tecnológica');

INSERT INTO profesores (id_profesor, nombre, telefono, departamento_facultad) VALUES
(1,  'Carlos Andrés Villacrés Ramos',  '0991234501', 'Facultad de Ciencias Administrativas, Gestión Empresarial e Informática'),
(2,  'María Fernanda Gavilanes Silva', '0991234502', 'Facultad de Ciencias Administrativas, Gestión Empresarial e Informática'),
(3,  'Luis Alberto Chimbo Yánez',      '0991234503', 'Facultad de Ciencias Agropecuarias, Recursos Naturales y del Ambiente'),
(4,  'Ana Lucía Arellano Torres',      '0991234504', 'Facultad de Ciencias Administrativas, Gestión Empresarial e Informática'),
(5,  'Jorge Patricio Naranjo Coloma',  '0991234505', 'Facultad de Ciencias Administrativas, Gestión Empresarial e Informática'),
(6,  'Diana Carolina Pazmiño Llerena', '0991234506', 'Facultad de Ciencias Agropecuarias, Recursos Naturales y del Ambiente'),
(7,  'Héctor Iván Sánchez Barragán',   '0991234507', 'Facultad de Ciencias Administrativas, Gestión Empresarial e Informática'),
(8,  'Gabriela Estefanía Mora Lema',   '0991234508', 'Facultad de Ciencias Administrativas, Gestión Empresarial e Informática'),
(9,  'Ramiro Javier Guamán Ortiz',     '0991234509', 'Facultad de Ciencias Administrativas, Gestión Empresarial e Informática'),
(10, 'Paola Alexandra Salazar Vega',   '0991234510', 'Facultad de Ciencias Agropecuarias, Recursos Naturales y del Ambiente'),
(11, 'Edison Fabricio Lombeida Pilco', '0991234511', 'Facultad de Ciencias Agropecuarias, Recursos Naturales y del Ambiente'),
(12, 'Verónica Isabel Coello Ruiz',    '0991234512', 'Facultad de Ciencias Administrativas, Gestión Empresarial e Informática'),
(13, 'Fausto Rodrigo Escobar Núñez',   '0991234513', 'Facultad de Ciencias de la Educación, Sociales, Filosóficas y Humanísticas');

INSERT INTO proyecto_investigacion (id_proyecto, nombre_proyecto, acronimo, presupuesto, programa, descripcion,
       inicio_pro, fin_pro, resolucion_consejo_uni_aprobado, resolucion_consejo_uni_cierre, prorroga) VALUES
(1, 'Plataforma web para la gestión de la investigación universitaria', 'PLATINV', 18500.00,
    'Programa de Desarrollo Tecnológico', 'Desarrollar un sistema web para registrar proyectos, investigadores y productos de investigación de la UEB.',
    '2025-03-01', '2026-12-31', 'RCU-UEB-2025-045', NULL, NULL),
(2, 'Análisis de imágenes satelitales para el monitoreo del clima en Bolívar', 'SATCLIMA', 32000.00,
    'Programa de Ambiente y Clima', 'Aplicar técnicas de inteligencia artificial sobre imágenes satelitales para analizar el clima de la provincia.',
    '2024-09-01', '2026-08-31', 'RCU-UEB-2024-118', NULL, '2027-02-28'),
(3, 'Red IoT para el monitoreo de cultivos andinos', 'IOTAGRO', 24750.00,
    'Programa Agropecuario Sostenible', 'Implementar sensores conectados en red para medir humedad y temperatura en cultivos.',
    '2025-06-01', '2027-06-30', 'RCU-UEB-2025-089', NULL, NULL),
(4, 'Modelo de ciberseguridad para gobiernos autónomos descentralizados', 'CIBERGAD', 12000.00,
    'Programa de Gestión Pública', 'Proponer un modelo de seguridad de la información para los GAD de la provincia Bolívar.',
    '2023-02-01', '2024-01-31', 'RCU-UEB-2023-007', 'RCU-UEB-2024-012', NULL),
(5, 'Repositorio de datos abiertos de la provincia Bolívar', 'DATABOL', 11500.00,
    'Programa de Desarrollo Tecnológico', 'Construir un repositorio de datos abiertos con información socioeconómica de la provincia.',
    '2026-01-05', '2026-11-30', 'RCU-UEB-2025-201', NULL, NULL);

INSERT INTO proyecto_linea (id_linea, id_proyecto) VALUES
(1,1),(5,1),(2,2),(3,2),(6,2),(3,3),(6,3),(4,4),(2,5),(5,5);

INSERT INTO linea_profesor (id_linea, id_profesor) VALUES
(1,1),(1,7),(1,12),(5,4),(5,8),(2,2),(2,5),(2,9),(3,9),(3,11),
(6,3),(6,6),(6,10),(6,11),(4,1),(4,8),(7,13);

INSERT INTO proyecto_profesor (id_proyecto, id_profesor, num_profesores, cargo,
       resolucion_ingreso, resolucion_salida, motivo_salida) VALUES
(1, 1,  1, 'Director',            'RCU-UEB-2025-045', NULL, NULL),
(1, 4,  2, 'Director subrogante', 'RCU-UEB-2025-045', NULL, NULL),
(1, 7,  3, 'Investigador',        'RCU-UEB-2025-045', NULL, NULL),
(1, 8,  5, 'Investigador',        'RCU-UEB-2025-061', 'RCU-UEB-2026-030', 'Cambio de dedicación a docencia'),
(1, 12, 4, 'Investigador',        'RCU-UEB-2025-045', NULL, NULL),
(2, 2,  1, 'Director',            'RCU-UEB-2024-118', NULL, NULL),
(2, 5,  2, 'Director subrogante', 'RCU-UEB-2024-118', NULL, NULL),
(2, 9,  3, 'Investigador',        'RCU-UEB-2024-131', NULL, NULL),
(2, 10, 4, 'Investigador',        'RCU-UEB-2024-118', NULL, NULL),
(2, 11, 5, 'Investigador',        'RCU-UEB-2025-004', NULL, NULL),
(3, 3,  1, 'Director',            'RCU-UEB-2025-089', NULL, NULL),
(3, 6,  2, 'Director subrogante', 'RCU-UEB-2025-089', NULL, NULL),
(3, 9,  3, 'Investigador',        'RCU-UEB-2025-089', NULL, NULL),
(3, 11, 4, 'Investigador',        'RCU-UEB-2025-089', NULL, NULL),
(3, 8,  5, 'Investigador',        'RCU-UEB-2026-150', NULL, NULL),
(4, 1,  1, 'Director',            'RCU-UEB-2023-007', 'RCU-UEB-2024-012', 'Cierre del proyecto'),
(4, 5,  2, 'Director subrogante', 'RCU-UEB-2023-007', 'RCU-UEB-2024-012', 'Cierre del proyecto'),
(4, 8,  3, 'Investigador',        'RCU-UEB-2023-007', 'RCU-UEB-2024-012', 'Cierre del proyecto'),
(5, 2,  1, 'Director',            'RCU-UEB-2025-201', NULL, NULL),
(5, 4,  2, 'Director subrogante', 'RCU-UEB-2025-201', NULL, NULL),
(5, 7,  3, 'Investigador',        'RCU-UEB-2025-201', NULL, NULL);

INSERT INTO estudiante (id_estudiante, id_proyecto, nombres_est, telefono_est, departamento_facultad) VALUES
(1, 1, 'Kevin Alexander Chela Guamán',   '0987654301', 'Facultad de Ciencias Administrativas, Gestión Empresarial e Informática'),
(2, 1, 'Mishel Carolina Yánez Pazmiño',  '0987654302', 'Facultad de Ciencias Administrativas, Gestión Empresarial e Informática'),
(3, 2, 'Bryan Santiago Ruiz Vargas',     '0987654303', 'Facultad de Ciencias Administrativas, Gestión Empresarial e Informática'),
(4, 2, 'Lizbeth Johanna Tixi Coles',     '0987654304', 'Facultad de Ciencias Agropecuarias, Recursos Naturales y del Ambiente'),
(5, 2, 'Jonathan David Sisa Llumitasig', '0987654305', 'Facultad de Ciencias Administrativas, Gestión Empresarial e Informática'),
(6, 3, 'Erika Fernanda Gaibor Arias',    '0987654306', 'Facultad de Ciencias Agropecuarias, Recursos Naturales y del Ambiente'),
(7, 3, 'Marco Vinicio Paredes Cruz',     '0987654307', 'Facultad de Ciencias Agropecuarias, Recursos Naturales y del Ambiente');

INSERT INTO tipo_pro (id_tipo, descripcion_tipo) VALUES
(1, 'Revista'), (2, 'Congreso'), (3, 'Libro'), (4, 'Patente');

INSERT INTO productos (id_producto, id_proyecto, id_tipo, titulo_publicacion, num_secuencia) VALUES
(1,  1, 1, 'Arquitectura de un sistema web para la gestión de proyectos de investigación', 1),
(2,  1, 3, 'Gestión de la investigación universitaria con software libre', 2),
(3,  1, 2, 'Evaluación de usabilidad de una plataforma de investigación universitaria', 3),
(4,  2, 1, 'Clasificación de cobertura vegetal con imágenes satelitales en Bolívar', 1),
(5,  2, 1, 'Modelo predictivo de precipitaciones con redes neuronales', 2),
(6,  2, 4, 'Método de procesamiento de imágenes satelitales para zonas andinas', 3),
(7,  2, 3, 'Inteligencia artificial aplicada al clima andino', 4),
(8,  3, 1, 'Sensores de bajo costo para la agricultura de precisión', 1),
(9,  3, 4, 'Dispositivo IoT para medir la humedad del suelo', 2),
(10, 4, 1, 'Diagnóstico de seguridad de la información en GAD cantonales', 1),
(11, 4, 2, 'Buenas prácticas de ciberseguridad para gobiernos locales', 2),
(12, 5, 2, 'Portal de datos abiertos de la provincia Bolívar', 1);

INSERT INTO publicacion_revista (id_revista, id_producto, nombre_revista, editorial, volumen, pagina_inicio, pagina_fin,
       quartil, url, doi, issn, e_issn) VALUES
(1, 1,  'Revista Ibérica de Sistemas e Tecnologias de Informação', 'AISTI', '45', 112, 125, 'Q3', 'https://www.risti.xyz', '10.17013/risti.45.112-125', '1646-9895', NULL),
(2, 4,  'Remote Sensing', 'MDPI', '17', 1, 22, 'Q1', 'https://www.mdpi.com/journal/remotesensing', '10.3390/rs17010001', NULL, '2072-4292'),
(3, 5,  'Revista Ciencia UNEMI', 'Universidad Estatal de Milagro', '18', 45, 58, NULL, 'https://ojs.unemi.edu.ec', '10.29076/issn.2528-7737vol18iss47.2025pp45-58p', '1390-4272', '2528-7737'),
(4, 8,  'Computers and Electronics in Agriculture', 'Elsevier', '230', 101, 115, 'Q2', 'https://www.sciencedirect.com/journal/computers-and-electronics-in-agriculture', '10.1016/j.compag.2025.101', '0168-1699', NULL),
(5, 10, 'Revista Tecnológica ESPOL', 'ESPOL', '36', 70, 84, 'Q4', 'https://rte.espol.edu.ec', '10.37815/rte.v36n1.2024', '0257-1749', '1390-3659');

INSERT INTO publicacion_congreso (id_congreso, id_producto, nombre_congreso, tipo_congreso, fecha_inicio, fecha_fin,
       lugar_celebracion, pais, editorial_actas, entidad_organizadora, tipo_participacion, ambito) VALUES
(1, 3,  'Congreso Internacional de Ciencia y Tecnología UEB 2026', 'Congreso científico', '2026-05-20', '2026-05-22', 'Guaranda', 'Ecuador', 'Editorial UEB', 'Universidad Estatal de Bolívar', 'Ponencia', 'Nacional'),
(2, 11, 'IEEE ANDESCON 2024', 'Conferencia', '2024-10-08', '2024-10-11', 'Lima', 'Perú', 'IEEE', 'IEEE Sección Perú', 'Artículo en actas', 'Internacional'),
(3, 12, 'Jornadas de Investigación UEB 2026', 'Jornada científica', '2026-10-14', '2026-10-15', 'Guaranda', 'Ecuador', NULL, 'Universidad Estatal de Bolívar', 'Ponencia', 'Local');

INSERT INTO libro (id_libro, id_producto, isbn, titulo_libro, editorial, lugar_publicacion, fecha_publicacion, total_paginas) VALUES
(1, 2, '978-9942-0000-1-1', 'Gestión de la investigación universitaria con software libre', 'Editorial UEB', 'Guaranda', '2026-03-10', 186),
(2, 7, '978-9942-0000-2-8', 'Inteligencia artificial aplicada al clima andino', 'Editorial UEB', 'Guaranda', '2025-11-20', 240);

INSERT INTO patentes (num_registro, id_producto, nombre_patente, estado, pais_registro, fecha_concesion,
       num_solicitud, fecha_solicitud, clasificacion_inter) VALUES
('SENADI-2025-0457', 6, 'Método de procesamiento de imágenes satelitales para zonas andinas', 'Concedida', 'Ecuador', '2026-04-18', 'SOL-2025-0457', '2025-05-02', 'G06T 7/00'),
('SENADI-2026-0112', 9, 'Dispositivo IoT para medir la humedad del suelo', 'Solicitada', 'Ecuador', NULL, 'SOL-2026-0112', '2026-02-14', 'A01G 25/16');

-- Carga inicial de la tabla resumen (los triggers la mantienen desde aquí)
INSERT INTO resumen_proyecto (id_proyecto, total_productos)
SELECT p.id_proyecto, COUNT(pr.id_producto)
  FROM proyecto_investigacion p
  LEFT JOIN productos pr ON pr.id_proyecto = p.id_proyecto
 GROUP BY p.id_proyecto;

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

-- =====================================================================
-- 04. Triggers
-- =====================================================================
USE gestion_investigacion;

DROP TRIGGER IF EXISTS trg_validar_participacion;
DROP TRIGGER IF EXISTS trg_auditoria_proyecto_upd;
DROP TRIGGER IF EXISTS trg_auditoria_proyecto_del;
DROP TRIGGER IF EXISTS trg_historial_participacion;
DROP TRIGGER IF EXISTS trg_resumen_producto_ins;
DROP TRIGGER IF EXISTS trg_resumen_producto_del;

DELIMITER $$

-- Trigger 1. Validación de las reglas de participación de la UEB
CREATE TRIGGER trg_validar_participacion
BEFORE INSERT ON proyecto_profesor
FOR EACH ROW
BEGIN
    DECLARE v_cierre   VARCHAR(50);
    DECLARE v_mismo    INT DEFAULT 0;
    DECLARE v_no_dir   INT DEFAULT 0;
    DECLARE v_equipo   INT DEFAULT 0;

    SELECT resolucion_consejo_uni_cierre INTO v_cierre
      FROM proyecto_investigacion WHERE id_proyecto = NEW.id_proyecto;

    -- a) Un proyecto cerrado no admite nuevos profesores
    IF v_cierre IS NOT NULL THEN
        SIGNAL SQLSTATE '45000'
           SET MESSAGE_TEXT = 'El proyecto ya está cerrado y no admite nuevos profesores.';
    END IF;

    -- b) Un solo Director y un solo Director subrogante activos por proyecto
    IF NEW.cargo IN ('Director', 'Director subrogante') THEN
        SELECT COUNT(*) INTO v_mismo
          FROM proyecto_profesor
         WHERE id_proyecto = NEW.id_proyecto
           AND cargo = NEW.cargo
           AND resolucion_salida IS NULL;
        IF v_mismo >= 1 THEN
            SIGNAL SQLSTATE '45000'
               SET MESSAGE_TEXT = 'El proyecto ya tiene un profesor activo con ese cargo.';
        END IF;
    END IF;

    -- c) Máximo 4 investigadores activos (incluye al Director subrogante)
    IF NEW.cargo <> 'Director' THEN
        SELECT COUNT(*) INTO v_no_dir
          FROM proyecto_profesor
         WHERE id_proyecto = NEW.id_proyecto
           AND cargo <> 'Director'
           AND resolucion_salida IS NULL;
        IF v_no_dir >= 4 THEN
            SIGNAL SQLSTATE '45000'
               SET MESSAGE_TEXT = 'El proyecto ya tiene 4 investigadores activos, que es el máximo permitido.';
        END IF;
    END IF;

    -- d) Máximo 2 proyectos activos al mismo tiempo por profesor
    IF fn_proyectos_activos(NEW.id_profesor) >= 2 THEN
        SIGNAL SQLSTATE '45000'
           SET MESSAGE_TEXT = 'El profesor ya participa en 2 proyectos activos, que es el máximo permitido.';
    END IF;

    -- e) num_profesores guarda el tamaño del equipo con el nuevo integrante
    SELECT COUNT(*) INTO v_equipo
      FROM proyecto_profesor
     WHERE id_proyecto = NEW.id_proyecto AND resolucion_salida IS NULL;
    SET NEW.num_profesores = v_equipo + 1;
END$$

-- Trigger 2. Auditoría de los proyectos (modificación y eliminación)
CREATE TRIGGER trg_auditoria_proyecto_upd
AFTER UPDATE ON proyecto_investigacion
FOR EACH ROW
BEGIN
    INSERT INTO auditoria_proyecto (id_proyecto, operacion, datos_anteriores, datos_nuevos, usuario)
    VALUES (OLD.id_proyecto, 'UPDATE',
            CONCAT('acronimo=', OLD.acronimo, '; presupuesto=', OLD.presupuesto,
                   '; fin_pro=', OLD.fin_pro, '; prorroga=', IFNULL(OLD.prorroga, '-'),
                   '; cierre=', IFNULL(OLD.resolucion_consejo_uni_cierre, '-')),
            CONCAT('acronimo=', NEW.acronimo, '; presupuesto=', NEW.presupuesto,
                   '; fin_pro=', NEW.fin_pro, '; prorroga=', IFNULL(NEW.prorroga, '-'),
                   '; cierre=', IFNULL(NEW.resolucion_consejo_uni_cierre, '-')),
            CURRENT_USER());
END$$

CREATE TRIGGER trg_auditoria_proyecto_del
AFTER DELETE ON proyecto_investigacion
FOR EACH ROW
BEGIN
    INSERT INTO auditoria_proyecto (id_proyecto, operacion, datos_anteriores, datos_nuevos, usuario)
    VALUES (OLD.id_proyecto, 'DELETE',
            CONCAT('nombre=', OLD.nombre_proyecto, '; acronimo=', OLD.acronimo,
                   '; presupuesto=', OLD.presupuesto),
            NULL, CURRENT_USER());
END$$

-- Trigger 3. Registro histórico de las participaciones
CREATE TRIGGER trg_historial_participacion
AFTER UPDATE ON proyecto_profesor
FOR EACH ROW
BEGIN
    IF NOT (OLD.cargo <=> NEW.cargo)
       OR NOT (OLD.resolucion_salida <=> NEW.resolucion_salida) THEN
        INSERT INTO historial_participacion
               (id_proyecto, id_profesor, cargo_anterior, cargo_nuevo,
                resolucion_salida, motivo_salida, usuario)
        VALUES (OLD.id_proyecto, OLD.id_profesor, OLD.cargo, NEW.cargo,
                NEW.resolucion_salida, NEW.motivo_salida, CURRENT_USER());
    END IF;
END$$

-- Trigger 4. Actualización automática de la tabla resumen
CREATE TRIGGER trg_resumen_producto_ins
AFTER INSERT ON productos
FOR EACH ROW
BEGIN
    INSERT INTO resumen_proyecto (id_proyecto, total_productos, ultima_actualizacion)
    VALUES (NEW.id_proyecto, 1, NOW())
    ON DUPLICATE KEY UPDATE total_productos      = total_productos + 1,
                            ultima_actualizacion = NOW();
END$$

CREATE TRIGGER trg_resumen_producto_del
AFTER DELETE ON productos
FOR EACH ROW
BEGIN
    UPDATE resumen_proyecto
       SET total_productos      = IF(total_productos > 0, total_productos - 1, 0),
           ultima_actualizacion = NOW()
     WHERE id_proyecto = OLD.id_proyecto;
END$$

DELIMITER ;
