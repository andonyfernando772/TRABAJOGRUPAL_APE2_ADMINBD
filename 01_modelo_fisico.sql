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
