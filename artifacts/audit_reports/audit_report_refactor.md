---
title: "Reporte de Auditoría Técnica: Descomposición de Monolitos, Poda de AI Slop y Plan de Modularización"
status: active
tags: [audit_report, systems-auditor, quality-gate, anti-slop, code-smell, monolith-refactor, flutter, v3.1.3, technical-debt, modularization]
agent: Systems-Auditor
date: 2026-09-02
version: v3.1.3
verdict: READY_FOR_REFACTOR
---

# 🛡️ Reporte de Auditoría Técnica: Diagnóstico Anti-Slop y Descomposición de Monolitos (v3.1.3)

**Documento emitido por:** Systems-Auditor (Quality Gatekeeper & Architectural Inspector)  
**Proyecto:** App Game Tracker  
**Objetivo:** Diagnóstico integral de deuda técnica, inventario cuantitativo de Líneas de Código (LoC), catálogo de "AI Slop" y duplicaciones, mapa anatómico de las 4 pantallas monolíticas y blueprint formal de extracción de componentes para la refactorización v3.2.0.  
**Modo de Ejecución:** Zero Production Modifications (Auditoría de Solo Lectura).

---

## 1. Resumen Ejecutivo (Executive Summary)

Se llevó a cabo una inspección arquitectónica y de calidad de código exhaustiva sobre la totalidad del código fuente de `frontend/lib/` (25 archivos, 12,646 líneas totales). El diagnóstico reveló una concentración crítica de complejidad en **4 pantallas monolíticas principales**:

1. `screens/game_detail_screen.dart` (**1,962 líneas** — 15.51% del codebase)
2. `screens/dashboard.dart` (**1,876 líneas** — 14.83% del codebase)
3. `screens/settings_screen.dart` (**1,455 líneas** — 11.51% del codebase)
4. `screens/search_screen.dart` (**1,162 líneas** — 9.19% del codebase)

Estos 4 archivos acumulan **6,455 líneas de código**, representando el **51.02% del volumen total de la aplicación**. Sumando la quinta pantalla (`screens/analytics_screen.dart` con 1,285 líneas), la capa de presentación alcanza el **61.20% de todo el código**.

### Principales Hallazgos Diagnósticos:
* **Fusión Antipatrón de UI y Negocio:** Las clases `State` de las pantallas acumulan lógica de integración con APIs externas (RAWG, Steam, Wikipedia, HLTB), mutaciones de persistencia SQLite, validaciones de formularios y algoritmos de transición de estado.
* **Modales Monolíticos Embebidos:** Cerca de **1,500 líneas** corresponden a clases de diálogos interactivos declaradas al pie de los archivos (`_GameDetailsPromptDialog` de 664 líneas en `search_screen.dart`, `_ImportBackupDialog` de 249 líneas en `settings_screen.dart`, `_showSocialCardDialog` de 568 líneas en `game_detail_screen.dart`, y `_showQuickActionMenu` de 136 líneas en `dashboard.dart`).
* **Bypass de la Capa de Servicios:** `search_screen.dart` ejecuta llamadas directas mediante `package:http/http.dart` (`http.get`), evadiendo `ResilientHttpClient` y `MetadataService`.
* **Multi-Duplicación de Lógica y Helpers:**
  * **Duplicación 7-way** del mapeo de colores de estados (`Jugando`, `Por jugar`, `Jugado`).
  * **Duplicación 6-way** de la lógica de auto-culminación / avance de estado por tiempo de juego.
  * Listas maestras de plataformas (15 items) y géneros (30 items) recreadas como arreglos locales en lugar de consumir `PlatformHelper` y `GenreHelper`.
  * Algoritmo de normalización de plataformas (`_canonicalPlatform`, 43 líneas) duplicado en `search_screen.dart`.
  * Expresiones regulares ad-hoc para limpieza de títulos en lugar de utilizar `StringNormalizer.cleanTitle`.
* **Presencia Extensiva de "AI Slop":** Se contabilizaron **46 bloques prominentes de comentarios didácticos y obvios** generados por IA (por ejemplo: `// Save button`, `// Title`, `// Dates Section`, `// Monogram & Title`, y comentarios de marketing sobre "60 FPS").

**Veredicto de Calidad:** `READY_FOR_REFACTOR`. La arquitectura base es sólida, con 11 suites de pruebas automatizadas y linter estricto al 100%, pero requiere la modularización inmediata de las pantallas para restaurar la mantenibilidad y desacoplar componentes.

---

## 2. Inventario Exhaustivo de Líneas de Código (LoC Baseline)

Medición estricta de las 25 unidades de código en `frontend/lib/`, categorizadas por líneas de código (SLOC), comentarios y líneas en blanco:

