-- -----------------------------------------------------
-- TRIGGERS DE REGLAS DE NEGOCIO - MySQL
-- Para hacer cumplir las reglas de negocio automáticamente
-- -----------------------------------------------------

DELIMITER //

-- Trigger antes de insertar reunión: validar reglas de negocio
CREATE TRIGGER trg_bi_reunion
BEFORE INSERT ON reunion
FOR EACH ROW
BEGIN
    DECLARE v_hora_apertura VARCHAR(5);
    DECLARE v_hora_cierre VARCHAR(5);
    DECLARE v_duracion_min INT;
    DECLARE v_es_lider INT;
    DECLARE v_solapamiento INT;
    DECLARE v_duracion_horas DECIMAL(5,2);
    
    -- Validar que el creador sea líder del grupo
    SELECT COUNT(*) INTO v_es_lider
    FROM miembro_grupo
    WHERE id_grupo = NEW.id_grupo
      AND id_usuario = NEW.id_creador
      AND rol = 'LIDER';
    
    IF v_es_lider = 0 THEN
        CALL registrar_error('REUNION', 'INSERT', 
            'El usuario no es líder del grupo');
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Solo los líderes pueden crear reuniones';
    END IF;
    
    -- Obtener reglas de negocio
    SELECT valor INTO v_hora_apertura
    FROM configuracion_reglas
    WHERE clave = 'HORA_APERTURA';
    
    SELECT valor INTO v_hora_cierre
    FROM configuracion_reglas
    WHERE clave = 'HORA_CIERRE';
    
    SELECT CAST(valor AS UNSIGNED) INTO v_duracion_min
    FROM configuracion_reglas
    WHERE clave = 'DURACION_MIN_HORAS';
    
    -- Validar horario de apertura
    IF TIME(NEW.fecha_hora_inicio) < v_hora_apertura THEN
        CALL registrar_error('REUNION', 'INSERT', 
            CONCAT('La reunión no puede iniciar antes de ', v_hora_apertura));
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 
            CONCAT('La reunión no puede iniciar antes de ', v_hora_apertura);
    END IF;
    
    -- Validar horario de cierre
    IF TIME(NEW.fecha_hora_fin) > v_hora_cierre THEN
        CALL registrar_error('REUNION', 'INSERT', 
            CONCAT('La reunión no puede terminar después de ', v_hora_cierre));
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 
            CONCAT('La reunión no puede terminar después de ', v_hora_cierre);
    END IF;
    
    -- Validar duración mínima
    SET v_duracion_horas = TIMESTAMPDIFF(HOUR, NEW.fecha_hora_inicio, NEW.fecha_hora_fin);
    
    IF v_duracion_horas < v_duracion_min THEN
        CALL registrar_error('REUNION', 'INSERT', 
            CONCAT('La reunión debe tener al menos ', v_duracion_min, ' hora(s) de duración'));
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 
            CONCAT('La reunión debe tener al menos ', v_duracion_min, ' hora(s) de duración');
    END IF;
    
    -- Validar solapamiento de reuniones
    SELECT COUNT(*) INTO v_solapamiento
    FROM reunion
    WHERE id_grupo = NEW.id_grupo
      AND estado IN ('PROGRAMADA', 'EN_CURSO')
      AND (
          (NEW.fecha_hora_inicio BETWEEN fecha_hora_inicio AND fecha_hora_fin)
          OR (NEW.fecha_hora_fin BETWEEN fecha_hora_inicio AND fecha_hora_fin)
          OR (fecha_hora_inicio BETWEEN NEW.fecha_hora_inicio AND NEW.fecha_hora_fin)
      );
    
    IF v_solapamiento > 0 THEN
        CALL registrar_error('REUNION', 'INSERT', 
            'Existe solapamiento con otra reunión programada');
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 
            'Existe solapamiento con otra reunión programada';
    END IF;
    
    -- Establecer estado por defecto si es NULL
    IF NEW.estado IS NULL THEN
        SET NEW.estado = 'PROGRAMADA';
    END IF;
    
    -- Establecer fecha de agendada si es NULL
    IF NEW.fecha_agendada IS NULL THEN
        SET NEW.fecha_agendada = CURRENT_TIMESTAMP;
    END IF;
END //

