<div align="center">

# MTA NEXUS | Implementación y migraciones

**Supabase local, Drizzle ORM, datos iniciales y operaciones**

![MTA: NEXUS](https://img.shields.io/static/v1?label=MTA&message=NEXUS&color=0A1A3A&style=for-the-badge) ![Documento: v1.0](https://img.shields.io/static/v1?label=Documento&message=v1.0&color=0066FF&style=for-the-badge) ![Entorno: Local first](https://img.shields.io/static/v1?label=Entorno&message=Local%20first&color=166534&style=for-the-badge) ![DDL: SQL versionado](https://img.shields.io/static/v1?label=DDL&message=SQL%20versionado&color=0066FF&style=for-the-badge) ![Costos: Sin SaaS obligatorio](https://img.shields.io/static/v1?label=Costos&message=Sin%20SaaS%20obligatorio&color=0A1A3A&style=for-the-badge)

</div>

> Estado: propuesta técnica para implementación. No representa una base de datos desplegada ni una auditoría de seguridad completada.

---

## 1. Estructura de repositorio propuesta

```text
mta-nexus/
├── apps/
│   ├── web/                       # Next.js: features, services y mocks
│   └── api/
│       ├── src/
│       │   ├── infrastructure/
│       │   │   └── database/
│       │   │       ├── database.module.ts
│       │   │       ├── database.provider.ts
│       │   │       ├── database.tokens.ts
│       │   │       ├── unit-of-work.ts
│       │   │       ├── transaction-context.ts
│       │   │       └── schema/
│       │   │           ├── index.ts
│       │   │           ├── identity.schema.ts
│       │   │           ├── projects.schema.ts
│       │   │           ├── collaboration.schema.ts
│       │   │           ├── time.schema.ts
│       │   │           ├── knowledge.schema.ts
│       │   │           ├── academy.schema.ts
│       │   │           ├── mia.schema.ts
│       │   │           ├── commercial.schema.ts
│       │   │           └── operations.schema.ts
│       │   └── modules/           # repositories por módulo NestJS
│       ├── drizzle.config.ts
│       └── .env.example
├── supabase/
│   ├── config.toml
│   ├── migrations/
│   ├── seed.sql                  # solo fixtures/catálogos autorizados
│   └── tests/                    # SQL RLS / integridad
└── docs/
    └── database/
        ├── README.md
        ├── 01_Modelo_Relacional.md
        ├── 02_Diccionario_de_Datos.md
        ├── 03_Seguridad_RLS_y_Permisos.md
        ├── 04_Implementacion_y_Migraciones.md
        └── 05_DDL_Referencia.sql
```

SQL versionado de `supabase/migrations/` es la única autoridad para DDL. Drizzle mapea las tablas y consulta mediante repositorios. No utilizar `drizzle-kit push` junto con migraciones Supabase ni editar tablas directamente en el Dashboard remoto. Los nombres anteriores son una ampliación de la arquitectura aprobada, no archivos NestJS ya generados.

## 2. Plan de migraciones incremental

El DDL entregado es una fotografía de referencia de todo el alcance. **No copiarlo íntegro a producción**: incluye funcionalidades futuras, no crea permisos efectivos y requiere prueba real. Convertirlo en migraciones pequeñas que se apliquen en orden, acompañando políticas, seeds y pruebas. Las FK que cruzan dominios deben agregarse después de que existan ambos lados; por ejemplo `role_grants.project_id` después de projects. Si se divide en archivos, separar creación de tablas y constraints diferidas según dependencia.

| Orden | Nombre orientativo | Contenido | Puerta de aceptación |
|---|---|---|---|
| 00 | `bootstrap_private_schema` | nexus, roles técnicos, grants mínimos, helpers, esquema privado | Ningún acceso anónimo; runtime no owner |
| 01 | `identity_and_organizations` | profiles, organizations, memberships, preferences, roles, permissions, invitations, settings | Alta y suspensión verificadas |
| 02 | `projects_and_board` | teams, project_members, projects, milestones, boards, columns, cards, grants de proyecto | Lectura por proyecto y alta atómica |
| 03 | `card_collaboration` | labels, assignees, fields, checklists, dependencies, comments, files, attachments, events | FK y permisos, orden y auditoría |
| 04 | `time_and_approvals` | timers, time_entries, versions, approvals, availability | Sin doble timer ni autoaprobación |
| 05 | `operations_base` | outbox, jobs, idempotency, audit, notifications, preferences | Rollback atómico y consumidores idempotentes |
| 06 | `knowledge_and_mia` | documents, versions, ACL, index_jobs, source_refs, conversations, messages, citations, actions, tool_runs | Fuentes vigentes y chats privados |
| 07 | `demo_import_and_reports` | import_batches, import_rows, historical_task_facts, export_jobs | 500 filas conservadas; demo aislado |
| 08 | `calendar_support_automation` | agenda, tickets, plantillas, reglas y runs | Triggers tipados y control de ciclos |
| 09 | `academy` | rutas, cursos, lecciones, evaluaciones, mentorías, logros y certificados | Puntajes y respuestas protegidos |
| 10 | `analytics_ml_speech` | models, predictions, usage, speech_sessions, quotas, integration_settings | Resultados reales y límites de consumo |
| 11 | `commercial` | services, plans, plan_versions, leads, quotes, items | Publicación, vigencia y dinero exacto |
| 12 | `performance_and_hardening` | índices según EXPLAIN, retención, revisión de políticas | Matriz RLS y pruebas de carga aprobadas |

Dividir de nuevo cada migración si supera una unidad revisable. No habilitar rutas de módulo hasta que sus políticas SQL, guards, permisos de columna y reglas transaccionales estén implementados. En equipos, usar archivos de migración append-only después de publicar; no reescribir historial aplicado.

## 3. Preparación local sin costo adicional

Requisitos propuestos: Node.js LTS del stack acordado, pnpm, Docker compatible con Supabase CLI, Git y memoria suficiente. El CLI puede usarse como dependencia de desarrollo (Node compatible); fijar versión en lockfile, no instalar globalmente vía npm si el método no está soportado. PostgreSQL/Supabase local utiliza recursos de tu equipo, no créditos Azure. No se requiere Redis, Azure SQL ni una base vectorial comercial.

```bash
# Ejecutar desde raíz del repositorio una vez inicializado.
pnpm install
# Instalar Supabase CLI como dependencia de desarrollo si aún no está.
pnpm add -Dw supabase
# Solo si todavía no existe supabase/config.toml:
pnpm exec supabase init
pnpm exec supabase start
pnpm exec supabase status
# Crear migración nueva:
pnpm exec supabase migration new bootstrap_private_schema
# Aplicar migraciones y seed en la BD LOCAL de desarrollo (destructivo local):
pnpm exec supabase db reset
```

Antes del reset confirmar que no se necesita conservar el contenido local. Nunca usar `db reset --remote` para un despliegue. La URL y claves locales se consultan con `supabase status`; no copiarlas a commits. No imprimir secretos en CI. Revisar Docker/WSL2 si estás en Windows. Los comandos son guía para un repositorio aún no inicializado.

### Conexión a Supabase hospedado (solo después de pruebas)

```bash
pnpm exec supabase login
pnpm exec supabase link --project-ref TU_PROJECT_REF
pnpm exec supabase migration list
pnpm exec supabase db push --dry-run
# Revisar plan, hacer backup y aprobación de cambios antes de aplicar:
pnpm exec supabase db push
```

Confirmar disponibilidad del flag en la versión instalada. Utilizar la conexión apropiada (directa o pooler), TLS y tamaño de pool adecuado. Mantener ambientes separados; no utilizar datos históricos demo en la organización operativa. Supabase Free está sujeto a límites y disponibilidad; revisar antes de alojar. No se requiere comprar herramientas externas para este diseño.

## 4. Variables de entorno y acceso

Ejemplo de `apps/api/.env.example` (sin valores reales):

```dotenv
NODE_ENV=development
PORT=4000
DATABASE_URL=
# Solo uso de migraciones, no cargar en runtime API:
DATABASE_MIGRATION_URL=
# Identidad Supabase:
SUPABASE_URL=
SUPABASE_PUBLISHABLE_KEY=
SUPABASE_JWT_ISSUER=
SUPABASE_JWT_AUDIENCE=authenticated
# Credencial privilegiada: solo adaptador administrativo de Storage/Auth
SUPABASE_SECRET_KEY=
# Conexión del worker, diferente del rol API
WORKER_DATABASE_URL=
APP_TIMEZONE=America/Lima
APP_CURRENCY=PEN
MIA_ENABLED=false
AZURE_PROJECT_ENDPOINT=
AZURE_AGENT_NAME=
AZURE_SEARCH_ENABLED=false
AZURE_SPEECH_ENABLED=false
AZURE_ML_ENABLED=false
```

Alinear nombres finales con el `env.config.ts` de Nest y modo de autenticación elegido. `DATABASE_URL` usa login restringido que asume permisos runtime revisados, no URL postgres owner. Las credenciales Azure se resuelven por identidad administrada o secretos de servidor según disponibilidad. No incluir claves en variables `NEXT_PUBLIC_*`. No almacenar contraseña Auth en `profiles`. El cliente usa únicamente configuración pública necesaria para su sesión. En logs no mostrar URLs con contraseña.

## 5. Drizzle: ejemplo de mapeo y repositorio

Instalación orientativa en backend: `cd apps/api` y `pnpm add drizzle-orm postgres`; `pnpm add -D drizzle-kit`. Fijar versiones tras comprobar compatibilidad. Mapear SQL existente, incluyendo FK/índices o conservarlos en DDL como autoridad. El siguiente fragmento es una proyección abreviada de `projects` para explicar el patrón, no el esquema completo listo para generar una migración.

```ts
import { pgSchema, uuid, text, integer, timestamp, date } from 'drizzle-orm/pg-core';

export const nexus = pgSchema('nexus');
export const projects = nexus.table('projects', {
  id: uuid('id').defaultRandom().primaryKey(),
  organizationId: uuid('organization_id').notNull(),
  code: text('code').notNull(),
  name: text('name').notNull(),
  status: text('status').notNull().default('planned'),
  dueDate: date('due_date', { mode: 'string' }),
  version: integer('version').notNull().default(1),
  createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
});
```

```ts
// Contrato de repositorio: recibe el contexto de transacción autorizado.
export interface ProjectsRepository<Tx, Project> {
  findById(tx: Tx, organizationId: string, id: string): Promise<Project | null>;
}

// La implementación Drizzle consulta con scope explícito y RLS como defensa.
// No devolver tipos internos del driver al frontend.
```

Al usar introspección, revisar el resultado y excluir esquemas administrados (`auth`, `storage`, extensiones). `numeric` se representa de forma exacta, normalmente string en DTO; `bigint` no serializable directamente en JSON debe convertirse a string o valor seguro validado. El backend convierte snake_case a camelCase mediante mappers. Frontend nunca importa tipos DB; utiliza DTO OpenAPI y mapea a types de cada feature.

## 6. Datos iniciales y bootstrap

`seed.sql` de desarrollo puede crear organizaciones ficticias y catálogos base: permisos, roles, columnas default `todo/doing/review/done/blocked`, etiquetas de muestra, preferencias por defecto. No incluir contraseñas ni claves. Primero crear cuentas de prueba mediante Admin API de Supabase Auth local, después asociar `profiles.auth_user_id` y memberships. No inventar UUID de Auth si no existe. Bootstrap de primera administración requiere canal privilegiado controlado; cerrar ese canal después del alta. Con `FORCE RLS` incluso el owner está sujeto a políticas salvo rol que la eluda por privilegios técnicos; seeds se ejecutan con migrador autorizado y estrategia explícita. Nunca desactivar RLS para facilitar un endpoint.

### CSV histórico original de MTA

Archivo verificado: `MTA_Software_500_Registros_Frontend_Backend(1).csv`. Contiene 500 filas, 9 nombres de participantes, 7 códigos de proyecto/especialidad, 350 registros FN y 150 BK, 470 finalizados, 30 pendientes, 163 retrasos Sí, 307 No y 30 sin dato de retraso. Es material de demostración académica: no se considera un sistema de control de asistencia real.

| CSV original | Campo destino en historical_task_facts | Transformación |
|---|---|---|
| ID_tarea | external_task_id | Mantener código original |
| ID_proyecto | external_project_id | Conservar 7 grupos |
| Proyecto | project_name | Nombre original |
| Practicante | participant_name | Texto demo, no cuenta Auth |
| Especialidad | specialty | FN/BK original; traducir solo UI |
| Tipo_tarea | task_type | Conservar categoría |
| Complejidad | complexity | Conservar categoría |
| Prioridad | priority | Conservar categoría |
| Dependencias | dependency_count | Entero no negativo; no inventar enlaces |
| Horas_estimadas | estimated_minutes | Decimal × 60, validar exactitud y redondeo explícito si se requiere |
| Fecha_inicio | start_date | DATE YYYY-MM-DD |
| Fecha_limite | due_date | DATE YYYY-MM-DD |
| Estado | source_status | Finalizada/Pendiente original |
| Horas_reales | actual_minutes | Decimal × 60; vacío → NULL, nunca 0 |
| Fecha_fin | end_date | DATE; vacío → NULL |
| Retraso | source_delay | Sí → true, No → false, vacío → NULL |

El cambio de diseño es deliberado: importar primero una tabla de hechos históricos, no crear 500 tarjetas operativas con asignaciones/horas artificiales. Si se desea demostrar el Kanban con tarjetas importadas, hacerlo como una transformación opcional a una organización demo separada, usando miembros ficticios de prueba y `import_rows.card_id` para trazabilidad. Las horas de fuente no se convierten en cronómetros ni aprobaciones inventadas. Los modelos conservan los nombres de entrada de sus CSV en `feature_schema` y `input_snapshot`; no reentrenar sin decisión explícita.

Proceso: upload privado → hash SHA-256 → parsing streaming UTF-8/BOM → mapeo → validación de tipos/nulos/dominios → preview → confirmación por permiso → inserción de import_batches, import_rows y facts en transacción → reporte de errores → métricas demo. Deduplicar por hash y código fuente; un archivo distinto con tareas repetidas exige política de sustitución de lote, no sumar ambas versiones. Si se revierte lote, conservar auditoría, evitar borrar datos posteriores y excluir lotes reverted de métricas. No mostrar nombres demo al público.

## 7. Integridad, índices y operación

### Transacciones críticas

**Mover tarjeta:** abrir transacción con actor → leer tarjeta y columna destino autorizadas → validar `expectedVersion`, dependencias y WIP → bloquear recurso de orden → actualizar posición y versión → insertar `card_events`, `audit_events` y outbox → commit. Si falla un paso, rollback completo. Ordenar por `(position,id)` y reequilibrar bajo lock cuando se agoten posiciones intermedias.

**Aprobar horas:** lock parte y aprobación → comprobar supervisor de cartera y no titular → verificar estado submitted y versión → aprobar, guardar decisión y versión de parte → emitir notificación. Para rectificar horas aprobadas usar flujo de anulación/rectificación revisado, nunca editar silenciosamente.

**Publicar documento:** validar versión aprobada, vigencia y ACL → marcar anterior superseded → activar nueva → insertar jobs upsert/remove → commit → worker indexa e informa estado. MIA no utiliza versión anterior si ya fue retirada, aunque el índice no termine de actualizarse. No marcar sincronización exitosa hasta confirmación del proveedor.

**Consumir jobs:** seleccionar disponibles con `FOR UPDATE SKIP LOCKED`, reservar lease y commit; ejecutar operación externa fuera de transacción larga, revalidar autorización y usar idempotencia; guardar resultado. Si worker falla, lease vence, retry con backoff y límite. Evitar reintento de acciones irreversibles sin clave del proveedor. Outbox entrega al menos una vez, consumidor deduplica.

### Índices y rendimiento

El DDL incluye índices de soporte a FK y consultas frecuentes, además de restricciones UNIQUE. Revisar redundancia y selectividad con datos reales; el plan no pretende indexar toda columna. Filtros de dashboard por organización/proyecto/fecha. Paginación por cursor `(created_at,id)` o `(position,id)`. No usar SELECT * para listados pesados; no incluir cuerpos de chat, JSON de documento ni respuestas de examen si no se necesitan. Índices parciales adicionales recomendados para jobs pendientes, notificaciones no leídas y tarjetas activas tras medir consultas. Considerar GIN solo para búsqueda textual aprobada; no introducir pgvector o Azure AI Search de pago por defecto.

```sql
-- Solo en entorno de prueba, con contexto y rol reales.
EXPLAIN (ANALYZE, BUFFERS)
SELECT id, title, due_date, priority
FROM nexus.cards
WHERE organization_id = '00000000-0000-0000-0000-000000000001'::uuid
  AND project_id = '00000000-0000-0000-0000-000000000002'::uuid
  AND archived_at IS NULL
ORDER BY due_date, id LIMIT 30;
```

`EXPLAIN ANALYZE` ejecuta la consulta; usar lectura controlada, nunca DML sobre producción para experimentar. No deshabilitar RLS para mejorar rendimiento. Medir p95, conexiones, locks, tamaños de tabla e índices, duración de exportación y fallos de jobs.

## 8. Backup, recuperación y retención

- Versionar migraciones y diccionario en Git, nunca dumps con datos reales ni claves. Para respaldo real usar dump autorizado y cifrado con almacenamiento controlado; Storage necesita su propio respaldo de objetos, no solo metadata de Postgres. Verificar consistencia de backup y restaurar en proyecto de prueba antes de confiar en él.
- Definir RPO/RTO con la empresa; no asumir backups o point-in-time recovery gratuitos. Documentar responsable, frecuencia, caducidad, restauración y pruebas. No hacer borrado masivo en producción sin backup y aprobación.
- Retención propuesta a validar: exportaciones temporales de vida corta; jobs y logs técnicos limitados por utilidad; chats según política y solicitudes de eliminación; evidencias de auditoría según obligaciones de la empresa. No fijar plazos legales inventados. Minimizar PII, seudonimizar al dar de baja perfiles según reglas de conservación. ON DELETE RESTRICT obliga a planificar limpieza referencial en lugar de borrar accidentalmente historial.
- Para Azure, mantener `MIA_ENABLED`, Speech y ML como flags, activar recursos solo después de estimar costo y validar saldo. `quota_limits` controla solicitudes internas, no garantiza gasto externo. Eliminar/desactivar endpoints o sesiones que generen cargos cuando terminen las pruebas. No contratar Azure AI Search, hosting pago o Redis sin aprobación.

## 9. Checklist de salida del MVP

- [ ] Migraciones aplicadas a Supabase local desde cero y a snapshot anterior.
- [ ] Diccionario, SQL y schema Drizzle coherentes.
- [ ] Rol API no propietario, NO BYPASSRLS, esquema no expuesto.
- [ ] Todas las políticas efectivas del módulo implementado y pruebas del documento 03 aprobadas.
- [ ] Bootstrap de identidad, rol por alcance y suspensión probados.
- [ ] CRUD de proyecto/tablero/tarjeta, concurrencia, checklists, comentarios y horas verificados.
- [ ] Exportaciones y métricas calculadas sobre filas autorizadas.
- [ ] Importación demo verificada (500 registros, sin datos operativos falsos).
- [ ] MIA no recupera documentos retirados o datos ajenos; chat privado.
- [ ] Seeds sin credenciales; variables sensibles fuera de Git.
- [ ] Backups y restauración de prueba; rollback/forward fix documentado.

## 10. Referencias

- [Supabase local development](https://supabase.com/docs/guides/local-development)
- [Supabase database migrations](https://supabase.com/docs/guides/local-development/database-migrations)
- [Supabase deployment migrations](https://supabase.com/docs/guides/deployment/database-migrations)
- [Supabase Storage security](https://supabase.com/docs/guides/storage/security/access-control)
- [Drizzle ORM](https://orm.drizzle.team/docs/overview)
- [PostgreSQL constraints](https://www.postgresql.org/docs/current/ddl-constraints.html)

**Estado de verificación:** diseño estructural y referencias cruzadas revisadas; no se ejecutó PostgreSQL/Supabase ni se probaron políticas con usuarios reales en esta entrega. La plantilla SQL no incluye las políticas permisivas completas, bootstrap de roles, seeds, ni triggers de invariantes intertabla; estos son siguientes pasos de implementación controlada.
