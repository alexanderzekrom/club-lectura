# Club de Lectura

Sistema de base de datos para gestionar reuniones de pequeños clubes de lectura.

## Objetivo

Permitir el registro de reuniones de pequeños clubes de lectura con un número limitado de personas y grupos.

## Alcance

- Registro de libros leídos o propuestos
- Registro de reuniones
- Gestión de grupos y usuarios
- Control de horarios y disponibilidad

## Fuera de alcance

- No se almacena información específica de libros o autores (no es una librería)
- No se registra información personal de los usuarios

## Reglas de negocio

- Las reuniones no pueden solaparse
- Las reuniones deben tener un mínimo de 1 hora de duración
- El total de reuniones diarias no puede exceder las horas de apertura
- Horario de atención: 9:00 AM - 5:00 PM
- Una reunión no puede iniciar antes de la hora de apertura ni solaparse con la hora de cierre
- La reunión debe tener un tema y al menos un libro
- Los usuarios pueden estar en muchos grupos y los grupos tienen muchos usuarios
- Se establece un líder de grupo que es quien agenda las reuniones
- Solo el líder de grupo puede agendar reuniones

## Estructura del proyecto

```
club-lectura/
├── contexto                    # Documentación original del proyecto
├── oracle/                     # Scripts para Oracle
│   ├── oracle_script.sql       # Esquema de tablas
│   ├── datos_prueba.sql        # Datos de prueba
│   ├── consultas.sql           # Consultas de negocio
│   ├── auditoria.sql           # Tablas de auditoría
│   ├── procedimientos.sql      # Procedimientos almacenados
│   └── triggers.sql            # Triggers de reglas de negocio
└── mysql/                      # Scripts para MySQL
    ├── mysql_script.sql        # Esquema de tablas
    ├── datos_prueba.sql        # Datos de prueba
    ├── consultas.sql           # Consultas de negocio
    ├── auditoria.sql           # Tablas de auditoría
    ├── procedimientos.sql      # Procedimientos almacenados
    └── triggers.sql            # Triggers de reglas de negocio
```

## Modelo de datos

### Tablas principales

1. **configuracion_reglas** - Almacena las reglas de negocio y horarios
2. **usuario** - Información de usuarios del sistema
3. **grupo** - Grupos de lectura
4. **miembro_grupo** - Relación entre usuarios y grupos con roles
5. **reunion** - Reuniones programadas
6. **reunion_libro** - Libros asociados a cada reunión

### Tablas de auditoría

1. **auditoria_errores** - Registro de errores del sistema
2. **auditoria_reuniones** - Cambios en reuniones
3. **auditoria_miembros** - Cambios en membresías de grupos

## Instalación

### Oracle

1. Ejecutar el script de esquema:
```bash
sqlplus usuario/password @oracle/oracle_script.sql
```

2. Ejecutar las tablas de auditoría:
```bash
sqlplus usuario/password @oracle/auditoria.sql
```

3. Ejecutar los procedimientos almacenados:
```bash
sqlplus usuario/password @oracle/procedimientos.sql
```

4. Ejecutar los triggers:
```bash
sqlplus usuario/password @oracle/triggers.sql
```

5. (Opcional) Cargar datos de prueba:
```bash
sqlplus usuario/password @oracle/datos_prueba.sql
```

### MySQL

1. Ejecutar el script de esquema:
```bash
mysql -u usuario -p base_datos < mysql/mysql_script.sql
```

2. Ejecutar las tablas de auditoría:
```bash
mysql -u usuario -p base_datos < mysql/auditoria.sql
```

3. Ejecutar los procedimientos almacenados:
```bash
mysql -u usuario -p base_datos < mysql/procedimientos.sql
```

4. Ejecutar los triggers:
```bash
mysql -u usuario -p base_datos < mysql/triggers.sql
```

5. (Opcional) Cargar datos de prueba:
```bash
mysql -u usuario -p base_datos < mysql/datos_prueba.sql
```

## Procedimientos almacenados

### Oracle

- `registrar_error` - Registra errores en la tabla de auditoría
- `insertar_reunion` - Inserta reunión con validaciones de negocio
- `insertar_miembro_grupo` - Inserta miembro en grupo con validaciones
- `actualizar_estado_reunion` - Actualiza estado de reunión con validación de transiciones
- `insertar_libro_reunion` - Inserta libro en reunión

### MySQL

- `registrar_error` - Registra errores en la tabla de auditoría
- `insertar_reunion` - Inserta reunión con validaciones de negocio
- `insertar_miembro_grupo` - Inserta miembro en grupo con validaciones
- `actualizar_estado_reunion` - Actualiza estado de reunión con validación de transiciones
- `insertar_libro_reunion` - Inserta libro en reunión

## Triggers

### Oracle

- `trg_bi_reunion` - Valida reglas antes de insertar reunión
- `trg_bu_reunion` - Valida cambios de estado y audita modificaciones
- `trg_bi_miembro_grupo` - Valida reglas antes de insertar miembro
- `trg_bu_miembro_grupo` - Audita cambios de rol
- `trg_ai_miembro_grupo` - Audita inserciones de miembros
- `trg_ad_miembro_grupo` - Audita eliminaciones de miembros
- `trg_bi_reunion_libro` - Valida existencia de reunión

### MySQL

- `trg_bi_reunion` - Valida reglas antes de insertar reunión
- `trg_bu_reunion` - Valida cambios de estado y audita modificaciones
- `trg_bi_miembro_grupo` - Valida reglas antes de insertar miembro
- `trg_bu_miembro_grupo` - Audita cambios de rol
- `trg_ai_miembro_grupo` - Audita inserciones de miembros
- `trg_ad_miembro_grupo` - Audita eliminaciones de miembros
- `trg_bi_reunion_libro` - Valida existencia de reunión

## Consultas de negocio

El archivo `consultas.sql` incluye 12 consultas para responder preguntas de negocio:

1. Grupos de lectura y sus líderes
2. Reuniones programadas para una fecha específica
3. Usuarios pertenecientes a un grupo específico
4. Libros discutidos en reuniones de un grupo
5. Cantidad de reuniones por grupo
6. Reuniones en un rango de fechas
7. Usuarios que son líderes de grupos
8. Horarios disponibles para agendar reuniones
9. Reuniones por estado
10. Libros más frecuentemente discutidos
11. Grupos con más miembros
12. Duración de reuniones vs reglas

## Autor

Alexander Zekrom
