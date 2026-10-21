-- -----------------------------------------------------
-- PROCEDIMIENTOS ALMACENADOS - Oracle (PL/SQL)
-- Para realizar inserciones con manejo de errores y auditoría
-- -----------------------------------------------------

-- Procedimiento para registrar errores en auditoría
CREATE OR REPLACE PROCEDURE registrar_error (
    p_tabla_afectada   IN VARCHAR2,
    p_operacion        IN VARCHAR2,
    p_mensaje_error    IN VARCHAR2,
    p_datos_originales IN CLOB DEFAULT NULL
) AS
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
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error al registrar en auditoría: ' || SQLERRM);
END;
/

-- Procedimiento para insertar reunión con validaciones
CREATE OR REPLACE PROCEDURE insertar_reunion (
    p_id_grupo          IN NUMBER,
    p_id_creador        IN NUMBER,
    p_tema              IN VARCHAR2,
    p_fecha_hora_inicio IN TIMESTAMP,
    p_fecha_hora_fin    IN TIMESTAMP,
    p_id_reunion_out    OUT NUMBER
) AS
    v_hora_apertura     VARCHAR2(5);
    v_hora_cierre       VARCHAR2(5);
    v_duracion_min      NUMBER;
    v_es_lider          NUMBER;
    v_solapamiento      NUMBER;
    v_duracion_horas    NUMBER;
BEGIN
    -- Validar que el creador sea líder del grupo
    SELECT COUNT(*) INTO v_es_lider
    FROM miembro_grupo
    WHERE id_grupo = p_id_grupo
      AND id_usuario = p_id_creador
      AND rol = 'LIDER';
    
    IF v_es_lider = 0 THEN
        registrar_error('REUNION', 'INSERT', 
            'El usuario no es líder del grupo');
        RAISE_APPLICATION_ERROR(-20001, 'Solo los líderes pueden crear reuniones');
    END IF;
    
    -- Obtener reglas de negocio
    SELECT valor INTO v_hora_apertura
    FROM configuracion_reglas
    WHERE clave = 'HORA_APERTURA';
    
    SELECT valor INTO v_hora_cierre
    FROM configuracion_reglas
    WHERE clave = 'HORA_CIERRE';
    
    SELECT TO_NUMBER(valor) INTO v_duracion_min
    FROM configuracion_reglas
    WHERE clave = 'DURACION_MIN_HORAS';
    
    -- Validar horario de apertura
    IF TO_CHAR(p_fecha_hora_inicio, 'HH24:MI') < v_hora_apertura THEN
        registrar_error('REUNION', 'INSERT', 
            'La reunión no puede iniciar antes de ' || v_hora_apertura);
        RAISE_APPLICATION_ERROR(-20002, 
            'La reunión no puede iniciar antes de ' || v_hora_apertura);
    END IF;
    
    -- Validar horario de cierre
    IF TO_CHAR(p_fecha_hora_fin, 'HH24:MI') > v_hora_cierre THEN
        registrar_error('REUNION', 'INSERT', 
            'La reunión no puede terminar después de ' || v_hora_cierre);
        RAISE_APPLICATION_ERROR(-20003, 
            'La reunión no puede terminar después de ' || v_hora_cierre);
    END IF;
    
    -- Validar duración mínima
    v_duracion_horas := EXTRACT(HOUR FROM (p_fecha_hora_fin - p_fecha_hora_inicio)) +
                       EXTRACT(MINUTE FROM (p_fecha_hora_fin - p_fecha_hora_inicio)) / 60;
    
    IF v_duracion_horas < v_duracion_min THEN
        registrar_error('REUNION', 'INSERT', 
            'La reunión debe tener al menos ' || v_duracion_min || ' hora(s) de duración');
        RAISE_APPLICATION_ERROR(-20004, 
            'La reunión debe tener al menos ' || v_duracion_min || ' hora(s) de duración');
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
        registrar_error('REUNION', 'INSERT', 
            'Existe solapamiento con otra reunión programada');
        RAISE_APPLICATION_ERROR(-20005, 
            'Existe solapamiento con otra reunión programada');
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
    SELECT id_reunion INTO p_id_reunion_out
    FROM reunion
    WHERE ROWNUM = 1
    ORDER BY id_reunion DESC;
    
    COMMIT;
    