| N° | Ruta Relativa | Líneas Totales | Líneas de Código (SLOC) | Líneas de Comentarios | Líneas en Blanco | % del Codebase | Clasificación Arquitectónica |
| :---: | :--- | :---: | :---: | :---: | :---: | :---: | :--- |
| **1** | `screens/game_detail_screen.dart` | **1,962** | 1,854 | 33 | 75 | **15.51%** | 🚨 **Monolito Crítico Nivel 1** |
| **2** | `screens/dashboard.dart` | **1,876** | 1,792 | 14 | 70 | **14.83%** | 🚨 **Monolito Crítico Nivel 2** |
| **3** | `screens/settings_screen.dart` | **1,455** | 1,368 | 11 | 76 | **11.51%** | 🚨 **Monolito Crítico Nivel 3** |
| **4** | `screens/analytics_screen.dart` | **1,285** | 1,216 | 23 | 46 | **10.16%** | ⚠️ Pantalla Compleja (Visualización) |
| **5** | `screens/search_screen.dart` | **1,162** | 1,103 | 11 | 48 | **9.19%** | 🚨 **Monolito Crítico Nivel 4** |
| **6** | `services/steam_service.dart` | 629 | 501 | 51 | 77 | 4.97% | Servicio Externo (Steam Web API) |
| **7** | `models/game.dart` | 436 | 398 | 11 | 27 | 3.45% | Modelo de Dominio (Sentinel Pattern) |
| **8** | `widgets/filter_modal_sheet.dart` | 385 | 352 | 10 | 23 | 3.04% | Widget de Filtrado Modal |
| **9** | `services/database_service.dart` | 314 | 257 | 20 | 37 | 2.48% | Capa de Persistencia SQLite |
| **10** | `widgets/dashboard/game_card_grid.dart` | 307 | 287 | 9 | 11 | 2.43% | Componente Modular Dashboard |
| **11** | `widgets/dashboard/steam_sync_dialog.dart` | 285 | 271 | 3 | 11 | 2.25% | Componente Modal Dashboard |
| **12** | `services/theme_manager.dart` | 269 | 241 | 10 | 18 | 2.13% | Gestor de Estado (Theming) |
| **13** | `services/hltb_service.dart` | 265 | 213 | 15 | 37 | 2.10% | Servicio Externo (HowLongToBeat) |
| **14** | `widgets/dashboard/hero_spotlight_card.dart` | 254 | 238 | 9 | 7 | 2.01% | Componente Modular Dashboard |
| **15** | `services/secure_storage_service.dart` | 254 | 178 | 44 | 32 | 2.01% | Almacenamiento Criptográfico |
| **16** | `services/metadata_service.dart` | 230 | 196 | 9 | 25 | 1.82% | Servicio de Enriquecimiento |
| **17** | `widgets/dashboard/game_card_list.dart` | 225 | 208 | 6 | 11 | 1.78% | Componente Modular Dashboard |
| **18** | `services/backup_service.dart` | 216 | 175 | 13 | 28 | 1.71% | Portabilidad y Backup JSON |
| **19** | `widgets/dashboard/pagination_control_bar.dart` | 170 | 153 | 7 | 10 | 1.34% | Componente Modular Dashboard |
| **20** | `services/resilient_http_client.dart` | 165 | 144 | 6 | 15 | 1.30% | Cliente HTTP Resiliente |
| **21** | `widgets/platform_helper.dart` | 137 | 130 | 0 | 7 | 1.08% | Helper de Plataformas y Colores |
| **22** | `widgets/genre_helper.dart` | 130 | 115 | 5 | 10 | 1.03% | Helper de Géneros y Colores |
| **23** | `services/string_normalizer.dart` | 98 | 70 | 10 | 18 | 0.78% | Utilidad de Normalización de Texto |
| **24** | `widgets/app_cover_image.dart` | 95 | 85 | 4 | 6 | 0.75% | Componente de Imagen con Fallbacks |
| **25** | `main.dart` | 42 | 31 | 3 | 8 | 0.33% | Entrypoint de la Aplicación |
| **TOTAL** | **`frontend/lib/` (25 archivos)** | **12,646** | **11,842** | **367** | **437** | **100.00%** | — |

### Resumen del Top 4 Monolitos:
* **Líneas Totales del Top 4:** **6,455 líneas**
* **Porcentaje del Total del Proyecto:** **51.02%**
* **Meta de Reducción:** Pasar de 6,455 líneas combinadas a **< 1,000 líneas** entre las 4 pantallas principales (**-84.5% de reducción** en los archivos de pantalla mediante extracción modular limpia).

---

## 3. Anatomía Detallada de las 4 Pantallas Monolíticas

### 3.1 `screens/dashboard.dart` (1,876 líneas)

