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
  resolucion_ingreso  VARCHAR(50)  NULL,
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
