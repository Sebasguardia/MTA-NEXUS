-- MTA NEXUS | DDL DE REFERENCIA, NO DEPLOY DIRECTO
-- Ejecutar solo en entorno de prueba Supabase vacío tras revisión.
-- Sin grants a runtime ni políticas permisivas. Toda tabla queda cerrada.
-- Supone auth.users existente; no modifica auth ni storage.
BEGIN;
CREATE SCHEMA IF NOT EXISTS nexus;
REVOKE ALL ON SCHEMA nexus FROM PUBLIC, anon, authenticated, service_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA nexus REVOKE ALL ON TABLES FROM PUBLIC, anon, authenticated, service_role;

-- Espacio de trabajo y frontera de aislamiento.
CREATE TABLE nexus."organizations" (
  "id" uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  "created_at" timestamptz NOT NULL DEFAULT now(),
  "updated_at" timestamptz NOT NULL DEFAULT now(),
  "slug" text NOT NULL,
  "name" text NOT NULL,
  "kind" text NOT NULL DEFAULT 'operational',
  "status" text NOT NULL DEFAULT 'active',
  "timezone" text NOT NULL DEFAULT 'America/Lima',
  "currency" char(3) NOT NULL DEFAULT 'PEN',
  UNIQUE ("slug"),
  CHECK (kind IN ('operational','demo')),
  CHECK (status IN ('active','suspended'))
);

-- Perfil humano vinculado a Supabase Auth; nunca guarda contraseñas.
CREATE TABLE nexus."profiles" (
  "id" uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  "created_at" timestamptz NOT NULL DEFAULT now(),
  "updated_at" timestamptz NOT NULL DEFAULT now(),
  "auth_user_id" uuid NOT NULL,
  "full_name" text NOT NULL,
  "avatar_path" text,
  "bio" text,
  "status" text NOT NULL DEFAULT 'active',
  UNIQUE ("auth_user_id"),
  CHECK (status IN ('active','suspended','deactivated'))
);

-- Participación vigente de un perfil en una organización.
CREATE TABLE nexus."memberships" (
  "id" uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  "organization_id" uuid NOT NULL,
  "created_at" timestamptz NOT NULL DEFAULT now(),
  "updated_at" timestamptz NOT NULL DEFAULT now(),
  "profile_id" uuid NOT NULL,
  "status" text NOT NULL DEFAULT 'invited',
  "joined_at" timestamptz,
  "left_at" timestamptz,
  "specialty" text,
  UNIQUE (organization_id, id),
  UNIQUE ("organization_id", "profile_id"),
  CHECK (status IN ('invited','active','suspended','left'))
);

-- Catálogo de roles de organización y proyecto.
CREATE TABLE nexus."roles" (
  "id" uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  "organization_id" uuid NOT NULL,
  "created_at" timestamptz NOT NULL DEFAULT now(),
  "updated_at" timestamptz NOT NULL DEFAULT now(),
  "code" text NOT NULL,
  "name" text NOT NULL,
  "scope" text NOT NULL,
  "is_system" boolean NOT NULL DEFAULT false,
  UNIQUE (organization_id, id),
  UNIQUE ("organization_id", "code"),
  CHECK (scope IN ('organization','project'))
);

-- Catálogo global de capacidades explícitas.
CREATE TABLE nexus."permissions" (
  "id" uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  "created_at" timestamptz NOT NULL DEFAULT now(),
  "updated_at" timestamptz NOT NULL DEFAULT now(),
  "code" text NOT NULL,
  "description" text NOT NULL,
  UNIQUE ("code")
);

-- Relación N:M de roles y capacidades.
CREATE TABLE nexus."role_permissions" (
  "id" uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  "organization_id" uuid NOT NULL,
  "created_at" timestamptz NOT NULL DEFAULT now(),
  "updated_at" timestamptz NOT NULL DEFAULT now(),
  "role_id" uuid NOT NULL,
  "permission_id" uuid NOT NULL,
  UNIQUE (organization_id, id),
  UNIQUE ("role_id", "permission_id")
);

-- Concesiones de rol por organización o proyecto.
CREATE TABLE nexus."role_grants" (
  "id" uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  "organization_id" uuid NOT NULL,
  "created_at" timestamptz NOT NULL DEFAULT now(),
  "updated_at" timestamptz NOT NULL DEFAULT now(),
  "membership_id" uuid NOT NULL,
  "role_id" uuid NOT NULL,
  "project_id" uuid,
  "granted_by" uuid NOT NULL,
  "expires_at" timestamptz,
  "revoked_at" timestamptz,
  UNIQUE (organization_id, id),
  CHECK (expires_at > created_at)
);

-- Invitaciones temporales sin contraseña local.
CREATE TABLE nexus."invitations" (
  "id" uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  "organization_id" uuid NOT NULL,
  "created_at" timestamptz NOT NULL DEFAULT now(),
  "updated_at" timestamptz NOT NULL DEFAULT now(),
  "email" text NOT NULL,
  "token_hash" text NOT NULL,
  "invited_by" uuid NOT NULL,
  "role_id" uuid NOT NULL,
  "expires_at" timestamptz NOT NULL,
  "accepted_at" timestamptz,
  "revoked_at" timestamptz,
  UNIQUE (organization_id, id),
  UNIQUE ("token_hash"),
  CHECK (expires_at > created_at)
);

-- Preferencias personales sincronizadas.
CREATE TABLE nexus."user_preferences" (
  "id" uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  "organization_id" uuid NOT NULL,
  "created_at" timestamptz NOT NULL DEFAULT now(),
  "updated_at" timestamptz NOT NULL DEFAULT now(),
  "membership_id" uuid NOT NULL,
  "theme" text NOT NULL DEFAULT 'system',
  "locale" text NOT NULL DEFAULT 'es-PE',
  "timezone" text NOT NULL DEFAULT 'America/Lima',
  "reduced_motion" boolean NOT NULL DEFAULT false,
  "dashboard_layout" jsonb NOT NULL DEFAULT '{}'::jsonb,
  "sidebar_collapsed" boolean NOT NULL DEFAULT false,
  UNIQUE (organization_id, id),
  UNIQUE ("membership_id"),
  CHECK (theme IN ('light','dark','system'))
);

-- Configuraciones funcionales de empresa.
CREATE TABLE nexus."organization_settings" (
  "id" uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  "organization_id" uuid NOT NULL,
  "created_at" timestamptz NOT NULL DEFAULT now(),
  "updated_at" timestamptz NOT NULL DEFAULT now(),
  "key" text NOT NULL,
  "value" jsonb NOT NULL,
  "updated_by" uuid NOT NULL,
  "version" integer NOT NULL DEFAULT 1,
  UNIQUE (organization_id, id),
  UNIQUE ("organization_id", "key"),
  CHECK (version > 0)
);

-- Equipos y especialidades de trabajo.
CREATE TABLE nexus."teams" (
  "id" uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  "organization_id" uuid NOT NULL,
  "created_at" timestamptz NOT NULL DEFAULT now(),
  "updated_at" timestamptz NOT NULL DEFAULT now(),
  "name" text NOT NULL,
  "code" text NOT NULL,
  "description" text,
  "archived_at" timestamptz,
  UNIQUE (organization_id, id),
  UNIQUE ("organization_id", "code")
);

-- Membresía N:M de equipos.
CREATE TABLE nexus."team_members" (
  "id" uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  "organization_id" uuid NOT NULL,
  "created_at" timestamptz NOT NULL DEFAULT now(),
  "updated_at" timestamptz NOT NULL DEFAULT now(),
  "team_id" uuid NOT NULL,
  "membership_id" uuid NOT NULL,
  "responsibility" text NOT NULL DEFAULT 'member',
  "removed_at" timestamptz,
  UNIQUE (organization_id, id),
  UNIQUE ("team_id", "membership_id")
);

-- Disponibilidad y capacidad planificada.
CREATE TABLE nexus."availability" (
  "id" uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  "organization_id" uuid NOT NULL,
  "created_at" timestamptz NOT NULL DEFAULT now(),
  "updated_at" timestamptz NOT NULL DEFAULT now(),
  "membership_id" uuid NOT NULL,
  "work_date" date NOT NULL,
  "capacity_minutes" integer NOT NULL,
  "reason" text,
  UNIQUE (organization_id, id),
  UNIQUE ("membership_id", "work_date"),
  CHECK (capacity_minutes BETWEEN 0 AND 1440)
);

-- Portafolio de proyectos; raíz del alcance operativo.
CREATE TABLE nexus."projects" (
  "id" uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  "organization_id" uuid NOT NULL,
  "created_at" timestamptz NOT NULL DEFAULT now(),
  "updated_at" timestamptz NOT NULL DEFAULT now(),
  "code" text NOT NULL,
  "name" text NOT NULL,
  "description" text,
  "status" text NOT NULL DEFAULT 'planned',
  "priority" text NOT NULL DEFAULT 'medium',
  "start_date" date,
  "due_date" date,
  "created_by" uuid NOT NULL,
  "version" integer NOT NULL DEFAULT 1,
  "archived_at" timestamptz,
  UNIQUE (organization_id, id),
  UNIQUE ("organization_id", "code"),
  CHECK (status IN ('planned','active','paused','completed','archived')),
  CHECK (priority IN ('low','medium','high','urgent')),
  CHECK (due_date >= start_date),
  CHECK (version > 0)
);

-- Participación en proyecto, independiente del rol global.
CREATE TABLE nexus."project_members" (
  "id" uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  "organization_id" uuid NOT NULL,
  "project_id" uuid NOT NULL,
  "created_at" timestamptz NOT NULL DEFAULT now(),
  "updated_at" timestamptz NOT NULL DEFAULT now(),
  "membership_id" uuid NOT NULL,
  "team_id" uuid,
  "removed_at" timestamptz,
  UNIQUE (organization_id, id),
  UNIQUE (organization_id, project_id, id),
  UNIQUE ("project_id", "membership_id"),
  UNIQUE ("organization_id", "project_id", "membership_id")
);

-- Hitos y entregables.
CREATE TABLE nexus."milestones" (
  "id" uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  "organization_id" uuid NOT NULL,
  "project_id" uuid NOT NULL,
  "created_at" timestamptz NOT NULL DEFAULT now(),
  "updated_at" timestamptz NOT NULL DEFAULT now(),
  "name" text NOT NULL,
  "due_date" date,
  "completed_at" timestamptz,
  "description" text,
  UNIQUE (organization_id, id),
  UNIQUE (organization_id, project_id, id)
);

-- Tableros múltiples por proyecto.
CREATE TABLE nexus."boards" (
  "id" uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  "organization_id" uuid NOT NULL,
  "project_id" uuid NOT NULL,
  "created_at" timestamptz NOT NULL DEFAULT now(),
  "updated_at" timestamptz NOT NULL DEFAULT now(),
  "name" text NOT NULL,
  "description" text,
  "position" numeric(20,8) NOT NULL DEFAULT 0,
  "version" integer NOT NULL DEFAULT 1,
  "archived_at" timestamptz,
  UNIQUE (organization_id, id),
  UNIQUE (organization_id, project_id, id),
  CHECK (version > 0)
);

-- Columnas personalizadas con semántica estable.
CREATE TABLE nexus."board_columns" (
  "id" uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  "organization_id" uuid NOT NULL,
  "project_id" uuid NOT NULL,
  "created_at" timestamptz NOT NULL DEFAULT now(),
  "updated_at" timestamptz NOT NULL DEFAULT now(),
  "board_id" uuid NOT NULL,
  "name" text NOT NULL,
  "status_category" text NOT NULL,
  "position" numeric(20,8) NOT NULL DEFAULT 0,
  "wip_limit" integer,
  "color" text,
  "version" integer NOT NULL DEFAULT 1,
  "archived_at" timestamptz,
  UNIQUE (organization_id, id),
  UNIQUE (organization_id, project_id, id),
  UNIQUE ("organization_id", "project_id", "board_id", "id"),
  CHECK (status_category IN ('todo','doing','review','done','blocked')),
  CHECK (wip_limit > 0),
  CHECK (version > 0)
);

-- Única entidad de tarea; no duplicar en una tabla tasks.
CREATE TABLE nexus."cards" (
  "id" uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  "organization_id" uuid NOT NULL,
  "project_id" uuid NOT NULL,
  "created_at" timestamptz NOT NULL DEFAULT now(),
  "updated_at" timestamptz NOT NULL DEFAULT now(),
  "board_id" uuid NOT NULL,
  "column_id" uuid NOT NULL,
  "parent_card_id" uuid,
  "milestone_id" uuid,
  "code" text NOT NULL,
  "title" text NOT NULL,
  "description" jsonb NOT NULL DEFAULT '{}'::jsonb,
  "priority" text NOT NULL DEFAULT 'medium',
  "complexity" text,
  "specialty" text,
  "task_type" text,
  "estimated_minutes" integer,
  "start_date" date,
  "due_date" date,
  "completed_at" timestamptz,
  "position" numeric(20,8) NOT NULL DEFAULT 0,
  "created_by" uuid NOT NULL,
  "version" integer NOT NULL DEFAULT 1,
  "archived_at" timestamptz,
  UNIQUE (organization_id, id),
  UNIQUE (organization_id, project_id, id),
  UNIQUE ("project_id", "code"),
  CHECK (priority IN ('low','medium','high','urgent')),
  CHECK (complexity IN ('low','medium','high')),
  CHECK (estimated_minutes >= 0),
  CHECK (due_date >= start_date),
  CHECK (version > 0),
  CHECK (parent_card_id <> id)
);

-- Asignación N:M de tarjetas a miembros del proyecto.
CREATE TABLE nexus."card_assignees" (
  "id" uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  "organization_id" uuid NOT NULL,
  "project_id" uuid NOT NULL,
  "created_at" timestamptz NOT NULL DEFAULT now(),
  "updated_at" timestamptz NOT NULL DEFAULT now(),
  "card_id" uuid NOT NULL,
  "membership_id" uuid NOT NULL,
  "assigned_by" uuid NOT NULL,
  "removed_at" timestamptz,
  UNIQUE (organization_id, id),
  UNIQUE (organization_id, project_id, id),
  UNIQUE ("card_id", "membership_id")
);

-- Etiquetas globales de organización o locales de proyecto.
CREATE TABLE nexus."labels" (
  "id" uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  "organization_id" uuid NOT NULL,
  "created_at" timestamptz NOT NULL DEFAULT now(),
  "updated_at" timestamptz NOT NULL DEFAULT now(),
  "project_id" uuid,
  "name" text NOT NULL,
  "normalized_name" text NOT NULL,
  "color" text NOT NULL,
  "archived_at" timestamptz,
  UNIQUE (organization_id, id),
  CHECK (color ~ '^#[0-9A-Fa-f]{6}$')
);

-- Relación N:M tarjeta-etiqueta.
CREATE TABLE nexus."card_labels" (
  "id" uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  "organization_id" uuid NOT NULL,
  "project_id" uuid NOT NULL,
  "created_at" timestamptz NOT NULL DEFAULT now(),
  "updated_at" timestamptz NOT NULL DEFAULT now(),
  "card_id" uuid NOT NULL,
  "label_id" uuid NOT NULL,
  UNIQUE (organization_id, id),
  UNIQUE (organization_id, project_id, id),
  UNIQUE ("card_id", "label_id")
);

-- Campos personalizados de tablero.
CREATE TABLE nexus."field_definitions" (
  "id" uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  "organization_id" uuid NOT NULL,
  "project_id" uuid NOT NULL,
  "created_at" timestamptz NOT NULL DEFAULT now(),
  "updated_at" timestamptz NOT NULL DEFAULT now(),
  "board_id" uuid NOT NULL,
  "name" text NOT NULL,
  "field_type" text NOT NULL,
  "options" jsonb NOT NULL DEFAULT '[]'::jsonb,
  "is_required" boolean NOT NULL DEFAULT false,
  "archived_at" timestamptz,
  UNIQUE (organization_id, id),
  UNIQUE (organization_id, project_id, id),
  CHECK (field_type IN ('text','number','date','select','boolean'))
);

-- Valores de campos personalizados por tarjeta.
CREATE TABLE nexus."field_values" (
  "id" uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  "organization_id" uuid NOT NULL,
  "project_id" uuid NOT NULL,
  "created_at" timestamptz NOT NULL DEFAULT now(),
  "updated_at" timestamptz NOT NULL DEFAULT now(),
  "card_id" uuid NOT NULL,
  "field_definition_id" uuid NOT NULL,
  "value" jsonb NOT NULL,
  UNIQUE (organization_id, id),
  UNIQUE (organization_id, project_id, id),
  UNIQUE ("card_id", "field_definition_id")
);

-- Listas de verificación en tarjetas.
CREATE TABLE nexus."checklists" (
  "id" uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  "organization_id" uuid NOT NULL,
  "project_id" uuid NOT NULL,
  "created_at" timestamptz NOT NULL DEFAULT now(),
  "updated_at" timestamptz NOT NULL DEFAULT now(),
  "card_id" uuid NOT NULL,
  "name" text NOT NULL,
  "position" numeric(20,8) NOT NULL DEFAULT 0,
  UNIQUE (organization_id, id),
  UNIQUE (organization_id, project_id, id)
);

-- Ítems marcables con responsable y fecha.
CREATE TABLE nexus."checklist_items" (
  "id" uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  "organization_id" uuid NOT NULL,
  "project_id" uuid NOT NULL,
  "created_at" timestamptz NOT NULL DEFAULT now(),
  "updated_at" timestamptz NOT NULL DEFAULT now(),
  "checklist_id" uuid NOT NULL,
  "text" text NOT NULL,
  "assignee_id" uuid,
  "position" numeric(20,8) NOT NULL DEFAULT 0,
  "completed_at" timestamptz,
  "completed_by" uuid,
  "due_date" date,
  UNIQUE (organization_id, id),
  UNIQUE (organization_id, project_id, id),
  CHECK ((completed_at IS NULL) = (completed_by IS NULL))
);

-- Grafo dirigido de bloqueo entre tarjetas.
CREATE TABLE nexus."card_dependencies" (
  "id" uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  "organization_id" uuid NOT NULL,
  "project_id" uuid NOT NULL,
  "created_at" timestamptz NOT NULL DEFAULT now(),
  "updated_at" timestamptz NOT NULL DEFAULT now(),
  "card_id" uuid NOT NULL,
  "prerequisite_id" uuid NOT NULL,
  "kind" text NOT NULL DEFAULT 'blocks',
  UNIQUE (organization_id, id),
  UNIQUE (organization_id, project_id, id),
  UNIQUE ("card_id", "prerequisite_id"),
  CHECK (card_id <> prerequisite_id)
);

-- Comentarios de tarjeta con edición trazable.
CREATE TABLE nexus."comments" (
  "id" uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  "organization_id" uuid NOT NULL,
  "project_id" uuid NOT NULL,
  "created_at" timestamptz NOT NULL DEFAULT now(),
  "updated_at" timestamptz NOT NULL DEFAULT now(),
  "card_id" uuid NOT NULL,
  "parent_comment_id" uuid,
  "author_id" uuid NOT NULL,
  "body" text NOT NULL,
  "edited_at" timestamptz,
  "deleted_at" timestamptz,
  UNIQUE (organization_id, id),
  UNIQUE (organization_id, project_id, id),
  UNIQUE ("organization_id", "project_id", "card_id", "id")
);

-- Menciones a miembros en comentarios.
CREATE TABLE nexus."comment_mentions" (
  "id" uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  "organization_id" uuid NOT NULL,
  "project_id" uuid NOT NULL,
  "created_at" timestamptz NOT NULL DEFAULT now(),
  "updated_at" timestamptz NOT NULL DEFAULT now(),
  "comment_id" uuid NOT NULL,
  "membership_id" uuid NOT NULL,
  UNIQUE (organization_id, id),
  UNIQUE (organization_id, project_id, id),
  UNIQUE ("comment_id", "membership_id")
);

-- Reacciones por código de icono, sin emojis requeridos.
CREATE TABLE nexus."comment_reactions" (
  "id" uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  "organization_id" uuid NOT NULL,
  "project_id" uuid NOT NULL,
  "created_at" timestamptz NOT NULL DEFAULT now(),
  "updated_at" timestamptz NOT NULL DEFAULT now(),
  "comment_id" uuid NOT NULL,
  "membership_id" uuid NOT NULL,
  "reaction_code" text NOT NULL,
  UNIQUE (organization_id, id),
  UNIQUE (organization_id, project_id, id),
  UNIQUE ("comment_id", "membership_id", "reaction_code")
);

-- Metadatos de objetos privados, no contenido binario.
CREATE TABLE nexus."files" (
  "id" uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  "organization_id" uuid NOT NULL,
  "created_at" timestamptz NOT NULL DEFAULT now(),
  "updated_at" timestamptz NOT NULL DEFAULT now(),
  "bucket" text NOT NULL,
  "object_path" text NOT NULL,
  "original_name" text NOT NULL,
  "mime_type" text NOT NULL,
  "size_bytes" bigint NOT NULL,
  "sha256" text,
  "uploaded_by" uuid NOT NULL,
  "status" text NOT NULL DEFAULT 'pending',
  UNIQUE (organization_id, id),
  UNIQUE ("bucket", "object_path"),
  CHECK (size_bytes >= 0),
  CHECK (status IN ('pending','ready','rejected','deleted'))
);

-- Vínculos de archivos con tarjetas.
CREATE TABLE nexus."attachments" (
  "id" uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  "organization_id" uuid NOT NULL,
  "project_id" uuid NOT NULL,
  "created_at" timestamptz NOT NULL DEFAULT now(),
  "updated_at" timestamptz NOT NULL DEFAULT now(),
  "card_id" uuid NOT NULL,
  "file_id" uuid NOT NULL,
  "added_by" uuid NOT NULL,
  "removed_at" timestamptz,
  UNIQUE (organization_id, id),
  UNIQUE (organization_id, project_id, id),
  UNIQUE ("card_id", "file_id")
);

-- Seguidores de actividad de tarjetas.
CREATE TABLE nexus."card_watchers" (
  "id" uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  "organization_id" uuid NOT NULL,
  "project_id" uuid NOT NULL,
  "created_at" timestamptz NOT NULL DEFAULT now(),
  "updated_at" timestamptz NOT NULL DEFAULT now(),
  "card_id" uuid NOT NULL,
  "membership_id" uuid NOT NULL,
  UNIQUE (organization_id, id),
  UNIQUE (organization_id, project_id, id),
  UNIQUE ("card_id", "membership_id")
);

-- Historial funcional de cambios por tarjeta.
CREATE TABLE nexus."card_events" (
  "id" uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  "organization_id" uuid NOT NULL,
  "project_id" uuid NOT NULL,
  "created_at" timestamptz NOT NULL DEFAULT now(),
  "card_id" uuid NOT NULL,
  "actor_id" uuid,
  "kind" text NOT NULL,
  "payload" jsonb NOT NULL DEFAULT '{}'::jsonb,
  "correlation_id" uuid NOT NULL,
  UNIQUE (organization_id, id),
  UNIQUE (organization_id, project_id, id)
);

-- Cronómetro persistente por persona.
CREATE TABLE nexus."timers" (
  "id" uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  "organization_id" uuid NOT NULL,
  "project_id" uuid NOT NULL,
  "created_at" timestamptz NOT NULL DEFAULT now(),
  "updated_at" timestamptz NOT NULL DEFAULT now(),
  "card_id" uuid NOT NULL,
  "membership_id" uuid NOT NULL,
  "started_at" timestamptz NOT NULL,
  "stopped_at" timestamptz,
  "status" text NOT NULL DEFAULT 'running',
  UNIQUE (organization_id, id),
  UNIQUE (organization_id, project_id, id),
  UNIQUE ("organization_id", "project_id", "card_id", "membership_id", "id"),
  CHECK (stopped_at >= started_at),
  CHECK (status IN ('running','stopped','cancelled')),
  CHECK ((status = 'running') = (stopped_at IS NULL))
);