```
screens/dashboard.dart (1,876 líneas)
├── Imports (Líneas 1-25)
├── Declaración del Widget: DashboardScreen (Líneas 26-31)
└── _DashboardScreenState (Líneas 33-1876) [State with SingleTickerProviderStateMixin]
    ├── Variables de Estado y Controladores (Líneas 35-66)
    │   ├── _searchController, _pulseController
    │   ├── _filteredGames, _heroGame, _totalGamesCount
    │   ├── _isLoading, _isRefreshing, _isSearchActive, _searchQuery
    │   ├── _selectedStatusFilter, _selectedPlatformFilter, _selectedGenreFilter, _selectedSort
    │   ├── _cachedPlatformOptions, _cachedGenreOptions
    │   └── _isGridView, _currentPage, _pageSize, _gridCardExtent, _statusFilters
    ├── Ciclo de Vida y Métricas de Rejilla (Líneas 68-150)
    │   ├── initState() & _loadPreferencesAndFetch()
    │   ├── _updateGridCardExtent(double) & _getCardSizeLabel(double)
    │   └── _buildSizeMenuItem(double, String, IconData), dispose()
    ├── Transición de Rutas Fluidas Inlined (Líneas 152-175)
    │   └── _buildFluidPageRoute<T>(Widget page)
    ├── Agregación y Consultas de Datos (Líneas 176-317)
    │   ├── _fetchFilterMetadata() (78 líneas de cálculo de badges de plataformas y géneros)
    │   └── _fetchGames({bool forceRefresh, bool userInitiated}) (63 líneas con consulta SQL directa)
    ├── Getters de Vista y Acciones de Filtro (Líneas 318-372)
    │   ├── _toggleViewMode(), _changePageSize(int)
    │   ├── _totalPages, _paginatedGames, _activeFiltersCount, _isAnyFilterActive
    │   └── _clearAllFilters()
    ├── Sincronización Externa de Steam (Líneas 373-418)
    │   └── _syncWithSteam() (46 líneas con SharedPreferences y SteamSyncDialog)
    ├── Mutaciones Rápidas de Dominio (Líneas 419-514)
    │   ├── _quickAddHours(Game, num) (55 líneas con regla duplicada de HLTB)
    │   └── _quickChangeStatus(Game, String) (40 líneas con actualización SQLite)
    ├── Modal Bottom Sheet Embebido (Líneas 515-690) (175 líneas)
    │   ├── _showQuickActionMenu(Game) (136 líneas de modal)
    │   └── _buildStatusQuickButton(Game, String, Color) (34 líneas)
    ├── Árbol Principal Scaffold & Build (Líneas 691-1532) (841 líneas)
    │   ├── AppBar con búsqueda animada y monograma (Líneas 699-794)
    │   ├── AppBar Actions (Líneas 795-988: 193 líneas bifurcando mobile PopupMenu vs desktop buttons)
    │   ├── Montaje de Hero Spotlight Card (Líneas 993-1008)
    │   ├── Responsive Filter Toolbar (Líneas 1010-1076: layout de 2 filas en móvil vs 1 en desktop)
    │   ├── Subheader: Contador de juegos y zoom de tarjetas Windows-style (Líneas 1078-1317: 240 líneas)
    │   ├── Main Grid/List View con animaciones escalonadas y zoom Ctrl+Scroll (Líneas 1319-1485)
    │   ├── Montaje de PaginationControlBar (Líneas 1488-1496)
    │   └── FloatingActionButton responsivo (Líneas 1499-1531)
    ├── Métodos Helper de Filtro Inlined (Líneas 1534-1815) (281 líneas)
    │   ├── _buildFilterChip(String) (57 líneas con mapeo manual de colores)
    │   ├── _buildPlatformFilterButton() (69 líneas)
    │   ├── _buildGenreFilterButton() (69 líneas)
    │   ├── _buildSortDropdown() (44 líneas)
    │   └── _buildClearFiltersButton() (35 líneas)
    └── Skeleton de Carga Inlined (Líneas 1817-1875) (58 líneas)
        └── _buildSkeletonGrid()
```

---

### 3.2 `screens/game_detail_screen.dart` (1,962 líneas)

```
screens/game_detail_screen.dart (1,962 líneas)
├── Imports (Líneas 1-19)
├── Declaración del Widget: GameDetailScreen (Líneas 20-26)
└── _GameDetailScreenState (Líneas 28-1962)
    ├── Variables de Estado, Controladores y Listas Fijas (Líneas 29-73)
    │   ├── _socialCardKey, _isExporting, _isFetchingHltb, _isSearchingWiki
    │   ├── 7 TextEditingControllers (_title, _hours, _hltbMain, _hltbComp, _coverUrl, _summary, _link)
    │   ├── _selectedStatus, _selectedPlatform, _selectedRating, _selectedGenres
    │   ├── _startDate, _completedDate, _isSaving, _isGenreAccordionExpanded
    │   └── Listas Hardcodeadas: _statuses (3), _platforms (15), _ratings (6), _allGenres (30)
    ├── Ciclo de Vida (Líneas 74-134)
    │   ├── initState() (Configura 7 controladores y fallback matching de plataformas)
    │   └── dispose() (Libera 7 controladores)
    ├── Servicios de Integración & Media (Líneas 135-295)
    │   ├── _fetchHltbData() (57 líneas interactuando con HltbService)
    │   ├── _fetchWikipediaLink() (44 líneas interactuando con MetadataService)
    │   └── _pickLocalImage() (57 líneas con FilePicker y copiado manual a Documents/covers)
    ├── Mutadores de Tiempo y Fechas (Líneas 296-350)
    │   ├── _addQuickHours(double) (26 líneas con validación duplicada de HLTB)
    │   └── _selectDate(BuildContext, bool) (27 líneas con showDatePicker y tema oscuro)
    ├── Handlers de Persistencia CRUD (Líneas 351-482)
    │   ├── _saveChanges() (74 líneas con validación, auto-status y SQLite update)
    │   └── _deleteGame() (54 líneas con AlertDialog inlined y SQLite delete)
    ├── Árbol Principal Scaffold & Formulario (Líneas 483-1223) (740 líneas)
    │   ├── AppBar con botón de Social Card y botón de eliminación (Líneas 492-514)
    │   ├── Body ScrollView (Líneas 515-1221):
    │   │   ├── Cinematic Cover Backdrop & Hero Cover Card (Líneas 523-600)
    │   │   ├── Campo Redundante 1 de Cover URL (Líneas 602-613)
    │   │   ├── Title TextField (Líneas 616-626)
    │   │   ├── Status & Platform Dropdowns (Líneas 628-660)
    │   │   ├── Rating Dropdown (Líneas 663-669)
    │   │   ├── Horas Jugadas + Botones Rápidos +30m/+1h/+2h (Líneas 671-698)
    │   │   ├── HLTB Progress Card interactiva (Líneas 700-791)
    │   │   ├── Fechas de Inicio y Finalización (Líneas 793-817)
    │   │   ├── Acordeón de Géneros con 30 FilterChips (Líneas 819-964: 145 líneas)
    │   │   ├── Resumen / Notas Personales TextField (Líneas 966-975)
    │   │   ├── Personalizador de Portada: Selector de Disco y URL Web (Líneas 977-1075: 98 líneas)
    │   │   ├── Campo de Wikipedia con botón de búsqueda (Líneas 1078-1125: 47 líneas)
    │   │   ├── Sección de Ajustes HLTB Historia/100% (Líneas 1127-1185: 58 líneas)
    │   │   └── Botón de Guardar Cambios (Líneas 1188-1221: 34 líneas)
    ├── Helpers de Renderizado de Formularios (Líneas 1225-1393)
    │   ├── _buildQuickHourButton(String, double), _buildSectionHeader(String)
    │   ├── _buildStatusPill(String), _buildDropdown(), _buildDatePicker()
    └── Subsistema Completo de Social Card (Líneas 1395-1962) (568 líneas)
        ├── _showSocialCardDialog() (233 líneas: diálogo con StatefulBuilder y selector de tema)
        ├── _buildSocialCardPreview({required bool isDark}) (273 líneas de diseño visual de la tarjeta)
        └── _exportSocialCard({bool isDark}) (58 lines: RenderRepaintBoundary a PNG a disco)
```

