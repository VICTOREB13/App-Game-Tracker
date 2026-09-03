---
title: Checklist de Tareas Atómicas de Refactorización y Modularización (v3.2.0)
status: Completed
tags:
  - checklist
  - tasks
  - refactor
  - modularization
  - execution
agent: worker_planning_architect
project: App-Game-Tracker
version: v3.2.0
date: 2026-09-02
---

# 📋 Checklist de Tareas Atómicas de Refactorización y Modularización (v3.2.0)

**Proyecto:** App Game Tracker  
**Versión Objetivo:** v3.2.0  
**Estado:** Completed (100% Tasks Executed & Certified)  
**Referencias:** [[PRJ_App_Game_Tracker_implementation_plan|Plan de Implementación v3.2.0]], [[PRJ_App_Game_Tracker_project_overview|Visión General del Proyecto]], [[PRJ_App_Game_Tracker_audit_report_refactor|Informe de Auditoría]]

---

## 🧱 Fase 1: Poda Global de AI Slop y Consolidación de Fundamentos

- [x] **[TASK-P1-01] Creación y Centralización de `StatusHelper`**
  - **Asignado:** `(Backend-Architect)`
  - **Descripción:** Crear `frontend/lib/widgets/status_helper.dart` centralizando constantes de estado (`Jugando`, `Por jugar`, `Jugado`), colores (`0xFFDC2626`, `0xFFF59E0B`, `0xFF10B981`), iconos, pills y chips de estado. Reemplazar la lógica duplicada en `analytics_screen.dart`, `dashboard.dart`, `game_detail_screen.dart`, `game_card_grid.dart`, `game_card_list.dart`, `steam_sync_dialog.dart` y `search_screen.dart`.
  - **Criterio Cualitativo:** Cero duplicaciones de lógica de color/badge de estado en pantallas y widgets.
  - **Criterio Cuantitativo:** 7 archivos actualizados para consumir `StatusHelper`; archivo nuevo de ~70 LoC.

- [x] **[TASK-P1-02] Unificación de Plataformas y Géneros en `PlatformHelper` y `GenreHelper`**
  - **Asignado:** `(Backend-Architect)`
  - **Descripción:** Exponer `allPlatforms` y `canonicalize(String rawPlatform)` en `frontend/lib/widgets/platform_helper.dart`. Exponer `allGenres` en `frontend/lib/widgets/genre_helper.dart`. Eliminar la función `_canonicalPlatform` de 43 líneas en `search_screen.dart` y las listas de plataformas/géneros hardcodeadas en `game_detail_screen.dart` y `search_screen.dart`.
  - **Criterio Cualitativo:** Listas de dominio centralizadas y reutilizables en un único punto de verdad.
  - **Criterio Cuantitativo:** Eliminación de 43 líneas de matching ad-hoc en `search_screen.dart` y >50 líneas de listas hardcodeadas redundantes.

- [x] **[TASK-P1-03] Encapsulación de Regla de Auto-Culminación en `Game.applyPlaytimeProgress`**
  - **Asignado:** `(Backend-Architect)`
  - **Descripción:** Añadir el método inmutable `applyPlaytimeProgress({num? additionalHours, num? totalHours})` al modelo `frontend/lib/models/game.dart` para manejar transiciones automáticas a 'Jugado' (si supera HLTB) y a 'Jugando' (si parte de 'Por jugar' y alcanza >=1.0h). Actualizar las 6 ubicaciones que duplican esta lógica (`metadata_service.dart`, `steam_service.dart`, `settings_screen.dart`, `dashboard.dart`, `game_detail_screen.dart`, `search_screen.dart`).
  - **Criterio Cualitativo:** Regla de negocio de dominio aislada en el modelo de entidad `Game` con inmutabilidad garantizada.
  - **Criterio Cuantitativo:** 6 llamadas actualizadas a `applyPlaytimeProgress`; ~80 líneas de condicionales duplicados eliminadas.

