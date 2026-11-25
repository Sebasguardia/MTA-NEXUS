# MTA NEXUS
## Especificación funcional, UX y arquitectura de software
**Producto:** plataforma empresarial de gestión de proyectos, aprendizaje y conocimiento con MIA Assistant.

**Versión:** 1.0 · Propuesta de diseño y desarrollo · 24 de noviembre de 2026

**Identidad:** MTA Software | MIA — MTA Intelligent Assistant

**Propósito del documento:** servir como fuente de verdad para diseñar las pantallas, implementar el frontend y backend, definir la base de datos, preparar el backlog y verificar el producto. No es un manual de un sistema ya implementado.

La plataforma integra gestión operativa, colaboración, capacitación, catálogo comercial, consulta documental y analítica predictiva. El chatbot existente en Microsoft Foundry se convierte en un asistente transversal, con voz y avatar opcionales, que consulta fuentes autorizadas y acompaña al usuario dentro de su espacio de trabajo.

**Principios:** datos confiables, permisos por alcance, trazabilidad de cada cambio, diseño corporativo consistente, accesibilidad, automatización controlada y experiencia interactiva.

**Entorno académico:** los archivos de proyectos y el dataset de tareas son el punto de partida; las funcionalidades y políticas de este documento son propuestas, no políticas corporativas aprobadas. El sistema debe distinguir datos de demostración y datos reales.

---
# 01. Índice y mapa de la especificación
| Capítulo | Contenido |
|---|---|
| 02–04 | Visión, identidad visual, estructura y navegación |
| 05–06 | Acceso, roles, permisos y seguridad por alcance |
| 07–08 | Dashboard y gestión del portafolio |
| 09–13 | Tablero Kanban, tarjetas, colaboración, horas y automatizaciones |
| 14–15 | Mis tareas, calendario, bloqueos y solicitudes |
| 16–18 | MIA Assistant, voz, avatar y herramientas inteligentes |
| 19–21 | MIA Academy, evaluaciones, soporte técnico y conocimiento |
| 22–23 | AI Analytics, predicciones y reportes |
| 24–25 | Servicios, planes y portal comercial opcional |
| 26–28 | Equipo, notificaciones, perfil y preferencias |
| 29–30 | Administración, superadministración y auditoría |
| 31–33 | Arquitectura, datos, API e integraciones |
| 34–36 | Requisitos no funcionales, pruebas, fases y referencias |

## Lectura y convenciones
- MVP: alcance prioritario para la entrega académica. A: ampliación; E: evolución empresarial. Los capítulos describen el producto objetivo completo, no un compromiso de que todas las funciones estarán disponibles en la primera entrega.
- Ruta: identificador propuesto de la pantalla. Los permisos se comprueban por operación y recurso; las rutas no son mecanismos de autorización.
- Las pantallas incluyen propósito, composición visual, acciones, reglas y estados. Los nombres y comportamientos se pueden refinar durante el diseño sin cambiar el objetivo.
- Las funciones de IA, servicios cloud, conexiones de terceros y precios requieren configuración real, permisos y validación; no deben simularse como si estuvieran activos.

---
# 02. Visión, contexto y alcance
## Problema y objetivo
MTA Nexus busca reducir la dispersión de información entre tableros, archivos, conversaciones y registros; mejorar la coordinación de practicantes; conservar conocimiento técnico; y apoyar decisiones mediante indicadores y predicciones. Su objetivo es que cada persona encuentre, ejecute y documente su trabajo desde un mismo espacio, sin reemplazar sistemas corporativos que ya cumplen esa función.

## Usuarios y propuesta de valor
- Practicante: comprende su trabajo, registra progreso y horas, aprende y resuelve incidencias con fuentes aprobadas.
- Líder: organiza un proyecto o equipo, distribuye trabajo, revisa entregables y eleva bloqueos. Sigue siendo practicante.
- Supervisor: controla la cartera autorizada, valida entregables, revisa capacidad, aprobaciones y resultados.
- Administrador: gestiona usuarios, catálogos, permisos delegados y configuración funcional.
- Superadministrador: administra infraestructura y seguridad de la plataforma, sin adquirir por defecto acceso al contenido privado ni poder alterar la operación.

## Alcance inicial y datos existentes
Los cinco proyectos documentados son la web corporativa de MTA Software, Strato Studio, Katrina's Imports, ROSVER y ERP MTA Software. El dataset académico contiene 500 tareas, 9 practicantes, 7 grupos de proyecto/especialidad, 470 finalizadas, 30 pendientes y 163 finalizadas con retraso. No confundir los 7 grupos con 7 proyectos independientes. Los modelos usan 470 filas cada uno; sus objetivos son Retraso y Horas_reales. El archivo no acredita un estado empresarial actual ni resultados de predicciones.

## Límites y decisiones
- ERP: Nexus prioriza colaboración y conocimiento; no replica inventario, facturación, nómina o asistencia del ERP. Integraciones futuras mediante contratos API autorizados.
- Catálogo: servicios y precios serán mantenidos por responsables autorizados. No se crean tarifas reales ni políticas de venta sin aprobación.
- Se propone área interna autenticada y portal comercial público opcional, separado de la información privada.

---
# 03. Sistema de diseño y experiencia visual
## Identidad de marca
Paleta proporcionada por MTA Software: azul profundo #0A1A3A (navegación y texto), azul principal #0066FF (acción primaria), azul claro #00A1FF (acento), azul suave #66C2FF (ilustración y foco), gris claro #F2F6FA (fondo). Gradiente principal #0066FF a #00A1FF; símbolo #0A1A3A a #0066FF a #66C2FF. Mantener logotipo oficial y área de respeto. Usar blanco para superficies y contrastes verificados para textos y botones.

## Composición
Inter o tipografía sans serif equivalente; escala 12/14/16/20/24/32 px; espaciado múltiplo de 4/8 px; tarjetas con radios 12–16 px, bordes sutiles, sombras bajas; iconos Lucide coherentes. Modo claro por defecto y oscuro opcional con tokens específicos. No saturar de gradientes: reservarlos para acentos, hero de bienvenida y MIA.

## Interacción y movimiento
- Entrada por vista: opacidad y traslación 8–12 px, 160–240 ms; gráficas animadas al entrar y al filtrar, sin alterar la escala.
- Sidebar colapsable; tarjetas que elevan sutilmente al pasar el cursor; transiciones de paneles y modales; drag & drop con sombra, destino visible y confirmación accesible.
- Skeletons con tamaño reservado, estados vacíos con acción principal, feedback de éxito/error, y opción deshacer cuando sea posible.
- Respetar prefers-reduced-motion; no bloquear el scroll ni usar movimientos intensos para funciones esenciales. Control por teclado, foco visible y contraste WCAG AA como meta.

## Responsive y componentes
Desktop: navegación 240 px, contenido flexible y panel auxiliar de 320–420 px; tablet: sidebar compacta y paneles superpuestos; móvil: drawer, tarjetas apiladas, tablero horizontal y modales a pantalla completa. Componentes reutilizables: breadcrumbs, filtros, tabla, gráfico, avatar, modal, formulario, buscador, etiquetas, selector de fechas, notificación, estado vacío y MIA dock.

---
# 04. Navegación global y estructura de vistas
| Menú principal | Ruta propuesta y submenús |
|---|---|
| Inicio | /dashboard · resumen, actividad, alertas |
| Proyectos | /projects · portafolio, archivados, plantillas |
| Mis tareas | /tasks · bandeja, lista, tablero, calendario |
| Horas y reportes | /time · temporizador, partes, aprobaciones |
| Calendario | /calendar · entregas, reuniones, cursos |
| Bloqueos y soporte | /support · incidencias, solicitudes, SLA |
| MIA Assistant | /mia · chat, voz, avatar, historial |
| MIA Academy | /academy · rutas, cursos, prácticas, evaluaciones |
| Conocimiento | /knowledge · biblioteca, versiones, aprobación |
| AI Analytics | /analytics · indicadores, modelos, exportación |
| Servicios y planes | /services · catálogo, planes, cotizaciones |
| Equipo | /team · directorio, capacidad, invitaciones |
| Administración | /admin · permisos, catálogos, configuración |
| Superadmin | /system · seguridad, integraciones, auditoría |

## Encabezado y navegación secundaria
Logo, breadcrumb, búsqueda global (Ctrl+K), botón Crear, acceso a MIA, reloj activo, campana con contador y menú de usuario. Crear abre opciones autorizadas: proyecto, tarjeta, parte de horas, documento, incidencia o curso. Búsqueda respeta permisos y muestra resultados por tipo; filtros y últimos elementos, sin exponer metadatos restringidos. El menú de usuario contiene Mi perfil, Preferencias, Seguridad, Ayuda y Cerrar sesión.

## Acceso público opcional
/ (página comercial), /servicios, /planes, /contacto, /login. La web corporativa existente puede seguir siendo el canal principal y enlazar al portal. No publicar datos de practicantes, tareas ni documentos internos. La navegación privada se adapta por rol; denegar rutas no permitidas con pantalla 403 y retorno seguro.

---
# 05. Autenticación y experiencia de acceso
**Rutas:** /login, /invite, /forgot-password, /reset-password, /onboarding, /session-expired.

## Diseño y acciones
Pantalla de login dividida: panel de marca azul profundo con gradiente y una ilustración discreta de MIA; panel claro con logo, correo corporativo, contraseña, mostrar/ocultar, recordar sesión según política, recuperar acceso y botón Iniciar sesión. Microsoft Entra SSO opcional, si el tenant lo permite. No permitir registro libre para roles internos: ingreso mediante invitación autorizada.

