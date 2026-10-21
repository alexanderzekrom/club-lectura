-- -----------------------------------------------------
-- DATOS DE PRUEBA - Oracle
-- -----------------------------------------------------

-- 1. Crear usuarios de prueba
INSERT INTO usuario (alias_usuario) VALUES ('carlos_reader');
INSERT INTO usuario (alias_usuario) VALUES ('ana_books');
INSERT INTO usuario (alias_usuario) VALUES ('lucia_lector');
COMMIT;

-- 2. Crear un Grupo de Lectura
INSERT INTO grupo (nombre_grupo, descripcion) 
VALUES ('Amigos de la Ciencia Ficción', 'Grupo dedicado a explorar clásicos y novedades de Sci-Fi.');
COMMIT;

-- 3. Asignar miembros y definir al Líder (Carlos es el LIDER, Ana y Lucía son MIEMBROS)
INSERT INTO miembro_grupo (id_grupo, id_usuario, rol) VALUES (1, 1, 'LIDER');
INSERT INTO miembro_grupo (id_grupo, id_usuario, rol) VALUES (1, 2, 'MIEMBRO');
INSERT INTO miembro_grupo (id_grupo, id_usuario, rol) VALUES (1, 3, 'MIEMBRO');
COMMIT;

-- 4. Insertar una Reunión válida agendada por el líder (Carlos: id_usuario = 1)
-- Tema: Análisis de Fundación
-- Horario: 10:00 AM a 12:00 PM (2 horas, dentro del rango 09:00 - 17:00)
INSERT INTO reunion (id_grupo, id_creador, tema, fecha_hora_inicio, fecha_hora_fin)
VALUES (
    1, 
    1, 
    'Análisis del ciclo de Fundación y psicohistoria', 
    TO_TIMESTAMP('2026-10-25 10:00:00', 'YYYY-MM-DD HH24:MI:SS'),
    TO_TIMESTAMP('2026-10-25 12:00:00', 'YYYY-MM-DD HH24:MI:SS')
);
COMMIT;

-- 5. Registrar el libro obligatorio de la reunión en el detalle
INSERT INTO reunion_libro (id_reunion, titulo_libro, autor_referencia, notas)
VALUES (1, 'Fundación', 'Isaac Asimov', 'Discutir los primeros 3 capítulos.');
COMMIT;

-- -----------------------------------------------------
-- DATOS ADICIONALES DE PRUEBA
-- -----------------------------------------------------

-- 6. Crear otro Grupo de Lectura
INSERT INTO grupo (nombre_grupo, descripcion) 
VALUES ('Clásicos Literarios', 'Grupo enfocado en literatura clásica universal.');
COMMIT;

-- 7. Asignar miembros al segundo grupo (Ana como LIDER, Carlos y Lucía como MIEMBROS)
INSERT INTO miembro_grupo (id_grupo, id_usuario, rol) VALUES (2, 2, 'LIDER');
INSERT INTO miembro_grupo (id_grupo, id_usuario, rol) VALUES (2, 1, 'MIEMBRO');
INSERT INTO miembro_grupo (id_grupo, id_usuario, rol) VALUES (2, 3, 'MIEMBRO');
COMMIT;

-- 8. Insertar una Reunión para el segundo grupo
INSERT INTO reunion (id_grupo, id_creador, tema, fecha_hora_inicio, fecha_hora_fin)
VALUES (
    2, 
    2, 
    'Análisis de Don Quijote de la Mancha', 
    TO_TIMESTAMP('2026-10-26 14:00:00', 'YYYY-MM-DD HH24:MI:SS'),
    TO_TIMESTAMP('2026-10-26 16:00:00', 'YYYY-MM-DD HH24:MI:SS')
);
COMMIT;

-- 9. Registrar libros para la segunda reunión
INSERT INTO reunion_libro (id_reunion, titulo_libro, autor_referencia, notas)
VALUES (2, 'Don Quijote de la Mancha', 'Miguel de Cervantes', 'Capítulos 1-10: La salida del hidalgo.');
COMMIT;