EXCEPTION
    WHEN OTHERS THEN
        registrar_error('REUNION', 'INSERT', SQLERRM);
        RAISE;
END;
/

-- Procedimiento para insertar miembro en grupo
CREATE OR REPLACE PROCEDURE insertar_miembro_grupo (
    p_id_grupo   IN NUMBER,
    p_id_usuario IN NUMBER,
    p_rol        IN VARCHAR2 DEFAULT 'MIEMBRO'
) AS
    v_ya_existe  NUMBER;
    v_lideres    NUMBER;
BEGIN
    -- Validar que el usuario no ya esté en el grupo
    SELECT COUNT(*) INTO v_ya_existe
    FROM miembro_grupo
    WHERE id_grupo = p_id_grupo
      AND id_usuario = p_id_usuario;
    
    IF v_ya_existe > 0 THEN
        registrar_error('MIEMBRO_GRUPO', 'INSERT', 
            'El usuario ya es miembro del grupo');
        RAISE_APPLICATION_ERROR(-20006, 'El usuario ya es miembro del grupo');
    END IF;
    
    -- Si es líder, validar que no haya otro líder
    IF p_rol = 'LIDER' THEN
        SELECT COUNT(*) INTO v_lideres
        FROM miembro_grupo
        WHERE id_grupo = p_id_grupo
          AND rol = 'LIDER';
        
        IF v_lideres > 0 THEN
            registrar_error('MIEMBRO_GRUPO', 'INSERT', 
                'El grupo ya tiene un líder');
            RAISE_APPLICATION_ERROR(-20007, 'El grupo ya tiene un líder');
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
    
EXCEPTION
    WHEN OTHERS THEN
        registrar_error('MIEMBRO_GRUPO', 'INSERT', SQLERRM);
        RAISE;
END;
/

-- Procedimiento para actualizar estado de reunión
CREATE OR REPLACE PROCEDURE actualizar_estado_reunion (
    p_id_reunion IN NUMBER,
    p_nuevo_estado IN VARCHAR2
) AS
    v_estado_actual VARCHAR2(20);
BEGIN
    -- Obtener estado actual
    SELECT estado INTO v_estado_actual
    FROM reunion
    WHERE id_reunion = p_id_reunion;
    
    -- Validar transición de estados
    IF v_estado_actual = 'FINALIZADA' AND p_nuevo_estado != 'CANCELADA' THEN
        registrar_error('REUNION', 'UPDATE', 
            'No se puede cambiar el estado de una reunión finalizada');
        RAISE_APPLICATION_ERROR(-20008, 
            'No se puede cambiar el estado de una reunión finalizada');
    END IF;
    
    IF v_estado_actual = 'CANCELADA' THEN
        registrar_error('REUNION', 'UPDATE', 
            'No se puede cambiar el estado de una reunión cancelada');
        RAISE_APPLICATION_ERROR(-20009, 
            'No se puede cambiar el estado de una reunión cancelada');
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
    
EXCEPTION
    WHEN OTHERS THEN
        registrar_error('REUNION', 'UPDATE', SQLERRM);
        RAISE;
END;
/

-- Procedimiento para insertar libro en reunión
CREATE OR REPLACE PROCEDURE insertar_libro_reunion (
    p_id_reunion       IN NUMBER,
    p_titulo_libro     IN VARCHAR2,
    p_autor_referencia IN VARCHAR2 DEFAULT NULL,
    p_notas            IN VARCHAR2 DEFAULT NULL
) AS
    v_reunion_existe   NUMBER;
BEGIN
    -- Validar que la reunión exista
    SELECT COUNT(*) INTO v_reunion_existe
    FROM reunion
    WHERE id_reunion = p_id_reunion;
    
    IF v_reunion_existe = 0 THEN
        registrar_error('REUNION_LIBRO', 'INSERT', 
            'La reunión no existe');
        RAISE_APPLICATION_ERROR(-20010, 'La reunión no existe');
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
    
EXCEPTION
    WHEN OTHERS THEN
        registrar_error('REUNION_LIBRO', 'INSERT', SQLERRM);
        RAISE;
END;
/
