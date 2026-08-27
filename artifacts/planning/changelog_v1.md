---
tipo: changelog
proyecto: App_Game_Tracker
version: v3.0.5
estado: activo
fecha: 2026-08-27
tags: [proyecto, changelog, versiones, v3.0.5, crud-null-deletion, sentinel-pattern, link-clear-button, victor-engineer]
---

# Registro de Cambios (Changelog) - Rastreador de Entretenimiento Personal

Todos los cambios notables de este proyecto se documentarán en este archivo.

## [3.0.5] - 2026-08-27 (CRUD Complete Null Support & Link Clearing)

### Fixed & Enhanced
- **Soporte Completo de Asignación y Borrado `NULL` en `Game.copyWith` (Patrón Sentinel):**
  - Se corrigió el error fundamental donde pasar `null` a campos opcionales (`link: null`, `coverUrl: null`, `summary: null`, `rating: null`) restauraba los valores antiguos debido al operador de coalescencia nula `param ?? this.param`.
  - Implementación del patrón canónico `_sentinel` de Dart en `Game.copyWith`, permitiendo distinguir entre un argumento no provisto (`_sentinel` $\rightarrow$ mantiene valor actual) y un valor `null` explícito (`identical(val, _sentinel) == false` $\rightarrow$ borra y asigna `NULL` en SQLite).
- **Botón de Borrado Rápido en Campo de Enlace (`GameDetailScreen`):**
  - Se añadió un botón `clear` (`Icons.clear_rounded`) interactivo al campo de Enlace Enciclopédico (Wikipedia) para vaciar el enlace con 1 solo toque.
  - Al guardar los cambios con el enlace o la carátula vacía, SQLite actualiza exitosamente el registro con `NULL`, persistiendo la eliminación sin restaurar el valor anterior.
- **Soporte de Calificación 'Sin calificar' a `NULL`:**
  - Al seleccionar 'Sin calificar' en el dropdown de calificación, el valor se envía como `null` a SQLite, eliminando cualquier puntuación previa correctamente.

## [3.0.4] - 2026-08-27 (Modern Visual Platform Selector & RAWG Platform Detection)

### Fixed & Enhanced
- **Rediseño Completo del Selector de Plataformas (`SearchScreen`):**
  - **Eliminación del Dropdown Desbordante:** Se reemplazó el menú desplegable vertical que se salía de la pantalla por un selector visual integrado basado en **Chips interactivos con logos oficiales** (`PlatformHelper`).
  - **Detección Inteligente de Plataformas de RAWG:** Al abrir el diálogo para guardar un juego nuevo, el sistema extrae automáticamente las plataformas oficiales en las que fue lanzado dicho título (ej. Elden Ring muestra directamente `PC`, `Playstation 5`, `Playstation 4`, `Xbox`).
  - **Selección Táctil Inmediata:** Cada chip incluye su logotipo a color, nombre de plataforma, feedback táctil animado y checkmark activo en rojo canónico (`#DC2626`).
  - **Modo Expandible ("+ Otras plataformas"):** Si el usuario jugó el título en una plataforma no oficial o emulada, un botón superior permite alternar instantáneamente al catálogo completo de plataformas disponibles.
- **Reorganización Ergonómica del Formulario:**
  - El campo **Estado** ahora cuenta con altura máxima restringida (`menuMaxHeight: 220`) impidiendo desbordamientos.
  - La fila superior agrupa de forma balanceada **Estado** y **Horas Jugadas**, seguida de la **Fecha de Inicio** y el nuevo bloque visual de **Plataformas**.

## [3.0.3] - 2026-08-27 (Unrestricted RAWG Genres & Automatic Wikipedia Links)

### Fixed & Enhanced
- **Asignación Ilimitada de Géneros RAWG:**
  - Removido el filtro restrictivo en `SearchScreen` que descartaba géneros en inglés de RAWG que no coincidieran exactamente con la lista en español.
  - Ahora se capturan y asignan **TODOS los géneros** devueltos por la API de RAWG sin ninguna limitación, guardándose directamente en SQLite y añadiéndose dinámicamente al catálogo de chips interactivos.
- **Asignación Automática y Robusta de Enlaces de Wikipedia:**
  - Corregido el motor de búsqueda en Wikipedia (`MetadataService.searchWikipedia`):
    - Uso de `Uri.https` para codificación correcta de parámetros sin colisiones de sintaxis.
    - Encabezado `User-Agent` compatible con la política de APIs de Wikimedia.
    - Sanitización de títulos (eliminación de símbolos `™`, `®`, `©`) y búsqueda cruzada en español e inglés con fallbacks inteligentes.
  - Al añadir un juego desde `SearchScreen`, se consulta y enlaza automáticamente su página oficial de Wikipedia en el campo de enlace.
  - En la sincronización con Steam (`SteamService`), tanto los juegos existentes sin enlace como los nuevos juegos creados reciben su link de Wikipedia automáticamente.
  - En `GameDetailScreen`, el campo de enlace enciclopédico incluye ahora un botón de acción rápida para buscar y asignar Wikipedia en 1 clic.