## Flujo funcional
1. Un administrador invita mediante correo, define equipo, rol base y fecha de expiración. El enlace es de un solo uso; reenviar invalida el anterior.
2. Usuario acepta, establece contraseña o usa SSO, confirma correo y completa perfil mínimo (nombre, especialidad, zona horaria y preferencias).
3. Backend valida estado de cuenta, membresías y políticas; si hay MFA obligatorio, solicita segundo factor. Redirige al dashboard correspondiente.
4. En recuperación se muestra una respuesta genérica, evitando revelar si una cuenta existe. Cambio de contraseña revoca sesiones según política.
5. Cierre de sesión elimina sesión local y revoca token cuando aplique; cambio de rol o suspensión se hace efectivo en nuevas solicitudes y se cierran sesiones si corresponde.

## Estados y reglas
Error de credenciales sin revelar detalles; invitación vencida; cuenta desactivada; sesión expirada con reautenticación; bloqueo temporal ante intentos repetidos. MFA obligatorio propuesto para administradores y superadministradores. No almacenar contraseñas en frontend, logs o base de datos propia si se usa un proveedor de autenticación. Sesiones mediante cookies seguras o mecanismo recomendado por el proveedor, HTTPS y protección CSRF donde aplique.

## Criterio de aceptación
Una persona sin invitación no accede al workspace. Un usuario suspendido pierde acceso aunque conserve una URL o sesión anterior. Un practicante que manipula una ruta de administración recibe denegación del servidor.

---
# 06. Roles, membresías y matriz de acceso
**Modelo:** permisos explícitos + pertenencia a organización/proyecto/equipo + clasificación del recurso. Líder es una responsabilidad asignada por proyecto a un practicante, no un privilegio global. Una persona puede liderar A y ser miembro de B.

| Acción | Practicante | Líder | Supervisor | Admin | Superadmin |
|---|---|---|---|---|---|
| Leer proyectos | Asignados | Su equipo | Su cartera | Delegado | No por defecto |
| Crear proyecto | Solicita | Solicita | Sí, cartera | Delegado | No |
| Configurar tablero | No | Su proyecto | Su cartera | Delegado | No |
| Asignar tarjetas | No* | Su equipo | Su cartera | No* | No |
| Editar tarjeta | Propia* | Su equipo* | Su cartera* | No* | No |
| Registrar horas | Propias | Propias | Propias | Propias* | No* |
| Aprobar horas/cierre | No | Revisión* | Sí | No* | No |
| Consultar MIA | Alcance | Alcance | Alcance | Alcance | Solo diagnóstico* |
| Gestionar cursos | No | Proponer | Aprobar* | Editor* | No |
| Publicar conocimiento | No | Proponer | Aprobar* | Editor* | No |
| Editar catálogo comercial | No | No | Lectura* | Comercial* | No |
| Gestionar usuarios/roles | No | Solicita | Solicita | Delegado | Admin global* |
| Seguridad e integraciones | No | No | No | Delegado | Sí |

*Con permiso específico; no implícito. Puede existir rol adicional de editor, comercial o auditor sin asignar superadmin. Invitado externo opcional: acceso a un proyecto y solo a tarjetas compartidas; fuera del MVP.

## Reglas críticas
- Denegar por defecto. RLS y autorización backend para lectura, escritura, búsqueda, exportación, adjuntos y consultas de MIA. No basta con el menú oculto.
- No autoasignarse privilegios ni autoaprobar horas o documentos propios. Delegaciones con caducidad y registro.
- Acceso excepcional del superadmin a contenido privado solo con justificación, alcance temporal, registro, aprobación si la política lo exige y revisión posterior.

---
# 07. Dashboard inteligente e interactivo
**Ruta:** /dashboard · personalización por rol y proyecto.

## Diseño visual
Encabezado con saludo, fecha local y selector de período/proyecto. Primera fila: KPI clicables de proyectos activos, tareas pendientes, bloqueos, tareas vencidas, horas registradas y cumplimiento. Segunda fila asimétrica: gráfica de avance por proyecto y MIA Briefing. Tercera: calendario próximo, actividad del equipo, capacidad y cursos pendientes. Cada widget admite ampliar, ocultar, reordenar y restablecer distribución personal.

## Interacciones y filtros
- Período, equipo, proyecto, responsable, etiqueta y estado; botón Limpiar; filtros persistentes en URL cuando no incluyan datos sensibles. Un clic en una barra abre el listado correspondiente; tooltip con valor y denominador.
- KPI con comparación contra período anterior equivalente; no mostrar porcentajes cuando el denominador es cero. Diferenciar tareas vencidas abiertas de tareas finalizadas con retraso.
- Widget de capacidad por persona, agenda semanal, tareas prioritarias, accesos rápidos y temporizador activo. MIA puede resumir solo el resultado filtrado y mostrar las fuentes.
- Realtime tras cambios autorizados; invalidar consultas y actualizar métricas derivadas. Mostrar última actualización, origen y estado de conexión.

## Personalización por rol
Practicante: mis tareas, horas, progreso de formación y bloqueos propios. Líder: carga del equipo, avance del tablero, revisión y dependencias. Supervisor: cartera, entregas, cumplimiento, horas aprobadas y riesgos. Admin: operación de plataforma, documentos pendientes, invitaciones y catálogo. Superadmin: salud de servicios, errores, cuotas, accesos y consumo, no ranking de personas.

## Animación y estados
Entrada escalonada discreta, contador animado solo al cargar, gráficos con transiciones, skeletons, estado sin actividad, error parcial por widget y reintento. Mantener filtros cuando falla un componente. Exportar snapshot del dashboard autorizado en PDF/CSV según widget.

---
# 08. Portafolio y ficha de proyectos
**Rutas:** /projects, /projects/new, /projects/[id]/overview.

## Vista de portafolio
Grid y tabla alternables; búsqueda, filtros por estado, líder, supervisor, equipo, especialidad, prioridad, cliente y fechas. Tarjetas con portada o iniciales, progreso, responsables, miembros, vencimiento, tareas abiertas, horas y alertas. Acciones: abrir, favorito, duplicar estructura, archivar/restaurar, exportar, solicitar nuevo proyecto. Progreso = tarjetas con estado semántico finalizado / tarjetas activas incluidas; si no hay tarjetas, mostrar sin datos.

## Creación y edición
Formulario por pasos: identidad (nombre, código único, descripción, cliente opcional), planificación (inicio, fin, prioridad, objetivos, alcance), equipo (supervisor, líder, miembros), tablero (plantilla, columnas, etiquetas, permisos), revisión. Validar fechas, responsables activos, duplicados y alcance. Proyecto inicia como borrador o activo por aprobación. Estados: borrador, activo, pausado, finalizado, archivado; finalización requiere revisión de pendientes y permisos. Archivar no elimina historial.

## Detalle del proyecto
Pestañas: Resumen, Tablero, Lista, Calendario, Cronograma, Archivos, Horas, Equipo, Actividad, Configuración. Resumen: objetivos, hitos, descripción, stack documentado, enlaces autorizados a repositorios y despliegues, KPIs, responsables, alertas y últimas actividades. Guardar enlaces sin tokens; proteger accesos externos. Permitir hitos, entregables, versiones, notas de sprint y acuerdos de reunión.

## Administración del proyecto
Invitar miembros, transferir liderazgo con aprobación, configurar visibilidad, campos personalizados, reglas, etiquetas, plantillas y límites de trabajo en curso. Cambiar fechas o responsables deja auditoría. Duplicación copia estructura y plantillas; no copia datos personales, adjuntos ni horas por defecto. Proyectos de demostración tienen distintivo persistente y se separan de los operativos.

---
# 09. Tablero Kanban tipo Trello
**Ruta:** /projects/[id]/board · espacio principal de trabajo.

## Estructura visual
Barra superior con nombre, favoritos, miembros, búsqueda, filtro, Agrupar, Cambiar vista, Automatizaciones y menú del tablero. Canvas horizontal con columnas independientes, contadores y botones Agregar tarjeta. Encabezado fijo de columna; tarjetas compactas con portada, título, etiquetas, avatares, prioridad, fecha, checklist, comentarios, adjuntos, horas y bloqueo. Panel lateral opcional con actividad y miembros. Móvil: scroll horizontal y selector de columna.

## Acciones de columnas
Crear, renombrar, recolorear, reordenar por arrastre, duplicar estructura, colapsar, ordenar tarjetas por fecha/prioridad/nombre, mover tarjetas en lote, archivar/restaurar. Definir límite WIP, políticas y categoría semántica (pendiente, en curso, revisión, finalizada). No se elimina una columna con tarjetas sin moverlas o archivarlas explícitamente. Mantener al menos una columna de entrada y una final, con permisos. Plantilla inicial: Backlog, Por hacer, En progreso, En revisión, Finalizado. Bloqueado es una marca transversal, no necesariamente una columna.

## Acciones rápidas de tarjeta
Crear inline, editar título, cambiar portada, etiquetas, prioridad, fecha, asignados, mover, copiar, seguir, archivar, restaurar, compartir enlace interno y abrir detalle. Selección múltiple para operaciones autorizadas con previsualización. Tarjetas nuevas poseen ID humano (p. ej. MTA-042) y UUID interno; plantillas permiten checklist y campos por defecto.