---

### 3.3 `screens/settings_screen.dart` (1,455 líneas)

```
screens/settings_screen.dart (1,455 líneas)
├── Imports (Líneas 1-14)
├── Declaración del Widget y Estado (Líneas 15-48)
│   ├── Controladores: _rawgKeyController, _steamKeyController, _steamIdController
│   └── Flags: _isTestingSteam, _isSyncingSteam, _isSyncingHltb, _isSyncingMetadata
├── Métodos Asíncronos de Negocio y Bucles de Sincronización (Líneas 49-500) (451 líneas)
│   ├── _loadSettings() [Líneas 49-67] - SharedPreferences, recuento SQLite, SecureStorage
│   ├── _saveRawgKey() & _saveSteamSettings() [Líneas 69-93]
│   ├── _testSteamConnection() & _resolveSteamVanity() [Líneas 95-166]
│   ├── _syncSteam() [Líneas 168-252] - Bucle + AlertDialog inlined de 48 líneas
│   ├── _syncAllHltb() [Líneas 254-356] - Bucle masivo (102 líneas) + AlertDialog inlined de 31 líneas
│   ├── _syncAllMetadata() [Líneas 358-486] - Bucle masivo (128 líneas) + AlertDialog inlined de 33 líneas
│   └── _optimizeDatabase() [Líneas 488-500] - Ejecución de SQLite VACUUM
├── Árbol Principal Scaffold & Secciones (Líneas 501-1051) (550 líneas)
│   ├── Scaffold & AppBar [Líneas 503-515]
│   ├── Sección 1: Selector de Tema (Dark / Light / System) [Líneas 523-580]
│   ├── Sección 2: Tarjeta de Almacenamiento Local SQLite [Líneas 583-665]
│   ├── Sección 3: Tarjeta de Configuración y Sincronización Steam [Líneas 668-750]
│   ├── Sección 4: Tarjeta de API Key RAWG [Líneas 753-817]
│   ├── Sección 5: Tarjeta de HowLongToBeat Bulk Sync [Líneas 820-900]
│   ├── Sección 6: Tarjeta de Respaldo y Portabilidad JSON [Líneas 903-975]
│   └── Sección 7: Branding Oficial Victor Engineer [Líneas 978-1048]
├── Builders Auxiliares y Handlers de Importación (Líneas 1054-1204)
│   ├── _buildSectionHeader() & _buildThemeOption()
│   ├── _exportBackup(), _showImportDialog()
│   └── _processFileImport() & _processJsonStringImport()
└── Modal Monolítico Embebido: _ImportBackupDialog (Líneas 1206-1455) (249 líneas)
    ├── Botón de selección mediante FilePicker
    ├── Botón para inyectar dataset de ejemplo (`sample_games_library.json`)
    ├── Selector de descargas recientes (hasta 3 copias de seguridad)
    └── Área de entrada de texto para JSON sin procesar o ruta local
```

---

### 3.4 `screens/search_screen.dart` (1,162 líneas)