- [x] **[TASK-P1-04] Centralización de Sanitización de Strings en `StringNormalizer`**
  - **Asignado:** `(Backend-Architect)`
  - **Descripción:** Añadir `sanitizeFilename(String name)` a `frontend/lib/services/string_normalizer.dart` y unificar los regex ad-hoc de limpieza de caracteres especiales y marcas registradas en `MetadataService` y `GameDetailScreen`.
  - **Criterio Cualitativo:** Uso consistente del servicio de normalización de cadenas.
  - **Criterio Cuantitativo:** Reemplazo de expresiones regulares manuales en al menos 3 ubicaciones.

- [x] **[TASK-P1-05] Enrutamiento de Búsqueda RAWG a través de `MetadataService`**
  - **Asignado:** `(Backend-Architect)`
  - **Descripción:** Implementar `MetadataService.searchRawgGames(String query, String rawgKey, {int pageSize = 15})` utilizando `ResilientHttpClient`. Eliminar la dependencia `import 'package:http/http.dart'` de `search_screen.dart`.
  - **Criterio Cualitativo:** Eliminación de llamadas HTTP crudas en vistas de UI, delegando en la capa de servicios con timeout y reintentos.
  - **Criterio Cuantitativo:** 0 llamadas directas a `http.get` en archivos de la carpeta `screens/`.

- [x] **[TASK-P1-06] Poda Global de AI Slop y Comentarios Didácticos**
  - **Asignado:** `(Backend-Architect)` / `(Frontend-UI)`
  - **Descripción:** Eliminar comentarios obvios de IA en todo `frontend/lib/` (ej. `// Title`, `// Rating`, `// Save button`, `// Actions`, `// RepaintBoundary Card`, anotaciones de nombres de color en `GenreHelper`). Mantener únicamente comentarios de diseño y docstrings útiles.
  - **Criterio Cualitativo:** Código limpio, profesional e idiomático en Dart sin explicaciones elementales.
  - **Criterio Cuantitativo:** Reducción de >250 líneas de comentarios triviales en el repositorio.

- [x] **[TASK-P1-07] Verificación de Calidad, Linter y Suites de Pruebas de Fase 1**
  - **Asignado:** `(Systems-Auditor)`
  - **Descripción:** Ejecutar análisis estático y linter para asegurar que no quede ningún error ni warning tras las refactorizaciones de la Fase 1. Corregir cualquier issue de linter, imports y campos no utilizados. Diseñar suites de pruebas unitarias y de widgets (`status_helper_test.dart`, `game_progress_test.dart`) certificando cobertura y determinismo offline al 100%.
  - **Criterio Cualitativo:** 100% de cumplimiento con las reglas estrictas de `analysis_options.yaml`, cero dependencias de red en pruebas y validación offline íntegra.
  - **Criterio Cuantitativo:** 0 errores, 0 warnings; 13 suites de pruebas automatizadas con 100% de éxito.

---

## 🎨 Fase 2: Modularización de Dashboard y Game Detail

- [x] **[TASK-P2-01] Extracción de `DashboardAppBar` (`widgets/dashboard/dashboard_app_bar.dart`)**
  - **Asignado:** `(Frontend-UI)`
  - **Descripción:** Extraer la barra de navegación superior de `dashboard.dart` a un `StatelessWidget` con `PreferredSizeWidget`. Manejar animación de búsqueda activa, monograma 'AGT', toggle de tema, spinner de sincronización de Steam y menú móvil vs botones de desktop.
  - **Criterio Cualitativo:** Componente de cabecera aislado y responsivo.
  - **Criterio Cuantitativo:** Archivo nuevo de ~180 LoC; reducción de ~280 LoC en `dashboard.dart`.

- [x] **[TASK-P2-02] Extracción de `DashboardFilterBar` (`widgets/dashboard/dashboard_filter_bar.dart`)**
  - **Asignado:** `(Frontend-UI)`
  - **Descripción:** Extraer los chips de estado (`StatusHelper`), dropdowns con badges de plataforma y género, selector de ordenamiento y botón para limpiar filtros. Soportar layout adaptativo de 2 filas en móvil y 1 fila en desktop.
  - **Criterio Cualitativo:** Barra de filtros totalmente desacoplada con callbacks declarativos.
  - **Criterio Cuantitativo:** Archivo nuevo de ~190 LoC; reducción de ~320 LoC en `dashboard.dart`.