## Movimiento y colaboración simultánea
Drag & drop entre columnas y dentro de ellas, con alternativa por teclado y menú Mover. Persistir orden, columna, versión y evento de auditoría en transacción. Actualización optimista con rollback si el servidor rechaza el cambio; conflictos muestran estado más reciente y permiten reintentar. Suscripciones por proyecto para sincronizar movimientos, nunca canales globales sin filtrado. Respetar WIP, transición permitida y validaciones de cierre.

---
# 10. Tarjeta: información, acciones y ciclo de vida
**Ruta:** /projects/[id]/cards/[cardId] · modal profundo o vista completa con URL compartible.

## Diseño de detalle
Cabecera: ID, título editable, columna, estado, proyecto, prioridad y menú. Cuerpo de dos columnas: descripción y trabajo a la izquierda, propiedades y acciones a la derecha. Tabs inferiores: Actividad, Comentarios, Archivos, Horas, Dependencias. En móvil, propiedades en acordeón. Indicador de cambios pendientes y autosave de borrador; botón guardar para cambios sensibles.

## Propiedades y contenido
Título requerido, descripción Markdown o editor enriquecido sanitizado, criterios de aceptación, tipo (feature, bug, investigación, documentación, soporte), prioridad, complejidad, responsables múltiples, creador, fechas de inicio/vencimiento, estimación en horas, etiquetas personalizadas, sprint, módulo, especialidad, hitos y campos configurables (texto, número, fecha, selector, booleano). Validar tipos, permisos y fechas. Propietario principal opcional para evitar responsabilidades ambiguas.

## Acciones de productividad
- Checklist múltiple: crear desde plantilla, reordenar, copiar, asignar ítems, fechas, completar y desmarcar; convertir ítem a tarjeta vinculada; mostrar progreso calculado.
- Subtareas con relación padre/hijo, tarjetas relacionadas, enlaces de dependencia (bloquea/depende de) y detección de ciclos. La tarjeta bloqueada registra motivo, responsable y fecha de resolución.
- Adjuntar archivos, enlazar documento aprobado, repositorio/PR/issue, evidencia de entrega; portada de imagen, vista previa, descargar, versionar o retirar con permiso.
- Seguir/silenciar, copiar, mover, archivar/restaurar, cambiar responsable, editar campos y solicitar revisión. Compartir enlace no concede acceso.

## Flujo de cierre
Practicar: Por hacer → En progreso → En revisión. Líder revisa, solicita ajustes o recomienda aprobación. Supervisor o revisor delegado valida criterios y evidencia; cierre registra fecha real y responsable. Reabrir requiere motivo y conserva cierres anteriores. Política configurable: checklist obligatorio, dependencias resueltas y horas presentadas antes del cierre. No bloquear entrega por una regla no habilitada.

---
# 11. Tarjetas: colaboración, archivos y auditoría
## Comentarios y actividad
Editor con menciones @usuario autorizado, respuestas a hilos, reacciones, edición marcada, adjuntos y enlaces. Notificar menciones y seguidores según preferencias. Permitir anclar acuerdos, marcar resolución, filtrar actividad (comentarios, estado, horas, asignaciones). Los comentarios eliminados se muestran como retirados cuando la política lo requiere; conservar evidencia mínima y acceso auditado. Sanitizar HTML, limitar tamaños y prevenir XSS. No mencionar miembros sin acceso a la tarjeta.

## Adjuntos y evidencia
Carga drag & drop, selector múltiple, progreso/cancelación/reintento, tipos MIME y extensión permitidos, cuota por archivo/proyecto, análisis antimalware, almacenamiento privado, miniaturas de imágenes/PDF, URLs firmadas de corta duración. Estados: subiendo, cuarentena, disponible, rechazado, eliminado. Versiones con autor, tamaño, hash y fecha. La eliminación retira acceso; retención depende de política. No indexar automáticamente adjuntos de tarjetas en el conocimiento general de MIA.

## Auditoría por tarjeta
Cada cambio relevante registra evento, actor, momento UTC, tarjeta, origen (UI/API/automatización), acción, valores antes/después permitidos, motivo si aplica y correlación. Ejemplos: asignación, movimiento, cambio de fecha, checklist, comentario editado, archivo retirado, horas corregidas y reapertura. El historial es de solo lectura para usuarios autorizados; no se permite edición manual de eventos. No guardar contraseñas, tokens o contenido sensible innecesario. Exportar actividad con permisos; mostrar detalles de cambios en un diff legible.

## Concurrencia y recuperación
Edición simultánea: versión/ETag, aviso de conflicto y resolución por campo cuando sea seguro. Reacciones y comentarios son operaciones independientes. Borradores locales sin datos sensibles cuando la política lo permita. Restaurar tarjeta archivada vuelve a una columna válida; si ya no existe, solicitar destino. Papelera con retención configurable y purga administrativa auditada, nunca eliminación silenciosa.

---
# 12. Registro de horas, partes y capacidad
**Rutas:** /time, /time/timesheet, /time/approvals; pestaña Horas por tarjeta.

## Diseño y acciones
Reloj global con tarjeta activa, cronómetro iniciar/pausar/reanudar/detener, nota y estado. Registro manual: tarea, fecha, inicio/fin o duración, tipo de trabajo, descripción, evidencia opcional. Lista diaria/semanal con filtros por proyecto, usuario autorizado, estado y tipo. Resumen estimadas, registradas, aprobadas y diferencia. Detalle de tarjeta muestra suma por colaborador, sesiones, historial y gráfico estimadas vs. reales.

## Reglas de negocio
- Un temporizador activo por usuario; persistir inicio en servidor, recuperar tras recarga. Pausas no cuentan. No confiar en reloj del cliente. Ajustes de zona horaria America/Lima por defecto y almacenamiento UTC.
- Prevenir solapamiento de intervalos por usuario; registros manuales sin intervalo requieren política de validación. Duración positiva, límites configurables y control de duplicados. No registrar sobre tarea archivada/cerrada sin autorización de corrección.
- Estados: borrador → presentado → aprobado/rechazado → corregido (nueva versión). El líder puede revisar; supervisor autorizado aprueba; nadie autoaprueba. Rechazo incluye motivo y notificación. Horas aprobadas no se sobrescriben; reversión y nuevo registro con auditoría.
- Horas reales operativas = suma de sesiones aprobadas; mostrar por separado horas en revisión. Para datos importados históricos usar campo Horas_reales de origen, sin inventar sesiones ni sumarlo con nuevas sesiones de la misma tarjeta.

## Reportes
Parte semanal por practicante, horas por proyecto, tarjeta, especialidad y rango; variación = reales - estimadas; utilización = horas aprobadas / capacidad configurada, si existe. Exportar CSV/XLSX/PDF con filtros, zona horaria, fecha y fuente. No usar horas como medida única de productividad. Capacidad definida por disponibilidad laboral aprobada, no por vigilancia.

---
# 13. Automatizaciones, plantillas y vistas alternativas
**Rutas:** /projects/[id]/automations, /projects/[id]/templates.

## Automatización tipo reglas
Constructor visual Cuando → Si → Entonces. Disparadores: tarjeta creada, movida, fecha próxima, checklist completo, comentario de mención o parte aprobado. Condiciones: etiqueta, prioridad, columna, responsable, estado, fecha o proyecto. Acciones autorizadas: asignar etiqueta, mover a columna, avisar, crear checklist, programar recordatorio, generar tarjeta recurrente. Acciones sensibles (cerrar, reasignar fuera del equipo, publicar documentos) requieren revisión humana o permiso explícito según política.

Prueba de regla con datos de ejemplo, previsualización, activar/desactivar, editar versión, duplicar, historial de ejecuciones, errores y reintento. Evitar ciclos, ejecutar con identidad y alcance limitados, idempotencia por evento y cuota. Prohibir ejecución de código o SQL arbitrario desde el constructor. MVP: recordatorios y reglas simples; editor avanzado posterior.

## Plantillas
Crear plantillas de proyecto, tablero, tarjeta, checklist y campos; por ejemplo onboarding, bug, feature, documentación y QA. Versionar, compartir dentro de alcance, clonar sin copiar datos privados. Tarjetas recurrentes con frecuencia, zona horaria, fecha final y tratamiento de festivos configurable. No duplicar por reintento.

## Vistas alternativas
- Lista/tabla: columnas elegibles, agrupación, orden, edición rápida, filtros guardados, selección y exportación; no revelar campos ocultos por permiso.
- Calendario: inicio, vencimiento, hitos; mover fecha mediante drag solo con permiso y confirmación cuando afecta dependencia.
- Cronograma/Gantt: hitos, duración y dependencias; mostrar conflictos, no cambiar fechas automáticamente sin aprobación.
- Carga de trabajo: capacidad vs. horas planificadas por persona/semana, redistribución propuesta por líder; nunca reasignar silenciosamente.
- Vista de tablero personal: combina tarjetas asignadas de distintos proyectos, conservando reglas y contexto de cada tablero.

---
# 14. Mis tareas, agenda y centro de trabajo
**Rutas:** /tasks, /calendar, /calendar/[eventId].

## Mis tareas
Cabecera con selector Hoy, Próximas, Vencidas, En revisión, Sin fecha y Finalizadas. Lista o Kanban personal con agrupación por proyecto, fecha, prioridad y estado. Filtros guardados, búsqueda, favoritos, foco de trabajo y selección múltiple autorizada. Cada fila muestra título, código, proyecto, fecha, etiqueta, checklist, horas y estado. Acción Abrir tarjeta conduce al registro original: no se crea una copia del trabajo.

