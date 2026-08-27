---
tipo: plan
proyecto: App_Rastreador_de_Entretenimiento_Personal
version: v2.7.2
estado: completado
fecha: 2026-08-26
tags: [plan, v2.7.2, offline-cache, dual-view, pagination, multi-year-goals, gamification, social-card, theme-manager, light-mode, smart-sync, victor-engineer]
---

# 📋 Plan de Implementación Consolidado (v2.7.2)

Plan integral de evolución técnica orquestado por el rol **Project-Planner** y ejecutado en conjunto por **Backend-Architect**, **Frontend-UI**, **Systems-Auditor** y **DevOps-Engineer**, consolidando la arquitectura final del **Rastreador de Entretenimiento Personal**.

---

## 🎯 Objetivos de la Versión

1. **Rendimiento & Disponibilidad Inmediata:** Carga en **0 ms** sin pantallas de espera inicial mediante caché local persistente con patrón *Stale-While-Revalidate*.
2. **Visualización y Ergonomía Visual:** Soporte nativo dual de **Modo Oscuro (Obsidian Zinc)** y **Modo Claro (Crisp Zinc)** con alternancia en tiempo real y persistencia.
3. **Control de Biblioteca:** Selector de vista dual (Grid de carátulas cinematográficas vs. Lista de alta densidad) y paginador dinámico con tamaños de 10, 25, 50, 100 o Todos los juegos.
4. **Gamificación Dinámica sin Obsolescencia:** Sistema de metas y balances multi-año interactivo (`< [Año] >`) para consultar el pasado o planificar años venideros (2025, 2026, 2027...).
5. **Viralidad y Logros Compartibles:** Exportación directa a PNG de tarjetas sociales con calificación y reseña en alta resolución.
6. **Estabilidad y Resiliencia en CI/CD:** Garantizar compilaciones automáticas limpias y sin fallos en GitHub Actions para Windows x64.

---

## 🔍 Desglose por Fases de Construcción

### Fase 1: ⚡ Caché Persistente Offline & Carga Instantánea (0 ms)
- **Rol Responsable:** `Backend-Architect` & `Frontend-UI`
- **Implementación:**
  - Implementación de `saveLocalCache()` y `getLocalCache()` en `NotionService` utilizando `SharedPreferences` con clave `'notion_persistent_games_cache_v1'`.
  - Carga inmediata de la biblioteca en `DashboardScreen` al inicializar el estado antes de cualquier llamada HTTP.
  - Sincronización en segundo plano con Notion y actualización de la UI si se detectan cambios (*Stale-While-Revalidate*).
  - Manejo de contingencias sin conexión (*Offline Mode*) con indicador sutil en pantalla.

### Fase 2: 🎛️ Vista Dual & Sistema de Paginación Inteligente
- **Rol Responsable:** `Frontend-UI`
- **Implementación:**
  - Toggle `[ ⊞ Grid | ☰ Lista ]` en la barra de herramientas del Dashboard con persistencia en `'preferred_library_view_mode'`.
  - Creación del componente `_GameListRow`: fila de 54px con miniatura 36x48, badges de plataforma mapeados por `PlatformHelper`, estado, barra HLTB y acción rápida `+1h`.
  - Selector de tamaño de página: 10, 25, 50, 100 o Todos los juegos, persistido en `'preferred_page_size'`.
  - Barra de navegación con botones `< Anterior`, indicador `Página X de Y` y `Siguiente >`.
  - Reseteo automático a página 1 al aplicar filtros o términos de búsqueda.

### Fase 3: 🎯 Gamificación y Metas Anuales Dinámicas Multi-Año
- **Rol Responsable:** `Frontend-UI` & `Backend-Architect`
- **Implementación:**
  - Stepper temporal interactivo `< [Año] >` en `AnalyticsScreen` con año en curso por defecto.
  - Almacenamiento independiente de metas por año (`annual_game_goal_${year}`) en `SharedPreferences`.
  - Tarjeta de meta anual con barra de progreso circular en acento rojo Victor Engineer `#DC2626`.
  - Salón de la Fama con récords personales: *El Titán* (más horas), *Obra Maestra* (5 estrellas y máxima dedicación) y *Aventura Ágil* (completado más rápido).
  - Medidor de salud del backlog y tasa porcentual de finalización.

### Fase 4: 🖼️ Generador de Tarjeta Social / Reseña Exportable (PNG)
- **Rol Responsable:** `Frontend-UI`
- **Implementación:**
  - Botón de exportación en la pantalla de detalle (`GameDetailScreen`).
  - Modal con tarjeta gráfica en formato 16:9 con isotipo squircle `VE`, carátula, estrellas, horas y cita personal.
  - Captura en alta resolución (pixel ratio 2.5x) mediante `RepaintBoundary`.
  - Guardado directo del archivo PNG en `%USERPROFILE%\Downloads` en Windows.

### Fase 5: ☀️ Modo Claro "Crisp Zinc" & Arquitectura de Temas
- **Rol Responsable:** `Frontend-UI`
- **Implementación:**
  - Creación de `ThemeManager` (`ChangeNotifier`) y helper de colores semánticos `AppColors`.
  - Definición de `AppTheme.darkTheme` (Obsidian Zinc `#09090B`) y `AppTheme.lightTheme` (Crisp Zinc `#FAFAFA`).
  - Enlace reactivo en `main.dart` con `AnimatedBuilder` sobre `ThemeManager.instance`.
  - Toggle directo de 1 clic en la barra superior del Dashboard (`Icons.light_mode_rounded` / `Icons.dark_mode_rounded`).
  - Selector de 3 opciones en `SettingsScreen`: *Oscuro*, *Claro* y *Sistema*.
  - Adaptación cromática de `DashboardScreen`, `AnalyticsScreen`, `GameDetailScreen`, `SearchScreen`, `SettingsScreen` y `SetupScreen`.

### Fase 6: 🛡️ Estabilización de Compilación & CI/CD Release v2.7.1
- **Rol Responsable:** `Systems-Auditor` & `DevOps-Engineer`
- **Implementación:**
  - Corrección del error de compilación `createGame` en `search_screen.dart` restaurando `await notion.createPage(notion.gamesDbId, properties)`.
  - Implementación del helper de conveniencia `createGame()` en `NotionService` para interoperabilidad completa.
  - Sincronización de versión a `2.7.1+1` en `pubspec.yaml`, `settings_screen.dart` y `changelog_v1.md`.
  - Ejecución de auditoría de calidad con veredicto `Status: PASS`.

### Fase 7: 💎 Pulido de Modo Claro, Smart Sync con Notion & Despeje de FAB (v2.7.2)
- **Rol Responsable:** `Frontend-UI`, `Backend-Architect` & `Systems-Auditor`
- **Implementación:**
  - **Rediseño de Contraste en Modo Claro:** Adaptación de chips de estado (`Todos`, `Jugando`, `Por jugar`, `Jugado`) a fondos blancos y bordes grises nítidos; migración de dropdowns (`Plataforma`, `Género`, `Orden`) a tokens semánticos `AppColors`; corrección del color de texto en el buscador para garantizar contraste óptimo.
  - **Paginación Centrada & Despeje de FAB:** Reorganización de la barra inferior con controles `< X / Y >` centrados mediante espaciadores elásticos y margen de 100px a la derecha, evitando que el botón `+ Añadir` tape los controles de página.
  - **Smart Sync con Notion:** Chequeo ultrarrápido (1 registro remoto por `last_edited_time`) antes de descargas masivas; adición de timeout HTTP de 15 segundos; bloque `finally` para asegurar que el indicador de carga se detenga siempre con SnackBar de feedback.
