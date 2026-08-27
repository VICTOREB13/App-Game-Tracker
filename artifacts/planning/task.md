---
tipo: task
proyecto: App_Rastreador_de_Entretenimiento_Personal
version: v2.8.0
estado: completado
fecha: 2026-08-26
tags: [tareas, checklist, v2.8.0, filter-sheet, genre-helper, touch-filters, json-backup, project-planner]
---

# ✅ Checklist de Tareas Técnicas (v2.8.0)

Documento operativo gestionado por **Project-Planner** para registrar la asignación y ejecución de tareas entre agentes especializados.

---

## ⚡ 1. Caché Persistente Offline & Carga Instantánea (0 ms)
- [x] `(Backend-Architect)` Implementar métodos `saveLocalCache()` y `getLocalCache()` en `notion_service.dart` usando `SharedPreferences`.
- [x] `(Frontend-UI)` Conectar `DashboardScreen` para renderizado inmediato en **0 ms** desde el almacenamiento local antes de llamadas a red.
- [x] `(Backend-Architect)` Implementar sincronización asíncrona en segundo plano con Notion (*Stale-While-Revalidate*).
- [x] `(Frontend-UI)` Diseñar e integrar indicador sutil de *"Modo Local / Sin Conexión"* en caso de fallos de red.

---

## 🎛️ 2. Selector de Vista Dual & Paginación Inteligente
- [x] `(Frontend-UI)` Crear botón toggle `[ ⊞ Grid | ☰ Lista ]` en la barra de herramientas del `DashboardScreen`.
- [x] `(Frontend-UI)` Construir el componente `_GameListRow` (54px) con hover reactivo, miniatura (36x48), insignias de plataforma, estado, barra HLTB y acción rápida `+1h`.
- [x] `(Frontend-UI)` Implementar barra de paginación con selector de registros (10, 25, 50, 100 o Todos), botones `< Anterior`, indicador de página y `Siguiente >`.
- [x] `(Frontend-UI)` Persistir preferencias de vista y paginación en `SharedPreferences`.
- [x] `(Frontend-UI)` Asegurar reseteo automático a página 1 al aplicar nuevos filtros o buscar juegos.

---

## 🎯 3. Gamificación y Metas Anuales Dinámicas Multi-Año
- [x] `(Frontend-UI)` Construir el selector temporal interactivo `< [Año] >` en `AnalyticsScreen`.
- [x] `(Backend-Architect)` Diseñar persistencia de metas independientes por año (`annual_game_goal_${year}`) en disco local.
- [x] `(Frontend-UI)` Crear tarjeta de meta anual con barra de progreso circular animada en acento rojo `#DC2626`.
- [x] `(Frontend-UI)` Implementar sección de Récords Personales (*El Titán*, *Obra Maestra*, *Aventura Ágil*).
- [x] `(Frontend-UI)` Calcular medidor de salud de la biblioteca (*Backlog Health*) y tasa de finalización.

---

## 🖼️ 4. Generador de Tarjeta Social / Reseña Exportable (PNG)
- [x] `(Frontend-UI)` Agregar botón de exportación en `GameDetailScreen`.
- [x] `(Frontend-UI)` Diseñar el componente gráfico en formato 16:9 con isotipo squircle `VE`, carátula, estrellas, horas jugadas, fecha de finalización y cita de reseña.
- [x] `(Frontend-UI)` Implementar captura mediante `RepaintBoundary` a 2.5x pixel ratio y guardado automático en `%USERPROFILE%\Downloads` en Windows.

---

## ☀️ 5. Arquitectura de Temas, Modo Claro & Pulido Anti-Slop
- [x] `(Frontend-UI)` Crear `ThemeManager` (`ChangeNotifier`) con soporte para modos `dark`, `light` y `system` con persistencia en `SharedPreferences`.
- [x] `(Frontend-UI)` Diseñar `AppTheme.darkTheme` (Obsidian Zinc `#09090B`) y `AppTheme.lightTheme` (Crisp Zinc `#FAFAFA`).
- [x] `(Frontend-UI)` Crear fachada `AppColors` con tokens semánticos reactivos al contexto.
- [x] `(Frontend-UI)` Agregar toggle directo de tema con iconos de sol/luna en la barra superior del Dashboard.
- [x] `(Frontend-UI)` Rediseñar completamente `SettingsScreen` eliminando estilos antiguos y agregando selector de temas de 3 opciones.
- [x] `(Frontend-UI)` Migrar componentes en `DashboardScreen`, `AnalyticsScreen`, `GameDetailScreen`, `SearchScreen` y `SetupScreen` a `AppColors`.