Modo enfoque: elegir una tarea, ver criterios de aceptación, comenzar temporizador y ocultar notificaciones no urgentes. Acceso rápido a guía técnica relacionada de Academy y a MIA contextual. El usuario puede solicitar extensión o reportar bloqueo, no cambiar plazos aprobados sin permiso. Acciones de actualización restringidas a su propia tarjeta y campos autorizados.

## Calendario y agenda
Vistas día/semana/mes/lista, colores por proyecto, filtros de entregas, reuniones, formación y recordatorios. Eventos: título, descripción, fechas, participantes, ubicación/enlace, visibilidad y recordatorio. Crear evento personal o de equipo según permiso, editar, cancelar, duplicar, confirmar asistencia y exportar ICS. Fechas de tarjeta derivan del registro original; actualizar desde calendario requiere autorización de la tarjeta.

## Integración opcional Microsoft
Sincronizar con Outlook Calendar mediante Microsoft Graph solo después de consentimiento y configuración de tenant. Definir origen y dirección de sincronización; usar ID externo, detectar cambios y evitar duplicados. Si no hay acceso, mantener calendario interno y exportación ICS. No conectar cuentas personales sin autorización.

## Estado y aceptación
Sin tareas: mensaje de bienvenida y acceso a solicitar trabajo o Academy. Vencimiento: tarjeta visible en rojo con texto, no solo color. Si un proyecto queda inaccesible, desaparecen sus eventos y tareas del usuario. Las notificaciones no deben filtrar detalles en calendarios externos no autorizados.

---
# 15. Bloqueos, incidencias y solicitudes
**Rutas:** /support, /support/new, /support/[id].

## Centro de ayuda interna
Pestañas Mis solicitudes, Equipo, Bloqueos, Base de soluciones y Métricas. Formulario: categoría (error técnico, acceso, infraestructura, dependencia, consulta, mejora), proyecto/tarjeta opcional, título, descripción, pasos para reproducir, esperado/obtenido, severidad, entorno, adjuntos sanitizados. Botón Consultar MIA ofrece buscar guías aprobadas antes de enviar, sin impedir crear ticket.

## Flujo
Nuevo → triage → asignado → en atención → esperando respuesta → resuelto → cerrado. Reapertura con motivo; vínculo a tarjeta, dependencias y responsable de soporte. SLA de atención definido por política y horario; no inventar tiempos. Alertas por vencimiento, escalamiento a líder/supervisor y recordatorio de seguimiento. Incidencia crítica permite destacar alerta sin revelar contenido fuera de alcance.

## Acciones y visualización
Tabla por estado/prioridad/responsable, panel de tickets, conversación en hilo, comentarios internos visibles solo al equipo autorizado, historial, evidencias, solución aplicada, causa raíz, etiquetas, vincular duplicados. Conversión a tarjeta crea relación, no duplica silenciosamente el trabajo. Reportes de tiempos de resolución, recurrencia y bloqueos abiertos; los indicadores excluyen casos sin fecha válida.

## Mejora continua
Una solución confirmada puede convertirse en borrador de artículo Academy/Conocimiento; eliminar datos sensibles, revisar técnicamente, aprobar y publicar antes de que MIA la use como fuente. El practicante puede valorar utilidad y solicitar corrección. Solicitudes de accesos o compra no ejecutan cambios por sí solas: requieren aprobador designado. Acceso solo a solicitante, equipo responsable y supervisores autorizados.

---
# 16. MIA Assistant: interfaz y experiencia conversacional
**Ruta:** /mia · MIA (MTA Intelligent Assistant), agente existente en Microsoft Foundry.

## Composición visual
Tres paneles en desktop: historial y conversaciones a la izquierda, chat central con bienvenida y sugerencias, avatar/contexto a la derecha; panel auxiliar plegable. Header con MIA, estado real de conexión, selector de modo (Consulta, Proyecto, Academy, Comercial, Analítica), nueva conversación y opciones. Inicio: saludo cordial, presentación y ejemplos según rol. En toda la plataforma, botón MIA abre un drawer contextual con proyecto/tarjeta visible; no envía contexto privado sin permiso.

## Funciones
- Mensajes de texto, entrada de voz opcional, respuesta streaming si la API lo permite, detener generación, reintentar, copiar, valorar, citar fuentes y ampliar extracto autorizado.
- Conversaciones con título, búsqueda, favoritos, renombrar, archivar/eliminar, exportar historial propio según política. Sesión nueva separa contexto; no mezclar identidades.
- Citas clicables a documentos/versiones o registros autorizados, fecha de consulta y origen. En respuestas estructuradas: tablas, indicadores y enlaces a tareas; los gráficos provienen de resultados reales de herramientas, no de números inventados.
- Adjuntar captura o archivo para consulta temporal solo si la modalidad y política lo permiten; escaneo y caducidad. Un adjunto no se convierte automáticamente en fuente oficial.
- Modo briefing: seleccionar proyecto, período y métricas; mostrar resumen narrado y enlaces. Modo Academy: explicar guías, ejercicios y errores documentados. Modo Comercial: planes publicados autorizados.

## Comportamiento obligatorio
Saluda como MIA, usa español por defecto, responde solo desde fuentes autorizadas y suficientes. Consulta fuera de contexto: «Lo siento, esa pregunta está fuera de mi contexto de conocimiento». Consulta interna sin datos: «No dispongo de información suficiente en mi base de conocimiento para responder esa consulta sobre MTA Software». No inventa futuros proyectos, precios, personas ni predicciones. Indica si el resultado es histórico, simulado o vigente; reconoce errores y límites.

---
# 17. MIA multimodal: voz, avatar y accesibilidad
## Experiencia propuesta
Avatar corporativo en panel lateral, con estados visuales: inactivo, escuchando, procesando, hablando, pausado y desconectado. Botones: activar avatar, micrófono, silenciar, detener voz, volumen, seleccionar voz autorizada, subtítulos y expandir. Una onda sonora indica captura real, no falsa actividad. La conversación por texto permanece utilizable siempre.

## Flujo de voz
1. Usuario pulsa micrófono y concede permiso del navegador; mostrar indicador de grabación, cancelar y detener. No escuchar en segundo plano.
2. Speech-to-text convierte audio a texto; usuario revisa transcripción y envía, o habilita envío automático explícito. El backend procesa el mismo flujo de autorización que el texto.
3. MIA devuelve respuesta fundada en fuentes; TTS lee el texto validado. Avatar sincroniza voz y labios si el servicio está disponible. Botón Interrumpir detiene reproducción y captura.
4. Subtítulos, control de velocidad si compatible, selección de voz en español y preferencia de lectura automática. No leer información sensible en voz alta por defecto.

## Implementación y alternativas
Azure Speech para reconocimiento y síntesis; avatar oficial en tiempo real mediante WebRTC si la región, red, cuota y suscripción lo permiten. Credenciales persistentes solo en servidor; token/credencial efímera al navegador según mecanismo soportado. Si falla avatar o WebRTC, usar voz sin vídeo; si falla voz, usar texto. Alternativa: avatar 2D/3D propio con animación de habla, identificado como tal, sin afirmar sincronía fonética exacta. No contratar recursos ni generar costos sin autorización.

## Privacidad y costos
Activación manual, tiempo máximo por sesión, desconexión al salir/inactividad y cuotas por usuario. No almacenar audio/video por defecto; transcripciones sujetas a retención de chat. Informar qué se envía al proveedor. No clonar voces ni usar imagen real sin consentimiento. Revisar región y precios antes de habilitar funciones facturables.

---
# 18. MIA: herramientas, acciones y gobierno de IA
## Herramientas propuestas (solo datos autorizados)
- searchKnowledge(query, scope): documentos publicados y vigentes, con citas y versión.
- getProjects(filters), getTask(id), listTasks(filters): datos operativos actuales, limitados por identidad y membresía.
- getHours(filters), getMetrics(filters): agregados calculados por servidor con fecha y denominadores.
- getServicePlans(filters), getAcademyContent(topic): catálogo publicado y material formativo permitido.
- predictTask(input): endpoint ML autorizado, versión del modelo, resultado y advertencias. Solo si hay conexión validada.

## Acciones asistidas (ampliación)
MIA puede proponer crear tarjeta, checklist, borrador de guía, resumen de reunión o ticket. La respuesta muestra formulario de revisión, destino, campos y responsable. El usuario confirma, backend vuelve a verificar permisos y ejecuta acción idempotente; audita actor humano y origen IA. No realizar modificaciones a escondidas ni delegar decisiones de contratación, evaluación disciplinaria o publicación comercial al modelo. MVP: herramientas de solo lectura.

## Separación de conocimiento y permisos
Consultar documentos con filtros de organización/proyecto/audiencia antes de entregar fragmentos al modelo. Si el agente de Foundry tiene File Search con índice compartido sin aislamiento verificable, usarlo solo para documentos comunes a todos los usuarios autorizados; fuentes restringidas pasan por herramienta de búsqueda controlada o almacenes aislados. No confiar en instrucciones del prompt para impedir fugas. Revalidar citas y archivos al abrirlos. No habilitar búsqueda web libre.

## Flujos y fallos
Autenticar → resolver ámbito → seleccionar herramienta → recuperar evidencia → generar respuesta → comprobar referencias y devolver. Si fuente está caída, no sustituirla con conocimiento general. Diferenciar sin coincidencias, permiso insuficiente y servicio indisponible sin revelar existencia de recursos ajenos. Limitar resultados, tiempos, tokens, llamadas y reintentos. Registrar métricas y errores sin guardar secretos ni prompts privados innecesarios. Evaluar inyección de instrucciones en documentos y mensajes.

