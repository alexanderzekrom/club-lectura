-- -----------------------------------------------------
-- PROCEDIMIENTOS ALMACENADOS - MySQL
-- Para realizar inserciones con manejo de errores y auditoría
-- -----------------------------------------------------

DELIMITER //

-- Procedimiento para registrar errores en auditoría
CREATE PROCEDURE registrar_error (
    IN p_tabla_afectada   VARCHAR(50),
    IN p_operacion        VARCHAR(20),
    IN p_mensaje_error    TEXT,
    IN p_datos_originales TEXT
)
BEGIN
    INSERT INTO auditoria_errores (
        tabla_afectada,
        operacion,
        mensaje_error,
        datos_originales
    ) VALUES (
        p_tabla_afectada,
        p_operacion,
        p_mensaje_error,
        p_datos_originales
    );
    COMMIT;
END //

-- Procedimiento para insertar reunión con validaciones
CREATE PROCEDURE insertar_reunion (
    IN p_id_grupo          INT,
    IN p_id_creador        INT,
    IN p_tema              VARCHAR(200),
    IN p_fecha_hora_inicio DATETIME,
    IN p_fecha_hora_fin    DATETIME,
    OUT p_id_reunion_out   INT
)
BEGIN
    DECLARE v_hora_apertura VARCHAR(5);
    DECLARE v_hora_cierre VARCHAR(5);
    DECLARE v_duracion_min INT;
    DECLARE v_es_lider INT;
    DECLARE v_solapamiento INT;
    DECLARE v_duracion_horas DECIMAL(5,2);
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        CALL registrar_error('REUNION', 'INSERT', 
            CONCAT('Error al insertar reunión: ', SQLSTATE, ' - ', SQLERRM));
    END;
    
    START TRANSACTION;
    
    -- Validar que el creador sea líder del grupo
    SELECT COUNT(*) INTO v_es_lider
    FROM miembro_grupo
    WHERE id_grupo = p_id_grupo
      AND id_usuario = p_id_creador
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
    IF TIME(p_fecha_hora_inicio) < v_hora_apertura THEN
        CALL registrar_error('REUNION', 'INSERT', 
            CONCAT('La reunión no puede iniciar antes de ', v_hora_apertura));
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 
            CONCAT('La reunión no puede iniciar antes de ', v_hora_apertura);
    END IF;
    
    -- Validar horario de cierre
    IF TIME(p_fecha_hora_fin) > v_hora_cierre THEN
        CALL registrar_error('REUNION', 'INSERT', 
            CONCAT('La reunión no puede terminar después de ', v_hora_cierre));
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 
            CONCAT('La reunión no puede terminar después de ', v_hora_cierre);
    END IF;
    
    -- Validar duración mínima
    SET v_duracion_horas = TIMESTAMPDIFF(HOUR, p_fecha_hora_inicio, p_fecha_hora_fin);
    
    IF v_duracion_horas < v_duracion_min THEN
        CALL registrar_error('REUNION', 'INSERT', 
            CONCAT('La reunión debe tener al menos ', v_duracion_min, ' hora(s) de duración'));
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 
            CONCAT('La reunión debe tener al menos ', v_duracion_min, ' hora(s) de duración');
    END IF;
    
    -- Validar solapamiento de reuniones
    SELECT COUNT(*) INTO v_solapamiento
    FROM reunion
    WHERE id_grupo = p_id_grupo
      AND estado IN ('PROGRAMADA', 'EN_CURSO')
      AND (
          (p_fecha_hora_inicio BETWEEN fecha_hora_inicio AND fecha_hora_fin)
          OR (p_fecha_hora_fin BETWEEN fecha_hora_inicio AND fecha_hora_fin)
          OR (fecha_hora_inicio BETWEEN p_fecha_hora_inicio AND p_fecha_hora_fin)
      );
    
    IF v_solapamiento > 0 THEN
        CALL registrar_error('REUNION', 'INSERT', 
            'Existe solapamiento con otra reunión programada');
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 
            'Existe solapamiento con otra reunión programada';
    END IF;
    
    -- Insertar la reunión
    INSERT INTO reunion (
        id_grupo,
        id_creador,
        tema,
        fecha_hora_inicio,
        fecha_hora_fin,
        estado
    ) VALUES (
        p_id_grupo,
        p_id_creador,
        p_tema,
        p_fecha_hora_inicio,
        p_fecha_hora_fin,
        'PROGRAMADA'
    );
    
    -- Retornar el ID generado
    SET p_id_reunion_out = LAST_INSERT_ID();
    
    COMMIT;
END //

