---
tipo: plan
proyecto: App_Rastreador_de_Entretenimiento
version: v2.6.0
estado: pendiente_aprobacion
fecha: 2026-08-26
tags: [plan, offline-cache, dual-view, pagination, multi-year-goals, gamification, social-card, victor-engineer, project-planner]
---

# 📋 Plan de Implementación: Iteración Definitiva (v2.6.0)

Este plan detalla las 4 mejoras seleccionadas para consolidar la versión definitiva de **App-Rastreador-de-Entretenimiento** bajo la identidad y sistema de diseño **Victor Engineer**, incorporando la **paginación configurable** y el **sistema multi-año dinámico**:

1. **⚡ Caché Persistente Offline & Carga Instantánea (0 ms)** con patrón *Stale-While-Revalidate*.
2. **🎛️ Selector de Vista Dual (Grid vs. Lista) & Sistema de Paginación Inteligente (10, 25, 50, 100, Todos):** Flexibilidad de visualización y control de densidad.
3. **🎯 Gamificación y Metas Anuales Dinámicas Multi-Año:** Selector de año histórico/futuro (2025, 2026, 2027...), metas independientes por año y récords del backlog.
4. **🖼️ Generador de Tarjeta Social / Reseña Exportable (PNG):** Captura gráfica estilizada con branding oficial Victor Engineer para compartir logros y reseñas.

---

## 🔍 Detalles Técnicos por Componente

### 1. ⚡ Caché Persistente Offline & Carga Instantánea (0 ms)
- **Objetivo:** Eliminar el tiempo de espera inicial en frío y permitir la consulta fluida de la biblioteca sin conexión.
- **Mecanismo (*Stale-While-Revalidate*):**
  - Al recibir los datos de Notion, serializar la lista de juegos a JSON y almacenarla en disco local mediante `SharedPreferences` (`'cached_games_payload_v1'`).
  - Al abrir el `DashboardScreen`, leer primero la caché de disco y poblar el estado en **0 ms**.
  - Lanzar en segundo plano `_fetchGames(background: true)`. Si hay cambios o registros actualizados en Notion, refrescar silenciosamente el estado de la UI y sincronizar la caché local.
  - En caso de fallo de red o modo offline, mantener los datos locales sin bloquear al usuario y mostrar un indicador discreto de *"Modo Local / Sin Conexión"*.

---

### 2. 🎛️ Selector de Vista Dual & Paginación Configurable
- **Objetivo:** Darle flexibilidad al usuario para elegir entre una experiencia visual cinematográfica y una vista rápida tipo tabla, con control de paginación para bibliotecas grandes.
- **Selector de Vista en Toolbar:**
  - Botón toggle `[ ⊞ Grid | ☰ Lista ]` con estado persistido en `SharedPreferences` (`'preferred_library_view_mode'`).
- **Widget `_GameListRow` (Modo Lista Compacta):**
  - Fila optimizada de 54px de alto con hover reactivo (`#18181B`).
  - Miniatura de portada con esquinas redondeadas (36x48px).
  - Título en `GoogleFonts.outfit()`, badge temático de plataforma (`PlatformHelper`).
  - Pill de estado coloreado (`Jugando`, `Por jugar`, `Jugado`).
  - Horas jugadas con micro-barra de progreso HLTB y calificación en estrellas.
  - Botón de registro rápido integrado (`+1h`) y soporte para `onTap` y `onLongPress`.
- **Sistema de Paginación Inteligente:**
  - Selector de tamaño de página: **`10`**, **`25`**, **`50`**, **`100`** o **`Todos`** (persistido en `SharedPreferences`).
  - Barra de navegación inferior estilizada:
    - Botón `[ < Anterior ]` (deshabilitado en pág. 1).
    - Indicador central: *"Página X de Y (Total: N juegos)"*.
    - Botón `[ Siguiente > ]` (deshabilitado en última pág.).
  - Reseteo automático a la página 1 al aplicar nuevos filtros de estado, plataforma, género o búsqueda en tiempo real.

---