- **Acción Masiva de Enriquecimiento en Configuración (`SettingsScreen`):**
  - Nuevo botón **"Sincronizar Géneros, Portadas y Wikipedia"** que recorre toda la biblioteca de SQLite, rellenando portadas faltantes, asignando todos los géneros disponibles de RAWG y buscando los enlaces enciclopédicos de Wikipedia.

## [3.0.2] - 2026-08-27 (Native HowLongToBeat Service & Auto-Enrichment)

### Added & Changed
- **Servicio Nativo HowLongToBeat (`HltbService`):**
  - Implementación de cliente HTTP directo contra la API interna moderna de HowLongToBeat (`/api/search/site/init` y `/api/search/site`).
  - Extracción automática de la duración en horas de la **Historia Principal (Campaña)** y **100% Completista** sin requerir claves de API de terceros.
  - Gestión automática de tokens de seguridad (`x-auth-token`, `x-hp-key`, `x-hp-val`) y reintentos transparentes ante expiración.
- **Sincronización Automática en Steam (`SteamService`):**
  - Al sincronizar juegos desde Steam (propios o compartidos por Family Sharing), el sistema consulta HowLongToBeat si el juego no tiene duración registrada.
  - Auto-culminación activa: si las horas jugadas acumuladas alcanzan o superan `hltb_main`, el juego se marca de inmediato como *Jugado* y se registra la fecha de culminación.
- **Búsqueda Instantánea en Detalle de Juego (`GameDetailScreen`):**
  - Nuevo botón interactivo **"Buscar en HLTB"** en la sección de Metadatos de duración con microanimación de carga y autocompletado en tiempo real de los campos numéricos de Campaña y Completista.
- **Enriquecimiento Masivo de Biblioteca (`SettingsScreen`):**
  - Nueva acción en Configuración: **"Buscar Metadatos HLTB en mi Biblioteca"**, que recorre todos los títulos que carecen de estimaciones, consulta HowLongToBeat, actualiza SQLite y reporta cuántos juegos fueron enriquecidos y auto-culminados.

## [3.0.1] - 2026-08-27 (Purge Legacy Notion Page ID & Defensive Memory Limits)

### Refactored & Optimized
- **Purga Definitiva de `notionPageId`:**
  - Eliminado el getter heredado `notionPageId => id` en `Game`.
  - Refactorizadas todas las referencias en animaciones Stagger (`ValueKey`), claves de listas y etiquetas Hero en `DashboardScreen` y `GameDetailScreen` hacia la propiedad canónica `game.id`.
- **Límites Defensivos de Variables para Optimización de Memoria:**
  - Implementada sanitización automática y transparente en el constructor de `Game` y en todas sus factorías de serialización (`fromSqliteMap`, `fromJson`, `fromLegacyNotion`):
    - `title`: acotado a un máximo de **255 caracteres** (estándar óptimo para índices B-Tree).
    - `platform`: acotado a **100 caracteres**.
    - `status`: acotado a **50 caracteres**.
    - `coverUrl` y `link`: acotados a **2048 caracteres**.
    - `summary`: acotado a **2000 caracteres** (previene que resúmenes masivos de Wikipedia saturen la memoria RAM o filas de SQLite).
    - `genres`: máximo **20 géneros**, cada uno truncado a **50 caracteres**.
    - `rating`: acotado a **20 caracteres**.
    - `hoursPlayed`, `hltbMain`, `hltbCompletionist`: clamped numérico estricto entre **0.0** y **99,999.0** horas (redondeado a 2 decimales, previniendo valores negativos, NaN o infinitos).
  - El usuario nunca experimenta bloqueos ni ve advertencias de límites, pero la memoria de la app, el tamaño de la base de datos y la velocidad de consultas operan con máxima eficiencia.
- **Suite de Pruebas Unitarias Ampliada:**
  - Nuevos tests en `game_model_test.dart` verificando la aplicación transparente de todos los límites y la ausencia de dependencias de Notion.

## [3.0.0] - 2026-08-27 (Local-First SQLite Architecture, Steam API Sync & Open Source Release)

### Added & Changed
- **Migración a Arquitectura 100% Local-First con SQLite:**
  - Sustitución completa de la base de datos remota de Notion por base de datos local SQLite (`sqflite` y `sqflite_common_ffi` para Windows Desktop).
  - Consultas y persistencia instantáneas (< 2 ms) con total soberanía y funcionamiento sin conexión a internet ni dependencias externas.
  - Tabla relacional `games` con índices B-Tree en `estado`, `plataforma`, `steam_id` y `título`.
- **Portabilidad Fiel de la Lógica de `games.py` a Dart (`SteamService`):**
  - Consulta dual a Steam Web API: `GetOwnedGames` (juegos propios) y `GetRecentlyPlayedGames` (detección de títulos en préstamo **Family Sharing**).
  - Filtro estricto anti-ruido de 30 minutos (`playtimeHours >= 0.5`).
  - Algoritmo de emparejamiento tri-fase: AppID indexado $\rightarrow$ Nombre limpio $\rightarrow$ Similitud difusa Sørensen-Dice / Levenshtein (> 0.90) con `StringNormalizer`.
  - Auto-culminación inteligente por HowLongToBeat: si `horas >= hltb_main`, el juego se marca automáticamente como *Jugado* con fecha de finalización.
  - Resolución automática de Vanity URLs para SteamID64 (`ISteamUser/ResolveVanityURL`).
