<div align="center">

# MTA NEXUS | Seguridad, RBAC y RLS

**Políticas por recurso, rol y operación**

![MTA: NEXUS](https://img.shields.io/static/v1?label=MTA&message=NEXUS&color=0A1A3A&style=for-the-badge) ![Documento: v1.0](https://img.shields.io/static/v1?label=Documento&message=v1.0&color=0066FF&style=for-the-badge) ![Seguridad: Deny by default](https://img.shields.io/static/v1?label=Seguridad&message=Deny%20by%20default&color=991B1B&style=for-the-badge) ![RLS: FORCE](https://img.shields.io/static/v1?label=RLS&message=FORCE&color=166534&style=for-the-badge) ![RBAC: Scoped](https://img.shields.io/static/v1?label=RBAC&message=Scoped&color=0066FF&style=for-the-badge)

</div>

> Estado: propuesta técnica para implementación. No representa una base de datos desplegada ni una auditoría de seguridad completada.

---

## 1. Modelo de amenazas y decisión de acceso

RLS (Row Level Security) limita las filas accesibles dentro de PostgreSQL. RBAC controla capacidades por rol. El alcance de recurso determina sobre qué proyecto, persona o documento se permite actuar. Las tres comprobaciones son necesarias. Tener permiso `card.move` no implica poder mover cualquier tarjeta. RLS tampoco limita por sí sola las columnas modificables ni valida transiciones complejas.

**Regla definitiva:** sesión verificada + perfil activo + organización activa + membresía activa + permiso vigente + relación con el recurso + validación de operación. Denegar por defecto si falta cualquiera de las condiciones aplicables. Las rutas públicas usan un servicio separado que devuelve únicamente proyecciones publicadas.

### Separación de roles PostgreSQL y roles empresariales

| Rol técnico propuesto | Privilegios | Límites |
|---|---|---|
| `nexus_migrator` / owner de migración | DDL y bootstrap controlado | Nunca usado por requests web |
| `nexus_api` | Solo grants y RLS requeridos para API | NO SUPERUSER, NO BYPASSRLS, no owner, sin CREATE/TRUNCATE ni gestión de roles |
| `nexus_worker` | Operaciones de job tipado por organización | No lectura general de chats, perfiles o documentos |
| `nexus_policy_reader` | NOLOGIN; lectura auxiliar únicamente de identidad y ACL | Sin membresía heredada o SET ROLE desde API; funciones SECURITY DEFINER limitadas |
| `anon`, `authenticated` | Auth/Storage según configuración oficial | Sin grants al esquema privado nexus |
| `service_role` | Administración Supabase restringida al adaptador de servidor | No usar en consultas de negocio ni exponer al frontend; sus credenciales privilegiadas requieren custodia |

Los nombres son propuestos; verificar capacidad de crear roles/owners en el entorno Supabase antes de migrar. Si no es viable, conservar el esquema privado y diseñar una alternativa revisada con JWT y roles de DB sin bypass. La aplicación no debe confiar en un parámetro de frontend para cambiar el contexto SQL. No existe un superadmin empresarial con BYPASSRLS.

## 2. Matriz empresarial

| Capacidad | Practicante | Líder | Supervisor | Admin funcional | Superadmin técnico |
|---|---|---|---|---|---|
| Proyecto / board.read | Asignado | Asignado | Cartera asignada | Delegado | No |
| card.create / assign | No por defecto | Su proyecto | Su cartera | Delegado | No |
| card.edit / move | Tarjeta propia y campos permitidos | Su proyecto | Su cartera | Delegado | No |
| time.write | Propias | Propias | Propias | Si delegado | No por defecto |
| time.approve | No | Revisión, no aprobación por defecto | Ajeno en cartera | Delegado | No |
| knowledge.edit | Proponer | Proponer | Según delegación | Editor delegado | No |
| knowledge.publish | No | No por defecto | Revisor delegado | Revisor delegado | No |
| academy.learn | Sí | Sí | Sí | Si autorizado | Si autorizado |
| academy.grade / publish | No | Mentor delegado | Revisor delegado | Editor delegado | No |
| mia.chat | Sí, fuentes autorizadas | Sí | Sí | Sí | Diagnóstico técnico, no chats ajenos |
| analytics.read / export | Propio / proyecto permitido | Equipo | Cartera | Delegado | Agregados técnicos |
| commercial.edit / publish | No | No | Lectura delegada | Comercial delegado | No |
| access.manage | No | Solicitar | Delegar limitado | Según delegación | Seguridad técnica según asignación |
| integration.manage | No | No | No | Delegado | Sí, sin contenido privado |
| audit.read | Propia actividad | Proyecto limitado | Cartera | Auditor delegado | Eventos técnicos autorizados |

`lider` es rol de proyecto; `supervisor` recibe alcance de proyecto por defecto. `admin` funcional no es universal. La organización puede crear roles de comercial, editor, mentor y auditor con capacidades explícitas; las concesiones no heredan más de lo autorizado.

### Catálogo inicial de permisos (seed propuesto)

| Dominio | Códigos estables |
|---|---|
| Identidad | `profile.read.self`, `profile.edit.self`, `team.read`, `team.manage`, `membership.invite`, `membership.suspend`, `role.read`, `role.delegate`, `organization.configure` |
| Proyectos | `project.read`, `project.create`, `project.edit`, `project.members.manage`, `board.manage`, `card.read`, `card.create`, `card.edit.own`, `card.edit`, `card.move.own`, `card.move`, `card.assign`, `card.archive`, `card.review`, `label.manage`, `comment.create`, `comment.moderate`, `attachment.upload` |
| Horas y agenda | `time.read.own`, `time.read.project`, `time.write.own`, `time.approve`, `calendar.manage`, `support.create`, `support.resolve`, `automation.manage` |
| Conocimiento | `knowledge.read`, `knowledge.propose`, `knowledge.edit`, `knowledge.review`, `knowledge.publish`, `knowledge.acl.manage`, `knowledge.index` |
| Academy | `academy.learn`, `academy.edit`, `academy.review`, `academy.publish`, `academy.grade`, `academy.mentor`, `academy.moderate`, `academy.achievements.manage` |
| IA | `mia.chat`, `mia.actions.confirm`, `speech.use`, `analytics.read`, `analytics.demo`, `predictions.run`, `reports.export` |
| Comercial | `commercial.read`, `commercial.edit`, `commercial.publish`, `commercial.quote`, `commercial.leads.read` |
| Operación | `import.run`, `audit.read`, `integration.manage`, `quota.manage`, `health.read`, `security.manage` |

No basta sembrar códigos: crear `role_permissions` revisadas, `role_grants` y membresías reales; aplicar restricciones a los roles de proyecto y prohibir escalamiento propio. Nunca sembrar un usuario real con contraseña conocida. Los permisos técnicos de workers no se conceden a usuarios finales.

## 3. Contexto SQL de una petición NestJS

La identidad confiable se deriva de un JWT verificado; no de `userId` en el body. `app.user_id` representa **auth.users.id** (no el id de membership). `app.organization_id` representa la organización seleccionada y validada. Los dos se establecen con parámetros en una única transacción. Los GUC son confiables únicamente porque el acceso SQL está restringido a código servidor sin consultas arbitrarias; un cliente con SQL directo podría alterarlos.

```ts
import { sql } from 'drizzle-orm';

// Actor obtenido por el guard de Nest y validado contra Supabase Auth.
// db corresponde al pool del rol nexus_api, no al propietario.
return db.transaction(async (tx) => {
  await tx.execute(sql`select set_config('app.user_id', ${actor.authUserId}, true)`);
  await tx.execute(sql`select set_config('app.organization_id', ${actor.organizationId}, true)`);
  // Resolver membresía activa con una función estrecha de identidad.
  // Si no existe, abortar antes de ejecutar la operación.
  return useCase.execute(tx, actor, dto);
});
```

Nunca combinar transacción con consultas de otro pool. El flag `true` vuelve los valores locales a la transacción. El pooler debe preservar la misma transacción; probar conexiones reutilizadas, rollback y cambio de usuario. Para jobs, usar identidad técnica y alcance de job validado, no simular una membresía arbitraria. Las funciones de contexto deben devolver NULL si no se configuró el actor; el código valida UUID y maneja contexto inválido sin permitir acceso.

## 4. Ejemplo SQL de RLS (patrón de lectura de proyectos)

Este ejemplo es **de referencia**, no una migración para producción ni una política completa para las 97 tablas. Requiere provisionar y revisar roles técnicos. El DDL adicional del paquete deja todas las tablas cerradas hasta crear los grants y políticas definitivos. No ejecutar este fragmento en una base real sin adaptar roles y validar permisos heredados. Usar un esquema auxiliar privado `nexus_security`, nunca expuesto por PostgREST.

```sql
-- Provisionar con el migrador autorizado, en entorno local de prueba.
CREATE ROLE nexus_api NOLOGIN NOSUPERUSER NOBYPASSRLS;
CREATE ROLE nexus_policy_reader NOLOGIN NOSUPERUSER NOBYPASSRLS;
CREATE SCHEMA nexus_security;
REVOKE ALL ON SCHEMA nexus_security FROM PUBLIC;
GRANT USAGE ON SCHEMA nexus, nexus_security TO nexus_policy_reader;
GRANT USAGE ON SCHEMA nexus, nexus_security TO nexus_api;

-- Las funciones auxiliares necesitan leer exclusivamente estas tablas.
GRANT SELECT ON nexus.profiles, nexus.organizations, nexus.memberships,
  nexus.project_members, nexus.role_grants, nexus.roles,
  nexus.role_permissions, nexus.permissions TO nexus_policy_reader;
-- Crear una política de lectura técnica por cada tabla anterior,
-- solo TO nexus_policy_reader; aquí se muestra el patrón para profiles.
CREATE POLICY profiles_internal_lookup ON nexus.profiles
  FOR SELECT TO nexus_policy_reader USING (true);
-- Repetir para organizations, memberships, project_members,
-- role_grants, roles, role_permissions y permissions antes de probar la función.
-- Este rol no tiene LOGIN ni se concede al rol de la API.

CREATE FUNCTION nexus_security.actor_org() RETURNS uuid
LANGUAGE sql STABLE SET search_path = pg_catalog AS $$
  SELECT nullif(current_setting('app.organization_id', true), '')::uuid
$$;
CREATE FUNCTION nexus_security.actor_auth_id() RETURNS uuid
LANGUAGE sql STABLE SET search_path = pg_catalog AS $$
  SELECT nullif(current_setting('app.user_id', true), '')::uuid
$$;
REVOKE ALL ON FUNCTION nexus_security.actor_org() FROM PUBLIC;
REVOKE ALL ON FUNCTION nexus_security.actor_auth_id() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION nexus_security.actor_org(), nexus_security.actor_auth_id()
  TO nexus_policy_reader, nexus_api;

-- Función estrecha: devuelve boolean, nunca filas de identidad.
CREATE FUNCTION nexus_security.can_read_project(p_org uuid, p_project uuid)
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = pg_catalog AS $$
  SELECT p_org = nexus_security.actor_org() AND EXISTS (
    SELECT 1 FROM nexus.memberships m
    JOIN nexus.profiles p ON p.id = m.profile_id
    JOIN nexus.organizations o ON o.id = m.organization_id
    JOIN nexus.project_members pm ON pm.organization_id = m.organization_id
      AND pm.membership_id = m.id AND pm.project_id = p_project
    JOIN nexus.role_grants rg ON rg.organization_id = m.organization_id
      AND rg.membership_id = m.id
    JOIN nexus.roles r ON r.organization_id = rg.organization_id AND r.id = rg.role_id
    JOIN nexus.role_permissions rp ON rp.organization_id = r.organization_id AND rp.role_id = r.id
    JOIN nexus.permissions perm ON perm.id = rp.permission_id
    WHERE m.organization_id = p_org
      AND p.auth_user_id = nexus_security.actor_auth_id()
      AND p.status = 'active' AND o.status = 'active' AND m.status = 'active'
      AND pm.removed_at IS NULL AND rg.revoked_at IS NULL
      AND (rg.expires_at IS NULL OR rg.expires_at > now())
      AND ((r.scope = 'organization' AND rg.project_id IS NULL)
        OR (r.scope = 'project' AND rg.project_id = p_project))
      AND perm.code = 'project.read'
  )
$$;
-- El migrador debe poder transferir la función; conceder CREATE temporalmente
-- al nuevo owner solo durante la provisión si se requiere y revocarlo después.
ALTER FUNCTION nexus_security.can_read_project(uuid, uuid) OWNER TO nexus_policy_reader;
REVOKE ALL ON FUNCTION nexus_security.can_read_project(uuid, uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION nexus_security.can_read_project(uuid, uuid) TO nexus_api;

GRANT SELECT ON nexus.projects TO nexus_api;
CREATE POLICY projects_select ON nexus.projects FOR SELECT TO nexus_api
  USING (nexus_security.can_read_project(organization_id, id));

-- Ejemplo: lectura de tarjetas solo si se implementa también card.read.
-- No habilitar antes de crear y probar el helper específico de tarjeta.
-- CREATE POLICY cards_select ON nexus.cards FOR SELECT TO nexus_api
--   USING (nexus_security.can_read_card(organization_id, project_id, id));
```

Se requieren funciones equivalentes y revisadas para `current_membership_id()`, `has_permission(code, org, project)`, `can_read_card`, `can_edit_card`, `can_read_document_version`, `can_read_conversation`, `can_read_enrollment`, `can_read_ticket`, `can_read_file`. Evitar recursión RLS a través de joins de seguridad: la función de lookup se ejecuta con rol restringido de lectura, no con el owner general ni con BYPASSRLS. Cada función fija `search_path`, califica nombres y revoca EXECUTE de PUBLIC. No usar dynamic SQL ni devolver IDs/filas ajenas.

### Cómo escribir políticas de actualización

- `SELECT`: USING verifica fila visible, scope y pertenencia.
- `INSERT`: WITH CHECK verifica fila nueva, autor igual a actor cuando corresponde, permisos y pertenencia de FK.
- `UPDATE`: USING autoriza fila anterior; WITH CHECK autoriza fila resultante. Impedir modificación de `organization_id`, `project_id`, `created_by`, propiedad o estados mediante grants de columna o función de caso de uso estrecha. Usar UPDATE condicional por `version` y validación de estado.
- `DELETE`: denegado salvo relación temporal explícita y política dedicada. Archivar recursos de negocio. Eventos append-only no tienen UPDATE/DELETE/TRUNCATE para roles runtime.
- Las políticas permisivas se combinan con OR: añadir una demasiado amplia puede anular la protección esperada. Usar condiciones completas o una política restrictiva adicional correctamente combinada con una permisiva.
- `USING`/`WITH CHECK` no comparan OLD vs NEW directamente. Inmutabilidad y transiciones requieren grants por columna, trigger probado o servicio transaccional. Nunca aceptar `organizationId`, `status`, `score` o `approvedBy` desde un PATCH genérico.

## 5. Contrato de RLS por tabla (cobertura de diseño)

Cada fila del inventario describe el acceso previsto. Debe transformarse en políticas SQL y grants mínimos antes de habilitar el módulo. Todas las políticas incluyen contexto activo, organización y permiso salvo excepción pública explícita. Las operaciones no enumeradas se deniegan. RLS no equivale a autorización de columnas; devolver DTO específicos. Las tablas de scope `project` exigen membresía y permiso sobre el proyecto, no solo coincidencia de organización.

### 01. Identidad, organización y permisos

| Tabla | Scope | Lectura / escritura y restricciones |
|---|---|---|
| `organizations` | global | Leer por membresía activa; configurar solo admin delegado; crear organización mediante bootstrap privilegiado. |
| `profiles` | global | Propietario lee y edita nombre/bio/avatar; directorio entrega proyección limitada de compañeros; suspensión por admin autorizado, no por propietario. |
| `memberships` | org | Leer propia o directorio autorizado; modificar estado por administrador delegado sin autoescalamiento. |
| `roles` | org | Leer roles aplicables; administrar roles delegados sin ampliar permisos propios. |
| `permissions` | global | Solo lectura por backend autenticado; cambios mediante migración revisada. |
| `role_permissions` | org | Leer según administración; escritura solo por flujo de delegación y auditoría. |
| `role_grants` | org | Propio o administrador autorizado; otorgar/revocar sin autoasignación, con alcance y expiración verificados. |
| `invitations` | org | Administrador delegado; aceptación mediante endpoint seguro; nunca exponer token_hash al cliente. |
| `user_preferences` | org | Solo titular; validar claves de JSON y no almacenar permisos ni secretos. |
| `organization_settings` | org | Leer solo claves permitidas; admin delegado cambia configuración funcional, nunca secretos. |
| `teams` | org | Miembros del equipo o supervisor asignado; administrar con permiso team.manage. |
| `team_members` | org | Leer equipo autorizado; gestionar supervisor o delegado; no concede privilegios automáticamente. |
| `availability` | org | Titular y supervisor de su equipo; no exponer motivos privados en informes. |

### 02. Proyectos, tableros y tarjetas

| Tabla | Scope | Lectura / escritura y restricciones |
|---|---|---|
| `projects` | org | Leer proyecto asignado; crear con project.create y asignar supervisor en misma transacción; editar por líder/supervisor delegado. |
| `project_members` | project | Leer miembros de proyecto visible; alta/baja solo supervisor o delegado; rol de líder se concede en role_grants. |
| `milestones` | project | Leer proyecto; escritura por coordinador autorizado. |
| `boards` | project | Leer proyecto; configurar por board.manage. |
| `board_columns` | project | Leer proyecto; modificar por board.manage; archivar solo con migración segura de tarjetas. |
| `cards` | project | Leer proyecto; editar asignadas propias o coordinador con permiso; mover validando columna/versión/cierre; nunca cambiar scope directamente. |
| `card_assignees` | project | Leer tarjeta; asignar/desasignar por card.assign y pertenencia vigente al proyecto. |
| `labels` | org | Leer etiquetas globales o del proyecto visible; editar catálogo por permiso específico; mantener relaciones históricas. |
| `card_labels` | project | Leer tarjeta; adjuntar/desvincular por card.edit; rechazar etiqueta archivada o de otro proyecto. |
| `field_definitions` | project | Leer proyecto; gestionar por board.manage. |
| `field_values` | project | Leer tarjeta; modificar con card.edit y validar definición del mismo tablero. |
| `checklists` | project | Leer tarjeta; editar por card.edit. |
| `checklist_items` | project | Leer tarjeta; marcar por asignado o editor autorizado; asignar solo a miembro del proyecto. |
| `card_dependencies` | project | Leer proyecto; editar por card.edit; detectar ciclos con bloqueo transaccional. |
| `comments` | project | Leer tarjeta; comentar por miembro autorizado; editar propio, moderación separada. |
| `comment_mentions` | project | Leer comentario; crear solo mediante servicio de comentarios; destinatario con acceso. |
| `comment_reactions` | project | Leer comentario; añadir/quitar propia reacción. |
| `files` | org | No listado global: leer por recurso padre autorizado; crear por carga autorizada; objetos privados. |
| `attachments` | project | Leer tarjeta; adjuntar con card.edit y archivo ready del mismo alcance. |
| `card_watchers` | project | Leer propios seguimientos; seguir/dejar de seguir tarjeta visible. |
| `card_events` | project | Leer tarjeta; append-only por servicio transaccional; sin edición o borrado desde UI. |

### 03. Tiempo, agenda, soporte y colaboración

| Tabla | Scope | Lectura / escritura y restricciones |
|---|---|---|
| `timers` | project | Titular opera su cronómetro en tarjeta autorizada; supervisor solo lectura delegada. |
| `time_entries` | project | Titular crea/edita borrador propio; supervisor de proyecto lee y aprueba sin autoaprobación; inmutable tras aprobación. |
| `time_entry_versions` | project | Leer si puede leer registro; solo append por servicio. |
| `approvals` | project | Solicitante y revisor autorizado; decisión por supervisor sin autoaprobación, validar estado y versión. |
| `calendar_events` | org | Titular/invitado o audiencia autorizada; editar organizador o gestor delegado. |
| `calendar_attendees` | org | Leer evento autorizado; responder invitación propia; gestionar por organizador. |
| `tickets` | org | Solicitante, soporte asignado o supervisor autorizado; resolver por permiso support.resolve. |
| `ticket_comments` | org | Leer ticket; escribir como participante autorizado. |
| `ticket_links` | project | Requiere acceso a ambos recursos; verificar proyecto coherente. |
| `card_templates` | project | Leer proyecto; gestionar por board.manage; no copiar asignados/archivos sin revalidar. |
| `automation_rules` | project | Leer coordinador; crear/activar por automation.manage; worker revalida alcance y evita ciclos. |
| `automation_runs` | project | Leer gestor del proyecto; escritura worker limitado. |

### 04. Knowledge Center y RAG

| Tabla | Scope | Lectura / escritura y restricciones |
|---|---|---|
| `documents` | org | Publicado y audiencia válida, ACL explícita o editor/revisor delegado; no acceso automático por admin. |
| `document_versions` | org | Lectores solo versión publicada vigente; borrador por editor/revisor; publicar con aprobación y transacción. |
| `document_acl` | org | Titular de permiso o gestor documental autorizado; administrar ACL con auditoría. |
| `index_jobs` | org | Leer estado por editor autorizado; worker indexador específico escribe. |
| `source_refs` | org | Leer solo fuente autorizada y vigente; indexador crea/revoca; revalidar antes de enviar a IA. |

### 05. MIA Academy

| Tabla | Scope | Lectura / escritura y restricciones |
|---|---|---|
| `learning_paths` | org | Leer publicados por miembros habilitados; editar/publicar por permiso Academy. |
| `courses` | org | Leer catálogo publicado; gestionar por academy.edit/publish separados. |
| `course_versions` | org | Leer versión publicada o matrícula válida; editor/revisor lee borrador; publicación separada. |
| `path_courses` | org | Leer ruta autorizada; modificar por editor de ruta. |
| `course_modules` | org | Hereda acceso a versión del curso; edición solo borrador. |
| `lessons` | org | Leer versión autorizada; editar solo borrador. |
| `lesson_resources` | org | Hereda acceso a lección y además a documento si aplica; editor en borrador. |
| `enrollments` | org | Alumno propio; mentor/supervisor con cartera; alta por matrícula autorizada. |
| `lesson_progress` | org | Alumno y mentor autorizado; servidor verifica lección pertenece a versión y requisitos. |
| `assessments` | org | Leer evaluación de curso autorizado; edición solo borrador. |
| `assessment_questions` | org | Alumno en intento autorizado; editor de borrador; no incluye respuesta correcta. |
| `assessment_answer_keys` | org | Solo evaluador/servicio de corrección con permiso; jamás alumno ni MIA general. |
| `attempts` | org | Alumno ve propio; evaluador asignado; score solo calculado por servidor. |
| `attempt_answers` | org | Alumno edita antes de enviar; evaluador corrige; validar pregunta y puntos. |
| `mentoring_sessions` | org | Participantes y coordinador autorizado; notas privadas excluidas del resumen. |
| `forum_posts` | org | Participante del curso; editar propio, moderador oculta; no indexar sin aprobación. |
| `achievements` | org | Leer catálogo; administrar por Academy; reglas no ejecutan código arbitrario. |
| `member_achievements` | org | Titular y audiencia autorizada; otorgar solo servicio de logros, no autoasignación. |
| `certificates` | org | Titular y autoridad formativa; verificación pública opcional mínima; emisión solo servidor. |

### 06. MIA, voz, analítica y Machine Learning

| Tabla | Scope | Lectura / escritura y restricciones |
|---|---|---|
| `conversations` | org | Solo titular activo con acceso al contexto; superadmin no lee conversaciones por defecto. |
| `messages` | org | Solo titular y servicio MIA; cliente no puede insertar rol assistant/tool ni modificar respuestas. |
| `citations` | org | Titular del mensaje y fuente todavía autorizada; ocultar detalle si revocada; servicio registra fuente real. |
| `tool_runs` | org | Titular ve resumen autorizado; diagnóstico agregado; argumentos sensibles no se guardan. |
| `action_previews` | org | Titular; confirmar explícitamente y revalidar permisos/versión; ejecutar una vez. |
| `speech_sessions` | org | Titular y servicio Speech; administración solo métricas agregadas. |
| `model_versions` | org | Leer usuarios con analytics/predict; editar integrador autorizado, métricas reales solamente. |
| `predictions` | org | Solicitante y supervisor con permiso sobre escenario; resultados solo adaptador ML; no inventar predicciones. |
| `usage_records` | org | Titular ve consumo propio; integrador ve agregados; servicio registra medición; nunca contenido de chats. |

### 07. Servicios, planes y cotizaciones

| Tabla | Scope | Lectura / escritura y restricciones |
|---|---|---|
| `services` | org | Leer publicado; comercial autorizado gestiona borradores y publicación separada. |
| `plans` | org | Leer plan publicado; editor comercial administra. |
| `plan_versions` | org | Leer versión publicada vigente; editor y aprobador distintos; evitar solapamiento de vigencias. |
| `leads` | org | Solo comercial autorizado; formulario público por endpoint limitado, sin listado anónimo. |
| `quotes` | org | Comercial delegado; no publicar al público ni enviar por MIA sin permiso/confirmación. |
| `quote_items` | org | Hereda cotización; cambios solo borrador y recalcular totales en transacción. |

### 08. Operación, notificaciones y auditoría

| Tabla | Scope | Lectura / escritura y restricciones |
|---|---|---|
| `notifications` | org | Solo destinatario lee y marca/archiva; creación por servicio de notificaciones. |
| `notification_preferences` | org | Solo titular; alertas críticas de seguridad siguen política independiente. |
| `audit_events` | org | Auditor delegado según alcance; superadmin solo eventos técnicos autorizados; append por servicio; sin UPDATE/DELETE. |
| `outbox` | org | No acceso usuario; API inserta vía caso de uso; worker consume por permiso técnico acotado. |
| `jobs` | org | No acceso general; worker restringido por tipo y organización; UI ve estado a través de recurso dueño. |
| `import_batches` | org | Importador delegado; CSV histórico exclusivamente en organización demo; validar antes de confirmar. |
| `import_rows` | org | Importador del lote; filas no se exponen a MIA operativa; preservar fuente y nulos. |
| `historical_task_facts` | org | Solo organización demo y permiso analytics.demo; datos históricos separados de tablero operativo. |
| `export_jobs` | org | Solicitante lee; worker revalida permisos antes de generar y descarga; sin exportación global implícita. |
| `integration_settings` | org | Solo integrador/superadmin delegado; no expone credenciales ni contenido privado. |
| `quota_limits` | org | Integrador configura; servicio de cuotas reserva y liquida consumo; no garantiza tope de factura externa. |
| `idempotency_keys` | org | Solo servicio de operación; comparar hash y no devolver respuestas de otro actor. |

## 6. Storage: políticas independientes

Los buckets `attachments`, `knowledge`, `avatars`, `academy`, `exports`, `imports` son privados. `nexus.files` solo almacena metadata; la carga se hace mediante API Storage, nunca `INSERT` en `storage.objects`. El contexto GUC de la conexión Nest no se transfiere automáticamente a Storage API. Por tanto, el diseño inicial no concede listado/lectura arbitraria a `authenticated` ni `anon` en estos buckets. El backend verifica fila padre y archivo antes de firmar una URL específica con expiración corta. El adaptador privilegiado de Storage permanece aislado y no permite rutas/buckets arbitrarios. Eliminar cualquier política amplia previa tras evaluar dependencias.

Ruta de objeto propuesta: `organization_uuid/resource_uuid/random_uuid.ext`. Validar tamaño máximo, tipo real, nombre, hash, cuarentena y malware según capacidad; limitar archivos ejecutables y SVG/HTML activos. Confirmar carga con metadata real, marcar `ready`, luego vincular en transacción. Eliminar huérfanos por job de mantenimiento. Revocar nuevos enlaces al retirar acceso; una URL firmada ya emitida puede seguir válida hasta expirar. No almacenar URL permanente en BD ni exponer clave secreta. Para datos especialmente sensibles, proxy autenticado en lugar de URL de vida larga.

## 7. MIA, documentos y privacidad

- Prohibido conectar el modelo a SQL libre o permitir que genere WHERE sin control. Tools tipadas llaman servicios autorizados; verifican scope en cada llamada, no solo al iniciar chat.
- RAG devuelve fragmentos indexados por organización, versión y ACL. Revalidar permisos y vigencia en PostgreSQL **antes** de enviar fragmentos a Foundry. Si la herramienta File Search del agente no puede restringir cada recuperación por usuario, no asociar documentos privados a un almacén global accesible por todos. Usar índices separados o retrieval backend controlado. El agente inicial con PDF de demo se mantiene separado de información operativa.
- Historial, archivos, reportes y exportaciones heredan permisos del recurso, no del propietario técnico. Si un mensaje histórico contiene un extracto de una fuente revocada, ocultar/redactar ese mensaje o bloquear la conversación afectada hasta sanearla; no basta esconder la cita. Evitar reenviar contexto revocado a Foundry.
- URLs de fuentes y descargas se resuelven en Nest con autorización nueva. Ningún resultado de predicción inventado. Sin evidencia suficiente, respuesta de insuficiencia; fuera de dominio, rechazo.
- Superadmin puede administrar cuotas y salud sin leer chats privados. Acceso excepcional a contenido requiere flujo separado aprobado, con vigencia, motivo y auditoría; no está habilitado en el DDL inicial.
- Nunca guardar claves Azure, tokens Auth, credenciales DB o respuestas de evaluación en logs. Audio no persistente por defecto. Definir política de eliminación/retención de chats, exportaciones y logs con MTA antes de producción.

## 8. Pruebas de seguridad obligatorias

Usar PostgreSQL/Supabase local con un rol runtime real sin BYPASSRLS. Fixtures: organización A operativa ficticia, B operativa ficticia y D demo; dos proyectos A1/A2; practicante propio y ajeno, líder A1, supervisor A2, admin funcional y superadmin; perfiles suspendidos y roles expirados. Crear fixtures mediante bootstrap de prueba separado.

| ID | Escenario | Esperado |
|---|---|---|
| RLS-01 | Sin contexto o actor desconocido | 0 filas / escritura rechazada |
| RLS-02 | Miembro A consulta por UUID de B | Sin datos, sin filtración en conteos |
| RLS-03 | Líder A1 intenta editar A2 | Denegado |
| RLS-04 | Practicante edita tarjeta ajena | Denegado; propia solo campos permitidos |
| RLS-05 | PATCH con org/autor/score privilegiado | Rechazo y sin cambio parcial |
| RLS-06 | Rol expirado o membresía suspendida | Revocación efectiva incluso con JWT aún vigente |
| RLS-07 | Columna de otro tablero/proyecto | FK rechaza; caso de uso devuelve error controlado |
| RLS-08 | Asignado retirado del proyecto | Rechazo aunque FK histórica exista |
| RLS-09 | Aprobar parte propio o reaprobar | Rechazo, registro de decisión intacto |
| RLS-10 | Usuario cambia score o lee answer keys | Rechazo |
| RLS-11 | Superadmin lista chats o leads | Rechazo por defecto |
| RLS-12 | Archivo ajeno por path/UUID | Sin firma, listado ni descarga |
| RLS-13 | Documento retirado, ACL revocada o índice atrasado | Ningún fragmento enviado al agente |
| RLS-14 | Prompt injection solicita datos de otra org | Tool denegada sin fuga |
| RLS-15 | Exportación solicitada antes de revocar membresía | Worker no genera o descarga rechazada |
| RLS-16 | Dos usuarios consecutivos en misma conexión pool | Sin arrastre de GUC entre transacciones |
| RLS-17 | Inserción directa de datos históricos en operativo | Rechazo por guard y trigger a implementar |
| RLS-18 | Escritura o borrado de audit_events por usuario | Denegado |
| RLS-19 | Repetición de acción MIA confirmada | Una sola modificación |
| RLS-20 | Anon consulta Data API o Storage privado | Sin acceso |
| RLS-21 | Worker recibe job con organización modificada | Rechazo y auditoría técnica |
| RLS-22 | Vista de dashboard agrupa proyecto ajeno | No aparecen conteos ajenos |
| RLS-23 | Cotización/borrador de precios en portal público | Solo catálogo publicado vigente |
| RLS-24 | Nueva concesión propia de superadmin | Rechazo |

Prueba de integridad adicional: verificar que todas las tablas de nexus tienen `relrowsecurity` y `relforcerowsecurity`, que los roles runtime no son dueños ni tienen bypass, y que no existan políticas amplias heredadas. Probar acciones con API real y errores de FK normalizados, porque FK/UNIQUE pueden revelar existencia indirecta y no se limitan por RLS.

```sql
SELECT n.nspname, c.relname, c.relrowsecurity, c.relforcerowsecurity
FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname = 'nexus' AND c.relkind = 'r'
  AND (NOT c.relrowsecurity OR NOT c.relforcerowsecurity);
-- Resultado esperado: cero filas.
SELECT schemaname, tablename, policyname, roles, cmd, qual, with_check
FROM pg_policies WHERE schemaname = 'nexus' ORDER BY tablename, policyname;
```

## 9. Referencias oficiales

- [PostgreSQL: Row Security Policies](https://www.postgresql.org/docs/current/ddl-rowsecurity.html)
- [Supabase: Row Level Security](https://supabase.com/docs/guides/database/postgres/row-level-security)
- [Supabase: Securing your API](https://supabase.com/docs/guides/api/securing-your-api)
- [Supabase: Storage Access Control](https://supabase.com/docs/guides/storage/security/access-control)
- [Supabase: Column Level Security](https://supabase.com/docs/guides/database/postgres/column-level-security)