```
screens/search_screen.dart (1,162 líneas)
├── Imports (Líneas 1-16) - Importación directa de 'package:http/http.dart'
├── Constantes Locales y Algoritmo de Normalización (Líneas 25-91)
│   ├── _allAvailableGenres: 30 cadenas de texto fijas [Líneas 30-37]
│   ├── _availablePlatforms: 15 cadenas de texto fijas [Líneas 39-46]
│   └── _canonicalPlatform(String raw): 43 líneas de coincidencia condicional [Líneas 48-90]
├── Handlers Asíncronos de Búsqueda e Ingesta (Líneas 92-268)
│   ├── _loadRawgKey() [Líneas 104-106]
│   ├── _searchGames(String query) [Líneas 108-144] - Llamada directa raw http.get
│   ├── _promptGameDetails() [Líneas 146-167] - Invocación modal
│   └── _addGameToLibrary() [Líneas 169-268] - Enriquecimiento secuencial + auto-culminación + SQLite insert
├── Árbol Principal Scaffold & Resultados (Líneas 270-480) (210 líneas)
│   ├── Scaffold & AppBar [Líneas 272-284]
│   ├── Campo de Búsqueda con Prefijo y Sufijo [Líneas 291-330]
│   ├── Empty State View con icono de Gamepad [Líneas 333-352]
│   └── ListView de Resultados [Líneas 353-473] - Tarjeta inline de 120 líneas
├── Modelo de Datos de Ingesta (Líneas 482-496)
│   └── _GameDetailsResult (status, platform, startDate, hoursPlayed, genres)
└── Modal Monolítico Masivo: _GameDetailsPromptDialog (Líneas 498-1162) (664 líneas)
    ├── Extracción de plataformas y géneros de RAWG en initState() [Líneas 533-572]
    ├── Encabezado de Juego (Portada, Título, Año, Estimación HLTB) [Líneas 598-674]
    ├── Formulario Desplazable de Ingesta [Líneas 685-1113]:
    │   ├── Estado y Horas Jugadas [Líneas 686-770]
    │   ├── Selector de Fecha de Inicio [Líneas 774-831]
    │   ├── Selector Wrap de Plataforma (+ Switch de Recomendadas) [Líneas 834-983: 149 líneas]
    │   └── Acordeón de Géneros con FilterChips [Líneas 986-1110: 124 líneas]
    └── Acciones de Diálogo (Cancelar y Agregar a Biblioteca) [Líneas 1117-1156]
```

---

## 4. Catálogo Detallado de AI Slop, Redundancias y Sobre-Ingeniería

### 4.1 Duplicación 7-Way del Mapeo de Colores de Estado

La asignación de color según el estado (`Jugando` -> `0xFFDC2626` / Rojo, `Por jugar` -> `0xFFF59E0B` / Ámbar, `Jugado` -> `0xFF10B981` / Esmeralda) se encuentra copiada textualmente en 7 archivos:

1. `frontend/lib/screens/analytics_screen.dart`: Líneas 76–87 (`_getStatusColor`)
2. `frontend/lib/screens/dashboard.dart`: Líneas 1538–1550 (`_buildFilterChip`)
3. `frontend/lib/screens/game_detail_screen.dart`: Líneas 1268–1281 (`_buildStatusPill`)
4. `frontend/lib/widgets/dashboard/game_card_grid.dart`: Líneas 35–48
5. `frontend/lib/widgets/dashboard/game_card_list.dart`: Líneas 37–50
6. `frontend/lib/widgets/dashboard/steam_sync_dialog.dart`: Líneas 100–110
7. `frontend/lib/screens/search_screen.dart`: Líneas 855–875

```dart
// Patrón duplicado en los 7 archivos:
Color getStatusColor(String status) {
  switch (status) {
    case 'Jugando': return const Color(0xFFDC2626);
    case 'Por jugar': return const Color(0xFFF59E0B);
    case 'Jugado': return const Color(0xFF10B981);
    default: return const Color(0xFF6B7280);
  }
}
```
**Solución Requerida:** Centralizar en `widgets/status_helper.dart` o en el modelo `GameStatus`.

---

### 4.2 Duplicación 6-Way de la Lógica de Auto-Culminación y Transición de Estados

La regla de dominio de actualización automática de estado por tiempo de juego está duplicada en 6 puntos distintos de la aplicación:
1. `services/metadata_service.dart`: Líneas 167–174
2. `services/steam_service.dart`: Líneas 374–389
3. `screens/settings_screen.dart`: Líneas 292–300
4. `screens/dashboard.dart`: Líneas 426–435
5. `screens/game_detail_screen.dart`: Líneas 306–312 y Líneas 365–376 (duplicada 2 veces en el mismo archivo)
6. `screens/search_screen.dart`: Líneas 215–221

```dart
// Lógica de negocio dispersa en controladores UI:
if (game.hltbMain != null && game.hltbMain! > 0 && newHours >= game.hltbMain! && game.status != 'Jugado') {
  finalStatus = 'Jugado';
  finalCompleted ??= DateTime.now();
} else if (game.status == 'Por jugar' && newHours >= 1.0) {
  finalStatus = 'Jugando';
  finalStartDate ??= DateTime.now();
}
```
**Solución Requerida:** Encapsular como método puro en el modelo de dominio: `Game.applyPlaytimeProgress(num newHours)`.

---

### 4.3 Listas Fijas Duplicadas de Plataformas y Géneros

A pesar de existir `widgets/platform_helper.dart` y `widgets/genre_helper.dart`, los listados maestros fueron re-declarados de forma estática en las clases State:
* `screens/game_detail_screen.dart`: Líneas 52–59 (`_platforms`, 15 items) y Líneas 65–72 (`_allGenres`, 30 items).
* `screens/search_screen.dart`: Líneas 39–46 (`_availablePlatforms`, 15 items) y Líneas 30–37 (`_allAvailableGenres`, 30 items).

**Solución Requerida:** Exponer `PlatformHelper.allPlatforms` y `GenreHelper.allGenres` como constantes inmutables canónicas.

---

### 4.4 Duplicación de Normalización de Plataformas (43 Líneas)