---
# 19. MIA Academy: plataforma de aprendizaje interno
**Rutas:** /academy, /academy/paths, /academy/courses/[id], /academy/learn/[lessonId].

## Inicio y biblioteca
Hero «Tu siguiente paso profesional», progreso semanal, continuar curso, rutas recomendadas, actividades próximas, guías recientes, buscador y filtros por rol, nivel, tecnología, duración, proyecto y formato. Tarjetas de curso con portada, descripción, módulos, dificultad, instructor/autor, tiempo estimado, requisitos, versión y progreso. Favoritos, historial y lista de aprendizaje. Recomendaciones basadas en cursos asignados o intereses elegidos, no en evaluación opaca del practicante.

## Rutas formativas propuestas
Onboarding MTA (procesos, Git, seguridad, comunicación); Frontend (HTML/CSS, React, TypeScript, pruebas); Backend (API, Node, SQL, seguridad); Azure e IA (Foundry, ML, datos responsables); QA y DevOps (testing, CI/CD); gestión ágil (Scrum, Kanban, documentación); especialización por proyecto. Cada ruta incluye objetivos, prerrequisitos, secuencia de cursos, actividades y criterios de finalización. Son propuestas de contenido a crear y aprobar, no cursos ya disponibles.

## Experiencia de lección
Player con video autorizado o texto, índice lateral, bloques de código copiables, diagramas, recursos descargables, notas personales, marcadores, subtítulos y navegación anterior/siguiente. Botón Preguntar a MIA envía contexto de la lección aprobada. Lecciones prácticas con instrucciones, casos, archivos de ejemplo, checklist y evidencia. Guardar avance por lección, retomar desde último punto y permitir repetición.

## Gestión editorial
Editor autorizado crea cursos, módulos, lecciones, recursos, objetivos, duración, idioma, nivel, audiencia, orden y portada. Borrador → revisión técnica → publicado → archivado. Vista previa como alumno, versiones, autor y fecha de revisión. Publicación actualiza búsqueda solo tras indexación; el material retirado deja de usarse en nuevas respuestas. Cursos asignados conservan versión para trazabilidad.

---
# 20. Academy: evaluaciones, mentoría y soporte técnico
**Rutas:** /academy/assessments, /academy/progress, /academy/mentors, /academy/admin.

## Evaluaciones y laboratorios
Cuestionarios de selección única/múltiple, verdadero/falso, preguntas abiertas y casos prácticos. Banco de preguntas versionado, intentos, límite de tiempo opcional, nota mínima y retroalimentación configurable. Calificación automática solo para respuestas deterministas; ejercicios de código o entregables con rúbrica y revisión humana. No ejecutar código no confiable en el servidor principal: sandbox aislado y límites, o entrega manual en MVP. Guardar intentos y reglas de versión. Mostrar revisión según política; no exponer respuestas antes de entregar.

## Progreso y certificación interna
Panel del practicante: avance por ruta, horas formativas declaradas, evaluaciones, logros y pendientes. Avance = lecciones requeridas completadas / total requerido; aprobación exige criterios del curso. Constancia interna opcional con código verificable, fecha, curso y emisor; no afirmar acreditación oficial. Líder/supervisor ven progreso de asignados, no notas privadas. Exportar resumen de formación según permisos.

## Mentoría y aprendizaje social
Solicitar mentoría, agenda de sesiones, objetivos, preguntas, recursos y acuerdos. Mentor autorizado responde, revisa entregables y recomienda rutas. Foro por curso moderado, marcar respuesta útil, reportar contenido, mencionar participantes autorizados. Convertir solución recurrente en artículo revisado. Gamificación opcional con insignias por hitos, sin ranking público obligatorio.

## MIA Tech Coach
Búsqueda por mensaje de error, stack, código o proyecto. Mostrar guía aplicable, versión, pasos, prueba de solución y fuente. Si no hay artículo autorizado, sugerir ticket o consulta a mentor; no generar una solución inventada. Capturas y logs se sanitizan para remover credenciales, tokens y datos de clientes. La respuesta de MIA no constituye aprobación de cambios de producción. Feedback permite señalar documentación obsoleta y crear propuesta de actualización.

---
# 21. Centro de conocimiento y actualización de MIA
**Rutas:** /knowledge, /knowledge/new, /knowledge/[id], /knowledge/review, /knowledge/indexing.

## Biblioteca y detalle
Vista carpeta, grid o tabla; filtros tipo, proyecto, autor, audiencia, estado, vigencia, etiqueta y versión. Búsqueda textual/semántica autorizada. Tipos: manual, política, FAQ, guía, README, catálogo, acta, reporte. Detalle con visor, metadatos, versiones, historial, fuentes relacionadas, descarga, editar permisos, solicitar cambio y estado de indexación. No confundir documento visible con documento publicado para MIA.

## Carga y publicación
1. Subir PDF/Markdown/DOCX u otros formatos admitidos por el pipeline; validar MIME, tamaño, hash, malware y sensibilidad. Capturar título, descripción, fuente, propietario, audiencia, proyecto, fecha efectiva y expiración.
2. Crear versión en borrador; extraer texto y mostrar vista previa; documentos escaneados requieren OCR controlado o revisión manual. Detectar duplicados y cambios. Autor solicita revisión; aprobador independiente valida exactitud y clasificación.
3. Publicar activa trabajo asíncrono de indexación. Estado: pendiente, procesando, disponible, fallido, retirando. Reintento controlado, logs y prueba de recuperación. No mostrar «MIA actualizado» hasta verificar indexación y citas.
4. Reemplazar/retirar: nueva versión, actualizar índice, eliminar fragmentos antiguos del acceso activo, invalidar caché y verificar que no se recuperen. Si falla retirada, bloquear la versión por autorización y alertar. Historial privado se conserva según retención.

## Seguridad y vigencia
Almacenamiento privado; ACL por documento, fragmento, proyecto y audiencia. El cambio de permisos aplica también a búsquedas, citas e historial mostrado. Documentos vencidos pasan a revisión y no son fuentes vigentes salvo consulta histórica explícita. Definir jerarquía: registro operativo y catálogo publicado vigentes prevalecen sobre PDFs antiguos; ante conflicto, indicar diferencias y solicitar revisión. Los cinco PDF iniciales son fuente histórica/académica, no se reescriben automáticamente con cada tarea.

---
# 22. AI Analytics: métricas y visualización
**Rutas:** /analytics, /analytics/projects, /analytics/time, /analytics/quality.

## Diseño y herramientas
Encabezado con rango de fechas, comparación, selector de origen (demo/operativo), proyecto, equipo y especialidad. Pestañas: Resumen, Cumplimiento, Tiempo, Capacidad, Formación, Predicciones. KPIs, barras agrupadas, línea temporal, distribución de horas, matriz de bloqueos, tabla con drill-down y tooltip de fórmula. Guardar vistas, restablecer filtros, seleccionar columnas y exportar. Gráficos con alternativa tabular accesible, escalas claras y leyenda interactiva.

## Diccionario mínimo de indicadores
| Indicador | Cálculo y regla |
|---|---|
| Tareas completadas | Conteo de tarjetas finalizadas del alcance y período de cierre |
| Cumplimiento | Finalizadas sin retraso / finalizadas con fecha límite y cierre válidos |
| Retraso histórico | Cierre posterior a fecha límite vigente según política registrada |
| Vencidas abiertas | No finalizadas y límite anterior a momento de corte |
| Horas reales | Horas aprobadas operativas o valor histórico importado, sin doble conteo |
| Desviación | Horas reales - estimadas; % solo si estimación > 0 |
| Lead time | Tiempo desde creación hasta cierre; distinguir de horas trabajadas |
| Cycle time | Tiempo desde primer inicio hasta cierre; política de reapertura definida |
| Throughput | Tarjetas finalizadas por intervalo; contar cada cierre según política |
| Capacidad | Horas aprobadas / disponibilidad configurada del período |

## Reglas
Distinguir fecha de creación, vencimiento, cierre y horas. Si se comparan períodos usar misma duración y filtros. Datos incompletos excluidos con contador y explicación. Mantener zona horaria y timestamp de corte. En demo, 163/470 = proporción histórica de retraso entre finalizadas; no extrapolar a desempeño actual. MIA explica métricas calculadas por backend. No usar IA para puntuar personas o inferir capacidad individual a partir de datos simulados.

---
# 23. Laboratorio predictivo y exportación de reportes
**Rutas:** /analytics/predictions, /analytics/models, /reports.

## Simulación de tareas
Formulario con siete entradas de entrenamiento: Proyecto, Especialidad, Tipo_tarea, Complejidad, Prioridad, Dependencias, Horas_estimadas. Selecciones derivadas del esquema/versiones del modelo, no etiquetas inventadas. Puede precargarse desde tarjeta, con validación de categoría desconocida, rango y unidades. Botón Ejecutar predicción llama a endpoints autorizados: clasificación predice Retraso (Sí/No) y probabilidad si disponible; regresión predice Horas_reales. Mostrar modelo, versión, fecha, entrada, estado, advertencia y diferencia frente a estimación. No fabricar intervalos de confianza o probabilidades no entregadas.