---

## 🛡️ 6. Estabilización de Build CI/CD & Hotfix v2.7.1
- [x] `(Systems-Auditor)` Diagnosticar el fallo de compilación en Windows CI (`The method 'createGame' isn't defined for the type 'NotionService'`).
- [x] `(Backend-Architect)` Restaurar la llamada canónica `await notion.createPage(notion.gamesDbId, properties)` en `search_screen.dart`.
- [x] `(Backend-Architect)` Añadir método de conveniencia `createGame()` en `NotionService` para interoperabilidad completa.
- [x] `(DevOps-Engineer)` Actualizar número de versión a `2.7.1+1` en `pubspec.yaml`, `settings_screen.dart` y `changelog_v1.md`.
- [x] `(DevOps-Engineer)` Verificar pipeline de integración continua y publicación en GitHub.

---

## 📋 7. Auditoría de Calidad y Puesta al Día de Artefactos
- [x] `(Systems-Auditor)` Validar ausencia de consultas N+1 y límites estrictos de árbol de widgets (DOM virtualization).
- [x] `(Systems-Auditor)` Redactar reporte formal de auditoría en `artifacts/audit_reports/audit_report.md` con veredicto `PASS`.
- [x] `(Project-Planner)` Actualizar `project_overview.md`, `architecture.md`, `api_spec.md`, `implementation_plan.md` y `task.md` con enlaces wikilink `[[PRJ_...]]` y frontmatter completo.

---

## 💎 8. Pulido de Modo Claro, Smart Sync & Paginación (v2.7.2)
- [x] `(Frontend-UI)` Rediseñar chips de estado (`Todos`, `Jugando`, `Por jugar`, `Jugado`) con fondo blanco puro `#FFFFFF` y bordes grises nítidos en modo claro.
- [x] `(Frontend-UI)` Migrar menús desplegables (`Plataforma`, `Género`, `Orden`) a tokens semánticos `AppColors` con tipografía de alto contraste.
- [x] `(Frontend-UI)` Corregir color de texto en el buscador de la biblioteca para garantizar legibilidad óptima en modo claro.
- [x] `(Frontend-UI)` Centrar controles de paginación `< X / Y >` en la barra inferior y añadir margen de seguridad de 100px para despejar el botón flotante `+ Añadir`.
- [x] `(Backend-Architect)` Implementar Smart Sync en `NotionService` con consulta ligera de 1 registro para comparar `last_edited_time` antes de descargas completas.
- [x] `(Backend-Architect)` Añadir timeout HTTP de 15 segundos a todas las peticiones a Notion para evitar bloqueos indefinidos.
- [x] `(Frontend-UI)` Garantizar la detención del spinner de recarga en el AppBar mediante bloque `finally` con feedback mediante SnackBar.
- [x] `(DevOps-Engineer)` Sincronizar número de versión a `2.7.2+1` en `pubspec.yaml`, `settings_screen.dart` y `changelog_v1.md`.
- [x] `(Frontend-UI)` Adaptar modal y exportador PNG de tarjeta social (`RepaintBoundary`) a modos Claro y Oscuro con conmutador en vivo `[ ☀️ Claro | 🌙 Oscuro ]`.

---

## 🎮 9. Logotipos de Plataformas de Alto Contraste & Multi-Modo (Claro/Oscuro/Exportación)
- [x] `(Frontend-UI)` Generar e incorporar icono 1:1 de **Nintendo Switch** (`assets/images/nintendo_switch_logo.png`) en rojo oficial (`#E60012`) Joy-Con.
- [x] `(Frontend-UI)` Generar e incorporar insignia 1:1 de **Nintendo** (`assets/images/nintendo_badge_red.png`) en píldora roja con texto blanco para plataformas clásicas (DS, Wii, etc.).
- [x] `(Frontend-UI)` Generar e incorporar esfera 1:1 de **Xbox** (`assets/images/xbox_logo_green.png`) en verde oficial (`#107C10`).
- [x] `(Frontend-UI)` Generar e incorporar logotipo 1:1 de **GOG** (`assets/images/gog_logo_purple.png`) en púrpura oficial (`#9B59B6`) de alto contraste.
- [x] `(Frontend-UI)` Generar e incorporar escudo con borde protector de **Epic Games** (`assets/images/epic_games_logo_bordered.png`) para fondos oscuros y claros.
- [x] `(Frontend-UI)` Corregir mapeo de **Steam / PC** para utilizar el icono circular azul/blanco (`steam-logo-steam-icon-transparent-free-png.webp`) en lugar del texto blanco que desaparecía en modo claro.
- [x] `(Frontend-UI)` Refactorizar `PlatformHelper.getIcon()` para soportar tintado `color` y `BlendMode.srcIn` en modo monocromático sin desvirtuar logos a todo color.
- [x] `(Frontend-UI)` Actualizar la tarjeta social en `game_detail_screen.dart` para renderizar logotipos a todo color (`isColor: true`), garantizando visibilidad 100% nítida en previsualización y exportaciones tanto en Claro como Oscuro.