### 3. 🎯 Gamificación y Metas Anuales Dinámicas Multi-Año (Backlog Crusher)
- **Objetivo:** Que el sistema de metas sea dinámico en el tiempo, permitiendo consultar años pasados (histórico) y planificar años futuros (2026, 2027, etc.) sin quedarse nunca estancado.
- **Selector Dinámico de Año:**
  - Cabecera con selector interactivo `< 2025 | 2026 | 2027 >` (o dropdown) centrado por defecto en `DateTime.now().year`.
  - La meta anual se almacena de forma independiente para cada año en `SharedPreferences` (`annual_game_goal_${year}`).
  - Si el usuario viaja a 2027, la app crea y gestiona la meta de 2027; si viaja a 2026 o 2025, muestra el recuento histórico exacto de juegos culminados en ese año y si la meta fue alcanzada.
- **Anillo y Barra de Progreso Circular:**
  - Gráfico de progreso animado en rojo `#DC2626` con feedback: *"X de Y Juegos Completados en [Año] (Z%)"*.
- **Salón de la Fama / Récords Personales (Global y por Año):**
  - 👑 **"El Titán":** Juego completado con más horas acumuladas.
  - ⭐ **"La Obra Maestra":** Juego culminado con máxima puntuación (5 estrellas) y mayores horas.
  - ⚡ **"Aventura Corta":** Juego completado en menor tiempo (horas HLTB).
- **Tasa de Eficiencia del Backlog:**
  - Ratio porcentual entre juegos terminados vs. juegos en espera.

---

### 4. 🖼️ Generador de Tarjeta Social / Reseña Exportable (PNG)
- **Objetivo:** Permitir al usuario exportar una imagen de alta resolución con su reseña, calificación y horas con la estética oficial Victor Engineer para compartir en redes o Discord.
- **Arquitectura de Captura:**
  - Botón en `GameDetailScreen`: `[ 📤 Compartir Ficha / Exportar ]`.
  - Diálogo modal de previsualización que renderiza una tarjeta de diseño profesional (relación 16:9 / tarjeta de reseña):
    - Fondo Obsidian `#09090B` con resplandor carmesí ambiental.
    - Isotipo squircle `VE` + marca *"Victor Engineer • Game Tracker"*.
    - Carátula cinematográfica, Título, Plataforma con logo oficial, Estrellas de calificación (`★★★★★`), Horas totales jugadas, Fecha de culminación y cita de las notas/resumen personal.
  - Envuelto en un `RepaintBoundary`.
  - Botón *"Guardar PNG"*:
    - Extrae el render a través de `toImage(pixelRatio: 2.5)` -> `toByteData(format: ui.ImageByteFormat.png)`.
    - En Windows Desktop, guarda directamente el archivo en la carpeta `Descargas` del usuario (`%USERPROFILE%\Downloads\Reseña_VE_{Titulo}.png`) y muestra un SnackBar de confirmación con la ruta.

---

## 📂 Archivos a Modificar / Crear

### `frontend/lib/services/notion_service.dart`
- Añadir métodos `saveLocalCache(List<dynamic> pages)` y `Future<List<dynamic>?> getLocalCache()`.
- Soporte para detección de modo offline y fallback transparente.

### `frontend/lib/screens/dashboard.dart`
- Integrar la carga instantánea desde caché local en `initState()`.
- Añadir selector toggle Grid / Lista compacta en la barra de herramientas.
- Implementar la lógica de paginación (páginas, selector de 10/25/50/100/Todos, botones Anterior/Siguiente).
- Implementar el widget `_GameListRow` para la vista compacta.
- Persistir las preferencias de vista y paginación con `SharedPreferences`.

### `frontend/lib/screens/analytics_screen.dart`
- Implementar el selector de año dinámico `< [Año] >`.
- Implementar la tarjeta de **Meta Anual** dependiente del año seleccionado con persistencia independiente (`annual_game_goal_${year}`).
- Implementar el bloque de **Récords Personales (Titán, Obra Maestra, Aventura Corta)** y tasa de finalización del backlog.

### `frontend/lib/screens/game_detail_screen.dart`
- Añadir botón de exportar/compartir en el AppBar o cabecera.
- Crear el componente visual de la **Tarjeta Social Victor Engineer** con `RepaintBoundary`.
- Implementar la función de exportación a archivo PNG en disco.
