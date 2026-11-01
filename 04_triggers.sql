-- =====================================================================
-- APE 2 - Administración de Bases de Datos
-- Script 04: Triggers (disparadores)
-- Las tablas auditoria_proyecto, historial_participacion y
-- resumen_proyecto son tablas de apoyo para los triggers; no cambian
-- las tablas del modelo entidad-relación, relacional ni físico.
-- =====================================================================
USE gestion_investigacion;

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