---

## 🎨 10. Selector de Tema en Pantalla de Conexión (`SetupScreen`)
- [x] `(Frontend-UI)` Incorporar tarjeta interactiva de selección de tema (`[ Oscuro | Claro | Sistema ]`) en `SetupScreen` (`setup_screen.dart`), permitiendo alternar el tema visual directamente al editar la conexión.
- [x] `(Frontend-UI)` Conectar `ThemeManager.instance` con `AnimatedBuilder` para reactividad inmediata al alternar entre modos Claro, Oscuro y Sistema.
- [x] `(Frontend-UI)` Añadir `AppBar` con botón de retroceso (`Navigator.canPop`) y título adaptativo cuando la pantalla es invocada desde "Editar Conexión".
- [x] `(Frontend-UI)` Adaptar el botón de acción para ejecutar `Navigator.pop(true)` al guardar cuando se proviene de Ajustes, preservando el flujo de navegación.
- [x] `(Frontend-UI)` Añadir restricciones de ancho máximo (`maxWidth: 520`) para visualización centrada y responsive en pantallas de escritorio.

---

## 🚀 11. Calidad de Vida (QoL) & Reorganización de Géneros/Plataformas (v2.8.0)
- [x] `(Frontend-UI)` Crear `GenreHelper` (`genre_helper.dart`) con normalización semántica virtual en memoria (sin tocar Notion) e iconografía temática.
- [x] `(Frontend-UI)` Construir `FilterModalSheet` (`filter_modal_sheet.dart`) adaptativo para móvil (BottomSheet) y escritorio, con buscador integrado y conteo de juegos.
- [x] `(Frontend-UI)` Integrar `FilterModalSheet` en `DashboardScreen` reemplazando los dropdowns rígidos de Género y Plataforma.
- [x] `(Frontend-UI)` Añadir botón interactivo de "Limpiar Filtros" con contador de filtros activos y texto de resultados ("Mostrando X de Y juegos").
- [x] `(Frontend-UI)` Añadir botón de borrado rápido `(X)` en el campo de búsqueda de la biblioteca.
- [x] `(Backend-Architect)` Implementar `BackupService` (`backup_service.dart`) con métodos para **Exportar** e **Importar / Restaurar** la biblioteca completa en JSON.
- [x] `(Frontend-UI)` Integrar sección de "Copia de Seguridad & Portabilidad" en `SettingsScreen` con botones para Exportar e Importar JSON.
- [x] `(DevOps-Engineer)` Actualizar número de versión a `2.8.0+1` en `pubspec.yaml`, `settings_screen.dart` y `changelog_v1.md`.
- [x] `(Systems-Auditor)` Ejecutar auditoría de calidad, validación de integridad JSON y accesibilidad táctil.
- [x] `(Frontend-UI)` Eliminar línea divisoria oscura huérfana entre el buscador y la lista en `FilterModalSheet`.
- [x] `(Frontend-UI)` Aplicar bordes redondeados completos (`BorderRadius.circular(24)`) y margen inferior flotante en `FilterModalSheet` tanto para Géneros como Plataformas.
- [x] `(Frontend-UI)` Adaptar botones rápidos de horas (+30m, +1h, +2h) y track de progreso HLTB a modo claro (`#FEF2F2` y `#E4E4E7`) en `GameDetailScreen`.

---

## 📱 12. Optimización Móvil & Arquitectura Responsiva (v2.8.1)
- [x] `(Frontend-UI)` Resolver colisión de AppBar en móvil envolviendo el título en `Flexible` + `FittedBox` y compactando acciones secundarias en menú desplegable `⋮`.
- [x] `(Frontend-UI)` Implementar barra de filtros en dos hileras en móvil (Fila 1: Estados, Fila 2: Plataforma, Género, Orden y Limpiar), preservando hilera única en escritorio.
- [x] `(Frontend-UI)` Adaptar FAB a formato circular compacto (56px) en móvil y optimizar la barra de paginación inferior para centrar `< 1 / 12 >` sin colisiones.
- [x] `(Frontend-UI)` Rediseñar métricas analíticas a cuadrícula 2x2 en móvil con `FittedBox` para evitar saltos de línea de números (`2176.3` y `65.8%`).
- [x] `(Frontend-UI)` Adaptar Salón de la Fama a carrusel horizontal con tarjetas amplias (175px) en móvil para evitar truncamiento de títulos y medallas.
- [x] `(Frontend-UI)` Reorganizar selector de año y meta anual a 2 filas en móvil para que las flechas y botón 'Ajustar' queden 100% dentro del marco.
- [x] `(Systems-Auditor)` Verificar ausencia de desbordamientos visuales y consistencia temática claro/oscuro.