-- Registro de esfuerzo real, manual o desde cronómetro.
CREATE TABLE nexus."time_entries" (
  "id" uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  "organization_id" uuid NOT NULL,
  "project_id" uuid NOT NULL,
  "created_at" timestamptz NOT NULL DEFAULT now(),
  "updated_at" timestamptz NOT NULL DEFAULT now(),
  "card_id" uuid NOT NULL,
  "membership_id" uuid NOT NULL,
  "timer_id" uuid,
  "work_date" date NOT NULL,
  "minutes" integer NOT NULL,
  "note" text,
  "status" text NOT NULL DEFAULT 'draft',
  "submitted_at" timestamptz,
  "version" integer NOT NULL DEFAULT 1,
  UNIQUE (organization_id, id),
  UNIQUE (organization_id, project_id, id),
  UNIQUE ("timer_id"),
  CHECK (minutes BETWEEN 1 AND 1440),
  CHECK (status IN ('draft','submitted','approved','rejected','void')),
  CHECK (version > 0)
);

-- Historial de cambios de parte de horas.
CREATE TABLE nexus."time_entry_versions" (
  "id" uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  "organization_id" uuid NOT NULL,
  "project_id" uuid NOT NULL,
  "created_at" timestamptz NOT NULL DEFAULT now(),
  "time_entry_id" uuid NOT NULL,
  "revision" integer NOT NULL,
  "snapshot" jsonb NOT NULL,
  "actor_id" uuid NOT NULL,
  UNIQUE (organization_id, id),
  UNIQUE (organization_id, project_id, id),
  UNIQUE ("time_entry_id", "revision"),
  CHECK (revision > 0)
);

-- Decisiones sobre horas o cierre de tarjeta, sin FK polimórfica libre.
CREATE TABLE nexus."approvals" (
  "id" uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  "organization_id" uuid NOT NULL,
  "project_id" uuid NOT NULL,
  "created_at" timestamptz NOT NULL DEFAULT now(),
  "updated_at" timestamptz NOT NULL DEFAULT now(),
  "time_entry_id" uuid,
  "card_id" uuid,
  "requested_by" uuid NOT NULL,
  "reviewed_by" uuid,
  "decision" text NOT NULL DEFAULT 'pending',
  "reason" text,
  "decided_at" timestamptz,
  UNIQUE (organization_id, id),
  UNIQUE (organization_id, project_id, id),
  CHECK (num_nonnulls(time_entry_id,card_id) = 1),
  CHECK (decision IN ('pending','approved','rejected')),
  CHECK (reviewed_by <> requested_by),
  CHECK ((decision = 'pending' AND reviewed_by IS NULL AND decided_at IS NULL) OR (decision <> 'pending' AND reviewed_by IS NOT NULL AND decided_at IS NOT NULL))
);

-- Agenda de reuniones, entregas y formación.
CREATE TABLE nexus."calendar_events" (
  "id" uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  "organization_id" uuid NOT NULL,
  "created_at" timestamptz NOT NULL DEFAULT now(),
  "updated_at" timestamptz NOT NULL DEFAULT now(),
  "project_id" uuid,
  "owner_id" uuid NOT NULL,
  "title" text NOT NULL,
  "starts_at" timestamptz NOT NULL,
  "ends_at" timestamptz NOT NULL,
  "timezone" text NOT NULL DEFAULT 'America/Lima',
  "visibility" text NOT NULL DEFAULT 'private',
  "external_id" text,
  UNIQUE (organization_id, id),
  CHECK (ends_at > starts_at),
  CHECK (visibility IN ('private','project','organization')),
  CHECK (visibility <> 'project' OR project_id IS NOT NULL),
  CHECK (length(trim(title)) > 0)
);

-- Invitados y respuestas.
CREATE TABLE nexus."calendar_attendees" (
  "id" uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  "organization_id" uuid NOT NULL,
  "created_at" timestamptz NOT NULL DEFAULT now(),
  "updated_at" timestamptz NOT NULL DEFAULT now(),
  "event_id" uuid NOT NULL,
  "membership_id" uuid NOT NULL,
  "response" text NOT NULL DEFAULT 'pending',
  UNIQUE (organization_id, id),
  UNIQUE ("event_id", "membership_id"),
  CHECK (response IN ('pending','accepted','declined'))
);

-- Bloqueos técnicos y solicitudes internas.
CREATE TABLE nexus."tickets" (
  "id" uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  "organization_id" uuid NOT NULL,
  "created_at" timestamptz NOT NULL DEFAULT now(),
  "updated_at" timestamptz NOT NULL DEFAULT now(),
  "project_id" uuid,
  "reporter_id" uuid NOT NULL,
  "assignee_id" uuid,
  "title" text NOT NULL,
  "description" text NOT NULL,
  "status" text NOT NULL DEFAULT 'open',
  "priority" text NOT NULL DEFAULT 'medium',
  "resolved_at" timestamptz,
  UNIQUE (organization_id, id),
  CHECK (status IN ('open','in_progress','resolved','closed')),
  CHECK (priority IN ('low','medium','high','urgent'))
);

-- Conversación y solución de soporte.
CREATE TABLE nexus."ticket_comments" (
  "id" uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  "organization_id" uuid NOT NULL,
  "created_at" timestamptz NOT NULL DEFAULT now(),
  "updated_at" timestamptz NOT NULL DEFAULT now(),
  "ticket_id" uuid NOT NULL,
  "author_id" uuid NOT NULL,
  "body" text NOT NULL,
  UNIQUE (organization_id, id)
);

-- Vínculo de bloqueo con tarjeta.
CREATE TABLE nexus."ticket_links" (
  "id" uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  "organization_id" uuid NOT NULL,
  "project_id" uuid NOT NULL,
  "created_at" timestamptz NOT NULL DEFAULT now(),
  "updated_at" timestamptz NOT NULL DEFAULT now(),
  "ticket_id" uuid NOT NULL,
  "card_id" uuid NOT NULL,
  UNIQUE (organization_id, id),
  UNIQUE (organization_id, project_id, id),
  UNIQUE ("ticket_id", "card_id")
);

-- Plantillas para creación de tarjetas y checklists.
CREATE TABLE nexus."card_templates" (
  "id" uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  "organization_id" uuid NOT NULL,
  "project_id" uuid NOT NULL,
  "created_at" timestamptz NOT NULL DEFAULT now(),
  "updated_at" timestamptz NOT NULL DEFAULT now(),
  "name" text NOT NULL,
  "payload" jsonb NOT NULL,
  "created_by" uuid NOT NULL,
  "archived_at" timestamptz,
  UNIQUE (organization_id, id),
  UNIQUE (organization_id, project_id, id)
);

-- Reglas declarativas, incluidas tareas recurrentes.
CREATE TABLE nexus."automation_rules" (
  "id" uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  "organization_id" uuid NOT NULL,
  "project_id" uuid NOT NULL,
  "created_at" timestamptz NOT NULL DEFAULT now(),
  "updated_at" timestamptz NOT NULL DEFAULT now(),
  "name" text NOT NULL,
  "trigger_code" text NOT NULL,
  "conditions" jsonb NOT NULL DEFAULT '{}'::jsonb,
  "actions" jsonb NOT NULL,
  "enabled" boolean NOT NULL DEFAULT false,
  "created_by" uuid NOT NULL,
  "next_run_at" timestamptz,
  UNIQUE (organization_id, id),
  UNIQUE (organization_id, project_id, id)
);

-- Ejecuciones idempotentes de reglas.
CREATE TABLE nexus."automation_runs" (
  "id" uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  "organization_id" uuid NOT NULL,
  "project_id" uuid NOT NULL,
  "created_at" timestamptz NOT NULL DEFAULT now(),
  "updated_at" timestamptz NOT NULL DEFAULT now(),
  "rule_id" uuid NOT NULL,
  "trigger_key" text NOT NULL,
  "status" text NOT NULL DEFAULT 'queued',
  "result" jsonb,
  UNIQUE (organization_id, id),
  UNIQUE (organization_id, project_id, id),
  UNIQUE ("rule_id", "trigger_key"),
  CHECK (status IN ('queued','running','succeeded','failed','cancelled'))
);

-- Documento lógico con audiencia y ciclo editorial.
CREATE TABLE nexus."documents" (
  "id" uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  "organization_id" uuid NOT NULL,
  "created_at" timestamptz NOT NULL DEFAULT now(),
  "updated_at" timestamptz NOT NULL DEFAULT now(),
  "project_id" uuid,
  "title" text NOT NULL,
  "category" text NOT NULL,
  "visibility" text NOT NULL DEFAULT 'restricted',
  "owner_id" uuid NOT NULL,
  "status" text NOT NULL DEFAULT 'draft',
  "archived_at" timestamptz,
  UNIQUE (organization_id, id),
  CHECK (visibility IN ('organization','project','restricted')),
  CHECK (visibility <> 'project' OR project_id IS NOT NULL),
  CHECK (status IN ('draft','published','withdrawn','archived'))
);

-- Versiones de archivo y contenido aprobadas.
CREATE TABLE nexus."document_versions" (
  "id" uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  "organization_id" uuid NOT NULL,
  "created_at" timestamptz NOT NULL DEFAULT now(),
  "updated_at" timestamptz NOT NULL DEFAULT now(),
  "document_id" uuid NOT NULL,
  "revision" integer NOT NULL,
  "file_id" uuid NOT NULL,
  "content_hash" text NOT NULL,
  "status" text NOT NULL DEFAULT 'draft',
  "created_by" uuid NOT NULL,
  "approved_by" uuid,
  "published_at" timestamptz,
  "valid_from" timestamptz,
  "valid_until" timestamptz,
  UNIQUE (organization_id, id),
  UNIQUE ("document_id", "revision"),
  CHECK (revision > 0),
  CHECK (approved_by <> created_by),
  CHECK (valid_until > valid_from),
  CHECK (status IN ('draft','in_review','approved','published','superseded','withdrawn')),
  CHECK (status <> 'published' OR (approved_by IS NOT NULL AND published_at IS NOT NULL AND valid_from IS NOT NULL))
);

-- Concesiones de lectura de documento a miembros específicos.
CREATE TABLE nexus."document_acl" (
  "id" uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  "organization_id" uuid NOT NULL,
  "created_at" timestamptz NOT NULL DEFAULT now(),
  "updated_at" timestamptz NOT NULL DEFAULT now(),
  "document_id" uuid NOT NULL,
  "membership_id" uuid NOT NULL,
  "expires_at" timestamptz,
  "revoked_at" timestamptz,
  UNIQUE (organization_id, id),
  UNIQUE ("document_id", "membership_id")
);

-- Cola de indexación y retirada del conocimiento.
CREATE TABLE nexus."index_jobs" (
  "id" uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  "organization_id" uuid NOT NULL,
  "created_at" timestamptz NOT NULL DEFAULT now(),
  "updated_at" timestamptz NOT NULL DEFAULT now(),
  "document_version_id" uuid NOT NULL,
  "operation" text NOT NULL,
  "status" text NOT NULL DEFAULT 'queued',
  "attempts" integer NOT NULL DEFAULT 0,
  "provider_ref" text,
  "last_error_code" text,
  "finished_at" timestamptz,
  UNIQUE (organization_id, id),
  CHECK (operation IN ('upsert','remove')),
  CHECK (attempts >= 0),
  CHECK (status IN ('queued','running','succeeded','failed','cancelled'))
);

-- Referencias recuperables a fragmentos indexados.
CREATE TABLE nexus."source_refs" (
  "id" uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  "organization_id" uuid NOT NULL,
  "created_at" timestamptz NOT NULL DEFAULT now(),
  "updated_at" timestamptz NOT NULL DEFAULT now(),
  "document_version_id" uuid NOT NULL,
  "chunk_key" text NOT NULL,
  "page_number" integer,
  "section_title" text,
  "provider_ref" text,
  "content_hash" text NOT NULL,
  "revoked_at" timestamptz,
  UNIQUE (organization_id, id),
  UNIQUE ("document_version_id", "chunk_key"),
  CHECK (page_number > 0)
);

-- Rutas de formación por especialidad.
CREATE TABLE nexus."learning_paths" (
  "id" uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  "organization_id" uuid NOT NULL,
  "created_at" timestamptz NOT NULL DEFAULT now(),
  "updated_at" timestamptz NOT NULL DEFAULT now(),
  "slug" text NOT NULL,
  "name" text NOT NULL,
  "description" text,
  "status" text NOT NULL DEFAULT 'draft',
  UNIQUE (organization_id, id),
  UNIQUE ("organization_id", "slug"),
  CHECK (status IN ('draft','published','archived'))
);

-- Curso lógico y propietario editorial.
CREATE TABLE nexus."courses" (
  "id" uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  "organization_id" uuid NOT NULL,
  "created_at" timestamptz NOT NULL DEFAULT now(),
  "updated_at" timestamptz NOT NULL DEFAULT now(),
  "slug" text NOT NULL,
  "name" text NOT NULL,
  "specialty" text NOT NULL,
  "level" text NOT NULL,
  "owner_id" uuid NOT NULL,
  "status" text NOT NULL DEFAULT 'draft',
  UNIQUE (organization_id, id),
  UNIQUE ("organization_id", "slug"),
  CHECK (status IN ('draft','published','archived')),
  CHECK (level IN ('beginner','intermediate','advanced'))
);

-- Versiones inmutables de temario publicado.
CREATE TABLE nexus."course_versions" (
  "id" uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  "organization_id" uuid NOT NULL,
  "created_at" timestamptz NOT NULL DEFAULT now(),
  "updated_at" timestamptz NOT NULL DEFAULT now(),
  "course_id" uuid NOT NULL,
  "revision" integer NOT NULL,
  "status" text NOT NULL DEFAULT 'draft',
  "created_by" uuid NOT NULL,
  "approved_by" uuid,
  "published_at" timestamptz,
  UNIQUE (organization_id, id),
  UNIQUE ("course_id", "revision"),
  CHECK (revision > 0),
  CHECK (approved_by <> created_by),
  CHECK (status IN ('draft','in_review','published','retired')),
  CHECK (status <> 'published' OR (approved_by IS NOT NULL AND published_at IS NOT NULL))
);

-- Cursos ordenados dentro de una ruta.
CREATE TABLE nexus."path_courses" (
  "id" uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  "organization_id" uuid NOT NULL,
  "created_at" timestamptz NOT NULL DEFAULT now(),
  "updated_at" timestamptz NOT NULL DEFAULT now(),
  "path_id" uuid NOT NULL,
  "course_id" uuid NOT NULL,
  "position" integer NOT NULL,
  "required" boolean NOT NULL DEFAULT true,
  UNIQUE (organization_id, id),
  UNIQUE ("path_id", "course_id"),
  CHECK (position >= 0)
);

-- Módulos de una versión de curso.
CREATE TABLE nexus."course_modules" (
  "id" uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  "organization_id" uuid NOT NULL,
  "created_at" timestamptz NOT NULL DEFAULT now(),
  "updated_at" timestamptz NOT NULL DEFAULT now(),
  "course_version_id" uuid NOT NULL,
  "name" text NOT NULL,
  "position" integer NOT NULL,
  UNIQUE (organization_id, id),
  UNIQUE ("course_version_id", "position"),
  CHECK (position >= 0)
);

-- Lecciones, teoría, video y práctica.
CREATE TABLE nexus."lessons" (
  "id" uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  "organization_id" uuid NOT NULL,
  "created_at" timestamptz NOT NULL DEFAULT now(),
  "updated_at" timestamptz NOT NULL DEFAULT now(),
  "course_module_id" uuid NOT NULL,
  "title" text NOT NULL,
  "kind" text NOT NULL,
  "content" jsonb NOT NULL DEFAULT '{}'::jsonb,
  "estimated_minutes" integer,
  "position" integer NOT NULL,
  UNIQUE (organization_id, id),
  UNIQUE ("course_module_id", "position"),
  CHECK (kind IN ('article','video','lab','quiz')),
  CHECK (estimated_minutes >= 0),
  CHECK (position >= 0)
);

-- Material complementario aprobado.
CREATE TABLE nexus."lesson_resources" (
  "id" uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  "organization_id" uuid NOT NULL,
  "created_at" timestamptz NOT NULL DEFAULT now(),
  "updated_at" timestamptz NOT NULL DEFAULT now(),
  "lesson_id" uuid NOT NULL,
  "file_id" uuid,
  "document_version_id" uuid,
  "title" text NOT NULL,
  UNIQUE (organization_id, id),
  CHECK (num_nonnulls(file_id,document_version_id) = 1)
);

-- Matrículas fijadas a una versión concreta.
CREATE TABLE nexus."enrollments" (
  "id" uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  "organization_id" uuid NOT NULL,
  "created_at" timestamptz NOT NULL DEFAULT now(),
  "updated_at" timestamptz NOT NULL DEFAULT now(),
  "course_version_id" uuid NOT NULL,
  "membership_id" uuid NOT NULL,
  "assigned_by" uuid,
  "status" text NOT NULL DEFAULT 'active',
  "completed_at" timestamptz,
  UNIQUE (organization_id, id),
  UNIQUE ("course_version_id", "membership_id"),
  CHECK (status IN ('active','completed','withdrawn'))
);

-- Progreso validado por servidor.
CREATE TABLE nexus."lesson_progress" (
  "id" uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  "organization_id" uuid NOT NULL,
  "created_at" timestamptz NOT NULL DEFAULT now(),
  "updated_at" timestamptz NOT NULL DEFAULT now(),
  "enrollment_id" uuid NOT NULL,
  "lesson_id" uuid NOT NULL,
  "status" text NOT NULL DEFAULT 'not_started',
  "seconds_spent" integer NOT NULL DEFAULT 0,
  "completed_at" timestamptz,
  UNIQUE (organization_id, id),
  UNIQUE ("enrollment_id", "lesson_id"),
  CHECK (seconds_spent >= 0),
  CHECK (status IN ('not_started','in_progress','completed'))
);

-- Evaluaciones y laboratorios evaluables.
CREATE TABLE nexus."assessments" (
  "id" uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  "organization_id" uuid NOT NULL,
  "created_at" timestamptz NOT NULL DEFAULT now(),
  "updated_at" timestamptz NOT NULL DEFAULT now(),
  "course_version_id" uuid NOT NULL,
  "lesson_id" uuid,
  "title" text NOT NULL,
  "passing_score" numeric(5,2) NOT NULL DEFAULT 70,
  "max_attempts" integer NOT NULL DEFAULT 3,
  "status" text NOT NULL DEFAULT 'draft',
  UNIQUE (organization_id, id),
  CHECK (passing_score BETWEEN 0 AND 100),
  CHECK (max_attempts > 0),
  CHECK (status IN ('draft','published','retired'))
);

-- Enunciados y opciones sin solución.
CREATE TABLE nexus."assessment_questions" (
  "id" uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  "organization_id" uuid NOT NULL,
  "created_at" timestamptz NOT NULL DEFAULT now(),
  "updated_at" timestamptz NOT NULL DEFAULT now(),
  "assessment_id" uuid NOT NULL,
  "prompt" text NOT NULL,
  "kind" text NOT NULL,
  "options" jsonb NOT NULL DEFAULT '[]'::jsonb,
  "points" numeric(8,2) NOT NULL DEFAULT 1,
  "position" integer NOT NULL,
  UNIQUE (organization_id, id),
  UNIQUE ("assessment_id", "position"),
  CHECK (points > 0),
  CHECK (position >= 0),
  CHECK (kind IN ('single','multiple','text','lab'))
);

-- Soluciones y rúbricas separadas del enunciado.
CREATE TABLE nexus."assessment_answer_keys" (
  "id" uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  "organization_id" uuid NOT NULL,
  "created_at" timestamptz NOT NULL DEFAULT now(),
  "updated_at" timestamptz NOT NULL DEFAULT now(),
  "question_id" uuid NOT NULL,
  "answer" jsonb NOT NULL,
  UNIQUE (organization_id, id),
  UNIQUE ("question_id")
);

-- Intentos de evaluación y resultado.
CREATE TABLE nexus."attempts" (
  "id" uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  "organization_id" uuid NOT NULL,
  "created_at" timestamptz NOT NULL DEFAULT now(),
  "updated_at" timestamptz NOT NULL DEFAULT now(),
  "enrollment_id" uuid NOT NULL,
  "assessment_id" uuid NOT NULL,
  "attempt_number" integer NOT NULL,
  "status" text NOT NULL DEFAULT 'in_progress',
  "submitted_at" timestamptz,
  "score" numeric(5,2),
  "graded_at" timestamptz,
  UNIQUE (organization_id, id),
  UNIQUE ("enrollment_id", "assessment_id", "attempt_number"),
  CHECK (attempt_number > 0),
  CHECK (score BETWEEN 0 AND 100),
  CHECK (status IN ('in_progress','submitted','graded'))
);

-- Respuestas del alumno, incluyendo evidencia de laboratorio.
CREATE TABLE nexus."attempt_answers" (
  "id" uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  "organization_id" uuid NOT NULL,
  "created_at" timestamptz NOT NULL DEFAULT now(),
  "updated_at" timestamptz NOT NULL DEFAULT now(),
  "attempt_id" uuid NOT NULL,
  "question_id" uuid NOT NULL,
  "answer" jsonb NOT NULL,
  "file_id" uuid,
  "awarded_points" numeric(8,2),
  "feedback" text,
  UNIQUE (organization_id, id),
  UNIQUE ("attempt_id", "question_id"),
  CHECK (awarded_points >= 0)
);

-- Mentorías programadas.
CREATE TABLE nexus."mentoring_sessions" (
  "id" uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  "organization_id" uuid NOT NULL,
  "created_at" timestamptz NOT NULL DEFAULT now(),
  "updated_at" timestamptz NOT NULL DEFAULT now(),
  "mentor_id" uuid NOT NULL,
  "student_id" uuid NOT NULL,
  "starts_at" timestamptz NOT NULL,
  "ends_at" timestamptz NOT NULL,
  "status" text NOT NULL DEFAULT 'scheduled',
  "topic" text NOT NULL,
  "summary" text,
  UNIQUE (organization_id, id),
  CHECK (mentor_id <> student_id),
  CHECK (ends_at > starts_at),
  CHECK (status IN ('scheduled','completed','cancelled'))
);

-- Preguntas y soluciones compartidas.
CREATE TABLE nexus."forum_posts" (
  "id" uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  "organization_id" uuid NOT NULL,
  "created_at" timestamptz NOT NULL DEFAULT now(),
  "updated_at" timestamptz NOT NULL DEFAULT now(),
  "course_id" uuid NOT NULL,
  "author_id" uuid NOT NULL,
  "parent_post_id" uuid,
  "title" text,
  "body" text NOT NULL,
  "status" text NOT NULL DEFAULT 'visible',
  UNIQUE (organization_id, id),
  UNIQUE ("organization_id", "course_id", "id"),
  CHECK (status IN ('visible','hidden','archived'))
);

-- Catálogo de insignias y reglas versionadas.
CREATE TABLE nexus."achievements" (
  "id" uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  "organization_id" uuid NOT NULL,
  "created_at" timestamptz NOT NULL DEFAULT now(),
  "updated_at" timestamptz NOT NULL DEFAULT now(),
  "code" text NOT NULL,
  "name" text NOT NULL,
  "description" text NOT NULL,
  "icon_key" text NOT NULL,
  "color" text NOT NULL,
  "criteria" jsonb NOT NULL,
  "active" boolean NOT NULL DEFAULT true,
  UNIQUE (organization_id, id),
  UNIQUE ("organization_id", "code")
);

-- Logros otorgados a personas.
CREATE TABLE nexus."member_achievements" (
  "id" uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  "organization_id" uuid NOT NULL,
  "created_at" timestamptz NOT NULL DEFAULT now(),
  "updated_at" timestamptz NOT NULL DEFAULT now(),
  "achievement_id" uuid NOT NULL,
  "membership_id" uuid NOT NULL,
  "evidence" jsonb NOT NULL,
  "revoked_at" timestamptz,
  UNIQUE (organization_id, id),
  UNIQUE ("achievement_id", "membership_id")
);