-- Procedimiento para insertar miembro en grupo
CREATE PROCEDURE insertar_miembro_grupo (
    IN p_id_grupo   INT,
    IN p_id_usuario INT,
    IN p_rol        VARCHAR(20)
)
BEGIN
    DECLARE v_ya_existe INT;
    DECLARE v_lideres INT;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        CALL registrar_error('MIEMBRO_GRUPO', 'INSERT', 
            CONCAT('Error al insertar miembro: ', SQLSTATE, ' - ', SQLERRM));
    END;
    
    START TRANSACTION;
    
    -- Validar que el usuario no ya esté en el grupo
    SELECT COUNT(*) INTO v_ya_existe
    FROM miembro_grupo
    WHERE id_grupo = p_id_grupo
      AND id_usuario = p_id_usuario;
    
    IF v_ya_existe > 0 THEN
        CALL registrar_error('MIEMBRO_GRUPO', 'INSERT', 
            'El usuario ya es miembro del grupo');
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El usuario ya es miembro del grupo';
    END IF;
    
    -- Si es líder, validar que no haya otro líder
    IF p_rol = 'LIDER' THEN
        SELECT COUNT(*) INTO v_lideres
        FROM miembro_grupo
        WHERE id_grupo = p_id_grupo
          AND rol = 'LIDER';
        
        IF v_lideres > 0 THEN
            CALL registrar_error('MIEMBRO_GRUPO', 'INSERT', 
                'El grupo ya tiene un líder');
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El grupo ya tiene un líder';
        END IF;
    END IF;
    
    -- Insertar miembro
    INSERT INTO miembro_grupo (
        id_grupo,
        id_usuario,
        rol
    ) VALUES (
        p_id_grupo,
        p_id_usuario,
        p_rol
    );
    
    COMMIT;
END //

-- Procedimiento para actualizar estado de reunión
CREATE PROCEDURE actualizar_estado_reunion (
    IN p_id_reunion INT,
    IN p_nuevo_estado VARCHAR(20)
)
BEGIN
    DECLARE v_estado_actual VARCHAR(20);
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        CALL registrar_error('REUNION', 'UPDATE', 
            CONCAT('Error al actualizar estado: ', SQLSTATE, ' - ', SQLERRM));
    END;
    
    START TRANSACTION;
    
    -- Obtener estado actual
    SELECT estado INTO v_estado_actual
    FROM reunion
    WHERE id_reunion = p_id_reunion;
    
    -- Validar transición de estados
    IF v_estado_actual = 'FINALIZADA' AND p_nuevo_estado != 'CANCELADA' THEN
        CALL registrar_error('REUNION', 'UPDATE', 
            'No se puede cambiar el estado de una reunión finalizada');
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 
            'No se puede cambiar el estado de una reunión finalizada';
    END IF;
    
    IF v_estado_actual = 'CANCELADA' THEN
        CALL registrar_error('REUNION', 'UPDATE', 
            'No se puede cambiar el estado de una reunión cancelada');
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 
            'No se puede cambiar el estado de una reunión cancelada';
    END IF;
    
    -- Actualizar estado
    UPDATE reunion
    SET estado = p_nuevo_estado
    WHERE id_reunion = p_id_reunion;
    
    -- Registrar en auditoría
    INSERT INTO auditoria_reuniones (
        id_reunion,
        operacion,
        campo_modificado,
        valor_anterior,
        valor_nuevo
    ) VALUES (
        p_id_reunion,
        'UPDATE',
        'estado',
        v_estado_actual,
        p_nuevo_estado
    );
    
    COMMIT;
END //

-- Procedimiento para insertar libro en reunión
CREATE PROCEDURE insertar_libro_reunion (
    IN p_id_reunion       INT,
    IN p_titulo_libro     VARCHAR(200),
    IN p_autor_referencia VARCHAR(150),
    IN p_notas            VARCHAR(500)
)
BEGIN
    DECLARE v_reunion_existe INT;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        CALL registrar_error('REUNION_LIBRO', 'INSERT', 
            CONCAT('Error al insertar libro: ', SQLSTATE, ' - ', SQLERRM));
    END;
    
    START TRANSACTION;
    
    -- Validar que la reunión exista
    SELECT COUNT(*) INTO v_reunion_existe
    FROM reunion
    WHERE id_reunion = p_id_reunion;
    
    IF v_reunion_existe = 0 THEN
        CALL registrar_error('REUNION_LIBRO', 'INSERT', 
            'La reunión no existe');
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La reunión no existe';
    END IF;
    
    -- Insertar libro
    INSERT INTO reunion_libro (
        id_reunion,
        titulo_libro,
        autor_referencia,
        notas
    ) VALUES (
        p_id_reunion,
        p_titulo_libro,
        p_autor_referencia,
        p_notas
    );
    
    COMMIT;
END //

DELIMITER ;
