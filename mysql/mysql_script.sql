-- -----------------------------------------------------
-- CLUB DE LECTURA - Script para MySQL
-- Objetivo: Registrar reuniones de pequeños clubes de lectura
-- Alcance: Pequeño número de personas y grupos
-- -----------------------------------------------------

-- -----------------------------------------------------
-- 1. TABLA: CONFIGURACION_REGLAS (Bloque de Reglas y Horarios)
-- -----------------------------------------------------
CREATE TABLE configuracion_reglas (
    clave         VARCHAR(50) PRIMARY KEY,
    valor         VARCHAR(100) NOT NULL,
    descripcion   VARCHAR(255)
);

-- Inserción de las reglas de negocio base
INSERT INTO configuracion_reglas VALUES ('HORA_APERTURA', '09:00', 'Hora de apertura del club para reuniones');
INSERT INTO configuracion_reglas VALUES ('HORA_CIERRE', '17:00', 'Hora de cierre del club para reuniones');
INSERT INTO configuracion_reglas VALUES ('DURACION_MIN_HORAS', '1', 'Duración mínima en horas por reunión');
COMMIT;

-- -----------------------------------------------------
-- 2. TABLA: USUARIO
-- -----------------------------------------------------
CREATE TABLE usuario (
    id_usuario      INT AUTO_INCREMENT PRIMARY KEY,
    alias_usuario   VARCHAR(50) NOT NULL UNIQUE,
    fecha_registro  TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL
);

-- -----------------------------------------------------
-- 3. TABLA: GRUPO
-- -----------------------------------------------------
CREATE TABLE grupo (
    id_grupo        INT AUTO_INCREMENT PRIMARY KEY,
    nombre_grupo    VARCHAR(100) NOT NULL UNIQUE,
    descripcion     VARCHAR(300),
    fecha_creacion  TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL
);

-- -----------------------------------------------------
-- 4. TABLA: MIEMBRO_GRUPO (Relación M:N + Control de Roles)
-- -----------------------------------------------------
CREATE TABLE miembro_grupo (
    id_miembro      INT AUTO_INCREMENT PRIMARY KEY,
    id_grupo        INT NOT NULL,
    id_usuario      INT NOT NULL,
    rol             VARCHAR(20) DEFAULT 'MIEMBRO' NOT NULL,
    fecha_ingreso   TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT fk_mg_grupo FOREIGN KEY (id_grupo) REFERENCES grupo(id_grupo) ON DELETE CASCADE,
    CONSTRAINT fk_mg_usuario FOREIGN KEY (id_usuario) REFERENCES usuario(id_usuario) ON DELETE CASCADE,
    CONSTRAINT chk_mg_rol CHECK (rol IN ('LIDER', 'MIEMBRO')),
    CONSTRAINT uk_grupo_usuario UNIQUE (id_grupo, id_usuario)
);

-- -----------------------------------------------------
-- 5. TABLA: REUNION
-- -----------------------------------------------------
CREATE TABLE reunion (
    id_reunion          INT AUTO_INCREMENT PRIMARY KEY,
    id_grupo            INT NOT NULL,
    id_creador          INT NOT NULL,
    tema                VARCHAR(200) NOT NULL,
    fecha_hora_inicio   TIMESTAMP NOT NULL,
    fecha_hora_fin      TIMESTAMP NOT NULL,
    estado              VARCHAR(20) DEFAULT 'PROGRAMADA' NOT NULL,
    fecha_agendada      TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT fk_reunion_grupo FOREIGN KEY (id_grupo) REFERENCES grupo(id_grupo),
    CONSTRAINT fk_reunion_creador FOREIGN KEY (id_creador) REFERENCES usuario(id_usuario),
    CONSTRAINT chk_reunion_fechas CHECK (fecha_hora_fin > fecha_hora_inicio),
    CONSTRAINT chk_reunion_estado CHECK (estado IN ('PROGRAMADA', 'EN_CURSO', 'FINALIZADA', 'CANCELADA'))
);

-- -----------------------------------------------------
-- 6. TABLA: REUNION_LIBRO (Detalle de reuniones: libros propuestos/leídos)
-- -----------------------------------------------------
CREATE TABLE reunion_libro (
    id_reunion_libro   INT AUTO_INCREMENT PRIMARY KEY,
    id_reunion         INT NOT NULL,
    titulo_libro       VARCHAR(200) NOT NULL,
    autor_referencia   VARCHAR(150),
    notas              VARCHAR(500),
    CONSTRAINT fk_rl_reunion FOREIGN KEY (id_reunion) REFERENCES reunion(id_reunion) ON DELETE CASCADE
);