- [x] **[TASK-P2-03] Extracción de `DashboardViewHeader` (`widgets/dashboard/dashboard_view_header.dart`)**
  - **Asignado:** `(Frontend-UI)`
  - **Descripción:** Extraer el subheader con el contador de juegos (`_filteredGames.length` / `_totalGamesCount`), chip de búsqueda activa, selector de vista dual (Grid/Lista) y controles de zoom de cuadrícula estilo explorador de Windows (`-`, popup menu de tamaños, `+`).
  - **Criterio Cualitativo:** Controles de vista y zoom desacoplados sin romper atajos de teclado o scroll zoom.
  - **Criterio Cuantitativo:** Archivo nuevo de ~140 LoC; reducción de ~240 LoC en `dashboard.dart`.

- [x] **[TASK-P2-04] Extracción de `QuickActionBottomSheet` (`widgets/dashboard/quick_action_bottom_sheet.dart`)**
  - **Asignado:** `(Frontend-UI)`
  - **Descripción:** Extraer el modal bottom sheet de acciones rápidas a una clase estática desacoplada con miniatura, título, horas jugadas, botones rápidos de estado (`StatusHelper`) y botón '+1h'.
  - **Criterio Cualitativo:** Modal completamente independiente invocable desde cualquier vista.
  - **Criterio Cuantitativo:** Archivo nuevo de ~140 LoC; reducción de ~170 LoC en `dashboard.dart`.

- [x] **[TASK-P2-05] Extracción de `DashboardSkeletonGrid` (`widgets/dashboard/dashboard_skeleton_grid.dart`)**
  - **Asignado:** `(Frontend-UI)`
  - **Descripción:** Extraer el widget de carga skeleton shimmer a un componente desacoplado en `widgets/dashboard/`.
  - **Criterio Cualitativo:** Placeholder de carga reutilizable.
  - **Criterio Cuantitativo:** Archivo nuevo de ~65 LoC; reducción de ~60 LoC en `dashboard.dart`.

- [x] **[TASK-P2-06] Consolidación y Refactorización Final de `DashboardScreen`**
  - **Asignado:** `(Frontend-UI)`
  - **Descripción:** Integrar los 5 componentes extraídos en `frontend/lib/screens/dashboard.dart`. Mantener únicamente el estado de ciclo de vida, consultas a `DatabaseService` y binding de eventos.
  - **Criterio Cualitativo:** Pantalla puramente orquestadora, legible y testeable.
  - **Criterio Cuantitativo:** `dashboard.dart` con **menos de 300 LoC** (objetivo: ~280 LoC).

- [x] **[TASK-P2-07] Extracción de `SocialCardDialog` y `SocialCardPreview` (`widgets/game_detail/`)**
  - **Asignado:** `(Frontend-UI)`
  - **Descripción:** Extraer el subsistema completo de tarjeta social (568 líneas) a `widgets/game_detail/social_card_dialog.dart` y `widgets/game_detail/social_card_preview.dart`. Preservar la captura de `RepaintBoundary` en PNG 2.5x, selector de tema Claro/Oscuro y guardado en carpeta de Descargas de Windows/Android.
  - **Criterio Cualitativo:** Subsistema de exportación gráfica 100% desacoplado de la pantalla de formulario.
  - **Criterio Cuantitativo:** Dos archivos nuevos (~220 y ~210 LoC); reducción de >560 LoC en `game_detail_screen.dart`.

- [x] **[TASK-P2-08] Extracción de `GameDetailHeader` (`widgets/game_detail/game_detail_header.dart`)**
  - **Asignado:** `(Frontend-UI)`
  - **Descripción:** Extraer el encabezado con portada difuminada en el fondo (backdrop blur), tarjeta Hero centralizada y badges de plataforma y estado (`StatusHelper`).
  - **Criterio Cualitativo:** Componente visual de cabecera aislado y estéticamente idéntico al original.
  - **Criterio Cuantitativo:** Archivo nuevo de ~110 LoC; reducción de ~130 LoC en `game_detail_screen.dart`.