## Modelos y validación
Datasets de entrenamiento: 470 filas cada uno, sin usar Horas_reales para predecir Retraso. Validar fuga de información, partición temporal cuando corresponda, distribución de clases y generalización. Clasificación: precision, recall, F1, matriz de confusión, ROC-AUC cuando disponible; regresión: MAE, RMSE y R². No mostrar métricas sin evidencia de ejecución. Guardar predicciones como escenarios separados de resultados reales, comparar posteriormente con cierre real y detectar deriva. No entrenar ni desplegar automáticamente desde el dashboard. Si endpoint está apagado, mostrar no disponible; cualquier simulación ilustrativa lleva etiqueta DEMO.

## Centro de reportes
Plantillas: informe de proyecto, tareas, partes de horas, cumplimiento, incidencias, Academy y predicciones. Elegir columnas, filtros, período, orden y formato CSV/XLSX/PDF. Vista previa, solicitud asíncrona para grandes volúmenes, estado, descarga temporal y cancelación. PDF con marca, título, fuente, autor, corte y filtros; XLSX con hojas de resumen/detalle, CSV UTF-8. Neutralizar fórmulas maliciosas en exportación. Aplicar permisos al generar y descargar; exportaciones no son públicas. Programación de informes por correo opcional con destinatarios autorizados y caducidad.

---
# 24. Servicios y planes comerciales
**Rutas:** /services, /services/[id], /services/plans, /services/quotes.

## Catálogo de servicios
Vista cards/tabla con filtros por categoría, estado, vigencia y público. Ficha: nombre, slug, descripción corta/larga, problema que resuelve, público objetivo, características, entregables, alcance incluido/excluido, tecnologías documentadas, requisitos, tiempos orientativos aprobados, responsables comerciales, archivos públicos, FAQ, condiciones y CTA. Categorías propuestas: desarrollo web, apps móviles, UI/UX, ERP empresarial, B2B/e-commerce, integraciones y automatización/IA; validar con catálogo corporativo vigente.

## Planes y precios
Editor con relación al servicio, nombre, nivel (por ejemplo Básico/Profesional/Empresarial, solo estructura), moneda PEN/USD, modalidad (único, mensual, por proyecto, cotización), importe o «a cotizar», impuestos incluidos/excluidos, límites, funcionalidades, SLA contractual si existe, vigencia desde/hasta, descuentos aprobados, condiciones y comparador. No utilizar precios de ejemplo como reales. Validar moneda, importes, fechas, solapamiento de vigencias y consistencia de prestaciones. Mantener versiones históricas.

## Publicación y permisos
Borrador → revisión comercial → aprobado → publicado → retirado. Separar datos internos (costos, márgenes, notas) de campos públicos. Editor comercial puede proponer cambios; aprobador publica; administrador técnico no adquiere permisos comerciales automáticamente. Historial de cambios, comparación de versiones, vista previa y restaurar como nueva versión. MIA consulta el catálogo publicado según público y fecha, no PDFs desactualizados.

## Cotizaciones (ampliación)
Crear borrador desde plan vigente con snapshot de precio, moneda, unidades y condiciones; contacto mínimo, notas, vigencia, estado y responsable. Revisión, enviar por canal autorizado, aceptar/rechazar/vencer. Exportar PDF de cotización; sin pagos ni facturación automática en MVP. Si ERP ya cubre cotizaciones, integrar en lugar de duplicar la operación.

---
# 25. Portal público y experiencia comercial opcional
**Rutas:** /, /servicios, /servicios/[slug], /planes, /contacto, /asistente-publico.

## Diseño
Hero corporativo con gradiente de marca y CTA «Conoce nuestros servicios» y «Acceso al workspace». Secciones de soluciones, comparador de planes, casos de éxito autorizados, FAQ, contacto y footer legal. Mantener consistencia con la web de MTA Software existente; puede implementarse como sección enlazada, no necesariamente una segunda página corporativa completa. Animaciones suaves y responsive; priorizar carga y legibilidad sobre efectos.

## Funcionalidad pública
Consultar solo campos publicados; comparar planes y solicitar información. Formulario de contacto con nombre, empresa, correo, servicio, mensaje, consentimiento y protección antispam. Estado de envío y respuesta genérica; no pedir información sensible. Solicitud entra a bandeja comercial autorizada, con estados nuevo, contactado, seguimiento, cerrado. No prometer plazos ni precios que no estén publicados. Mostrar canales corporativos verificados.

## MIA comercial público
Si se habilita, usar un agente/configuración e índice separados o un alcance público técnicamente aislado. No reutilizar sin aislamiento el índice interno. Herramientas exclusivamente de catálogo y FAQ públicos, rate limiting, límites de sesión, no acceso a tareas, personas, horas, soporte interno o predicciones privadas. Respuestas sobre precios citan plan vigente; si no existe, indica que no está documentado y deriva a contacto. Sin identidad de supervisor ni accesos administrativos.

## Reglas de implementación
MVP interno primero. Portal público, leads y comparador requieren aprobación de MTA Software, privacidad, publicación comercial y alineación con su web existente. No activar registro libre de practicantes. El CTA de login redirige a la aplicación protegida; ninguna respuesta pública revela existencia de contenido interno. Mantener SEO y accesibilidad en páginas públicas; las rutas privadas no se indexan.

---
# 26. Equipo, directorio y gestión de personas
**Rutas:** /team, /team/[id], /team/groups, /team/invitations.

## Vista de equipo
Directorio por tarjetas o tabla, filtros por especialidad, proyecto, equipo, rol y disponibilidad declarada. Mostrar avatar, nombre, rol contextual, especialidad, proyectos compartidos y contacto interno permitido. Detalle: habilidades declaradas, perfil profesional, membresías, tareas autorizadas, capacidad y formación cuando corresponda. No mostrar contraseñas, datos personales innecesarios, notas privadas ni salarios.

## Acciones por alcance
Practicante: editar su perfil, consultar miembros compartidos y solicitar ayuda. Líder: proponer incorporación o retiro, asignar tarjetas y revisar carga de su equipo. Supervisor: gestionar membresías de su cartera, designar líder, revisar disponibilidad y redistribuir trabajo con auditoría. Admin delegado: invitar, actualizar roles base, activar/suspender, gestionar áreas y especialidades. Superadmin: administrar privilegios globales y seguridad, no asignar trabajo ordinario.

## Gestión de membresías
Equipos con nombre, descripción, proyectos, líder, supervisor y miembros; historial de altas/bajas. Un usuario puede pertenecer a varios equipos. Al retirar un miembro, revocar acceso y notificar tarjetas que requieren reasignación. No borrar su historial de horas y comentarios. Transferencia de liderazgo con fecha de vigencia y aprobación. Invitaciones pendientes, vencidas, aceptadas y revocadas; reasignación masiva con vista previa y validación de alcance.

## Capacidad y privacidad
Disponibilidad semanal, días no laborables y ausencias declaradas con visibilidad mínima; no registrar motivos médicos innecesarios. Mostrar horas planificadas y aprobadas por alcance. Evitar rankings de productividad basados exclusivamente en horas/retrasos; los modelos apoyan planificación de tareas, no decisiones laborales automatizadas. Exportar directorio o capacidad solo con permiso específico y registro de auditoría.

---
# 27. Notificaciones, actividad y centro de comunicación
**Rutas:** /notifications, /activity, /announcements.

## Diseño
Campana con contador de no leídas y popover con recientes, filtros y enlace Ver todas. Centro con pestañas Todas, Menciones, Tareas, Horas, Academia, Conocimiento, Sistema. Agrupar por fecha y tipo, iconos y estado leído/no leído, acción contextual, marcar una/todas, archivar, silenciar hilo. Actividad personal separada de auditoría técnica. Anuncios corporativos fijados y con caducidad; solo autores autorizados publican.

## Eventos y destinatarios
- Tareas: asignación, mención, cambio de fecha, revisión, bloqueo, vencimiento y cierre. Enviar al responsable, seguidores o revisor según evento.
- Horas: presentación, aprobación, rechazo y corrección. Enviar al autor y aprobador correspondiente.
- Conocimiento/Academy: revisión solicitada, publicación, curso asignado, evaluación pendiente y actualización relevante.
- Sistema: invitación, cambio de permiso, sesión de riesgo, fallo de indexación o integración; entregar solo al usuario o administrador autorizado.

## Canales y lógica
In-app como canal base, correo opcional, push web si hay consentimiento, Teams mediante integración configurada. No enviar contenido privado a canales externos sin autorización. Preferencias por categoría/canal, horario silencioso, resumen diario/semanal, zona horaria, frecuencia y desuscripción para avisos opcionales. Avisos críticos de seguridad pueden ser obligatorios por política. Evitar duplicados mediante clave idempotente, agrupar eventos similares y reintentar envíos con backoff. No exponer contenido tras revocación de acceso: revalidar al abrir y minimizar texto del correo.

## Actividad y aceptación
Notificación dirige al recurso autorizado; si fue archivado o se perdió permiso, mostrar explicación genérica. Cambiar estado de lectura no modifica el evento de auditoría. Centro de comunicación no reemplaza chat corporativo; comentarios permanecen en la tarjeta y las conversaciones de MIA en su historial.

---
# 28. Mi perfil y configuración personal
**Rutas:** /profile, /settings/profile, /settings/preferences, /settings/security, /settings/privacy.