-- Constancias internas con código verificable.
CREATE TABLE nexus."certificates" (
  "id" uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  "organization_id" uuid NOT NULL,
  "created_at" timestamptz NOT NULL DEFAULT now(),
  "updated_at" timestamptz NOT NULL DEFAULT now(),
  "enrollment_id" uuid NOT NULL,
  "verification_code" uuid NOT NULL DEFAULT gen_random_uuid(),
  "file_id" uuid,
  "issued_at" timestamptz NOT NULL DEFAULT now(),
  "revoked_at" timestamptz,
  UNIQUE (organization_id, id),
  UNIQUE ("verification_code"),
  UNIQUE ("enrollment_id")
);

-- Conversación privada de MIA.
CREATE TABLE nexus."conversations" (
  "id" uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  "organization_id" uuid NOT NULL,
  "created_at" timestamptz NOT NULL DEFAULT now(),
  "updated_at" timestamptz NOT NULL DEFAULT now(),
  "owner_id" uuid NOT NULL,
  "mode" text NOT NULL DEFAULT 'general',
  "project_id" uuid,
  "title" text,
  "provider_thread_id" text,
  "archived_at" timestamptz,
  UNIQUE (organization_id, id),
  CHECK (mode IN ('general','projects','academy','analytics','commercial','voice','briefing'))
);

-- Mensajes de conversación y resultado de consulta.
CREATE TABLE nexus."messages" (
  "id" uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  "organization_id" uuid NOT NULL,
  "created_at" timestamptz NOT NULL DEFAULT now(),
  "updated_at" timestamptz NOT NULL DEFAULT now(),
  "conversation_id" uuid NOT NULL,
  "role" text NOT NULL,
  "body" text NOT NULL,
  "status" text NOT NULL DEFAULT 'completed',
  "sequence" integer NOT NULL,
  "provider_message_id" text,
  UNIQUE (organization_id, id),
  UNIQUE ("conversation_id", "sequence"),
  CHECK (role IN ('user','assistant','tool')),
  CHECK (sequence >= 0),
  CHECK (status IN ('streaming','completed','failed','cancelled'))
);

-- Fuentes de respuesta y evidencia operativa.
CREATE TABLE nexus."citations" (
  "id" uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  "organization_id" uuid NOT NULL,
  "created_at" timestamptz NOT NULL DEFAULT now(),
  "updated_at" timestamptz NOT NULL DEFAULT now(),
  "message_id" uuid NOT NULL,
  "source_ref_id" uuid,
  "card_id" uuid,
  "source_kind" text NOT NULL,
  "snapshot" jsonb,
  UNIQUE (organization_id, id),
  CHECK ((source_kind = 'document' AND source_ref_id IS NOT NULL AND card_id IS NULL) OR (source_kind = 'card' AND card_id IS NOT NULL AND source_ref_id IS NULL) OR (source_kind = 'aggregate' AND source_ref_id IS NULL AND card_id IS NULL))
);

-- Trazabilidad de llamadas de herramientas de MIA.
CREATE TABLE nexus."tool_runs" (
  "id" uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  "organization_id" uuid NOT NULL,
  "created_at" timestamptz NOT NULL DEFAULT now(),
  "updated_at" timestamptz NOT NULL DEFAULT now(),
  "conversation_id" uuid NOT NULL,
  "message_id" uuid,
  "tool_code" text NOT NULL,
  "status" text NOT NULL,
  "correlation_id" uuid NOT NULL,
  "safe_summary" jsonb,
  "finished_at" timestamptz,
  UNIQUE (organization_id, id)
);

-- Propuestas de acción sujetas a confirmación.
CREATE TABLE nexus."action_previews" (
  "id" uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  "organization_id" uuid NOT NULL,
  "created_at" timestamptz NOT NULL DEFAULT now(),
  "updated_at" timestamptz NOT NULL DEFAULT now(),
  "conversation_id" uuid NOT NULL,
  "requested_by" uuid NOT NULL,
  "operation" text NOT NULL,
  "payload" jsonb NOT NULL,
  "expires_at" timestamptz NOT NULL,
  "status" text NOT NULL DEFAULT 'pending',
  "idempotency_key" uuid NOT NULL,
  UNIQUE (organization_id, id),
  UNIQUE ("organization_id", "idempotency_key"),
  CHECK (status IN ('pending','confirmed','executed','expired','cancelled')),
  CHECK (expires_at > created_at)
);

-- Control de sesión de voz/avatar, sin audio persistente por defecto.
CREATE TABLE nexus."speech_sessions" (
  "id" uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  "organization_id" uuid NOT NULL,
  "created_at" timestamptz NOT NULL DEFAULT now(),
  "updated_at" timestamptz NOT NULL DEFAULT now(),
  "membership_id" uuid NOT NULL,
  "conversation_id" uuid,
  "mode" text NOT NULL,
  "started_at" timestamptz NOT NULL,
  "ended_at" timestamptz,
  "consent_at" timestamptz,
  "status" text NOT NULL DEFAULT 'active',
  UNIQUE (organization_id, id),
  CHECK (ended_at >= started_at),
  CHECK (status IN ('active','ended','failed')),
  CHECK (mode IN ('local','speech','avatar'))
);

-- Versiones de clasificación y regresión.
CREATE TABLE nexus."model_versions" (
  "id" uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  "organization_id" uuid NOT NULL,
  "created_at" timestamptz NOT NULL DEFAULT now(),
  "updated_at" timestamptz NOT NULL DEFAULT now(),
  "model_kind" text NOT NULL,
  "version_tag" text NOT NULL,
  "provider_ref" text,
  "target_column" text NOT NULL,
  "feature_schema" jsonb NOT NULL,
  "metrics" jsonb,
  "status" text NOT NULL DEFAULT 'registered',
  UNIQUE (organization_id, id),
  UNIQUE ("organization_id", "model_kind", "version_tag"),
  CHECK (model_kind IN ('classification','regression')),
  CHECK (status IN ('registered','validated','deployed','disabled')),
  CHECK ((model_kind = 'classification' AND target_column = 'Retraso') OR (model_kind = 'regression' AND target_column = 'Horas_reales'))
);

-- Resultados históricos de inferencia, no horas reales.
CREATE TABLE nexus."predictions" (
  "id" uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  "organization_id" uuid NOT NULL,
  "created_at" timestamptz NOT NULL DEFAULT now(),
  "updated_at" timestamptz NOT NULL DEFAULT now(),
  "model_version_id" uuid NOT NULL,
  "requested_by" uuid NOT NULL,
  "project_id" uuid,
  "card_id" uuid,
  "input_snapshot" jsonb NOT NULL,
  "status" text NOT NULL DEFAULT 'pending',
  "predicted_delay" boolean,
  "probability" numeric(8,7),
  "predicted_hours" numeric(12,4),
  "error_code" text,
  "finished_at" timestamptz,
  UNIQUE (organization_id, id),
  CHECK (probability BETWEEN 0 AND 1),
  CHECK (predicted_hours >= 0),
  CHECK (card_id IS NULL OR project_id IS NOT NULL),
  CHECK (status IN ('pending','succeeded','failed')),
  CHECK (status <> 'succeeded' OR (num_nonnulls(predicted_delay,predicted_hours) = 1 AND finished_at IS NOT NULL)),
  CHECK (status = 'succeeded' OR (predicted_delay IS NULL AND probability IS NULL AND predicted_hours IS NULL)),
  CHECK (probability IS NULL OR predicted_delay IS NOT NULL)
);

-- Consumo medido de IA y servicios.
CREATE TABLE nexus."usage_records" (
  "id" uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  "organization_id" uuid NOT NULL,
  "created_at" timestamptz NOT NULL DEFAULT now(),
  "membership_id" uuid,
  "service_code" text NOT NULL,
  "quantity" numeric(18,6) NOT NULL,
  "unit" text NOT NULL,
  "estimated_cost_usd" numeric(14,6),
  "provider_request_id" text,
  "occurred_at" timestamptz NOT NULL,
  UNIQUE (organization_id, id),
  CHECK (quantity >= 0),
  CHECK (estimated_cost_usd >= 0)
);

-- Catálogo de servicios empresariales.
CREATE TABLE nexus."services" (
  "id" uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  "organization_id" uuid NOT NULL,
  "created_at" timestamptz NOT NULL DEFAULT now(),
  "updated_at" timestamptz NOT NULL DEFAULT now(),
  "slug" text NOT NULL,
  "name" text NOT NULL,
  "description" text NOT NULL,
  "category" text NOT NULL,
  "status" text NOT NULL DEFAULT 'draft',
  "published_at" timestamptz,
  UNIQUE (organization_id, id),
  UNIQUE ("organization_id", "slug"),
  CHECK (status IN ('draft','published','archived'))
);

-- Plan comercial asociado a servicio.
CREATE TABLE nexus."plans" (
  "id" uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  "organization_id" uuid NOT NULL,
  "created_at" timestamptz NOT NULL DEFAULT now(),
  "updated_at" timestamptz NOT NULL DEFAULT now(),
  "service_id" uuid NOT NULL,
  "code" text NOT NULL,
  "name" text NOT NULL,
  "status" text NOT NULL DEFAULT 'draft',
  UNIQUE (organization_id, id),
  UNIQUE ("organization_id", "code"),
  CHECK (status IN ('draft','published','archived'))
);

-- Precios y condiciones versionados.
CREATE TABLE nexus."plan_versions" (
  "id" uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  "organization_id" uuid NOT NULL,
  "created_at" timestamptz NOT NULL DEFAULT now(),
  "updated_at" timestamptz NOT NULL DEFAULT now(),
  "plan_id" uuid NOT NULL,
  "revision" integer NOT NULL,
  "amount" numeric(14,2),
  "currency" char(3) NOT NULL DEFAULT 'PEN',
  "billing_cycle" text NOT NULL,
  "features" jsonb NOT NULL DEFAULT '[]'::jsonb,
  "terms" text,
  "valid_from" timestamptz,
  "valid_until" timestamptz,
  "status" text NOT NULL DEFAULT 'draft',
  "created_by" uuid NOT NULL,
  "approved_by" uuid,
  UNIQUE (organization_id, id),
  UNIQUE ("plan_id", "revision"),
  CHECK (revision > 0),
  CHECK (amount >= 0),
  CHECK (valid_until > valid_from),
  CHECK (approved_by <> created_by),
  CHECK (status IN ('draft','published','retired')),
  CHECK (status <> 'published' OR (approved_by IS NOT NULL AND valid_from IS NOT NULL)),
  CHECK (billing_cycle IN ('once','monthly','yearly','custom'))
);

-- Contactos comerciales privados.
CREATE TABLE nexus."leads" (
  "id" uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  "organization_id" uuid NOT NULL,
  "created_at" timestamptz NOT NULL DEFAULT now(),
  "updated_at" timestamptz NOT NULL DEFAULT now(),
  "name" text NOT NULL,
  "email" text NOT NULL,
  "company" text,
  "message" text,
  "consent_at" timestamptz,
  "status" text NOT NULL DEFAULT 'new',
  UNIQUE (organization_id, id),
  CHECK (status IN ('new','contacted','closed'))
);

-- Cotización privada con snapshot de condiciones.
CREATE TABLE nexus."quotes" (
  "id" uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  "organization_id" uuid NOT NULL,
  "created_at" timestamptz NOT NULL DEFAULT now(),
  "updated_at" timestamptz NOT NULL DEFAULT now(),
  "lead_id" uuid NOT NULL,
  "code" text NOT NULL,
  "created_by" uuid NOT NULL,
  "status" text NOT NULL DEFAULT 'draft',
  "currency" char(3) NOT NULL DEFAULT 'PEN',
  "valid_until" date,
  "subtotal" numeric(14,2) NOT NULL DEFAULT 0,
  "tax" numeric(14,2) NOT NULL DEFAULT 0,
  "total" numeric(14,2) NOT NULL DEFAULT 0,
  "version" integer NOT NULL DEFAULT 1,
  UNIQUE (organization_id, id),
  UNIQUE ("organization_id", "code"),
  CHECK (subtotal >= 0),
  CHECK (tax >= 0),
  CHECK (total = subtotal + tax),
  CHECK (version > 0),
  CHECK (status IN ('draft','sent','accepted','rejected','expired'))
);

-- Líneas de cotización con precio histórico.
CREATE TABLE nexus."quote_items" (
  "id" uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  "organization_id" uuid NOT NULL,
  "created_at" timestamptz NOT NULL DEFAULT now(),
  "updated_at" timestamptz NOT NULL DEFAULT now(),
  "quote_id" uuid NOT NULL,
  "plan_version_id" uuid,
  "name_snapshot" text NOT NULL,
  "quantity" numeric(12,3) NOT NULL,
  "unit_price" numeric(14,2) NOT NULL,
  "line_total" numeric(14,2) NOT NULL,
  UNIQUE (organization_id, id),
  CHECK (quantity > 0),
  CHECK (unit_price >= 0),
  CHECK (line_total = round(quantity * unit_price,2))
);

-- Bandeja personal de alertas.
CREATE TABLE nexus."notifications" (
  "id" uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  "organization_id" uuid NOT NULL,
  "created_at" timestamptz NOT NULL DEFAULT now(),
  "updated_at" timestamptz NOT NULL DEFAULT now(),
  "recipient_id" uuid NOT NULL,
  "kind" text NOT NULL,
  "title" text NOT NULL,
  "body" text,
  "target_path" text,
  "read_at" timestamptz,
  "archived_at" timestamptz,
  "dedupe_key" text NOT NULL,
  UNIQUE (organization_id, id),
  UNIQUE ("recipient_id", "dedupe_key")
);

-- Configuración de canales por tipo de alerta.
CREATE TABLE nexus."notification_preferences" (
  "id" uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  "organization_id" uuid NOT NULL,
  "created_at" timestamptz NOT NULL DEFAULT now(),
  "updated_at" timestamptz NOT NULL DEFAULT now(),
  "membership_id" uuid NOT NULL,
  "kind" text NOT NULL,
  "in_app" boolean NOT NULL DEFAULT true,
  "email" boolean NOT NULL DEFAULT false,
  "digest" text NOT NULL DEFAULT 'immediate',
  UNIQUE (organization_id, id),
  UNIQUE ("membership_id", "kind"),
  CHECK (digest IN ('immediate','daily','weekly','off'))
);

-- Auditoría append-only de operaciones sensibles.
CREATE TABLE nexus."audit_events" (
  "id" uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  "organization_id" uuid NOT NULL,
  "created_at" timestamptz NOT NULL DEFAULT now(),
  "actor_id" uuid,
  "project_id" uuid,
  "action" text NOT NULL,
  "resource_type" text NOT NULL,
  "resource_id" uuid,
  "changes" jsonb NOT NULL DEFAULT '{}'::jsonb,
  "correlation_id" uuid NOT NULL,
  "outcome" text NOT NULL,
  UNIQUE (organization_id, id),
  CHECK (outcome IN ('success','denied'))
);

-- Eventos transaccionales para publicación posterior.
CREATE TABLE nexus."outbox" (
  "id" uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  "organization_id" uuid NOT NULL,
  "created_at" timestamptz NOT NULL DEFAULT now(),
  "updated_at" timestamptz NOT NULL DEFAULT now(),
  "event_type" text NOT NULL,
  "aggregate_id" uuid NOT NULL,
  "payload" jsonb NOT NULL,
  "status" text NOT NULL DEFAULT 'pending',
  "attempts" integer NOT NULL DEFAULT 0,
  "available_at" timestamptz NOT NULL DEFAULT now(),
  "published_at" timestamptz,
  UNIQUE (organization_id, id),
  CHECK (attempts >= 0),
  CHECK (status IN ('pending','processing','published','failed'))
);

-- Cola durable para tareas asíncronas sin Redis obligatorio.
CREATE TABLE nexus."jobs" (
  "id" uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  "organization_id" uuid NOT NULL,
  "created_at" timestamptz NOT NULL DEFAULT now(),
  "updated_at" timestamptz NOT NULL DEFAULT now(),
  "job_type" text NOT NULL,
  "payload" jsonb NOT NULL,
  "status" text NOT NULL DEFAULT 'queued',
  "attempts" integer NOT NULL DEFAULT 0,
  "run_after" timestamptz NOT NULL DEFAULT now(),
  "lease_until" timestamptz,
  "last_error_code" text,
  "idempotency_key" text NOT NULL,
  UNIQUE (organization_id, id),
  UNIQUE ("organization_id", "job_type", "idempotency_key"),
  CHECK (attempts >= 0),
  CHECK (status IN ('queued','running','succeeded','failed','cancelled'))
);

-- Lotes de importación con procedencia.
CREATE TABLE nexus."import_batches" (
  "id" uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  "organization_id" uuid NOT NULL,
  "created_at" timestamptz NOT NULL DEFAULT now(),
  "updated_at" timestamptz NOT NULL DEFAULT now(),
  "file_id" uuid NOT NULL,
  "requested_by" uuid NOT NULL,
  "source_name" text NOT NULL,
  "source_hash" text NOT NULL,
  "status" text NOT NULL DEFAULT 'pending',
  "row_count" integer NOT NULL DEFAULT 0,
  "accepted_count" integer NOT NULL DEFAULT 0,
  "rejected_count" integer NOT NULL DEFAULT 0,
  UNIQUE (organization_id, id),
  UNIQUE ("organization_id", "source_name", "source_hash"),
  CHECK (row_count >= 0),
  CHECK (accepted_count >= 0),
  CHECK (rejected_count >= 0),
  CHECK (accepted_count + rejected_count <= row_count),
  CHECK (status IN ('pending','validated','importing','completed','failed','reverted'))
);

-- Trazabilidad de fila y errores de importación.
CREATE TABLE nexus."import_rows" (
  "id" uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  "organization_id" uuid NOT NULL,
  "created_at" timestamptz NOT NULL DEFAULT now(),
  "updated_at" timestamptz NOT NULL DEFAULT now(),
  "batch_id" uuid NOT NULL,
  "row_number" integer NOT NULL,
  "external_task_id" text NOT NULL,
  "source_data" jsonb NOT NULL,
  "card_id" uuid,
  "status" text NOT NULL DEFAULT 'pending',
  "error_code" text,
  UNIQUE (organization_id, id),
  UNIQUE ("batch_id", "row_number"),
  UNIQUE ("batch_id", "external_task_id"),
  CHECK (row_number > 0),
  CHECK (status IN ('pending','accepted','rejected'))
);

-- Registros históricos simulados sin cuentas Auth ni horas artificiales por usuario.
CREATE TABLE nexus."historical_task_facts" (
  "id" uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  "organization_id" uuid NOT NULL,
  "created_at" timestamptz NOT NULL DEFAULT now(),
  "updated_at" timestamptz NOT NULL DEFAULT now(),
  "batch_id" uuid NOT NULL,
  "external_task_id" text NOT NULL,
  "external_project_id" text NOT NULL,
  "project_name" text NOT NULL,
  "participant_name" text NOT NULL,
  "specialty" text NOT NULL,
  "task_type" text NOT NULL,
  "complexity" text NOT NULL,
  "priority" text NOT NULL,
  "dependency_count" integer NOT NULL,
  "estimated_minutes" integer NOT NULL,
  "actual_minutes" integer,
  "start_date" date,
  "due_date" date,
  "end_date" date,
  "source_status" text NOT NULL,
  "source_delay" boolean,
  UNIQUE (organization_id, id),
  UNIQUE ("batch_id", "external_task_id"),
  CHECK (estimated_minutes >= 0),
  CHECK (actual_minutes >= 0),
  CHECK (dependency_count >= 0)
);

-- Solicitudes de CSV, Excel y PDF.
CREATE TABLE nexus."export_jobs" (
  "id" uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  "organization_id" uuid NOT NULL,
  "created_at" timestamptz NOT NULL DEFAULT now(),
  "updated_at" timestamptz NOT NULL DEFAULT now(),
  "requested_by" uuid NOT NULL,
  "report_code" text NOT NULL,
  "filters" jsonb NOT NULL,
  "status" text NOT NULL DEFAULT 'queued',
  "file_id" uuid,
  "expires_at" timestamptz,
  UNIQUE (organization_id, id),
  CHECK (status IN ('queued','running','succeeded','failed','expired'))
);

-- Configuración técnica no secreta por integración.
CREATE TABLE nexus."integration_settings" (
  "id" uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  "organization_id" uuid NOT NULL,
  "created_at" timestamptz NOT NULL DEFAULT now(),
  "updated_at" timestamptz NOT NULL DEFAULT now(),
  "provider" text NOT NULL,
  "enabled" boolean NOT NULL DEFAULT false,
  "configuration" jsonb NOT NULL DEFAULT '{}'::jsonb,
  "secret_ref" text,
  "updated_by" uuid NOT NULL,
  "version" integer NOT NULL DEFAULT 1,
  UNIQUE (organization_id, id),
  UNIQUE ("organization_id", "provider"),
  CHECK (version > 0)
);

-- Límites de consumo internos.
CREATE TABLE nexus."quota_limits" (
  "id" uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  "organization_id" uuid NOT NULL,
  "created_at" timestamptz NOT NULL DEFAULT now(),
  "updated_at" timestamptz NOT NULL DEFAULT now(),
  "service_code" text NOT NULL,
  "period" text NOT NULL,
  "max_quantity" numeric(18,6),
  "max_estimated_usd" numeric(14,6),
  "enabled" boolean NOT NULL DEFAULT true,
  UNIQUE (organization_id, id),
  UNIQUE ("organization_id", "service_code", "period"),
  CHECK (max_quantity >= 0),
  CHECK (max_estimated_usd >= 0),
  CHECK (period IN ('day','month')),
  CHECK (num_nonnulls(max_quantity,max_estimated_usd) >= 1)
);

-- Prevención de operaciones duplicadas por reintento.
CREATE TABLE nexus."idempotency_keys" (
  "id" uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  "organization_id" uuid NOT NULL,
  "created_at" timestamptz NOT NULL DEFAULT now(),
  "updated_at" timestamptz NOT NULL DEFAULT now(),
  "membership_id" uuid NOT NULL,
  "operation" text NOT NULL,
  "key" text NOT NULL,
  "request_hash" text NOT NULL,
  "response_ref" uuid,
  "expires_at" timestamptz NOT NULL,
  UNIQUE (organization_id, id),
  UNIQUE ("membership_id", "operation", "key")
);