- [x] **[TASK-P2-09] Extracción de `GameHltbProgressCard` (`widgets/game_detail/game_hltb_progress_card.dart`)**
  - **Asignado:** `(Frontend-UI)`
  - **Descripción:** Extraer la tarjeta de progreso contra HowLongToBeat con barra animada de progreso, hitos de duración (Campaña vs 100%) y badge dinámico de horas restantes.
  - **Criterio Cualitativo:** Componente visual de gamificación desacoplado.
  - **Criterio Cuantitativo:** Archivo nuevo de ~100 LoC; reducción de ~100 LoC en `game_detail_screen.dart`.

- [x] **[TASK-P2-10] Extracción de `GameGenreSelector` (`widgets/game_detail/game_genre_selector.dart`)**
  - **Asignado:** `(Frontend-UI)`
  - **Descripción:** Extraer el acordeón desplegable de géneros con animación de chevron, badge con contador de seleccionados y `Wrap` de `FilterChip` interactivos para los 30 géneros estándar provistos por `GenreHelper`.
  - **Criterio Cualitativo:** Componente de selección múltiple interactivo y limpio.
  - **Criterio Cuantitativo:** Archivo nuevo de ~130 LoC; reducción de ~150 LoC en `game_detail_screen.dart`.

- [x] **[TASK-P2-11] Extracción de `GameCoverPickerCard` y Unificación de URL**
  - **Asignado:** `(Frontend-UI)`
  - **Descripción:** Extraer a `widgets/game_detail/game_cover_picker_card.dart` el selector de archivo local mediante `FilePicker`, el copiado al directorio de portadas y el campo de URL web. Eliminar el campo de texto de URL duplicado que existía en el formulario.
  - **Criterio Cualitativo:** Gestión de portadas unificada y sin inputs duplicados en pantalla.
  - **Criterio Cuantitativo:** Archivo nuevo de ~110 LoC; eliminación del campo duplicado.

- [x] **[TASK-P2-12] Extracción de `GameDetailFormFields` y Consolidación de `GameDetailScreen`**
  - **Asignado:** `(Frontend-UI)`
  - **Descripción:** Extraer componentes de formulario (`GameSectionHeader`, `QuickHourButton`, `GameDropdownField`, `GameDatePickerField`) a `widgets/game_detail/game_detail_form_fields.dart`. Reensamblar `game_detail_screen.dart` integrando los 7 widgets extraídos.
  - **Criterio Cualitativo:** Pantalla de detalle desacoplada, legible y enfocada exclusivamente en el ciclo de vida y persistencia SQLite.
  - **Criterio Cuantitativo:** `game_detail_screen.dart` con **menos de 300 LoC** (objetivo: ~310 LoC).

---

## ⚙️ Fase 3: Modularización de Settings y Search

- [x] **[TASK-P3-01] Traslado de Bucles Masivos de Sincronización a `MetadataService`**
  - **Asignado:** `(Backend-Architect)`
  - **Descripción:** Trasladar la lógica iterativa de `_syncAllHltb` y `_syncAllMetadata` desde `settings_screen.dart` hacia `MetadataService.syncAllHltbGames()` y `MetadataService.syncAllGamesMetadata()`.
  - **Criterio Cualitativo:** Lógica de sincronización masiva desacoplada de la capa de presentación.
  - **Criterio Cuantitativo:** Reducción de >230 líneas de bucles de red en `settings_screen.dart`.

- [x] **[TASK-P3-02] Extracción de `SyncSummaryDialog` (`widgets/settings/sync_summary_dialog.dart`)**
  - **Asignado:** `(Frontend-UI)`
  - **Descripción:** Crear diálogo modal genérico y reutilizable para presentar resúmenes de sincronización (Steam, HLTB o RAWG), unificando los 3 diálogos alert idénticos presentes en `settings_screen.dart`.
  - **Criterio Cualitativo:** Unificación visual y estructural de alertas de sincronización.
  - **Criterio Cuantitativo:** Archivo nuevo de ~55 LoC; eliminación de ~100 LoC duplicadas.