## Perfil
Portada sobria, avatar, nombre, puesto/rol contextual, especialidad, equipo, correo verificado y descripción profesional. Edición de foto, nombre visible, bio, habilidades declaradas, enlaces profesionales opcionales y zona horaria. Rol, correo corporativo y membresías sensibles se modifican mediante proceso autorizado. Avatar subido se escanea y almacena privado según política. Vista previa de qué datos ven otros miembros.

## Preferencias de experiencia
Tema claro/oscuro/sistema, densidad compacta o cómoda, idioma español por defecto, tamaño de texto, reducción de movimiento, formato fecha/hora, landing preferida, sidebar y widgets de dashboard. Configuración de MIA: voz, subtítulos, reproducción automática desactivada por defecto, avatar, modo preferido, conservación de historial según política y modo accesible. Preferencias se sincronizan entre dispositivos sin guardar secretos en localStorage.

## Seguridad y cuenta
Cambiar contraseña si aplica, MFA, sesiones activas (dispositivo aproximado, última actividad), cerrar otras sesiones, actividad de acceso y recuperación. Operaciones sensibles requieren reautenticación. Para SSO, derivar gestión de credenciales al proveedor. Notificar cambios de seguridad sin revelar información innecesaria. Botón cerrar sesión disponible en todo momento.

## Privacidad, ayuda y solicitudes
Gestionar notificaciones, consentimientos opcionales, solicitar copia de datos o corrección y eliminación conforme a política de retención. Eliminar historial de chat propio cuando esté permitido, explicando límites de registros legales/seguridad. Ayuda contextual, preguntas frecuentes, atajos de teclado, reportar problema y estado de servicio. No permitir cambiar configuraciones globales desde perfil personal. Estados: guardando, guardado, error y cambios sin guardar; validación inline y confirmación de operaciones irreversibles.

---
# 29. Administración funcional y configuración de organización
**Rutas:** /admin/users, /admin/roles, /admin/catalogs, /admin/settings, /admin/approvals.

## Panel de administración
Resumen de invitaciones, solicitudes, revisiones documentales, fallos y cambios recientes. Buscador de configuración; navegación por pestañas. Usuarios: tabla, detalle, invitar, reenviar, suspender, reactivar, asignar roles delegados, reset de sesión autorizado y exportación mínima. No cambiar contraseña de otro usuario directamente. Operaciones masivas con vista previa, razón y confirmación.

## Configuración funcional
- Organización: nombre, logo aprobado, idioma, zona horaria, formato de fechas, calendario laboral, áreas y especialidades.
- Proyectos: plantillas, tipos de tarea, complejidad, prioridades, categorías semánticas de columna, WIP, reglas de revisión, dependencias, campos y etiquetas.
- Horas: límites, aprobación, correcciones, categorías, capacidad y plazos de envío. No alterar períodos ya aprobados sin corrección trazable.
- Academy: niveles, categorías, rúbricas, certificados, autores, mentores, aprobadores y reglas de asignación.
- Conocimiento: tipos permitidos, tamaño, retención, audiencias, revisores, frecuencia de vigencia e indexación.
- Comercial: monedas, categorías, aprobadores, estados y condiciones; precios requieren permiso comercial específico.
- Comunicación: plantillas de avisos, canales, recordatorios, horarios, anuncios y frecuencia.

## Roles y aprobaciones
Editor de permisos con matriz, ámbitos y simulación «ver accesos» sin suplantar identidad. Roles protegidos no editables por admins de menor nivel. Solicitudes de cambio con solicitante, justificación, antes/después, aprobador, estado, fecha y caducidad. Configuraciones críticas versionadas; validación, vista previa de impacto y rollback como nueva versión. Separar configuración operativa de infraestructura y credenciales.

---
# 30. Superadministración, seguridad y auditoría global
**Rutas:** /system/overview, /system/access, /system/integrations, /system/audit, /system/jobs, /system/policies.

## Consola de plataforma
Salud de autenticación, base de datos, almacenamiento, Foundry, indexación, Speech, ML y notificaciones; última prueba, latencia, tasa de errores, cuotas, consumo y trabajos fallidos. Gestión de integraciones: configurar identificadores no secretos, referencia a gestor de secretos, activar/desactivar, prueba de conexión, rotar credenciales y ver logs sanitizados. Nunca mostrar clave completa ni almacenar en navegador.

## Acciones permitidas y límites
Gestionar administradores globales, políticas MFA, sesiones, retención, backups, flags de funciones, cuotas, entornos y mantenimiento. Puede abrir consola técnica pero no editar tarjetas, aprobar horas, publicar precios o consultar chats privados por defecto. Acceso excepcional solo mediante proceso de emergencia con alcance, motivo, tiempo limitado, auditoría y revisión. No permitir autoelevación silenciosa ni suplantación sin autorización explícita.

## Auditoría global
Filtros por actor, acción, recurso, origen, período, resultado y correlación. Eventos: inicio de sesión, cambio de permiso, exportación, publicación, borrado, cambios de configuración, operaciones de emergencia y llamadas sensibles. Detalle de evento sanitizado, exportación restringida, detección de anomalías, conservación inmutable o resistente a manipulación según infraestructura. La auditoría no puede ser editada ni purgada individualmente desde UI; retención legal configurable con proceso aprobado.

## Operación y continuidad
Monitor de colas de indexación, importación, reportes y notificaciones: estado, intentos, error, reintentar/cancelar con autorización e idempotencia. Backup cifrado y pruebas de restauración en entorno aislado. Modo mantenimiento, rollback de configuración, alertas de consumo y bloqueo de funciones de alto costo. Segregar producción, pruebas y demo; cambios críticos requieren aprobación independiente cuando sea viable.

---
# 31. Arquitectura técnica y estrategia de integración
## Componentes propuestos
- Frontend y BFF: Next.js + TypeScript, Tailwind CSS, shadcn/ui, Motion, dnd-kit para Kanban, biblioteca de gráficos (Recharts u otra). Server routes para operaciones seguras; no depender de estado del cliente como fuente de verdad.
- Identidad y persistencia: Supabase Auth + PostgreSQL, RLS, Storage privado y Realtime con políticas de acceso. Alternativa Entra SSO tras configurar tenant. Backend aplica autorización además de RLS; service role solo en trabajos controlados, nunca al navegador.
- IA: Microsoft Foundry Agent Service para MIA, File Search para fuentes comunes o Azure AI Search/búsqueda controlada para documentos restringidos; herramientas backend para datos operativos. Elegir SDK/API según tipo y versión del agente ya creado, no asumir compatibilidad clásica/nueva.
- Azure Speech: STT/TTS/avatar opcional; Azure ML: endpoints desplegados para inferencia. Teams/Outlook/Graph y ERP mediante adaptadores opcionales, con consentimiento y permisos mínimos.
- Trabajos asíncronos: cola/worker para indexación, escaneo, exportación, importación y notificaciones; idempotencia, reintentos, dead-letter y monitorización. No bloquear solicitudes web esperando tareas largas.

## Flujo de datos
Navegador → autenticación/BFF → autorización → PostgreSQL o almacenamiento → servicio externo necesario → respuesta. Para chat: BFF resuelve sesión y ámbito → agente → herramientas autorizadas → datos/documentos → respuesta con fuentes. Identidad del servicio no equivale a identidad del usuario; propagar contexto firmado o resolver permisos en servidor. Actualización de tarjeta: transacción de dato + evento/auditoría + outbox → realtime/avisos. Documento publicado: versión aprobada → job → índice → verificación → estado disponible.

## Despliegue
Entornos local, staging y producción aislados; variables en gestor de secretos, migraciones versionadas, CI con lint, tipos y pruebas, deploy con rollback. Observabilidad con logs estructurados, correlation ID, latencia y métricas sin PII innecesaria. Confirmar costos, región y permisos Azure for Students; el estado del agente y los endpoints debe probarse antes de prometer integración real.

---
# 32. Modelo lógico de base de datos
| Dominio | Entidades principales |
|---|---|
| Identidad | organizations, profiles, roles, permissions, role_grants, invitations, user_preferences |
| Equipo | teams, team_members, project_members, availability |
| Proyectos | projects, boards, board_columns, milestones, labels, field_definitions |
| Tarjetas | cards, card_assignees, card_labels, field_values, checklists, checklist_items, card_dependencies, comments, attachments, card_events |
| Horas | timers, time_entries, time_entry_versions, approvals |
| Agenda/soporte | calendar_events, tickets, ticket_comments, ticket_links |
| Academy | paths, courses, course_versions, modules, lessons, enrollments, lesson_progress, assessments, attempts, mentoring_sessions |
| Conocimiento | documents, document_versions, document_acl, index_jobs, source_refs |
| Comercial | services, plans, plan_versions, quotes, quote_items, leads |
| IA | conversations, messages, citations, tool_runs, model_versions, predictions |
| Operación | notifications, notification_preferences, automation_rules, automation_runs, audit_events, outbox, export_jobs, integration_settings |

## Relaciones y restricciones
Organización 1:N proyectos/usuarios por membresía; proyecto 1:N tableros; tablero 1:N columnas; columna 1:N tarjetas; tarjeta N:M usuarios/etiquetas, 1:N comentarios/checklists/horas/archivos; dependencias N:M dirigidas sin ciclos. Cursos versionados con módulos/lecciones y matrículas. Documento 1:N versiones y ACL. Plan 1:N versiones con vigencia; cotización guarda snapshot. Predicción referencia versión del modelo, tarjeta opcional y escenario; no modifica horas reales.