- **Gestión Híbrida de Carátulas (Web + Galería Local):**
  - Widget universal `AppCoverImage` para renderizar indistintamente enlaces HTTP(S) y rutas locales de disco.
  - Selector nativo de archivos y galería (`file_picker`) que guarda de forma segura las imágenes locales en `app_documents/covers/cover_{id}_{timestamp}.png`.
- **Preservación Visual Absoluta del Frontend:**
  - Se mantuvo intacto el diseño visual prémium Zinc & Crimson Red (`#DC2626`), tipografías Outfit/Inter, Spotlight Hero, vistas Grid/List y filtros dinámicos.
- **Portabilidad de Datos & Respaldo JSON:**
  - Exportador e importador directo en `BackupService` para respaldar la biblioteca completa en Descargas y restaurar copias de v3 o versiones anteriores de Notion.
  - Dataset de prueba ficticio listo para usar: `sample_games_library.json`.
- **Publicación Open Source & DevOps:**
  - `README.md` maestro con branding oficial Victor Engineer ([https://victorengineer.fyi](https://victorengineer.fyi)).
  - Licencia de código abierto MIT (`LICENSE`).
  - Pipeline de CI/CD automatizado (`.github/workflows/release.yml`) con ejecución **exclusiva ante tags (`v*`)** para compilar instaladores de Windows x64 ZIP y Android APK.

## [2.8.4] - 2026-08-27 (Fix Notion API Error 400 on Game Edit & Update)

### Fixed & Enhanced
- **Corrección de Error HTTP 400 al Guardar Cambios en Notion:**
  - Diagnosticado el origen del error: juegos con portadas subidas directamente a Notion se almacenan como archivos S3 internos (`prod-files-secure.s3...`). Al guardar cualquier cambio desde el detalle del juego, la app re-enviaba esa URL con `type: external`, provocando el rechazo inmediato de la API de Notion: *"A file with type external cannot contain a Notion hosted file url. Use type file."*
  - Modificado [`_saveChanges()`](file:///c:/Users/vmesp/Documents/Cositas/App-Rastreador-de-Entretenimiento/frontend/lib/screens/game_detail_screen.dart) para comparar si la URL de la portada fue realmente editada por el usuario. Si no fue modificada, se omite el campo `Portada` del payload PATCH, preservando la portada original en Notion sin provocar errores.
  - Actualizado [`toNotionProperties()`](file:///c:/Users/vmesp/Documents/Cositas/App-Rastreador-de-Entretenimiento/frontend/lib/models/game.dart) para filtrar URLs alojadas en AWS S3/Notion e impedir su envío como enlaces externos.
  - Robusteza en constructores de [`NotionParser`](file:///c:/Users/vmesp/Documents/Cositas/App-Rastreador-de-Entretenimiento/frontend/lib/services/notion_parser.dart) (`buildSelect`, `buildUrl`, `buildRichText`, `buildMultiSelect`) para enviar `null` o estructuras limpias en lugar de cadenas vacías que puedan invalidar el esquema de Notion.
  - Mejorada la clase `NotionApiException` en [`notion_service.dart`](file:///c:/Users/vmesp/Documents/Cositas/App-Rastreador-de-Entretenimiento/frontend/lib/services/notion_service.dart) para parsear el campo `message` de la respuesta JSON de error de Notion y mostrar explicaciones claras en el SnackBar.

## [2.8.3] - 2026-08-27 (Code & Asset Optimization / Bloatware Removal)

### Removed & Optimized
- **Limpieza de Assets Huérfanos y Redundantes:**
  - Auditados todos los archivos multimedia de [`frontend/assets/images/`](file:///c:/Users/vmesp/Documents/Cositas/App-Rastreador-de-Entretenimiento/frontend/assets/images/) contra el código de la aplicación.
  - Eliminadas 7 imágenes no utilizadas (`Epic_Games_logo.svg.webp`, `GOG_LOGO_DARK.png`, `logo-Xbox.png`, `nintendo-logo-1-1.png`, `nintendo_logo_red.png`, `nintendo_PNG19.png` y `steam-logo.png`), reduciendo el peso del bundle final en más de **361 KB**.
- **Purga de Dependencias Inactivas (`pubspec.yaml`):**
  - Eliminado `dio: ^5.4.0`: Toda la conectividad de red con Notion API y RAWG API se realiza de forma nativa y robusta a través de `http: ^1.2.0`, haciendo que `dio` fuera un paquete completamente redundante.
  - Eliminado `flutter_staggered_grid_view: ^0.7.0`: La app emplea layouts responsivos propios con `GridView.builder` y delegados nativos de Flutter, prescindiendo de este paquete externo.
  - Se redujo la superficie de dependencias transitivas, acelerando los tiempos de descarga y compilación en CI/CD.
- **Auditoría de Código y Depuración:**
  - Verificados los 14 archivos Dart de `lib/`: 100% de los imports activos y utilizados.

## [2.8.2] - 2026-08-27 (Official Victor Engineer Native Branding & Iconography)

### Added & Enhanced
- **Icono de Aplicación Gamer y Preservación de `icon.svg`:**
  - Preservado intacto el vector oficial [`icon.svg`](file:///c:/Users/vmesp/Documents/Cositas/App-Rastreador-de-Entretenimiento/frontend/assets/images/icon.svg) original de Victor Engineer (con las siglas **VE**).
  - Configurado el icono ejecutable (`app_icon.ico`) y de la app móvil (`app_icon.png` y mipmaps de Android) con el mando gamer 2D minimalista sobre fondo rojo Victor Engineer (`#DC2626`).
- **Firma Criptográfica Permanente de Android (`release.keystore`):**
  - Resuelto el error *"Conflicto con un paquete ya existente"* al intentar actualizar la app en Android sin desinstalarla.
  - El error ocurría porque cada compilación en GitHub Actions se ejecuta en una máquina virtual efímera nueva, generando una clave temporal `debug.keystore` con una huella digital criptográfica (SHA-256) diferente en cada ejecución. Como Android prohíbe actualizar un paquete con firmas distintas por seguridad, bloqueaba la actualización.
  - Se generó y fijó un keystore permanente de larga duración (validez de 27 años, hasta 2054) en [`frontend/assets/keystore/release.keystore`](file:///c:/Users/vmesp/Documents/Cositas/App-Rastreador-de-Entretenimiento/frontend/assets/keystore/release.keystore), inyectado en `~/.android/debug.keystore` durante el build.
  - Se dinamizó `--build-name` para extraer automáticamente la versión real desde `pubspec.yaml` (v2.8.2) y un `versionCode` estrictamente creciente (`github.run_number`), permitiendo actualizaciones directas con 1 solo toque de aquí en adelante.

## [2.8.1] - 2026-08-27 (Mobile Ergonomics, Dual-Row Filter Architecture & Visual Collision Fixes)

### Added & Enhanced
- **Barra de Filtros en Dos Hileras en Móvil (`DashboardScreen`):**
  - **Fila 1 (Estados Principales):** `[Todos]`, `[Jugando]`, `[Por jugar]`, `[Jugado]` en una fila horizontal dedicada.
  - **Fila 2 (Selectores de Catálogo & Orden):** `[Plataforma: Todas v]`, `[Género: Todos v]`, `[Orden v]` y `[Limpiar (X)]` en una segunda hilera independiente inmediatamente visible en pantallas estrechas (< 600px).
  - En pantallas anchas (>= 600px), se preserva la hilera única unificada con divisor vertical.
- **Resolución de Colisión en AppBar en Móvil:**
  - En móvil (< 500px), el logo y texto `Victor Engineer` ahora se escalan automáticamente con `FittedBox` y `Flexible`, evitando cualquier solapamiento.
  - Las 5 acciones directas que desbordaban la pantalla se agruparon en móvil: acceso directo a Búsqueda y Estadísticas, y un elegante menú desplegable `⋮` (`PopupMenuButton`) para Cambio de Tema, Sincronización Notion y Ajustes. En PC se conservan los 5 botones individuales.
- **Rediseño Cuadrícula 2x2 para Métricas Superiores (`AnalyticsScreen`):**
  - En móviles (< 600px), las 4 tarjetas de estadísticas (`Total Juegos`, `Horas Jugadas`, `Terminados`, `Tasa Éxito`) pasan de 1 sola fila apretada de 70px a una cómoda cuadrícula 2x2 con el doble de anchura.
  - **Cero Saltos de Línea en Números (`FittedBox`):** Valores como `2176.3` y porcentajes como `65.8%` ya no se dividen en dos renglones bajo ninguna configuración de escala o fuente.
- **Salón de la Fama Adaptativo (`AnalyticsScreen`):**
  - En móvil, las tarjetas de récords (`El Titán`, `Obra Maestra`, `Aventura Ágil`) se despliegan en un carrusel deslizable horizontal de 175px por tarjeta, permitiendo leer títulos como *"Zenless Zone Zero"* y detalles sin truncamiento.
- **Selector de Año y Meta Anual Adaptativo (`AnalyticsScreen`):**
  - Resuelto el desbordamiento de las flechas de selección de año (`< 2026 >` y botón *Ajustar*), que en móvil quedaban cortadas y fuera del marco de la tarjeta.
  - En móvil (< 600px), la cabecera se reorganiza en 2 líneas: Fila 1 para el título y botón *Ajustar*, y Fila 2 para un selector de año con botones táctiles generosos (`< Año 2026 >`) 100% dentro del marco y centrado.
- **Ergonomía de Paginación y Botón Añadir (FAB):**
  - El FAB en móvil se adapta a botón circular compacto de 56px con icono `+`, reduciendo la zona de seguridad a 64px y compactando `'Por pág:'` a `'Ver:'`, manteniendo los controles `< 1 / 12 >` perfectamente centrados y cómodos de pulsar.

## [2.8.0] - 2026-08-26 (QoL & Filter Reorganization, Virtual Normalization & Dual JSON Backup)

### Added & Enhanced
- **Reorganización Táctil de Filtros (`FilterModalSheet`):**
  - Reemplazados los menús desplegables rígidos y kilométricos por un componente modal interactivo y adaptativo (BottomSheet en Android/móvil y Diálogo en escritorio).
  - **Buscador en Tiempo Real:** Campo de texto integrado en la cabecera que permite filtrar géneros y plataformas al instante mientras se teclea.
  - **Conteo Dinámico por Categoría:** Cada opción muestra una pastilla numérica con la cantidad exacta de juegos asociados (ej. `Acción (18)`, `Nintendo Switch (12)`), ordenadas por frecuencia de títulos.
  - **Acción Rápida Todos:** Opción directa para restablecer a *"Todos / Todas"* con 1 solo toque.
- **Normalización Semántica Virtual de Géneros (`GenreHelper`):**
  - Mapeo canónico transparente en memoria que unifica sinónimos bilingües de Notion y RAWG (ej: `Action` $\rightarrow$ `Acción`, `Adventure` $\rightarrow$ `Aventura`, `Racing` $\rightarrow$ `Carreras`, `RPG` $\rightarrow$ `Rol / RPG`).
  - **Cero Modificaciones en Notion:** La base de datos remota no sufre ninguna alteración, eliminando cualquier riesgo de corrupción o rate limits.
  - **Iconografía y Colores Temáticos:** Cada género dispone de un icono semántico dedicado (espadas, mira, mapa, volante, calavera, etc.) y un color característico en lugar del icono genérico anterior.
- **Copia de Seguridad y Portabilidad Local (`BackupService`):**
  - **Exportar Biblioteca (JSON):** Genera y descarga un archivo estructurado `tracker_backup_YYYYMMDD_HHmmss.json` en la carpeta de Descargas con todos los registros y propiedades de la biblioteca.
  - **Importar / Restaurar Biblioteca (JSON):** Modal en Ajustes que detecta respaldos recientes en Descargas y permite restaurar la biblioteca local de inmediato offline o al cambiar de dispositivo.
- **Calidad de Vida en Biblioteca (Dashboard QoL):**
  - **Contador de Filtros Activos:** El botón de limpieza en la barra de herramientas ahora muestra dinámicamente la cantidad de filtros aplicados (`Limpiar (X)`).
  - **Botón de Borrado Rápido en Buscador:** Borrado instantáneo del término de búsqueda con un toque.
- **Pulido Visual del Modal de Filtros (`FilterModalSheet`):**
  - **Eliminación de Barra Negra:** Erradicado el divisor huérfano entre el buscador y la lista que generaba una línea oscura discordante en modo claro.
  - **Bordes Redondeados Completos:** Aplicado radio de curvatura total (`BorderRadius.circular(24)`) y margen inferior flotante con `Clip.antiAlias` para que el modal termine con elegantes bordes redondeados tanto en la parte superior como inferior.
- **Adaptación de Botones Rápidos de Horas en Modo Claro (`GameDetailScreen`):**
  - **Botones de Tiempo (`+30m`, `+1h`, `+2h`):** Adaptados dinámicamente según el tema activo; en modo claro lucen un elegante fondo suave `#FEF2F2` con tipografía carmesí `#DC2626` y borde sutil, eliminando los bloques negros aislados.
  - **Barra de Progreso HLTB:** El track de fondo de la barra de progreso de campaña ahora emplea un gris suave `#E4E4E7` en modo claro en lugar de la barra negra `#27272A`.

## [2.7.2] - 2026-08-26 (Light Mode Contrast Polish, Smart Sync & FAB Clearance)

### Fixed & Enhanced
- **Contraste y Legibilidad en Modo Claro (Anti-Slop):**
  - **Filtros y Chips:** Rediseñados los chips de estado (`Todos`, `Jugando`, `Por jugar`, `Jugado`) con fondo blanco `#FFFFFF`, borde sutil `#E4E4E7` y tipografía de alto contraste cuando no están seleccionados, eliminando cajas oscuras huérfanas en modo claro.
  - **Menús Desplegables (`Plataforma`, `Género`, `Orden`):** Migrados a tokens semánticos `AppColors`, mostrando fondos de superficie reactivos, bordes elegantes y texto oscuro (`#09090B`) con acento rojo `#DC2626` cuando están activos.
  - **Buscador en Biblioteca:** Corregido el color de texto del campo de búsqueda en el AppBar para mostrar texto oscuro sobre fondo claro en vez de blanco invisible.
  - **Hero Spotlight:** Contenedor superior adaptado con superficies suaves y bordes de acento para integrarse con naturalidad en temas claro y oscuro.
- **Paginación Centrada y Despeje de FAB (+ Añadir):**
  - **Resolución de Colisión:** Centrados los controles de navegación `< X / Y >` en la barra inferior mediante espaciadores elásticos (`Spacer`), incorporando una zona de seguridad lateral de 100px a la derecha. El botón flotante `+ Añadir` ya no colisiona ni oculta la flecha de página siguiente.
  - **Fondo de Barra Inferior:** Sustituido el fondo oscuro estático `#0D0D10` por `AppColors.surface(context)` con borde superior semántico.
- **Smart Sync & Optimización de Sincronización con Notion:**
  - **Chequeo Ultrarrápido (Head Check):** Antes de descargar todos los registros, la app consulta únicamente 1 registro remoto ordenado por `last_edited_time`. Si coincide con la marca de tiempo de la caché local, retorna de inmediato sin transferir cientos de registros innecesarios.
  - **Timeout HTTP de Seguridad:** Incorporado un límite estricto de 15 segundos en todas las llamadas de red (`http.get`, `http.post`, `http.patch`) para evitar que la app quede congelada o esperando indefinidamente.
- **Tarjeta Social Exportable Adaptativa (Modo Claro / Oscuro):**
  - La ventana modal de compartir y exportar reseña en PNG (`_showSocialCardDialog`) ahora detecta y adopta automáticamente el modo visual activo del usuario (Claro u Oscuro).
  - Se incorporó un conmutador interactivo `[ ☀️ Claro | 🌙 Oscuro ]` en la cabecera del modal que permite previsualizar y alternar el tema de la postal gráfica antes de exportar.
  - En modo claro, la tarjeta se renderiza con fondo blanco puro `#FFFFFF`, bordes zinc `#E4E4E7`, tipografía oscura `#09090B` y branding `#DC2626`. El archivo exportado se guarda automáticamente con el sufijo `_Light_` o `_Dark_` en la carpeta Descargas.
- **Logotipos de Plataformas de Alto Contraste & Multi-Modo:**
  - **Nintendo Switch:** Generado e implementado el nuevo icono 1:1 Joy-Con (`nintendo_switch_logo.png`) en rojo oficial (`#E60012`), resolviendo el problema de invisibilidad y distorsión que sufría el banner de texto 4:1 en modo oscuro y claro.
  - **Nintendo Retro (DS, Wii, N64):** Generada insignia 1:1 (`nintendo_badge_red.png`) en píldora roja con tipografía blanca nítida, 100% legible sobre fondos oscuros y claros.
  - **Xbox:** Generada esfera 1:1 (`xbox_logo_green.png`) en verde oficial `#107C10`, erradicando el logo negro plano que se perdía en temas oscuros.
  - **Steam / PC:** Corregido el mapeo de recursos para cargar el icono circular azul/blanco (`steam-logo-steam-icon-transparent-free-png.webp`) en vez del texto blanco plano que se camuflaba en modo claro.
  - **GOG & Epic Games:** Creados recursos optimizados (`gog_logo_purple.png` en púrpura oficial y `epic_games_logo_bordered.png` con contorno de escudo protector).
- **Selector de Tema en Pantalla de Conexión (`SetupScreen`):**
  - Incorporada la tarjeta de selección visual de tres opciones (`[ 🌙 Oscuro | ☀️ Claro | 🖥️ Sistema ]`) en la pantalla de conexión y edición de credenciales de Notion.
  - Conectado a `ThemeManager.instance` con reactividad instantánea al hacer clic en cualquiera de las opciones de tema.
  - Añadido soporte de barra superior con botón de regreso (`Navigator.pop`) y restricciones de ancho máximo (520px) para pantallas de escritorio.

---

## [2.7.1] - 2026-08-26 (Hotfix: Notion Page Creation & Build Stability)

### Fixed
- **Corrección de Error de Compilación en `SearchScreen`:**
  - Solucionado el error `The method 'createGame' isn't defined for the type 'NotionService'` en `search_screen.dart` restaurando la invocación canónica `await notion.createPage(notion.gamesDbId, properties)`.
  - Se implementó además el método helper `createGame(properties)` en `NotionService` para garantizar interoperabilidad completa y prevenir regresiones futuras en compilaciones CI de Windows/Linux.

---

## [2.7.0] - 2026-08-26 (Crisp Zinc Light Mode & Cross-App Theme Architecture)

### Added & Polished
- **Modo Claro "Crisp Zinc" (Light Mode):**
  - Integración completa de un tema claro elegante y de alto contraste (fondo `#FAFAFA`, superficies `#FFFFFF`, bordes sutiles `#E4E4E7`, texto `#09090B` y acento rojo Victor Engineer `#DC2626`).
  - Mantenimiento idéntico e intacto del **Modo Oscuro (Obsidian Zinc `#09090B`)**.
  - Toggle directo de 1 clic en la barra superior del `DashboardScreen` con iconos animados de sol/luna.
  - Selector de tema de 3 opciones en `SettingsScreen`: **Oscuro**, **Claro** y **Sistema** (sigue el SO).
  - Persistencia automática de la preferencia en `SharedPreferences` (`preferred_theme_mode`).
- **Arquitectura Centralizada de Color (`AppColors` & `ThemeManager`):**
  - Adaptación transversal en `DashboardScreen`, `AnalyticsScreen`, `GameDetailScreen`, `SearchScreen`, `SettingsScreen` y `SetupScreen`.
  - Degradados adaptativos, filtros, chips de géneros y diálogos que reaccionan instantáneamente sin reiniciar la app.
- **Renovación Completa de `SettingsScreen`:**
  - Sustitución de colores cian/magenta heredados por la paleta oficial Victor Engineer.
  - Tarjetas de estado de conexión, gestión de clave RAWG API, vaciado de caché y metadatos de versión.
- **Refinamiento de Búsqueda RAWG (`SearchScreen`):**
  - Diálogo modal y acordeón de géneros con estilos acordes al tema activo y acento rojo.

---

## [2.6.0] - 2026-08-26 (Definitive Release: Offline Cache, Dual View, Pagination & Gamification)

### Added
- **Caché Persistente Offline (0 ms Cold-Start):**
  - Implementación de almacenamiento serializado local mediante `SharedPreferences` en `NotionService`.
  - Carga inmediata de la biblioteca al iniciar la aplicación sin pantallas de carga previas y sincronización en background (*Stale-While-Revalidate*).
  - Indicador sutil de *"Modo Local"* en caso de falta de conexión a internet o latencia de Notion.
- **Selector de Vista Dual (Grid Cinematográfico vs. Lista Compacta):**
  - Toggle interactivo `[ ⊞ Grid | ☰ Lista ]` en la barra de herramientas del Dashboard con persistencia en disco.
  - Componente de alta densidad `_GameListRow`: miniatura redondeada de carátula (36x48), título en `Outfit`, badge temático de plataforma, estado, barra HLTB, estrellas y botón rápido `+1h`.
- **Sistema de Paginación Inteligente:**
  - Selector de tamaño de página: **10**, **25**, **50**, **100** o **Todos** persistido en memoria local.
  - Controles de navegación con botones estilizados `< Anterior`, indicador de página activa (`Página X de Y`) y `Siguiente >`.
  - Reseteo automático a página 1 al aplicar nuevos filtros o realizar búsquedas en tiempo real.
- **Gamificación Dinámica Multi-Año en Analíticas:**
  - Selector interactivo de año `< [Año] >` que recalcula el balance histórico y permite proyectar metas en años futuros (2025, 2026, 2027...).
  - Meta anual editable (`annual_game_goal_${year}`) con barra de progreso circular en `#DC2626` y badge de logro.
  - **Salón de la Fama / Récords Personales:**
    - 👑 *El Titán* (Juego completado con mayor tiempo acumulado).
    - ⭐ *Obra Maestra* (Juego con 5 estrellas y mayor dedicación).
    - ⚡ *Aventura Ágil* (Juego completado en menor tiempo).
  - Medidor de salud y tasa porcentual de finalización de biblioteca (*Backlog Health*).
- **Generador de Tarjeta Social / Reseña Exportable (PNG):**
  - Botón de exportación en la pantalla de detalle (`GameDetailScreen`).
  - Renderizado de tarjeta estilizada con squircle `VE`, título, plataforma, calificación en estrellas, horas jugadas, fecha de culminación y cita de reseña personal.
  - Captura en alta resolución mediante `RepaintBoundary` (2.5x pixel ratio) y guardado directo en la carpeta `Descargas` del usuario en Windows.

---

## [2.5.0] - 2026-08-25 (Fluid Motion & Microinteractions System)

### Added & Animated
- **Microinteracciones en Tarjetas de Juego (`_GameCard`):**
  - Efecto hover interactivo con escala suave (`1.035`), resplandor carmesí (`#DC2626` 0.22 opacity) y transición de borde en 220ms (`Curves.easeOutCubic`).
  - Respuesta táctil al toque (press down scale `0.97`) en 180ms.
- **Transiciones Cinematográficas Hero:**
  - Vuelo y acople fluido de portadas (`Hero(tag: 'game-cover-${id}')`) entre el grid de biblioteca y la pantalla de detalle (`GameDetailScreen`).
- **Entrada Escalonada del Grid (Staggered Animations):**
  - Cascada de entrada suave con fade-in y desplazamiento vertical (`16px -> 0px`) con curvas cúbicas calculadas por índice (`TweenAnimationBuilder`).
- **Pulsing Glow en Hero Spotlight:**
  - Animación continua de respiración luminosa para el punto de estado `JUGANDO AHORA` con `AnimationController`.
- **Barras de Progreso Animadas:**
  - Llenado progresivo de las barras de progreso HLTB en Dashboard y Game Detail con `TweenAnimationBuilder` (600ms `Curves.easeOutCubic`).
- **Navegación Fluida de Pantallas (`_buildFluidPageRoute`):**
  - Transición personalizada compartida con fade y deslizamiento suave (260ms) para Ficha, Búsqueda, Analíticas y Configuración.

---

## [2.4.0] - 2026-08-25 (Victor Engineer Signature Red - Anti-Slop Redesign)

### Added & Redesigned
- **Identidad de Marca Personal "Victor Engineer":** Adopción de la paleta y estilo oficial extraído de la web personal (`Homepage`).
- **Signature Red Accent (`#DC2626` / `#EF4444`):** Rojo de ingeniería aplicado como acento primario en botones de acción, barras de progreso, badges de "Jugando", indicadores y selectores activos.
- **Tipografía Oficial:** Integración de `Outfit` (`GoogleFonts.outfit`) para titulares y elementos de marca, junto a `Inter` (`GoogleFonts.inter`) para legibilidad técnica.
- **Isotipo Oficial "VE":** Cabecera de marca con el squircle rojo característico `VE` y tipografía bicolor `Victor` (Blanco) + `Engineer` (Rojo).
- **Tema Oscuro Obsidian Zinc:** Fondo `#09090B`, tarjetas `#121215`, y bordes de precisión `#27272A`.
- **Coherencia Transversal:** Actualización de `Dashboard`, `SetupScreen`, `GameDetailScreen`, `SearchScreen` y `AnalyticsScreen`.

---

## [2.3.0] - 2026-08-25 (Clean Unified Toolbar & Platform Helper)

### Added
- **Barra de Filtros Unificada (1 Sola Fila):** Eliminación de las dos filas apiladas por una barra horizontal limpia con tabs de estado y menús desplegables para Plataforma, Género y Orden.
- **Menú Desplegable de Plataformas:** Sustitución de la tira de 12+ chips por un selector estilizado con iconos temáticos y feedback visual de filtro activo.
- **Botón Rápido de Limpieza:** Botón dinámico `[ ✕ Limpiar ]` en la barra y en el estado vacío para restablecer todos los filtros con un toque.
- **Helper Global de Plataformas (`PlatformHelper`):** Unificación de iconos, paletas y badges temáticos de consolas para Dashboard, Ficha de Juego y Modal de Añadir.

---

## [2.2.0] - 2026-08-25 (Gamer Hub & Minimalist Branding)
### Added
- Nuevo isotipo minimalista con silueta de gamepad sobre squircle oscuro mate.
- Hero Spotlight "Jugando Ahora" interactivo con barra estática y botón rápido `+1h`.
- Menú contextual (Long Press) y microinteracciones de registro rápido (+30m, +1h, +2h).
- Ficha cinematográfica y calculadora de backlog en analíticas.

---

## [2.1.0] - 2026-08-25
### Added
- Modal avanzado de adición con DatePicker, horas iniciales y selector desplegable de géneros.
- Buscador en tiempo real en la biblioteca dentro del Dashboard.
- Soporte y workflow de compilación para Windows PC (Desktop).

---

## [2.0.0] - 2026-07-19 (Architecture Pivot: Notion Direct Cloud Database)

### Changed & Rebuilt
- **Migración Arquitectónica Mayor:**
  - Supresión definitiva de Supabase como backend intermediario.
  - Implementación de [`NotionService`](file:///c:/Users/vmesp/Documents/Cositas/App-Rastreador-de-Entretenimiento/frontend/lib/services/notion_service.dart) para comunicación directa con la API oficial de Notion (`2022-06-28`).
  - Integración de rate limiter estricto (máximo 3 req/s) con cola FIFO para respetar las cuotas de Notion.
- **Flujo de Configuración Inicial (`SetupScreen`):**
  - Asistente de vinculación de credenciales (Notion Internal Integration Token + Database ID de juegos).
- **Pipeline CI/CD:**
  - Automatización de compilación de APK en GitHub Actions (`build_apk.yml`).
- **Identidad Visual "Arcade Noir":**
  - Primera iteración en tema oscuro con cuadrícula de juegos, filtros básicos por estado y seguimiento de progreso.

---

## [1.0.0] - 2026-04-07 (Beta Release - Supabase MVP Architecture)

### Added
- **Integración con Supabase Backend:**
  - Autenticación de usuarios (registro, inicio de sesión y gestión de sesiones con Supabase Auth).
  - Persistencia de biblioteca de juegos en PostgreSQL alojado en Supabase.
- **Pantalla de Búsqueda de Videojuegos:**
  - Consulta a catálogo y adición de títulos a la biblioteca personal.
- **Dashboard de Analíticas:**
  - Gráficos de distribución de juegos por estado (`fl_chart`) y desglose de horas jugadas.
- **Despliegue Móvil Inicial:**
  - Configuración inicial de GitHub Actions para compilación automática de APKs de Android.

---

## [0.1.0] - 2026-04-07 (Alpha Prototype - Initial Scaffold)

### Added
- **Inicialización del Repositorio:**
  - Scaffold inicial del proyecto Flutter (`tracker_app`).
  - Estructura base de carpetas (`lib/models`, `lib/screens`, `lib/services`).
  - Definición inicial de entidades y modelos de datos para videojuegos.
  - Configuración de dependencias esenciales (`http`, `google_fonts`, `shared_preferences`).