ALTER TABLE nexus."profiles" ADD CONSTRAINT "fk_profiles_1" FOREIGN KEY ("auth_user_id") REFERENCES auth.users ("id") ON DELETE RESTRICT;
ALTER TABLE nexus."memberships" ADD CONSTRAINT "fk_memberships_1" FOREIGN KEY ("organization_id") REFERENCES nexus."organizations" ("id") ON DELETE RESTRICT;
ALTER TABLE nexus."memberships" ADD CONSTRAINT "fk_memberships_2" FOREIGN KEY ("profile_id") REFERENCES nexus."profiles" ("id") ON DELETE RESTRICT;
ALTER TABLE nexus."roles" ADD CONSTRAINT "fk_roles_1" FOREIGN KEY ("organization_id") REFERENCES nexus."organizations" ("id") ON DELETE RESTRICT;
ALTER TABLE nexus."role_permissions" ADD CONSTRAINT "fk_role_permissions_1" FOREIGN KEY ("organization_id") REFERENCES nexus."organizations" ("id") ON DELETE RESTRICT;
ALTER TABLE nexus."role_permissions" ADD CONSTRAINT "fk_role_permissions_2" FOREIGN KEY ("organization_id", "role_id") REFERENCES nexus."roles" ("organization_id", "id") ON DELETE RESTRICT;
ALTER TABLE nexus."role_permissions" ADD CONSTRAINT "fk_role_permissions_3" FOREIGN KEY ("permission_id") REFERENCES nexus."permissions" ("id") ON DELETE RESTRICT;
ALTER TABLE nexus."role_grants" ADD CONSTRAINT "fk_role_grants_1" FOREIGN KEY ("organization_id") REFERENCES nexus."organizations" ("id") ON DELETE RESTRICT;
ALTER TABLE nexus."role_grants" ADD CONSTRAINT "fk_role_grants_2" FOREIGN KEY ("organization_id", "membership_id") REFERENCES nexus."memberships" ("organization_id", "id") ON DELETE RESTRICT;
ALTER TABLE nexus."role_grants" ADD CONSTRAINT "fk_role_grants_3" FOREIGN KEY ("organization_id", "role_id") REFERENCES nexus."roles" ("organization_id", "id") ON DELETE RESTRICT;
ALTER TABLE nexus."role_grants" ADD CONSTRAINT "fk_role_grants_4" FOREIGN KEY ("organization_id", "project_id") REFERENCES nexus."projects" ("organization_id", "id") ON DELETE RESTRICT;
ALTER TABLE nexus."role_grants" ADD CONSTRAINT "fk_role_grants_5" FOREIGN KEY ("organization_id", "granted_by") REFERENCES nexus."memberships" ("organization_id", "id") ON DELETE RESTRICT;
ALTER TABLE nexus."invitations" ADD CONSTRAINT "fk_invitations_1" FOREIGN KEY ("organization_id") REFERENCES nexus."organizations" ("id") ON DELETE RESTRICT;
ALTER TABLE nexus."invitations" ADD CONSTRAINT "fk_invitations_2" FOREIGN KEY ("organization_id", "invited_by") REFERENCES nexus."memberships" ("organization_id", "id") ON DELETE RESTRICT;
ALTER TABLE nexus."invitations" ADD CONSTRAINT "fk_invitations_3" FOREIGN KEY ("organization_id", "role_id") REFERENCES nexus."roles" ("organization_id", "id") ON DELETE RESTRICT;
ALTER TABLE nexus."user_preferences" ADD CONSTRAINT "fk_user_preferences_1" FOREIGN KEY ("organization_id") REFERENCES nexus."organizations" ("id") ON DELETE RESTRICT;
ALTER TABLE nexus."user_preferences" ADD CONSTRAINT "fk_user_preferences_2" FOREIGN KEY ("organization_id", "membership_id") REFERENCES nexus."memberships" ("organization_id", "id") ON DELETE RESTRICT;
ALTER TABLE nexus."organization_settings" ADD CONSTRAINT "fk_organization_settings_1" FOREIGN KEY ("organization_id") REFERENCES nexus."organizations" ("id") ON DELETE RESTRICT;
ALTER TABLE nexus."organization_settings" ADD CONSTRAINT "fk_organization_settings_2" FOREIGN KEY ("organization_id", "updated_by") REFERENCES nexus."memberships" ("organization_id", "id") ON DELETE RESTRICT;
ALTER TABLE nexus."teams" ADD CONSTRAINT "fk_teams_1" FOREIGN KEY ("organization_id") REFERENCES nexus."organizations" ("id") ON DELETE RESTRICT;
ALTER TABLE nexus."team_members" ADD CONSTRAINT "fk_team_members_1" FOREIGN KEY ("organization_id") REFERENCES nexus."organizations" ("id") ON DELETE RESTRICT;
ALTER TABLE nexus."team_members" ADD CONSTRAINT "fk_team_members_2" FOREIGN KEY ("organization_id", "team_id") REFERENCES nexus."teams" ("organization_id", "id") ON DELETE RESTRICT;
ALTER TABLE nexus."team_members" ADD CONSTRAINT "fk_team_members_3" FOREIGN KEY ("organization_id", "membership_id") REFERENCES nexus."memberships" ("organization_id", "id") ON DELETE RESTRICT;
ALTER TABLE nexus."availability" ADD CONSTRAINT "fk_availability_1" FOREIGN KEY ("organization_id") REFERENCES nexus."organizations" ("id") ON DELETE RESTRICT;
ALTER TABLE nexus."availability" ADD CONSTRAINT "fk_availability_2" FOREIGN KEY ("organization_id", "membership_id") REFERENCES nexus."memberships" ("organization_id", "id") ON DELETE RESTRICT;
ALTER TABLE nexus."projects" ADD CONSTRAINT "fk_projects_1" FOREIGN KEY ("organization_id") REFERENCES nexus."organizations" ("id") ON DELETE RESTRICT;
ALTER TABLE nexus."projects" ADD CONSTRAINT "fk_projects_2" FOREIGN KEY ("organization_id", "created_by") REFERENCES nexus."memberships" ("organization_id", "id") ON DELETE RESTRICT;
ALTER TABLE nexus."project_members" ADD CONSTRAINT "fk_project_members_1" FOREIGN KEY ("organization_id") REFERENCES nexus."organizations" ("id") ON DELETE RESTRICT;
ALTER TABLE nexus."project_members" ADD CONSTRAINT "fk_project_members_2" FOREIGN KEY ("organization_id", "project_id") REFERENCES nexus."projects" ("organization_id", "id") ON DELETE RESTRICT;
ALTER TABLE nexus."project_members" ADD CONSTRAINT "fk_project_members_3" FOREIGN KEY ("organization_id", "membership_id") REFERENCES nexus."memberships" ("organization_id", "id") ON DELETE RESTRICT;
ALTER TABLE nexus."project_members" ADD CONSTRAINT "fk_project_members_4" FOREIGN KEY ("organization_id", "team_id") REFERENCES nexus."teams" ("organization_id", "id") ON DELETE RESTRICT;
ALTER TABLE nexus."milestones" ADD CONSTRAINT "fk_milestones_1" FOREIGN KEY ("organization_id") REFERENCES nexus."organizations" ("id") ON DELETE RESTRICT;
ALTER TABLE nexus."milestones" ADD CONSTRAINT "fk_milestones_2" FOREIGN KEY ("organization_id", "project_id") REFERENCES nexus."projects" ("organization_id", "id") ON DELETE RESTRICT;
ALTER TABLE nexus."boards" ADD CONSTRAINT "fk_boards_1" FOREIGN KEY ("organization_id") REFERENCES nexus."organizations" ("id") ON DELETE RESTRICT;
ALTER TABLE nexus."boards" ADD CONSTRAINT "fk_boards_2" FOREIGN KEY ("organization_id", "project_id") REFERENCES nexus."projects" ("organization_id", "id") ON DELETE RESTRICT;
ALTER TABLE nexus."board_columns" ADD CONSTRAINT "fk_board_columns_1" FOREIGN KEY ("organization_id") REFERENCES nexus."organizations" ("id") ON DELETE RESTRICT;
ALTER TABLE nexus."board_columns" ADD CONSTRAINT "fk_board_columns_2" FOREIGN KEY ("organization_id", "project_id") REFERENCES nexus."projects" ("organization_id", "id") ON DELETE RESTRICT;
ALTER TABLE nexus."board_columns" ADD CONSTRAINT "fk_board_columns_3" FOREIGN KEY ("organization_id", "project_id", "board_id") REFERENCES nexus."boards" ("organization_id", "project_id", "id") ON DELETE RESTRICT;
ALTER TABLE nexus."cards" ADD CONSTRAINT "fk_cards_1" FOREIGN KEY ("organization_id") REFERENCES nexus."organizations" ("id") ON DELETE RESTRICT;
ALTER TABLE nexus."cards" ADD CONSTRAINT "fk_cards_2" FOREIGN KEY ("organization_id", "project_id") REFERENCES nexus."projects" ("organization_id", "id") ON DELETE RESTRICT;
ALTER TABLE nexus."cards" ADD CONSTRAINT "fk_cards_3" FOREIGN KEY ("organization_id", "project_id", "board_id") REFERENCES nexus."boards" ("organization_id", "project_id", "id") ON DELETE RESTRICT;
ALTER TABLE nexus."cards" ADD CONSTRAINT "fk_cards_4" FOREIGN KEY ("organization_id", "project_id", "column_id") REFERENCES nexus."board_columns" ("organization_id", "project_id", "id") ON DELETE RESTRICT;
ALTER TABLE nexus."cards" ADD CONSTRAINT "fk_cards_5" FOREIGN KEY ("organization_id", "project_id", "parent_card_id") REFERENCES nexus."cards" ("organization_id", "project_id", "id") ON DELETE RESTRICT;
ALTER TABLE nexus."cards" ADD CONSTRAINT "fk_cards_6" FOREIGN KEY ("organization_id", "project_id", "milestone_id") REFERENCES nexus."milestones" ("organization_id", "project_id", "id") ON DELETE RESTRICT;
ALTER TABLE nexus."cards" ADD CONSTRAINT "fk_cards_7" FOREIGN KEY ("organization_id", "created_by") REFERENCES nexus."memberships" ("organization_id", "id") ON DELETE RESTRICT;
ALTER TABLE nexus."cards" ADD CONSTRAINT "fk_cards_8" FOREIGN KEY ("organization_id", "project_id", "board_id", "column_id") REFERENCES nexus."board_columns" ("organization_id", "project_id", "board_id", "id") ON DELETE RESTRICT;
ALTER TABLE nexus."card_assignees" ADD CONSTRAINT "fk_card_assignees_1" FOREIGN KEY ("organization_id") REFERENCES nexus."organizations" ("id") ON DELETE RESTRICT;
ALTER TABLE nexus."card_assignees" ADD CONSTRAINT "fk_card_assignees_2" FOREIGN KEY ("organization_id", "project_id") REFERENCES nexus."projects" ("organization_id", "id") ON DELETE RESTRICT;
ALTER TABLE nexus."card_assignees" ADD CONSTRAINT "fk_card_assignees_3" FOREIGN KEY ("organization_id", "project_id", "card_id") REFERENCES nexus."cards" ("organization_id", "project_id", "id") ON DELETE RESTRICT;
ALTER TABLE nexus."card_assignees" ADD CONSTRAINT "fk_card_assignees_4" FOREIGN KEY ("organization_id", "membership_id") REFERENCES nexus."memberships" ("organization_id", "id") ON DELETE RESTRICT;
ALTER TABLE nexus."card_assignees" ADD CONSTRAINT "fk_card_assignees_5" FOREIGN KEY ("organization_id", "assigned_by") REFERENCES nexus."memberships" ("organization_id", "id") ON DELETE RESTRICT;
ALTER TABLE nexus."card_assignees" ADD CONSTRAINT "fk_card_assignees_6" FOREIGN KEY ("organization_id", "project_id", "membership_id") REFERENCES nexus."project_members" ("organization_id", "project_id", "membership_id") ON DELETE RESTRICT;
ALTER TABLE nexus."labels" ADD CONSTRAINT "fk_labels_1" FOREIGN KEY ("organization_id") REFERENCES nexus."organizations" ("id") ON DELETE RESTRICT;
ALTER TABLE nexus."labels" ADD CONSTRAINT "fk_labels_2" FOREIGN KEY ("organization_id", "project_id") REFERENCES nexus."projects" ("organization_id", "id") ON DELETE RESTRICT;
ALTER TABLE nexus."card_labels" ADD CONSTRAINT "fk_card_labels_1" FOREIGN KEY ("organization_id") REFERENCES nexus."organizations" ("id") ON DELETE RESTRICT;
ALTER TABLE nexus."card_labels" ADD CONSTRAINT "fk_card_labels_2" FOREIGN KEY ("organization_id", "project_id") REFERENCES nexus."projects" ("organization_id", "id") ON DELETE RESTRICT;
ALTER TABLE nexus."card_labels" ADD CONSTRAINT "fk_card_labels_3" FOREIGN KEY ("organization_id", "project_id", "card_id") REFERENCES nexus."cards" ("organization_id", "project_id", "id") ON DELETE RESTRICT;
ALTER TABLE nexus."card_labels" ADD CONSTRAINT "fk_card_labels_4" FOREIGN KEY ("organization_id", "label_id") REFERENCES nexus."labels" ("organization_id", "id") ON DELETE RESTRICT;
ALTER TABLE nexus."field_definitions" ADD CONSTRAINT "fk_field_definitions_1" FOREIGN KEY ("organization_id") REFERENCES nexus."organizations" ("id") ON DELETE RESTRICT;
ALTER TABLE nexus."field_definitions" ADD CONSTRAINT "fk_field_definitions_2" FOREIGN KEY ("organization_id", "project_id") REFERENCES nexus."projects" ("organization_id", "id") ON DELETE RESTRICT;
ALTER TABLE nexus."field_definitions" ADD CONSTRAINT "fk_field_definitions_3" FOREIGN KEY ("organization_id", "project_id", "board_id") REFERENCES nexus."boards" ("organization_id", "project_id", "id") ON DELETE RESTRICT;
ALTER TABLE nexus."field_values" ADD CONSTRAINT "fk_field_values_1" FOREIGN KEY ("organization_id") REFERENCES nexus."organizations" ("id") ON DELETE RESTRICT;
ALTER TABLE nexus."field_values" ADD CONSTRAINT "fk_field_values_2" FOREIGN KEY ("organization_id", "project_id") REFERENCES nexus."projects" ("organization_id", "id") ON DELETE RESTRICT;
ALTER TABLE nexus."field_values" ADD CONSTRAINT "fk_field_values_3" FOREIGN KEY ("organization_id", "project_id", "card_id") REFERENCES nexus."cards" ("organization_id", "project_id", "id") ON DELETE RESTRICT;
ALTER TABLE nexus."field_values" ADD CONSTRAINT "fk_field_values_4" FOREIGN KEY ("organization_id", "project_id", "field_definition_id") REFERENCES nexus."field_definitions" ("organization_id", "project_id", "id") ON DELETE RESTRICT;
ALTER TABLE nexus."checklists" ADD CONSTRAINT "fk_checklists_1" FOREIGN KEY ("organization_id") REFERENCES nexus."organizations" ("id") ON DELETE RESTRICT;
ALTER TABLE nexus."checklists" ADD CONSTRAINT "fk_checklists_2" FOREIGN KEY ("organization_id", "project_id") REFERENCES nexus."projects" ("organization_id", "id") ON DELETE RESTRICT;
ALTER TABLE nexus."checklists" ADD CONSTRAINT "fk_checklists_3" FOREIGN KEY ("organization_id", "project_id", "card_id") REFERENCES nexus."cards" ("organization_id", "project_id", "id") ON DELETE RESTRICT;
ALTER TABLE nexus."checklist_items" ADD CONSTRAINT "fk_checklist_items_1" FOREIGN KEY ("organization_id") REFERENCES nexus."organizations" ("id") ON DELETE RESTRICT;
ALTER TABLE nexus."checklist_items" ADD CONSTRAINT "fk_checklist_items_2" FOREIGN KEY ("organization_id", "project_id") REFERENCES nexus."projects" ("organization_id", "id") ON DELETE RESTRICT;
ALTER TABLE nexus."checklist_items" ADD CONSTRAINT "fk_checklist_items_3" FOREIGN KEY ("organization_id", "project_id", "checklist_id") REFERENCES nexus."checklists" ("organization_id", "project_id", "id") ON DELETE RESTRICT;
ALTER TABLE nexus."checklist_items" ADD CONSTRAINT "fk_checklist_items_4" FOREIGN KEY ("organization_id", "assignee_id") REFERENCES nexus."memberships" ("organization_id", "id") ON DELETE RESTRICT;
ALTER TABLE nexus."checklist_items" ADD CONSTRAINT "fk_checklist_items_5" FOREIGN KEY ("organization_id", "completed_by") REFERENCES nexus."memberships" ("organization_id", "id") ON DELETE RESTRICT;
ALTER TABLE nexus."checklist_items" ADD CONSTRAINT "fk_checklist_items_6" FOREIGN KEY ("organization_id", "project_id", "assignee_id") REFERENCES nexus."project_members" ("organization_id", "project_id", "membership_id") ON DELETE RESTRICT;
ALTER TABLE nexus."card_dependencies" ADD CONSTRAINT "fk_card_dependencies_1" FOREIGN KEY ("organization_id") REFERENCES nexus."organizations" ("id") ON DELETE RESTRICT;
ALTER TABLE nexus."card_dependencies" ADD CONSTRAINT "fk_card_dependencies_2" FOREIGN KEY ("organization_id", "project_id") REFERENCES nexus."projects" ("organization_id", "id") ON DELETE RESTRICT;
ALTER TABLE nexus."card_dependencies" ADD CONSTRAINT "fk_card_dependencies_3" FOREIGN KEY ("organization_id", "project_id", "card_id") REFERENCES nexus."cards" ("organization_id", "project_id", "id") ON DELETE RESTRICT;
ALTER TABLE nexus."card_dependencies" ADD CONSTRAINT "fk_card_dependencies_4" FOREIGN KEY ("organization_id", "project_id", "prerequisite_id") REFERENCES nexus."cards" ("organization_id", "project_id", "id") ON DELETE RESTRICT;
ALTER TABLE nexus."comments" ADD CONSTRAINT "fk_comments_1" FOREIGN KEY ("organization_id") REFERENCES nexus."organizations" ("id") ON DELETE RESTRICT;
ALTER TABLE nexus."comments" ADD CONSTRAINT "fk_comments_2" FOREIGN KEY ("organization_id", "project_id") REFERENCES nexus."projects" ("organization_id", "id") ON DELETE RESTRICT;
ALTER TABLE nexus."comments" ADD CONSTRAINT "fk_comments_3" FOREIGN KEY ("organization_id", "project_id", "card_id") REFERENCES nexus."cards" ("organization_id", "project_id", "id") ON DELETE RESTRICT;
ALTER TABLE nexus."comments" ADD CONSTRAINT "fk_comments_4" FOREIGN KEY ("organization_id", "project_id", "parent_comment_id") REFERENCES nexus."comments" ("organization_id", "project_id", "id") ON DELETE RESTRICT;
ALTER TABLE nexus."comments" ADD CONSTRAINT "fk_comments_5" FOREIGN KEY ("organization_id", "author_id") REFERENCES nexus."memberships" ("organization_id", "id") ON DELETE RESTRICT;
ALTER TABLE nexus."comments" ADD CONSTRAINT "fk_comments_6" FOREIGN KEY ("organization_id", "project_id", "card_id", "parent_comment_id") REFERENCES nexus."comments" ("organization_id", "project_id", "card_id", "id") ON DELETE RESTRICT;
ALTER TABLE nexus."comment_mentions" ADD CONSTRAINT "fk_comment_mentions_1" FOREIGN KEY ("organization_id") REFERENCES nexus."organizations" ("id") ON DELETE RESTRICT;
ALTER TABLE nexus."comment_mentions" ADD CONSTRAINT "fk_comment_mentions_2" FOREIGN KEY ("organization_id", "project_id") REFERENCES nexus."projects" ("organization_id", "id") ON DELETE RESTRICT;
ALTER TABLE nexus."comment_mentions" ADD CONSTRAINT "fk_comment_mentions_3" FOREIGN KEY ("organization_id", "project_id", "comment_id") REFERENCES nexus."comments" ("organization_id", "project_id", "id") ON DELETE RESTRICT;
ALTER TABLE nexus."comment_mentions" ADD CONSTRAINT "fk_comment_mentions_4" FOREIGN KEY ("organization_id", "membership_id") REFERENCES nexus."memberships" ("organization_id", "id") ON DELETE RESTRICT;
ALTER TABLE nexus."comment_reactions" ADD CONSTRAINT "fk_comment_reactions_1" FOREIGN KEY ("organization_id") REFERENCES nexus."organizations" ("id") ON DELETE RESTRICT;
ALTER TABLE nexus."comment_reactions" ADD CONSTRAINT "fk_comment_reactions_2" FOREIGN KEY ("organization_id", "project_id") REFERENCES nexus."projects" ("organization_id", "id") ON DELETE RESTRICT;
ALTER TABLE nexus."comment_reactions" ADD CONSTRAINT "fk_comment_reactions_3" FOREIGN KEY ("organization_id", "project_id", "comment_id") REFERENCES nexus."comments" ("organization_id", "project_id", "id") ON DELETE RESTRICT;
ALTER TABLE nexus."comment_reactions" ADD CONSTRAINT "fk_comment_reactions_4" FOREIGN KEY ("organization_id", "membership_id") REFERENCES nexus."memberships" ("organization_id", "id") ON DELETE RESTRICT;
ALTER TABLE nexus."files" ADD CONSTRAINT "fk_files_1" FOREIGN KEY ("organization_id") REFERENCES nexus."organizations" ("id") ON DELETE RESTRICT;
ALTER TABLE nexus."files" ADD CONSTRAINT "fk_files_2" FOREIGN KEY ("organization_id", "uploaded_by") REFERENCES nexus."memberships" ("organization_id", "id") ON DELETE RESTRICT;
ALTER TABLE nexus."attachments" ADD CONSTRAINT "fk_attachments_1" FOREIGN KEY ("organization_id") REFERENCES nexus."organizations" ("id") ON DELETE RESTRICT;
ALTER TABLE nexus."attachments" ADD CONSTRAINT "fk_attachments_2" FOREIGN KEY ("organization_id", "project_id") REFERENCES nexus."projects" ("organization_id", "id") ON DELETE RESTRICT;
ALTER TABLE nexus."attachments" ADD CONSTRAINT "fk_attachments_3" FOREIGN KEY ("organization_id", "project_id", "card_id") REFERENCES nexus."cards" ("organization_id", "project_id", "id") ON DELETE RESTRICT;
ALTER TABLE nexus."attachments" ADD CONSTRAINT "fk_attachments_4" FOREIGN KEY ("organization_id", "file_id") REFERENCES nexus."files" ("organization_id", "id") ON DELETE RESTRICT;
ALTER TABLE nexus."attachments" ADD CONSTRAINT "fk_attachments_5" FOREIGN KEY ("organization_id", "added_by") REFERENCES nexus."memberships" ("organization_id", "id") ON DELETE RESTRICT;
ALTER TABLE nexus."card_watchers" ADD CONSTRAINT "fk_card_watchers_1" FOREIGN KEY ("organization_id") REFERENCES nexus."organizations" ("id") ON DELETE RESTRICT;
ALTER TABLE nexus."card_watchers" ADD CONSTRAINT "fk_card_watchers_2" FOREIGN KEY ("organization_id", "project_id") REFERENCES nexus."projects" ("organization_id", "id") ON DELETE RESTRICT;
ALTER TABLE nexus."card_watchers" ADD CONSTRAINT "fk_card_watchers_3" FOREIGN KEY ("organization_id", "project_id", "card_id") REFERENCES nexus."cards" ("organization_id", "project_id", "id") ON DELETE RESTRICT;
ALTER TABLE nexus."card_watchers" ADD CONSTRAINT "fk_card_watchers_4" FOREIGN KEY ("organization_id", "membership_id") REFERENCES nexus."memberships" ("organization_id", "id") ON DELETE RESTRICT;
ALTER TABLE nexus."card_events" ADD CONSTRAINT "fk_card_events_1" FOREIGN KEY ("organization_id") REFERENCES nexus."organizations" ("id") ON DELETE RESTRICT;
ALTER TABLE nexus."card_events" ADD CONSTRAINT "fk_card_events_2" FOREIGN KEY ("organization_id", "project_id") REFERENCES nexus."projects" ("organization_id", "id") ON DELETE RESTRICT;
ALTER TABLE nexus."card_events" ADD CONSTRAINT "fk_card_events_3" FOREIGN KEY ("organization_id", "project_id", "card_id") REFERENCES nexus."cards" ("organization_id", "project_id", "id") ON DELETE RESTRICT;
ALTER TABLE nexus."card_events" ADD CONSTRAINT "fk_card_events_4" FOREIGN KEY ("organization_id", "actor_id") REFERENCES nexus."memberships" ("organization_id", "id") ON DELETE RESTRICT;
ALTER TABLE nexus."timers" ADD CONSTRAINT "fk_timers_1" FOREIGN KEY ("organization_id") REFERENCES nexus."organizations" ("id") ON DELETE RESTRICT;
ALTER TABLE nexus."timers" ADD CONSTRAINT "fk_timers_2" FOREIGN KEY ("organization_id", "project_id") REFERENCES nexus."projects" ("organization_id", "id") ON DELETE RESTRICT;
ALTER TABLE nexus."timers" ADD CONSTRAINT "fk_timers_3" FOREIGN KEY ("organization_id", "project_id", "card_id") REFERENCES nexus."cards" ("organization_id", "project_id", "id") ON DELETE RESTRICT;
ALTER TABLE nexus."timers" ADD CONSTRAINT "fk_timers_4" FOREIGN KEY ("organization_id", "membership_id") REFERENCES nexus."memberships" ("organization_id", "id") ON DELETE RESTRICT;
ALTER TABLE nexus."time_entries" ADD CONSTRAINT "fk_time_entries_1" FOREIGN KEY ("organization_id") REFERENCES nexus."organizations" ("id") ON DELETE RESTRICT;
ALTER TABLE nexus."time_entries" ADD CONSTRAINT "fk_time_entries_2" FOREIGN KEY ("organization_id", "project_id") REFERENCES nexus."projects" ("organization_id", "id") ON DELETE RESTRICT;
ALTER TABLE nexus."time_entries" ADD CONSTRAINT "fk_time_entries_3" FOREIGN KEY ("organization_id", "project_id", "card_id") REFERENCES nexus."cards" ("organization_id", "project_id", "id") ON DELETE RESTRICT;
ALTER TABLE nexus."time_entries" ADD CONSTRAINT "fk_time_entries_4" FOREIGN KEY ("organization_id", "membership_id") REFERENCES nexus."memberships" ("organization_id", "id") ON DELETE RESTRICT;
ALTER TABLE nexus."time_entries" ADD CONSTRAINT "fk_time_entries_5" FOREIGN KEY ("organization_id", "project_id", "timer_id") REFERENCES nexus."timers" ("organization_id", "project_id", "id") ON DELETE RESTRICT;
ALTER TABLE nexus."time_entries" ADD CONSTRAINT "fk_time_entries_6" FOREIGN KEY ("organization_id", "project_id", "card_id", "membership_id", "timer_id") REFERENCES nexus."timers" ("organization_id", "project_id", "card_id", "membership_id", "id") ON DELETE RESTRICT;
ALTER TABLE nexus."time_entry_versions" ADD CONSTRAINT "fk_time_entry_versions_1" FOREIGN KEY ("organization_id") REFERENCES nexus."organizations" ("id") ON DELETE RESTRICT;
ALTER TABLE nexus."time_entry_versions" ADD CONSTRAINT "fk_time_entry_versions_2" FOREIGN KEY ("organization_id", "project_id") REFERENCES nexus."projects" ("organization_id", "id") ON DELETE RESTRICT;
ALTER TABLE nexus."time_entry_versions" ADD CONSTRAINT "fk_time_entry_versions_3" FOREIGN KEY ("organization_id", "project_id", "time_entry_id") REFERENCES nexus."time_entries" ("organization_id", "project_id", "id") ON DELETE RESTRICT;
ALTER TABLE nexus."time_entry_versions" ADD CONSTRAINT "fk_time_entry_versions_4" FOREIGN KEY ("organization_id", "actor_id") REFERENCES nexus."memberships" ("organization_id", "id") ON DELETE RESTRICT;
ALTER TABLE nexus."approvals" ADD CONSTRAINT "fk_approvals_1" FOREIGN KEY ("organization_id") REFERENCES nexus."organizations" ("id") ON DELETE RESTRICT;
ALTER TABLE nexus."approvals" ADD CONSTRAINT "fk_approvals_2" FOREIGN KEY ("organization_id", "project_id") REFERENCES nexus."projects" ("organization_id", "id") ON DELETE RESTRICT;
ALTER TABLE nexus."approvals" ADD CONSTRAINT "fk_approvals_3" FOREIGN KEY ("organization_id", "project_id", "time_entry_id") REFERENCES nexus."time_entries" ("organization_id", "project_id", "id") ON DELETE RESTRICT;
ALTER TABLE nexus."approvals" ADD CONSTRAINT "fk_approvals_4" FOREIGN KEY ("organization_id", "project_id", "card_id") REFERENCES nexus."cards" ("organization_id", "project_id", "id") ON DELETE RESTRICT;
ALTER TABLE nexus."approvals" ADD CONSTRAINT "fk_approvals_5" FOREIGN KEY ("organization_id", "requested_by") REFERENCES nexus."memberships" ("organization_id", "id") ON DELETE RESTRICT;
ALTER TABLE nexus."approvals" ADD CONSTRAINT "fk_approvals_6" FOREIGN KEY ("organization_id", "reviewed_by") REFERENCES nexus."memberships" ("organization_id", "id") ON DELETE RESTRICT;
ALTER TABLE nexus."calendar_events" ADD CONSTRAINT "fk_calendar_events_1" FOREIGN KEY ("organization_id") REFERENCES nexus."organizations" ("id") ON DELETE RESTRICT;
ALTER TABLE nexus."calendar_events" ADD CONSTRAINT "fk_calendar_events_2" FOREIGN KEY ("organization_id", "project_id") REFERENCES nexus."projects" ("organization_id", "id") ON DELETE RESTRICT;
ALTER TABLE nexus."calendar_events" ADD CONSTRAINT "fk_calendar_events_3" FOREIGN KEY ("organization_id", "owner_id") REFERENCES nexus."memberships" ("organization_id", "id") ON DELETE RESTRICT;
ALTER TABLE nexus."calendar_attendees" ADD CONSTRAINT "fk_calendar_attendees_1" FOREIGN KEY ("organization_id") REFERENCES nexus."organizations" ("id") ON DELETE RESTRICT;
ALTER TABLE nexus."calendar_attendees" ADD CONSTRAINT "fk_calendar_attendees_2" FOREIGN KEY ("organization_id", "event_id") REFERENCES nexus."calendar_events" ("organization_id", "id") ON DELETE RESTRICT;
ALTER TABLE nexus."calendar_attendees" ADD CONSTRAINT "fk_calendar_attendees_3" FOREIGN KEY ("organization_id", "membership_id") REFERENCES nexus."memberships" ("organization_id", "id") ON DELETE RESTRICT;
ALTER TABLE nexus."tickets" ADD CONSTRAINT "fk_tickets_1" FOREIGN KEY ("organization_id") REFERENCES nexus."organizations" ("id") ON DELETE RESTRICT;
ALTER TABLE nexus."tickets" ADD CONSTRAINT "fk_tickets_2" FOREIGN KEY ("organization_id", "project_id") REFERENCES nexus."projects" ("organization_id", "id") ON DELETE RESTRICT;
ALTER TABLE nexus."tickets" ADD CONSTRAINT "fk_tickets_3" FOREIGN KEY ("organization_id", "reporter_id") REFERENCES nexus."memberships" ("organization_id", "id") ON DELETE RESTRICT;
ALTER TABLE nexus."tickets" ADD CONSTRAINT "fk_tickets_4" FOREIGN KEY ("organization_id", "assignee_id") REFERENCES nexus."memberships" ("organization_id", "id") ON DELETE RESTRICT;
ALTER TABLE nexus."ticket_comments" ADD CONSTRAINT "fk_ticket_comments_1" FOREIGN KEY ("organization_id") REFERENCES nexus."organizations" ("id") ON DELETE RESTRICT;
ALTER TABLE nexus."ticket_comments" ADD CONSTRAINT "fk_ticket_comments_2" FOREIGN KEY ("organization_id", "ticket_id") REFERENCES nexus."tickets" ("organization_id", "id") ON DELETE RESTRICT;
ALTER TABLE nexus."ticket_comments" ADD CONSTRAINT "fk_ticket_comments_3" FOREIGN KEY ("organization_id", "author_id") REFERENCES nexus."memberships" ("organization_id", "id") ON DELETE RESTRICT;
ALTER TABLE nexus."ticket_links" ADD CONSTRAINT "fk_ticket_links_1" FOREIGN KEY ("organization_id") REFERENCES nexus."organizations" ("id") ON DELETE RESTRICT;
ALTER TABLE nexus."ticket_links" ADD CONSTRAINT "fk_ticket_links_2" FOREIGN KEY ("organization_id", "project_id") REFERENCES nexus."projects" ("organization_id", "id") ON DELETE RESTRICT;
ALTER TABLE nexus."ticket_links" ADD CONSTRAINT "fk_ticket_links_3" FOREIGN KEY ("organization_id", "ticket_id") REFERENCES nexus."tickets" ("organization_id", "id") ON DELETE RESTRICT;
ALTER TABLE nexus."ticket_links" ADD CONSTRAINT "fk_ticket_links_4" FOREIGN KEY ("organization_id", "project_id", "card_id") REFERENCES nexus."cards" ("organization_id", "project_id", "id") ON DELETE RESTRICT;
ALTER TABLE nexus."card_templates" ADD CONSTRAINT "fk_card_templates_1" FOREIGN KEY ("organization_id") REFERENCES nexus."organizations" ("id") ON DELETE RESTRICT;
ALTER TABLE nexus."card_templates" ADD CONSTRAINT "fk_card_templates_2" FOREIGN KEY ("organization_id", "project_id") REFERENCES nexus."projects" ("organization_id", "id") ON DELETE RESTRICT;
ALTER TABLE nexus."card_templates" ADD CONSTRAINT "fk_card_templates_3" FOREIGN KEY ("organization_id", "created_by") REFERENCES nexus."memberships" ("organization_id", "id") ON DELETE RESTRICT;
ALTER TABLE nexus."automation_rules" ADD CONSTRAINT "fk_automation_rules_1" FOREIGN KEY ("organization_id") REFERENCES nexus."organizations" ("id") ON DELETE RESTRICT;
ALTER TABLE nexus."automation_rules" ADD CONSTRAINT "fk_automation_rules_2" FOREIGN KEY ("organization_id", "project_id") REFERENCES nexus."projects" ("organization_id", "id") ON DELETE RESTRICT;
ALTER TABLE nexus."automation_rules" ADD CONSTRAINT "fk_automation_rules_3" FOREIGN KEY ("organization_id", "created_by") REFERENCES nexus."memberships" ("organization_id", "id") ON DELETE RESTRICT;
ALTER TABLE nexus."automation_runs" ADD CONSTRAINT "fk_automation_runs_1" FOREIGN KEY ("organization_id") REFERENCES nexus."organizations" ("id") ON DELETE RESTRICT;
ALTER TABLE nexus."automation_runs" ADD CONSTRAINT "fk_automation_runs_2" FOREIGN KEY ("organization_id", "project_id") REFERENCES nexus."projects" ("organization_id", "id") ON DELETE RESTRICT;
ALTER TABLE nexus."automation_runs" ADD CONSTRAINT "fk_automation_runs_3" FOREIGN KEY ("organization_id", "project_id", "rule_id") REFERENCES nexus."automation_rules" ("organization_id", "project_id", "id") ON DELETE RESTRICT;
ALTER TABLE nexus."documents" ADD CONSTRAINT "fk_documents_1" FOREIGN KEY ("organization_id") REFERENCES nexus."organizations" ("id") ON DELETE RESTRICT;
ALTER TABLE nexus."documents" ADD CONSTRAINT "fk_documents_2" FOREIGN KEY ("organization_id", "project_id") REFERENCES nexus."projects" ("organization_id", "id") ON DELETE RESTRICT;
ALTER TABLE nexus."documents" ADD CONSTRAINT "fk_documents_3" FOREIGN KEY ("organization_id", "owner_id") REFERENCES nexus."memberships" ("organization_id", "id") ON DELETE RESTRICT;
ALTER TABLE nexus."document_versions" ADD CONSTRAINT "fk_document_versions_1" FOREIGN KEY ("organization_id") REFERENCES nexus."organizations" ("id") ON DELETE RESTRICT;
ALTER TABLE nexus."document_versions" ADD CONSTRAINT "fk_document_versions_2" FOREIGN KEY ("organization_id", "document_id") REFERENCES nexus."documents" ("organization_id", "id") ON DELETE RESTRICT;
ALTER TABLE nexus."document_versions" ADD CONSTRAINT "fk_document_versions_3" FOREIGN KEY ("organization_id", "file_id") REFERENCES nexus."files" ("organization_id", "id") ON DELETE RESTRICT;
ALTER TABLE nexus."document_versions" ADD CONSTRAINT "fk_document_versions_4" FOREIGN KEY ("organization_id", "created_by") REFERENCES nexus."memberships" ("organization_id", "id") ON DELETE RESTRICT;
ALTER TABLE nexus."document_versions" ADD CONSTRAINT "fk_document_versions_5" FOREIGN KEY ("organization_id", "approved_by") REFERENCES nexus."memberships" ("organization_id", "id") ON DELETE RESTRICT;
ALTER TABLE nexus."document_acl" ADD CONSTRAINT "fk_document_acl_1" FOREIGN KEY ("organization_id") REFERENCES nexus."organizations" ("id") ON DELETE RESTRICT;
ALTER TABLE nexus."document_acl" ADD CONSTRAINT "fk_document_acl_2" FOREIGN KEY ("organization_id", "document_id") REFERENCES nexus."documents" ("organization_id", "id") ON DELETE RESTRICT;
ALTER TABLE nexus."document_acl" ADD CONSTRAINT "fk_document_acl_3" FOREIGN KEY ("organization_id", "membership_id") REFERENCES nexus."memberships" ("organization_id", "id") ON DELETE RESTRICT;
ALTER TABLE nexus."index_jobs" ADD CONSTRAINT "fk_index_jobs_1" FOREIGN KEY ("organization_id") REFERENCES nexus."organizations" ("id") ON DELETE RESTRICT;
ALTER TABLE nexus."index_jobs" ADD CONSTRAINT "fk_index_jobs_2" FOREIGN KEY ("organization_id", "document_version_id") REFERENCES nexus."document_versions" ("organization_id", "id") ON DELETE RESTRICT;
ALTER TABLE nexus."source_refs" ADD CONSTRAINT "fk_source_refs_1" FOREIGN KEY ("organization_id") REFERENCES nexus."organizations" ("id") ON DELETE RESTRICT;
ALTER TABLE nexus."source_refs" ADD CONSTRAINT "fk_source_refs_2" FOREIGN KEY ("organization_id", "document_version_id") REFERENCES nexus."document_versions" ("organization_id", "id") ON DELETE RESTRICT;
ALTER TABLE nexus."learning_paths" ADD CONSTRAINT "fk_learning_paths_1" FOREIGN KEY ("organization_id") REFERENCES nexus."organizations" ("id") ON DELETE RESTRICT;
ALTER TABLE nexus."courses" ADD CONSTRAINT "fk_courses_1" FOREIGN KEY ("organization_id") REFERENCES nexus."organizations" ("id") ON DELETE RESTRICT;
ALTER TABLE nexus."courses" ADD CONSTRAINT "fk_courses_2" FOREIGN KEY ("organization_id", "owner_id") REFERENCES nexus."memberships" ("organization_id", "id") ON DELETE RESTRICT;
ALTER TABLE nexus."course_versions" ADD CONSTRAINT "fk_course_versions_1" FOREIGN KEY ("organization_id") REFERENCES nexus."organizations" ("id") ON DELETE RESTRICT;
ALTER TABLE nexus."course_versions" ADD CONSTRAINT "fk_course_versions_2" FOREIGN KEY ("organization_id", "course_id") REFERENCES nexus."courses" ("organization_id", "id") ON DELETE RESTRICT;
ALTER TABLE nexus."course_versions" ADD CONSTRAINT "fk_course_versions_3" FOREIGN KEY ("organization_id", "created_by") REFERENCES nexus."memberships" ("organization_id", "id") ON DELETE RESTRICT;
ALTER TABLE nexus."course_versions" ADD CONSTRAINT "fk_course_versions_4" FOREIGN KEY ("organization_id", "approved_by") REFERENCES nexus."memberships" ("organization_id", "id") ON DELETE RESTRICT;
ALTER TABLE nexus."path_courses" ADD CONSTRAINT "fk_path_courses_1" FOREIGN KEY ("organization_id") REFERENCES nexus."organizations" ("id") ON DELETE RESTRICT;
ALTER TABLE nexus."path_courses" ADD CONSTRAINT "fk_path_courses_2" FOREIGN KEY ("organization_id", "path_id") REFERENCES nexus."learning_paths" ("organization_id", "id") ON DELETE RESTRICT;
ALTER TABLE nexus."path_courses" ADD CONSTRAINT "fk_path_courses_3" FOREIGN KEY ("organization_id", "course_id") REFERENCES nexus."courses" ("organization_id", "id") ON DELETE RESTRICT;
ALTER TABLE nexus."course_modules" ADD CONSTRAINT "fk_course_modules_1" FOREIGN KEY ("organization_id") REFERENCES nexus."organizations" ("id") ON DELETE RESTRICT;
ALTER TABLE nexus."course_modules" ADD CONSTRAINT "fk_course_modules_2" FOREIGN KEY ("organization_id", "course_version_id") REFERENCES nexus."course_versions" ("organization_id", "id") ON DELETE RESTRICT;
ALTER TABLE nexus."lessons" ADD CONSTRAINT "fk_lessons_1" FOREIGN KEY ("organization_id") REFERENCES nexus."organizations" ("id") ON DELETE RESTRICT;
ALTER TABLE nexus."lessons" ADD CONSTRAINT "fk_lessons_2" FOREIGN KEY ("organization_id", "course_module_id") REFERENCES nexus."course_modules" ("organization_id", "id") ON DELETE RESTRICT;
ALTER TABLE nexus."lesson_resources" ADD CONSTRAINT "fk_lesson_resources_1" FOREIGN KEY ("organization_id") REFERENCES nexus."organizations" ("id") ON DELETE RESTRICT;
ALTER TABLE nexus."lesson_resources" ADD CONSTRAINT "fk_lesson_resources_2" FOREIGN KEY ("organization_id", "lesson_id") REFERENCES nexus."lessons" ("organization_id", "id") ON DELETE RESTRICT;
ALTER TABLE nexus."lesson_resources" ADD CONSTRAINT "fk_lesson_resources_3" FOREIGN KEY ("organization_id", "file_id") REFERENCES nexus."files" ("organization_id", "id") ON DELETE RESTRICT;
ALTER TABLE nexus."lesson_resources" ADD CONSTRAINT "fk_lesson_resources_4" FOREIGN KEY ("organization_id", "document_version_id") REFERENCES nexus."document_versions" ("organization_id", "id") ON DELETE RESTRICT;
ALTER TABLE nexus."enrollments" ADD CONSTRAINT "fk_enrollments_1" FOREIGN KEY ("organization_id") REFERENCES nexus."organizations" ("id") ON DELETE RESTRICT;
ALTER TABLE nexus."enrollments" ADD CONSTRAINT "fk_enrollments_2" FOREIGN KEY ("organization_id", "course_version_id") REFERENCES nexus."course_versions" ("organization_id", "id") ON DELETE RESTRICT;
ALTER TABLE nexus."enrollments" ADD CONSTRAINT "fk_enrollments_3" FOREIGN KEY ("organization_id", "membership_id") REFERENCES nexus."memberships" ("organization_id", "id") ON DELETE RESTRICT;
ALTER TABLE nexus."enrollments" ADD CONSTRAINT "fk_enrollments_4" FOREIGN KEY ("organization_id", "assigned_by") REFERENCES nexus."memberships" ("organization_id", "id") ON DELETE RESTRICT;
ALTER TABLE nexus."lesson_progress" ADD CONSTRAINT "fk_lesson_progress_1" FOREIGN KEY ("organization_id") REFERENCES nexus."organizations" ("id") ON DELETE RESTRICT;
ALTER TABLE nexus."lesson_progress" ADD CONSTRAINT "fk_lesson_progress_2" FOREIGN KEY ("organization_id", "enrollment_id") REFERENCES nexus."enrollments" ("organization_id", "id") ON DELETE RESTRICT;
ALTER TABLE nexus."lesson_progress" ADD CONSTRAINT "fk_lesson_progress_3" FOREIGN KEY ("organization_id", "lesson_id") REFERENCES nexus."lessons" ("organization_id", "id") ON DELETE RESTRICT;
ALTER TABLE nexus."assessments" ADD CONSTRAINT "fk_assessments_1" FOREIGN KEY ("organization_id") REFERENCES nexus."organizations" ("id") ON DELETE RESTRICT;
ALTER TABLE nexus."assessments" ADD CONSTRAINT "fk_assessments_2" FOREIGN KEY ("organization_id", "course_version_id") REFERENCES nexus."course_versions" ("organization_id", "id") ON DELETE RESTRICT;
ALTER TABLE nexus."assessments" ADD CONSTRAINT "fk_assessments_3" FOREIGN KEY ("organization_id", "lesson_id") REFERENCES nexus."lessons" ("organization_id", "id") ON DELETE RESTRICT;
ALTER TABLE nexus."assessment_questions" ADD CONSTRAINT "fk_assessment_questions_1" FOREIGN KEY ("organization_id") REFERENCES nexus."organizations" ("id") ON DELETE RESTRICT;
ALTER TABLE nexus."assessment_questions" ADD CONSTRAINT "fk_assessment_questions_2" FOREIGN KEY ("organization_id", "assessment_id") REFERENCES nexus."assessments" ("organization_id", "id") ON DELETE RESTRICT;
ALTER TABLE nexus."assessment_answer_keys" ADD CONSTRAINT "fk_assessment_answer_keys_1" FOREIGN KEY ("organization_id") REFERENCES nexus."organizations" ("id") ON DELETE RESTRICT;
ALTER TABLE nexus."assessment_answer_keys" ADD CONSTRAINT "fk_assessment_answer_keys_2" FOREIGN KEY ("organization_id", "question_id") REFERENCES nexus."assessment_questions" ("organization_id", "id") ON DELETE RESTRICT;
ALTER TABLE nexus."attempts" ADD CONSTRAINT "fk_attempts_1" FOREIGN KEY ("organization_id") REFERENCES nexus."organizations" ("id") ON DELETE RESTRICT;
ALTER TABLE nexus."attempts" ADD CONSTRAINT "fk_attempts_2" FOREIGN KEY ("organization_id", "enrollment_id") REFERENCES nexus."enrollments" ("organization_id", "id") ON DELETE RESTRICT;
ALTER TABLE nexus."attempts" ADD CONSTRAINT "fk_attempts_3" FOREIGN KEY ("organization_id", "assessment_id") REFERENCES nexus."assessments" ("organization_id", "id") ON DELETE RESTRICT;
ALTER TABLE nexus."attempt_answers" ADD CONSTRAINT "fk_attempt_answers_1" FOREIGN KEY ("organization_id") REFERENCES nexus."organizations" ("id") ON DELETE RESTRICT;
ALTER TABLE nexus."attempt_answers" ADD CONSTRAINT "fk_attempt_answers_2" FOREIGN KEY ("organization_id", "attempt_id") REFERENCES nexus."attempts" ("organization_id", "id") ON DELETE RESTRICT;
ALTER TABLE nexus."attempt_answers" ADD CONSTRAINT "fk_attempt_answers_3" FOREIGN KEY ("organization_id", "question_id") REFERENCES nexus."assessment_questions" ("organization_id", "id") ON DELETE RESTRICT;
ALTER TABLE nexus."attempt_answers" ADD CONSTRAINT "fk_attempt_answers_4" FOREIGN KEY ("organization_id", "file_id") REFERENCES nexus."files" ("organization_id", "id") ON DELETE RESTRICT;
ALTER TABLE nexus."mentoring_sessions" ADD CONSTRAINT "fk_mentoring_sessions_1" FOREIGN KEY ("organization_id") REFERENCES nexus."organizations" ("id") ON DELETE RESTRICT;
ALTER TABLE nexus."mentoring_sessions" ADD CONSTRAINT "fk_mentoring_sessions_2" FOREIGN KEY ("organization_id", "mentor_id") REFERENCES nexus."memberships" ("organization_id", "id") ON DELETE RESTRICT;
ALTER TABLE nexus."mentoring_sessions" ADD CONSTRAINT "fk_mentoring_sessions_3" FOREIGN KEY ("organization_id", "student_id") REFERENCES nexus."memberships" ("organization_id", "id") ON DELETE RESTRICT;
ALTER TABLE nexus."forum_posts" ADD CONSTRAINT "fk_forum_posts_1" FOREIGN KEY ("organization_id") REFERENCES nexus."organizations" ("id") ON DELETE RESTRICT;
ALTER TABLE nexus."forum_posts" ADD CONSTRAINT "fk_forum_posts_2" FOREIGN KEY ("organization_id", "course_id") REFERENCES nexus."courses" ("organization_id", "id") ON DELETE RESTRICT;
ALTER TABLE nexus."forum_posts" ADD CONSTRAINT "fk_forum_posts_3" FOREIGN KEY ("organization_id", "author_id") REFERENCES nexus."memberships" ("organization_id", "id") ON DELETE RESTRICT;
ALTER TABLE nexus."forum_posts" ADD CONSTRAINT "fk_forum_posts_4" FOREIGN KEY ("organization_id", "parent_post_id") REFERENCES nexus."forum_posts" ("organization_id", "id") ON DELETE RESTRICT;
ALTER TABLE nexus."forum_posts" ADD CONSTRAINT "fk_forum_posts_5" FOREIGN KEY ("organization_id", "course_id", "parent_post_id") REFERENCES nexus."forum_posts" ("organization_id", "course_id", "id") ON DELETE RESTRICT;
ALTER TABLE nexus."achievements" ADD CONSTRAINT "fk_achievements_1" FOREIGN KEY ("organization_id") REFERENCES nexus."organizations" ("id") ON DELETE RESTRICT;
ALTER TABLE nexus."member_achievements" ADD CONSTRAINT "fk_member_achievements_1" FOREIGN KEY ("organization_id") REFERENCES nexus."organizations" ("id") ON DELETE RESTRICT;
ALTER TABLE nexus."member_achievements" ADD CONSTRAINT "fk_member_achievements_2" FOREIGN KEY ("organization_id", "achievement_id") REFERENCES nexus."achievements" ("organization_id", "id") ON DELETE RESTRICT;
ALTER TABLE nexus."member_achievements" ADD CONSTRAINT "fk_member_achievements_3" FOREIGN KEY ("organization_id", "membership_id") REFERENCES nexus."memberships" ("organization_id", "id") ON DELETE RESTRICT;
ALTER TABLE nexus."certificates" ADD CONSTRAINT "fk_certificates_1" FOREIGN KEY ("organization_id") REFERENCES nexus."organizations" ("id") ON DELETE RESTRICT;
ALTER TABLE nexus."certificates" ADD CONSTRAINT "fk_certificates_2" FOREIGN KEY ("organization_id", "enrollment_id") REFERENCES nexus."enrollments" ("organization_id", "id") ON DELETE RESTRICT;
ALTER TABLE nexus."certificates" ADD CONSTRAINT "fk_certificates_3" FOREIGN KEY ("organization_id", "file_id") REFERENCES nexus."files" ("organization_id", "id") ON DELETE RESTRICT;
ALTER TABLE nexus."conversations" ADD CONSTRAINT "fk_conversations_1" FOREIGN KEY ("organization_id") REFERENCES nexus."organizations" ("id") ON DELETE RESTRICT;
ALTER TABLE nexus."conversations" ADD CONSTRAINT "fk_conversations_2" FOREIGN KEY ("organization_id", "owner_id") REFERENCES nexus."memberships" ("organization_id", "id") ON DELETE RESTRICT;
ALTER TABLE nexus."conversations" ADD CONSTRAINT "fk_conversations_3" FOREIGN KEY ("organization_id", "project_id") REFERENCES nexus."projects" ("organization_id", "id") ON DELETE RESTRICT;
ALTER TABLE nexus."messages" ADD CONSTRAINT "fk_messages_1" FOREIGN KEY ("organization_id") REFERENCES nexus."organizations" ("id") ON DELETE RESTRICT;
ALTER TABLE nexus."messages" ADD CONSTRAINT "fk_messages_2" FOREIGN KEY ("organization_id", "conversation_id") REFERENCES nexus."conversations" ("organization_id", "id") ON DELETE RESTRICT;
ALTER TABLE nexus."citations" ADD CONSTRAINT "fk_citations_1" FOREIGN KEY ("organization_id") REFERENCES nexus."organizations" ("id") ON DELETE RESTRICT;
ALTER TABLE nexus."citations" ADD CONSTRAINT "fk_citations_2" FOREIGN KEY ("organization_id", "message_id") REFERENCES nexus."messages" ("organization_id", "id") ON DELETE RESTRICT;
ALTER TABLE nexus."citations" ADD CONSTRAINT "fk_citations_3" FOREIGN KEY ("organization_id", "source_ref_id") REFERENCES nexus."source_refs" ("organization_id", "id") ON DELETE RESTRICT;
ALTER TABLE nexus."citations" ADD CONSTRAINT "fk_citations_4" FOREIGN KEY ("organization_id", "card_id") REFERENCES nexus."cards" ("organization_id", "id") ON DELETE RESTRICT;
ALTER TABLE nexus."tool_runs" ADD CONSTRAINT "fk_tool_runs_1" FOREIGN KEY ("organization_id") REFERENCES nexus."organizations" ("id") ON DELETE RESTRICT;
ALTER TABLE nexus."tool_runs" ADD CONSTRAINT "fk_tool_runs_2" FOREIGN KEY ("organization_id", "conversation_id") REFERENCES nexus."conversations" ("organization_id", "id") ON DELETE RESTRICT;
ALTER TABLE nexus."tool_runs" ADD CONSTRAINT "fk_tool_runs_3" FOREIGN KEY ("organization_id", "message_id") REFERENCES nexus."messages" ("organization_id", "id") ON DELETE RESTRICT;
ALTER TABLE nexus."action_previews" ADD CONSTRAINT "fk_action_previews_1" FOREIGN KEY ("organization_id") REFERENCES nexus."organizations" ("id") ON DELETE RESTRICT;
ALTER TABLE nexus."action_previews" ADD CONSTRAINT "fk_action_previews_2" FOREIGN KEY ("organization_id", "conversation_id") REFERENCES nexus."conversations" ("organization_id", "id") ON DELETE RESTRICT;
ALTER TABLE nexus."action_previews" ADD CONSTRAINT "fk_action_previews_3" FOREIGN KEY ("organization_id", "requested_by") REFERENCES nexus."memberships" ("organization_id", "id") ON DELETE RESTRICT;
ALTER TABLE nexus."speech_sessions" ADD CONSTRAINT "fk_speech_sessions_1" FOREIGN KEY ("organization_id") REFERENCES nexus."organizations" ("id") ON DELETE RESTRICT;
ALTER TABLE nexus."speech_sessions" ADD CONSTRAINT "fk_speech_sessions_2" FOREIGN KEY ("organization_id", "membership_id") REFERENCES nexus."memberships" ("organization_id", "id") ON DELETE RESTRICT;
ALTER TABLE nexus."speech_sessions" ADD CONSTRAINT "fk_speech_sessions_3" FOREIGN KEY ("organization_id", "conversation_id") REFERENCES nexus."conversations" ("organization_id", "id") ON DELETE RESTRICT;
ALTER TABLE nexus."model_versions" ADD CONSTRAINT "fk_model_versions_1" FOREIGN KEY ("organization_id") REFERENCES nexus."organizations" ("id") ON DELETE RESTRICT;
ALTER TABLE nexus."predictions" ADD CONSTRAINT "fk_predictions_1" FOREIGN KEY ("organization_id") REFERENCES nexus."organizations" ("id") ON DELETE RESTRICT;
ALTER TABLE nexus."predictions" ADD CONSTRAINT "fk_predictions_2" FOREIGN KEY ("organization_id", "model_version_id") REFERENCES nexus."model_versions" ("organization_id", "id") ON DELETE RESTRICT;
ALTER TABLE nexus."predictions" ADD CONSTRAINT "fk_predictions_3" FOREIGN KEY ("organization_id", "requested_by") REFERENCES nexus."memberships" ("organization_id", "id") ON DELETE RESTRICT;
ALTER TABLE nexus."predictions" ADD CONSTRAINT "fk_predictions_4" FOREIGN KEY ("organization_id", "project_id") REFERENCES nexus."projects" ("organization_id", "id") ON DELETE RESTRICT;
ALTER TABLE nexus."predictions" ADD CONSTRAINT "fk_predictions_5" FOREIGN KEY ("organization_id", "card_id") REFERENCES nexus."cards" ("organization_id", "id") ON DELETE RESTRICT;
ALTER TABLE nexus."predictions" ADD CONSTRAINT "fk_predictions_6" FOREIGN KEY ("organization_id", "project_id", "card_id") REFERENCES nexus."cards" ("organization_id", "project_id", "id") ON DELETE RESTRICT;
ALTER TABLE nexus."usage_records" ADD CONSTRAINT "fk_usage_records_1" FOREIGN KEY ("organization_id") REFERENCES nexus."organizations" ("id") ON DELETE RESTRICT;
ALTER TABLE nexus."usage_records" ADD CONSTRAINT "fk_usage_records_2" FOREIGN KEY ("organization_id", "membership_id") REFERENCES nexus."memberships" ("organization_id", "id") ON DELETE RESTRICT;
ALTER TABLE nexus."services" ADD CONSTRAINT "fk_services_1" FOREIGN KEY ("organization_id") REFERENCES nexus."organizations" ("id") ON DELETE RESTRICT;
ALTER TABLE nexus."plans" ADD CONSTRAINT "fk_plans_1" FOREIGN KEY ("organization_id") REFERENCES nexus."organizations" ("id") ON DELETE RESTRICT;
ALTER TABLE nexus."plans" ADD CONSTRAINT "fk_plans_2" FOREIGN KEY ("organization_id", "service_id") REFERENCES nexus."services" ("organization_id", "id") ON DELETE RESTRICT;
ALTER TABLE nexus."plan_versions" ADD CONSTRAINT "fk_plan_versions_1" FOREIGN KEY ("organization_id") REFERENCES nexus."organizations" ("id") ON DELETE RESTRICT;
ALTER TABLE nexus."plan_versions" ADD CONSTRAINT "fk_plan_versions_2" FOREIGN KEY ("organization_id", "plan_id") REFERENCES nexus."plans" ("organization_id", "id") ON DELETE RESTRICT;
ALTER TABLE nexus."plan_versions" ADD CONSTRAINT "fk_plan_versions_3" FOREIGN KEY ("organization_id", "created_by") REFERENCES nexus."memberships" ("organization_id", "id") ON DELETE RESTRICT;
ALTER TABLE nexus."plan_versions" ADD CONSTRAINT "fk_plan_versions_4" FOREIGN KEY ("organization_id", "approved_by") REFERENCES nexus."memberships" ("organization_id", "id") ON DELETE RESTRICT;
ALTER TABLE nexus."leads" ADD CONSTRAINT "fk_leads_1" FOREIGN KEY ("organization_id") REFERENCES nexus."organizations" ("id") ON DELETE RESTRICT;
ALTER TABLE nexus."quotes" ADD CONSTRAINT "fk_quotes_1" FOREIGN KEY ("organization_id") REFERENCES nexus."organizations" ("id") ON DELETE RESTRICT;
ALTER TABLE nexus."quotes" ADD CONSTRAINT "fk_quotes_2" FOREIGN KEY ("organization_id", "lead_id") REFERENCES nexus."leads" ("organization_id", "id") ON DELETE RESTRICT;
ALTER TABLE nexus."quotes" ADD CONSTRAINT "fk_quotes_3" FOREIGN KEY ("organization_id", "created_by") REFERENCES nexus."memberships" ("organization_id", "id") ON DELETE RESTRICT;
ALTER TABLE nexus."quote_items" ADD CONSTRAINT "fk_quote_items_1" FOREIGN KEY ("organization_id") REFERENCES nexus."organizations" ("id") ON DELETE RESTRICT;
ALTER TABLE nexus."quote_items" ADD CONSTRAINT "fk_quote_items_2" FOREIGN KEY ("organization_id", "quote_id") REFERENCES nexus."quotes" ("organization_id", "id") ON DELETE RESTRICT;
ALTER TABLE nexus."quote_items" ADD CONSTRAINT "fk_quote_items_3" FOREIGN KEY ("organization_id", "plan_version_id") REFERENCES nexus."plan_versions" ("organization_id", "id") ON DELETE RESTRICT;
ALTER TABLE nexus."notifications" ADD CONSTRAINT "fk_notifications_1" FOREIGN KEY ("organization_id") REFERENCES nexus."organizations" ("id") ON DELETE RESTRICT;
ALTER TABLE nexus."notifications" ADD CONSTRAINT "fk_notifications_2" FOREIGN KEY ("organization_id", "recipient_id") REFERENCES nexus."memberships" ("organization_id", "id") ON DELETE RESTRICT;
ALTER TABLE nexus."notification_preferences" ADD CONSTRAINT "fk_notification_preferences_1" FOREIGN KEY ("organization_id") REFERENCES nexus."organizations" ("id") ON DELETE RESTRICT;
ALTER TABLE nexus."notification_preferences" ADD CONSTRAINT "fk_notification_preferences_2" FOREIGN KEY ("organization_id", "membership_id") REFERENCES nexus."memberships" ("organization_id", "id") ON DELETE RESTRICT;
ALTER TABLE nexus."audit_events" ADD CONSTRAINT "fk_audit_events_1" FOREIGN KEY ("organization_id") REFERENCES nexus."organizations" ("id") ON DELETE RESTRICT;
ALTER TABLE nexus."audit_events" ADD CONSTRAINT "fk_audit_events_2" FOREIGN KEY ("organization_id", "actor_id") REFERENCES nexus."memberships" ("organization_id", "id") ON DELETE RESTRICT;
ALTER TABLE nexus."audit_events" ADD CONSTRAINT "fk_audit_events_3" FOREIGN KEY ("organization_id", "project_id") REFERENCES nexus."projects" ("organization_id", "id") ON DELETE RESTRICT;
ALTER TABLE nexus."outbox" ADD CONSTRAINT "fk_outbox_1" FOREIGN KEY ("organization_id") REFERENCES nexus."organizations" ("id") ON DELETE RESTRICT;
ALTER TABLE nexus."jobs" ADD CONSTRAINT "fk_jobs_1" FOREIGN KEY ("organization_id") REFERENCES nexus."organizations" ("id") ON DELETE RESTRICT;
ALTER TABLE nexus."import_batches" ADD CONSTRAINT "fk_import_batches_1" FOREIGN KEY ("organization_id") REFERENCES nexus."organizations" ("id") ON DELETE RESTRICT;
ALTER TABLE nexus."import_batches" ADD CONSTRAINT "fk_import_batches_2" FOREIGN KEY ("organization_id", "file_id") REFERENCES nexus."files" ("organization_id", "id") ON DELETE RESTRICT;
ALTER TABLE nexus."import_batches" ADD CONSTRAINT "fk_import_batches_3" FOREIGN KEY ("organization_id", "requested_by") REFERENCES nexus."memberships" ("organization_id", "id") ON DELETE RESTRICT;
ALTER TABLE nexus."import_rows" ADD CONSTRAINT "fk_import_rows_1" FOREIGN KEY ("organization_id") REFERENCES nexus."organizations" ("id") ON DELETE RESTRICT;
ALTER TABLE nexus."import_rows" ADD CONSTRAINT "fk_import_rows_2" FOREIGN KEY ("organization_id", "batch_id") REFERENCES nexus."import_batches" ("organization_id", "id") ON DELETE RESTRICT;
ALTER TABLE nexus."import_rows" ADD CONSTRAINT "fk_import_rows_3" FOREIGN KEY ("organization_id", "card_id") REFERENCES nexus."cards" ("organization_id", "id") ON DELETE RESTRICT;
ALTER TABLE nexus."historical_task_facts" ADD CONSTRAINT "fk_historical_task_facts_1" FOREIGN KEY ("organization_id") REFERENCES nexus."organizations" ("id") ON DELETE RESTRICT;
ALTER TABLE nexus."historical_task_facts" ADD CONSTRAINT "fk_historical_task_facts_2" FOREIGN KEY ("organization_id", "batch_id") REFERENCES nexus."import_batches" ("organization_id", "id") ON DELETE RESTRICT;
ALTER TABLE nexus."export_jobs" ADD CONSTRAINT "fk_export_jobs_1" FOREIGN KEY ("organization_id") REFERENCES nexus."organizations" ("id") ON DELETE RESTRICT;
ALTER TABLE nexus."export_jobs" ADD CONSTRAINT "fk_export_jobs_2" FOREIGN KEY ("organization_id", "requested_by") REFERENCES nexus."memberships" ("organization_id", "id") ON DELETE RESTRICT;
ALTER TABLE nexus."export_jobs" ADD CONSTRAINT "fk_export_jobs_3" FOREIGN KEY ("organization_id", "file_id") REFERENCES nexus."files" ("organization_id", "id") ON DELETE RESTRICT;
ALTER TABLE nexus."integration_settings" ADD CONSTRAINT "fk_integration_settings_1" FOREIGN KEY ("organization_id") REFERENCES nexus."organizations" ("id") ON DELETE RESTRICT;
ALTER TABLE nexus."integration_settings" ADD CONSTRAINT "fk_integration_settings_2" FOREIGN KEY ("organization_id", "updated_by") REFERENCES nexus."memberships" ("organization_id", "id") ON DELETE RESTRICT;
ALTER TABLE nexus."quota_limits" ADD CONSTRAINT "fk_quota_limits_1" FOREIGN KEY ("organization_id") REFERENCES nexus."organizations" ("id") ON DELETE RESTRICT;
ALTER TABLE nexus."idempotency_keys" ADD CONSTRAINT "fk_idempotency_keys_1" FOREIGN KEY ("organization_id") REFERENCES nexus."organizations" ("id") ON DELETE RESTRICT;
ALTER TABLE nexus."idempotency_keys" ADD CONSTRAINT "fk_idempotency_keys_2" FOREIGN KEY ("organization_id", "membership_id") REFERENCES nexus."memberships" ("organization_id", "id") ON DELETE RESTRICT;