En `screens/search_screen.dart` (Líneas 48–90), la función `_canonicalPlatform(String raw)` contiene 15 sentencias `if (lower.contains(...))` para mapear plataformas de RAWG a los identificadores de la app, ignorando `PlatformHelper`.

**Solución Requerida:** Mover `canonicalize(String raw)` a `PlatformHelper`.

---

### 4.5 Limpieza Ad-hoc con Expresiones Regulares vs `StringNormalizer.cleanTitle`

Se identificó la re-implementación manual de reemplazo de caracteres y marcas registradas en lugar de consumir `StringNormalizer.cleanTitle`:
* `services/metadata_service.dart`: Líneas 31 y 95 (`.replaceAll(RegExp(r'[™®©]'), '').replaceAll(RegExp(r'\s+'), ' ').trim()`).
* `screens/game_detail_screen.dart`: Línea 1924 (`.replaceAll(RegExp(r'[^\w\s-]'), '').replaceAll(' ', '_')`).

**Solución Requerida:** Unificar todas las rutinas de sanitización bajo `StringNormalizer`.

---

### 4.6 Bypass de la Capa de Red en `SearchScreen`

En `screens/search_screen.dart` (Líneas 4–5 y 108–144), se realiza un `http.get` directo sin:
* Gestión de timeouts ni User-Agent estandarizado.
* Reintentos con retroceso exponencial ante errores HTTP 429/503.
* Aislamiento en la capa de servicios.

**Solución Requerida:** Trasladar la búsqueda de juegos de RAWG a `MetadataService.searchRawg(query, apiKey)` utilizando `ResilientHttpClient`.

---

### 4.7 Modales Monolíticos Embebidos (~1,500 Líneas)

Cuatro modales gigantes residen como clases o métodos privados dentro de los archivos de pantalla:
1. `_GameDetailsPromptDialog` (`screens/search_screen.dart:498-1162`): **664 líneas** dedicadas al modal de ingesta de juegos.
2. Subsistema Social Card (`screens/game_detail_screen.dart:1395-1962`): **568 líneas** que combinan diálogo interactivo, vista previa y exportación RepaintBoundary a PNG.
3. `_ImportBackupDialog` (`screens/settings_screen.dart:1206-1455`): **249 líneas** con selector FilePicker, inyección de fixtures y lectura de JSON.
4. `_showQuickActionMenu` (`screens/dashboard.dart:515-690`): **175 líneas** de modal bottom sheet con botones de horas y estado.

**Solución Requerida:** Extraer cada modal a su propio archivo dentro del subdirectorio correspondiente en `widgets/`.

---

### 4.8 Catálogo de Comentarios Didácticos y Obvios de IA (46 Instancias)

Comentarios redundantes que saturan el código explicando sintaxis obvia de Flutter:

