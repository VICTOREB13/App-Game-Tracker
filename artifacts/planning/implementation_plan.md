---
tipo: plan
proyecto: App_Rastreador_de_Entretenimiento_Personal
version: v2.8.4
estado: completado
fecha: 2026-08-27
tags: [plan, v2.8.4, offline-cache, dual-view, pagination, multi-year-goals, gamification, social-card, theme-manager, light-mode, smart-sync, backup-service, mobile-responsive, permanent-signing, fix-400, victor-engineer]
---

# 📋 Plan de Implementación Consolidado (v2.8.4)

Plan integral de evolución técnica orquestado por el rol **Project-Planner** y ejecutado en conjunto por **Backend-Architect**, **Frontend-UI**, **Systems-Auditor** y **DevOps-Engineer**, consolidando la arquitectura final del **Rastreador de Entretenimiento Personal**.

---

## 🎯 Objetivos de la Versión

1. **Rendimiento & Disponibilidad Inmediata:** Carga en **0 ms** sin pantallas de espera inicial mediante caché local persistente con patrón *Stale-While-Revalidate*.
2. **Visualización y Ergonomía Visual:** Soporte nativo dual de **Modo Oscuro (Obsidian Zinc)** y **Modo Claro (Crisp Zinc)** con alternancia en tiempo real y persistencia.
3. **Control de Biblioteca:** Selector de vista dual (Grid de carátulas cinematográficas vs. Lista de alta densidad) y paginador dinámico con tamaños de 10, 25, 50, 100 o Todos los juegos.
4. **Gamificación Dinámica sin Obsolescencia:** Sistema de metas y balances multi-año interactivo (`< [Año] >`) para consultar el pasado o planificar años venideros (2025, 2026, 2027...).
5. **Viralidad y Logros Compartibles:** Exportación directa a PNG de tarjetas sociales con calificación y reseña en alta resolución.
6. **Ergonomía Móvil Integral:** Adaptación de filtros en doble fila, layout 2x2 en estadísticas y selector de metas anuales sin desbordes.
7. **Identidad Nativa & Distribución:** Branding oficial Victor Engineer en iconos ejecutables y firma criptográfica persistente para actualizaciones continuas de Android en 1 toque.
8. **Resiliencia ante la API de Notion:** Blindaje frente a errores de validación 400 por archivos S3 y deserialización de mensajes de error transparentes.

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

### Fase 6: 🛡️ Estabilización de Compilación & CI/CD Release v2.7.1
- **Rol Responsable:** `Systems-Auditor` & `DevOps-Engineer`
- **Implementación:**
  - Corrección del error de compilación `createGame` en `search_screen.dart` restaurando `await notion.createPage(notion.gamesDbId, properties)`.
  - Implementación del helper de conveniencia `createGame()` en `NotionService`.

### Fase 7: 💎 Pulido de Modo Claro, Smart Sync & Despeje de FAB (v2.7.2)
- **Rol Responsable:** `Frontend-UI`, `Backend-Architect` & `Systems-Auditor`
- **Implementación:**
  - Rediseño de contraste en modo claro para chips de estado y menús desplegables.
  - Paginador centrado con zona de seguridad de 100px para eliminar colisiones con el botón flotante `+ Añadir`.
  - Smart Sync mediante comprobación previa de 1 registro (`last_edited_time`) con timeout de 15 segundos.

### Fase 8: 💾 Modal Bottom Sheet QoL, Normalización & Respaldo JSON (v2.8.0)
- **Rol Responsable:** `Frontend-UI` & `Backend-Architect`
- **Implementación:**
  - Creación de `BackupService` para exportar e importar la biblioteca en JSON estructurado.
  - Modal sheet táctil con esquinas redondeadas para filtros en pantallas reducidas.
  - Normalización de géneros redundantes en catálogo.

### Fase 9: 📱 Ergonomía Móvil & Barra de Filtros Dual (v2.8.1)
- **Rol Responsable:** `Frontend-UI`
- **Implementación:**
  - Barra de filtros en dos hileras compactas para dispositivos móviles.
  - AppBar móvil protegida con `FittedBox` y menú popup `⋮` para acciones secundarias.
  - Cuadrícula 2x2 para tarjetas de métricas y selector anual de dos filas en `AnalyticsScreen`.

### Fase 10: 🛡️ Branding Nativo Victor Engineer & Firma Persistente Android (v2.8.2)
- **Rol Responsable:** `Frontend-UI` & `DevOps-Engineer`
- **Implementación:**
  - Integración del icono de mando gamer 2D minimalista sobre rojo Victor Engineer (`#DC2626`) en `app_icon.png`, `app_icon.ico` y mipmaps Android.
  - Preservación del vector original [`icon.svg`](file:///c:/Users/vmesp/Documents/Cositas/App-Rastreador-de-Entretenimiento/frontend/assets/images/icon.svg) con el monograma VE.
  - Generación de keystore permanente (`release.keystore`, validez 2054) y versionado dinámico en GitHub Actions para eliminar errores de actualización en Android.

### Fase 11: 🧹 Purga de Assets Huérfanos & Optimización (v2.8.3)
- **Rol Responsable:** `Systems-Auditor`
- **Implementación:**
  - Eliminación de 7 imágenes obsoletas y duplicadas, reduciendo el bundle en más de 361 KB.
  - Desinstalación limpia de `dio` y `flutter_staggered_grid_view` en `pubspec.yaml`.

### Fase 12: 🛠️ Corrección Error 400 Notion S3 & Parser Blindado (v2.8.4)
- **Rol Responsable:** `Backend-Architect` & `Frontend-UI`
- **Implementación:**
  - Detección inteligente de portadas modificadas en `_saveChanges()` para no re-enviar archivos de S3 como `type: external`.
  - Filtro de enlaces internos en `toNotionProperties()` y constructores robustos en `NotionParser`.
  - Deserialización de mensajes JSON de error en `NotionApiException` para exhibir textos claros en la interfaz.
