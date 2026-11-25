# MTA NEXUS — Stack tecnológico Frontend

![MTA Nexus — Frontend](https://img.shields.io/badge/MTA%20Nexus-Frontend-0066FF?style=flat-square) ![Versión 1.1](https://img.shields.io/badge/Versi%C3%B3n-1.1-0A1A3A?style=flat-square) ![Local sin licencia de pago](https://img.shields.io/badge/Local-sin%20licencia%20de%20pago-166534?style=flat-square) ![Azure opcional y sujeto a consumo](https://img.shields.io/badge/Azure-cr%C3%A9ditos%20y%20cuotas-92400E?style=flat-square)

**Etiquetas de revisión:** `v1.1` · `Badges y etiquetas` · `Paleta MTA` · `Modo claro/oscuro` · `Sin emojis`

> Los badges de cabecera son una ayuda visual opcional del visor Markdown (imágenes remotas de Shields.io); los textos alternativos y etiquetas mantienen el significado sin conexión. La aplicación no dependerá de Shields.io ni de un servicio de badges externo.

**Documento:** arquitectura, sistema de diseño y guía de implementación del cliente web  
**Versión:** 1.1 — 24 de noviembre de 2026 (ampliación del sistema visual de badges y etiquetas)  
**Framework obligatorio:** Next.js (App Router) + React + TypeScript  
**Documento base:** `MTA_Nexus_Especificacion.md`, v1.0  
**Documento complementario:** `MTA_Nexus_Stack_Backend_v1.1.md` (NestJS)

> Decisión de arquitectura: se reemplaza la propuesta anterior de usar Next.js como backend principal por un frontend Next.js y una API NestJS independiente. Next.js podrá actuar como BFF (Backend for Frontend) para sesión y proxy, pero la lógica de negocio será responsabilidad de NestJS. Este documento define el producto objetivo, no afirma que esté implementado. No exige plantillas premium, licencias comerciales, servicios de IA distintos de Azure ni suscripciones pagadas.

## 1. Objetivo y principios

MTA Nexus será un workspace empresarial de MTA Software: gestión de proyectos y tareas tipo Trello, horas, reportes, calendario, soporte, MIA Assistant, MIA Academy, conocimiento, AI Analytics, servicios y planes, equipo y administración. La experiencia debe ser fluida, dinámica, accesible y coherente entre todos los módulos.

Principios obligatorios:

- Construir una aplicación funcional, no un dashboard decorativo. Cada botón tendrá un comportamiento, un estado, permisos y manejo de errores.
- Priorizar animación con propósito: explicar jerarquías, cambios, carga, navegación, feedback y actividad en tiempo real. Evitar movimientos constantes que dificulten el trabajo.
- Usar iconos vectoriales consistentes, nunca emojis como iconos, títulos, notificaciones ni elementos del diseño. Usar Lucide, ilustraciones propias y el logotipo corporativo autorizado.
- Reutilizar componentes y tokens; no crear una interfaz distinta por cada módulo.
- No duplicar lógica de negocio o acceso directo a tablas desde el frontend. NestJS es la autoridad para operaciones y permisos.
- Mostrar datos reales de la API o un entorno demo claramente identificado. No simular respuestas de MIA, métricas, predicciones ni precios como si fueran reales.
- Todas las dependencias deben poder ejecutarse localmente sin licencia de pago. Las funciones cloud estarán sujetas a cuotas, créditos y disponibilidad.

## 2. Stack principal y política de versiones

| Tecnología | Uso | Condición |
|---|---|---|
| Next.js App Router | Rutas, layouts, SSR, streaming, BFF y optimización de assets | Código abierto; sin obligación de contratar Vercel |
| React | Componentes y composición de interfaces | Código abierto |
| TypeScript strict | Tipos, contratos API, modelos de UI y validación de compilación | Código abierto |
| Node.js 24 LTS | Runtime compartido con NestJS | Fijar versión de parche compatible; no depender de una rama experimental |
| pnpm + workspaces | Instalación reproducible y monorepo | Gratuito |
| Tailwind CSS v4 | Utilidades y tokens semánticos mediante CSS variables | Gratuito; no confundir con plantillas comerciales Tailwind Plus |
| shadcn/ui | Componentes de diseño que pasan a formar parte del código fuente | Usar componentes abiertos, no bloques premium |
| Radix UI | Primitivas accesibles de diálogo, menú, popover, tabs y otros | Gratuito |
| Lucide React | Iconografía de toda la plataforma | Gratuito; licencia ISC |
| Motion (`motion/react`) | Transiciones, layout animations, gestos, modales y microinteracciones | Usar API abierta, sin Motion+ |
| TanStack Query | Estado remoto, caché, reintentos e invalidación | Gratuito |
| Zustand | Estado de interfaz compartido cuando React local no sea suficiente | Gratuito |
| React Hook Form + Zod | Formularios, validación de UI y esquemas de entrada | Gratuito |
| Supabase Auth + `@supabase/ssr` | Sesión SSR y autenticación del usuario | CLI local o plan Free; límites de proveedor |
| `openapi-typescript` + `openapi-fetch` | Cliente tipado generado desde Swagger de NestJS | Gratuito |
| ESLint + Prettier | Calidad y formato | Gratuito |

Usar versiones estables compatibles entre sí, fijadas en `pnpm-lock.yaml`. Node 24 LTS es la línea recomendada; verificar requisitos de Next, Nest y librerías antes de instalar. No fijar números de parche inventados ni usar `latest` en CI. Probar React, Next, Tailwind, Motion y adaptadores juntos antes de cerrar la versión inicial. Revisar licencias de dependencias transitivas y conservar avisos de copyright. Que una librería sea abierta no significa que un servicio hospedado asociado sea gratuito.

## 3. Librerías por capacidad (instalación progresiva)

### 3.1 UI, diseño y navegación

| Paquete | Funcionalidad concreta |
|---|---|
| `class-variance-authority`, `clsx`, `tailwind-merge` | Variantes de tamaño/estado y composición de clases sin duplicación |
| `lucide-react` | Navegación, acciones, estados y toolbar |
| `next-themes` | Preferencia claro/oscuro/sistema sin parpadeo inicial |
| `sonner` | Toast de guardado, error, recuperación, acción deshacer |
| `cmdk` | Paleta de comandos Ctrl/Cmd+K y buscador global |
| `react-resizable-panels` | Paneles redimensionables en MIA, archivos y vistas de detalle |
| `embla-carousel-react` | Carruseles accesibles de Academy cuando aporten valor |
| `react-day-picker` | Selectores de fecha y rango |
| `vaul` | Drawer táctil opcional mediante componentes shadcn compatibles |
| `date-fns` y `@date-fns/tz` | Fechas, duración, rangos y zona America/Lima o la del perfil |

### 3.2 Animaciones y experiencia visual avanzada

| Paquete | Aplicación | Fase |
|---|---|---|
| `motion` | Motor principal de animación: presencia, layout, gestos, stagger y springs | MVP |
| CSS nativo | Hover, focus, transiciones de tokens, skeleton y gradientes | MVP |
| `gsap` + `@gsap/react` | Secuencias complejas o narrativas visuales en bienvenida/briefing | Avanzada; API gratuita y licencia vigente por revisar |
| `lottie-react` | Ilustraciones animadas locales, de carga o onboarding | Opcional; assets propios/licenciados |
| `three`, `@react-three/fiber`, `@react-three/drei` | Avatar 3D propio, escenas ligeras y visualización espacial | Avanzada; solo si aporta valor |

Motion y GSAP no deben modificar la misma propiedad del mismo nodo. No instalar un motor por cada efecto. Cargar GSAP, Lottie y Three de forma diferida. No depender de modelos 3D, animaciones descargadas o imágenes sin licencia. No usar scroll hijacking, cursores personalizados obligatorios ni efectos de partículas permanentes en el workspace.

### 3.3 Datos, productividad y visualización

| Paquete | Uso concreto |
|---|---|
| `@dnd-kit/core`, `@dnd-kit/sortable`, `@dnd-kit/utilities` | Drag & drop Kanban; verificar compatibilidad de esta familia de API con React elegido; no mezclar generaciones de dnd-kit |
| `@tanstack/react-table` | Tablas de reportes, usuarios, tareas, conocimiento, planes |
| `@tanstack/react-virtual` | Virtualización de filas/listas grandes y chats extensos cuando haga falta |
| `recharts` | Gráficos de barras, áreas, líneas, donut, composición y tooltips |
| `@fullcalendar/react`, `@fullcalendar/core`, `@fullcalendar/daygrid`, `@fullcalendar/timegrid`, `@fullcalendar/interaction`, `@fullcalendar/list` | Calendario estándar de eventos, entregas, drag y agenda; sin plugins Premium Resource Timeline/Scheduler |
| `@tiptap/react`, `@tiptap/starter-kit` | Editor enriquecido de tarjetas, cursos, guías y documentación; usar extensiones abiertas y compatibles |
| `react-markdown`, `remark-gfm`, `rehype-sanitize` | Render seguro de respuestas de MIA, tablas, listas y código |
| `shiki` | Resaltado de código en Academy/MIA, preferentemente bajo demanda o servidor |
| `@monaco-editor/react`, `monaco-editor` | Editor de ejercicios y ejemplos; carga diferida, workers locales; no ejecutar código arbitrario |
| `react-dropzone` | Interfaz de adjuntos, evidencias, PDF e importación |
| `pdfjs-dist` | Visor PDF privado, worker local de misma versión, sin subir archivos a visores externos |
| `papaparse` | Previsualización CSV local; la importación final es validada en NestJS |
| `react-player` (opcional) | Reproducción de contenidos permitidos; preferir video HTML nativo en MVP |
| `dompurify` (si se necesita HTML) | Sanitizar HTML antes de renderizar; preferir JSON estructurado y Markdown sin HTML crudo |

No utilizar AG Grid Enterprise, FullCalendar Premium, Tiptap Cloud/Pro, editores de pago ni servicios de búsqueda comercial. Para cronograma/Gantt, crear vista CSS Grid/SVG con virtualización y controles accesibles; no requiere scheduler premium. Para mapas de calor y redes simples, usar CSS/SVG; introducir otro motor gráfico solo si Recharts no cubre un requisito medido.

### 3.4 IA, voz y avatar

| Tecnología | Función | Costo |
|---|---|---|
| Fetch + ReadableStream + AbortController | Chat en streaming a NestJS mediante BFF | Local gratuito; generación Azure consume crédito |
| Web Speech API | Dictado y lectura opcionales según navegador | Sin contrato extra, pero disponibilidad y procesamiento local/remoto varían; no garantizar offline ni privacidad local |
| HTML Audio / Web Audio API | Reproducción, amplitud visual, medidor de voz | Gratuito |
| `microsoft-cognitiveservices-speech-sdk` | STT/TTS de Azure y avatar WebRTC si están habilitados | SDK sin licencia de pago; consumo Azure facturable |
| Three.js/R3F o SVG + Motion | Avatar visual propio con estados idle/listening/thinking/speaking | Gratuito con assets licenciados |

Usar por defecto un avatar corporativo local animado con voz del navegador si está disponible; el chat textual siempre funciona sin micrófono. Nunca sustituir el agente real por respuestas generadas localmente sin indicarlo. El avatar Microsoft es una mejora opcional; el SDK no vuelve gratuito el servicio.

## 4. Arquitectura del repositorio y límites

Monorepo sugerido:

```text
mta-nexus/
  apps/
    web/                 # Next.js
    api/                 # NestJS
  packages/
    api-client/          # Tipos y cliente generados por OpenAPI
    design-tokens/       # Tokens CSS de marca; sin lógica de negocio
    config/              # ESLint/TSConfig compartidos
  supabase/              # Migraciones SQL y configuración local
  docs/                  # SRS y estos documentos
  pnpm-workspace.yaml
  pnpm-lock.yaml
```

Frontend:

```text
apps/web/src/
  app/
    (public)/
    (auth)/
      login/page.tsx
      invite/page.tsx
      forgot-password/page.tsx
      reset-password/page.tsx
      onboarding/page.tsx
    (workspace)/
      layout.tsx
      dashboard/page.tsx
      projects/[projectId]/boards/[boardId]/page.tsx
      tasks/page.tsx
      time/page.tsx
      calendar/page.tsx
      support/page.tsx
      mia/page.tsx
      academy/page.tsx
      knowledge/page.tsx
      analytics/page.tsx
      services/page.tsx
      team/page.tsx
      notifications/page.tsx
      profile/page.tsx
      settings/page.tsx
      admin/page.tsx
      system/page.tsx
    api/bff/[...path]/route.ts    # proxy explícitamente permitido; no proxy abierto
    auth/callback/route.ts
    layout.tsx
    error.tsx
    not-found.tsx
    globals.css
  components/
    ui/             # shadcn y primitivas
    layout/         # AppShell, Sidebar, Header, MobileNav
    feedback/       # Skeleton, EmptyState, ErrorState, PermissionState
    forms/          # campos y secciones reutilizables
    data-display/   # tabla, gráfico, tarjetas KPI
    motion/         # wrappers y presets de animación
  features/
    auth/ dashboard/ projects/ boards/ tasks/ time/ calendar/
    support/ mia/ academy/ knowledge/ analytics/ services/
    team/ notifications/ profile/ settings/ admin/ system/
  lib/
    api/ auth/ permissions/ formatting/ validation/
  hooks/
  providers/
  stores/
  styles/
  tests/
```

Cada feature puede contener `components`, `hooks`, `queries`, `schemas`, `types`, `utils` y `tests`. Mantener dependencias dirigidas hacia componentes compartidos; evitar imports circulares. Los Server Components se utilizan para layouts, datos iniciales y páginas informativas; los Client Components se limitan a eventos, gráficos, formularios, drag, voz y estado interactivo. No convertir el árbol completo en cliente. Los datos privados SSR deben ser específicos de sesión, no cacheados globalmente.

## 5. Comunicación Next.js - NestJS

- Navegador se comunica con rutas same-origin de Next (BFF) y no recibe credenciales Azure, DB o claves administrativas.
- Supabase SSR establece cookies de sesión siguiendo la documentación oficial. El BFF obtiene/valida la sesión de forma segura, reenvía un access token al backend; Nest valida firma, emisor, audiencia, expiración, cuenta y permisos. No autorizar a partir de un objeto `session` sin verificar.
- El BFF permite únicamente rutas y métodos previstos, reenvía `Authorization` desde la sesión verificada y nunca confía en headers de identidad del cliente. Proteger escrituras contra CSRF, validar Origin/Host y aplicar límites de tamaño y tiempo. No permitir URLs arbitrarias.
- Contrato REST `/api/v1` mediante OpenAPI. React Query usa claves por organización, usuario, recurso y filtro. Limpiar caché al cerrar sesión o cambiar contexto. Estado de servidor no se duplica en Zustand.
- Streaming SSE/fetch: conservar framing de eventos y señal de cancelación; no almacenar buffers completos. Eventos `delta`, `citation`, `tool_status`, `done`, `error` para MIA; eventos de dominio separados para tareas y notificaciones. Reconectar con backoff y refrescar datos al perder eventos.
- Adjuntos: solicitar sesión de subida autorizada a Nest, cargar mediante URL firmada si procede, finalizar y consultar estado de análisis. No usar buckets públicos para información interna.
- Manejar 401 (reauth), 403/404 (sin acceso), 409 (conflicto), 422 (validación), 429 (límite) y 503 (servicio no disponible). Mensajes en español; correlation ID para soporte. Operaciones optimistas solo si se puede revertir correctamente.

## 6. Sistema de diseño MTA Software

### 6.1 Tokens de marca

```css
:root {
  --mta-deep: #0A1A3A;
  --mta-primary: #0066FF;
  --mta-cyan: #00A1FF;
  --mta-soft: #66C2FF;
  --mta-bg: #F2F6FA;
  --surface: #FFFFFF;
  --foreground: #0A1A3A;
  --border: #DCE5F1;
  --muted-foreground: #52647B;
  --radius-card: 16px;
  --radius-control: 10px;
  --gradient-brand: linear-gradient(110deg, #0066FF, #00A1FF);
  --gradient-symbol: linear-gradient(110deg, #0A1A3A, #0066FF, #66C2FF);
}
```

Modo oscuro con superficies azul noche, texto claro y bordes diferenciados; no invertir imágenes/logotipo. Mapear tokens semánticos de shadcn a estos valores. Los colores de éxito, advertencia y error no reemplazan las etiquetas de texto. Verificar contraste WCAG AA; azul claro sobre blanco se reserva para acento, no texto pequeño sin comprobar contraste.

Tipografía: Inter local mediante `next/font/local` o una sans serif de sistema; conservar licencia de fuentes. Títulos 24–32 px, subtítulos 18–20 px, cuerpo 14–16 px, metadata 12–13 px. Números tabulares en horas y métricas. Espaciado 4/8 px, tarjetas 12–16 px, sombra discreta, borde sutil. Estilo corporativo premium, no aspecto de videojuego.

### 6.2 Layout y componentes globales

- AppShell: sidebar de 240–264 px colapsable a 64–72 px; header sticky, breadcrumb, búsqueda Ctrl/Cmd+K, creación rápida, timer, campana y perfil.
- Desktop: grid de 12 columnas, panel derecho contextual de 320–420 px, max-width flexible según módulo. Tablet: sidebar compacta y sheets. Móvil: drawer, acciones agrupadas, tablero horizontal táctil y detalles a pantalla completa.
- Componentes: `PageHeader`, `SectionHeader`, `StatCard`, `MetricSparkline`, `FilterBar`, `DataTable`, `Pagination`, `StatusPill`, `PriorityBadge`, `AvatarGroup`, `MemberPicker`, `DateRangePicker`, `EntityCombobox`, `FormField`, `RichTextEditor`, `FileUploader`, `ActivityTimeline`, `PermissionGate`, `ConfirmDialog`, `EmptyState`, `ErrorState`, `LoadingSkeleton`, `NotificationInbox`, `MiaDock`.
- Cada componente debe admitir variantes, loading, disabled, focus y accesibilidad. Los `PermissionGate` solo controlan visualización; Nest vuelve a verificar cada acción.
- Skeletons con dimensiones estables, mensajes de vacío con CTA autorizado y retry para errores recuperables. No usar emojis ni en textos de fallback.

### 6.3 Sistema de badges, etiquetas y colores — obligatorio en toda la aplicación

**Requisito transversal de diseño:** cada módulo utiliza un vocabulario visual consistente para estados, prioridades, roles, especialidades, categorías, vigencia, riesgo, procedencia y disponibilidad. No limitar las etiquetas al Kanban. Los badges deben comunicar información útil, no ser adornos. No utilizar emojis ni contratar componentes premium.

#### 6.3.1 Componentes y dependencias

| Componente reutilizable | Uso y comportamiento |
|---|---|
| `Badge` (shadcn/ui + CVA) | Primitiva de presentación: variantes `soft`, `outline`, `solid`; texto breve, tamaño `sm`/`md`, icono Lucide opcional |
| `StatusBadge` / `StatusPill` | Estado semántico del recurso, lectura de código tipado, fallback neutro para estado desconocido |
| `PriorityBadge`, `RiskBadge` | Prioridad y riesgo separado del estado; no inferir riesgo a partir del color ni de una predicción ausente |
| `RoleBadge`, `SpecialtyBadge`, `LabelChip` | Rol efectivo, especialidad y etiqueta personalizable con nombre visible |
| `BadgeGroup`, `OverflowBadges` | Agrupar etiquetas con wrap y contador `+N`; popover con todas las etiquetas accesible por teclado |
| `LabelPicker`, `LabelManager`, `ColorTokenPicker` | Crear, editar, buscar, aplicar, retirar y archivar etiquetas dentro del alcance autorizado |
| `FilterChip`, `TagInput` | Filtros seleccionables, remoción accesible con botón y nombre, limpiar todos; distinguir de un badge pasivo |
| `SourceBadge`, `CapabilityBadge`, `SyncBadge` | Procedencia, integración, vigencia y sincronización real del backend |
| `AchievementBadge` | Insignias de Academy con SVG/Lucide, título, criterio, fecha y progreso; no confundir con estados de curso |

Usar `class-variance-authority`, `clsx`, `tailwind-merge`, CSS variables, `lucide-react` y primitivas Radix/shadcn ya elegidas. No agregar una librería exclusiva de badges. `Badge` pasivo es un `span`; si permite filtrar o seleccionar se usa un botón con estado `aria-pressed`, y si navega se usa un enlace. Un badge que no realiza una acción no tendrá cursor interactivo. El selector de color debe tener texto y foco visible.

#### 6.3.2 Paleta semántica compartida (propuesta de tokens)

Conservar los cinco colores de marca de 6.1. Los tonos de estado complementan la marca sin sustituirla. Cada fila contiene fondo/texto/borde para modo claro y fondo/texto para modo oscuro. Validar contraste WCAG AA de los estados finales, incluidos hover y focus, durante implementación. Los azules claros corporativos se reservan a acentos y gráficos cuando no alcancen contraste de texto.

| Token | Claro: fondo / texto / borde | Oscuro: fondo / texto | Significado |
|---|---|---|---|
| `neutral` | `#F1F5F9` / `#334155` / `#CBD5E1` | `#253449` / `#E2E8F0` | Pendiente, borrador, sin dato, archivado |
| `brand` | `#E8F0FF` / `#1746A2` / `#B8D2FF` | `#142D58` / `#BFDBFE` | Activo, asignación, marca |
| `info` | `#E0F2FE` / `#075985` / `#BAE6FD` | `#103548` / `#BAE6FD` | Proceso, revisión, información |
| `success` | `#DCFCE7` / `#166534` / `#BBF7D0` | `#143B2B` / `#BBF7D0` | Finalizado, aprobado, disponible |
| `warning` | `#FEF3C7` / `#92400E` / `#FDE68A` | `#422D15` / `#FDE68A` | Vencimiento cercano, revisión pendiente, cuota próxima |
| `danger` | `#FEE2E2` / `#991B1B` / `#FECACA` | `#48232A` / `#FECACA` | Bloqueo, error, retraso confirmado, riesgo alto |
| `violet` | `#EDE9FE` / `#5B21B6` / `#DDD6FE` | `#36254F` / `#DDD6FE` | IA, especialidades, mentoría |
| `teal` | `#CCFBF1` / `#115E59` / `#99F6E4` | `#103A39` / `#99F6E4` | Categoría técnica o integración |
| `orange` | `#FFEDD5` / `#9A3412` / `#FED7AA` | `#432917` / `#FED7AA` | Prioridad alta o categoría personalizada |

Ejemplo de estructura de estilos (extender las variables existentes; sin clases Tailwind construidas desde entradas del usuario):

```css
:root {
  --badge-success-bg: #DCFCE7;
  --badge-success-fg: #166534;
  --badge-success-border: #BBF7D0;
  --badge-brand-bg: #E8F0FF;
  --badge-brand-fg: #1746A2;
  --badge-brand-border: #B8D2FF;
}
.dark {
  --badge-success-bg: #143B2B;
  --badge-success-fg: #BBF7D0;
  --badge-success-border: #38604B;
  --badge-brand-bg: #142D58;
  --badge-brand-fg: #BFDBFE;
  --badge-brand-border: #36588A;
}
```

Completar los nueve tokens con el mismo patrón. Mantener un mapa estático exhaustivo de variantes de CVA que referencie las variables. Los códigos de backend se transforman en nombres traducidos y tonos mediante diccionarios tipados de cada dominio. No usar clases como `bg-${color}` con valores de API. Las etiquetas libres usan tokens permitidos y no admiten CSS arbitrario.

#### 6.3.3 Catálogo de estados y etiquetas por módulo

Las denominaciones de esta tabla son textos de interfaz propuestos; los códigos persistidos se consolidan en el contrato OpenAPI de NestJS. Una misma entidad puede mostrar estado, prioridad y origen de manera independiente. No convertir un estado visual en autorización o regla de negocio.

| Vista | Badges y etiquetas requeridos |
|---|---|
| Login / onboarding | Sesión expirada, MFA requerido, invitación pendiente, cuenta activa/suspendida (solo donde corresponda sin enumerar cuentas) |
| Dashboard | Variación positiva/negativa con contexto de métrica, demo/operativo, actualizado, sin datos, filtros activos, tareas vencidas, bloqueos; mostrar unidad y período |
| Proyectos | Planificado (neutral), activo (brand), en pausa (warning), completado (success), archivado (neutral); tecnologías y miembros |
| Kanban / Mis tareas | Por hacer (neutral), en progreso (brand), en revisión (info), finalizada (success), bloqueada (danger); prioridad baja (neutral), media (info), alta (orange), urgente (danger); tags de frontend/backend/QA/DevOps, checklist, horas, vencimiento |
| Horas | Borrador (neutral), enviado (info), aprobado (success), rechazado (danger); origen manual/temporizador/histórico; exceso de estimación si el dato existe |
| Calendario | Entrega, reunión, capacitación, mentoría; pendiente/confirmado/cancelado según entidad y permisos |
| Bloqueos / soporte | Abierto, en atención, esperando respuesta, resuelto, cerrado; severidad separada y etiquetas técnicas |
| MIA Assistant | Escuchando, pensando, hablando, error; fuente documental, datos operativos, histórico/demo, información insuficiente, fuera de contexto, acción propuesta/confirmada; voz/avatar disponible o desactivado |
| MIA Academy | Principiante/intermedio/avanzado; Frontend, Backend, IA, DevOps, Scrum; no iniciado/en curso/completado; evaluación pendiente/aprobada/no aprobada; logros y certificados verificables |
| Conocimiento | Borrador, en revisión, publicado, retirado; indexando, listo, fallo de indexación, no indexado; clasificación y versión, vigencia y etiquetas temáticas |
| AI Analytics | Datos simulados/operativos; modelo disponible/no disponible, resultado registrado, exportación en cola/proceso/lista/error; clase predicha y riesgo solo según evidencia real |
| Servicios y planes | Borrador, en revisión, publicado, vigente, vencido, retirado; precio por confirmar, plan recomendado solo si aprobado, tecnología y segmento |
| Equipo | Practicante, líder de proyecto, supervisor, administrador, superadministrador; activo/invitado/suspendido; especialidad y disponibilidad registrada |
| Notificaciones | No leída, mención, tarea, aprobación, academia, sistema; prioridad real y contador de pendientes |
| Perfil | Cuenta activa, MFA habilitado/deshabilitado, preferencias de tema; rol de solo lectura |
| Administración | Permiso concedido/restringido, invitación pendiente, cambios pendientes, aprobación; estados de usuarios |
| Superadministración | Salud operativa/degradada/no disponible; integración configurada/verificada/desactivada; cuota, job y auditoría; nunca equiparar configurado con conectado |
| Portal público | Categoría, característica incluida, plan vigente y disponibilidad pública aprobada; sin revelar roles, datos internos ni tags privados |

Los estados de negocio, permisos, indexación, predicción y auditoría son de solo lectura como badges; se cambian mediante acciones autorizadas, no haciendo clic en su color. Los filtros y tags personalizables sí podrán editarse cuando exista permiso.

#### 6.3.4 Etiquetas avanzadas de Trello y gestión visual

- Mostrar etiquetas de color con texto corto en la parte superior de la tarjeta, título debajo, metadata y responsables al pie. En modo compacto se pueden reducir a barras, pero debe existir una opción para expandir a texto y un nombre accesible por etiqueta.
- Administrador del proyecto/líder delegado: abrir `LabelManager`, buscar, crear con nombre y descripción opcional, seleccionar uno de los tokens, editar nombre/color, archivar, restaurar y consultar cuántas tarjetas lo usan. Confirmar archivado con impacto; no eliminar la trazabilidad ni cambiar estado por renombrar una etiqueta.
- Aplicación de etiquetas desde tarjeta, menú rápido y selección múltiple: cambios optimistas únicamente si el servidor autoriza; al fallar revertir y mostrar explicación. Mantener historial de cambios. No permitir selección entre proyectos no autorizados.
- Filtros combinables por etiqueta, miembro, prioridad, vencimiento, bloqueo, estado y búsqueda. Operadores “cualquiera” / “todas” para etiquetas, visibles en UI; persistir en URL cuando sea posible. Indicar número de resultados y vacíos de filtro.
- Mostrar hasta tres tags en tarjetas pequeñas; `+N` abre listado completo, con truncado seguro y tooltip opcional. En móvil permitir wrap y menú de acciones; no depender de hover.
- Semillas sugeridas y configurables: Frontend (brand), Backend (teal), QA (violet), DevOps (orange), Documentación (neutral), Bug (danger), Mejora (info), Investigación (violet). Son categorías visuales propuestas, no datos confirmados de la empresa ni prioridades automáticas.
- Fechas y horas: mostrar `Vence hoy`, `Vencida` o `Sin fecha` según zona y estado; una tarjeta finalizada tarde conserva el indicador histórico de retraso, no se muestra como pendiente vencida. `4/6 h` se acompaña de tooltip de reportadas/estimadas; exceso no equivale automáticamente a retraso. Checklist muestra `3/5` y barra discreta.
- El color de la columna es un acento; el estado semántico y la validación de transiciones se obtienen del backend. Arrastrar entre columnas no modifica etiquetas arbitrariamente. Animar inserción, cambio de orden y aparición de tags con Motion, sin parpadeo continuo ni movimiento cuando se reduce movimiento.

#### 6.3.5 Academy, IA y analítica: experiencia visual especial

Academy tendrá una galería de logros con `AchievementBadge` (por ejemplo, completar ruta inicial o evaluación aprobada), bloqueo visual de logros no obtenidos, criterios y progreso reales. No conceder insignias solo desde el cliente. Los badges de curso muestran nivel, tecnología, formato, duración y estado; máximo tres destacados por tarjeta, resto en detalle. Certificado y logro son conceptos diferentes.

MIA usa una cápsula compacta de estado del avatar y badges de fuentes con enlaces autorizados. El estado `thinking` puede animar un halo de forma discreta; `speaking` usa waveform del audio si está disponible. La voz/avatares apagados se indican con texto, sin inventar conexión. En AI Analytics, `Riesgo alto` y `Retraso predicho` no se muestran como un retraso ya ocurrido; el umbral de riesgo es una política versionada si se usa probabilidad. Si no hay probabilidad real, mostrar solo la clase devuelta. Los gráficos usan leyendas, patrones y textos además de colores; no usar solo rojo/verde para comparar.

#### 6.3.6 Reglas visuales, rendimiento y aceptación

- Badges pequeños de 20–24 px visuales, con padding horizontal de 8–10 px y texto de 11–12 px; las áreas interactivas deben alcanzar objetivos táctiles accesibles, preferentemente 44 px. Para tablas, priorizar un estado y una prioridad. Evitar llenar toda la pantalla de píldoras y colores saturados.
- Usar semántica de iconos Lucide (`CheckCircle2`, `Clock3`, `AlertTriangle`, `LockKeyhole`, `Tag`, `ShieldCheck`, `GraduationCap`) solo donde aporten claridad. Iconos decorativos `aria-hidden`, texto obligatorio para estado; tooltips complementarios, no sustitutos.
- `Badge` no inicia requests por sí solo. Renderizar grandes tablas con paginación/virtualización según necesidad. Memoizar diccionarios estáticos; aplicar actualización al recibir SSE autorizado y revalidar con TanStack Query. No animar cientos de tags simultáneamente.
- Pruebas unitarias de mapa estado→texto/tono, fallback, overflow, badges interactivos y filtros; Playwright de crear/editar/aplicar etiquetas, recarga persistente, conflicto, archivado y permisos; axe y revisión manual en ambos temas. Verificar que el mismo estado se representa igual en dashboard, Kanban, lista, móvil y detalle.
- Criterio de terminado: todos los módulos tienen estados visibles y coherentes, etiquetas persistentes cuando aplica, paleta corporativa y semántica, tema claro/oscuro, ausencia de emojis, accesibilidad, sin librerías premium ni dependencias de servicios de badges externos.

## 7. Sistema de movimiento e interacción

| Patrón | Implementación | Duración orientativa |
|---|---|---|
| Entrada de página | opacity 0→1 y y 8→0, sin ocultar contenido SSR permanentemente | 180–240 ms |
| Stagger de dashboard | tarjetas con retraso de 30–50 ms, limitado al primer ingreso | máximo ~450 ms total |
| Hover/focus de tarjeta | borde/sombra y desplazamiento de 1–2 px | 120–160 ms |
| Sidebar | ancho/visibilidad; preferir transform donde corresponda | 180–220 ms |
| Modal y sheet | AnimatePresence con fade/scale o slide; foco restaurado | 160–240 ms |
| Kanban | DragOverlay, layout animation, drop target, spring corto | ligado al gesto |
| KPI y gráfico | interpolación visual al recibir datos; valor final accesible inmediato | 300–500 ms |
| MIA | halo y waveform vinculados a estado real, indicador de streaming | discreto; detener al estar idle |
| Toast y notificación | entrada y salida suaves; pausa al enfocar | 160–200 ms |
| Academy | progreso, transición de módulos, celebración breve sin emojis | 200–350 ms |

Usar `MotionConfig reducedMotion="user"`, `useReducedMotion`, CSS `prefers-reduced-motion` y alternativa estática para avatar y gráficos. Animar transform/opacity preferentemente. Cancelar efectos al desmontar, pausar fuera de viewport con IntersectionObserver, limitar requestAnimationFrame, evitar recalcular layout en cada frame. No secuestrar scroll ni forzar animación de ruta completa que elimine foco. Efectos de cursor y parallax se reservan a la landing/hero y se deshabilitan en móvil, teclado y movimiento reducido. El contenido debe ser utilizable incluso si el efecto falla.

## 8. Implementación por vista y módulo

| Ruta/módulo | Componentes y librerías | Interacción y lógica |
|---|---|---|
| `/login`, `/invite`, recuperación, onboarding | RHF, Zod, shadcn Input, password toggle, Motion | invitaciones, errores genéricos, MFA, redirección permitida y reauth; sin registro público interno |
| `/dashboard` | StatCard, Recharts, TanStack Query, Motion, FilterBar | filtros por período/proyecto/equipo, drill-down a tareas, cambios en tiempo real, widgets por rol, persistencia de orden/preferencias, briefing MIA |
| `/projects` | tarjetas/lista, table, tabs, filtros, dialog de proyecto | crear/editar/archivar según permiso, plantillas, estados, hitos y equipo; lista paginada |
| `/projects/:id` | ficha, tabs, resumen, miembros, timeline | vistas autorizadas: tablero, actividad, horas, archivos, bloqueos, configuración |
| `/tasks` | bandeja, tablero, lista, calendario, filtros | propias/asignadas, vencimiento, prioridad, búsqueda y acciones múltiples autorizadas |
| `/time` | timer, partes, table, gráficos, date range | iniciar/detener, registro manual, envío, revisión, aprobación, exportación |
| `/calendar` | FullCalendar estándar | entregas, cursos, reuniones y agenda; zona del usuario, drag con autorización y versión |
| `/support` | ticket list, detalle, comentarios, actividad | crear bloqueos, prioridad, asignación, resolución, convertir solución en borrador de guía |
| `/mia` | chat, Markdown seguro, drawer, audio, avatar, citations | consultar información autorizada, streaming, cancelar, copiar, feedback y confirmar propuestas |
| `/academy` | catálogo, filtros, progress, player, editor, quizzes | rutas, lecciones, prácticas, evaluaciones, mentoría, certificados internos y edición aprobada |
| `/knowledge` | tree/list, upload, viewer, diff/versiones | carga, revisión, publicación, indexación, retiro, reintentos autorizados, permisos |
| `/analytics` | Recharts, TanStack Table, filtro, wizard | métricas, comparación, escenarios ML, exportaciones y estado del modelo |
| `/services` | fichas, tablas, comparador, formulario de plan | catálogo, versiones, moneda, vigencia, cotización snapshot y aprobación; no inventar precios |
| `/team` | directorio, perfiles, roles, carga, invitaciones | alcance de equipo, líderes por proyecto, suspensión y capacidad autorizadas |
| `/notifications` | bandeja, tabs, filtros, preferencias | leído/no leído, marcar todo, menciones y vínculos con revalidación |
| `/profile` | avatar, formulario, sesiones, preferencias | actualizar campos permitidos, zona horaria, idioma, tema, seguridad |
| `/settings` | paneles de configuración | preferencias personales, notificaciones, movimiento, audio; no modificar rol propio |
| `/admin` | tablas, forms, permisos, catálogos | usuarios, invitaciones, configuración funcional y aprobaciones delegadas |
| `/system` | health, integraciones, auditoría, cuotas | diagnóstico sin acceso implícito a tareas privadas; activar servicios con permiso y confirmación |
| Portal público opcional | SSR, landing, servicios y planes publicados | SEO, contacto y datos aprobados únicamente; sin IDs privados, sin indexar workspace |

### 8.1 Dashboard altamente interactivo

Composición por rol: encabezado con saludo y resumen, KPI, actividad, calendario breve, tareas próximas, bloqueos, avance de proyectos y panel MIA. Supervisor ve capacidad y aprobaciones; practicante ve tareas y aprendizaje; superadmin ve salud técnica y cuotas. La personalización de widgets no puede habilitar métricas no autorizadas.

Interacciones: filtros reflejados en URL, tooltips con unidad/denominador/fecha, cross-filter a la tabla, drill-down a registros, rango de fechas, comparación períodos equivalentes, refrescar y descargar. Datos provenientes de Nest; no calcular totales empresariales a partir de una sola página paginada. Mostrar origen demo, período y estado de actualización. Gráficas con leyenda, alternativa tabular y estados sin datos. Transiciones de entrada y actualización no deben retrasar la navegación.

### 8.2 Kanban estilo Trello — diseño de máxima prioridad

`BoardHeader`, `BoardToolbar`, `KanbanBoard`, `KanbanColumn`, `CardPreview`, `CardDetail`, `DragOverlay`, `ColumnComposer`, `CardComposer`, `ChecklistEditor`, `CommentThread`, `AttachmentGallery`, `ActivityTimeline`, `TimeEntryPanel`, `DependencyPicker`, `AutomationRuleDialog`.

- Crear, renombrar, reordenar, archivar y restaurar columnas. Mostrar límite WIP, conteo, semántica de estado y validación si hay tarjetas activas. No borrar columnas ocupadas sin flujo autorizado.
- Crear tarjetas desde cada columna y desde menú global; título, descripción, responsable(s), etiquetas de color, prioridad, fecha, horas estimadas, dependencias, checklist, subtareas, comentarios, adjuntos, observadores y portada opcional.
- Drag con mouse/touch/teclado; opción explícita “Mover a columna” como alternativa accesible. Auto-scroll, overlay, placeholders y destino válido. Orden persistido en backend con versión, `Idempotency-Key` y conflicto 409; revertir cambios si falla. No asumir que mover a Finalizado equivale a aprobación.
- Detalle de tarjeta mediante modal profundo enlazable por URL; panel de contenido y sidebar de acciones; pestañas de actividad, horas y archivos. Evitar perder edición al cerrar; advertir cambios sin guardar.
- Comentarios con menciones autorizadas, reacciones representadas por iconos y etiquetas sin emojis, edición/borrado según regla, historial y sanitización. Adjuntos con nombre, peso, progreso, descarga segura, análisis y error. No incrustar HTML ejecutable.
- Checklist con progreso, reordenamiento, responsables y fechas opcionales; mover/completar no modifica aprobación automáticamente. Dependencias con alerta de bloqueo y validación de ciclos en API.
- Auditoría de tarjeta en timeline: actor, operación, fecha, antes/después cuando autorizado. No editable por UI. Notificar cambios de terceros y refrescar conflictos. Mostrar indicadores de presencia solo si se implementa realmente.
- Horas: timer visible en header y tarjeta, estimadas/reales aprobadas/pendientes diferenciadas, gráfico de distribución y registro manual con motivo. El reloj visual deriva de timestamps servidor, no es la fuente de verdad. Control de temporizador concurrente en backend.
- Plantillas, duplicar, mover entre tableros autorizados, archivo, restauración, reglas recurrentes y acciones masivas; confirmación para operaciones de impacto. Exportación mediante jobs de API.
- Virtualizar columnas/listas muy grandes con integración probada con drag; comenzar con paginación y render acotado. No virtualizar sin verificar drop target, enfoque y accesibilidad.

### 8.3 MIA Assistant — UX multimodal

Tres zonas en escritorio: conversaciones/búsqueda, chat principal y panel de contexto/voz/avatar. En móvil, paneles mediante tabs/sheets. MIA se presenta al saludar; selector General, Projects, Academy, Analytics, Commercial y Briefing, que restringe el alcance y no cambia la autorización. No enviar historial privado a otro usuario ni mostrar fuentes no permitidas.

Flujo: escribir o dictar → revisar texto → enviar → visualizar streaming → mostrar citas autorizadas/versiones → copiar, valorar, abrir fuente, detener o reintentar. Si no hay información, mostrar la respuesta de insuficiencia; si el tema es externo, mostrar rechazo. No inventar información cuando Azure falla. Propuestas de acciones muestran campos y cambios antes de confirmar; nunca ejecutar una escritura por mera sugerencia del modelo.

Avatar local: estados `idle`, `listening`, `thinking`, `speaking`, `error`; iluminación corporativa, parpadeo discreto, mouth animation por amplitud de audio si existe o indicador visual de habla (no prometer lip-sync exacto). Controles iniciar/detener voz, silenciar, cambiar voz permitida, velocidad, subtítulos, modo texto, movimiento reducido. No iniciar micrófono/cámara automáticamente.

Azure opcional: Speech SDK con autorización efímera del backend y configuración de región, WebRTC y credenciales ICE temporales cuando corresponda. Botón Activar avatar, indicador de sesión y cierre por inactividad, al salir o cambiar pestaña según política. `SpeechRecognizer`, sintetizador y PeerConnection se liberan al desmontar; detener MediaStream tracks. Capturar voz solo tras consentimiento. No guardar audio por defecto. Fallback a texto o avatar local si no hay región, acceso o presupuesto. Mostrar que una función cloud está desactivada sin venderla como operativa.

### 8.4 MIA Academy — experiencia de formación profesional

- Home con continuar aprendizaje, rutas por especialidad, progreso, cursos asignados y próximos eventos. Catálogo con filtros por nivel, tecnología, duración y estado.
- Ruta con módulos/lecciones, progreso y prerrequisitos; player de video o contenido Markdown, notas privadas, recursos, favoritos, transcripción y acceso a MIA Tech Coach contextual.
- Laboratorios: Monaco con código de ejemplo, copiar/descargar instrucciones, entrega de repositorio o archivo; no ejecutar código de usuario en el navegador principal ni servidor sin sandbox. Mostrar resultados de evaluación reales.
- Evaluaciones: preguntas y tipos permitidos, timer si se requiere, guardado de borrador, envío y retroalimentación; no incluir claves de respuesta en payload previo a evaluación.
- Mentorías, foro, ticket técnico, historial y certificados internos con verificación de cumplimiento por backend. Insignias con iconos Lucide/SVG, no emojis. No usar diplomas comerciales de proveedores sin autorización.
- Editor autorizado: cursos en borrador, estructura drag & drop, lecciones Tiptap, adjuntos, versiones, vista previa, aprobación/publicación y archivo. MIA solo consulta contenido publicado y permitido.

### 8.5 Conocimiento, AI Analytics y comercial

Knowledge: biblioteca con etiquetas, colecciones, búsqueda y clasificación; documentos con versiones, metadatos, dueño y ACL. Wizard de carga con avance real, validación, revisión, publicación y estado `indexing/ready/failed/withdrawn`; vista PDF privada, historial, reindexación autorizada. Diferenciar publicado en biblioteca de disponible para MIA. Mostrar retirado/fallo, no asumir que subir PDF lo indexa.

Analytics: filtros por origen demo/operativo, período, proyecto, equipo y estado; definición de indicadores; gráficos y drill-down con permisos. Laboratorio con las siete variables de entrada (`Proyecto`, `Especialidad`, `Tipo_tarea`, `Complejidad`, `Prioridad`, `Dependencias`, `Horas_estimadas`), validar categorías del modelo, mostrar `Retraso` y `Horas_reales` solo si el endpoint devuelve resultado verificable. Versión, timestamp, escenario y probabilidad si realmente se entrega. No mostrar una cifra inventada ni modificar tareas automáticamente. Exportación CSV/XLSX/PDF mediante jobs de Nest, progreso y enlace temporal.

Comercial: ficha de servicio, planes comparables, características, límites, condiciones, moneda, vigencia, impuestos según información aprobada y versiones. Formularios de edición con aprobación. Previsualizar portal público y cotización snapshot. Si no existe tarifa vigente, mostrar “Precio por confirmar” o respuesta de insuficiencia. No contratar un procesador de pagos para el MVP.

## 9. Estado, formularios y realtime

- React local para interacción simple; Context para proveedores estables; Zustand para preferencias temporales, paneles y estado de UI (no contraseñas ni tokens); TanStack Query para entidades remotas. Persistir preferencias no sensibles por usuario y limpiar al cerrar sesión.
- Zod valida UX y parseo de valores; Nest revalida siempre. RHF con mensajes junto al campo, error global, disabled durante envío y protección contra doble clic. Importación CSV local solo previsualiza.
- Mutación optimista: snapshot → patch UI → request con versión → respuesta canónica → invalidar; rollback y diálogo en 409. No optimismo para permisos, aprobación de horas, publicación de documentos o ejecución de IA.
- Realtime desde Nest SSE same-origin: recibir invalidaciones por ámbito y versión; actualizar cache o solicitar datos. Al reconectar, recargar consultas activas. No distribuir payload de tarjeta a toda la organización. Alternativa de polling adaptativo mientras la pantalla esté visible.
- Acciones masivas con selección persistida por filtro y confirmación. Evitar que seleccionar página se confunda con seleccionar todos los registros.

## 10. Rendimiento, accesibilidad y seguridad

- Objetivos de diseño: WCAG 2.2 AA, navegación completa por teclado, foco visible, `aria-live` moderado, captions, formularios etiquetados, alternativas de drag, estado con texto y no solo color. Probar axe y manualmente.
- Objetivos medibles de carga: LCP ≤ 2.5 s, INP ≤ 200 ms, CLS ≤ 0.1 como metas de laboratorio/campo; no garantías. Separar latencia de IA. Medir bundle por ruta, no cargar Monaco/Three/PDF/Speech en dashboard inicial.
- `next/dynamic` para editor, charts complejos, avatar y PDF viewer; SSR desactivado solo cuando el módulo necesita navegador. Optimizar imágenes, assets locales, fuentes, virtualización y paginación.
- CSP ajustada a orígenes requeridos, no `dangerouslySetInnerHTML` sin sanitización, Markdown sin HTML raw, links externos seguros, URLs de archivos firmadas. Limitar dependencias y revisar auditorías. No `NEXT_PUBLIC_` para claves privadas, Azure, DB o service role.
- Usar HTTPS en despliegue y cookies de sesión siguiendo guía Supabase SSR. No guardar access/refresh tokens manualmente en localStorage; usar mecanismo del proveedor y limitar exposición. Evitar caching de páginas privadas por CDN. No registrar conversaciones ni datos personales en analytics de terceros.
- Offline: mostrar estado, conservar borradores no sensibles si se aprueba y reintentar manualmente; no simular escritura sincronizada sin respuesta real. No cachear archivos/documentos privados en service worker.

## 11. Pruebas y calidad

| Herramienta | Uso |
|---|---|
| Vitest + Testing Library + `user-event` | componentes, estados, formularios, lógica UI |
| MSW | mocks de contrato durante desarrollo/pruebas, claramente separados de producción |
| Playwright | E2E login, roles, Kanban, aprobación, chat, documentos, responsive |
| `@axe-core/playwright` | accesibilidad automatizada |
| Storybook (local, opcional) | catálogo de componentes, variantes y regresión visual local |
| ESLint, Prettier, TypeScript | análisis estático y consistencia |
| Lighthouse / DevTools | rendimiento, accesibilidad y perfilado de animaciones |

Casos mínimos: usuario no invitado, acceso prohibido, cambio de rol, arrastre persistido, conflicto 409, timer único, adjunto fallido, publicación de guía, retiro de fuente, rechazo de pregunta ajena, proyecto futuro desconocido, chat cancelado, avatar no disponible, exportación sin permiso, móvil y reduced motion. Testear respuestas con datos de prueba separados, no consumir Azure en cada CI; pruebas reales de integración deliberadas y con límite.

## 12. Configuración y arranque (guía propuesta)

Crear monorepo, configurar Node/pnpm, generar Next App Router y Nest, importar tokens y cliente OpenAPI. Comandos de referencia para ejecutar dentro de `apps/web` una vez creado:

```bash
pnpm add motion lucide-react next-themes sonner cmdk
pnpm add @tanstack/react-query @tanstack/react-table @tanstack/react-virtual
pnpm add zustand react-hook-form zod @hookform/resolvers
pnpm add @supabase/supabase-js @supabase/ssr openapi-fetch
pnpm add recharts date-fns @date-fns/tz
pnpm dlx shadcn@latest init
pnpm add -D openapi-typescript vitest @testing-library/react @testing-library/user-event
pnpm add -D @playwright/test @axe-core/playwright
```

Los comandos son orientativos, no se han ejecutado ni se ha validado un lockfile; resolver versiones compatibles, fijarlas y revisar componentes antes de confirmar. Añadir dnd-kit, calendario, Tiptap, Monaco, voz y avatar cuando corresponda. No instalar todo para el primer commit.

`.env.example` web:

```dotenv
NEXT_PUBLIC_SUPABASE_URL=
NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY=
NEST_API_URL=http://localhost:4000/api/v1
NEXT_PUBLIC_APP_NAME=MTA Nexus
NEXT_PUBLIC_ENABLE_LOCAL_AVATAR=true
```

La clave publishable de Supabase no es un secreto de administrador; seguridad depende de políticas. Los flags públicos son solo UX. Las capacidades reales vienen de `/capabilities` en Nest. No declarar `AZURE_*`, `DATABASE_URL` ni claves service role en web. Configurar SSR Auth y callback con URLs permitidas.

## 13. Operación sin pagar hosting adicional

Desarrollo y sustentación: Next en localhost:3000, Nest en localhost:4000, Supabase local con CLI y motor de contenedores compatible, o Supabase Free hospedado. Usar Podman/Docker Engine o Docker Desktop únicamente bajo sus condiciones de licencia aplicables. No es necesario contratar Vercel, Render, Railway, Figma Pro, Storybook Cloud ni un dominio nuevo.

Para mostrar desde otra máquina, primero usar una red de prueba controlada; para publicar datos empresariales se requiere HTTPS, revisión de seguridad y alojamiento autorizado. Vercel Hobby es de uso personal/no comercial; no asumir que cubre una aplicación de empresa. Un servidor propio existente puede ser opción si la empresa autoriza recursos; no es un servicio gratuito garantizado. Azure puede alojar componentes pero consumir crédito: mantener cómputo local por defecto. Los free tiers pueden suspenderse o cambiar.

## 14. Plan de implementación frontend

1. Fundamentos: tokens, AppShell, login, guards visuales, cliente API, mocks de tests, estados globales.
2. Operación: dashboard, proyectos, Kanban, tarjeta, horas, importación demo, auditoría, notificaciones.
3. IA principal: conectar MIA real, streaming, historial y fuentes; conocimiento y actualización verificable.
4. Colaboración y formación: Academy, soporte, calendario, reportes y perfiles completos.
5. Diferenciación: avatar local, voz, briefing, animaciones avanzadas, predicciones reales cuando disponibles.
6. Administración, servicios y portal opcional; refinamiento de accesibilidad, rendimiento y pruebas.

Criterio de terminado: responsive, interacción accesible, estados completos, datos persistidos, autorización en Nest, pruebas de flujo, no emojis, animación medida, documentación y demo reproducible. Las integraciones cloud son “disponibles” solo después de verificar una ejecución real.

## 15. Referencias oficiales y condiciones verificadas

- Next.js App Router e instalación: https://nextjs.org/docs/app/getting-started/installation
- Despliegue Next.js: https://nextjs.org/docs/app/getting-started/deploying
- Tailwind: https://tailwindcss.com/docs — shadcn: https://ui.shadcn.com/docs
- Motion: https://motion.dev/docs/react — GSAP: https://gsap.com/docs/v3/
- TanStack: https://tanstack.com/ — dnd-kit: https://dndkit.com/
- FullCalendar estándar y licencia: https://fullcalendar.io/license
- Tiptap: https://tiptap.dev/docs — React Three Fiber: https://r3f.docs.pmnd.rs/
- Supabase Free: https://supabase.com/pricing — SSR: https://supabase.com/docs/guides/auth/server-side
- Azure Speech: https://azure.microsoft.com/en-us/pricing/details/speech/
- Avatar WebRTC: https://learn.microsoft.com/en-us/azure/ai-services/speech-service/text-to-speech-avatar/real-time-synthesis-avatar
- Vercel Hobby: https://vercel.com/docs/plans/hobby

Se verificaron las referencias de instalación de Next, límites de Supabase, restricciones de Vercel Hobby y documentación de Azure Speech. El resto son referencias técnicas de implementación; revisar versiones/licencias de cada paquete al instalar. No se ha desplegado ni probado aún la aplicación. Las decisiones de diseño y stack se proponen para el alcance completo de MTA Nexus; los permisos empresariales y condiciones reales de Azure requieren validación.