| Archivo | Línea | Comentario Verbatim | Diagnóstico de Slop |
| :--- | :---: | :--- | :--- |
| `dashboard.dart` | 50 | `// Opciones de filtro cacheadas para alto rendimiento en 60 FPS` | Comentario didáctico / marketing |
| `dashboard.dart` | 54 | `// Dual View & Pagination & Card Sizing (Estilo Explorador de Windows)` | Comentario explicativo superfluo |
| `dashboard.dart` | 183 | `// Hero game (primer juego con estado 'Jugando')` | Explicación evidente de asignación |
| `dashboard.dart` | 187 | `// Conteo de plataformas` | Etiqueta de código autoevidente |
| `dashboard.dart` | 210 | `// Conteo de géneros normalizados` | Etiqueta de código autoevidente |
| `dashboard.dart` | 445 | `// Actualización optimista de UI` | Comentario superfluo de gestión de estado |
| `dashboard.dart` | 992 | `// Hero Spotlight "Jugando Ahora"` | Etiqueta obvia de sección visual |
| `dashboard.dart` | 1010 | `// Toolbar de Filtros (Responsive: 2 filas en Mobile, 1 fila en Desktop)` | Comentario de layout evidente |
| `dashboard.dart` | 1078 | `// Subheader: contador de juegos y switch Grid/Lista` | Etiqueta de widget obvia |
| `dashboard.dart` | 1122 | `// Dual View Mode Switcher` | Etiqueta de widget obvia |
| `dashboard.dart` | 1319 | `// Main View: GridView / ListView con animación escalonada y soporte de zoom...` | Comentario narrativo verboso |
| `dashboard.dart` | 1487 | `// Barra de Paginación Desacoplada` | Etiqueta de widget obvia |
| `game_detail_screen.dart` | 250 | `// Directorio interno persistente de portadas` | Comentario evidente |
| `game_detail_screen.dart` | 364 | `// 1. Auto-culminación si horas superan HLTB` | Pseudocódigo numerado en producción |
| `game_detail_screen.dart` | 372 | `// 2. Transición a 'Jugando' si estaba 'Por jugar' y alcanza >= 1.0h` | Pseudocódigo numerado en producción |
| `game_detail_screen.dart` | 523 | `// Cinematic Header with Cover Backdrop & Image` | Comentario de estilo evidente |
| `game_detail_screen.dart` | 527 | `// Backdrop blur container` | Etiqueta de widget obvia |
| `game_detail_screen.dart` | 559 | `// Centered Main Cover Card with Hero animation` | Etiqueta de widget obvia |
| `game_detail_screen.dart` | 602 | `// Cover URL Input` | Etiqueta de campo de formulario obvia |
| `game_detail_screen.dart` | 615 | `// Title` | Etiqueta de campo de formulario obvia |
| `game_detail_screen.dart` | 628 | `// Status & Platform row` | Etiqueta de layout obvia |
| `game_detail_screen.dart` | 662 | `// Rating` | Etiqueta de campo obvia |
| `game_detail_screen.dart` | 671 | `// Hours Played & Quick Action Buttons` | Etiqueta de layout obvia |
| `game_detail_screen.dart` | 690 | `// Quick +buttons` | Etiqueta de layout obvia |
| `game_detail_screen.dart` | 700 | `// HLTB Progress Card if available` | Etiqueta de layout obvia |
| `game_detail_screen.dart` | 793 | `// Dates Section` | Etiqueta de layout obvia |
| `game_detail_screen.dart` | 819 | `// Genres Collapsible Section` | Etiqueta de layout obvia |
| `game_detail_screen.dart` | 966 | `// Summary` | Etiqueta de campo obvia |
| `game_detail_screen.dart` | 977 | `// Cover Image Customizer` | Etiqueta de layout obvia |
| `game_detail_screen.dart` | 1078 | `// Link / Wikipedia` | Etiqueta de layout obvia |
| `game_detail_screen.dart` | 1127 | `// HLTB Settings Section` | Etiqueta de layout obvia |
| `game_detail_screen.dart` | 1187 | `// Save button` | Etiqueta de layout obvia |
| `game_detail_screen.dart` | 1418 | `// Header with title and theme selector` | Etiqueta de diálogo obvia |
| `game_detail_screen.dart` | 1449 | `// Theme Switcher for card (Claro / Oscuro)` | Etiqueta de switch obvia |
| `game_detail_screen.dart` | 1559 | `// RepaintBoundary Card` | Etiqueta de widget obvia |
| `game_detail_screen.dart` | 1664 | `// Header: Brand & Rating` | Etiqueta de layout obvia |
| `game_detail_screen.dart` | 1668 | `// Monogram & Title` | Etiqueta de layout obvia |
| `game_detail_screen.dart` | 1747 | `// Cover` | Etiqueta de widget obvia |
| `settings_screen.dart` | 522 | `// Apariencia y Tema` | Etiqueta de sección obvia |
| `settings_screen.dart` | 582 | `// Almacenamiento Local SQLite` | Etiqueta de sección obvia |
| `settings_screen.dart` | 667 | `// Integración con Steam` | Etiqueta de sección obvia |
| `settings_screen.dart` | 752 | `// RAWG API Key` | Etiqueta de sección obvia |
| `settings_screen.dart` | 819 | `// HowLongToBeat Integration & Bulk Enrichment` | Etiqueta de sección obvia |
| `settings_screen.dart` | 902 | `// Copia de Seguridad & Portabilidad (JSON)` | Etiqueta de sección obvia |
| `search_screen.dart` | 192 | `// Consultar Wikipedia para el enlace oficial` | Comentario didáctico de flujo |
| `search_screen.dart` | 200 | `// Consultar HowLongToBeat para duración exacta...` | Comentario didáctico de flujo |

---

## 5. Blueprint de Extracción y Modularización de Componentes

### 5.1 Descomposición de `DashboardScreen`
* **Ruta de Pantalla:** `frontend/lib/screens/dashboard.dart`
* **LoC Actual:** 1,876 líneas | **LoC Objetivo:** < 280 líneas (**-85.1%**)

| Nuevo Archivo de Componente | Responsabilidad Extraída | LoC Estimado |
| :--- | :--- | :---: |
| `widgets/dashboard/dashboard_app_bar.dart` | AppBar responsiva, buscador animado, monograma, tema y menú móvil. | ~180 |
| `widgets/dashboard/dashboard_filter_bar.dart` | Barra de filtros (Estado, Plataforma, Género, Ordenamiento y Limpiar). | ~190 |
| `widgets/dashboard/dashboard_view_header.dart` | Contador de juegos, switch Grid/Lista y controles de zoom de tarjetas. | ~140 |
| `widgets/dashboard/quick_action_bottom_sheet.dart` | Modal de acciones rápidas (+1h, cambio de estado, navegación a detalle). | ~140 |
| `widgets/dashboard/dashboard_skeleton_grid.dart` | Placeholder de carga shimmer/skeleton durante consultas SQLite. | ~65 |

---

### 5.2 Descomposición de `GameDetailScreen`
* **Ruta de Pantalla:** `frontend/lib/screens/game_detail_screen.dart`
* **LoC Actual:** 1,962 líneas | **LoC Objetivo:** < 310 líneas (**-84.2%**)

| Nuevo Archivo de Componente | Responsabilidad Extraída | LoC Estimado |
| :--- | :--- | :---: |
| `widgets/game_detail/social_card_dialog.dart` | Diálogo modal de Social Card con selector de tema y render RepaintBoundary. | ~220 |
| `widgets/game_detail/social_card_preview.dart` | Widget visual puro de la tarjeta para exportación gráfica en PNG. | ~210 |
| `widgets/game_detail/game_detail_header.dart` | Backdrop blur cinematográfico, tarjeta Hero central y badges de plataforma. | ~110 |
| `widgets/game_detail/game_hltb_progress_card.dart` | Barra de progreso animada de HLTB, hitos de historia/100% y badge dinámico. | ~100 |
| `widgets/game_detail/game_genre_selector.dart` | Acordeón desplegable de géneros con wrap de FilterChips y contador. | ~130 |
| `widgets/game_detail/game_cover_picker_card.dart` | Selector de imagen de disco con FilePicker y campo de URL web. | ~110 |
| `widgets/game_detail/game_detail_form_fields.dart` | Bloques modulares: SectionHeader, QuickHourButton, Dropdown, DatePicker. | ~140 |