-- Índices únicos parciales: resolver conflictos de archivo y vigencia en servicio.
CREATE UNIQUE INDEX uq_labels_global_active ON nexus."labels" (organization_id, normalized_name) WHERE project_id IS NULL AND archived_at IS NULL;
CREATE UNIQUE INDEX uq_labels_project_active ON nexus."labels" (organization_id, project_id, normalized_name) WHERE project_id IS NOT NULL AND archived_at IS NULL;
CREATE UNIQUE INDEX uq_timers_running ON nexus."timers" (membership_id) WHERE status = 'running';
CREATE UNIQUE INDEX uq_role_grants_org_active ON nexus."role_grants" (membership_id, role_id) WHERE project_id IS NULL AND revoked_at IS NULL;
CREATE UNIQUE INDEX uq_role_grants_project_active ON nexus."role_grants" (membership_id, role_id, project_id) WHERE project_id IS NOT NULL AND revoked_at IS NULL;
CREATE UNIQUE INDEX uq_document_published ON nexus."document_versions" (document_id) WHERE status = 'published';
CREATE UNIQUE INDEX uq_course_published ON nexus."course_versions" (course_id) WHERE status = 'published';

-- Índices por FK, ámbito y consultas frecuentes. Revisar con EXPLAIN en datos reales.
CREATE INDEX "ix_memberships_2" ON nexus."memberships" ("profile_id");
CREATE INDEX "ix_role_permissions_2" ON nexus."role_permissions" ("organization_id", "role_id");
CREATE INDEX "ix_role_permissions_3" ON nexus."role_permissions" ("permission_id");
CREATE INDEX "ix_role_grants_2" ON nexus."role_grants" ("organization_id", "membership_id");
CREATE INDEX "ix_role_grants_3" ON nexus."role_grants" ("organization_id", "role_id");
CREATE INDEX "ix_role_grants_4" ON nexus."role_grants" ("organization_id", "project_id");
CREATE INDEX "ix_role_grants_5" ON nexus."role_grants" ("organization_id", "granted_by");
CREATE INDEX "ix_invitations_2" ON nexus."invitations" ("organization_id", "invited_by");
CREATE INDEX "ix_invitations_3" ON nexus."invitations" ("organization_id", "role_id");
CREATE INDEX "ix_user_preferences_2" ON nexus."user_preferences" ("organization_id", "membership_id");
CREATE INDEX "ix_organization_settings_2" ON nexus."organization_settings" ("organization_id", "updated_by");
CREATE INDEX "ix_team_members_2" ON nexus."team_members" ("organization_id", "team_id");
CREATE INDEX "ix_team_members_3" ON nexus."team_members" ("organization_id", "membership_id");
CREATE INDEX "ix_availability_2" ON nexus."availability" ("organization_id", "membership_id");
CREATE INDEX "ix_projects_2" ON nexus."projects" ("organization_id", "created_by");
CREATE INDEX "ix_projects_3" ON nexus."projects" ("organization_id", "status", "due_date");
CREATE INDEX "ix_project_members_3" ON nexus."project_members" ("organization_id", "membership_id");
CREATE INDEX "ix_project_members_4" ON nexus."project_members" ("organization_id", "team_id");
CREATE INDEX "ix_board_columns_4" ON nexus."board_columns" ("board_id", "position");
CREATE INDEX "ix_cards_3" ON nexus."cards" ("organization_id", "project_id", "board_id");
CREATE INDEX "ix_cards_4" ON nexus."cards" ("organization_id", "project_id", "column_id");
CREATE INDEX "ix_cards_5" ON nexus."cards" ("organization_id", "project_id", "parent_card_id");
CREATE INDEX "ix_cards_6" ON nexus."cards" ("organization_id", "project_id", "milestone_id");
CREATE INDEX "ix_cards_7" ON nexus."cards" ("organization_id", "created_by");
CREATE INDEX "ix_cards_8" ON nexus."cards" ("organization_id", "project_id", "board_id", "column_id");
CREATE INDEX "ix_cards_9" ON nexus."cards" ("column_id", "position");
CREATE INDEX "ix_cards_10" ON nexus."cards" ("project_id", "due_date");
CREATE INDEX "ix_cards_11" ON nexus."cards" ("project_id", "archived_at");
CREATE INDEX "ix_card_assignees_3" ON nexus."card_assignees" ("organization_id", "project_id", "card_id");
CREATE INDEX "ix_card_assignees_4" ON nexus."card_assignees" ("organization_id", "membership_id");
CREATE INDEX "ix_card_assignees_5" ON nexus."card_assignees" ("organization_id", "assigned_by");
CREATE INDEX "ix_card_assignees_6" ON nexus."card_assignees" ("organization_id", "project_id", "membership_id");
CREATE INDEX "ix_card_assignees_7" ON nexus."card_assignees" ("membership_id", "removed_at");
CREATE INDEX "ix_labels_2" ON nexus."labels" ("organization_id", "project_id");
CREATE INDEX "ix_card_labels_3" ON nexus."card_labels" ("organization_id", "project_id", "card_id");
CREATE INDEX "ix_card_labels_4" ON nexus."card_labels" ("organization_id", "label_id");
CREATE INDEX "ix_field_definitions_3" ON nexus."field_definitions" ("organization_id", "project_id", "board_id");
CREATE INDEX "ix_field_values_3" ON nexus."field_values" ("organization_id", "project_id", "card_id");
CREATE INDEX "ix_field_values_4" ON nexus."field_values" ("organization_id", "project_id", "field_definition_id");
CREATE INDEX "ix_checklists_3" ON nexus."checklists" ("organization_id", "project_id", "card_id");
CREATE INDEX "ix_checklist_items_3" ON nexus."checklist_items" ("organization_id", "project_id", "checklist_id");
CREATE INDEX "ix_checklist_items_4" ON nexus."checklist_items" ("organization_id", "assignee_id");
CREATE INDEX "ix_checklist_items_5" ON nexus."checklist_items" ("organization_id", "completed_by");
CREATE INDEX "ix_checklist_items_6" ON nexus."checklist_items" ("organization_id", "project_id", "assignee_id");
CREATE INDEX "ix_card_dependencies_3" ON nexus."card_dependencies" ("organization_id", "project_id", "card_id");
CREATE INDEX "ix_card_dependencies_4" ON nexus."card_dependencies" ("organization_id", "project_id", "prerequisite_id");
CREATE INDEX "ix_comments_4" ON nexus."comments" ("organization_id", "project_id", "parent_comment_id");
CREATE INDEX "ix_comments_5" ON nexus."comments" ("organization_id", "author_id");
CREATE INDEX "ix_comments_6" ON nexus."comments" ("organization_id", "project_id", "card_id", "parent_comment_id");
CREATE INDEX "ix_comment_mentions_3" ON nexus."comment_mentions" ("organization_id", "project_id", "comment_id");
CREATE INDEX "ix_comment_mentions_4" ON nexus."comment_mentions" ("organization_id", "membership_id");
CREATE INDEX "ix_comment_reactions_3" ON nexus."comment_reactions" ("organization_id", "project_id", "comment_id");
CREATE INDEX "ix_comment_reactions_4" ON nexus."comment_reactions" ("organization_id", "membership_id");
CREATE INDEX "ix_files_2" ON nexus."files" ("organization_id", "uploaded_by");
CREATE INDEX "ix_attachments_3" ON nexus."attachments" ("organization_id", "project_id", "card_id");
CREATE INDEX "ix_attachments_4" ON nexus."attachments" ("organization_id", "file_id");
CREATE INDEX "ix_attachments_5" ON nexus."attachments" ("organization_id", "added_by");
CREATE INDEX "ix_card_watchers_3" ON nexus."card_watchers" ("organization_id", "project_id", "card_id");
CREATE INDEX "ix_card_watchers_4" ON nexus."card_watchers" ("organization_id", "membership_id");
CREATE INDEX "ix_card_events_3" ON nexus."card_events" ("organization_id", "project_id", "card_id");
CREATE INDEX "ix_card_events_4" ON nexus."card_events" ("organization_id", "actor_id");
CREATE INDEX "ix_card_events_5" ON nexus."card_events" ("card_id", "created_at");
CREATE INDEX "ix_timers_4" ON nexus."timers" ("organization_id", "membership_id");
CREATE INDEX "ix_time_entries_3" ON nexus."time_entries" ("organization_id", "project_id", "card_id");
CREATE INDEX "ix_time_entries_4" ON nexus."time_entries" ("organization_id", "membership_id");
CREATE INDEX "ix_time_entries_5" ON nexus."time_entries" ("organization_id", "project_id", "timer_id");
CREATE INDEX "ix_time_entries_6" ON nexus."time_entries" ("organization_id", "project_id", "card_id", "membership_id", "timer_id");
CREATE INDEX "ix_time_entries_7" ON nexus."time_entries" ("membership_id", "work_date");
CREATE INDEX "ix_time_entries_8" ON nexus."time_entries" ("card_id", "status");
CREATE INDEX "ix_time_entry_versions_3" ON nexus."time_entry_versions" ("organization_id", "project_id", "time_entry_id");
CREATE INDEX "ix_time_entry_versions_4" ON nexus."time_entry_versions" ("organization_id", "actor_id");
CREATE INDEX "ix_approvals_3" ON nexus."approvals" ("organization_id", "project_id", "time_entry_id");
CREATE INDEX "ix_approvals_4" ON nexus."approvals" ("organization_id", "project_id", "card_id");
CREATE INDEX "ix_approvals_5" ON nexus."approvals" ("organization_id", "requested_by");
CREATE INDEX "ix_approvals_6" ON nexus."approvals" ("organization_id", "reviewed_by");
CREATE INDEX "ix_calendar_events_2" ON nexus."calendar_events" ("organization_id", "project_id");
CREATE INDEX "ix_calendar_events_3" ON nexus."calendar_events" ("organization_id", "owner_id");
CREATE INDEX "ix_calendar_attendees_2" ON nexus."calendar_attendees" ("organization_id", "event_id");
CREATE INDEX "ix_calendar_attendees_3" ON nexus."calendar_attendees" ("organization_id", "membership_id");
CREATE INDEX "ix_tickets_2" ON nexus."tickets" ("organization_id", "project_id");
CREATE INDEX "ix_tickets_3" ON nexus."tickets" ("organization_id", "reporter_id");
CREATE INDEX "ix_tickets_4" ON nexus."tickets" ("organization_id", "assignee_id");
CREATE INDEX "ix_ticket_comments_2" ON nexus."ticket_comments" ("organization_id", "ticket_id");
CREATE INDEX "ix_ticket_comments_3" ON nexus."ticket_comments" ("organization_id", "author_id");
CREATE INDEX "ix_ticket_links_3" ON nexus."ticket_links" ("organization_id", "ticket_id");
CREATE INDEX "ix_ticket_links_4" ON nexus."ticket_links" ("organization_id", "project_id", "card_id");
CREATE INDEX "ix_card_templates_3" ON nexus."card_templates" ("organization_id", "created_by");
CREATE INDEX "ix_automation_rules_3" ON nexus."automation_rules" ("organization_id", "created_by");
CREATE INDEX "ix_automation_runs_3" ON nexus."automation_runs" ("organization_id", "project_id", "rule_id");
CREATE INDEX "ix_documents_2" ON nexus."documents" ("organization_id", "project_id");
CREATE INDEX "ix_documents_3" ON nexus."documents" ("organization_id", "owner_id");
CREATE INDEX "ix_document_versions_2" ON nexus."document_versions" ("organization_id", "document_id");
CREATE INDEX "ix_document_versions_3" ON nexus."document_versions" ("organization_id", "file_id");
CREATE INDEX "ix_document_versions_4" ON nexus."document_versions" ("organization_id", "created_by");
CREATE INDEX "ix_document_versions_5" ON nexus."document_versions" ("organization_id", "approved_by");
CREATE INDEX "ix_document_acl_2" ON nexus."document_acl" ("organization_id", "document_id");
CREATE INDEX "ix_document_acl_3" ON nexus."document_acl" ("organization_id", "membership_id");
CREATE INDEX "ix_index_jobs_2" ON nexus."index_jobs" ("organization_id", "document_version_id");
CREATE INDEX "ix_source_refs_2" ON nexus."source_refs" ("organization_id", "document_version_id");
CREATE INDEX "ix_courses_2" ON nexus."courses" ("organization_id", "owner_id");
CREATE INDEX "ix_course_versions_2" ON nexus."course_versions" ("organization_id", "course_id");
CREATE INDEX "ix_course_versions_3" ON nexus."course_versions" ("organization_id", "created_by");
CREATE INDEX "ix_course_versions_4" ON nexus."course_versions" ("organization_id", "approved_by");
CREATE INDEX "ix_path_courses_2" ON nexus."path_courses" ("organization_id", "path_id");
CREATE INDEX "ix_path_courses_3" ON nexus."path_courses" ("organization_id", "course_id");
CREATE INDEX "ix_course_modules_2" ON nexus."course_modules" ("organization_id", "course_version_id");
CREATE INDEX "ix_lessons_2" ON nexus."lessons" ("organization_id", "course_module_id");
CREATE INDEX "ix_lesson_resources_2" ON nexus."lesson_resources" ("organization_id", "lesson_id");
CREATE INDEX "ix_lesson_resources_3" ON nexus."lesson_resources" ("organization_id", "file_id");
CREATE INDEX "ix_lesson_resources_4" ON nexus."lesson_resources" ("organization_id", "document_version_id");
CREATE INDEX "ix_enrollments_2" ON nexus."enrollments" ("organization_id", "course_version_id");
CREATE INDEX "ix_enrollments_3" ON nexus."enrollments" ("organization_id", "membership_id");
CREATE INDEX "ix_enrollments_4" ON nexus."enrollments" ("organization_id", "assigned_by");
CREATE INDEX "ix_lesson_progress_2" ON nexus."lesson_progress" ("organization_id", "enrollment_id");
CREATE INDEX "ix_lesson_progress_3" ON nexus."lesson_progress" ("organization_id", "lesson_id");
CREATE INDEX "ix_assessments_2" ON nexus."assessments" ("organization_id", "course_version_id");
CREATE INDEX "ix_assessments_3" ON nexus."assessments" ("organization_id", "lesson_id");
CREATE INDEX "ix_assessment_questions_2" ON nexus."assessment_questions" ("organization_id", "assessment_id");
CREATE INDEX "ix_assessment_answer_keys_2" ON nexus."assessment_answer_keys" ("organization_id", "question_id");
CREATE INDEX "ix_attempts_2" ON nexus."attempts" ("organization_id", "enrollment_id");
CREATE INDEX "ix_attempts_3" ON nexus."attempts" ("organization_id", "assessment_id");
CREATE INDEX "ix_attempt_answers_2" ON nexus."attempt_answers" ("organization_id", "attempt_id");
CREATE INDEX "ix_attempt_answers_3" ON nexus."attempt_answers" ("organization_id", "question_id");
CREATE INDEX "ix_attempt_answers_4" ON nexus."attempt_answers" ("organization_id", "file_id");
CREATE INDEX "ix_mentoring_sessions_2" ON nexus."mentoring_sessions" ("organization_id", "mentor_id");
CREATE INDEX "ix_mentoring_sessions_3" ON nexus."mentoring_sessions" ("organization_id", "student_id");
CREATE INDEX "ix_forum_posts_3" ON nexus."forum_posts" ("organization_id", "author_id");
CREATE INDEX "ix_forum_posts_4" ON nexus."forum_posts" ("organization_id", "parent_post_id");
CREATE INDEX "ix_forum_posts_5" ON nexus."forum_posts" ("organization_id", "course_id", "parent_post_id");
CREATE INDEX "ix_member_achievements_2" ON nexus."member_achievements" ("organization_id", "achievement_id");
CREATE INDEX "ix_member_achievements_3" ON nexus."member_achievements" ("organization_id", "membership_id");
CREATE INDEX "ix_certificates_2" ON nexus."certificates" ("organization_id", "enrollment_id");
CREATE INDEX "ix_certificates_3" ON nexus."certificates" ("organization_id", "file_id");
CREATE INDEX "ix_conversations_2" ON nexus."conversations" ("organization_id", "owner_id");
CREATE INDEX "ix_conversations_3" ON nexus."conversations" ("organization_id", "project_id");
CREATE INDEX "ix_messages_2" ON nexus."messages" ("organization_id", "conversation_id");
CREATE INDEX "ix_citations_2" ON nexus."citations" ("organization_id", "message_id");
CREATE INDEX "ix_citations_3" ON nexus."citations" ("organization_id", "source_ref_id");
CREATE INDEX "ix_citations_4" ON nexus."citations" ("organization_id", "card_id");
CREATE INDEX "ix_tool_runs_2" ON nexus."tool_runs" ("organization_id", "conversation_id");
CREATE INDEX "ix_tool_runs_3" ON nexus."tool_runs" ("organization_id", "message_id");
CREATE INDEX "ix_action_previews_2" ON nexus."action_previews" ("organization_id", "conversation_id");
CREATE INDEX "ix_action_previews_3" ON nexus."action_previews" ("organization_id", "requested_by");
CREATE INDEX "ix_speech_sessions_2" ON nexus."speech_sessions" ("organization_id", "membership_id");
CREATE INDEX "ix_speech_sessions_3" ON nexus."speech_sessions" ("organization_id", "conversation_id");
CREATE INDEX "ix_predictions_2" ON nexus."predictions" ("organization_id", "model_version_id");
CREATE INDEX "ix_predictions_3" ON nexus."predictions" ("organization_id", "requested_by");
CREATE INDEX "ix_predictions_4" ON nexus."predictions" ("organization_id", "project_id");
CREATE INDEX "ix_predictions_5" ON nexus."predictions" ("organization_id", "card_id");
CREATE INDEX "ix_predictions_6" ON nexus."predictions" ("organization_id", "project_id", "card_id");
CREATE INDEX "ix_usage_records_2" ON nexus."usage_records" ("organization_id", "membership_id");
CREATE INDEX "ix_plans_2" ON nexus."plans" ("organization_id", "service_id");
CREATE INDEX "ix_plan_versions_2" ON nexus."plan_versions" ("organization_id", "plan_id");
CREATE INDEX "ix_plan_versions_3" ON nexus."plan_versions" ("organization_id", "created_by");
CREATE INDEX "ix_plan_versions_4" ON nexus."plan_versions" ("organization_id", "approved_by");
CREATE INDEX "ix_quotes_2" ON nexus."quotes" ("organization_id", "lead_id");
CREATE INDEX "ix_quotes_3" ON nexus."quotes" ("organization_id", "created_by");
CREATE INDEX "ix_quote_items_2" ON nexus."quote_items" ("organization_id", "quote_id");
CREATE INDEX "ix_quote_items_3" ON nexus."quote_items" ("organization_id", "plan_version_id");
CREATE INDEX "ix_notifications_2" ON nexus."notifications" ("organization_id", "recipient_id");
CREATE INDEX "ix_notifications_3" ON nexus."notifications" ("recipient_id", "read_at", "created_at");
CREATE INDEX "ix_notification_preferences_2" ON nexus."notification_preferences" ("organization_id", "membership_id");
CREATE INDEX "ix_audit_events_2" ON nexus."audit_events" ("organization_id", "actor_id");
CREATE INDEX "ix_audit_events_3" ON nexus."audit_events" ("organization_id", "project_id");
CREATE INDEX "ix_outbox_2" ON nexus."outbox" ("status", "available_at");
CREATE INDEX "ix_jobs_2" ON nexus."jobs" ("status", "run_after");
CREATE INDEX "ix_import_batches_2" ON nexus."import_batches" ("organization_id", "file_id");
CREATE INDEX "ix_import_batches_3" ON nexus."import_batches" ("organization_id", "requested_by");
CREATE INDEX "ix_import_rows_2" ON nexus."import_rows" ("organization_id", "batch_id");
CREATE INDEX "ix_import_rows_3" ON nexus."import_rows" ("organization_id", "card_id");
CREATE INDEX "ix_historical_task_facts_2" ON nexus."historical_task_facts" ("organization_id", "batch_id");
CREATE INDEX "ix_historical_task_facts_3" ON nexus."historical_task_facts" ("organization_id", "external_project_id");
CREATE INDEX "ix_historical_task_facts_4" ON nexus."historical_task_facts" ("organization_id", "source_status");
CREATE INDEX "ix_export_jobs_2" ON nexus."export_jobs" ("organization_id", "requested_by");
CREATE INDEX "ix_export_jobs_3" ON nexus."export_jobs" ("organization_id", "file_id");
CREATE INDEX "ix_integration_settings_2" ON nexus."integration_settings" ("organization_id", "updated_by");
CREATE INDEX "ix_idempotency_keys_2" ON nexus."idempotency_keys" ("organization_id", "membership_id");