## Convenciones
UUID internos, códigos humanos únicos por organización/proyecto, timestamps UTC, created_by, updated_at, version para concurrencia, archived_at cuando aplique, índices por organización/proyecto/estado/fecha. FK y restricciones en BD, RLS por alcance, transacciones para movimientos y aprobación, montos NUMERIC y duración en minutos/segundos enteros. Identificador externo de importación único por lote/fuente. Audit/outbox append-only en flujos críticos; minimización de PII y retención por dominio. Separar demo/operativo mediante entorno o ámbito explícito no mezclable.

---
# 33. Contratos API, sincronización e importación
| Método / ruta orientativa | Responsabilidad |
|---|---|
| GET /api/projects; POST /api/projects | Listar autorizados / crear con permiso |
| POST /api/boards/:id/columns | Crear columna con orden y semántica |
| PATCH /api/cards/:id; POST /api/cards/:id/move | Actualizar campos / mover con versión |
| POST /api/cards/:id/comments; /attachments | Comentar / iniciar carga segura |
| POST /api/timers/start; /stop | Control de temporizador del usuario |
| POST /api/time/:id/submit; /approve | Flujo de aprobación con separación |
| POST /api/documents/:id/versions; /publish | Versionar / publicar y encolar índice |
| POST /api/mia/chat; POST /api/speech/session | Chat autorizado / sesión efímera |
| POST /api/predictions | Validar entrada y ejecutar endpoint |
| GET /api/analytics; POST /api/exports | Consultar métricas / crear reporte |
| POST /api/imports; GET /api/jobs/:id | Validar importación / ver estado |

## Contrato común
Validación de esquema en servidor; sesión, permiso, recurso, ámbito y versión. Paginación por cursor, filtros permitidos, IDs opacos, respuesta con data/meta o error con código y correlation ID. HTTP 401/403/404 según política de no revelación, 409 para conflicto, 422 validación, 429 cuota, 503 dependencia no disponible. Idempotency-Key para creaciones/reintentos. Streaming con cancelación si soportado. URLs firmadas para archivos y descargas; revalidar pertenencia antes de emitir.

## Importar 500 registros
Asistente CSV: subir → mapear columnas → previsualizar → validar IDs, categorías, fechas, horas y duplicados → confirmar lote demo → importar transaccionalmente o por lotes → resumen y errores descargables. Mapear siete grupos a cinco proyectos con especialidades/equipos conservando etiquetas originales. No crear contraseñas, cuentas activas ni invitaciones a partir del nombre del CSV. Identidades demo separadas. No inventar comentarios, adjuntos, checklists o sesiones. Importar 470 finalizadas y 30 pendientes según origen; preservar nulos de pendientes. Registrar procedencia, hash y posibilidad de revertir lote sin borrar cambios posteriores no relacionados.

---
# 34. Requisitos no funcionales y control de calidad
| Área | Requisito propuesto / criterio |
|---|---|
| Seguridad | HTTPS, RLS, autorización servidor, MFA privilegiado, secretos aislados, validación, CSP, protección CSRF cuando aplique y rate limits |
| Privacidad | Minimizar PII, ACL en archivos y chat, retención aprobada, sin datos privados en logs, separación demo/real |
| Accesibilidad | Objetivo WCAG 2.2 AA; teclado, foco, contraste, alternativas a drag, subtítulos y movimiento reducido |
| Rendimiento | Objetivo p95 API interna < 800 ms en carga de prueba acordada; IA externa se mide aparte; paginación y virtualización de tablero |
| Disponibilidad | Manejar fallos parciales, timeout, reintento acotado, modo texto sin voz; no prometer SLA no contratado |
| Consistencia | Transacciones, control de versión, outbox, idempotencia y rollback UI |
| Escalabilidad | Índices, colas, límites por usuario, cargas directas autorizadas y procesamiento por lotes |
| Mantenibilidad | Módulos por dominio, tipos compartidos, migraciones, tests, revisión de PR y documentación de API |
| Auditoría | Actor, alcance, acción, fecha, resultado y correlación; eventos de cambios críticos protegidos |
| Costos | Cuotas de tokens/voz/avatar/ML, timeout de sesión, presupuesto y alertas; límites antes de activar servicios |

## Manejo transversal de estados
Todas las vistas deben contemplar carga, vacío, datos parciales, error, sin permisos, offline, reintento, sesión vencida y éxito. No presentar mock como conectado. Las acciones destructivas requieren confirmación y restauración si es viable. La aplicación funciona en Chrome/Edge modernos y se prueba en móvil; WebRTC y permisos de micrófono requieren comprobación específica.

## Calidad de IA
Evaluar exactitud de fuentes, rechazo fuera de contexto, insuficiencia, acceso cruzado, documento retirado, inyección de prompt, exactitud de cifras, actualización de datos y latencia. Versionar instrucciones, conjunto de pruebas y modelo; medir antes y después de cambios. Una instrucción de sistema sola no garantiza seguridad. Predicciones requieren evaluación y supervisión humana.

---
# 35. Casos de aceptación, roadmap y entrega
## Pruebas end-to-end prioritarias
| ID | Escenario | Resultado esperado |
|---|---|---|
| AC-01 | Invitación y login de practicante | Accede solo a su workspace y proyectos |
| AC-02 | Arrastrar tarjeta como líder | Cambio persistido, orden y auditoría visibles |
| AC-03 | Practicante intenta editar tarjeta ajena | Denegación backend; datos intactos |
| AC-04 | Dos personas editan una tarjeta | Conflicto controlado, sin pérdida silenciosa |
| AC-05 | Registrar y aprobar horas | Totales exactos; no autoaprobación |
| AC-06 | Subir y publicar manual | MIA cita versión solo tras indexación |
| AC-07 | Retirar versión o acceso | No recuperable por MIA ni descarga |
| AC-08 | Preguntar por proyecto futuro desconocido | Respuesta de insuficiencia, no invención |
| AC-09 | Pregunta ajena a MTA | Rechazo de contexto |
| AC-10 | MIA consulta tarjeta actualizada | Lee valor operativo vigente autorizado |
| AC-11 | Avatar o endpoint ML falla | Degradación a texto o no disponible |
| AC-12 | Exportación y URL compartida | Permisos verificados al generar/descargar |
| AC-13 | Superadmin abre proyecto sin permiso | No accede por privilegio técnico global |

## Roadmap recomendado
**Fase 0:** confirmar marca, alcance, agente funcional, esquema de datos, presupuesto y permisos. **Fase 1 (MVP):** login/roles, shell, dashboard, proyectos, Kanban, tarjetas, horas básicas, importación demo, MIA real y biblioteca actualizable. **Fase 2:** comentarios/adjuntos completos, realtime, aprobaciones, notificaciones, reportes, soporte y Academy inicial. **Fase 3:** voz/avatar, analítica y endpoints ML, cursos avanzados, automatizaciones y calendario. **Fase 4:** catálogo, portal comercial opcional, integraciones ERP/Graph y consola operativa avanzada. Seguridad mínima y auditoría no se posponen a fase 4.

Definición de terminado: diseño responsive, permisos y pruebas, persistencia real, manejo de fallos, auditoría pertinente, documentación y demo reproducible. Ninguna función externa se marca lista sin prueba real.

---
# 36. Demostración, fuentes y decisiones pendientes
## Guion de demostración
1. Iniciar sesión como líder, abrir dashboard y filtrar un proyecto demo; mostrar indicadores con fuente.
2. Crear columna o tarjeta, asignar, añadir checklist/comentario/adjunto, mover a revisión y observar auditoría. Registrar horas y presentar; aprobar desde supervisor separado.
3. Consultar MIA por la tarjeta modificada y mostrar la fuente operativa. Preguntar por un proyecto futuro no documentado y por un tema ajeno; verificar los rechazos.
4. Publicar una guía Academy como editor con revisión de supervisor; verificar versión e indexación; consultar MIA por esa guía.
5. Si están disponibles, activar voz/avatar y ejecutar clasificación/regresión con entradas reales del esquema. Mostrar resultado del endpoint, no cifras ficticias. Exportar reporte y comprobar permisos.

## Material de partida y referencias técnicas
Archivos del usuario: paleta corporativa MTA Software; README.MD, README(1).md, README(2).MD, README(3).md, CONTEXTO.md; MTA_Software_500_Registros_Frontend_Backend(1).csv, MTA_Clasificacion.csv, MTA_Regresion.csv; cinco PDF de conocimiento MTA. Las cifras del dataset fueron comprobadas en los CSV. El alcance aquí es una especificación nueva; no acredita que los proyectos o roles estén desplegados.

Microsoft Learn (consultado para factibilidad técnica):
- File Search: https://learn.microsoft.com/azure/ai-services/agents/how-to/tools/file-search
- Runtime y herramientas: https://learn.microsoft.com/azure/foundry/agents/concepts/runtime-components
- Avatar Speech en tiempo real: https://learn.microsoft.com/en-us/azure/ai-services/speech-service/text-to-speech-avatar/real-time-synthesis-avatar
- Regiones Speech: https://learn.microsoft.com/en-us/azure/ai-services/speech-service/regions
- Endpoints ML: https://learn.microsoft.com/en-us/azure/machine-learning/how-to-deploy-managed-online-endpoints?view=azureml-api-2

## Pendiente de validación
Permisos y políticas reales de MTA, publicación de precios, acceso Azure, estado de modelos/agente, integración ERP, costos, límites de archivos, retención, canales y calendario laboral. Las rutas, stack, flujos de aprobación, umbrales y fases son decisiones propuestas para desarrollar, ajustables con el equipo.