---

### 5.3 Descomposición de `SettingsScreen`
* **Ruta de Pantalla:** `frontend/lib/screens/settings_screen.dart`
* **LoC Actual:** 1,455 líneas | **LoC Objetivo:** < 220 líneas (**-84.8%**)

| Nuevo Archivo de Componente | Responsabilidad Extraída | LoC Estimado |
| :--- | :--- | :---: |
| `widgets/settings/settings_section_header.dart` | Encabezado tipográfico reutilizable de secciones con acento de color. | ~25 |
| `widgets/settings/theme_settings_card.dart` | Tarjeta interactiva de selección de tema (Oscuro / Claro / Sistema). | ~65 |
| `widgets/settings/database_settings_card.dart` | Estado de SQLite, conteo de juegos/horas, ruta local y botón de vacío (VACUUM). | ~80 |
| `widgets/settings/steam_settings_card.dart` | Campos de Steam API/Vanity, prueba de conexión y sincronización. | ~110 |
| `widgets/settings/rawg_settings_card.dart` | Configuración de API Key de RAWG y enriquecimiento de metadatos. | ~70 |
| `widgets/settings/hltb_settings_card.dart` | Información y botón de sincronización masiva de duraciones HLTB. | ~70 |
| `widgets/settings/backup_settings_card.dart` | Exportación e importación de respaldo JSON. | ~70 |
| `widgets/settings/import_backup_dialog.dart` | Diálogo modal completo de importación (FilePicker, dataset de prueba, JSON). | ~180 |
| `widgets/settings/sync_summary_dialog.dart` | Modal genérico de resumen de operaciones de sincronización. | ~55 |
| `widgets/settings/branding_footer.dart` | Footer con logotipo Victor Engineer, versión de la app y enlaces. | ~50 |

---

### 5.4 Descomposición de `SearchScreen`
* **Ruta de Pantalla:** `frontend/lib/screens/search_screen.dart`
* **LoC Actual:** 1,162 líneas | **LoC Objetivo:** < 180 líneas (**-84.5%**)

| Nuevo Archivo de Componente | Responsabilidad Extraída | LoC Estimado |
| :--- | :--- | :---: |
| `widgets/search/search_bar_input.dart` | Campo de búsqueda estilizado con icono de lupa, botón de borrado y spinner. | ~60 |
| `widgets/search/search_empty_state.dart` | Placeholder centrado con icono de gamepad y texto de instrucción. | ~30 |
| `widgets/search/search_result_card.dart` | Tarjeta de resultado con portada en caché, año, géneros y botón rojo de adición. | ~85 |
| `widgets/search/game_details_prompt_dialog.dart` | Modal completo de ingesta (HLTB estimate, chips de plataforma, géneros). | ~240 |
| `widgets/search/game_details_result.dart` | Modelo fuertemente tipado para los datos de salida del diálogo. | ~25 |

---

## 6. Verificación de Línea Base y Quality Gate

* **Linter & Análisis Estático:** Configurado en `frontend/analysis_options.yaml` con reglas estrictas (`strict-casts`, `strict-inference`, `strict-raw-types`).
* **Inventario de Pruebas Automatizadas:** 11 archivos de prueba en `frontend/test/` (1,377 líneas de código de prueba) cubriendo:
  1. `backup_service_test.dart`
  2. `database_service_test.dart`
  3. `game_model_test.dart`
  4. `hltb_service_test.dart`
  5. `metadata_service_test.dart`
  6. `resilient_http_client_test.dart`
  7. `secure_storage_service_test.dart`
  8. `steam_service_test.dart`
  9. `string_normalizer_test.dart`
  10. `widgets/app_cover_image_test.dart`
  11. `widgets/dashboard_widgets_test.dart`
* **Plan de Nuevas Pruebas de Widgets para Componentes Extraídos:**
  - `frontend/test/widgets/game_detail_widgets_test.dart` (validar renderizado de `SocialCardPreview`, acordeón de géneros y header).
  - `frontend/test/widgets/settings_widgets_test.dart` (validar cambio de temas y diálogos de respaldo).
  - `frontend/test/widgets/search_widgets_test.dart` (validar tarjetas de resultados y diálogo de ingesta).

---

## 7. Declaración de Cumplimiento: Cero Modificaciones en Código de Producción

En estricto apego a las normas del protocolo y el rol **Systems-Auditor**:
* **Archivos modificados en `frontend/lib/` durante la auditoría:** **0 archivos**.
* Todas las observaciones, métricas de LoC, anatomías y diagramas fueron recopilados mediante inspección estática en modo de solo lectura.
* El repositorio permanece en su estado funcional base intacto, listo para la ejecución de la Fase 1 del plan de refactorización por parte de los subagentes especializados.

---

**Firma:** Systems-Auditor (Quality Gatekeeper)  
**Estado:** `READY_FOR_REFACTOR`  
**Próximo Paso:** Despacho de subagentes por parte de `Project-Planner` para ejecutar las Fases 1 a 4 según `artifacts/planning/implementation_plan.md`.