CREATE FUNCTION nexus.touch_updated_at() RETURNS trigger LANGUAGE plpgsql SET search_path = pg_catalog AS $$
BEGIN NEW.updated_at := now(); RETURN NEW; END; $$;
REVOKE ALL ON FUNCTION nexus.touch_updated_at() FROM PUBLIC;

CREATE TRIGGER touch_updated_at BEFORE UPDATE ON nexus."organizations" FOR EACH ROW EXECUTE FUNCTION nexus.touch_updated_at();
ALTER TABLE nexus."organizations" ENABLE ROW LEVEL SECURITY;
ALTER TABLE nexus."organizations" FORCE ROW LEVEL SECURITY;
CREATE TRIGGER touch_updated_at BEFORE UPDATE ON nexus."profiles" FOR EACH ROW EXECUTE FUNCTION nexus.touch_updated_at();
ALTER TABLE nexus."profiles" ENABLE ROW LEVEL SECURITY;
ALTER TABLE nexus."profiles" FORCE ROW LEVEL SECURITY;
CREATE TRIGGER touch_updated_at BEFORE UPDATE ON nexus."memberships" FOR EACH ROW EXECUTE FUNCTION nexus.touch_updated_at();
ALTER TABLE nexus."memberships" ENABLE ROW LEVEL SECURITY;
ALTER TABLE nexus."memberships" FORCE ROW LEVEL SECURITY;
CREATE TRIGGER touch_updated_at BEFORE UPDATE ON nexus."roles" FOR EACH ROW EXECUTE FUNCTION nexus.touch_updated_at();
ALTER TABLE nexus."roles" ENABLE ROW LEVEL SECURITY;
ALTER TABLE nexus."roles" FORCE ROW LEVEL SECURITY;
CREATE TRIGGER touch_updated_at BEFORE UPDATE ON nexus."permissions" FOR EACH ROW EXECUTE FUNCTION nexus.touch_updated_at();
ALTER TABLE nexus."permissions" ENABLE ROW LEVEL SECURITY;
ALTER TABLE nexus."permissions" FORCE ROW LEVEL SECURITY;
CREATE TRIGGER touch_updated_at BEFORE UPDATE ON nexus."role_permissions" FOR EACH ROW EXECUTE FUNCTION nexus.touch_updated_at();
ALTER TABLE nexus."role_permissions" ENABLE ROW LEVEL SECURITY;
ALTER TABLE nexus."role_permissions" FORCE ROW LEVEL SECURITY;
CREATE TRIGGER touch_updated_at BEFORE UPDATE ON nexus."role_grants" FOR EACH ROW EXECUTE FUNCTION nexus.touch_updated_at();
ALTER TABLE nexus."role_grants" ENABLE ROW LEVEL SECURITY;
ALTER TABLE nexus."role_grants" FORCE ROW LEVEL SECURITY;
CREATE TRIGGER touch_updated_at BEFORE UPDATE ON nexus."invitations" FOR EACH ROW EXECUTE FUNCTION nexus.touch_updated_at();
ALTER TABLE nexus."invitations" ENABLE ROW LEVEL SECURITY;
ALTER TABLE nexus."invitations" FORCE ROW LEVEL SECURITY;
CREATE TRIGGER touch_updated_at BEFORE UPDATE ON nexus."user_preferences" FOR EACH ROW EXECUTE FUNCTION nexus.touch_updated_at();
ALTER TABLE nexus."user_preferences" ENABLE ROW LEVEL SECURITY;
ALTER TABLE nexus."user_preferences" FORCE ROW LEVEL SECURITY;
CREATE TRIGGER touch_updated_at BEFORE UPDATE ON nexus."organization_settings" FOR EACH ROW EXECUTE FUNCTION nexus.touch_updated_at();
ALTER TABLE nexus."organization_settings" ENABLE ROW LEVEL SECURITY;
ALTER TABLE nexus."organization_settings" FORCE ROW LEVEL SECURITY;
CREATE TRIGGER touch_updated_at BEFORE UPDATE ON nexus."teams" FOR EACH ROW EXECUTE FUNCTION nexus.touch_updated_at();
ALTER TABLE nexus."teams" ENABLE ROW LEVEL SECURITY;
ALTER TABLE nexus."teams" FORCE ROW LEVEL SECURITY;
CREATE TRIGGER touch_updated_at BEFORE UPDATE ON nexus."team_members" FOR EACH ROW EXECUTE FUNCTION nexus.touch_updated_at();
ALTER TABLE nexus."team_members" ENABLE ROW LEVEL SECURITY;
ALTER TABLE nexus."team_members" FORCE ROW LEVEL SECURITY;
CREATE TRIGGER touch_updated_at BEFORE UPDATE ON nexus."availability" FOR EACH ROW EXECUTE FUNCTION nexus.touch_updated_at();
ALTER TABLE nexus."availability" ENABLE ROW LEVEL SECURITY;
ALTER TABLE nexus."availability" FORCE ROW LEVEL SECURITY;
CREATE TRIGGER touch_updated_at BEFORE UPDATE ON nexus."projects" FOR EACH ROW EXECUTE FUNCTION nexus.touch_updated_at();
ALTER TABLE nexus."projects" ENABLE ROW LEVEL SECURITY;
ALTER TABLE nexus."projects" FORCE ROW LEVEL SECURITY;
CREATE TRIGGER touch_updated_at BEFORE UPDATE ON nexus."project_members" FOR EACH ROW EXECUTE FUNCTION nexus.touch_updated_at();
ALTER TABLE nexus."project_members" ENABLE ROW LEVEL SECURITY;
ALTER TABLE nexus."project_members" FORCE ROW LEVEL SECURITY;
CREATE TRIGGER touch_updated_at BEFORE UPDATE ON nexus."milestones" FOR EACH ROW EXECUTE FUNCTION nexus.touch_updated_at();
ALTER TABLE nexus."milestones" ENABLE ROW LEVEL SECURITY;
ALTER TABLE nexus."milestones" FORCE ROW LEVEL SECURITY;
CREATE TRIGGER touch_updated_at BEFORE UPDATE ON nexus."boards" FOR EACH ROW EXECUTE FUNCTION nexus.touch_updated_at();
ALTER TABLE nexus."boards" ENABLE ROW LEVEL SECURITY;
ALTER TABLE nexus."boards" FORCE ROW LEVEL SECURITY;
CREATE TRIGGER touch_updated_at BEFORE UPDATE ON nexus."board_columns" FOR EACH ROW EXECUTE FUNCTION nexus.touch_updated_at();
ALTER TABLE nexus."board_columns" ENABLE ROW LEVEL SECURITY;
ALTER TABLE nexus."board_columns" FORCE ROW LEVEL SECURITY;
CREATE TRIGGER touch_updated_at BEFORE UPDATE ON nexus."cards" FOR EACH ROW EXECUTE FUNCTION nexus.touch_updated_at();
ALTER TABLE nexus."cards" ENABLE ROW LEVEL SECURITY;
ALTER TABLE nexus."cards" FORCE ROW LEVEL SECURITY;
CREATE TRIGGER touch_updated_at BEFORE UPDATE ON nexus."card_assignees" FOR EACH ROW EXECUTE FUNCTION nexus.touch_updated_at();
ALTER TABLE nexus."card_assignees" ENABLE ROW LEVEL SECURITY;
ALTER TABLE nexus."card_assignees" FORCE ROW LEVEL SECURITY;
CREATE TRIGGER touch_updated_at BEFORE UPDATE ON nexus."labels" FOR EACH ROW EXECUTE FUNCTION nexus.touch_updated_at();
ALTER TABLE nexus."labels" ENABLE ROW LEVEL SECURITY;
ALTER TABLE nexus."labels" FORCE ROW LEVEL SECURITY;
CREATE TRIGGER touch_updated_at BEFORE UPDATE ON nexus."card_labels" FOR EACH ROW EXECUTE FUNCTION nexus.touch_updated_at();
ALTER TABLE nexus."card_labels" ENABLE ROW LEVEL SECURITY;
ALTER TABLE nexus."card_labels" FORCE ROW LEVEL SECURITY;
CREATE TRIGGER touch_updated_at BEFORE UPDATE ON nexus."field_definitions" FOR EACH ROW EXECUTE FUNCTION nexus.touch_updated_at();
ALTER TABLE nexus."field_definitions" ENABLE ROW LEVEL SECURITY;
ALTER TABLE nexus."field_definitions" FORCE ROW LEVEL SECURITY;
CREATE TRIGGER touch_updated_at BEFORE UPDATE ON nexus."field_values" FOR EACH ROW EXECUTE FUNCTION nexus.touch_updated_at();
ALTER TABLE nexus."field_values" ENABLE ROW LEVEL SECURITY;
ALTER TABLE nexus."field_values" FORCE ROW LEVEL SECURITY;
CREATE TRIGGER touch_updated_at BEFORE UPDATE ON nexus."checklists" FOR EACH ROW EXECUTE FUNCTION nexus.touch_updated_at();
ALTER TABLE nexus."checklists" ENABLE ROW LEVEL SECURITY;
ALTER TABLE nexus."checklists" FORCE ROW LEVEL SECURITY;
CREATE TRIGGER touch_updated_at BEFORE UPDATE ON nexus."checklist_items" FOR EACH ROW EXECUTE FUNCTION nexus.touch_updated_at();
ALTER TABLE nexus."checklist_items" ENABLE ROW LEVEL SECURITY;
ALTER TABLE nexus."checklist_items" FORCE ROW LEVEL SECURITY;
CREATE TRIGGER touch_updated_at BEFORE UPDATE ON nexus."card_dependencies" FOR EACH ROW EXECUTE FUNCTION nexus.touch_updated_at();
ALTER TABLE nexus."card_dependencies" ENABLE ROW LEVEL SECURITY;
ALTER TABLE nexus."card_dependencies" FORCE ROW LEVEL SECURITY;
CREATE TRIGGER touch_updated_at BEFORE UPDATE ON nexus."comments" FOR EACH ROW EXECUTE FUNCTION nexus.touch_updated_at();
ALTER TABLE nexus."comments" ENABLE ROW LEVEL SECURITY;
ALTER TABLE nexus."comments" FORCE ROW LEVEL SECURITY;
CREATE TRIGGER touch_updated_at BEFORE UPDATE ON nexus."comment_mentions" FOR EACH ROW EXECUTE FUNCTION nexus.touch_updated_at();
ALTER TABLE nexus."comment_mentions" ENABLE ROW LEVEL SECURITY;
ALTER TABLE nexus."comment_mentions" FORCE ROW LEVEL SECURITY;
CREATE TRIGGER touch_updated_at BEFORE UPDATE ON nexus."comment_reactions" FOR EACH ROW EXECUTE FUNCTION nexus.touch_updated_at();
ALTER TABLE nexus."comment_reactions" ENABLE ROW LEVEL SECURITY;
ALTER TABLE nexus."comment_reactions" FORCE ROW LEVEL SECURITY;
CREATE TRIGGER touch_updated_at BEFORE UPDATE ON nexus."files" FOR EACH ROW EXECUTE FUNCTION nexus.touch_updated_at();
ALTER TABLE nexus."files" ENABLE ROW LEVEL SECURITY;
ALTER TABLE nexus."files" FORCE ROW LEVEL SECURITY;
CREATE TRIGGER touch_updated_at BEFORE UPDATE ON nexus."attachments" FOR EACH ROW EXECUTE FUNCTION nexus.touch_updated_at();
ALTER TABLE nexus."attachments" ENABLE ROW LEVEL SECURITY;
ALTER TABLE nexus."attachments" FORCE ROW LEVEL SECURITY;
CREATE TRIGGER touch_updated_at BEFORE UPDATE ON nexus."card_watchers" FOR EACH ROW EXECUTE FUNCTION nexus.touch_updated_at();
ALTER TABLE nexus."card_watchers" ENABLE ROW LEVEL SECURITY;
ALTER TABLE nexus."card_watchers" FORCE ROW LEVEL SECURITY;
ALTER TABLE nexus."card_events" ENABLE ROW LEVEL SECURITY;
ALTER TABLE nexus."card_events" FORCE ROW LEVEL SECURITY;
CREATE TRIGGER touch_updated_at BEFORE UPDATE ON nexus."timers" FOR EACH ROW EXECUTE FUNCTION nexus.touch_updated_at();
ALTER TABLE nexus."timers" ENABLE ROW LEVEL SECURITY;
ALTER TABLE nexus."timers" FORCE ROW LEVEL SECURITY;
CREATE TRIGGER touch_updated_at BEFORE UPDATE ON nexus."time_entries" FOR EACH ROW EXECUTE FUNCTION nexus.touch_updated_at();
ALTER TABLE nexus."time_entries" ENABLE ROW LEVEL SECURITY;
ALTER TABLE nexus."time_entries" FORCE ROW LEVEL SECURITY;
ALTER TABLE nexus."time_entry_versions" ENABLE ROW LEVEL SECURITY;
ALTER TABLE nexus."time_entry_versions" FORCE ROW LEVEL SECURITY;
CREATE TRIGGER touch_updated_at BEFORE UPDATE ON nexus."approvals" FOR EACH ROW EXECUTE FUNCTION nexus.touch_updated_at();
ALTER TABLE nexus."approvals" ENABLE ROW LEVEL SECURITY;
ALTER TABLE nexus."approvals" FORCE ROW LEVEL SECURITY;
CREATE TRIGGER touch_updated_at BEFORE UPDATE ON nexus."calendar_events" FOR EACH ROW EXECUTE FUNCTION nexus.touch_updated_at();
ALTER TABLE nexus."calendar_events" ENABLE ROW LEVEL SECURITY;
ALTER TABLE nexus."calendar_events" FORCE ROW LEVEL SECURITY;
CREATE TRIGGER touch_updated_at BEFORE UPDATE ON nexus."calendar_attendees" FOR EACH ROW EXECUTE FUNCTION nexus.touch_updated_at();
ALTER TABLE nexus."calendar_attendees" ENABLE ROW LEVEL SECURITY;
ALTER TABLE nexus."calendar_attendees" FORCE ROW LEVEL SECURITY;
CREATE TRIGGER touch_updated_at BEFORE UPDATE ON nexus."tickets" FOR EACH ROW EXECUTE FUNCTION nexus.touch_updated_at();
ALTER TABLE nexus."tickets" ENABLE ROW LEVEL SECURITY;
ALTER TABLE nexus."tickets" FORCE ROW LEVEL SECURITY;
CREATE TRIGGER touch_updated_at BEFORE UPDATE ON nexus."ticket_comments" FOR EACH ROW EXECUTE FUNCTION nexus.touch_updated_at();
ALTER TABLE nexus."ticket_comments" ENABLE ROW LEVEL SECURITY;
ALTER TABLE nexus."ticket_comments" FORCE ROW LEVEL SECURITY;
CREATE TRIGGER touch_updated_at BEFORE UPDATE ON nexus."ticket_links" FOR EACH ROW EXECUTE FUNCTION nexus.touch_updated_at();
ALTER TABLE nexus."ticket_links" ENABLE ROW LEVEL SECURITY;
ALTER TABLE nexus."ticket_links" FORCE ROW LEVEL SECURITY;
CREATE TRIGGER touch_updated_at BEFORE UPDATE ON nexus."card_templates" FOR EACH ROW EXECUTE FUNCTION nexus.touch_updated_at();
ALTER TABLE nexus."card_templates" ENABLE ROW LEVEL SECURITY;
ALTER TABLE nexus."card_templates" FORCE ROW LEVEL SECURITY;
CREATE TRIGGER touch_updated_at BEFORE UPDATE ON nexus."automation_rules" FOR EACH ROW EXECUTE FUNCTION nexus.touch_updated_at();
ALTER TABLE nexus."automation_rules" ENABLE ROW LEVEL SECURITY;
ALTER TABLE nexus."automation_rules" FORCE ROW LEVEL SECURITY;
CREATE TRIGGER touch_updated_at BEFORE UPDATE ON nexus."automation_runs" FOR EACH ROW EXECUTE FUNCTION nexus.touch_updated_at();
ALTER TABLE nexus."automation_runs" ENABLE ROW LEVEL SECURITY;
ALTER TABLE nexus."automation_runs" FORCE ROW LEVEL SECURITY;
CREATE TRIGGER touch_updated_at BEFORE UPDATE ON nexus."documents" FOR EACH ROW EXECUTE FUNCTION nexus.touch_updated_at();
ALTER TABLE nexus."documents" ENABLE ROW LEVEL SECURITY;
ALTER TABLE nexus."documents" FORCE ROW LEVEL SECURITY;
CREATE TRIGGER touch_updated_at BEFORE UPDATE ON nexus."document_versions" FOR EACH ROW EXECUTE FUNCTION nexus.touch_updated_at();
ALTER TABLE nexus."document_versions" ENABLE ROW LEVEL SECURITY;
ALTER TABLE nexus."document_versions" FORCE ROW LEVEL SECURITY;
CREATE TRIGGER touch_updated_at BEFORE UPDATE ON nexus."document_acl" FOR EACH ROW EXECUTE FUNCTION nexus.touch_updated_at();
ALTER TABLE nexus."document_acl" ENABLE ROW LEVEL SECURITY;
ALTER TABLE nexus."document_acl" FORCE ROW LEVEL SECURITY;
CREATE TRIGGER touch_updated_at BEFORE UPDATE ON nexus."index_jobs" FOR EACH ROW EXECUTE FUNCTION nexus.touch_updated_at();
ALTER TABLE nexus."index_jobs" ENABLE ROW LEVEL SECURITY;
ALTER TABLE nexus."index_jobs" FORCE ROW LEVEL SECURITY;
CREATE TRIGGER touch_updated_at BEFORE UPDATE ON nexus."source_refs" FOR EACH ROW EXECUTE FUNCTION nexus.touch_updated_at();
ALTER TABLE nexus."source_refs" ENABLE ROW LEVEL SECURITY;
ALTER TABLE nexus."source_refs" FORCE ROW LEVEL SECURITY;
CREATE TRIGGER touch_updated_at BEFORE UPDATE ON nexus."learning_paths" FOR EACH ROW EXECUTE FUNCTION nexus.touch_updated_at();
ALTER TABLE nexus."learning_paths" ENABLE ROW LEVEL SECURITY;
ALTER TABLE nexus."learning_paths" FORCE ROW LEVEL SECURITY;
CREATE TRIGGER touch_updated_at BEFORE UPDATE ON nexus."courses" FOR EACH ROW EXECUTE FUNCTION nexus.touch_updated_at();
ALTER TABLE nexus."courses" ENABLE ROW LEVEL SECURITY;
ALTER TABLE nexus."courses" FORCE ROW LEVEL SECURITY;
CREATE TRIGGER touch_updated_at BEFORE UPDATE ON nexus."course_versions" FOR EACH ROW EXECUTE FUNCTION nexus.touch_updated_at();
ALTER TABLE nexus."course_versions" ENABLE ROW LEVEL SECURITY;
ALTER TABLE nexus."course_versions" FORCE ROW LEVEL SECURITY;
CREATE TRIGGER touch_updated_at BEFORE UPDATE ON nexus."path_courses" FOR EACH ROW EXECUTE FUNCTION nexus.touch_updated_at();
ALTER TABLE nexus."path_courses" ENABLE ROW LEVEL SECURITY;
ALTER TABLE nexus."path_courses" FORCE ROW LEVEL SECURITY;
CREATE TRIGGER touch_updated_at BEFORE UPDATE ON nexus."course_modules" FOR EACH ROW EXECUTE FUNCTION nexus.touch_updated_at();
ALTER TABLE nexus."course_modules" ENABLE ROW LEVEL SECURITY;
ALTER TABLE nexus."course_modules" FORCE ROW LEVEL SECURITY;
CREATE TRIGGER touch_updated_at BEFORE UPDATE ON nexus."lessons" FOR EACH ROW EXECUTE FUNCTION nexus.touch_updated_at();
ALTER TABLE nexus."lessons" ENABLE ROW LEVEL SECURITY;
ALTER TABLE nexus."lessons" FORCE ROW LEVEL SECURITY;
CREATE TRIGGER touch_updated_at BEFORE UPDATE ON nexus."lesson_resources" FOR EACH ROW EXECUTE FUNCTION nexus.touch_updated_at();
ALTER TABLE nexus."lesson_resources" ENABLE ROW LEVEL SECURITY;
ALTER TABLE nexus."lesson_resources" FORCE ROW LEVEL SECURITY;
CREATE TRIGGER touch_updated_at BEFORE UPDATE ON nexus."enrollments" FOR EACH ROW EXECUTE FUNCTION nexus.touch_updated_at();
ALTER TABLE nexus."enrollments" ENABLE ROW LEVEL SECURITY;
ALTER TABLE nexus."enrollments" FORCE ROW LEVEL SECURITY;
CREATE TRIGGER touch_updated_at BEFORE UPDATE ON nexus."lesson_progress" FOR EACH ROW EXECUTE FUNCTION nexus.touch_updated_at();
ALTER TABLE nexus."lesson_progress" ENABLE ROW LEVEL SECURITY;
ALTER TABLE nexus."lesson_progress" FORCE ROW LEVEL SECURITY;
CREATE TRIGGER touch_updated_at BEFORE UPDATE ON nexus."assessments" FOR EACH ROW EXECUTE FUNCTION nexus.touch_updated_at();
ALTER TABLE nexus."assessments" ENABLE ROW LEVEL SECURITY;
ALTER TABLE nexus."assessments" FORCE ROW LEVEL SECURITY;
CREATE TRIGGER touch_updated_at BEFORE UPDATE ON nexus."assessment_questions" FOR EACH ROW EXECUTE FUNCTION nexus.touch_updated_at();
ALTER TABLE nexus."assessment_questions" ENABLE ROW LEVEL SECURITY;
ALTER TABLE nexus."assessment_questions" FORCE ROW LEVEL SECURITY;
CREATE TRIGGER touch_updated_at BEFORE UPDATE ON nexus."assessment_answer_keys" FOR EACH ROW EXECUTE FUNCTION nexus.touch_updated_at();
ALTER TABLE nexus."assessment_answer_keys" ENABLE ROW LEVEL SECURITY;
ALTER TABLE nexus."assessment_answer_keys" FORCE ROW LEVEL SECURITY;
CREATE TRIGGER touch_updated_at BEFORE UPDATE ON nexus."attempts" FOR EACH ROW EXECUTE FUNCTION nexus.touch_updated_at();
ALTER TABLE nexus."attempts" ENABLE ROW LEVEL SECURITY;
ALTER TABLE nexus."attempts" FORCE ROW LEVEL SECURITY;
CREATE TRIGGER touch_updated_at BEFORE UPDATE ON nexus."attempt_answers" FOR EACH ROW EXECUTE FUNCTION nexus.touch_updated_at();
ALTER TABLE nexus."attempt_answers" ENABLE ROW LEVEL SECURITY;
ALTER TABLE nexus."attempt_answers" FORCE ROW LEVEL SECURITY;
CREATE TRIGGER touch_updated_at BEFORE UPDATE ON nexus."mentoring_sessions" FOR EACH ROW EXECUTE FUNCTION nexus.touch_updated_at();
ALTER TABLE nexus."mentoring_sessions" ENABLE ROW LEVEL SECURITY;
ALTER TABLE nexus."mentoring_sessions" FORCE ROW LEVEL SECURITY;
CREATE TRIGGER touch_updated_at BEFORE UPDATE ON nexus."forum_posts" FOR EACH ROW EXECUTE FUNCTION nexus.touch_updated_at();
ALTER TABLE nexus."forum_posts" ENABLE ROW LEVEL SECURITY;
ALTER TABLE nexus."forum_posts" FORCE ROW LEVEL SECURITY;
CREATE TRIGGER touch_updated_at BEFORE UPDATE ON nexus."achievements" FOR EACH ROW EXECUTE FUNCTION nexus.touch_updated_at();
ALTER TABLE nexus."achievements" ENABLE ROW LEVEL SECURITY;
ALTER TABLE nexus."achievements" FORCE ROW LEVEL SECURITY;
CREATE TRIGGER touch_updated_at BEFORE UPDATE ON nexus."member_achievements" FOR EACH ROW EXECUTE FUNCTION nexus.touch_updated_at();
ALTER TABLE nexus."member_achievements" ENABLE ROW LEVEL SECURITY;
ALTER TABLE nexus."member_achievements" FORCE ROW LEVEL SECURITY;
CREATE TRIGGER touch_updated_at BEFORE UPDATE ON nexus."certificates" FOR EACH ROW EXECUTE FUNCTION nexus.touch_updated_at();
ALTER TABLE nexus."certificates" ENABLE ROW LEVEL SECURITY;
ALTER TABLE nexus."certificates" FORCE ROW LEVEL SECURITY;
CREATE TRIGGER touch_updated_at BEFORE UPDATE ON nexus."conversations" FOR EACH ROW EXECUTE FUNCTION nexus.touch_updated_at();
ALTER TABLE nexus."conversations" ENABLE ROW LEVEL SECURITY;
ALTER TABLE nexus."conversations" FORCE ROW LEVEL SECURITY;
CREATE TRIGGER touch_updated_at BEFORE UPDATE ON nexus."messages" FOR EACH ROW EXECUTE FUNCTION nexus.touch_updated_at();
ALTER TABLE nexus."messages" ENABLE ROW LEVEL SECURITY;
ALTER TABLE nexus."messages" FORCE ROW LEVEL SECURITY;
CREATE TRIGGER touch_updated_at BEFORE UPDATE ON nexus."citations" FOR EACH ROW EXECUTE FUNCTION nexus.touch_updated_at();
ALTER TABLE nexus."citations" ENABLE ROW LEVEL SECURITY;
ALTER TABLE nexus."citations" FORCE ROW LEVEL SECURITY;
CREATE TRIGGER touch_updated_at BEFORE UPDATE ON nexus."tool_runs" FOR EACH ROW EXECUTE FUNCTION nexus.touch_updated_at();
ALTER TABLE nexus."tool_runs" ENABLE ROW LEVEL SECURITY;
ALTER TABLE nexus."tool_runs" FORCE ROW LEVEL SECURITY;
CREATE TRIGGER touch_updated_at BEFORE UPDATE ON nexus."action_previews" FOR EACH ROW EXECUTE FUNCTION nexus.touch_updated_at();
ALTER TABLE nexus."action_previews" ENABLE ROW LEVEL SECURITY;
ALTER TABLE nexus."action_previews" FORCE ROW LEVEL SECURITY;
CREATE TRIGGER touch_updated_at BEFORE UPDATE ON nexus."speech_sessions" FOR EACH ROW EXECUTE FUNCTION nexus.touch_updated_at();
ALTER TABLE nexus."speech_sessions" ENABLE ROW LEVEL SECURITY;
ALTER TABLE nexus."speech_sessions" FORCE ROW LEVEL SECURITY;
CREATE TRIGGER touch_updated_at BEFORE UPDATE ON nexus."model_versions" FOR EACH ROW EXECUTE FUNCTION nexus.touch_updated_at();
ALTER TABLE nexus."model_versions" ENABLE ROW LEVEL SECURITY;
ALTER TABLE nexus."model_versions" FORCE ROW LEVEL SECURITY;
CREATE TRIGGER touch_updated_at BEFORE UPDATE ON nexus."predictions" FOR EACH ROW EXECUTE FUNCTION nexus.touch_updated_at();
ALTER TABLE nexus."predictions" ENABLE ROW LEVEL SECURITY;
ALTER TABLE nexus."predictions" FORCE ROW LEVEL SECURITY;
ALTER TABLE nexus."usage_records" ENABLE ROW LEVEL SECURITY;
ALTER TABLE nexus."usage_records" FORCE ROW LEVEL SECURITY;
CREATE TRIGGER touch_updated_at BEFORE UPDATE ON nexus."services" FOR EACH ROW EXECUTE FUNCTION nexus.touch_updated_at();
ALTER TABLE nexus."services" ENABLE ROW LEVEL SECURITY;
ALTER TABLE nexus."services" FORCE ROW LEVEL SECURITY;
CREATE TRIGGER touch_updated_at BEFORE UPDATE ON nexus."plans" FOR EACH ROW EXECUTE FUNCTION nexus.touch_updated_at();
ALTER TABLE nexus."plans" ENABLE ROW LEVEL SECURITY;
ALTER TABLE nexus."plans" FORCE ROW LEVEL SECURITY;
CREATE TRIGGER touch_updated_at BEFORE UPDATE ON nexus."plan_versions" FOR EACH ROW EXECUTE FUNCTION nexus.touch_updated_at();
ALTER TABLE nexus."plan_versions" ENABLE ROW LEVEL SECURITY;
ALTER TABLE nexus."plan_versions" FORCE ROW LEVEL SECURITY;
CREATE TRIGGER touch_updated_at BEFORE UPDATE ON nexus."leads" FOR EACH ROW EXECUTE FUNCTION nexus.touch_updated_at();
ALTER TABLE nexus."leads" ENABLE ROW LEVEL SECURITY;
ALTER TABLE nexus."leads" FORCE ROW LEVEL SECURITY;
CREATE TRIGGER touch_updated_at BEFORE UPDATE ON nexus."quotes" FOR EACH ROW EXECUTE FUNCTION nexus.touch_updated_at();
ALTER TABLE nexus."quotes" ENABLE ROW LEVEL SECURITY;
ALTER TABLE nexus."quotes" FORCE ROW LEVEL SECURITY;
CREATE TRIGGER touch_updated_at BEFORE UPDATE ON nexus."quote_items" FOR EACH ROW EXECUTE FUNCTION nexus.touch_updated_at();
ALTER TABLE nexus."quote_items" ENABLE ROW LEVEL SECURITY;
ALTER TABLE nexus."quote_items" FORCE ROW LEVEL SECURITY;
CREATE TRIGGER touch_updated_at BEFORE UPDATE ON nexus."notifications" FOR EACH ROW EXECUTE FUNCTION nexus.touch_updated_at();
ALTER TABLE nexus."notifications" ENABLE ROW LEVEL SECURITY;
ALTER TABLE nexus."notifications" FORCE ROW LEVEL SECURITY;
CREATE TRIGGER touch_updated_at BEFORE UPDATE ON nexus."notification_preferences" FOR EACH ROW EXECUTE FUNCTION nexus.touch_updated_at();
ALTER TABLE nexus."notification_preferences" ENABLE ROW LEVEL SECURITY;
ALTER TABLE nexus."notification_preferences" FORCE ROW LEVEL SECURITY;
ALTER TABLE nexus."audit_events" ENABLE ROW LEVEL SECURITY;
ALTER TABLE nexus."audit_events" FORCE ROW LEVEL SECURITY;
CREATE TRIGGER touch_updated_at BEFORE UPDATE ON nexus."outbox" FOR EACH ROW EXECUTE FUNCTION nexus.touch_updated_at();
ALTER TABLE nexus."outbox" ENABLE ROW LEVEL SECURITY;
ALTER TABLE nexus."outbox" FORCE ROW LEVEL SECURITY;
CREATE TRIGGER touch_updated_at BEFORE UPDATE ON nexus."jobs" FOR EACH ROW EXECUTE FUNCTION nexus.touch_updated_at();
ALTER TABLE nexus."jobs" ENABLE ROW LEVEL SECURITY;
ALTER TABLE nexus."jobs" FORCE ROW LEVEL SECURITY;
CREATE TRIGGER touch_updated_at BEFORE UPDATE ON nexus."import_batches" FOR EACH ROW EXECUTE FUNCTION nexus.touch_updated_at();
ALTER TABLE nexus."import_batches" ENABLE ROW LEVEL SECURITY;
ALTER TABLE nexus."import_batches" FORCE ROW LEVEL SECURITY;
CREATE TRIGGER touch_updated_at BEFORE UPDATE ON nexus."import_rows" FOR EACH ROW EXECUTE FUNCTION nexus.touch_updated_at();
ALTER TABLE nexus."import_rows" ENABLE ROW LEVEL SECURITY;
ALTER TABLE nexus."import_rows" FORCE ROW LEVEL SECURITY;
CREATE TRIGGER touch_updated_at BEFORE UPDATE ON nexus."historical_task_facts" FOR EACH ROW EXECUTE FUNCTION nexus.touch_updated_at();
ALTER TABLE nexus."historical_task_facts" ENABLE ROW LEVEL SECURITY;
ALTER TABLE nexus."historical_task_facts" FORCE ROW LEVEL SECURITY;
CREATE TRIGGER touch_updated_at BEFORE UPDATE ON nexus."export_jobs" FOR EACH ROW EXECUTE FUNCTION nexus.touch_updated_at();
ALTER TABLE nexus."export_jobs" ENABLE ROW LEVEL SECURITY;
ALTER TABLE nexus."export_jobs" FORCE ROW LEVEL SECURITY;
CREATE TRIGGER touch_updated_at BEFORE UPDATE ON nexus."integration_settings" FOR EACH ROW EXECUTE FUNCTION nexus.touch_updated_at();
ALTER TABLE nexus."integration_settings" ENABLE ROW LEVEL SECURITY;
ALTER TABLE nexus."integration_settings" FORCE ROW LEVEL SECURITY;
CREATE TRIGGER touch_updated_at BEFORE UPDATE ON nexus."quota_limits" FOR EACH ROW EXECUTE FUNCTION nexus.touch_updated_at();
ALTER TABLE nexus."quota_limits" ENABLE ROW LEVEL SECURITY;
ALTER TABLE nexus."quota_limits" FORCE ROW LEVEL SECURITY;
CREATE TRIGGER touch_updated_at BEFORE UPDATE ON nexus."idempotency_keys" FOR EACH ROW EXECUTE FUNCTION nexus.touch_updated_at();
ALTER TABLE nexus."idempotency_keys" ENABLE ROW LEVEL SECURITY;
ALTER TABLE nexus."idempotency_keys" FORCE ROW LEVEL SECURITY;
REVOKE ALL ON ALL TABLES IN SCHEMA nexus FROM PUBLIC, anon, authenticated, service_role;
-- No policies created intentionally. See 03_RLS for the policy contract and examples.
COMMIT;