- [x] **[TASK-P3-03] Extracción de `ImportBackupDialog` (`widgets/settings/import_backup_dialog.dart`)**
  - **Asignado:** `(Frontend-UI)`
  - **Descripción:** Extraer la clase privada `_ImportBackupDialog` (249 líneas) de `settings_screen.dart` a un componente modal independiente en `widgets/settings/`.
  - **Criterio Cualitativo:** Diálogo de importación de respaldos totalmente desacoplado y reutilizable.
  - **Criterio Cuantitativo:** Archivo nuevo de ~180 LoC; reducción de 249 LoC en `settings_screen.dart`.

- [x] **[TASK-P3-04] Extracción de Tarjetas Modulares de Ajustes (`widgets/settings/`)**
  - **Asignado:** `(Frontend-UI)`
  - **Descripción:** Extraer a `widgets/settings/`:
    - `settings_section_header.dart` (~25 LoC)
    - `theme_settings_card.dart` (~65 LoC)
    - `database_settings_card.dart` (~80 LoC)
    - `steam_settings_card.dart` (~110 LoC)
    - `rawg_settings_card.dart` (~70 LoC)
    - `hltb_settings_card.dart` (~70 LoC)
    - `backup_settings_card.dart` (~70 LoC)
    - `branding_footer.dart` (~50 LoC)
  - **Criterio Cualitativo:** Cada sección de ajustes encapsulada en su propio widget con responsabilidades claras.
  - **Criterio Cuantitativo:** 8 archivos de tarjetas modulares creados; reducción masiva del árbol de build en `settings_screen.dart`.

- [x] **[TASK-P3-05] Consolidación Final de `SettingsScreen`**
  - **Asignado:** `(Frontend-UI)`
  - **Descripción:** Reensamblar `frontend/lib/screens/settings_screen.dart` componiendo las tarjetas y diálogos extraídos.
  - **Criterio Cualitativo:** Pantalla de configuración concisa, declarativa y limpia.
  - **Criterio Cuantitativo:** `settings_screen.dart` con **menos de 220 LoC** (objetivo: ~200 LoC).

- [x] **[TASK-P3-06] Extracción de Componentes de Búsqueda (`widgets/search/`)**
  - **Asignado:** `(Frontend-UI)`
  - **Descripción:** Extraer a `widgets/search/`:
    - `search_bar_input.dart` (~60 LoC): Campo de búsqueda con icono, clear y spinner.
    - `search_empty_state.dart` (~30 LoC): Vista centrada con icono de gamepad.
    - `search_result_card.dart` (~85 LoC): Tarjeta individual de resultado con portada, tags y botón '+'.
    - `game_details_result.dart` (~25 LoC): Modelo tipado inmutable de resultado.
  - **Criterio Cualitativo:** Componentes de búsqueda desacoplados y reutilizables.
  - **Criterio Cuantitativo:** 4 archivos creados en `widgets/search/`.

- [x] **[TASK-P3-07] Extracción de `GameDetailsPromptDialog` (`widgets/search/game_details_prompt_dialog.dart`)**
  - **Asignado:** `(Frontend-UI)`
  - **Descripción:** Extraer la clase privada masiva `_GameDetailsPromptDialog` (664 líneas) a un modal desacoplado. Utilizar `PlatformHelper` para el selector de plataformas y `GenreHelper` para el acordeón de géneros.
  - **Criterio Cualitativo:** Diálogo de ingesta desacoplado y reutilizando helpers de dominio.
  - **Criterio Cuantitativo:** Archivo nuevo de ~240 LoC; reducción de 664 LoC en `search_screen.dart`.

- [x] **[TASK-P3-08] Consolidación Final de `SearchScreen`**
  - **Asignado:** `(Frontend-UI)`
  - **Descripción:** Reensamblar `frontend/lib/screens/search_screen.dart` integrando los 5 componentes de `widgets/search/` y enrutando la búsqueda a través de `MetadataService.searchRawgGames`.
  - **Criterio Cualitativo:** Pantalla de búsqueda ligera, reactiva y desacoplada de dependencias HTTP directas.
  - **Criterio Cuantitativo:** `search_screen.dart` con **menos de 220 LoC** (objetivo: ~180 LoC).

