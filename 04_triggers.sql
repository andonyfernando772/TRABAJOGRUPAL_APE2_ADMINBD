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
