---
tipo: task
proyecto: App_Rastreador_de_Entretenimiento
version: v2.6.0
estado: completado
fecha: 2026-08-26
tags: [tareas, checklist, offline-cache, dual-view, pagination, multi-year, gamification, social-card, project-planner]
---

# ✅ Lista de Tareas (Task Checklist) - Iteración Definitiva v2.6.0

## ⚡ 1. Caché Persistente Offline & Carga Instantánea (`Backend-Architect`)
- [x] (Backend) Implementar `saveLocalCache()` y `getLocalCache()` en `notion_service.dart` con `SharedPreferences`.
- [x] (Frontend) Conectar `dashboard.dart` para renderizado instantáneo (0 ms) y refresco asíncrono en background (*Stale-While-Revalidate*).
- [x] (Frontend) Agregar indicador discreto de *"Modo Local / Sin Conexión"* en caso de desconexión.

## 🎛️ 2. Selector de Vista Dual & Paginación Configurable (`Frontend-UI`)
- [x] (Frontend) Agregar botón toggle `[ ⊞ Grid | ☰ Lista ]` en la barra de herramientas del `DashboardScreen`.
- [x] (Frontend) Crear el componente `_GameListRow` optimizado con hover, miniatura, badges de plataforma y botón `+1h`.
- [x] (Frontend) Implementar controles de paginación (selector de 10, 25, 50, 100 o Todos, botones Anterior/Siguiente e indicador de página).
- [x] (Frontend) Persistir preferencias de vista y tamaño de página en `SharedPreferences`.

## 🎯 3. Gamificación y Metas Anuales Dinámicas Multi-Año (`Frontend-UI`)
- [x] (Frontend) Crear selector interactivo de año `< [Año] >` en `AnalyticsScreen` con año actual por defecto.
- [x] (Frontend) Implementar persistencia de metas independientes por año (`annual_game_goal_${year}`) en `SharedPreferences`.
- [x] (Frontend) Diseñar tarjeta de Meta Anual con anillo/barra de progreso en `#DC2626` calculada para el año seleccionado.
- [x] (Frontend) Implementar sección de Récords Personales (El Titán, La Obra Maestra, Aventura Corta).
- [x] (Frontend) Calcular y mostrar tasa de eficiencia de resolución del Backlog.

## 🖼️ 4. Generador de Tarjeta Social / Reseña Exportable (`Frontend-UI`)
- [x] (Frontend) Agregar botón de exportación en `GameDetailScreen`.
- [x] (Frontend) Diseñar componente visual de la Tarjeta Social con branding Victor Engineer (`VE` squircle, carátula, estrellas, horas, cita).
- [x] (Frontend) Implementar captura mediante `RepaintBoundary` y guardado como PNG en la carpeta `Descargas`.

## 🛡️ 5. Auditoría de Calidad (`Systems-Auditor`)
- [x] (Auditor) Verificar que la app cargue en 0 ms con caché persistente y no falle sin internet.
- [x] (Auditor) Verificar navegación fluida entre páginas y alternancia instantánea entre Grid y Lista (60 FPS).
- [x] (Auditor) Verificar cálculo histórico y futuro al cambiar entre años en Analíticas.
- [x] (Auditor) Validar generación y guardado del archivo PNG en Windows.