---

## 🛡️ Fase 4: Verificación Integral de Calidad y Cero Regresiones

- [x] **[TASK-P4-01] Creación de Nuevas Suites de Pruebas Unitarias y de Widgets**
  - **Asignado:** `(Systems-Auditor)` / `(Backend-Architect)` / `(Frontend-UI)`
  - **Descripción:** Implementar las suites de prueba para los componentes nuevos y helpers consolidados:
    - `frontend/test/status_helper_test.dart`
    - `frontend/test/game_progress_test.dart`
    - `frontend/test/widgets/settings_widgets_test.dart`
    - `frontend/test/widgets/search_widgets_test.dart`
    - `frontend/test/widgets/game_detail_widgets_test.dart`
  - **Criterio Cualitativo:** Cobertura de tests unitarios y de widgets para todos los componentes nuevos.
  - **Criterio Cuantitativo:** 5 archivos nuevos de pruebas pasando al 100%.

- [x] **[TASK-P4-02] Ejecución de la Batería Completa de Tests Automatizados (`flutter test`)**
  - **Asignado:** `(Systems-Auditor)`
  - **Descripción:** Ejecutar todas las pruebas existentes (11 suites) más las 5 nuevas suites.
  - **Criterio Cualitativo:** 100% de pruebas pasando sin fallos ni excepciones.
  - **Criterio Cuantitativo:** 16 suites de prueba con 100% de tasa de éxito.

- [x] **[TASK-P4-03] Análisis Estático Estricto (`flutter analyze`)**
  - **Asignado:** `(Systems-Auditor)`
  - **Descripción:** Ejecutar `flutter analyze --fatal-infos` en `frontend/` verificando cumplimiento de reglas linter estrictas.
  - **Criterio Cualitativo:** Código completamente conforme a las directrices de `analysis_options.yaml`.
  - **Criterio Cuantitativo:** 0 errores, 0 advertencias, 0 sugerencias.

- [x] **[TASK-P4-04] Medición y Validación Cuantitativa de Reducción de LoC**
  - **Asignado:** `(Systems-Auditor)`
  - **Descripción:** Medir y auditar las líneas de código finales en todas las pantallas y widgets:
    - `dashboard.dart`: < 300 LoC
    - `game_detail_screen.dart`: < 300 LoC
    - `settings_screen.dart`: < 220 LoC
    - `search_screen.dart`: < 220 LoC
    - Reducción neta global en pantallas: > 5,000 líneas extraídas hacia componentes modulares cohesivos.
  - **Criterio Cualitativo:** Cumplimiento estricto de los límites de tamaño por pantalla.
  - **Criterio Cuantitativo:** Todas las pantallas dentro de los límites establecidos.

- [x] **[TASK-P4-05] Generación del Informe de Auditoría y Quality Gate Sign-Off**
  - **Asignado:** `(Systems-Auditor)`
  - **Descripción:** Redactar el informe formal `artifacts/audit_reports/audit_report_refactor_v3.2.0.md` documentando todas las mediciones, pruebas ejecutadas y certificando `Status: PASS`.
  - **Criterio Cualitativo:** Documento formal de certificación para autorización de release.
  - **Criterio Cuantitativo:** Estado final `Status: PASS` emitido.

- [x] **[TASK-P4-06] Verificación de CI/CD y Preparación de Release v3.2.0**
  - **Asignado:** `(DevOps-Engineer)`
  - **Descripción:** Verificar la compatibilidad del pipeline `.github/workflows/ci.yml` y actualizar el changelog de versión `artifacts/planning/changelog_v1.md`.
  - **Criterio Cualitativo:** Repositorio en estado limpio y listo para despliegue/etiquetado v3.2.0.
  - **Criterio Cuantitativo:** Registro de cambios actualizado y verificado.
