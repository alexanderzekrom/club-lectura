-- -----------------------------------------------------
-- TABLAS DE AUDITORÍA - MySQL
-- Para registrar errores y cambios en el sistema
-- -----------------------------------------------------

-- Tabla de auditoría de errores
CREATE TABLE auditoria_errores (
    id_error          INT AUTO_INCREMENT PRIMARY KEY,
    tabla_afectada    VARCHAR(50) NOT NULL,
    operacion         VARCHAR(20) NOT NULL,
    mensaje_error     TEXT NOT NULL,
    datos_originales  TEXT,
    usuario_registro  VARCHAR(100) DEFAULT CURRENT_USER(),
    fecha_error       TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL
);

-- Tabla de auditoría de cambios en reuniones
CREATE TABLE auditoria_reuniones (
    id_auditoria      INT AUTO_INCREMENT PRIMARY KEY,
    id_reunion        INT NOT NULL,
    operacion         VARCHAR(20) NOT NULL,
    campo_modificado  VARCHAR(50),
    valor_anterior    VARCHAR(500),
    valor_nuevo       VARCHAR(500),
    usuario_registro  VARCHAR(100) DEFAULT CURRENT_USER(),
    fecha_cambio      TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL
);

-- Tabla de auditoría de cambios en miembros de grupo
CREATE TABLE auditoria_miembros (
    id_auditoria      INT AUTO_INCREMENT PRIMARY KEY,
    id_miembro        INT NOT NULL,
    id_grupo          INT NOT NULL,
    id_usuario        INT NOT NULL,
    operacion         VARCHAR(20) NOT NULL,
    rol_anterior      VARCHAR(20),
    rol_nuevo         VARCHAR(20),
    usuario_registro  VARCHAR(100) DEFAULT CURRENT_USER(),
    fecha_cambio      TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL
);

-- Índices para mejorar rendimiento
CREATE INDEX idx_auditoria_errores_fecha ON auditoria_errores(fecha_error);
CREATE INDEX idx_auditoria_errores_tabla ON auditoria_errores(tabla_afectada);
CREATE INDEX idx_auditoria_reuniones_id ON auditoria_reuniones(id_reunion);
CREATE INDEX idx_auditoria_reuniones_fecha ON auditoria_reuniones(fecha_cambio);
CREATE INDEX idx_auditoria_miembros_grupo ON auditoria_miembros(id_grupo);
CREATE INDEX idx_auditoria_miembros_fecha ON auditoria_miembros(fecha_cambio);