-- Trigger antes de actualizar reunión: validar cambios de estado
CREATE TRIGGER trg_bu_reunion
BEFORE UPDATE ON reunion
FOR EACH ROW
BEGIN
    -- Validar transición de estados
    IF OLD.estado = 'FINALIZADA' AND NEW.estado != 'CANCELADA' AND NEW.estado != 'FINALIZADA' THEN
        CALL registrar_error('REUNION', 'UPDATE', 
            'No se puede cambiar el estado de una reunión finalizada');
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 
            'No se puede cambiar el estado de una reunión finalizada';
    END IF;
    
    IF OLD.estado = 'CANCELADA' AND NEW.estado != 'CANCELADA' THEN
        CALL registrar_error('REUNION', 'UPDATE', 
            'No se puede cambiar el estado de una reunión cancelada');
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 
            'No se puede cambiar el estado de una reunión cancelada';
    END IF;
    
    -- Registrar cambios en auditoría
    IF OLD.estado != NEW.estado THEN
        INSERT INTO auditoria_reuniones (
            id_reunion,
            operacion,
            campo_modificado,
            valor_anterior,
            valor_nuevo
        ) VALUES (
            NEW.id_reunion,
            'UPDATE',
            'estado',
            OLD.estado,
            NEW.estado
        );
    END IF;
    
    IF OLD.tema != NEW.tema THEN
        INSERT INTO auditoria_reuniones (
            id_reunion,
            operacion,
            campo_modificado,
            valor_anterior,
            valor_nuevo
        ) VALUES (
            NEW.id_reunion,
            'UPDATE',
            'tema',
            OLD.tema,
            NEW.tema
        );
    END IF;
END //

-- Trigger antes de insertar miembro_grupo: validar reglas
CREATE TRIGGER trg_bi_miembro_grupo
BEFORE INSERT ON miembro_grupo
FOR EACH ROW
BEGIN
    DECLARE v_ya_existe INT;
    DECLARE v_lideres INT;
    
    -- Validar que el usuario no ya esté en el grupo
    SELECT COUNT(*) INTO v_ya_existe
    FROM miembro_grupo
    WHERE id_grupo = NEW.id_grupo
      AND id_usuario = NEW.id_usuario;
    
    IF v_ya_existe > 0 THEN
        CALL registrar_error('MIEMBRO_GRUPO', 'INSERT', 
            'El usuario ya es miembro del grupo');
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El usuario ya es miembro del grupo';
    END IF;
    
    -- Si es líder, validar que no haya otro líder
    IF NEW.rol = 'LIDER' THEN
        SELECT COUNT(*) INTO v_lideres
        FROM miembro_grupo
        WHERE id_grupo = NEW.id_grupo
          AND rol = 'LIDER';
        
        IF v_lideres > 0 THEN
            CALL registrar_error('MIEMBRO_GRUPO', 'INSERT', 
                'El grupo ya tiene un líder');
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El grupo ya tiene un líder';
        END IF;
    END IF;
    
    -- Establecer rol por defecto si es NULL
    IF NEW.rol IS NULL THEN
        SET NEW.rol = 'MIEMBRO';
    END IF;
    
    -- Establecer fecha de ingreso si es NULL
    IF NEW.fecha_ingreso IS NULL THEN
        SET NEW.fecha_ingreso = CURRENT_TIMESTAMP;
    END IF;
END //

-- Trigger antes de actualizar miembro_grupo: registrar cambios
CREATE TRIGGER trg_bu_miembro_grupo
BEFORE UPDATE ON miembro_grupo
FOR EACH ROW
BEGIN
    -- Registrar cambios de rol en auditoría
    IF OLD.rol != NEW.rol THEN
        INSERT INTO auditoria_miembros (
            id_miembro,
            id_grupo,
            id_usuario,
            operacion,
            rol_anterior,
            rol_nuevo
        ) VALUES (
            NEW.id_miembro,
            NEW.id_grupo,
            NEW.id_usuario,
            'UPDATE',
            OLD.rol,
            NEW.rol
        );
    END IF;
END //

-- Trigger después de insertar miembro_grupo: registrar en auditoría
CREATE TRIGGER trg_ai_miembro_grupo
AFTER INSERT ON miembro_grupo
FOR EACH ROW
BEGIN
    INSERT INTO auditoria_miembros (
        id_miembro,
        id_grupo,
        id_usuario,
        operacion,
        rol_anterior,
        rol_nuevo
    ) VALUES (
        NEW.id_miembro,
        NEW.id_grupo,
        NEW.id_usuario,
        'INSERT',
        NULL,
        NEW.rol
    );
END //

-- Trigger después de eliminar miembro_grupo: registrar en auditoría
CREATE TRIGGER trg_ad_miembro_grupo
AFTER DELETE ON miembro_grupo
FOR EACH ROW
BEGIN
    INSERT INTO auditoria_miembros (
        id_miembro,
        id_grupo,
        id_usuario,
        operacion,
        rol_anterior,
        rol_nuevo
    ) VALUES (
        OLD.id_miembro,
        OLD.id_grupo,
        OLD.id_usuario,
        'DELETE',
        OLD.rol,
        NULL
    );
END //

-- Trigger antes de insertar reunion_libro: validar que la reunión exista
CREATE TRIGGER trg_bi_reunion_libro
BEFORE INSERT ON reunion_libro
FOR EACH ROW
BEGIN
    DECLARE v_reunion_existe INT;
    
    -- Validar que la reunión exista
    SELECT COUNT(*) INTO v_reunion_existe
    FROM reunion
    WHERE id_reunion = NEW.id_reunion;
    
    IF v_reunion_existe = 0 THEN
        CALL registrar_error('REUNION_LIBRO', 'INSERT', 
            'La reunión no existe');
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La reunión no existe';
    END IF;
END //

DELIMITER ;
