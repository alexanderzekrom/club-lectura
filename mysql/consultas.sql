-- -----------------------------------------------------
-- CONSULTAS DE NEGOCIO - MySQL
-- Club de Lectura
-- -----------------------------------------------------

-- 1. ¿Cuáles son los grupos de lectura y quiénes son sus líderes?
SELECT 
    g.id_grupo,
    g.nombre_grupo,
    g.descripcion,
    u.alias_usuario AS lider_grupo
FROM grupo g
JOIN miembro_grupo mg ON g.id_grupo = mg.id_grupo
JOIN usuario u ON mg.id_usuario = u.id_usuario
WHERE mg.rol = 'LIDER'
ORDER BY g.nombre_grupo;

-- 2. ¿Qué reuniones están programadas para una fecha específica?
SELECT 
    r.id_reunion,
    g.nombre_grupo,
    r.tema,
    r.fecha_hora_inicio,
    r.fecha_hora_fin,
    r.estado
FROM reunion r
JOIN grupo g ON r.id_grupo = g.id_grupo
WHERE DATE(r.fecha_hora_inicio) = '2026-10-25'
ORDER BY r.fecha_hora_inicio;

-- 3. ¿Qué usuarios pertenecen a un grupo específico?
SELECT 
    u.id_usuario,
    u.alias_usuario,
    mg.rol,
    mg.fecha_ingreso
FROM usuario u
JOIN miembro_grupo mg ON u.id_usuario = mg.id_usuario
WHERE mg.id_grupo = 1
ORDER BY mg.rol DESC, u.alias_usuario;

-- 4. ¿Qué libros se han discutido en las reuniones de un grupo?
SELECT 
    g.nombre_grupo,
    r.tema AS reunion_tema,
    rl.titulo_libro,
    rl.autor_referencia,
    rl.notas
FROM reunion_libro rl
JOIN reunion r ON rl.id_reunion = r.id_reunion
JOIN grupo g ON r.id_grupo = g.id_grupo
WHERE g.id_grupo = 1
ORDER BY r.fecha_hora_inicio DESC;

-- 5. ¿Cuántas reuniones ha tenido cada grupo?
SELECT 
    g.id_grupo,
    g.nombre_grupo,
    COUNT(r.id_reunion) AS total_reuniones,
    SUM(CASE WHEN r.estado = 'FINALIZADA' THEN 1 ELSE 0 END) AS reuniones_finalizadas,
    SUM(CASE WHEN r.estado = 'PROGRAMADA' THEN 1 ELSE 0 END) AS reuniones_programadas
FROM grupo g
LEFT JOIN reunion r ON g.id_grupo = r.id_grupo
GROUP BY g.id_grupo, g.nombre_grupo
ORDER BY total_reuniones DESC;

-- 6. ¿Qué reuniones están programadas en un rango de fechas?
SELECT 
    r.id_reunion,
    g.nombre_grupo,
    r.tema,
    r.fecha_hora_inicio,
    r.fecha_hora_fin,
    r.estado,
    u.alias_usuario AS creador
FROM reunion r
JOIN grupo g ON r.id_grupo = g.id_grupo
JOIN usuario u ON r.id_creador = u.id_usuario
WHERE r.fecha_hora_inicio >= '2026-10-25 00:00:00'
  AND r.fecha_hora_inicio <= '2026-10-31 23:59:59'
ORDER BY r.fecha_hora_inicio;

-- 7. ¿Qué usuarios son líderes de grupos?
SELECT DISTINCT
    u.id_usuario,
    u.alias_usuario,
    COUNT(mg.id_grupo) AS grupos_liderados
FROM usuario u
JOIN miembro_grupo mg ON u.id_usuario = mg.id_usuario
WHERE mg.rol = 'LIDER'
GROUP BY u.id_usuario, u.alias_usuario
ORDER BY grupos_liderados DESC;

-- 8. ¿Cuáles son los horarios disponibles para agendar nuevas reuniones?
-- Horarios ocupados en una fecha específica
SELECT 
    DATE_FORMAT(r.fecha_hora_inicio, '%H:%i') AS hora_inicio,
    DATE_FORMAT(r.fecha_hora_fin, '%H:%i') AS hora_fin,
    g.nombre_grupo,
    r.tema
FROM reunion r
JOIN grupo g ON r.id_grupo = g.id_grupo
WHERE DATE(r.fecha_hora_inicio) = '2026-10-25'
  AND r.estado IN ('PROGRAMADA', 'EN_CURSO')
ORDER BY r.fecha_hora_inicio;

-- Horarios disponibles (considerando reglas de negocio)
SELECT 
    cr.valor AS hora_apertura,
    cr2.valor AS hora_cierre
FROM configuracion_reglas cr
JOIN configuracion_reglas cr2 ON cr2.clave = 'HORA_CIERRE'
WHERE cr.clave = 'HORA_APERTURA';

-- 9. ¿Qué reuniones están en cada estado?
SELECT 
    estado,
    COUNT(*) AS cantidad,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS porcentaje
FROM reunion
GROUP BY estado
ORDER BY cantidad DESC;

-- 10. ¿Qué libros se han discutido más frecuentemente?
SELECT 
    rl.titulo_libro,
    rl.autor_referencia,
    COUNT(*) AS veces_discutido,
    COUNT(DISTINCT r.id_grupo) AS grupos_que_lo_discutieron
FROM reunion_libro rl
JOIN reunion r ON rl.id_reunion = r.id_reunion
GROUP BY rl.titulo_libro, rl.autor_referencia
ORDER BY veces_discutido DESC;

-- 11. ¿Qué grupos tienen más miembros?
SELECT 
    g.id_grupo,
    g.nombre_grupo,
    COUNT(mg.id_usuario) AS total_miembros,
    SUM(CASE WHEN mg.rol = 'LIDER' THEN 1 ELSE 0 END) AS total_lideres,
    SUM(CASE WHEN mg.rol = 'MIEMBRO' THEN 1 ELSE 0 END) AS total_miembros_regulares
FROM grupo g
JOIN miembro_grupo mg ON g.id_grupo = mg.id_grupo
GROUP BY g.id_grupo, g.nombre_grupo
ORDER BY total_miembros DESC;

-- 12. ¿Qué reuniones han excedido su duración mínima?
SELECT 
    r.id_reunion,
    g.nombre_grupo,
    r.tema,
    r.fecha_hora_inicio,
    r.fecha_hora_fin,
    TIMESTAMPDIFF(HOUR, r.fecha_hora_inicio, r.fecha_hora_fin) AS duracion_horas,
    cr.valor AS duracion_minima_requerida
FROM reunion r
JOIN grupo g ON r.id_grupo = g.id_grupo
CROSS JOIN configuracion_reglas cr
WHERE cr.clave = 'DURACION_MIN_HORAS'
ORDER BY r.fecha_hora_inicio DESC;
