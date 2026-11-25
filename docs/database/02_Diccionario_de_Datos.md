<div align="center">

# MTA NEXUS | Diccionario de datos

**Tablas, columnas, tipos, relaciones y restricciones**

![MTA: NEXUS](https://img.shields.io/static/v1?label=MTA&message=NEXUS&color=0A1A3A&style=for-the-badge) ![Documento: v1.0](https://img.shields.io/static/v1?label=Documento&message=v1.0&color=0066FF&style=for-the-badge) ![PostgreSQL: UUID / SQL](https://img.shields.io/static/v1?label=PostgreSQL&message=UUID%20/%20SQL&color=336791&style=for-the-badge) ![Tablas: 97](https://img.shields.io/static/v1?label=Tablas&message=97&color=0066FF&style=for-the-badge) ![RLS: Deny by default](https://img.shields.io/static/v1?label=RLS&message=Deny%20by%20default&color=166534&style=for-the-badge)

</div>

> Estado: propuesta técnica para implementación. No representa una base de datos desplegada ni una auditoría de seguridad completada.

---

## Cómo leer el diccionario

Cada tabla se ubica en `nexus`, esquema privado. `auth.users` pertenece a Supabase y no se redefine. PK = clave primaria, FK = clave foránea, UQ = unicidad, NN = no nulo. **Sí; default** significa NOT NULL con valor inicial. Las referencias se almacenan como UUID. Las fechas de trabajo son `date`; los instantes son `timestamptz`. Las descripciones se mantienen en español y los nombres físicos en inglés snake_case. La columna `id` es PK incluso en tablas puente; las combinaciones N:M tienen UQ propia.

**Inventario:** 97 tablas, 975 columnas (incluidas columnas compartidas), 288 restricciones FK explícitas. Los módulos dashboard, health y consultas de analytics son servicios de lectura; no necesitan tablas duplicadas. Los índices de FK y restricciones se detallan en el DDL de referencia.

## 01. Identidad, organización y permisos

[`organizations`](#organizations) | [`profiles`](#profiles) | [`memberships`](#memberships) | [`roles`](#roles) | [`permissions`](#permissions) | [`role_permissions`](#role_permissions) | [`role_grants`](#role_grants) | [`invitations`](#invitations) | [`user_preferences`](#user_preferences) | [`organization_settings`](#organization_settings) | [`teams`](#teams) | [`team_members`](#team_members) | [`availability`](#availability)

### organizations

![Fase: MVP](https://img.shields.io/static/v1?label=Fase&message=MVP&color=0066FF&style=for-the-badge) ![Ámbito: global](https://img.shields.io/static/v1?label=%C3%81mbito&message=global&color=0A1A3A&style=for-the-badge)

Espacio de trabajo y frontera de aislamiento.

| Columna SQL | Tipo PostgreSQL | Obligatorio / default | Descripción |
|---|---|---|---|
| `id` | `uuid` | Sí; `gen_random_uuid()` | Identificador interno opaco; PK. |
| `created_at` | `timestamptz` | Sí; `now()` | Fecha de creación UTC. |
| `updated_at` | `timestamptz` | Sí; `now()` | Última modificación; trigger de servidor. |
| `slug` | `text` | Sí | Identificador legible de la organización |
| `name` | `text` | Sí | Nombre comercial |
| `kind` | `text` | Sí; `'operational'` | operational o demo |
| `status` | `text` | Sí; `'active'` | active o suspended |
| `timezone` | `text` | Sí; `'America/Lima'` | Zona IANA de presentación |
| `currency` | `char(3)` | Sí; `'PEN'` | Moneda base ISO 4217 |

**Integridad:** PK `id`. UQ `(slug)`. CHECK: `kind IN ('operational','demo')`; `status IN ('active','suspended')`.

**Contrato de autorización:** Leer por membresía activa; configurar solo admin delegado; crear organización mediante bootstrap privilegiado.

---

### profiles

![Fase: MVP](https://img.shields.io/static/v1?label=Fase&message=MVP&color=0066FF&style=for-the-badge) ![Ámbito: global](https://img.shields.io/static/v1?label=%C3%81mbito&message=global&color=0A1A3A&style=for-the-badge)

Perfil humano vinculado a Supabase Auth; nunca guarda contraseñas.

| Columna SQL | Tipo PostgreSQL | Obligatorio / default | Descripción |
|---|---|---|---|
| `id` | `uuid` | Sí; `gen_random_uuid()` | Identificador interno opaco; PK. |
| `created_at` | `timestamptz` | Sí; `now()` | Fecha de creación UTC. |
| `updated_at` | `timestamptz` | Sí; `now()` | Última modificación; trigger de servidor. |
| `auth_user_id` | `uuid` | Sí | Identidad externa única → `auth.users` |
| `full_name` | `text` | Sí | Nombre de presentación |
| `avatar_path` | `text` | No | Ruta privada del avatar |
| `bio` | `text` | No | Descripción profesional |
| `status` | `text` | Sí; `'active'` | active, suspended o deactivated |

**Integridad:** PK `id`. UQ `(auth_user_id)`. CHECK: `status IN ('active','suspended','deactivated')`.

**FK (todas `ON DELETE RESTRICT`):**

- `(auth_user_id)` → `auth.users(id)`.

**Contrato de autorización:** Propietario lee y edita nombre/bio/avatar; directorio entrega proyección limitada de compañeros; suspensión por admin autorizado, no por propietario.

---

### memberships

![Fase: MVP](https://img.shields.io/static/v1?label=Fase&message=MVP&color=0066FF&style=for-the-badge) ![Ámbito: org](https://img.shields.io/static/v1?label=%C3%81mbito&message=org&color=0A1A3A&style=for-the-badge)

Participación vigente de un perfil en una organización.

| Columna SQL | Tipo PostgreSQL | Obligatorio / default | Descripción |
|---|---|---|---|
| `id` | `uuid` | Sí; `gen_random_uuid()` | Identificador interno opaco; PK. |
| `organization_id` | `uuid` | Sí | Frontera obligatoria de organización. → `organizations` |
| `created_at` | `timestamptz` | Sí; `now()` | Fecha de creación UTC. |
| `updated_at` | `timestamptz` | Sí; `now()` | Última modificación; trigger de servidor. |
| `profile_id` | `uuid` | Sí | Perfil asociado → `profiles` |
| `status` | `text` | Sí; `'invited'` | invited, active, suspended o left |
| `joined_at` | `timestamptz` | No | Fecha efectiva de ingreso |
| `left_at` | `timestamptz` | No | Fecha de baja |
| `specialty` | `text` | No | Especialidad profesional |

**Integridad:** PK `id`. UQ `(organization_id, id)`. UQ `(organization_id, profile_id)`. CHECK: `status IN ('invited','active','suspended','left')`.

**FK (todas `ON DELETE RESTRICT`):**

- `(organization_id)` → `organizations(id)`.
- `(profile_id)` → `profiles(id)`.

**Contrato de autorización:** Leer propia o directorio autorizado; modificar estado por administrador delegado sin autoescalamiento.

---

### roles

![Fase: MVP](https://img.shields.io/static/v1?label=Fase&message=MVP&color=0066FF&style=for-the-badge) ![Ámbito: org](https://img.shields.io/static/v1?label=%C3%81mbito&message=org&color=0A1A3A&style=for-the-badge)

Catálogo de roles de organización y proyecto.

| Columna SQL | Tipo PostgreSQL | Obligatorio / default | Descripción |
|---|---|---|---|
| `id` | `uuid` | Sí; `gen_random_uuid()` | Identificador interno opaco; PK. |
| `organization_id` | `uuid` | Sí | Frontera obligatoria de organización. → `organizations` |
| `created_at` | `timestamptz` | Sí; `now()` | Fecha de creación UTC. |
| `updated_at` | `timestamptz` | Sí; `now()` | Última modificación; trigger de servidor. |
| `code` | `text` | Sí | practicante, lider, supervisor, admin, superadmin o delegado |
| `name` | `text` | Sí | Etiqueta visible |
| `scope` | `text` | Sí | organization o project |
| `is_system` | `boolean` | Sí; `false` | Rol base protegido |

**Integridad:** PK `id`. UQ `(organization_id, id)`. UQ `(organization_id, code)`. CHECK: `scope IN ('organization','project')`.

**FK (todas `ON DELETE RESTRICT`):**

- `(organization_id)` → `organizations(id)`.

**Contrato de autorización:** Leer roles aplicables; administrar roles delegados sin ampliar permisos propios.

---

### permissions

![Fase: MVP](https://img.shields.io/static/v1?label=Fase&message=MVP&color=0066FF&style=for-the-badge) ![Ámbito: global](https://img.shields.io/static/v1?label=%C3%81mbito&message=global&color=0A1A3A&style=for-the-badge)

Catálogo global de capacidades explícitas.

| Columna SQL | Tipo PostgreSQL | Obligatorio / default | Descripción |
|---|---|---|---|
| `id` | `uuid` | Sí; `gen_random_uuid()` | Identificador interno opaco; PK. |
| `created_at` | `timestamptz` | Sí; `now()` | Fecha de creación UTC. |
| `updated_at` | `timestamptz` | Sí; `now()` | Última modificación; trigger de servidor. |
| `code` | `text` | Sí | Código estable, por ejemplo card.move |
| `description` | `text` | Sí | Significado funcional |

**Integridad:** PK `id`. UQ `(code)`. 

**Contrato de autorización:** Solo lectura por backend autenticado; cambios mediante migración revisada.

---

### role_permissions

![Fase: MVP](https://img.shields.io/static/v1?label=Fase&message=MVP&color=0066FF&style=for-the-badge) ![Ámbito: org](https://img.shields.io/static/v1?label=%C3%81mbito&message=org&color=0A1A3A&style=for-the-badge)

Relación N:M de roles y capacidades.

| Columna SQL | Tipo PostgreSQL | Obligatorio / default | Descripción |
|---|---|---|---|
| `id` | `uuid` | Sí; `gen_random_uuid()` | Identificador interno opaco; PK. |
| `organization_id` | `uuid` | Sí | Frontera obligatoria de organización. → `organizations` |
| `created_at` | `timestamptz` | Sí; `now()` | Fecha de creación UTC. |
| `updated_at` | `timestamptz` | Sí; `now()` | Última modificación; trigger de servidor. |
| `role_id` | `uuid` | Sí | Rol al que se concede → `roles` |
| `permission_id` | `uuid` | Sí | Capacidad concedida → `permissions` |

**Integridad:** PK `id`. UQ `(organization_id, id)`. UQ `(role_id, permission_id)`. 

**FK (todas `ON DELETE RESTRICT`):**

- `(organization_id)` → `organizations(id)`.
- `(organization_id, role_id)` → `roles(organization_id, id)`.
- `(permission_id)` → `permissions(id)`.

**Contrato de autorización:** Leer según administración; escritura solo por flujo de delegación y auditoría.

---

### role_grants

![Fase: MVP](https://img.shields.io/static/v1?label=Fase&message=MVP&color=0066FF&style=for-the-badge) ![Ámbito: org](https://img.shields.io/static/v1?label=%C3%81mbito&message=org&color=0A1A3A&style=for-the-badge)

Concesiones de rol por organización o proyecto.

| Columna SQL | Tipo PostgreSQL | Obligatorio / default | Descripción |
|---|---|---|---|
| `id` | `uuid` | Sí; `gen_random_uuid()` | Identificador interno opaco; PK. |
| `organization_id` | `uuid` | Sí | Frontera obligatoria de organización. → `organizations` |
| `created_at` | `timestamptz` | Sí; `now()` | Fecha de creación UTC. |
| `updated_at` | `timestamptz` | Sí; `now()` | Última modificación; trigger de servidor. |
| `membership_id` | `uuid` | Sí | Miembro beneficiario → `memberships` |
| `role_id` | `uuid` | Sí | Rol concedido → `roles` |
| `project_id` | `uuid` | No | NULL para alcance organizacional → `projects` |
| `granted_by` | `uuid` | Sí | Miembro autorizante → `memberships` |
| `expires_at` | `timestamptz` | No | Expiración |
| `revoked_at` | `timestamptz` | No | Revocación |

**Integridad:** PK `id`. UQ `(organization_id, id)`. CHECK: `expires_at > created_at`.

**FK (todas `ON DELETE RESTRICT`):**

- `(organization_id)` → `organizations(id)`.
- `(organization_id, membership_id)` → `memberships(organization_id, id)`.
- `(organization_id, role_id)` → `roles(organization_id, id)`.
- `(organization_id, project_id)` → `projects(organization_id, id)`.
- `(organization_id, granted_by)` → `memberships(organization_id, id)`.

**Índice único parcial:** `uq_role_grants_org_active` sobre `(membership_id, role_id)`, WHERE `project_id IS NULL AND revoked_at IS NULL`.

**Índice único parcial:** `uq_role_grants_project_active` sobre `(membership_id, role_id, project_id)`, WHERE `project_id IS NOT NULL AND revoked_at IS NULL`.

**Contrato de autorización:** Propio o administrador autorizado; otorgar/revocar sin autoasignación, con alcance y expiración verificados.

---

### invitations

![Fase: MVP](https://img.shields.io/static/v1?label=Fase&message=MVP&color=0066FF&style=for-the-badge) ![Ámbito: org](https://img.shields.io/static/v1?label=%C3%81mbito&message=org&color=0A1A3A&style=for-the-badge)

Invitaciones temporales sin contraseña local.

| Columna SQL | Tipo PostgreSQL | Obligatorio / default | Descripción |
|---|---|---|---|
| `id` | `uuid` | Sí; `gen_random_uuid()` | Identificador interno opaco; PK. |
| `organization_id` | `uuid` | Sí | Frontera obligatoria de organización. → `organizations` |
| `created_at` | `timestamptz` | Sí; `now()` | Fecha de creación UTC. |
| `updated_at` | `timestamptz` | Sí; `now()` | Última modificación; trigger de servidor. |
| `email` | `text` | Sí | Correo destinatario normalizado |
| `token_hash` | `text` | Sí | Hash del token de un solo uso |
| `invited_by` | `uuid` | Sí | Responsable de invitación → `memberships` |
| `role_id` | `uuid` | Sí | Rol propuesto → `roles` |
| `expires_at` | `timestamptz` | Sí | Caducidad |
| `accepted_at` | `timestamptz` | No | Consumo del token |
| `revoked_at` | `timestamptz` | No | Revocación |

**Integridad:** PK `id`. UQ `(organization_id, id)`. UQ `(token_hash)`. CHECK: `expires_at > created_at`.

**FK (todas `ON DELETE RESTRICT`):**

- `(organization_id)` → `organizations(id)`.
- `(organization_id, invited_by)` → `memberships(organization_id, id)`.
- `(organization_id, role_id)` → `roles(organization_id, id)`.

**Contrato de autorización:** Administrador delegado; aceptación mediante endpoint seguro; nunca exponer token_hash al cliente.

---

### user_preferences

![Fase: MVP](https://img.shields.io/static/v1?label=Fase&message=MVP&color=0066FF&style=for-the-badge) ![Ámbito: org](https://img.shields.io/static/v1?label=%C3%81mbito&message=org&color=0A1A3A&style=for-the-badge)

Preferencias personales sincronizadas.

| Columna SQL | Tipo PostgreSQL | Obligatorio / default | Descripción |
|---|---|---|---|
| `id` | `uuid` | Sí; `gen_random_uuid()` | Identificador interno opaco; PK. |
| `organization_id` | `uuid` | Sí | Frontera obligatoria de organización. → `organizations` |
| `created_at` | `timestamptz` | Sí; `now()` | Fecha de creación UTC. |
| `updated_at` | `timestamptz` | Sí; `now()` | Última modificación; trigger de servidor. |
| `membership_id` | `uuid` | Sí | Titular → `memberships` |
| `theme` | `text` | Sí; `'system'` | light, dark o system |
| `locale` | `text` | Sí; `'es-PE'` | Idioma y región |
| `timezone` | `text` | Sí; `'America/Lima'` | Zona de presentación |
| `reduced_motion` | `boolean` | Sí; `false` | Preferencia de movimiento reducido |
| `dashboard_layout` | `jsonb` | Sí; `'{}'::jsonb` | Widgets, orden y tamaños validados |
| `sidebar_collapsed` | `boolean` | Sí; `false` | Estado de menú |

**Integridad:** PK `id`. UQ `(organization_id, id)`. UQ `(membership_id)`. CHECK: `theme IN ('light','dark','system')`.

**FK (todas `ON DELETE RESTRICT`):**

- `(organization_id)` → `organizations(id)`.
- `(organization_id, membership_id)` → `memberships(organization_id, id)`.

**Contrato de autorización:** Solo titular; validar claves de JSON y no almacenar permisos ni secretos.

---

### organization_settings

![Fase: MVP](https://img.shields.io/static/v1?label=Fase&message=MVP&color=0066FF&style=for-the-badge) ![Ámbito: org](https://img.shields.io/static/v1?label=%C3%81mbito&message=org&color=0A1A3A&style=for-the-badge)

Configuraciones funcionales de empresa.

| Columna SQL | Tipo PostgreSQL | Obligatorio / default | Descripción |
|---|---|---|---|
| `id` | `uuid` | Sí; `gen_random_uuid()` | Identificador interno opaco; PK. |
| `organization_id` | `uuid` | Sí | Frontera obligatoria de organización. → `organizations` |
| `created_at` | `timestamptz` | Sí; `now()` | Fecha de creación UTC. |
| `updated_at` | `timestamptz` | Sí; `now()` | Última modificación; trigger de servidor. |
| `key` | `text` | Sí | Clave registrada |
| `value` | `jsonb` | Sí | Valor validado según esquema |
| `updated_by` | `uuid` | Sí | Autor del cambio → `memberships` |
| `version` | `integer` | Sí; `1` | Control optimista |

**Integridad:** PK `id`. UQ `(organization_id, id)`. UQ `(organization_id, key)`. CHECK: `version > 0`.

**FK (todas `ON DELETE RESTRICT`):**

- `(organization_id)` → `organizations(id)`.
- `(organization_id, updated_by)` → `memberships(organization_id, id)`.

**Contrato de autorización:** Leer solo claves permitidas; admin delegado cambia configuración funcional, nunca secretos.

---

### teams

![Fase: MVP](https://img.shields.io/static/v1?label=Fase&message=MVP&color=0066FF&style=for-the-badge) ![Ámbito: org](https://img.shields.io/static/v1?label=%C3%81mbito&message=org&color=0A1A3A&style=for-the-badge)

Equipos y especialidades de trabajo.

| Columna SQL | Tipo PostgreSQL | Obligatorio / default | Descripción |
|---|---|---|---|
| `id` | `uuid` | Sí; `gen_random_uuid()` | Identificador interno opaco; PK. |
| `organization_id` | `uuid` | Sí | Frontera obligatoria de organización. → `organizations` |
| `created_at` | `timestamptz` | Sí; `now()` | Fecha de creación UTC. |
| `updated_at` | `timestamptz` | Sí; `now()` | Última modificación; trigger de servidor. |
| `name` | `text` | Sí | Nombre del equipo |
| `code` | `text` | Sí | Código corto |
| `description` | `text` | No | Propósito |
| `archived_at` | `timestamptz` | No | Archivado |

**Integridad:** PK `id`. UQ `(organization_id, id)`. UQ `(organization_id, code)`. 

**FK (todas `ON DELETE RESTRICT`):**

- `(organization_id)` → `organizations(id)`.

**Contrato de autorización:** Miembros del equipo o supervisor asignado; administrar con permiso team.manage.

---

### team_members

![Fase: MVP](https://img.shields.io/static/v1?label=Fase&message=MVP&color=0066FF&style=for-the-badge) ![Ámbito: org](https://img.shields.io/static/v1?label=%C3%81mbito&message=org&color=0A1A3A&style=for-the-badge)

Membresía N:M de equipos.

| Columna SQL | Tipo PostgreSQL | Obligatorio / default | Descripción |
|---|---|---|---|
| `id` | `uuid` | Sí; `gen_random_uuid()` | Identificador interno opaco; PK. |
| `organization_id` | `uuid` | Sí | Frontera obligatoria de organización. → `organizations` |
| `created_at` | `timestamptz` | Sí; `now()` | Fecha de creación UTC. |
| `updated_at` | `timestamptz` | Sí; `now()` | Última modificación; trigger de servidor. |
| `team_id` | `uuid` | Sí | Equipo → `teams` |
| `membership_id` | `uuid` | Sí | Integrante → `memberships` |
| `responsibility` | `text` | Sí; `'member'` | Responsabilidad descriptiva |
| `removed_at` | `timestamptz` | No | Salida del equipo |

**Integridad:** PK `id`. UQ `(organization_id, id)`. UQ `(team_id, membership_id)`. 

**FK (todas `ON DELETE RESTRICT`):**

- `(organization_id)` → `organizations(id)`.
- `(organization_id, team_id)` → `teams(organization_id, id)`.
- `(organization_id, membership_id)` → `memberships(organization_id, id)`.

**Contrato de autorización:** Leer equipo autorizado; gestionar supervisor o delegado; no concede privilegios automáticamente.

---

### availability

![Fase: MVP](https://img.shields.io/static/v1?label=Fase&message=MVP&color=0066FF&style=for-the-badge) ![Ámbito: org](https://img.shields.io/static/v1?label=%C3%81mbito&message=org&color=0A1A3A&style=for-the-badge)

Disponibilidad y capacidad planificada.

| Columna SQL | Tipo PostgreSQL | Obligatorio / default | Descripción |
|---|---|---|---|
| `id` | `uuid` | Sí; `gen_random_uuid()` | Identificador interno opaco; PK. |
| `organization_id` | `uuid` | Sí | Frontera obligatoria de organización. → `organizations` |
| `created_at` | `timestamptz` | Sí; `now()` | Fecha de creación UTC. |
| `updated_at` | `timestamptz` | Sí; `now()` | Última modificación; trigger de servidor. |
| `membership_id` | `uuid` | Sí | Titular → `memberships` |
| `work_date` | `date` | Sí | Día local |
| `capacity_minutes` | `integer` | Sí | Minutos disponibles |
| `reason` | `text` | No | Motivo no sensible |

**Integridad:** PK `id`. UQ `(organization_id, id)`. UQ `(membership_id, work_date)`. CHECK: `capacity_minutes BETWEEN 0 AND 1440`.

**FK (todas `ON DELETE RESTRICT`):**

- `(organization_id)` → `organizations(id)`.
- `(organization_id, membership_id)` → `memberships(organization_id, id)`.

**Contrato de autorización:** Titular y supervisor de su equipo; no exponer motivos privados en informes.

---

## 02. Proyectos, tableros y tarjetas

[`projects`](#projects) | [`project_members`](#project_members) | [`milestones`](#milestones) | [`boards`](#boards) | [`board_columns`](#board_columns) | [`cards`](#cards) | [`card_assignees`](#card_assignees) | [`labels`](#labels) | [`card_labels`](#card_labels) | [`field_definitions`](#field_definitions) | [`field_values`](#field_values) | [`checklists`](#checklists) | [`checklist_items`](#checklist_items) | [`card_dependencies`](#card_dependencies) | [`comments`](#comments) | [`comment_mentions`](#comment_mentions) | [`comment_reactions`](#comment_reactions) | [`files`](#files) | [`attachments`](#attachments) | [`card_watchers`](#card_watchers) | [`card_events`](#card_events)

### projects

![Fase: MVP](https://img.shields.io/static/v1?label=Fase&message=MVP&color=0066FF&style=for-the-badge) ![Ámbito: org](https://img.shields.io/static/v1?label=%C3%81mbito&message=org&color=0A1A3A&style=for-the-badge)

Portafolio de proyectos; raíz del alcance operativo.

| Columna SQL | Tipo PostgreSQL | Obligatorio / default | Descripción |
|---|---|---|---|
| `id` | `uuid` | Sí; `gen_random_uuid()` | Identificador interno opaco; PK. |
| `organization_id` | `uuid` | Sí | Frontera obligatoria de organización. → `organizations` |
| `created_at` | `timestamptz` | Sí; `now()` | Fecha de creación UTC. |
| `updated_at` | `timestamptz` | Sí; `now()` | Última modificación; trigger de servidor. |
| `code` | `text` | Sí | Código humano único |
| `name` | `text` | Sí | Nombre del proyecto |
| `description` | `text` | No | Resumen y objetivos |
| `status` | `text` | Sí; `'planned'` | planned, active, paused, completed, archived |
| `priority` | `text` | Sí; `'medium'` | low, medium, high, urgent |
| `start_date` | `date` | No | Inicio planificado |
| `due_date` | `date` | No | Fecha prevista |
| `created_by` | `uuid` | Sí | Autor → `memberships` |
| `version` | `integer` | Sí; `1` | Control de concurrencia |
| `archived_at` | `timestamptz` | No | Archivo lógico |

**Integridad:** PK `id`. UQ `(organization_id, id)`. UQ `(organization_id, code)`. CHECK: `status IN ('planned','active','paused','completed','archived')`; `priority IN ('low','medium','high','urgent')`; `due_date >= start_date`; `version > 0`.

**FK (todas `ON DELETE RESTRICT`):**

- `(organization_id)` → `organizations(id)`.
- `(organization_id, created_by)` → `memberships(organization_id, id)`.

**Índices de consulta:** `(organization_id, status, due_date)`. Además índices de soporte FK cuando no estén cubiertos.

**Contrato de autorización:** Leer proyecto asignado; crear con project.create y asignar supervisor en misma transacción; editar por líder/supervisor delegado.

---

### project_members

![Fase: MVP](https://img.shields.io/static/v1?label=Fase&message=MVP&color=0066FF&style=for-the-badge) ![Ámbito: project](https://img.shields.io/static/v1?label=%C3%81mbito&message=project&color=0A1A3A&style=for-the-badge)

Participación en proyecto, independiente del rol global.

| Columna SQL | Tipo PostgreSQL | Obligatorio / default | Descripción |
|---|---|---|---|
| `id` | `uuid` | Sí; `gen_random_uuid()` | Identificador interno opaco; PK. |
| `organization_id` | `uuid` | Sí | Frontera obligatoria de organización. → `organizations` |
| `project_id` | `uuid` | Sí | Proyecto padre; debe pertenecer a la organización. → `projects` |
| `created_at` | `timestamptz` | Sí; `now()` | Fecha de creación UTC. |
| `updated_at` | `timestamptz` | Sí; `now()` | Última modificación; trigger de servidor. |
| `membership_id` | `uuid` | Sí | Miembro asignado → `memberships` |
| `team_id` | `uuid` | No | Equipo de trabajo → `teams` |
| `removed_at` | `timestamptz` | No | Retiro de acceso |

**Integridad:** PK `id`. UQ `(organization_id, id)`. UQ `(organization_id, project_id, id)`. UQ `(project_id, membership_id)`; `(organization_id, project_id, membership_id)`. 

**FK (todas `ON DELETE RESTRICT`):**

- `(organization_id)` → `organizations(id)`.
- `(organization_id, project_id)` → `projects(organization_id, id)`.
- `(organization_id, membership_id)` → `memberships(organization_id, id)`.
- `(organization_id, team_id)` → `teams(organization_id, id)`.

**Contrato de autorización:** Leer miembros de proyecto visible; alta/baja solo supervisor o delegado; rol de líder se concede en role_grants.

---

### milestones

![Fase: MVP](https://img.shields.io/static/v1?label=Fase&message=MVP&color=0066FF&style=for-the-badge) ![Ámbito: project](https://img.shields.io/static/v1?label=%C3%81mbito&message=project&color=0A1A3A&style=for-the-badge)

Hitos y entregables.

| Columna SQL | Tipo PostgreSQL | Obligatorio / default | Descripción |
|---|---|---|---|
| `id` | `uuid` | Sí; `gen_random_uuid()` | Identificador interno opaco; PK. |
| `organization_id` | `uuid` | Sí | Frontera obligatoria de organización. → `organizations` |
| `project_id` | `uuid` | Sí | Proyecto padre; debe pertenecer a la organización. → `projects` |
| `created_at` | `timestamptz` | Sí; `now()` | Fecha de creación UTC. |
| `updated_at` | `timestamptz` | Sí; `now()` | Última modificación; trigger de servidor. |
| `name` | `text` | Sí | Nombre del hito |
| `due_date` | `date` | No | Fecha objetivo |
| `completed_at` | `timestamptz` | No | Cumplimiento |
| `description` | `text` | No | Criterios del hito |

**Integridad:** PK `id`. UQ `(organization_id, id)`. UQ `(organization_id, project_id, id)`. 

**FK (todas `ON DELETE RESTRICT`):**

- `(organization_id)` → `organizations(id)`.
- `(organization_id, project_id)` → `projects(organization_id, id)`.

**Contrato de autorización:** Leer proyecto; escritura por coordinador autorizado.

---

### boards

![Fase: MVP](https://img.shields.io/static/v1?label=Fase&message=MVP&color=0066FF&style=for-the-badge) ![Ámbito: project](https://img.shields.io/static/v1?label=%C3%81mbito&message=project&color=0A1A3A&style=for-the-badge)

Tableros múltiples por proyecto.

| Columna SQL | Tipo PostgreSQL | Obligatorio / default | Descripción |
|---|---|---|---|
| `id` | `uuid` | Sí; `gen_random_uuid()` | Identificador interno opaco; PK. |
| `organization_id` | `uuid` | Sí | Frontera obligatoria de organización. → `organizations` |
| `project_id` | `uuid` | Sí | Proyecto padre; debe pertenecer a la organización. → `projects` |
| `created_at` | `timestamptz` | Sí; `now()` | Fecha de creación UTC. |
| `updated_at` | `timestamptz` | Sí; `now()` | Última modificación; trigger de servidor. |
| `name` | `text` | Sí | Nombre del tablero |
| `description` | `text` | No | Descripción |
| `position` | `numeric(20,8)` | Sí; `0` | Orden relativo |
| `version` | `integer` | Sí; `1` | Versión de tablero |
| `archived_at` | `timestamptz` | No | Archivo |

**Integridad:** PK `id`. UQ `(organization_id, id)`. UQ `(organization_id, project_id, id)`. CHECK: `version > 0`.

**FK (todas `ON DELETE RESTRICT`):**

- `(organization_id)` → `organizations(id)`.
- `(organization_id, project_id)` → `projects(organization_id, id)`.

**Contrato de autorización:** Leer proyecto; configurar por board.manage.

---

### board_columns

![Fase: MVP](https://img.shields.io/static/v1?label=Fase&message=MVP&color=0066FF&style=for-the-badge) ![Ámbito: project](https://img.shields.io/static/v1?label=%C3%81mbito&message=project&color=0A1A3A&style=for-the-badge)

Columnas personalizadas con semántica estable.

| Columna SQL | Tipo PostgreSQL | Obligatorio / default | Descripción |
|---|---|---|---|
| `id` | `uuid` | Sí; `gen_random_uuid()` | Identificador interno opaco; PK. |
| `organization_id` | `uuid` | Sí | Frontera obligatoria de organización. → `organizations` |
| `project_id` | `uuid` | Sí | Proyecto padre; debe pertenecer a la organización. → `projects` |
| `created_at` | `timestamptz` | Sí; `now()` | Fecha de creación UTC. |
| `updated_at` | `timestamptz` | Sí; `now()` | Última modificación; trigger de servidor. |
| `board_id` | `uuid` | Sí | Tablero padre → `boards` |
| `name` | `text` | Sí | Nombre visible personalizable |
| `status_category` | `text` | Sí | todo, doing, review, done, blocked |
| `position` | `numeric(20,8)` | Sí; `0` | Orden relativo |
| `wip_limit` | `integer` | No | Límite de tarjetas en progreso |
| `color` | `text` | No | Color hexadecimal |
| `version` | `integer` | Sí; `1` | Versión de edición |
| `archived_at` | `timestamptz` | No | Archivo |

**Integridad:** PK `id`. UQ `(organization_id, id)`. UQ `(organization_id, project_id, id)`. UQ `(organization_id, project_id, board_id, id)`. CHECK: `status_category IN ('todo','doing','review','done','blocked')`; `wip_limit > 0`; `version > 0`.

**FK (todas `ON DELETE RESTRICT`):**

- `(organization_id)` → `organizations(id)`.
- `(organization_id, project_id)` → `projects(organization_id, id)`.
- `(organization_id, project_id, board_id)` → `boards(organization_id, project_id, id)`.

**Índices de consulta:** `(board_id, position)`. Además índices de soporte FK cuando no estén cubiertos.

**Contrato de autorización:** Leer proyecto; modificar por board.manage; archivar solo con migración segura de tarjetas.

---

### cards

![Fase: MVP](https://img.shields.io/static/v1?label=Fase&message=MVP&color=0066FF&style=for-the-badge) ![Ámbito: project](https://img.shields.io/static/v1?label=%C3%81mbito&message=project&color=0A1A3A&style=for-the-badge)

Única entidad de tarea; no duplicar en una tabla tasks.

| Columna SQL | Tipo PostgreSQL | Obligatorio / default | Descripción |
|---|---|---|---|
| `id` | `uuid` | Sí; `gen_random_uuid()` | Identificador interno opaco; PK. |
| `organization_id` | `uuid` | Sí | Frontera obligatoria de organización. → `organizations` |
| `project_id` | `uuid` | Sí | Proyecto padre; debe pertenecer a la organización. → `projects` |
| `created_at` | `timestamptz` | Sí; `now()` | Fecha de creación UTC. |
| `updated_at` | `timestamptz` | Sí; `now()` | Última modificación; trigger de servidor. |
| `board_id` | `uuid` | Sí | Tablero actual → `boards` |
| `column_id` | `uuid` | Sí | Columna actual → `board_columns` |
| `parent_card_id` | `uuid` | No | Subtarea de una tarjeta → `cards` |
| `milestone_id` | `uuid` | No | Hito asociado → `milestones` |
| `code` | `text` | Sí | Código humano en el proyecto |
| `title` | `text` | Sí | Título de la tarea |
| `description` | `jsonb` | Sí; `'{}'::jsonb` | Documento enriquecido validado y sanitizado |
| `priority` | `text` | Sí; `'medium'` | low, medium, high, urgent |
| `complexity` | `text` | No | low, medium, high |
| `specialty` | `text` | No | frontend, backend u otra especialidad aprobada |
| `task_type` | `text` | No | Categoría de actividad |
| `estimated_minutes` | `integer` | No | Esfuerzo planificado en minutos |
| `start_date` | `date` | No | Inicio planificado |
| `due_date` | `date` | No | Vencimiento local |
| `completed_at` | `timestamptz` | No | Cierre registrado |
| `position` | `numeric(20,8)` | Sí; `0` | Orden relativo en columna |
| `created_by` | `uuid` | Sí | Creador → `memberships` |
| `version` | `integer` | Sí; `1` | Versión optimista |
| `archived_at` | `timestamptz` | No | Archivo lógico |

**Integridad:** PK `id`. UQ `(organization_id, id)`. UQ `(organization_id, project_id, id)`. UQ `(project_id, code)`. CHECK: `priority IN ('low','medium','high','urgent')`; `complexity IN ('low','medium','high')`; `estimated_minutes >= 0`; `due_date >= start_date`; `version > 0`; `parent_card_id <> id`.

**FK (todas `ON DELETE RESTRICT`):**

- `(organization_id)` → `organizations(id)`.
- `(organization_id, project_id)` → `projects(organization_id, id)`.
- `(organization_id, project_id, board_id)` → `boards(organization_id, project_id, id)`.
- `(organization_id, project_id, column_id)` → `board_columns(organization_id, project_id, id)`.
- `(organization_id, project_id, parent_card_id)` → `cards(organization_id, project_id, id)`.
- `(organization_id, project_id, milestone_id)` → `milestones(organization_id, project_id, id)`.
- `(organization_id, created_by)` → `memberships(organization_id, id)`.
- `(organization_id, project_id, board_id, column_id)` → `board_columns(organization_id, project_id, board_id, id)`.

**Índices de consulta:** `(column_id, position)`; `(project_id, due_date)`; `(project_id, archived_at)`. Además índices de soporte FK cuando no estén cubiertos.

**Contrato de autorización:** Leer proyecto; editar asignadas propias o coordinador con permiso; mover validando columna/versión/cierre; nunca cambiar scope directamente.

---

### card_assignees

![Fase: MVP](https://img.shields.io/static/v1?label=Fase&message=MVP&color=0066FF&style=for-the-badge) ![Ámbito: project](https://img.shields.io/static/v1?label=%C3%81mbito&message=project&color=0A1A3A&style=for-the-badge)

Asignación N:M de tarjetas a miembros del proyecto.

| Columna SQL | Tipo PostgreSQL | Obligatorio / default | Descripción |
|---|---|---|---|
| `id` | `uuid` | Sí; `gen_random_uuid()` | Identificador interno opaco; PK. |
| `organization_id` | `uuid` | Sí | Frontera obligatoria de organización. → `organizations` |
| `project_id` | `uuid` | Sí | Proyecto padre; debe pertenecer a la organización. → `projects` |
| `created_at` | `timestamptz` | Sí; `now()` | Fecha de creación UTC. |
| `updated_at` | `timestamptz` | Sí; `now()` | Última modificación; trigger de servidor. |
| `card_id` | `uuid` | Sí | Tarjeta → `cards` |
| `membership_id` | `uuid` | Sí | Responsable asignado → `memberships` |
| `assigned_by` | `uuid` | Sí | Autor de asignación → `memberships` |
| `removed_at` | `timestamptz` | No | Retiro |

**Integridad:** PK `id`. UQ `(organization_id, id)`. UQ `(organization_id, project_id, id)`. UQ `(card_id, membership_id)`. 

**FK (todas `ON DELETE RESTRICT`):**

- `(organization_id)` → `organizations(id)`.
- `(organization_id, project_id)` → `projects(organization_id, id)`.
- `(organization_id, project_id, card_id)` → `cards(organization_id, project_id, id)`.
- `(organization_id, membership_id)` → `memberships(organization_id, id)`.
- `(organization_id, assigned_by)` → `memberships(organization_id, id)`.
- `(organization_id, project_id, membership_id)` → `project_members(organization_id, project_id, membership_id)`.

**Índices de consulta:** `(membership_id, removed_at)`. Además índices de soporte FK cuando no estén cubiertos.

**Contrato de autorización:** Leer tarjeta; asignar/desasignar por card.assign y pertenencia vigente al proyecto.

---

### labels

![Fase: MVP](https://img.shields.io/static/v1?label=Fase&message=MVP&color=0066FF&style=for-the-badge) ![Ámbito: org](https://img.shields.io/static/v1?label=%C3%81mbito&message=org&color=0A1A3A&style=for-the-badge)

Etiquetas globales de organización o locales de proyecto.

| Columna SQL | Tipo PostgreSQL | Obligatorio / default | Descripción |
|---|---|---|---|
| `id` | `uuid` | Sí; `gen_random_uuid()` | Identificador interno opaco; PK. |
| `organization_id` | `uuid` | Sí | Frontera obligatoria de organización. → `organizations` |
| `created_at` | `timestamptz` | Sí; `now()` | Fecha de creación UTC. |
| `updated_at` | `timestamptz` | Sí; `now()` | Última modificación; trigger de servidor. |
| `project_id` | `uuid` | No | NULL significa etiqueta organizacional → `projects` |
| `name` | `text` | Sí | Texto visible |
| `normalized_name` | `text` | Sí | Nombre normalizado para unicidad |
| `color` | `text` | Sí | Color HEX validado |
| `archived_at` | `timestamptz` | No | No asignable si archivada |

**Integridad:** PK `id`. UQ `(organization_id, id)`. CHECK: `color ~ '^#[0-9A-Fa-f]{6}$'`.

**FK (todas `ON DELETE RESTRICT`):**

- `(organization_id)` → `organizations(id)`.
- `(organization_id, project_id)` → `projects(organization_id, id)`.

**Índice único parcial:** `uq_labels_global_active` sobre `(organization_id, normalized_name)`, WHERE `project_id IS NULL AND archived_at IS NULL`.

**Índice único parcial:** `uq_labels_project_active` sobre `(organization_id, project_id, normalized_name)`, WHERE `project_id IS NOT NULL AND archived_at IS NULL`.

**Contrato de autorización:** Leer etiquetas globales o del proyecto visible; editar catálogo por permiso específico; mantener relaciones históricas.

---

### card_labels

![Fase: MVP](https://img.shields.io/static/v1?label=Fase&message=MVP&color=0066FF&style=for-the-badge) ![Ámbito: project](https://img.shields.io/static/v1?label=%C3%81mbito&message=project&color=0A1A3A&style=for-the-badge)

Relación N:M tarjeta-etiqueta.

| Columna SQL | Tipo PostgreSQL | Obligatorio / default | Descripción |
|---|---|---|---|
| `id` | `uuid` | Sí; `gen_random_uuid()` | Identificador interno opaco; PK. |
| `organization_id` | `uuid` | Sí | Frontera obligatoria de organización. → `organizations` |
| `project_id` | `uuid` | Sí | Proyecto padre; debe pertenecer a la organización. → `projects` |
| `created_at` | `timestamptz` | Sí; `now()` | Fecha de creación UTC. |
| `updated_at` | `timestamptz` | Sí; `now()` | Última modificación; trigger de servidor. |
| `card_id` | `uuid` | Sí | Tarjeta → `cards` |
| `label_id` | `uuid` | Sí | Etiqueta global o del proyecto → `labels` |

**Integridad:** PK `id`. UQ `(organization_id, id)`. UQ `(organization_id, project_id, id)`. UQ `(card_id, label_id)`. 

**FK (todas `ON DELETE RESTRICT`):**

- `(organization_id)` → `organizations(id)`.
- `(organization_id, project_id)` → `projects(organization_id, id)`.
- `(organization_id, project_id, card_id)` → `cards(organization_id, project_id, id)`.
- `(organization_id, label_id)` → `labels(organization_id, id)`.

**Contrato de autorización:** Leer tarjeta; adjuntar/desvincular por card.edit; rechazar etiqueta archivada o de otro proyecto.

---

### field_definitions

![Fase: MVP](https://img.shields.io/static/v1?label=Fase&message=MVP&color=0066FF&style=for-the-badge) ![Ámbito: project](https://img.shields.io/static/v1?label=%C3%81mbito&message=project&color=0A1A3A&style=for-the-badge)

Campos personalizados de tablero.

| Columna SQL | Tipo PostgreSQL | Obligatorio / default | Descripción |
|---|---|---|---|
| `id` | `uuid` | Sí; `gen_random_uuid()` | Identificador interno opaco; PK. |
| `organization_id` | `uuid` | Sí | Frontera obligatoria de organización. → `organizations` |
| `project_id` | `uuid` | Sí | Proyecto padre; debe pertenecer a la organización. → `projects` |
| `created_at` | `timestamptz` | Sí; `now()` | Fecha de creación UTC. |
| `updated_at` | `timestamptz` | Sí; `now()` | Última modificación; trigger de servidor. |
| `board_id` | `uuid` | Sí | Tablero → `boards` |
| `name` | `text` | Sí | Etiqueta de campo |
| `field_type` | `text` | Sí | text, number, date, select, boolean |
| `options` | `jsonb` | Sí; `'[]'::jsonb` | Opciones para selección |
| `is_required` | `boolean` | Sí; `false` | Obligatoriedad de negocio |
| `archived_at` | `timestamptz` | No | Retiro |

**Integridad:** PK `id`. UQ `(organization_id, id)`. UQ `(organization_id, project_id, id)`. CHECK: `field_type IN ('text','number','date','select','boolean')`.

**FK (todas `ON DELETE RESTRICT`):**

- `(organization_id)` → `organizations(id)`.
- `(organization_id, project_id)` → `projects(organization_id, id)`.
- `(organization_id, project_id, board_id)` → `boards(organization_id, project_id, id)`.

**Contrato de autorización:** Leer proyecto; gestionar por board.manage.

---

### field_values

![Fase: MVP](https://img.shields.io/static/v1?label=Fase&message=MVP&color=0066FF&style=for-the-badge) ![Ámbito: project](https://img.shields.io/static/v1?label=%C3%81mbito&message=project&color=0A1A3A&style=for-the-badge)

Valores de campos personalizados por tarjeta.

| Columna SQL | Tipo PostgreSQL | Obligatorio / default | Descripción |
|---|---|---|---|
| `id` | `uuid` | Sí; `gen_random_uuid()` | Identificador interno opaco; PK. |
| `organization_id` | `uuid` | Sí | Frontera obligatoria de organización. → `organizations` |
| `project_id` | `uuid` | Sí | Proyecto padre; debe pertenecer a la organización. → `projects` |
| `created_at` | `timestamptz` | Sí; `now()` | Fecha de creación UTC. |
| `updated_at` | `timestamptz` | Sí; `now()` | Última modificación; trigger de servidor. |
| `card_id` | `uuid` | Sí | Tarjeta → `cards` |
| `field_definition_id` | `uuid` | Sí | Definición → `field_definitions` |
| `value` | `jsonb` | Sí | Valor tipado por field_type |

**Integridad:** PK `id`. UQ `(organization_id, id)`. UQ `(organization_id, project_id, id)`. UQ `(card_id, field_definition_id)`. 

**FK (todas `ON DELETE RESTRICT`):**

- `(organization_id)` → `organizations(id)`.
- `(organization_id, project_id)` → `projects(organization_id, id)`.
- `(organization_id, project_id, card_id)` → `cards(organization_id, project_id, id)`.
- `(organization_id, project_id, field_definition_id)` → `field_definitions(organization_id, project_id, id)`.

**Contrato de autorización:** Leer tarjeta; modificar con card.edit y validar definición del mismo tablero.

---

### checklists

![Fase: MVP](https://img.shields.io/static/v1?label=Fase&message=MVP&color=0066FF&style=for-the-badge) ![Ámbito: project](https://img.shields.io/static/v1?label=%C3%81mbito&message=project&color=0A1A3A&style=for-the-badge)

Listas de verificación en tarjetas.

| Columna SQL | Tipo PostgreSQL | Obligatorio / default | Descripción |
|---|---|---|---|
| `id` | `uuid` | Sí; `gen_random_uuid()` | Identificador interno opaco; PK. |
| `organization_id` | `uuid` | Sí | Frontera obligatoria de organización. → `organizations` |
| `project_id` | `uuid` | Sí | Proyecto padre; debe pertenecer a la organización. → `projects` |
| `created_at` | `timestamptz` | Sí; `now()` | Fecha de creación UTC. |
| `updated_at` | `timestamptz` | Sí; `now()` | Última modificación; trigger de servidor. |
| `card_id` | `uuid` | Sí | Tarjeta → `cards` |
| `name` | `text` | Sí | Título |
| `position` | `numeric(20,8)` | Sí; `0` | Orden |

**Integridad:** PK `id`. UQ `(organization_id, id)`. UQ `(organization_id, project_id, id)`. 

**FK (todas `ON DELETE RESTRICT`):**

- `(organization_id)` → `organizations(id)`.
- `(organization_id, project_id)` → `projects(organization_id, id)`.
- `(organization_id, project_id, card_id)` → `cards(organization_id, project_id, id)`.

**Contrato de autorización:** Leer tarjeta; editar por card.edit.

---

### checklist_items

![Fase: MVP](https://img.shields.io/static/v1?label=Fase&message=MVP&color=0066FF&style=for-the-badge) ![Ámbito: project](https://img.shields.io/static/v1?label=%C3%81mbito&message=project&color=0A1A3A&style=for-the-badge)

Ítems marcables con responsable y fecha.

| Columna SQL | Tipo PostgreSQL | Obligatorio / default | Descripción |
|---|---|---|---|
| `id` | `uuid` | Sí; `gen_random_uuid()` | Identificador interno opaco; PK. |
| `organization_id` | `uuid` | Sí | Frontera obligatoria de organización. → `organizations` |
| `project_id` | `uuid` | Sí | Proyecto padre; debe pertenecer a la organización. → `projects` |
| `created_at` | `timestamptz` | Sí; `now()` | Fecha de creación UTC. |
| `updated_at` | `timestamptz` | Sí; `now()` | Última modificación; trigger de servidor. |
| `checklist_id` | `uuid` | Sí | Lista padre → `checklists` |
| `text` | `text` | Sí | Descripción del ítem |
| `assignee_id` | `uuid` | No | Responsable → `memberships` |
| `position` | `numeric(20,8)` | Sí; `0` | Orden |
| `completed_at` | `timestamptz` | No | Momento de cumplimiento |
| `completed_by` | `uuid` | No | Actor de cumplimiento → `memberships` |
| `due_date` | `date` | No | Vencimiento |

**Integridad:** PK `id`. UQ `(organization_id, id)`. UQ `(organization_id, project_id, id)`. CHECK: `(completed_at IS NULL) = (completed_by IS NULL)`.

**FK (todas `ON DELETE RESTRICT`):**

- `(organization_id)` → `organizations(id)`.
- `(organization_id, project_id)` → `projects(organization_id, id)`.
- `(organization_id, project_id, checklist_id)` → `checklists(organization_id, project_id, id)`.
- `(organization_id, assignee_id)` → `memberships(organization_id, id)`.
- `(organization_id, completed_by)` → `memberships(organization_id, id)`.
- `(organization_id, project_id, assignee_id)` → `project_members(organization_id, project_id, membership_id)`.

**Contrato de autorización:** Leer tarjeta; marcar por asignado o editor autorizado; asignar solo a miembro del proyecto.

---

### card_dependencies

![Fase: MVP](https://img.shields.io/static/v1?label=Fase&message=MVP&color=0066FF&style=for-the-badge) ![Ámbito: project](https://img.shields.io/static/v1?label=%C3%81mbito&message=project&color=0A1A3A&style=for-the-badge)

Grafo dirigido de bloqueo entre tarjetas.

| Columna SQL | Tipo PostgreSQL | Obligatorio / default | Descripción |
|---|---|---|---|
| `id` | `uuid` | Sí; `gen_random_uuid()` | Identificador interno opaco; PK. |
| `organization_id` | `uuid` | Sí | Frontera obligatoria de organización. → `organizations` |
| `project_id` | `uuid` | Sí | Proyecto padre; debe pertenecer a la organización. → `projects` |
| `created_at` | `timestamptz` | Sí; `now()` | Fecha de creación UTC. |
| `updated_at` | `timestamptz` | Sí; `now()` | Última modificación; trigger de servidor. |
| `card_id` | `uuid` | Sí | Tarjeta dependiente → `cards` |
| `prerequisite_id` | `uuid` | Sí | Tarjeta precedente → `cards` |
| `kind` | `text` | Sí; `'blocks'` | Tipo de dependencia |

**Integridad:** PK `id`. UQ `(organization_id, id)`. UQ `(organization_id, project_id, id)`. UQ `(card_id, prerequisite_id)`. CHECK: `card_id <> prerequisite_id`.

**FK (todas `ON DELETE RESTRICT`):**

- `(organization_id)` → `organizations(id)`.
- `(organization_id, project_id)` → `projects(organization_id, id)`.
- `(organization_id, project_id, card_id)` → `cards(organization_id, project_id, id)`.
- `(organization_id, project_id, prerequisite_id)` → `cards(organization_id, project_id, id)`.

**Contrato de autorización:** Leer proyecto; editar por card.edit; detectar ciclos con bloqueo transaccional.

---

### comments

![Fase: MVP](https://img.shields.io/static/v1?label=Fase&message=MVP&color=0066FF&style=for-the-badge) ![Ámbito: project](https://img.shields.io/static/v1?label=%C3%81mbito&message=project&color=0A1A3A&style=for-the-badge)

Comentarios de tarjeta con edición trazable.

| Columna SQL | Tipo PostgreSQL | Obligatorio / default | Descripción |
|---|---|---|---|
| `id` | `uuid` | Sí; `gen_random_uuid()` | Identificador interno opaco; PK. |
| `organization_id` | `uuid` | Sí | Frontera obligatoria de organización. → `organizations` |
| `project_id` | `uuid` | Sí | Proyecto padre; debe pertenecer a la organización. → `projects` |
| `created_at` | `timestamptz` | Sí; `now()` | Fecha de creación UTC. |
| `updated_at` | `timestamptz` | Sí; `now()` | Última modificación; trigger de servidor. |
| `card_id` | `uuid` | Sí | Tarjeta → `cards` |
| `parent_comment_id` | `uuid` | No | Respuesta a comentario → `comments` |
| `author_id` | `uuid` | Sí | Autor → `memberships` |
| `body` | `text` | Sí | Contenido sanitizado |
| `edited_at` | `timestamptz` | No | Fecha de edición |
| `deleted_at` | `timestamptz` | No | Borrado lógico |

**Integridad:** PK `id`. UQ `(organization_id, id)`. UQ `(organization_id, project_id, id)`. UQ `(organization_id, project_id, card_id, id)`. 

**FK (todas `ON DELETE RESTRICT`):**

- `(organization_id)` → `organizations(id)`.
- `(organization_id, project_id)` → `projects(organization_id, id)`.
- `(organization_id, project_id, card_id)` → `cards(organization_id, project_id, id)`.
- `(organization_id, project_id, parent_comment_id)` → `comments(organization_id, project_id, id)`.
- `(organization_id, author_id)` → `memberships(organization_id, id)`.
- `(organization_id, project_id, card_id, parent_comment_id)` → `comments(organization_id, project_id, card_id, id)`.

**Contrato de autorización:** Leer tarjeta; comentar por miembro autorizado; editar propio, moderación separada.

---

### comment_mentions

![Fase: MVP](https://img.shields.io/static/v1?label=Fase&message=MVP&color=0066FF&style=for-the-badge) ![Ámbito: project](https://img.shields.io/static/v1?label=%C3%81mbito&message=project&color=0A1A3A&style=for-the-badge)

Menciones a miembros en comentarios.

| Columna SQL | Tipo PostgreSQL | Obligatorio / default | Descripción |
|---|---|---|---|
| `id` | `uuid` | Sí; `gen_random_uuid()` | Identificador interno opaco; PK. |
| `organization_id` | `uuid` | Sí | Frontera obligatoria de organización. → `organizations` |
| `project_id` | `uuid` | Sí | Proyecto padre; debe pertenecer a la organización. → `projects` |
| `created_at` | `timestamptz` | Sí; `now()` | Fecha de creación UTC. |
| `updated_at` | `timestamptz` | Sí; `now()` | Última modificación; trigger de servidor. |
| `comment_id` | `uuid` | Sí | Comentario → `comments` |
| `membership_id` | `uuid` | Sí | Destinatario → `memberships` |

**Integridad:** PK `id`. UQ `(organization_id, id)`. UQ `(organization_id, project_id, id)`. UQ `(comment_id, membership_id)`. 

**FK (todas `ON DELETE RESTRICT`):**

- `(organization_id)` → `organizations(id)`.
- `(organization_id, project_id)` → `projects(organization_id, id)`.
- `(organization_id, project_id, comment_id)` → `comments(organization_id, project_id, id)`.
- `(organization_id, membership_id)` → `memberships(organization_id, id)`.

**Contrato de autorización:** Leer comentario; crear solo mediante servicio de comentarios; destinatario con acceso.

---

### comment_reactions

![Fase: MVP](https://img.shields.io/static/v1?label=Fase&message=MVP&color=0066FF&style=for-the-badge) ![Ámbito: project](https://img.shields.io/static/v1?label=%C3%81mbito&message=project&color=0A1A3A&style=for-the-badge)

Reacciones por código de icono, sin emojis requeridos.

| Columna SQL | Tipo PostgreSQL | Obligatorio / default | Descripción |
|---|---|---|---|
| `id` | `uuid` | Sí; `gen_random_uuid()` | Identificador interno opaco; PK. |
| `organization_id` | `uuid` | Sí | Frontera obligatoria de organización. → `organizations` |
| `project_id` | `uuid` | Sí | Proyecto padre; debe pertenecer a la organización. → `projects` |
| `created_at` | `timestamptz` | Sí; `now()` | Fecha de creación UTC. |
| `updated_at` | `timestamptz` | Sí; `now()` | Última modificación; trigger de servidor. |
| `comment_id` | `uuid` | Sí | Comentario → `comments` |
| `membership_id` | `uuid` | Sí | Actor → `memberships` |
| `reaction_code` | `text` | Sí | Código de reacción permitido |

**Integridad:** PK `id`. UQ `(organization_id, id)`. UQ `(organization_id, project_id, id)`. UQ `(comment_id, membership_id, reaction_code)`. 

**FK (todas `ON DELETE RESTRICT`):**

- `(organization_id)` → `organizations(id)`.
- `(organization_id, project_id)` → `projects(organization_id, id)`.
- `(organization_id, project_id, comment_id)` → `comments(organization_id, project_id, id)`.
- `(organization_id, membership_id)` → `memberships(organization_id, id)`.

**Contrato de autorización:** Leer comentario; añadir/quitar propia reacción.

---

### files

![Fase: MVP](https://img.shields.io/static/v1?label=Fase&message=MVP&color=0066FF&style=for-the-badge) ![Ámbito: org](https://img.shields.io/static/v1?label=%C3%81mbito&message=org&color=0A1A3A&style=for-the-badge)

Metadatos de objetos privados, no contenido binario.

| Columna SQL | Tipo PostgreSQL | Obligatorio / default | Descripción |
|---|---|---|---|
| `id` | `uuid` | Sí; `gen_random_uuid()` | Identificador interno opaco; PK. |
| `organization_id` | `uuid` | Sí | Frontera obligatoria de organización. → `organizations` |
| `created_at` | `timestamptz` | Sí; `now()` | Fecha de creación UTC. |
| `updated_at` | `timestamptz` | Sí; `now()` | Última modificación; trigger de servidor. |
| `bucket` | `text` | Sí | Bucket autorizado |
| `object_path` | `text` | Sí | Ruta aleatoria inmutable |
| `original_name` | `text` | Sí | Nombre para descarga |
| `mime_type` | `text` | Sí | Tipo detectado |
| `size_bytes` | `bigint` | Sí | Tamaño |
| `sha256` | `text` | No | Integridad |
| `uploaded_by` | `uuid` | Sí | Autor → `memberships` |
| `status` | `text` | Sí; `'pending'` | pending, ready, rejected, deleted |

**Integridad:** PK `id`. UQ `(organization_id, id)`. UQ `(bucket, object_path)`. CHECK: `size_bytes >= 0`; `status IN ('pending','ready','rejected','deleted')`.

**FK (todas `ON DELETE RESTRICT`):**

- `(organization_id)` → `organizations(id)`.
- `(organization_id, uploaded_by)` → `memberships(organization_id, id)`.

**Contrato de autorización:** No listado global: leer por recurso padre autorizado; crear por carga autorizada; objetos privados.

---

### attachments

![Fase: MVP](https://img.shields.io/static/v1?label=Fase&message=MVP&color=0066FF&style=for-the-badge) ![Ámbito: project](https://img.shields.io/static/v1?label=%C3%81mbito&message=project&color=0A1A3A&style=for-the-badge)

Vínculos de archivos con tarjetas.

| Columna SQL | Tipo PostgreSQL | Obligatorio / default | Descripción |
|---|---|---|---|
| `id` | `uuid` | Sí; `gen_random_uuid()` | Identificador interno opaco; PK. |
| `organization_id` | `uuid` | Sí | Frontera obligatoria de organización. → `organizations` |
| `project_id` | `uuid` | Sí | Proyecto padre; debe pertenecer a la organización. → `projects` |
| `created_at` | `timestamptz` | Sí; `now()` | Fecha de creación UTC. |
| `updated_at` | `timestamptz` | Sí; `now()` | Última modificación; trigger de servidor. |
| `card_id` | `uuid` | Sí | Tarjeta → `cards` |
| `file_id` | `uuid` | Sí | Objeto validado → `files` |
| `added_by` | `uuid` | Sí | Autor → `memberships` |
| `removed_at` | `timestamptz` | No | Desvinculación |

**Integridad:** PK `id`. UQ `(organization_id, id)`. UQ `(organization_id, project_id, id)`. UQ `(card_id, file_id)`. 

**FK (todas `ON DELETE RESTRICT`):**

- `(organization_id)` → `organizations(id)`.
- `(organization_id, project_id)` → `projects(organization_id, id)`.
- `(organization_id, project_id, card_id)` → `cards(organization_id, project_id, id)`.
- `(organization_id, file_id)` → `files(organization_id, id)`.
- `(organization_id, added_by)` → `memberships(organization_id, id)`.

**Contrato de autorización:** Leer tarjeta; adjuntar con card.edit y archivo ready del mismo alcance.

---

### card_watchers

![Fase: MVP](https://img.shields.io/static/v1?label=Fase&message=MVP&color=0066FF&style=for-the-badge) ![Ámbito: project](https://img.shields.io/static/v1?label=%C3%81mbito&message=project&color=0A1A3A&style=for-the-badge)

Seguidores de actividad de tarjetas.

| Columna SQL | Tipo PostgreSQL | Obligatorio / default | Descripción |
|---|---|---|---|
| `id` | `uuid` | Sí; `gen_random_uuid()` | Identificador interno opaco; PK. |
| `organization_id` | `uuid` | Sí | Frontera obligatoria de organización. → `organizations` |
| `project_id` | `uuid` | Sí | Proyecto padre; debe pertenecer a la organización. → `projects` |
| `created_at` | `timestamptz` | Sí; `now()` | Fecha de creación UTC. |
| `updated_at` | `timestamptz` | Sí; `now()` | Última modificación; trigger de servidor. |
| `card_id` | `uuid` | Sí | Tarjeta → `cards` |
| `membership_id` | `uuid` | Sí | Seguidor → `memberships` |

**Integridad:** PK `id`. UQ `(organization_id, id)`. UQ `(organization_id, project_id, id)`. UQ `(card_id, membership_id)`. 

**FK (todas `ON DELETE RESTRICT`):**

- `(organization_id)` → `organizations(id)`.
- `(organization_id, project_id)` → `projects(organization_id, id)`.
- `(organization_id, project_id, card_id)` → `cards(organization_id, project_id, id)`.
- `(organization_id, membership_id)` → `memberships(organization_id, id)`.

**Contrato de autorización:** Leer propios seguimientos; seguir/dejar de seguir tarjeta visible.

---

### card_events

![Fase: MVP](https://img.shields.io/static/v1?label=Fase&message=MVP&color=0066FF&style=for-the-badge) ![Ámbito: project](https://img.shields.io/static/v1?label=%C3%81mbito&message=project&color=0A1A3A&style=for-the-badge)

Historial funcional de cambios por tarjeta.

| Columna SQL | Tipo PostgreSQL | Obligatorio / default | Descripción |
|---|---|---|---|
| `id` | `uuid` | Sí; `gen_random_uuid()` | Identificador interno opaco; PK. |
| `organization_id` | `uuid` | Sí | Frontera obligatoria de organización. → `organizations` |
| `project_id` | `uuid` | Sí | Proyecto padre; debe pertenecer a la organización. → `projects` |
| `created_at` | `timestamptz` | Sí; `now()` | Fecha de creación UTC. |
| `card_id` | `uuid` | Sí | Tarjeta → `cards` |
| `actor_id` | `uuid` | No | Actor o sistema → `memberships` |
| `kind` | `text` | Sí | Acción tipada |
| `payload` | `jsonb` | Sí; `'{}'::jsonb` | Cambios permitidos y redactados |
| `correlation_id` | `uuid` | Sí | Trazabilidad de operación |

**Integridad:** PK `id`. UQ `(organization_id, id)`. UQ `(organization_id, project_id, id)`. 

**FK (todas `ON DELETE RESTRICT`):**

- `(organization_id)` → `organizations(id)`.
- `(organization_id, project_id)` → `projects(organization_id, id)`.
- `(organization_id, project_id, card_id)` → `cards(organization_id, project_id, id)`.
- `(organization_id, actor_id)` → `memberships(organization_id, id)`.

**Índices de consulta:** `(card_id, created_at)`. Además índices de soporte FK cuando no estén cubiertos.

**Contrato de autorización:** Leer tarjeta; append-only por servicio transaccional; sin edición o borrado desde UI.

---

## 03. Tiempo, agenda, soporte y colaboración

[`timers`](#timers) | [`time_entries`](#time_entries) | [`time_entry_versions`](#time_entry_versions) | [`approvals`](#approvals) | [`calendar_events`](#calendar_events) | [`calendar_attendees`](#calendar_attendees) | [`tickets`](#tickets) | [`ticket_comments`](#ticket_comments) | [`ticket_links`](#ticket_links) | [`card_templates`](#card_templates) | [`automation_rules`](#automation_rules) | [`automation_runs`](#automation_runs)

### timers

![Fase: MVP / Fase 2](https://img.shields.io/static/v1?label=Fase&message=MVP%20/%20Fase%202&color=0066FF&style=for-the-badge) ![Ámbito: project](https://img.shields.io/static/v1?label=%C3%81mbito&message=project&color=0A1A3A&style=for-the-badge)

Cronómetro persistente por persona.

| Columna SQL | Tipo PostgreSQL | Obligatorio / default | Descripción |
|---|---|---|---|
| `id` | `uuid` | Sí; `gen_random_uuid()` | Identificador interno opaco; PK. |
| `organization_id` | `uuid` | Sí | Frontera obligatoria de organización. → `organizations` |
| `project_id` | `uuid` | Sí | Proyecto padre; debe pertenecer a la organización. → `projects` |
| `created_at` | `timestamptz` | Sí; `now()` | Fecha de creación UTC. |
| `updated_at` | `timestamptz` | Sí; `now()` | Última modificación; trigger de servidor. |
| `card_id` | `uuid` | Sí | Tarjeta → `cards` |
| `membership_id` | `uuid` | Sí | Titular → `memberships` |
| `started_at` | `timestamptz` | Sí | Inicio del servidor |
| `stopped_at` | `timestamptz` | No | Fin |
| `status` | `text` | Sí; `'running'` | running, stopped, cancelled |

**Integridad:** PK `id`. UQ `(organization_id, id)`. UQ `(organization_id, project_id, id)`. UQ `(organization_id, project_id, card_id, membership_id, id)`. CHECK: `stopped_at >= started_at`; `status IN ('running','stopped','cancelled')`; `(status = 'running') = (stopped_at IS NULL)`.

**FK (todas `ON DELETE RESTRICT`):**

- `(organization_id)` → `organizations(id)`.
- `(organization_id, project_id)` → `projects(organization_id, id)`.
- `(organization_id, project_id, card_id)` → `cards(organization_id, project_id, id)`.
- `(organization_id, membership_id)` → `memberships(organization_id, id)`.

**Índice único parcial:** `uq_timers_running` sobre `(membership_id)`, WHERE `status = 'running'`.

**Contrato de autorización:** Titular opera su cronómetro en tarjeta autorizada; supervisor solo lectura delegada.

---

### time_entries

![Fase: MVP / Fase 2](https://img.shields.io/static/v1?label=Fase&message=MVP%20/%20Fase%202&color=0066FF&style=for-the-badge) ![Ámbito: project](https://img.shields.io/static/v1?label=%C3%81mbito&message=project&color=0A1A3A&style=for-the-badge)

Registro de esfuerzo real, manual o desde cronómetro.

| Columna SQL | Tipo PostgreSQL | Obligatorio / default | Descripción |
|---|---|---|---|
| `id` | `uuid` | Sí; `gen_random_uuid()` | Identificador interno opaco; PK. |
| `organization_id` | `uuid` | Sí | Frontera obligatoria de organización. → `organizations` |
| `project_id` | `uuid` | Sí | Proyecto padre; debe pertenecer a la organización. → `projects` |
| `created_at` | `timestamptz` | Sí; `now()` | Fecha de creación UTC. |
| `updated_at` | `timestamptz` | Sí; `now()` | Última modificación; trigger de servidor. |
| `card_id` | `uuid` | Sí | Tarjeta → `cards` |
| `membership_id` | `uuid` | Sí | Autor del trabajo → `memberships` |
| `timer_id` | `uuid` | No | Origen de temporizador → `timers` |
| `work_date` | `date` | Sí | Día local de trabajo |
| `minutes` | `integer` | Sí | Duración entera |
| `note` | `text` | No | Descripción |
| `status` | `text` | Sí; `'draft'` | draft, submitted, approved, rejected, void |
| `submitted_at` | `timestamptz` | No | Envío a revisión |
| `version` | `integer` | Sí; `1` | Concurrencia |

**Integridad:** PK `id`. UQ `(organization_id, id)`. UQ `(organization_id, project_id, id)`. UQ `(timer_id)`. CHECK: `minutes BETWEEN 1 AND 1440`; `status IN ('draft','submitted','approved','rejected','void')`; `version > 0`.

**FK (todas `ON DELETE RESTRICT`):**

- `(organization_id)` → `organizations(id)`.
- `(organization_id, project_id)` → `projects(organization_id, id)`.
- `(organization_id, project_id, card_id)` → `cards(organization_id, project_id, id)`.
- `(organization_id, membership_id)` → `memberships(organization_id, id)`.
- `(organization_id, project_id, timer_id)` → `timers(organization_id, project_id, id)`.
- `(organization_id, project_id, card_id, membership_id, timer_id)` → `timers(organization_id, project_id, card_id, membership_id, id)`.

**Índices de consulta:** `(membership_id, work_date)`; `(card_id, status)`. Además índices de soporte FK cuando no estén cubiertos.

**Contrato de autorización:** Titular crea/edita borrador propio; supervisor de proyecto lee y aprueba sin autoaprobación; inmutable tras aprobación.

---

### time_entry_versions

![Fase: MVP / Fase 2](https://img.shields.io/static/v1?label=Fase&message=MVP%20/%20Fase%202&color=0066FF&style=for-the-badge) ![Ámbito: project](https://img.shields.io/static/v1?label=%C3%81mbito&message=project&color=0A1A3A&style=for-the-badge)

Historial de cambios de parte de horas.

| Columna SQL | Tipo PostgreSQL | Obligatorio / default | Descripción |
|---|---|---|---|
| `id` | `uuid` | Sí; `gen_random_uuid()` | Identificador interno opaco; PK. |
| `organization_id` | `uuid` | Sí | Frontera obligatoria de organización. → `organizations` |
| `project_id` | `uuid` | Sí | Proyecto padre; debe pertenecer a la organización. → `projects` |
| `created_at` | `timestamptz` | Sí; `now()` | Fecha de creación UTC. |
| `time_entry_id` | `uuid` | Sí | Registro original → `time_entries` |
| `revision` | `integer` | Sí | Número de revisión |
| `snapshot` | `jsonb` | Sí | Estado anterior o nuevo |
| `actor_id` | `uuid` | Sí | Autor → `memberships` |

**Integridad:** PK `id`. UQ `(organization_id, id)`. UQ `(organization_id, project_id, id)`. UQ `(time_entry_id, revision)`. CHECK: `revision > 0`.

**FK (todas `ON DELETE RESTRICT`):**

- `(organization_id)` → `organizations(id)`.
- `(organization_id, project_id)` → `projects(organization_id, id)`.
- `(organization_id, project_id, time_entry_id)` → `time_entries(organization_id, project_id, id)`.
- `(organization_id, actor_id)` → `memberships(organization_id, id)`.

**Contrato de autorización:** Leer si puede leer registro; solo append por servicio.

---

### approvals

![Fase: MVP / Fase 2](https://img.shields.io/static/v1?label=Fase&message=MVP%20/%20Fase%202&color=0066FF&style=for-the-badge) ![Ámbito: project](https://img.shields.io/static/v1?label=%C3%81mbito&message=project&color=0A1A3A&style=for-the-badge)

Decisiones sobre horas o cierre de tarjeta, sin FK polimórfica libre.

| Columna SQL | Tipo PostgreSQL | Obligatorio / default | Descripción |
|---|---|---|---|
| `id` | `uuid` | Sí; `gen_random_uuid()` | Identificador interno opaco; PK. |
| `organization_id` | `uuid` | Sí | Frontera obligatoria de organización. → `organizations` |
| `project_id` | `uuid` | Sí | Proyecto padre; debe pertenecer a la organización. → `projects` |
| `created_at` | `timestamptz` | Sí; `now()` | Fecha de creación UTC. |
| `updated_at` | `timestamptz` | Sí; `now()` | Última modificación; trigger de servidor. |
| `time_entry_id` | `uuid` | No | Parte a revisar → `time_entries` |
| `card_id` | `uuid` | No | Tarjeta a revisar → `cards` |
| `requested_by` | `uuid` | Sí | Solicitante → `memberships` |
| `reviewed_by` | `uuid` | No | Revisor → `memberships` |
| `decision` | `text` | Sí; `'pending'` | pending, approved, rejected |
| `reason` | `text` | No | Justificación |
| `decided_at` | `timestamptz` | No | Momento decisión |

**Integridad:** PK `id`. UQ `(organization_id, id)`. UQ `(organization_id, project_id, id)`. CHECK: `num_nonnulls(time_entry_id,card_id) = 1`; `decision IN ('pending','approved','rejected')`; `reviewed_by <> requested_by`; `(decision = 'pending' AND reviewed_by IS NULL AND decided_at IS NULL) OR (decision <> 'pending' AND reviewed_by IS NOT NULL AND decided_at IS NOT NULL)`.

**FK (todas `ON DELETE RESTRICT`):**

- `(organization_id)` → `organizations(id)`.
- `(organization_id, project_id)` → `projects(organization_id, id)`.
- `(organization_id, project_id, time_entry_id)` → `time_entries(organization_id, project_id, id)`.
- `(organization_id, project_id, card_id)` → `cards(organization_id, project_id, id)`.
- `(organization_id, requested_by)` → `memberships(organization_id, id)`.
- `(organization_id, reviewed_by)` → `memberships(organization_id, id)`.

**Contrato de autorización:** Solicitante y revisor autorizado; decisión por supervisor sin autoaprobación, validar estado y versión.

---

### calendar_events

![Fase: MVP / Fase 2](https://img.shields.io/static/v1?label=Fase&message=MVP%20/%20Fase%202&color=0066FF&style=for-the-badge) ![Ámbito: org](https://img.shields.io/static/v1?label=%C3%81mbito&message=org&color=0A1A3A&style=for-the-badge)

Agenda de reuniones, entregas y formación.

| Columna SQL | Tipo PostgreSQL | Obligatorio / default | Descripción |
|---|---|---|---|
| `id` | `uuid` | Sí; `gen_random_uuid()` | Identificador interno opaco; PK. |
| `organization_id` | `uuid` | Sí | Frontera obligatoria de organización. → `organizations` |
| `created_at` | `timestamptz` | Sí; `now()` | Fecha de creación UTC. |
| `updated_at` | `timestamptz` | Sí; `now()` | Última modificación; trigger de servidor. |
| `project_id` | `uuid` | No | Proyecto cuando aplique → `projects` |
| `owner_id` | `uuid` | Sí | Organizador → `memberships` |
| `title` | `text` | Sí | Título |
| `starts_at` | `timestamptz` | Sí | Inicio |
| `ends_at` | `timestamptz` | Sí | Fin |
| `timezone` | `text` | Sí; `'America/Lima'` | Zona original |
| `visibility` | `text` | Sí; `'private'` | private, project, organization |
| `external_id` | `text` | No | Referencia Graph opcional |

**Integridad:** PK `id`. UQ `(organization_id, id)`. CHECK: `ends_at > starts_at`; `visibility IN ('private','project','organization')`; `visibility <> 'project' OR project_id IS NOT NULL`; `length(trim(title)) > 0`.

**FK (todas `ON DELETE RESTRICT`):**

- `(organization_id)` → `organizations(id)`.
- `(organization_id, project_id)` → `projects(organization_id, id)`.
- `(organization_id, owner_id)` → `memberships(organization_id, id)`.

**Contrato de autorización:** Titular/invitado o audiencia autorizada; editar organizador o gestor delegado.

---

### calendar_attendees

![Fase: MVP / Fase 2](https://img.shields.io/static/v1?label=Fase&message=MVP%20/%20Fase%202&color=0066FF&style=for-the-badge) ![Ámbito: org](https://img.shields.io/static/v1?label=%C3%81mbito&message=org&color=0A1A3A&style=for-the-badge)

Invitados y respuestas.

| Columna SQL | Tipo PostgreSQL | Obligatorio / default | Descripción |
|---|---|---|---|
| `id` | `uuid` | Sí; `gen_random_uuid()` | Identificador interno opaco; PK. |
| `organization_id` | `uuid` | Sí | Frontera obligatoria de organización. → `organizations` |
| `created_at` | `timestamptz` | Sí; `now()` | Fecha de creación UTC. |
| `updated_at` | `timestamptz` | Sí; `now()` | Última modificación; trigger de servidor. |
| `event_id` | `uuid` | Sí | Evento → `calendar_events` |
| `membership_id` | `uuid` | Sí | Invitado → `memberships` |
| `response` | `text` | Sí; `'pending'` | pending, accepted, declined |

**Integridad:** PK `id`. UQ `(organization_id, id)`. UQ `(event_id, membership_id)`. CHECK: `response IN ('pending','accepted','declined')`.

**FK (todas `ON DELETE RESTRICT`):**

- `(organization_id)` → `organizations(id)`.
- `(organization_id, event_id)` → `calendar_events(organization_id, id)`.
- `(organization_id, membership_id)` → `memberships(organization_id, id)`.

**Contrato de autorización:** Leer evento autorizado; responder invitación propia; gestionar por organizador.

---

### tickets

![Fase: MVP / Fase 2](https://img.shields.io/static/v1?label=Fase&message=MVP%20/%20Fase%202&color=0066FF&style=for-the-badge) ![Ámbito: org](https://img.shields.io/static/v1?label=%C3%81mbito&message=org&color=0A1A3A&style=for-the-badge)

Bloqueos técnicos y solicitudes internas.

| Columna SQL | Tipo PostgreSQL | Obligatorio / default | Descripción |
|---|---|---|---|
| `id` | `uuid` | Sí; `gen_random_uuid()` | Identificador interno opaco; PK. |
| `organization_id` | `uuid` | Sí | Frontera obligatoria de organización. → `organizations` |
| `created_at` | `timestamptz` | Sí; `now()` | Fecha de creación UTC. |
| `updated_at` | `timestamptz` | Sí; `now()` | Última modificación; trigger de servidor. |
| `project_id` | `uuid` | No | Proyecto relacionado → `projects` |
| `reporter_id` | `uuid` | Sí | Solicitante → `memberships` |
| `assignee_id` | `uuid` | No | Responsable de soporte → `memberships` |
| `title` | `text` | Sí | Problema |
| `description` | `text` | Sí | Contexto sin secretos |
| `status` | `text` | Sí; `'open'` | open, in_progress, resolved, closed |
| `priority` | `text` | Sí; `'medium'` | Prioridad |
| `resolved_at` | `timestamptz` | No | Resolución |

**Integridad:** PK `id`. UQ `(organization_id, id)`. CHECK: `status IN ('open','in_progress','resolved','closed')`; `priority IN ('low','medium','high','urgent')`.

**FK (todas `ON DELETE RESTRICT`):**

- `(organization_id)` → `organizations(id)`.
- `(organization_id, project_id)` → `projects(organization_id, id)`.
- `(organization_id, reporter_id)` → `memberships(organization_id, id)`.
- `(organization_id, assignee_id)` → `memberships(organization_id, id)`.

**Contrato de autorización:** Solicitante, soporte asignado o supervisor autorizado; resolver por permiso support.resolve.

---

### ticket_comments

![Fase: MVP / Fase 2](https://img.shields.io/static/v1?label=Fase&message=MVP%20/%20Fase%202&color=0066FF&style=for-the-badge) ![Ámbito: org](https://img.shields.io/static/v1?label=%C3%81mbito&message=org&color=0A1A3A&style=for-the-badge)

Conversación y solución de soporte.

| Columna SQL | Tipo PostgreSQL | Obligatorio / default | Descripción |
|---|---|---|---|
| `id` | `uuid` | Sí; `gen_random_uuid()` | Identificador interno opaco; PK. |
| `organization_id` | `uuid` | Sí | Frontera obligatoria de organización. → `organizations` |
| `created_at` | `timestamptz` | Sí; `now()` | Fecha de creación UTC. |
| `updated_at` | `timestamptz` | Sí; `now()` | Última modificación; trigger de servidor. |
| `ticket_id` | `uuid` | Sí | Solicitud → `tickets` |
| `author_id` | `uuid` | Sí | Autor → `memberships` |
| `body` | `text` | Sí | Comentario o solución |

**Integridad:** PK `id`. UQ `(organization_id, id)`. 

**FK (todas `ON DELETE RESTRICT`):**

- `(organization_id)` → `organizations(id)`.
- `(organization_id, ticket_id)` → `tickets(organization_id, id)`.
- `(organization_id, author_id)` → `memberships(organization_id, id)`.

**Contrato de autorización:** Leer ticket; escribir como participante autorizado.

---

### ticket_links

![Fase: MVP / Fase 2](https://img.shields.io/static/v1?label=Fase&message=MVP%20/%20Fase%202&color=0066FF&style=for-the-badge) ![Ámbito: project](https://img.shields.io/static/v1?label=%C3%81mbito&message=project&color=0A1A3A&style=for-the-badge)

Vínculo de bloqueo con tarjeta.

| Columna SQL | Tipo PostgreSQL | Obligatorio / default | Descripción |
|---|---|---|---|
| `id` | `uuid` | Sí; `gen_random_uuid()` | Identificador interno opaco; PK. |
| `organization_id` | `uuid` | Sí | Frontera obligatoria de organización. → `organizations` |
| `project_id` | `uuid` | Sí | Proyecto padre; debe pertenecer a la organización. → `projects` |
| `created_at` | `timestamptz` | Sí; `now()` | Fecha de creación UTC. |
| `updated_at` | `timestamptz` | Sí; `now()` | Última modificación; trigger de servidor. |
| `ticket_id` | `uuid` | Sí | Solicitud → `tickets` |
| `card_id` | `uuid` | Sí | Tarjeta bloqueada → `cards` |

**Integridad:** PK `id`. UQ `(organization_id, id)`. UQ `(organization_id, project_id, id)`. UQ `(ticket_id, card_id)`. 

**FK (todas `ON DELETE RESTRICT`):**

- `(organization_id)` → `organizations(id)`.
- `(organization_id, project_id)` → `projects(organization_id, id)`.
- `(organization_id, ticket_id)` → `tickets(organization_id, id)`.
- `(organization_id, project_id, card_id)` → `cards(organization_id, project_id, id)`.

**Contrato de autorización:** Requiere acceso a ambos recursos; verificar proyecto coherente.

---

### card_templates

![Fase: MVP / Fase 2](https://img.shields.io/static/v1?label=Fase&message=MVP%20/%20Fase%202&color=0066FF&style=for-the-badge) ![Ámbito: project](https://img.shields.io/static/v1?label=%C3%81mbito&message=project&color=0A1A3A&style=for-the-badge)

Plantillas para creación de tarjetas y checklists.

| Columna SQL | Tipo PostgreSQL | Obligatorio / default | Descripción |
|---|---|---|---|
| `id` | `uuid` | Sí; `gen_random_uuid()` | Identificador interno opaco; PK. |
| `organization_id` | `uuid` | Sí | Frontera obligatoria de organización. → `organizations` |
| `project_id` | `uuid` | Sí | Proyecto padre; debe pertenecer a la organización. → `projects` |
| `created_at` | `timestamptz` | Sí; `now()` | Fecha de creación UTC. |
| `updated_at` | `timestamptz` | Sí; `now()` | Última modificación; trigger de servidor. |
| `name` | `text` | Sí | Nombre |
| `payload` | `jsonb` | Sí | Campos y listas validados |
| `created_by` | `uuid` | Sí | Autor → `memberships` |
| `archived_at` | `timestamptz` | No | Retiro |

**Integridad:** PK `id`. UQ `(organization_id, id)`. UQ `(organization_id, project_id, id)`. 

**FK (todas `ON DELETE RESTRICT`):**

- `(organization_id)` → `organizations(id)`.
- `(organization_id, project_id)` → `projects(organization_id, id)`.
- `(organization_id, created_by)` → `memberships(organization_id, id)`.

**Contrato de autorización:** Leer proyecto; gestionar por board.manage; no copiar asignados/archivos sin revalidar.

---

### automation_rules

![Fase: MVP / Fase 2](https://img.shields.io/static/v1?label=Fase&message=MVP%20/%20Fase%202&color=0066FF&style=for-the-badge) ![Ámbito: project](https://img.shields.io/static/v1?label=%C3%81mbito&message=project&color=0A1A3A&style=for-the-badge)

Reglas declarativas, incluidas tareas recurrentes.

| Columna SQL | Tipo PostgreSQL | Obligatorio / default | Descripción |
|---|---|---|---|
| `id` | `uuid` | Sí; `gen_random_uuid()` | Identificador interno opaco; PK. |
| `organization_id` | `uuid` | Sí | Frontera obligatoria de organización. → `organizations` |
| `project_id` | `uuid` | Sí | Proyecto padre; debe pertenecer a la organización. → `projects` |
| `created_at` | `timestamptz` | Sí; `now()` | Fecha de creación UTC. |
| `updated_at` | `timestamptz` | Sí; `now()` | Última modificación; trigger de servidor. |
| `name` | `text` | Sí | Nombre |
| `trigger_code` | `text` | Sí | Evento permitido |
| `conditions` | `jsonb` | Sí; `'{}'::jsonb` | Filtros tipados |
| `actions` | `jsonb` | Sí | Acciones de lista blanca |
| `enabled` | `boolean` | Sí; `false` | Activación |
| `created_by` | `uuid` | Sí | Responsable → `memberships` |
| `next_run_at` | `timestamptz` | No | Siguiente ejecución |

**Integridad:** PK `id`. UQ `(organization_id, id)`. UQ `(organization_id, project_id, id)`. 

**FK (todas `ON DELETE RESTRICT`):**

- `(organization_id)` → `organizations(id)`.
- `(organization_id, project_id)` → `projects(organization_id, id)`.
- `(organization_id, created_by)` → `memberships(organization_id, id)`.

**Contrato de autorización:** Leer coordinador; crear/activar por automation.manage; worker revalida alcance y evita ciclos.

---

### automation_runs

![Fase: MVP / Fase 2](https://img.shields.io/static/v1?label=Fase&message=MVP%20/%20Fase%202&color=0066FF&style=for-the-badge) ![Ámbito: project](https://img.shields.io/static/v1?label=%C3%81mbito&message=project&color=0A1A3A&style=for-the-badge)

Ejecuciones idempotentes de reglas.

| Columna SQL | Tipo PostgreSQL | Obligatorio / default | Descripción |
|---|---|---|---|
| `id` | `uuid` | Sí; `gen_random_uuid()` | Identificador interno opaco; PK. |
| `organization_id` | `uuid` | Sí | Frontera obligatoria de organización. → `organizations` |
| `project_id` | `uuid` | Sí | Proyecto padre; debe pertenecer a la organización. → `projects` |
| `created_at` | `timestamptz` | Sí; `now()` | Fecha de creación UTC. |
| `updated_at` | `timestamptz` | Sí; `now()` | Última modificación; trigger de servidor. |
| `rule_id` | `uuid` | Sí | Regla → `automation_rules` |
| `trigger_key` | `text` | Sí | Identificador de evento único |
| `status` | `text` | Sí; `'queued'` | queued, running, succeeded, failed, cancelled |
| `result` | `jsonb` | No | Resumen redactado |

**Integridad:** PK `id`. UQ `(organization_id, id)`. UQ `(organization_id, project_id, id)`. UQ `(rule_id, trigger_key)`. CHECK: `status IN ('queued','running','succeeded','failed','cancelled')`.

**FK (todas `ON DELETE RESTRICT`):**

- `(organization_id)` → `organizations(id)`.
- `(organization_id, project_id)` → `projects(organization_id, id)`.
- `(organization_id, project_id, rule_id)` → `automation_rules(organization_id, project_id, id)`.

**Contrato de autorización:** Leer gestor del proyecto; escritura worker limitado.

---

## 04. Knowledge Center y RAG

[`documents`](#documents) | [`document_versions`](#document_versions) | [`document_acl`](#document_acl) | [`index_jobs`](#index_jobs) | [`source_refs`](#source_refs)

### documents

![Fase: MVP / Fase 2](https://img.shields.io/static/v1?label=Fase&message=MVP%20/%20Fase%202&color=0066FF&style=for-the-badge) ![Ámbito: org](https://img.shields.io/static/v1?label=%C3%81mbito&message=org&color=0A1A3A&style=for-the-badge)

Documento lógico con audiencia y ciclo editorial.

| Columna SQL | Tipo PostgreSQL | Obligatorio / default | Descripción |
|---|---|---|---|
| `id` | `uuid` | Sí; `gen_random_uuid()` | Identificador interno opaco; PK. |
| `organization_id` | `uuid` | Sí | Frontera obligatoria de organización. → `organizations` |
| `created_at` | `timestamptz` | Sí; `now()` | Fecha de creación UTC. |
| `updated_at` | `timestamptz` | Sí; `now()` | Última modificación; trigger de servidor. |
| `project_id` | `uuid` | No | Ámbito de proyecto si corresponde → `projects` |
| `title` | `text` | Sí | Nombre del documento |
| `category` | `text` | Sí | manual, policy, technical, commercial u otra categoría |
| `visibility` | `text` | Sí; `'restricted'` | organization, project, restricted |
| `owner_id` | `uuid` | Sí | Responsable editorial → `memberships` |
| `status` | `text` | Sí; `'draft'` | draft, published, withdrawn, archived |
| `archived_at` | `timestamptz` | No | Archivo |

**Integridad:** PK `id`. UQ `(organization_id, id)`. CHECK: `visibility IN ('organization','project','restricted')`; `visibility <> 'project' OR project_id IS NOT NULL`; `status IN ('draft','published','withdrawn','archived')`.

**FK (todas `ON DELETE RESTRICT`):**

- `(organization_id)` → `organizations(id)`.
- `(organization_id, project_id)` → `projects(organization_id, id)`.
- `(organization_id, owner_id)` → `memberships(organization_id, id)`.

**Contrato de autorización:** Publicado y audiencia válida, ACL explícita o editor/revisor delegado; no acceso automático por admin.

---

### document_versions

![Fase: MVP / Fase 2](https://img.shields.io/static/v1?label=Fase&message=MVP%20/%20Fase%202&color=0066FF&style=for-the-badge) ![Ámbito: org](https://img.shields.io/static/v1?label=%C3%81mbito&message=org&color=0A1A3A&style=for-the-badge)

Versiones de archivo y contenido aprobadas.

| Columna SQL | Tipo PostgreSQL | Obligatorio / default | Descripción |
|---|---|---|---|
| `id` | `uuid` | Sí; `gen_random_uuid()` | Identificador interno opaco; PK. |
| `organization_id` | `uuid` | Sí | Frontera obligatoria de organización. → `organizations` |
| `created_at` | `timestamptz` | Sí; `now()` | Fecha de creación UTC. |
| `updated_at` | `timestamptz` | Sí; `now()` | Última modificación; trigger de servidor. |
| `document_id` | `uuid` | Sí | Documento padre → `documents` |
| `revision` | `integer` | Sí | Versión correlativa |
| `file_id` | `uuid` | Sí | Archivo original → `files` |
| `content_hash` | `text` | Sí | Hash del contenido |
| `status` | `text` | Sí; `'draft'` | draft, in_review, approved, published, superseded, withdrawn |
| `created_by` | `uuid` | Sí | Editor → `memberships` |
| `approved_by` | `uuid` | No | Revisor distinto → `memberships` |
| `published_at` | `timestamptz` | No | Publicación efectiva |
| `valid_from` | `timestamptz` | No | Inicio de vigencia |
| `valid_until` | `timestamptz` | No | Fin de vigencia |

**Integridad:** PK `id`. UQ `(organization_id, id)`. UQ `(document_id, revision)`. CHECK: `revision > 0`; `approved_by <> created_by`; `valid_until > valid_from`; `status IN ('draft','in_review','approved','published','superseded','withdrawn')`; `status <> 'published' OR (approved_by IS NOT NULL AND published_at IS NOT NULL AND valid_from IS NOT NULL)`.

**FK (todas `ON DELETE RESTRICT`):**

- `(organization_id)` → `organizations(id)`.
- `(organization_id, document_id)` → `documents(organization_id, id)`.
- `(organization_id, file_id)` → `files(organization_id, id)`.
- `(organization_id, created_by)` → `memberships(organization_id, id)`.
- `(organization_id, approved_by)` → `memberships(organization_id, id)`.

**Índice único parcial:** `uq_document_published` sobre `(document_id)`, WHERE `status = 'published'`.

**Contrato de autorización:** Lectores solo versión publicada vigente; borrador por editor/revisor; publicar con aprobación y transacción.

---

### document_acl

![Fase: MVP / Fase 2](https://img.shields.io/static/v1?label=Fase&message=MVP%20/%20Fase%202&color=0066FF&style=for-the-badge) ![Ámbito: org](https://img.shields.io/static/v1?label=%C3%81mbito&message=org&color=0A1A3A&style=for-the-badge)

Concesiones de lectura de documento a miembros específicos.

| Columna SQL | Tipo PostgreSQL | Obligatorio / default | Descripción |
|---|---|---|---|
| `id` | `uuid` | Sí; `gen_random_uuid()` | Identificador interno opaco; PK. |
| `organization_id` | `uuid` | Sí | Frontera obligatoria de organización. → `organizations` |
| `created_at` | `timestamptz` | Sí; `now()` | Fecha de creación UTC. |
| `updated_at` | `timestamptz` | Sí; `now()` | Última modificación; trigger de servidor. |
| `document_id` | `uuid` | Sí | Documento → `documents` |
| `membership_id` | `uuid` | Sí | Miembro autorizado → `memberships` |
| `expires_at` | `timestamptz` | No | Vigencia del acceso |
| `revoked_at` | `timestamptz` | No | Revocación |

**Integridad:** PK `id`. UQ `(organization_id, id)`. UQ `(document_id, membership_id)`. 

**FK (todas `ON DELETE RESTRICT`):**

- `(organization_id)` → `organizations(id)`.
- `(organization_id, document_id)` → `documents(organization_id, id)`.
- `(organization_id, membership_id)` → `memberships(organization_id, id)`.

**Contrato de autorización:** Titular de permiso o gestor documental autorizado; administrar ACL con auditoría.

---

### index_jobs

![Fase: MVP / Fase 2](https://img.shields.io/static/v1?label=Fase&message=MVP%20/%20Fase%202&color=0066FF&style=for-the-badge) ![Ámbito: org](https://img.shields.io/static/v1?label=%C3%81mbito&message=org&color=0A1A3A&style=for-the-badge)

Cola de indexación y retirada del conocimiento.

| Columna SQL | Tipo PostgreSQL | Obligatorio / default | Descripción |
|---|---|---|---|
| `id` | `uuid` | Sí; `gen_random_uuid()` | Identificador interno opaco; PK. |
| `organization_id` | `uuid` | Sí | Frontera obligatoria de organización. → `organizations` |
| `created_at` | `timestamptz` | Sí; `now()` | Fecha de creación UTC. |
| `updated_at` | `timestamptz` | Sí; `now()` | Última modificación; trigger de servidor. |
| `document_version_id` | `uuid` | Sí | Versión objetivo → `document_versions` |
| `operation` | `text` | Sí | upsert o remove |
| `status` | `text` | Sí; `'queued'` | queued, running, succeeded, failed, cancelled |
| `attempts` | `integer` | Sí; `0` | Reintentos |
| `provider_ref` | `text` | No | ID externo opaco |
| `last_error_code` | `text` | No | Error redactado |
| `finished_at` | `timestamptz` | No | Fin |

**Integridad:** PK `id`. UQ `(organization_id, id)`. CHECK: `operation IN ('upsert','remove')`; `attempts >= 0`; `status IN ('queued','running','succeeded','failed','cancelled')`.

**FK (todas `ON DELETE RESTRICT`):**

- `(organization_id)` → `organizations(id)`.
- `(organization_id, document_version_id)` → `document_versions(organization_id, id)`.

**Contrato de autorización:** Leer estado por editor autorizado; worker indexador específico escribe.

---

### source_refs

![Fase: MVP / Fase 2](https://img.shields.io/static/v1?label=Fase&message=MVP%20/%20Fase%202&color=0066FF&style=for-the-badge) ![Ámbito: org](https://img.shields.io/static/v1?label=%C3%81mbito&message=org&color=0A1A3A&style=for-the-badge)

Referencias recuperables a fragmentos indexados.

| Columna SQL | Tipo PostgreSQL | Obligatorio / default | Descripción |
|---|---|---|---|
| `id` | `uuid` | Sí; `gen_random_uuid()` | Identificador interno opaco; PK. |
| `organization_id` | `uuid` | Sí | Frontera obligatoria de organización. → `organizations` |
| `created_at` | `timestamptz` | Sí; `now()` | Fecha de creación UTC. |
| `updated_at` | `timestamptz` | Sí; `now()` | Última modificación; trigger de servidor. |
| `document_version_id` | `uuid` | Sí | Versión fuente → `document_versions` |
| `chunk_key` | `text` | Sí | Clave estable de fragmento |
| `page_number` | `integer` | No | Página cuando existe |
| `section_title` | `text` | No | Sección |
| `provider_ref` | `text` | No | ID de índice externo |
| `content_hash` | `text` | Sí | Hash del fragmento |
| `revoked_at` | `timestamptz` | No | Invalida recuperación |

**Integridad:** PK `id`. UQ `(organization_id, id)`. UQ `(document_version_id, chunk_key)`. CHECK: `page_number > 0`.

**FK (todas `ON DELETE RESTRICT`):**

- `(organization_id)` → `organizations(id)`.
- `(organization_id, document_version_id)` → `document_versions(organization_id, id)`.

**Contrato de autorización:** Leer solo fuente autorizada y vigente; indexador crea/revoca; revalidar antes de enviar a IA.

---

## 05. MIA Academy

[`learning_paths`](#learning_paths) | [`courses`](#courses) | [`course_versions`](#course_versions) | [`path_courses`](#path_courses) | [`course_modules`](#course_modules) | [`lessons`](#lessons) | [`lesson_resources`](#lesson_resources) | [`enrollments`](#enrollments) | [`lesson_progress`](#lesson_progress) | [`assessments`](#assessments) | [`assessment_questions`](#assessment_questions) | [`assessment_answer_keys`](#assessment_answer_keys) | [`attempts`](#attempts) | [`attempt_answers`](#attempt_answers) | [`mentoring_sessions`](#mentoring_sessions) | [`forum_posts`](#forum_posts) | [`achievements`](#achievements) | [`member_achievements`](#member_achievements) | [`certificates`](#certificates)

### learning_paths

![Fase: Fase 2](https://img.shields.io/static/v1?label=Fase&message=Fase%202&color=0066FF&style=for-the-badge) ![Ámbito: org](https://img.shields.io/static/v1?label=%C3%81mbito&message=org&color=0A1A3A&style=for-the-badge)

Rutas de formación por especialidad.

| Columna SQL | Tipo PostgreSQL | Obligatorio / default | Descripción |
|---|---|---|---|
| `id` | `uuid` | Sí; `gen_random_uuid()` | Identificador interno opaco; PK. |
| `organization_id` | `uuid` | Sí | Frontera obligatoria de organización. → `organizations` |
| `created_at` | `timestamptz` | Sí; `now()` | Fecha de creación UTC. |
| `updated_at` | `timestamptz` | Sí; `now()` | Última modificación; trigger de servidor. |
| `slug` | `text` | Sí | Identificador |
| `name` | `text` | Sí | Nombre |
| `description` | `text` | No | Objetivo |
| `status` | `text` | Sí; `'draft'` | draft, published, archived |

**Integridad:** PK `id`. UQ `(organization_id, id)`. UQ `(organization_id, slug)`. CHECK: `status IN ('draft','published','archived')`.

**FK (todas `ON DELETE RESTRICT`):**

- `(organization_id)` → `organizations(id)`.

**Contrato de autorización:** Leer publicados por miembros habilitados; editar/publicar por permiso Academy.

---

### courses

![Fase: Fase 2](https://img.shields.io/static/v1?label=Fase&message=Fase%202&color=0066FF&style=for-the-badge) ![Ámbito: org](https://img.shields.io/static/v1?label=%C3%81mbito&message=org&color=0A1A3A&style=for-the-badge)

Curso lógico y propietario editorial.

| Columna SQL | Tipo PostgreSQL | Obligatorio / default | Descripción |
|---|---|---|---|
| `id` | `uuid` | Sí; `gen_random_uuid()` | Identificador interno opaco; PK. |
| `organization_id` | `uuid` | Sí | Frontera obligatoria de organización. → `organizations` |
| `created_at` | `timestamptz` | Sí; `now()` | Fecha de creación UTC. |
| `updated_at` | `timestamptz` | Sí; `now()` | Última modificación; trigger de servidor. |
| `slug` | `text` | Sí | Identificador |
| `name` | `text` | Sí | Nombre |
| `specialty` | `text` | Sí | Área |
| `level` | `text` | Sí | beginner, intermediate, advanced |
| `owner_id` | `uuid` | Sí | Responsable → `memberships` |
| `status` | `text` | Sí; `'draft'` | draft, published, archived |

**Integridad:** PK `id`. UQ `(organization_id, id)`. UQ `(organization_id, slug)`. CHECK: `status IN ('draft','published','archived')`; `level IN ('beginner','intermediate','advanced')`.

**FK (todas `ON DELETE RESTRICT`):**

- `(organization_id)` → `organizations(id)`.
- `(organization_id, owner_id)` → `memberships(organization_id, id)`.

**Contrato de autorización:** Leer catálogo publicado; gestionar por academy.edit/publish separados.

---

### course_versions

![Fase: Fase 2](https://img.shields.io/static/v1?label=Fase&message=Fase%202&color=0066FF&style=for-the-badge) ![Ámbito: org](https://img.shields.io/static/v1?label=%C3%81mbito&message=org&color=0A1A3A&style=for-the-badge)

Versiones inmutables de temario publicado.

| Columna SQL | Tipo PostgreSQL | Obligatorio / default | Descripción |
|---|---|---|---|
| `id` | `uuid` | Sí; `gen_random_uuid()` | Identificador interno opaco; PK. |
| `organization_id` | `uuid` | Sí | Frontera obligatoria de organización. → `organizations` |
| `created_at` | `timestamptz` | Sí; `now()` | Fecha de creación UTC. |
| `updated_at` | `timestamptz` | Sí; `now()` | Última modificación; trigger de servidor. |
| `course_id` | `uuid` | Sí | Curso → `courses` |
| `revision` | `integer` | Sí | Número de versión |
| `status` | `text` | Sí; `'draft'` | draft, in_review, published, retired |
| `created_by` | `uuid` | Sí | Editor → `memberships` |
| `approved_by` | `uuid` | No | Revisor → `memberships` |
| `published_at` | `timestamptz` | No | Publicación |

**Integridad:** PK `id`. UQ `(organization_id, id)`. UQ `(course_id, revision)`. CHECK: `revision > 0`; `approved_by <> created_by`; `status IN ('draft','in_review','published','retired')`; `status <> 'published' OR (approved_by IS NOT NULL AND published_at IS NOT NULL)`.

**FK (todas `ON DELETE RESTRICT`):**

- `(organization_id)` → `organizations(id)`.
- `(organization_id, course_id)` → `courses(organization_id, id)`.
- `(organization_id, created_by)` → `memberships(organization_id, id)`.
- `(organization_id, approved_by)` → `memberships(organization_id, id)`.

**Índice único parcial:** `uq_course_published` sobre `(course_id)`, WHERE `status = 'published'`.

**Contrato de autorización:** Leer versión publicada o matrícula válida; editor/revisor lee borrador; publicación separada.

---

### path_courses

![Fase: Fase 2](https://img.shields.io/static/v1?label=Fase&message=Fase%202&color=0066FF&style=for-the-badge) ![Ámbito: org](https://img.shields.io/static/v1?label=%C3%81mbito&message=org&color=0A1A3A&style=for-the-badge)

Cursos ordenados dentro de una ruta.

| Columna SQL | Tipo PostgreSQL | Obligatorio / default | Descripción |
|---|---|---|---|
| `id` | `uuid` | Sí; `gen_random_uuid()` | Identificador interno opaco; PK. |
| `organization_id` | `uuid` | Sí | Frontera obligatoria de organización. → `organizations` |
| `created_at` | `timestamptz` | Sí; `now()` | Fecha de creación UTC. |
| `updated_at` | `timestamptz` | Sí; `now()` | Última modificación; trigger de servidor. |
| `path_id` | `uuid` | Sí | Ruta → `learning_paths` |
| `course_id` | `uuid` | Sí | Curso → `courses` |
| `position` | `integer` | Sí | Orden |
| `required` | `boolean` | Sí; `true` | Obligatorio para completar |

**Integridad:** PK `id`. UQ `(organization_id, id)`. UQ `(path_id, course_id)`. CHECK: `position >= 0`.

**FK (todas `ON DELETE RESTRICT`):**

- `(organization_id)` → `organizations(id)`.
- `(organization_id, path_id)` → `learning_paths(organization_id, id)`.
- `(organization_id, course_id)` → `courses(organization_id, id)`.

**Contrato de autorización:** Leer ruta autorizada; modificar por editor de ruta.

---

### course_modules

![Fase: Fase 2](https://img.shields.io/static/v1?label=Fase&message=Fase%202&color=0066FF&style=for-the-badge) ![Ámbito: org](https://img.shields.io/static/v1?label=%C3%81mbito&message=org&color=0A1A3A&style=for-the-badge)

Módulos de una versión de curso.

| Columna SQL | Tipo PostgreSQL | Obligatorio / default | Descripción |
|---|---|---|---|
| `id` | `uuid` | Sí; `gen_random_uuid()` | Identificador interno opaco; PK. |
| `organization_id` | `uuid` | Sí | Frontera obligatoria de organización. → `organizations` |
| `created_at` | `timestamptz` | Sí; `now()` | Fecha de creación UTC. |
| `updated_at` | `timestamptz` | Sí; `now()` | Última modificación; trigger de servidor. |
| `course_version_id` | `uuid` | Sí | Versión → `course_versions` |
| `name` | `text` | Sí | Nombre |
| `position` | `integer` | Sí | Orden |

**Integridad:** PK `id`. UQ `(organization_id, id)`. UQ `(course_version_id, position)`. CHECK: `position >= 0`.

**FK (todas `ON DELETE RESTRICT`):**

- `(organization_id)` → `organizations(id)`.
- `(organization_id, course_version_id)` → `course_versions(organization_id, id)`.

**Contrato de autorización:** Hereda acceso a versión del curso; edición solo borrador.

---

### lessons

![Fase: Fase 2](https://img.shields.io/static/v1?label=Fase&message=Fase%202&color=0066FF&style=for-the-badge) ![Ámbito: org](https://img.shields.io/static/v1?label=%C3%81mbito&message=org&color=0A1A3A&style=for-the-badge)

Lecciones, teoría, video y práctica.

| Columna SQL | Tipo PostgreSQL | Obligatorio / default | Descripción |
|---|---|---|---|
| `id` | `uuid` | Sí; `gen_random_uuid()` | Identificador interno opaco; PK. |
| `organization_id` | `uuid` | Sí | Frontera obligatoria de organización. → `organizations` |
| `created_at` | `timestamptz` | Sí; `now()` | Fecha de creación UTC. |
| `updated_at` | `timestamptz` | Sí; `now()` | Última modificación; trigger de servidor. |
| `course_module_id` | `uuid` | Sí | Módulo → `course_modules` |
| `title` | `text` | Sí | Título |
| `kind` | `text` | Sí | article, video, lab, quiz |
| `content` | `jsonb` | Sí; `'{}'::jsonb` | Contenido estructurado |
| `estimated_minutes` | `integer` | No | Duración orientativa |
| `position` | `integer` | Sí | Orden |

**Integridad:** PK `id`. UQ `(organization_id, id)`. UQ `(course_module_id, position)`. CHECK: `kind IN ('article','video','lab','quiz')`; `estimated_minutes >= 0`; `position >= 0`.

**FK (todas `ON DELETE RESTRICT`):**

- `(organization_id)` → `organizations(id)`.
- `(organization_id, course_module_id)` → `course_modules(organization_id, id)`.

**Contrato de autorización:** Leer versión autorizada; editar solo borrador.

---

### lesson_resources

![Fase: Fase 2](https://img.shields.io/static/v1?label=Fase&message=Fase%202&color=0066FF&style=for-the-badge) ![Ámbito: org](https://img.shields.io/static/v1?label=%C3%81mbito&message=org&color=0A1A3A&style=for-the-badge)

Material complementario aprobado.

| Columna SQL | Tipo PostgreSQL | Obligatorio / default | Descripción |
|---|---|---|---|
| `id` | `uuid` | Sí; `gen_random_uuid()` | Identificador interno opaco; PK. |
| `organization_id` | `uuid` | Sí | Frontera obligatoria de organización. → `organizations` |
| `created_at` | `timestamptz` | Sí; `now()` | Fecha de creación UTC. |
| `updated_at` | `timestamptz` | Sí; `now()` | Última modificación; trigger de servidor. |
| `lesson_id` | `uuid` | Sí | Lección → `lessons` |
| `file_id` | `uuid` | No | Archivo privado → `files` |
| `document_version_id` | `uuid` | No | Fuente documental → `document_versions` |
| `title` | `text` | Sí | Nombre |

**Integridad:** PK `id`. UQ `(organization_id, id)`. CHECK: `num_nonnulls(file_id,document_version_id) = 1`.

**FK (todas `ON DELETE RESTRICT`):**

- `(organization_id)` → `organizations(id)`.
- `(organization_id, lesson_id)` → `lessons(organization_id, id)`.
- `(organization_id, file_id)` → `files(organization_id, id)`.
- `(organization_id, document_version_id)` → `document_versions(organization_id, id)`.

**Contrato de autorización:** Hereda acceso a lección y además a documento si aplica; editor en borrador.

---

### enrollments

![Fase: Fase 2](https://img.shields.io/static/v1?label=Fase&message=Fase%202&color=0066FF&style=for-the-badge) ![Ámbito: org](https://img.shields.io/static/v1?label=%C3%81mbito&message=org&color=0A1A3A&style=for-the-badge)

Matrículas fijadas a una versión concreta.

| Columna SQL | Tipo PostgreSQL | Obligatorio / default | Descripción |
|---|---|---|---|
| `id` | `uuid` | Sí; `gen_random_uuid()` | Identificador interno opaco; PK. |
| `organization_id` | `uuid` | Sí | Frontera obligatoria de organización. → `organizations` |
| `created_at` | `timestamptz` | Sí; `now()` | Fecha de creación UTC. |
| `updated_at` | `timestamptz` | Sí; `now()` | Última modificación; trigger de servidor. |
| `course_version_id` | `uuid` | Sí | Versión cursada → `course_versions` |
| `membership_id` | `uuid` | Sí | Alumno → `memberships` |
| `assigned_by` | `uuid` | No | Mentor que asignó → `memberships` |
| `status` | `text` | Sí; `'active'` | active, completed, withdrawn |
| `completed_at` | `timestamptz` | No | Finalización |

**Integridad:** PK `id`. UQ `(organization_id, id)`. UQ `(course_version_id, membership_id)`. CHECK: `status IN ('active','completed','withdrawn')`.

**FK (todas `ON DELETE RESTRICT`):**

- `(organization_id)` → `organizations(id)`.
- `(organization_id, course_version_id)` → `course_versions(organization_id, id)`.
- `(organization_id, membership_id)` → `memberships(organization_id, id)`.
- `(organization_id, assigned_by)` → `memberships(organization_id, id)`.

**Contrato de autorización:** Alumno propio; mentor/supervisor con cartera; alta por matrícula autorizada.

---

### lesson_progress

![Fase: Fase 2](https://img.shields.io/static/v1?label=Fase&message=Fase%202&color=0066FF&style=for-the-badge) ![Ámbito: org](https://img.shields.io/static/v1?label=%C3%81mbito&message=org&color=0A1A3A&style=for-the-badge)

Progreso validado por servidor.

| Columna SQL | Tipo PostgreSQL | Obligatorio / default | Descripción |
|---|---|---|---|
| `id` | `uuid` | Sí; `gen_random_uuid()` | Identificador interno opaco; PK. |
| `organization_id` | `uuid` | Sí | Frontera obligatoria de organización. → `organizations` |
| `created_at` | `timestamptz` | Sí; `now()` | Fecha de creación UTC. |
| `updated_at` | `timestamptz` | Sí; `now()` | Última modificación; trigger de servidor. |
| `enrollment_id` | `uuid` | Sí | Matrícula → `enrollments` |
| `lesson_id` | `uuid` | Sí | Lección de la versión → `lessons` |
| `status` | `text` | Sí; `'not_started'` | not_started, in_progress, completed |
| `seconds_spent` | `integer` | Sí; `0` | Tiempo registrado |
| `completed_at` | `timestamptz` | No | Finalización |

**Integridad:** PK `id`. UQ `(organization_id, id)`. UQ `(enrollment_id, lesson_id)`. CHECK: `seconds_spent >= 0`; `status IN ('not_started','in_progress','completed')`.

**FK (todas `ON DELETE RESTRICT`):**

- `(organization_id)` → `organizations(id)`.
- `(organization_id, enrollment_id)` → `enrollments(organization_id, id)`.
- `(organization_id, lesson_id)` → `lessons(organization_id, id)`.

**Contrato de autorización:** Alumno y mentor autorizado; servidor verifica lección pertenece a versión y requisitos.

---

### assessments

![Fase: Fase 2](https://img.shields.io/static/v1?label=Fase&message=Fase%202&color=0066FF&style=for-the-badge) ![Ámbito: org](https://img.shields.io/static/v1?label=%C3%81mbito&message=org&color=0A1A3A&style=for-the-badge)

Evaluaciones y laboratorios evaluables.

| Columna SQL | Tipo PostgreSQL | Obligatorio / default | Descripción |
|---|---|---|---|
| `id` | `uuid` | Sí; `gen_random_uuid()` | Identificador interno opaco; PK. |
| `organization_id` | `uuid` | Sí | Frontera obligatoria de organización. → `organizations` |
| `created_at` | `timestamptz` | Sí; `now()` | Fecha de creación UTC. |
| `updated_at` | `timestamptz` | Sí; `now()` | Última modificación; trigger de servidor. |
| `course_version_id` | `uuid` | Sí | Versión → `course_versions` |
| `lesson_id` | `uuid` | No | Lección asociada → `lessons` |
| `title` | `text` | Sí | Título |
| `passing_score` | `numeric(5,2)` | Sí; `70` | Umbral porcentual |
| `max_attempts` | `integer` | Sí; `3` | Intentos máximos |
| `status` | `text` | Sí; `'draft'` | Estado editorial |

**Integridad:** PK `id`. UQ `(organization_id, id)`. CHECK: `passing_score BETWEEN 0 AND 100`; `max_attempts > 0`; `status IN ('draft','published','retired')`.

**FK (todas `ON DELETE RESTRICT`):**

- `(organization_id)` → `organizations(id)`.
- `(organization_id, course_version_id)` → `course_versions(organization_id, id)`.
- `(organization_id, lesson_id)` → `lessons(organization_id, id)`.

**Contrato de autorización:** Leer evaluación de curso autorizado; edición solo borrador.

---

### assessment_questions

![Fase: Fase 2](https://img.shields.io/static/v1?label=Fase&message=Fase%202&color=0066FF&style=for-the-badge) ![Ámbito: org](https://img.shields.io/static/v1?label=%C3%81mbito&message=org&color=0A1A3A&style=for-the-badge)

Enunciados y opciones sin solución.

| Columna SQL | Tipo PostgreSQL | Obligatorio / default | Descripción |
|---|---|---|---|
| `id` | `uuid` | Sí; `gen_random_uuid()` | Identificador interno opaco; PK. |
| `organization_id` | `uuid` | Sí | Frontera obligatoria de organización. → `organizations` |
| `created_at` | `timestamptz` | Sí; `now()` | Fecha de creación UTC. |
| `updated_at` | `timestamptz` | Sí; `now()` | Última modificación; trigger de servidor. |
| `assessment_id` | `uuid` | Sí | Evaluación → `assessments` |
| `prompt` | `text` | Sí | Enunciado |
| `kind` | `text` | Sí | single, multiple, text, lab |
| `options` | `jsonb` | Sí; `'[]'::jsonb` | Opciones públicas de pregunta |
| `points` | `numeric(8,2)` | Sí; `1` | Puntuación |
| `position` | `integer` | Sí | Orden |

**Integridad:** PK `id`. UQ `(organization_id, id)`. UQ `(assessment_id, position)`. CHECK: `points > 0`; `position >= 0`; `kind IN ('single','multiple','text','lab')`.

**FK (todas `ON DELETE RESTRICT`):**

- `(organization_id)` → `organizations(id)`.
- `(organization_id, assessment_id)` → `assessments(organization_id, id)`.

**Contrato de autorización:** Alumno en intento autorizado; editor de borrador; no incluye respuesta correcta.

---

### assessment_answer_keys

![Fase: Fase 2](https://img.shields.io/static/v1?label=Fase&message=Fase%202&color=0066FF&style=for-the-badge) ![Ámbito: org](https://img.shields.io/static/v1?label=%C3%81mbito&message=org&color=0A1A3A&style=for-the-badge)

Soluciones y rúbricas separadas del enunciado.

| Columna SQL | Tipo PostgreSQL | Obligatorio / default | Descripción |
|---|---|---|---|
| `id` | `uuid` | Sí; `gen_random_uuid()` | Identificador interno opaco; PK. |
| `organization_id` | `uuid` | Sí | Frontera obligatoria de organización. → `organizations` |
| `created_at` | `timestamptz` | Sí; `now()` | Fecha de creación UTC. |
| `updated_at` | `timestamptz` | Sí; `now()` | Última modificación; trigger de servidor. |
| `question_id` | `uuid` | Sí | Pregunta → `assessment_questions` |
| `answer` | `jsonb` | Sí | Solución y rúbrica |

**Integridad:** PK `id`. UQ `(organization_id, id)`. UQ `(question_id)`. 

**FK (todas `ON DELETE RESTRICT`):**

- `(organization_id)` → `organizations(id)`.
- `(organization_id, question_id)` → `assessment_questions(organization_id, id)`.

**Contrato de autorización:** Solo evaluador/servicio de corrección con permiso; jamás alumno ni MIA general.

---

### attempts

![Fase: Fase 2](https://img.shields.io/static/v1?label=Fase&message=Fase%202&color=0066FF&style=for-the-badge) ![Ámbito: org](https://img.shields.io/static/v1?label=%C3%81mbito&message=org&color=0A1A3A&style=for-the-badge)

Intentos de evaluación y resultado.

| Columna SQL | Tipo PostgreSQL | Obligatorio / default | Descripción |
|---|---|---|---|
| `id` | `uuid` | Sí; `gen_random_uuid()` | Identificador interno opaco; PK. |
| `organization_id` | `uuid` | Sí | Frontera obligatoria de organización. → `organizations` |
| `created_at` | `timestamptz` | Sí; `now()` | Fecha de creación UTC. |
| `updated_at` | `timestamptz` | Sí; `now()` | Última modificación; trigger de servidor. |
| `enrollment_id` | `uuid` | Sí | Matrícula → `enrollments` |
| `assessment_id` | `uuid` | Sí | Evaluación → `assessments` |
| `attempt_number` | `integer` | Sí | Número de intento |
| `status` | `text` | Sí; `'in_progress'` | in_progress, submitted, graded |
| `submitted_at` | `timestamptz` | No | Envío |
| `score` | `numeric(5,2)` | No | Puntaje porcentual |
| `graded_at` | `timestamptz` | No | Corrección |

**Integridad:** PK `id`. UQ `(organization_id, id)`. UQ `(enrollment_id, assessment_id, attempt_number)`. CHECK: `attempt_number > 0`; `score BETWEEN 0 AND 100`; `status IN ('in_progress','submitted','graded')`.

**FK (todas `ON DELETE RESTRICT`):**

- `(organization_id)` → `organizations(id)`.
- `(organization_id, enrollment_id)` → `enrollments(organization_id, id)`.
- `(organization_id, assessment_id)` → `assessments(organization_id, id)`.

**Contrato de autorización:** Alumno ve propio; evaluador asignado; score solo calculado por servidor.

---

### attempt_answers

![Fase: Fase 2](https://img.shields.io/static/v1?label=Fase&message=Fase%202&color=0066FF&style=for-the-badge) ![Ámbito: org](https://img.shields.io/static/v1?label=%C3%81mbito&message=org&color=0A1A3A&style=for-the-badge)

Respuestas del alumno, incluyendo evidencia de laboratorio.

| Columna SQL | Tipo PostgreSQL | Obligatorio / default | Descripción |
|---|---|---|---|
| `id` | `uuid` | Sí; `gen_random_uuid()` | Identificador interno opaco; PK. |
| `organization_id` | `uuid` | Sí | Frontera obligatoria de organización. → `organizations` |
| `created_at` | `timestamptz` | Sí; `now()` | Fecha de creación UTC. |
| `updated_at` | `timestamptz` | Sí; `now()` | Última modificación; trigger de servidor. |
| `attempt_id` | `uuid` | Sí | Intento → `attempts` |
| `question_id` | `uuid` | Sí | Pregunta → `assessment_questions` |
| `answer` | `jsonb` | Sí | Respuesta |
| `file_id` | `uuid` | No | Evidencia → `files` |
| `awarded_points` | `numeric(8,2)` | No | Puntos adjudicados |
| `feedback` | `text` | No | Retroalimentación |

**Integridad:** PK `id`. UQ `(organization_id, id)`. UQ `(attempt_id, question_id)`. CHECK: `awarded_points >= 0`.

**FK (todas `ON DELETE RESTRICT`):**

- `(organization_id)` → `organizations(id)`.
- `(organization_id, attempt_id)` → `attempts(organization_id, id)`.
- `(organization_id, question_id)` → `assessment_questions(organization_id, id)`.
- `(organization_id, file_id)` → `files(organization_id, id)`.

**Contrato de autorización:** Alumno edita antes de enviar; evaluador corrige; validar pregunta y puntos.

---

### mentoring_sessions

![Fase: Fase 2](https://img.shields.io/static/v1?label=Fase&message=Fase%202&color=0066FF&style=for-the-badge) ![Ámbito: org](https://img.shields.io/static/v1?label=%C3%81mbito&message=org&color=0A1A3A&style=for-the-badge)

Mentorías programadas.

| Columna SQL | Tipo PostgreSQL | Obligatorio / default | Descripción |
|---|---|---|---|
| `id` | `uuid` | Sí; `gen_random_uuid()` | Identificador interno opaco; PK. |
| `organization_id` | `uuid` | Sí | Frontera obligatoria de organización. → `organizations` |
| `created_at` | `timestamptz` | Sí; `now()` | Fecha de creación UTC. |
| `updated_at` | `timestamptz` | Sí; `now()` | Última modificación; trigger de servidor. |
| `mentor_id` | `uuid` | Sí | Mentor → `memberships` |
| `student_id` | `uuid` | Sí | Alumno → `memberships` |
| `starts_at` | `timestamptz` | Sí | Inicio |
| `ends_at` | `timestamptz` | Sí | Fin |
| `status` | `text` | Sí; `'scheduled'` | scheduled, completed, cancelled |
| `topic` | `text` | Sí | Tema |
| `summary` | `text` | No | Acuerdos compartidos |

**Integridad:** PK `id`. UQ `(organization_id, id)`. CHECK: `mentor_id <> student_id`; `ends_at > starts_at`; `status IN ('scheduled','completed','cancelled')`.

**FK (todas `ON DELETE RESTRICT`):**

- `(organization_id)` → `organizations(id)`.
- `(organization_id, mentor_id)` → `memberships(organization_id, id)`.
- `(organization_id, student_id)` → `memberships(organization_id, id)`.

**Contrato de autorización:** Participantes y coordinador autorizado; notas privadas excluidas del resumen.

---

### forum_posts

![Fase: Fase 2](https://img.shields.io/static/v1?label=Fase&message=Fase%202&color=0066FF&style=for-the-badge) ![Ámbito: org](https://img.shields.io/static/v1?label=%C3%81mbito&message=org&color=0A1A3A&style=for-the-badge)

Preguntas y soluciones compartidas.

| Columna SQL | Tipo PostgreSQL | Obligatorio / default | Descripción |
|---|---|---|---|
| `id` | `uuid` | Sí; `gen_random_uuid()` | Identificador interno opaco; PK. |
| `organization_id` | `uuid` | Sí | Frontera obligatoria de organización. → `organizations` |
| `created_at` | `timestamptz` | Sí; `now()` | Fecha de creación UTC. |
| `updated_at` | `timestamptz` | Sí; `now()` | Última modificación; trigger de servidor. |
| `course_id` | `uuid` | Sí | Curso → `courses` |
| `author_id` | `uuid` | Sí | Autor → `memberships` |
| `parent_post_id` | `uuid` | No | Respuesta → `forum_posts` |
| `title` | `text` | No | Título de hilo |
| `body` | `text` | Sí | Contenido |
| `status` | `text` | Sí; `'visible'` | visible, hidden, archived |

**Integridad:** PK `id`. UQ `(organization_id, id)`. UQ `(organization_id, course_id, id)`. CHECK: `status IN ('visible','hidden','archived')`.

**FK (todas `ON DELETE RESTRICT`):**

- `(organization_id)` → `organizations(id)`.
- `(organization_id, course_id)` → `courses(organization_id, id)`.
- `(organization_id, author_id)` → `memberships(organization_id, id)`.
- `(organization_id, parent_post_id)` → `forum_posts(organization_id, id)`.
- `(organization_id, course_id, parent_post_id)` → `forum_posts(organization_id, course_id, id)`.

**Contrato de autorización:** Participante del curso; editar propio, moderador oculta; no indexar sin aprobación.

---

### achievements

![Fase: Fase 2](https://img.shields.io/static/v1?label=Fase&message=Fase%202&color=0066FF&style=for-the-badge) ![Ámbito: org](https://img.shields.io/static/v1?label=%C3%81mbito&message=org&color=0A1A3A&style=for-the-badge)

Catálogo de insignias y reglas versionadas.

| Columna SQL | Tipo PostgreSQL | Obligatorio / default | Descripción |
|---|---|---|---|
| `id` | `uuid` | Sí; `gen_random_uuid()` | Identificador interno opaco; PK. |
| `organization_id` | `uuid` | Sí | Frontera obligatoria de organización. → `organizations` |
| `created_at` | `timestamptz` | Sí; `now()` | Fecha de creación UTC. |
| `updated_at` | `timestamptz` | Sí; `now()` | Última modificación; trigger de servidor. |
| `code` | `text` | Sí | Código de logro |
| `name` | `text` | Sí | Etiqueta |
| `description` | `text` | Sí | Criterio visible |
| `icon_key` | `text` | Sí | Icono Lucide permitido |
| `color` | `text` | Sí | Color corporativo |
| `criteria` | `jsonb` | Sí | Criterio verificable por servidor |
| `active` | `boolean` | Sí; `true` | Disponibilidad |

**Integridad:** PK `id`. UQ `(organization_id, id)`. UQ `(organization_id, code)`. 

**FK (todas `ON DELETE RESTRICT`):**

- `(organization_id)` → `organizations(id)`.

**Contrato de autorización:** Leer catálogo; administrar por Academy; reglas no ejecutan código arbitrario.

---

### member_achievements

![Fase: Fase 2](https://img.shields.io/static/v1?label=Fase&message=Fase%202&color=0066FF&style=for-the-badge) ![Ámbito: org](https://img.shields.io/static/v1?label=%C3%81mbito&message=org&color=0A1A3A&style=for-the-badge)

Logros otorgados a personas.

| Columna SQL | Tipo PostgreSQL | Obligatorio / default | Descripción |
|---|---|---|---|
| `id` | `uuid` | Sí; `gen_random_uuid()` | Identificador interno opaco; PK. |
| `organization_id` | `uuid` | Sí | Frontera obligatoria de organización. → `organizations` |
| `created_at` | `timestamptz` | Sí; `now()` | Fecha de creación UTC. |
| `updated_at` | `timestamptz` | Sí; `now()` | Última modificación; trigger de servidor. |
| `achievement_id` | `uuid` | Sí | Insignia → `achievements` |
| `membership_id` | `uuid` | Sí | Titular → `memberships` |
| `evidence` | `jsonb` | Sí | Evidencia verificable |
| `revoked_at` | `timestamptz` | No | Revocación |

**Integridad:** PK `id`. UQ `(organization_id, id)`. UQ `(achievement_id, membership_id)`. 

**FK (todas `ON DELETE RESTRICT`):**

- `(organization_id)` → `organizations(id)`.
- `(organization_id, achievement_id)` → `achievements(organization_id, id)`.
- `(organization_id, membership_id)` → `memberships(organization_id, id)`.

**Contrato de autorización:** Titular y audiencia autorizada; otorgar solo servicio de logros, no autoasignación.

---

### certificates

![Fase: Fase 2](https://img.shields.io/static/v1?label=Fase&message=Fase%202&color=0066FF&style=for-the-badge) ![Ámbito: org](https://img.shields.io/static/v1?label=%C3%81mbito&message=org&color=0A1A3A&style=for-the-badge)

Constancias internas con código verificable.

| Columna SQL | Tipo PostgreSQL | Obligatorio / default | Descripción |
|---|---|---|---|
| `id` | `uuid` | Sí; `gen_random_uuid()` | Identificador interno opaco; PK. |
| `organization_id` | `uuid` | Sí | Frontera obligatoria de organización. → `organizations` |
| `created_at` | `timestamptz` | Sí; `now()` | Fecha de creación UTC. |
| `updated_at` | `timestamptz` | Sí; `now()` | Última modificación; trigger de servidor. |
| `enrollment_id` | `uuid` | Sí | Matrícula completada → `enrollments` |
| `verification_code` | `uuid` | Sí; `gen_random_uuid()` | Código opaco |
| `file_id` | `uuid` | No | PDF emitido → `files` |
| `issued_at` | `timestamptz` | Sí; `now()` | Emisión |
| `revoked_at` | `timestamptz` | No | Revocación |

**Integridad:** PK `id`. UQ `(organization_id, id)`. UQ `(verification_code)`; `(enrollment_id)`. 

**FK (todas `ON DELETE RESTRICT`):**

- `(organization_id)` → `organizations(id)`.
- `(organization_id, enrollment_id)` → `enrollments(organization_id, id)`.
- `(organization_id, file_id)` → `files(organization_id, id)`.

**Contrato de autorización:** Titular y autoridad formativa; verificación pública opcional mínima; emisión solo servidor.

---

## 06. MIA, voz, analítica y Machine Learning

[`conversations`](#conversations) | [`messages`](#messages) | [`citations`](#citations) | [`tool_runs`](#tool_runs) | [`action_previews`](#action_previews) | [`speech_sessions`](#speech_sessions) | [`model_versions`](#model_versions) | [`predictions`](#predictions) | [`usage_records`](#usage_records)

### conversations

![Fase: MVP / Fase 3](https://img.shields.io/static/v1?label=Fase&message=MVP%20/%20Fase%203&color=0066FF&style=for-the-badge) ![Ámbito: org](https://img.shields.io/static/v1?label=%C3%81mbito&message=org&color=0A1A3A&style=for-the-badge)

Conversación privada de MIA.

| Columna SQL | Tipo PostgreSQL | Obligatorio / default | Descripción |
|---|---|---|---|
| `id` | `uuid` | Sí; `gen_random_uuid()` | Identificador interno opaco; PK. |
| `organization_id` | `uuid` | Sí | Frontera obligatoria de organización. → `organizations` |
| `created_at` | `timestamptz` | Sí; `now()` | Fecha de creación UTC. |
| `updated_at` | `timestamptz` | Sí; `now()` | Última modificación; trigger de servidor. |
| `owner_id` | `uuid` | Sí | Titular → `memberships` |
| `mode` | `text` | Sí; `'general'` | general, projects, academy, analytics, commercial, voice, briefing |
| `project_id` | `uuid` | No | Contexto de proyecto → `projects` |
| `title` | `text` | No | Título |
| `provider_thread_id` | `text` | No | Referencia Foundry no pública |
| `archived_at` | `timestamptz` | No | Archivo |

**Integridad:** PK `id`. UQ `(organization_id, id)`. CHECK: `mode IN ('general','projects','academy','analytics','commercial','voice','briefing')`.

**FK (todas `ON DELETE RESTRICT`):**

- `(organization_id)` → `organizations(id)`.
- `(organization_id, owner_id)` → `memberships(organization_id, id)`.
- `(organization_id, project_id)` → `projects(organization_id, id)`.

**Contrato de autorización:** Solo titular activo con acceso al contexto; superadmin no lee conversaciones por defecto.

---

### messages

![Fase: MVP / Fase 3](https://img.shields.io/static/v1?label=Fase&message=MVP%20/%20Fase%203&color=0066FF&style=for-the-badge) ![Ámbito: org](https://img.shields.io/static/v1?label=%C3%81mbito&message=org&color=0A1A3A&style=for-the-badge)

Mensajes de conversación y resultado de consulta.

| Columna SQL | Tipo PostgreSQL | Obligatorio / default | Descripción |
|---|---|---|---|
| `id` | `uuid` | Sí; `gen_random_uuid()` | Identificador interno opaco; PK. |
| `organization_id` | `uuid` | Sí | Frontera obligatoria de organización. → `organizations` |
| `created_at` | `timestamptz` | Sí; `now()` | Fecha de creación UTC. |
| `updated_at` | `timestamptz` | Sí; `now()` | Última modificación; trigger de servidor. |
| `conversation_id` | `uuid` | Sí | Conversación → `conversations` |
| `role` | `text` | Sí | user, assistant o tool |
| `body` | `text` | Sí | Texto minimizado |
| `status` | `text` | Sí; `'completed'` | streaming, completed, failed, cancelled |
| `sequence` | `integer` | Sí | Orden estable |
| `provider_message_id` | `text` | No | ID externo |

**Integridad:** PK `id`. UQ `(organization_id, id)`. UQ `(conversation_id, sequence)`. CHECK: `role IN ('user','assistant','tool')`; `sequence >= 0`; `status IN ('streaming','completed','failed','cancelled')`.

**FK (todas `ON DELETE RESTRICT`):**

- `(organization_id)` → `organizations(id)`.
- `(organization_id, conversation_id)` → `conversations(organization_id, id)`.

**Contrato de autorización:** Solo titular y servicio MIA; cliente no puede insertar rol assistant/tool ni modificar respuestas.

---

### citations

![Fase: MVP / Fase 3](https://img.shields.io/static/v1?label=Fase&message=MVP%20/%20Fase%203&color=0066FF&style=for-the-badge) ![Ámbito: org](https://img.shields.io/static/v1?label=%C3%81mbito&message=org&color=0A1A3A&style=for-the-badge)

Fuentes de respuesta y evidencia operativa.

| Columna SQL | Tipo PostgreSQL | Obligatorio / default | Descripción |
|---|---|---|---|
| `id` | `uuid` | Sí; `gen_random_uuid()` | Identificador interno opaco; PK. |
| `organization_id` | `uuid` | Sí | Frontera obligatoria de organización. → `organizations` |
| `created_at` | `timestamptz` | Sí; `now()` | Fecha de creación UTC. |
| `updated_at` | `timestamptz` | Sí; `now()` | Última modificación; trigger de servidor. |
| `message_id` | `uuid` | Sí | Mensaje → `messages` |
| `source_ref_id` | `uuid` | No | Fragmento documental → `source_refs` |
| `card_id` | `uuid` | No | Tarjeta de evidencia → `cards` |
| `source_kind` | `text` | Sí | document, card o aggregate |
| `snapshot` | `jsonb` | No | Metadatos mínimos de fecha/indicador |

**Integridad:** PK `id`. UQ `(organization_id, id)`. CHECK: `(source_kind = 'document' AND source_ref_id IS NOT NULL AND card_id IS NULL) OR (source_kind = 'card' AND card_id IS NOT NULL AND source_ref_id IS NULL) OR (source_kind = 'aggregate' AND source_ref_id IS NULL AND card_id IS NULL)`.

**FK (todas `ON DELETE RESTRICT`):**

- `(organization_id)` → `organizations(id)`.
- `(organization_id, message_id)` → `messages(organization_id, id)`.
- `(organization_id, source_ref_id)` → `source_refs(organization_id, id)`.
- `(organization_id, card_id)` → `cards(organization_id, id)`.

**Contrato de autorización:** Titular del mensaje y fuente todavía autorizada; ocultar detalle si revocada; servicio registra fuente real.

---

### tool_runs

![Fase: MVP / Fase 3](https://img.shields.io/static/v1?label=Fase&message=MVP%20/%20Fase%203&color=0066FF&style=for-the-badge) ![Ámbito: org](https://img.shields.io/static/v1?label=%C3%81mbito&message=org&color=0A1A3A&style=for-the-badge)

Trazabilidad de llamadas de herramientas de MIA.

| Columna SQL | Tipo PostgreSQL | Obligatorio / default | Descripción |
|---|---|---|---|
| `id` | `uuid` | Sí; `gen_random_uuid()` | Identificador interno opaco; PK. |
| `organization_id` | `uuid` | Sí | Frontera obligatoria de organización. → `organizations` |
| `created_at` | `timestamptz` | Sí; `now()` | Fecha de creación UTC. |
| `updated_at` | `timestamptz` | Sí; `now()` | Última modificación; trigger de servidor. |
| `conversation_id` | `uuid` | Sí | Conversación → `conversations` |
| `message_id` | `uuid` | No | Mensaje asociado → `messages` |
| `tool_code` | `text` | Sí | Herramienta de lista blanca |
| `status` | `text` | Sí | Resultado |
| `correlation_id` | `uuid` | Sí | Trazabilidad |
| `safe_summary` | `jsonb` | No | Resumen sin secretos |
| `finished_at` | `timestamptz` | No | Fin |

**Integridad:** PK `id`. UQ `(organization_id, id)`. 

**FK (todas `ON DELETE RESTRICT`):**

- `(organization_id)` → `organizations(id)`.
- `(organization_id, conversation_id)` → `conversations(organization_id, id)`.
- `(organization_id, message_id)` → `messages(organization_id, id)`.

**Contrato de autorización:** Titular ve resumen autorizado; diagnóstico agregado; argumentos sensibles no se guardan.

---

### action_previews

![Fase: MVP / Fase 3](https://img.shields.io/static/v1?label=Fase&message=MVP%20/%20Fase%203&color=0066FF&style=for-the-badge) ![Ámbito: org](https://img.shields.io/static/v1?label=%C3%81mbito&message=org&color=0A1A3A&style=for-the-badge)

Propuestas de acción sujetas a confirmación.

| Columna SQL | Tipo PostgreSQL | Obligatorio / default | Descripción |
|---|---|---|---|
| `id` | `uuid` | Sí; `gen_random_uuid()` | Identificador interno opaco; PK. |
| `organization_id` | `uuid` | Sí | Frontera obligatoria de organización. → `organizations` |
| `created_at` | `timestamptz` | Sí; `now()` | Fecha de creación UTC. |
| `updated_at` | `timestamptz` | Sí; `now()` | Última modificación; trigger de servidor. |
| `conversation_id` | `uuid` | Sí | Conversación → `conversations` |
| `requested_by` | `uuid` | Sí | Actor → `memberships` |
| `operation` | `text` | Sí | Acción permitida |
| `payload` | `jsonb` | Sí | DTO validado |
| `expires_at` | `timestamptz` | Sí | Caducidad |
| `status` | `text` | Sí; `'pending'` | pending, confirmed, executed, expired, cancelled |
| `idempotency_key` | `uuid` | Sí | Clave de ejecución |

**Integridad:** PK `id`. UQ `(organization_id, id)`. UQ `(organization_id, idempotency_key)`. CHECK: `status IN ('pending','confirmed','executed','expired','cancelled')`; `expires_at > created_at`.

**FK (todas `ON DELETE RESTRICT`):**

- `(organization_id)` → `organizations(id)`.
- `(organization_id, conversation_id)` → `conversations(organization_id, id)`.
- `(organization_id, requested_by)` → `memberships(organization_id, id)`.

**Contrato de autorización:** Titular; confirmar explícitamente y revalidar permisos/versión; ejecutar una vez.

---

### speech_sessions

![Fase: MVP / Fase 3](https://img.shields.io/static/v1?label=Fase&message=MVP%20/%20Fase%203&color=0066FF&style=for-the-badge) ![Ámbito: org](https://img.shields.io/static/v1?label=%C3%81mbito&message=org&color=0A1A3A&style=for-the-badge)

Control de sesión de voz/avatar, sin audio persistente por defecto.

| Columna SQL | Tipo PostgreSQL | Obligatorio / default | Descripción |
|---|---|---|---|
| `id` | `uuid` | Sí; `gen_random_uuid()` | Identificador interno opaco; PK. |
| `organization_id` | `uuid` | Sí | Frontera obligatoria de organización. → `organizations` |
| `created_at` | `timestamptz` | Sí; `now()` | Fecha de creación UTC. |
| `updated_at` | `timestamptz` | Sí; `now()` | Última modificación; trigger de servidor. |
| `membership_id` | `uuid` | Sí | Titular → `memberships` |
| `conversation_id` | `uuid` | No | Contexto → `conversations` |
| `mode` | `text` | Sí | local, speech, avatar |
| `started_at` | `timestamptz` | Sí | Inicio |
| `ended_at` | `timestamptz` | No | Fin |
| `consent_at` | `timestamptz` | No | Aceptación de micrófono |
| `status` | `text` | Sí; `'active'` | active, ended, failed |

**Integridad:** PK `id`. UQ `(organization_id, id)`. CHECK: `ended_at >= started_at`; `status IN ('active','ended','failed')`; `mode IN ('local','speech','avatar')`.

**FK (todas `ON DELETE RESTRICT`):**

- `(organization_id)` → `organizations(id)`.
- `(organization_id, membership_id)` → `memberships(organization_id, id)`.
- `(organization_id, conversation_id)` → `conversations(organization_id, id)`.

**Contrato de autorización:** Titular y servicio Speech; administración solo métricas agregadas.

---

### model_versions

![Fase: MVP / Fase 3](https://img.shields.io/static/v1?label=Fase&message=MVP%20/%20Fase%203&color=0066FF&style=for-the-badge) ![Ámbito: org](https://img.shields.io/static/v1?label=%C3%81mbito&message=org&color=0A1A3A&style=for-the-badge)

Versiones de clasificación y regresión.

| Columna SQL | Tipo PostgreSQL | Obligatorio / default | Descripción |
|---|---|---|---|
| `id` | `uuid` | Sí; `gen_random_uuid()` | Identificador interno opaco; PK. |
| `organization_id` | `uuid` | Sí | Frontera obligatoria de organización. → `organizations` |
| `created_at` | `timestamptz` | Sí; `now()` | Fecha de creación UTC. |
| `updated_at` | `timestamptz` | Sí; `now()` | Última modificación; trigger de servidor. |
| `model_kind` | `text` | Sí | classification o regression |
| `version_tag` | `text` | Sí | Versión registrada |
| `provider_ref` | `text` | No | ID del modelo/endpoint, sin claves |
| `target_column` | `text` | Sí | Retraso o Horas_reales |
| `feature_schema` | `jsonb` | Sí | Contrato de entrada |
| `metrics` | `jsonb` | No | Métricas verificadas |
| `status` | `text` | Sí; `'registered'` | registered, validated, deployed, disabled |

**Integridad:** PK `id`. UQ `(organization_id, id)`. UQ `(organization_id, model_kind, version_tag)`. CHECK: `model_kind IN ('classification','regression')`; `status IN ('registered','validated','deployed','disabled')`; `(model_kind = 'classification' AND target_column = 'Retraso') OR (model_kind = 'regression' AND target_column = 'Horas_reales')`.

**FK (todas `ON DELETE RESTRICT`):**

- `(organization_id)` → `organizations(id)`.

**Contrato de autorización:** Leer usuarios con analytics/predict; editar integrador autorizado, métricas reales solamente.

---

### predictions

![Fase: MVP / Fase 3](https://img.shields.io/static/v1?label=Fase&message=MVP%20/%20Fase%203&color=0066FF&style=for-the-badge) ![Ámbito: org](https://img.shields.io/static/v1?label=%C3%81mbito&message=org&color=0A1A3A&style=for-the-badge)

Resultados históricos de inferencia, no horas reales.

| Columna SQL | Tipo PostgreSQL | Obligatorio / default | Descripción |
|---|---|---|---|
| `id` | `uuid` | Sí; `gen_random_uuid()` | Identificador interno opaco; PK. |
| `organization_id` | `uuid` | Sí | Frontera obligatoria de organización. → `organizations` |
| `created_at` | `timestamptz` | Sí; `now()` | Fecha de creación UTC. |
| `updated_at` | `timestamptz` | Sí; `now()` | Última modificación; trigger de servidor. |
| `model_version_id` | `uuid` | Sí | Modelo utilizado → `model_versions` |
| `requested_by` | `uuid` | Sí | Actor → `memberships` |
| `project_id` | `uuid` | No | Proyecto de escenario → `projects` |
| `card_id` | `uuid` | No | Tarjeta opcional → `cards` |
| `input_snapshot` | `jsonb` | Sí | Variables realmente enviadas |
| `status` | `text` | Sí; `'pending'` | pending, succeeded, failed |
| `predicted_delay` | `boolean` | No | Clase predicha |
| `probability` | `numeric(8,7)` | No | Probabilidad si la devuelve el modelo |
| `predicted_hours` | `numeric(12,4)` | No | Horas de regresión |
| `error_code` | `text` | No | Error no sensible |
| `finished_at` | `timestamptz` | No | Fin |

**Integridad:** PK `id`. UQ `(organization_id, id)`. CHECK: `probability BETWEEN 0 AND 1`; `predicted_hours >= 0`; `card_id IS NULL OR project_id IS NOT NULL`; `status IN ('pending','succeeded','failed')`; `status <> 'succeeded' OR (num_nonnulls(predicted_delay,predicted_hours) = 1 AND finished_at IS NOT NULL)`; `status = 'succeeded' OR (predicted_delay IS NULL AND probability IS NULL AND predicted_hours IS NULL)`; `probability IS NULL OR predicted_delay IS NOT NULL`.

**FK (todas `ON DELETE RESTRICT`):**

- `(organization_id)` → `organizations(id)`.
- `(organization_id, model_version_id)` → `model_versions(organization_id, id)`.
- `(organization_id, requested_by)` → `memberships(organization_id, id)`.
- `(organization_id, project_id)` → `projects(organization_id, id)`.
- `(organization_id, card_id)` → `cards(organization_id, id)`.
- `(organization_id, project_id, card_id)` → `cards(organization_id, project_id, id)`.

**Contrato de autorización:** Solicitante y supervisor con permiso sobre escenario; resultados solo adaptador ML; no inventar predicciones.

---

### usage_records

![Fase: MVP / Fase 3](https://img.shields.io/static/v1?label=Fase&message=MVP%20/%20Fase%203&color=0066FF&style=for-the-badge) ![Ámbito: org](https://img.shields.io/static/v1?label=%C3%81mbito&message=org&color=0A1A3A&style=for-the-badge)

Consumo medido de IA y servicios.

| Columna SQL | Tipo PostgreSQL | Obligatorio / default | Descripción |
|---|---|---|---|
| `id` | `uuid` | Sí; `gen_random_uuid()` | Identificador interno opaco; PK. |
| `organization_id` | `uuid` | Sí | Frontera obligatoria de organización. → `organizations` |
| `created_at` | `timestamptz` | Sí; `now()` | Fecha de creación UTC. |
| `membership_id` | `uuid` | No | Actor cuando aplica → `memberships` |
| `service_code` | `text` | Sí | foundry, speech, avatar, ml, search |
| `quantity` | `numeric(18,6)` | Sí | Cantidad registrada |
| `unit` | `text` | Sí | tokens, seconds, requests u otra unidad |
| `estimated_cost_usd` | `numeric(14,6)` | No | Estimación, no factura |
| `provider_request_id` | `text` | No | Referencia externa |
| `occurred_at` | `timestamptz` | Sí | Fecha de consumo |

**Integridad:** PK `id`. UQ `(organization_id, id)`. CHECK: `quantity >= 0`; `estimated_cost_usd >= 0`.

**FK (todas `ON DELETE RESTRICT`):**

- `(organization_id)` → `organizations(id)`.
- `(organization_id, membership_id)` → `memberships(organization_id, id)`.

**Contrato de autorización:** Titular ve consumo propio; integrador ve agregados; servicio registra medición; nunca contenido de chats.

---

## 07. Servicios, planes y cotizaciones

[`services`](#services) | [`plans`](#plans) | [`plan_versions`](#plan_versions) | [`leads`](#leads) | [`quotes`](#quotes) | [`quote_items`](#quote_items)

### services

![Fase: Fase 4](https://img.shields.io/static/v1?label=Fase&message=Fase%204&color=0066FF&style=for-the-badge) ![Ámbito: org](https://img.shields.io/static/v1?label=%C3%81mbito&message=org&color=0A1A3A&style=for-the-badge)

Catálogo de servicios empresariales.

| Columna SQL | Tipo PostgreSQL | Obligatorio / default | Descripción |
|---|---|---|---|
| `id` | `uuid` | Sí; `gen_random_uuid()` | Identificador interno opaco; PK. |
| `organization_id` | `uuid` | Sí | Frontera obligatoria de organización. → `organizations` |
| `created_at` | `timestamptz` | Sí; `now()` | Fecha de creación UTC. |
| `updated_at` | `timestamptz` | Sí; `now()` | Última modificación; trigger de servidor. |
| `slug` | `text` | Sí | URL pública si se publica |
| `name` | `text` | Sí | Nombre |
| `description` | `text` | Sí | Alcance |
| `category` | `text` | Sí | Categoría comercial |
| `status` | `text` | Sí; `'draft'` | draft, published, archived |
| `published_at` | `timestamptz` | No | Publicación |

**Integridad:** PK `id`. UQ `(organization_id, id)`. UQ `(organization_id, slug)`. CHECK: `status IN ('draft','published','archived')`.

**FK (todas `ON DELETE RESTRICT`):**

- `(organization_id)` → `organizations(id)`.

**Contrato de autorización:** Leer publicado; comercial autorizado gestiona borradores y publicación separada.

---

### plans

![Fase: Fase 4](https://img.shields.io/static/v1?label=Fase&message=Fase%204&color=0066FF&style=for-the-badge) ![Ámbito: org](https://img.shields.io/static/v1?label=%C3%81mbito&message=org&color=0A1A3A&style=for-the-badge)

Plan comercial asociado a servicio.

| Columna SQL | Tipo PostgreSQL | Obligatorio / default | Descripción |
|---|---|---|---|
| `id` | `uuid` | Sí; `gen_random_uuid()` | Identificador interno opaco; PK. |
| `organization_id` | `uuid` | Sí | Frontera obligatoria de organización. → `organizations` |
| `created_at` | `timestamptz` | Sí; `now()` | Fecha de creación UTC. |
| `updated_at` | `timestamptz` | Sí; `now()` | Última modificación; trigger de servidor. |
| `service_id` | `uuid` | Sí | Servicio → `services` |
| `code` | `text` | Sí | Código de plan |
| `name` | `text` | Sí | Nombre |
| `status` | `text` | Sí; `'draft'` | draft, published, archived |

**Integridad:** PK `id`. UQ `(organization_id, id)`. UQ `(organization_id, code)`. CHECK: `status IN ('draft','published','archived')`.

**FK (todas `ON DELETE RESTRICT`):**

- `(organization_id)` → `organizations(id)`.
- `(organization_id, service_id)` → `services(organization_id, id)`.

**Contrato de autorización:** Leer plan publicado; editor comercial administra.

---

### plan_versions

![Fase: Fase 4](https://img.shields.io/static/v1?label=Fase&message=Fase%204&color=0066FF&style=for-the-badge) ![Ámbito: org](https://img.shields.io/static/v1?label=%C3%81mbito&message=org&color=0A1A3A&style=for-the-badge)

Precios y condiciones versionados.

| Columna SQL | Tipo PostgreSQL | Obligatorio / default | Descripción |
|---|---|---|---|
| `id` | `uuid` | Sí; `gen_random_uuid()` | Identificador interno opaco; PK. |
| `organization_id` | `uuid` | Sí | Frontera obligatoria de organización. → `organizations` |
| `created_at` | `timestamptz` | Sí; `now()` | Fecha de creación UTC. |
| `updated_at` | `timestamptz` | Sí; `now()` | Última modificación; trigger de servidor. |
| `plan_id` | `uuid` | Sí | Plan → `plans` |
| `revision` | `integer` | Sí | Versión |
| `amount` | `numeric(14,2)` | No | Precio aprobado; NULL significa consultar |
| `currency` | `char(3)` | Sí; `'PEN'` | Moneda |
| `billing_cycle` | `text` | Sí | once, monthly, yearly, custom |
| `features` | `jsonb` | Sí; `'[]'::jsonb` | Prestaciones aprobadas |
| `terms` | `text` | No | Condiciones |
| `valid_from` | `timestamptz` | No | Inicio de vigencia |
| `valid_until` | `timestamptz` | No | Fin de vigencia |
| `status` | `text` | Sí; `'draft'` | draft, published, retired |
| `created_by` | `uuid` | Sí | Editor → `memberships` |
| `approved_by` | `uuid` | No | Aprobador → `memberships` |

**Integridad:** PK `id`. UQ `(organization_id, id)`. UQ `(plan_id, revision)`. CHECK: `revision > 0`; `amount >= 0`; `valid_until > valid_from`; `approved_by <> created_by`; `status IN ('draft','published','retired')`; `status <> 'published' OR (approved_by IS NOT NULL AND valid_from IS NOT NULL)`; `billing_cycle IN ('once','monthly','yearly','custom')`.

**FK (todas `ON DELETE RESTRICT`):**

- `(organization_id)` → `organizations(id)`.
- `(organization_id, plan_id)` → `plans(organization_id, id)`.
- `(organization_id, created_by)` → `memberships(organization_id, id)`.
- `(organization_id, approved_by)` → `memberships(organization_id, id)`.

**Contrato de autorización:** Leer versión publicada vigente; editor y aprobador distintos; evitar solapamiento de vigencias.

---

### leads

![Fase: Fase 4](https://img.shields.io/static/v1?label=Fase&message=Fase%204&color=0066FF&style=for-the-badge) ![Ámbito: org](https://img.shields.io/static/v1?label=%C3%81mbito&message=org&color=0A1A3A&style=for-the-badge)

Contactos comerciales privados.

| Columna SQL | Tipo PostgreSQL | Obligatorio / default | Descripción |
|---|---|---|---|
| `id` | `uuid` | Sí; `gen_random_uuid()` | Identificador interno opaco; PK. |
| `organization_id` | `uuid` | Sí | Frontera obligatoria de organización. → `organizations` |
| `created_at` | `timestamptz` | Sí; `now()` | Fecha de creación UTC. |
| `updated_at` | `timestamptz` | Sí; `now()` | Última modificación; trigger de servidor. |
| `name` | `text` | Sí | Nombre de contacto |
| `email` | `text` | Sí | Correo de contacto |
| `company` | `text` | No | Organización interesada |
| `message` | `text` | No | Solicitud |
| `consent_at` | `timestamptz` | No | Consentimiento aplicable |
| `status` | `text` | Sí; `'new'` | new, contacted, closed |

**Integridad:** PK `id`. UQ `(organization_id, id)`. CHECK: `status IN ('new','contacted','closed')`.

**FK (todas `ON DELETE RESTRICT`):**

- `(organization_id)` → `organizations(id)`.

**Contrato de autorización:** Solo comercial autorizado; formulario público por endpoint limitado, sin listado anónimo.

---

### quotes

![Fase: Fase 4](https://img.shields.io/static/v1?label=Fase&message=Fase%204&color=0066FF&style=for-the-badge) ![Ámbito: org](https://img.shields.io/static/v1?label=%C3%81mbito&message=org&color=0A1A3A&style=for-the-badge)

Cotización privada con snapshot de condiciones.

| Columna SQL | Tipo PostgreSQL | Obligatorio / default | Descripción |
|---|---|---|---|
| `id` | `uuid` | Sí; `gen_random_uuid()` | Identificador interno opaco; PK. |
| `organization_id` | `uuid` | Sí | Frontera obligatoria de organización. → `organizations` |
| `created_at` | `timestamptz` | Sí; `now()` | Fecha de creación UTC. |
| `updated_at` | `timestamptz` | Sí; `now()` | Última modificación; trigger de servidor. |
| `lead_id` | `uuid` | Sí | Contacto → `leads` |
| `code` | `text` | Sí | Código de cotización |
| `created_by` | `uuid` | Sí | Comercial → `memberships` |
| `status` | `text` | Sí; `'draft'` | draft, sent, accepted, rejected, expired |
| `currency` | `char(3)` | Sí; `'PEN'` | Moneda única |
| `valid_until` | `date` | No | Validez |
| `subtotal` | `numeric(14,2)` | Sí; `0` | Subtotal calculado |
| `tax` | `numeric(14,2)` | Sí; `0` | Impuesto calculado |
| `total` | `numeric(14,2)` | Sí; `0` | Total calculado |
| `version` | `integer` | Sí; `1` | Control de concurrencia |

**Integridad:** PK `id`. UQ `(organization_id, id)`. UQ `(organization_id, code)`. CHECK: `subtotal >= 0`; `tax >= 0`; `total = subtotal + tax`; `version > 0`; `status IN ('draft','sent','accepted','rejected','expired')`.

**FK (todas `ON DELETE RESTRICT`):**

- `(organization_id)` → `organizations(id)`.
- `(organization_id, lead_id)` → `leads(organization_id, id)`.
- `(organization_id, created_by)` → `memberships(organization_id, id)`.

**Contrato de autorización:** Comercial delegado; no publicar al público ni enviar por MIA sin permiso/confirmación.

---

### quote_items

![Fase: Fase 4](https://img.shields.io/static/v1?label=Fase&message=Fase%204&color=0066FF&style=for-the-badge) ![Ámbito: org](https://img.shields.io/static/v1?label=%C3%81mbito&message=org&color=0A1A3A&style=for-the-badge)

Líneas de cotización con precio histórico.

| Columna SQL | Tipo PostgreSQL | Obligatorio / default | Descripción |
|---|---|---|---|
| `id` | `uuid` | Sí; `gen_random_uuid()` | Identificador interno opaco; PK. |
| `organization_id` | `uuid` | Sí | Frontera obligatoria de organización. → `organizations` |
| `created_at` | `timestamptz` | Sí; `now()` | Fecha de creación UTC. |
| `updated_at` | `timestamptz` | Sí; `now()` | Última modificación; trigger de servidor. |
| `quote_id` | `uuid` | Sí | Cotización → `quotes` |
| `plan_version_id` | `uuid` | No | Versión origen → `plan_versions` |
| `name_snapshot` | `text` | Sí | Nombre congelado |
| `quantity` | `numeric(12,3)` | Sí | Cantidad |
| `unit_price` | `numeric(14,2)` | Sí | Precio aprobado congelado |
| `line_total` | `numeric(14,2)` | Sí | Total redondeado |

**Integridad:** PK `id`. UQ `(organization_id, id)`. CHECK: `quantity > 0`; `unit_price >= 0`; `line_total = round(quantity * unit_price,2)`.

**FK (todas `ON DELETE RESTRICT`):**

- `(organization_id)` → `organizations(id)`.
- `(organization_id, quote_id)` → `quotes(organization_id, id)`.
- `(organization_id, plan_version_id)` → `plan_versions(organization_id, id)`.

**Contrato de autorización:** Hereda cotización; cambios solo borrador y recalcular totales en transacción.

---

## 08. Operación, notificaciones y auditoría

[`notifications`](#notifications) | [`notification_preferences`](#notification_preferences) | [`audit_events`](#audit_events) | [`outbox`](#outbox) | [`jobs`](#jobs) | [`import_batches`](#import_batches) | [`import_rows`](#import_rows) | [`historical_task_facts`](#historical_task_facts) | [`export_jobs`](#export_jobs) | [`integration_settings`](#integration_settings) | [`quota_limits`](#quota_limits) | [`idempotency_keys`](#idempotency_keys)

### notifications

![Fase: MVP / Fase 2 / Fase 4](https://img.shields.io/static/v1?label=Fase&message=MVP%20/%20Fase%202%20/%20Fase%204&color=0066FF&style=for-the-badge) ![Ámbito: org](https://img.shields.io/static/v1?label=%C3%81mbito&message=org&color=0A1A3A&style=for-the-badge)

Bandeja personal de alertas.

| Columna SQL | Tipo PostgreSQL | Obligatorio / default | Descripción |
|---|---|---|---|
| `id` | `uuid` | Sí; `gen_random_uuid()` | Identificador interno opaco; PK. |
| `organization_id` | `uuid` | Sí | Frontera obligatoria de organización. → `organizations` |
| `created_at` | `timestamptz` | Sí; `now()` | Fecha de creación UTC. |
| `updated_at` | `timestamptz` | Sí; `now()` | Última modificación; trigger de servidor. |
| `recipient_id` | `uuid` | Sí | Destinatario → `memberships` |
| `kind` | `text` | Sí | Categoría de notificación |
| `title` | `text` | Sí | Título |
| `body` | `text` | No | Resumen mínimo |
| `target_path` | `text` | No | Ruta interna validada |
| `read_at` | `timestamptz` | No | Leída |
| `archived_at` | `timestamptz` | No | Archivada |
| `dedupe_key` | `text` | Sí | Clave idempotente |

**Integridad:** PK `id`. UQ `(organization_id, id)`. UQ `(recipient_id, dedupe_key)`. 

**FK (todas `ON DELETE RESTRICT`):**

- `(organization_id)` → `organizations(id)`.
- `(organization_id, recipient_id)` → `memberships(organization_id, id)`.

**Índices de consulta:** `(recipient_id, read_at, created_at)`. Además índices de soporte FK cuando no estén cubiertos.

**Contrato de autorización:** Solo destinatario lee y marca/archiva; creación por servicio de notificaciones.

---

### notification_preferences

![Fase: MVP / Fase 2 / Fase 4](https://img.shields.io/static/v1?label=Fase&message=MVP%20/%20Fase%202%20/%20Fase%204&color=0066FF&style=for-the-badge) ![Ámbito: org](https://img.shields.io/static/v1?label=%C3%81mbito&message=org&color=0A1A3A&style=for-the-badge)

Configuración de canales por tipo de alerta.

| Columna SQL | Tipo PostgreSQL | Obligatorio / default | Descripción |
|---|---|---|---|
| `id` | `uuid` | Sí; `gen_random_uuid()` | Identificador interno opaco; PK. |
| `organization_id` | `uuid` | Sí | Frontera obligatoria de organización. → `organizations` |
| `created_at` | `timestamptz` | Sí; `now()` | Fecha de creación UTC. |
| `updated_at` | `timestamptz` | Sí; `now()` | Última modificación; trigger de servidor. |
| `membership_id` | `uuid` | Sí | Titular → `memberships` |
| `kind` | `text` | Sí | Categoría |
| `in_app` | `boolean` | Sí; `true` | Canal interno |
| `email` | `boolean` | Sí; `false` | Correo optativo |
| `digest` | `text` | Sí; `'immediate'` | immediate, daily, weekly, off |

**Integridad:** PK `id`. UQ `(organization_id, id)`. UQ `(membership_id, kind)`. CHECK: `digest IN ('immediate','daily','weekly','off')`.

**FK (todas `ON DELETE RESTRICT`):**

- `(organization_id)` → `organizations(id)`.
- `(organization_id, membership_id)` → `memberships(organization_id, id)`.

**Contrato de autorización:** Solo titular; alertas críticas de seguridad siguen política independiente.

---

### audit_events

![Fase: MVP / Fase 2 / Fase 4](https://img.shields.io/static/v1?label=Fase&message=MVP%20/%20Fase%202%20/%20Fase%204&color=0066FF&style=for-the-badge) ![Ámbito: org](https://img.shields.io/static/v1?label=%C3%81mbito&message=org&color=0A1A3A&style=for-the-badge)

Auditoría append-only de operaciones sensibles.

| Columna SQL | Tipo PostgreSQL | Obligatorio / default | Descripción |
|---|---|---|---|
| `id` | `uuid` | Sí; `gen_random_uuid()` | Identificador interno opaco; PK. |
| `organization_id` | `uuid` | Sí | Frontera obligatoria de organización. → `organizations` |
| `created_at` | `timestamptz` | Sí; `now()` | Fecha de creación UTC. |
| `actor_id` | `uuid` | No | Actor o servicio → `memberships` |
| `project_id` | `uuid` | No | Proyecto si aplica → `projects` |
| `action` | `text` | Sí | Código de acción |
| `resource_type` | `text` | Sí | Tipo auditado |
| `resource_id` | `uuid` | No | ID histórico, sin FK polimórfica |
| `changes` | `jsonb` | Sí; `'{}'::jsonb` | Diff redactado |
| `correlation_id` | `uuid` | Sí | Trazabilidad |
| `outcome` | `text` | Sí | success o denied |

**Integridad:** PK `id`. UQ `(organization_id, id)`. CHECK: `outcome IN ('success','denied')`.

**FK (todas `ON DELETE RESTRICT`):**

- `(organization_id)` → `organizations(id)`.
- `(organization_id, actor_id)` → `memberships(organization_id, id)`.
- `(organization_id, project_id)` → `projects(organization_id, id)`.

**Contrato de autorización:** Auditor delegado según alcance; superadmin solo eventos técnicos autorizados; append por servicio; sin UPDATE/DELETE.

---

### outbox

![Fase: MVP / Fase 2 / Fase 4](https://img.shields.io/static/v1?label=Fase&message=MVP%20/%20Fase%202%20/%20Fase%204&color=0066FF&style=for-the-badge) ![Ámbito: org](https://img.shields.io/static/v1?label=%C3%81mbito&message=org&color=0A1A3A&style=for-the-badge)

Eventos transaccionales para publicación posterior.

| Columna SQL | Tipo PostgreSQL | Obligatorio / default | Descripción |
|---|---|---|---|
| `id` | `uuid` | Sí; `gen_random_uuid()` | Identificador interno opaco; PK. |
| `organization_id` | `uuid` | Sí | Frontera obligatoria de organización. → `organizations` |
| `created_at` | `timestamptz` | Sí; `now()` | Fecha de creación UTC. |
| `updated_at` | `timestamptz` | Sí; `now()` | Última modificación; trigger de servidor. |
| `event_type` | `text` | Sí | Tipo registrado |
| `aggregate_id` | `uuid` | Sí | Identificador del agregado |
| `payload` | `jsonb` | Sí | DTO de evento mínimo |
| `status` | `text` | Sí; `'pending'` | pending, processing, published, failed |
| `attempts` | `integer` | Sí; `0` | Intentos |
| `available_at` | `timestamptz` | Sí; `now()` | Disponible para procesar |
| `published_at` | `timestamptz` | No | Publicación |

**Integridad:** PK `id`. UQ `(organization_id, id)`. CHECK: `attempts >= 0`; `status IN ('pending','processing','published','failed')`.

**FK (todas `ON DELETE RESTRICT`):**

- `(organization_id)` → `organizations(id)`.

**Índices de consulta:** `(status, available_at)`. Además índices de soporte FK cuando no estén cubiertos.

**Contrato de autorización:** No acceso usuario; API inserta vía caso de uso; worker consume por permiso técnico acotado.

---

### jobs

![Fase: MVP / Fase 2 / Fase 4](https://img.shields.io/static/v1?label=Fase&message=MVP%20/%20Fase%202%20/%20Fase%204&color=0066FF&style=for-the-badge) ![Ámbito: org](https://img.shields.io/static/v1?label=%C3%81mbito&message=org&color=0A1A3A&style=for-the-badge)

Cola durable para tareas asíncronas sin Redis obligatorio.

| Columna SQL | Tipo PostgreSQL | Obligatorio / default | Descripción |
|---|---|---|---|
| `id` | `uuid` | Sí; `gen_random_uuid()` | Identificador interno opaco; PK. |
| `organization_id` | `uuid` | Sí | Frontera obligatoria de organización. → `organizations` |
| `created_at` | `timestamptz` | Sí; `now()` | Fecha de creación UTC. |
| `updated_at` | `timestamptz` | Sí; `now()` | Última modificación; trigger de servidor. |
| `job_type` | `text` | Sí | Trabajo tipado |
| `payload` | `jsonb` | Sí | Datos mínimos |
| `status` | `text` | Sí; `'queued'` | queued, running, succeeded, failed, cancelled |
| `attempts` | `integer` | Sí; `0` | Intentos |
| `run_after` | `timestamptz` | Sí; `now()` | Planificación |
| `lease_until` | `timestamptz` | No | Expiración del bloqueo |
| `last_error_code` | `text` | No | Error redactado |
| `idempotency_key` | `text` | Sí | Identificador único |

**Integridad:** PK `id`. UQ `(organization_id, id)`. UQ `(organization_id, job_type, idempotency_key)`. CHECK: `attempts >= 0`; `status IN ('queued','running','succeeded','failed','cancelled')`.

**FK (todas `ON DELETE RESTRICT`):**

- `(organization_id)` → `organizations(id)`.

**Índices de consulta:** `(status, run_after)`. Además índices de soporte FK cuando no estén cubiertos.

**Contrato de autorización:** No acceso general; worker restringido por tipo y organización; UI ve estado a través de recurso dueño.

---

### import_batches

![Fase: MVP / Fase 2 / Fase 4](https://img.shields.io/static/v1?label=Fase&message=MVP%20/%20Fase%202%20/%20Fase%204&color=0066FF&style=for-the-badge) ![Ámbito: org](https://img.shields.io/static/v1?label=%C3%81mbito&message=org&color=0A1A3A&style=for-the-badge)

Lotes de importación con procedencia.

| Columna SQL | Tipo PostgreSQL | Obligatorio / default | Descripción |
|---|---|---|---|
| `id` | `uuid` | Sí; `gen_random_uuid()` | Identificador interno opaco; PK. |
| `organization_id` | `uuid` | Sí | Frontera obligatoria de organización. → `organizations` |
| `created_at` | `timestamptz` | Sí; `now()` | Fecha de creación UTC. |
| `updated_at` | `timestamptz` | Sí; `now()` | Última modificación; trigger de servidor. |
| `file_id` | `uuid` | Sí | CSV fuente → `files` |
| `requested_by` | `uuid` | Sí | Actor → `memberships` |
| `source_name` | `text` | Sí | Nombre del origen |
| `source_hash` | `text` | Sí | Hash de archivo |
| `status` | `text` | Sí; `'pending'` | pending, validated, importing, completed, failed, reverted |
| `row_count` | `integer` | Sí; `0` | Filas detectadas |
| `accepted_count` | `integer` | Sí; `0` | Filas aceptadas |
| `rejected_count` | `integer` | Sí; `0` | Filas rechazadas |

**Integridad:** PK `id`. UQ `(organization_id, id)`. UQ `(organization_id, source_name, source_hash)`. CHECK: `row_count >= 0`; `accepted_count >= 0`; `rejected_count >= 0`; `accepted_count + rejected_count <= row_count`; `status IN ('pending','validated','importing','completed','failed','reverted')`.

**FK (todas `ON DELETE RESTRICT`):**

- `(organization_id)` → `organizations(id)`.
- `(organization_id, file_id)` → `files(organization_id, id)`.
- `(organization_id, requested_by)` → `memberships(organization_id, id)`.

**Contrato de autorización:** Importador delegado; CSV histórico exclusivamente en organización demo; validar antes de confirmar.

---

### import_rows

![Fase: MVP / Fase 2 / Fase 4](https://img.shields.io/static/v1?label=Fase&message=MVP%20/%20Fase%202%20/%20Fase%204&color=0066FF&style=for-the-badge) ![Ámbito: org](https://img.shields.io/static/v1?label=%C3%81mbito&message=org&color=0A1A3A&style=for-the-badge)

Trazabilidad de fila y errores de importación.

| Columna SQL | Tipo PostgreSQL | Obligatorio / default | Descripción |
|---|---|---|---|
| `id` | `uuid` | Sí; `gen_random_uuid()` | Identificador interno opaco; PK. |
| `organization_id` | `uuid` | Sí | Frontera obligatoria de organización. → `organizations` |
| `created_at` | `timestamptz` | Sí; `now()` | Fecha de creación UTC. |
| `updated_at` | `timestamptz` | Sí; `now()` | Última modificación; trigger de servidor. |
| `batch_id` | `uuid` | Sí | Lote → `import_batches` |
| `row_number` | `integer` | Sí | Número de fila |
| `external_task_id` | `text` | Sí | ID original |
| `source_data` | `jsonb` | Sí | Fila original protegida |
| `card_id` | `uuid` | No | Tarjeta creada → `cards` |
| `status` | `text` | Sí; `'pending'` | pending, accepted, rejected |
| `error_code` | `text` | No | Motivo de rechazo |

**Integridad:** PK `id`. UQ `(organization_id, id)`. UQ `(batch_id, row_number)`; `(batch_id, external_task_id)`. CHECK: `row_number > 0`; `status IN ('pending','accepted','rejected')`.

**FK (todas `ON DELETE RESTRICT`):**

- `(organization_id)` → `organizations(id)`.
- `(organization_id, batch_id)` → `import_batches(organization_id, id)`.
- `(organization_id, card_id)` → `cards(organization_id, id)`.

**Contrato de autorización:** Importador del lote; filas no se exponen a MIA operativa; preservar fuente y nulos.

---

### historical_task_facts

![Fase: MVP / Fase 2 / Fase 4](https://img.shields.io/static/v1?label=Fase&message=MVP%20/%20Fase%202%20/%20Fase%204&color=0066FF&style=for-the-badge) ![Ámbito: org](https://img.shields.io/static/v1?label=%C3%81mbito&message=org&color=0A1A3A&style=for-the-badge)

Registros históricos simulados sin cuentas Auth ni horas artificiales por usuario.

| Columna SQL | Tipo PostgreSQL | Obligatorio / default | Descripción |
|---|---|---|---|
| `id` | `uuid` | Sí; `gen_random_uuid()` | Identificador interno opaco; PK. |
| `organization_id` | `uuid` | Sí | Frontera obligatoria de organización. → `organizations` |
| `created_at` | `timestamptz` | Sí; `now()` | Fecha de creación UTC. |
| `updated_at` | `timestamptz` | Sí; `now()` | Última modificación; trigger de servidor. |
| `batch_id` | `uuid` | Sí | Lote de origen → `import_batches` |
| `external_task_id` | `text` | Sí | ID_tarea original |
| `external_project_id` | `text` | Sí | ID_proyecto original |
| `project_name` | `text` | Sí | Proyecto original |
| `participant_name` | `text` | Sí | Nombre simulado de participante |
| `specialty` | `text` | Sí | FN o BK original u otro código de fuente |
| `task_type` | `text` | Sí | Tipo_tarea |
| `complexity` | `text` | Sí | Complejidad original |
| `priority` | `text` | Sí | Prioridad original |
| `dependency_count` | `integer` | Sí | Dependencias reportadas |
| `estimated_minutes` | `integer` | Sí | Horas estimadas convertidas |
| `actual_minutes` | `integer` | No | Horas reales si existen |
| `start_date` | `date` | No | Inicio de fuente |
| `due_date` | `date` | No | Límite de fuente |
| `end_date` | `date` | No | Fin de fuente |
| `source_status` | `text` | Sí | Estado original |
| `source_delay` | `boolean` | No | Retraso original, NULL si desconocido |

**Integridad:** PK `id`. UQ `(organization_id, id)`. UQ `(batch_id, external_task_id)`. CHECK: `estimated_minutes >= 0`; `actual_minutes >= 0`; `dependency_count >= 0`.

**FK (todas `ON DELETE RESTRICT`):**

- `(organization_id)` → `organizations(id)`.
- `(organization_id, batch_id)` → `import_batches(organization_id, id)`.

**Índices de consulta:** `(organization_id, external_project_id)`; `(organization_id, source_status)`. Además índices de soporte FK cuando no estén cubiertos.

**Contrato de autorización:** Solo organización demo y permiso analytics.demo; datos históricos separados de tablero operativo.

---

### export_jobs

![Fase: MVP / Fase 2 / Fase 4](https://img.shields.io/static/v1?label=Fase&message=MVP%20/%20Fase%202%20/%20Fase%204&color=0066FF&style=for-the-badge) ![Ámbito: org](https://img.shields.io/static/v1?label=%C3%81mbito&message=org&color=0A1A3A&style=for-the-badge)

Solicitudes de CSV, Excel y PDF.

| Columna SQL | Tipo PostgreSQL | Obligatorio / default | Descripción |
|---|---|---|---|
| `id` | `uuid` | Sí; `gen_random_uuid()` | Identificador interno opaco; PK. |
| `organization_id` | `uuid` | Sí | Frontera obligatoria de organización. → `organizations` |
| `created_at` | `timestamptz` | Sí; `now()` | Fecha de creación UTC. |
| `updated_at` | `timestamptz` | Sí; `now()` | Última modificación; trigger de servidor. |
| `requested_by` | `uuid` | Sí | Solicitante → `memberships` |
| `report_code` | `text` | Sí | Tipo de reporte |
| `filters` | `jsonb` | Sí | Filtros autorizados |
| `status` | `text` | Sí; `'queued'` | queued, running, succeeded, failed, expired |
| `file_id` | `uuid` | No | Resultado privado → `files` |
| `expires_at` | `timestamptz` | No | Caducidad de descarga |

**Integridad:** PK `id`. UQ `(organization_id, id)`. CHECK: `status IN ('queued','running','succeeded','failed','expired')`.

**FK (todas `ON DELETE RESTRICT`):**

- `(organization_id)` → `organizations(id)`.
- `(organization_id, requested_by)` → `memberships(organization_id, id)`.
- `(organization_id, file_id)` → `files(organization_id, id)`.

**Contrato de autorización:** Solicitante lee; worker revalida permisos antes de generar y descarga; sin exportación global implícita.

---

### integration_settings

![Fase: MVP / Fase 2 / Fase 4](https://img.shields.io/static/v1?label=Fase&message=MVP%20/%20Fase%202%20/%20Fase%204&color=0066FF&style=for-the-badge) ![Ámbito: org](https://img.shields.io/static/v1?label=%C3%81mbito&message=org&color=0A1A3A&style=for-the-badge)

Configuración técnica no secreta por integración.

| Columna SQL | Tipo PostgreSQL | Obligatorio / default | Descripción |
|---|---|---|---|
| `id` | `uuid` | Sí; `gen_random_uuid()` | Identificador interno opaco; PK. |
| `organization_id` | `uuid` | Sí | Frontera obligatoria de organización. → `organizations` |
| `created_at` | `timestamptz` | Sí; `now()` | Fecha de creación UTC. |
| `updated_at` | `timestamptz` | Sí; `now()` | Última modificación; trigger de servidor. |
| `provider` | `text` | Sí | foundry, speech, ml, search, graph |
| `enabled` | `boolean` | Sí; `false` | Activación |
| `configuration` | `jsonb` | Sí; `'{}'::jsonb` | IDs y opciones no secretas |
| `secret_ref` | `text` | No | Referencia externa, no valor de secreto |
| `updated_by` | `uuid` | Sí | Responsable → `memberships` |
| `version` | `integer` | Sí; `1` | Concurrencia |

**Integridad:** PK `id`. UQ `(organization_id, id)`. UQ `(organization_id, provider)`. CHECK: `version > 0`.

**FK (todas `ON DELETE RESTRICT`):**

- `(organization_id)` → `organizations(id)`.
- `(organization_id, updated_by)` → `memberships(organization_id, id)`.

**Contrato de autorización:** Solo integrador/superadmin delegado; no expone credenciales ni contenido privado.

---

### quota_limits

![Fase: MVP / Fase 2 / Fase 4](https://img.shields.io/static/v1?label=Fase&message=MVP%20/%20Fase%202%20/%20Fase%204&color=0066FF&style=for-the-badge) ![Ámbito: org](https://img.shields.io/static/v1?label=%C3%81mbito&message=org&color=0A1A3A&style=for-the-badge)

Límites de consumo internos.

| Columna SQL | Tipo PostgreSQL | Obligatorio / default | Descripción |
|---|---|---|---|
| `id` | `uuid` | Sí; `gen_random_uuid()` | Identificador interno opaco; PK. |
| `organization_id` | `uuid` | Sí | Frontera obligatoria de organización. → `organizations` |
| `created_at` | `timestamptz` | Sí; `now()` | Fecha de creación UTC. |
| `updated_at` | `timestamptz` | Sí; `now()` | Última modificación; trigger de servidor. |
| `service_code` | `text` | Sí | Servicio |
| `period` | `text` | Sí | day, month |
| `max_quantity` | `numeric(18,6)` | No | Tope de unidades |
| `max_estimated_usd` | `numeric(14,6)` | No | Tope orientativo de gasto |
| `enabled` | `boolean` | Sí; `true` | Aplicación de cuota |

**Integridad:** PK `id`. UQ `(organization_id, id)`. UQ `(organization_id, service_code, period)`. CHECK: `max_quantity >= 0`; `max_estimated_usd >= 0`; `period IN ('day','month')`; `num_nonnulls(max_quantity,max_estimated_usd) >= 1`.

**FK (todas `ON DELETE RESTRICT`):**

- `(organization_id)` → `organizations(id)`.

**Contrato de autorización:** Integrador configura; servicio de cuotas reserva y liquida consumo; no garantiza tope de factura externa.

---

### idempotency_keys

![Fase: MVP / Fase 2 / Fase 4](https://img.shields.io/static/v1?label=Fase&message=MVP%20/%20Fase%202%20/%20Fase%204&color=0066FF&style=for-the-badge) ![Ámbito: org](https://img.shields.io/static/v1?label=%C3%81mbito&message=org&color=0A1A3A&style=for-the-badge)

Prevención de operaciones duplicadas por reintento.

| Columna SQL | Tipo PostgreSQL | Obligatorio / default | Descripción |
|---|---|---|---|
| `id` | `uuid` | Sí; `gen_random_uuid()` | Identificador interno opaco; PK. |
| `organization_id` | `uuid` | Sí | Frontera obligatoria de organización. → `organizations` |
| `created_at` | `timestamptz` | Sí; `now()` | Fecha de creación UTC. |
| `updated_at` | `timestamptz` | Sí; `now()` | Última modificación; trigger de servidor. |
| `membership_id` | `uuid` | Sí | Actor → `memberships` |
| `operation` | `text` | Sí | Caso de uso |
| `key` | `text` | Sí | Clave del cliente |
| `request_hash` | `text` | Sí | Hash del DTO normalizado |
| `response_ref` | `uuid` | No | Recurso resultante |
| `expires_at` | `timestamptz` | Sí | Caducidad |

**Integridad:** PK `id`. UQ `(organization_id, id)`. UQ `(membership_id, operation, key)`. 

**FK (todas `ON DELETE RESTRICT`):**

- `(organization_id)` → `organizations(id)`.
- `(organization_id, membership_id)` → `memberships(organization_id, id)`.

**Contrato de autorización:** Solo servicio de operación; comparar hash y no devolver respuestas de otro actor.

---