---

## 🎨 13. Identidad Visual & Iconografía Nativa Victor Engineer (v2.8.2)
- [x] `(Frontend-UI)` Preservar `icon.svg` original (logotipo VE) y compilar `app_icon.png` y `app_icon.ico` con el mando gamer 2D minimalista en rojo Victor Engineer.
- [x] `(Frontend-UI)` Compilar `app_icon.png` (1024x1024), `app_icon.ico` (multi-resolución para Windows) y suite de Android (`mipmap-mdpi`, `hdpi`, `xhdpi`, `xxhdpi`, `xxxhdpi`).
- [x] `(DevOps-Engineer)` Actualizar pipeline `build_windows.yml` para inyectar `app_icon.ico` en `windows/runner/resources/app_icon.ico` antes de compilar el binario release.
- [x] `(DevOps-Engineer)` Actualizar pipeline `build_apk.yml` para copiar los iconos mipmap en `android/app/src/main/res/` antes de compilar el APK.
- [x] `(DevOps-Engineer)` Generar keystore de firma criptográfica permanente (`release.keystore`, RSA 2048, SHA256) con validez hasta 2054.
- [x] `(DevOps-Engineer)` Actualizar `build_apk.yml` para usar el keystore permanente e inyectar dinámicamente la versión (`build-name`) desde `pubspec.yaml`, resolviendo el error "Conflicto con un paquete ya existente" al actualizar en Android.
- [x] `(Systems-Auditor)` Validar que `tracker_app.exe` y el APK de Android exhiban la identidad oficial de Victor Engineer sin depender del icono por defecto de Flutter.

---

## 🧹 14. Limpieza de Assets Huérfanos & Optimización de Dependencias (v2.8.3)
- [x] `(Systems-Auditor)` Auditar exhaustivamente todas las imágenes de `frontend/assets/images/` contra el código fuente Dart para identificar archivos huérfanos y redundantes.
- [x] `(Systems-Auditor)` Eliminar 7 imágenes obsoletas y duplicadas (`Epic_Games_logo.svg.webp`, `GOG_LOGO_DARK.png`, `logo-Xbox.png`, `nintendo-logo-1-1.png`, `nintendo_logo_red.png`, `nintendo_PNG19.png`, `steam-logo.png`), ahorrando más de 361 KB en el bundle de distribución.
- [x] `(Backend-Architect)` Auditar dependencias en `frontend/pubspec.yaml` y eliminar paquetes no utilizados (`dio: ^5.4.0` y `flutter_staggered_grid_view: ^0.7.0`) para aligerar la compilación y evitar dependencias transitivas innecesarias.
- [x] `(Systems-Auditor)` Verificar que los 14 archivos Dart conserven únicamente imports activos y funcionalidades esenciales sin código muerto.

---

## 🛠️ 15. Corrección de Error 400 al Guardar Cambios en Notion (v2.8.4)
- [x] `(Backend-Architect)` Diagnosticar y reproducir el error HTTP 400 (`validation_error: A file with type external cannot contain a Notion hosted file url`). Identificado que ocurría en páginas con portadas alojadas internamente en Notion (S3).
- [x] `(Backend-Architect)` Actualizar `toNotionProperties()` en `Game` para aceptar el flag `includeCover` y filtrar URLs alojadas en AWS S3/Notion para no enviarlas como `external`.
- [x] `(Frontend-UI)` Modificar `_saveChanges()` en `GameDetailScreen` para comparar si la portada realmente cambió; si no cambió, omitir `Portada` del PATCH preservando el archivo original de Notion.
- [x] `(Backend-Architect)` Fortalecer constructores de `NotionParser` (`buildSelect`, `buildUrl`, `buildExternalFile`, `buildRichText`, `buildMultiSelect`) ante cadenas vacías y nulos.
- [x] `(Backend-Architect)` Mejorar `NotionApiException` para deserializar el JSON de error de Notion y mostrar mensajes de error legibles en español en la interfaz.










