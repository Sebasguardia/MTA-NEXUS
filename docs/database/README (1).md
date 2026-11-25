<div align="center">

# MTA NEXUS | Base de datos

**Documentación central de persistencia, seguridad y migraciones**

![MTA: NEXUS](https://img.shields.io/static/v1?label=MTA&message=NEXUS&color=0A1A3A&style=for-the-badge) ![Documento: v1.0](https://img.shields.io/static/v1?label=Documento&message=v1.0&color=0066FF&style=for-the-badge) ![Tablas: 97](https://img.shields.io/static/v1?label=Tablas&message=97&color=0066FF&style=for-the-badge) ![Campos: 975](https://img.shields.io/static/v1?label=Campos&message=975&color=00A1FF&style=for-the-badge) ![FK: 288](https://img.shields.io/static/v1?label=FK&message=288&color=0A1A3A&style=for-the-badge) ![Estado: Diseño](https://img.shields.io/static/v1?label=Estado&message=Dise%C3%B1o&color=92400E&style=for-the-badge)

</div>

> Estado: propuesta técnica para implementación. No representa una base de datos desplegada ni una auditoría de seguridad completada.

---

## Objetivo

Diseño relacional modular de MTA Nexus, compatible con backend NestJS, frontend Next.js, PostgreSQL/Supabase y Drizzle. Incluye la plataforma de proyectos tipo Trello, MIA, Academy, conocimiento, analítica, servicios y administración. Documentación en español; identificadores SQL en inglés. Sin emojis. Badges de color mediante Shields.io (decoración externa opcional, texto legible sin imágenes).

| Documento | Contenido |
|---|---|
| [01_Modelo_Relacional.md](01_Modelo_Relacional.md) | Diagramas Mermaid, relaciones, reglas, módulos y convenciones |
| [02_Diccionario_de_Datos.md](02_Diccionario_de_Datos.md) | Cada tabla y columna: tipo, null, default, FK, UQ, CHECK, índices y acceso |
| [03_Seguridad_RLS_y_Permisos.md](03_Seguridad_RLS_y_Permisos.md) | RBAC, scope, política prevista por tabla, SQL de ejemplo, Storage y pruebas |
| [04_Implementacion_y_Migraciones.md](04_Implementacion_y_Migraciones.md) | Roadmap SQL, Supabase local, conexión, ORM, CSV histórico, operación y calidad |
| [05_DDL_Referencia.sql](05_DDL_Referencia.sql) | SQL generado del mismo diccionario, con RLS ENABLE + FORCE y sin grants de runtime |

## Cómo utilizar estos documentos

1. Leer el modelo relacional y elegir el alcance del MVP.
2. Revisar el diccionario y congelar nombres de campos para los DTO de frontend/backend.
3. Preparar Supabase local y convertir el DDL de referencia en migraciones incrementales.
4. Implementar políticas SQL y permisos por módulo, fixtures y pruebas antes de habilitar endpoints.
5. Mapear Drizzle, desarrollar repositories y conectar frontend services.

**Seguridad:** el SQL de referencia queda cerrado por defecto. No es un esquema listo para producción. No contiene las políticas efectivas completas ni credenciales, ni datos reales, ni un despliegue. No utilizar cuentas propietarias o service_role para lógica empresarial. Validar permisos, compatibilidad y rendimiento en Supabase local.

**Decisiones:** una sola entidad `cards` para tareas, roles y membresías con alcance, historia demo separada de operación, duración en minutos, moneda decimal exacta, registros auditables, almacenamiento privado y fuentes MIA autorizadas. La elección de 97 tablas representa todo el alcance futuro, no obliga a crear todo en la primera iteración.
