---
tipo: overview
proyecto: App_Rastreador_de_Entretenimiento_Personal
estado: activo
version: v2.7.2
fecha: 2026-08-26
tags: [proyecto, overview, notion, flutter, entretenimiento, gaming, victor-engineer, light-mode, dark-mode, multi-year, offline-cache, smart-sync, v2.7.2]
---

# 🚀 Visión General del Proyecto: Rastreador de Entretenimiento Personal

Aplicación multiplataforma de grado profesional (Windows Desktop x64 y Android) desarrollada en **Flutter 3.22+**, conectada directamente a la **API de Notion** como base de datos en la nube sin intermediarios, enriquecida con metadatos de **RAWG API** y diseñada bajo la identidad visual de marca personal **Victor Engineer** (acento Rojo `#DC2626`, tipografías Google Fonts `Outfit` + `Inter`, y soporte nativo dual de **Modo Oscuro Obsidian Zinc** y **Modo Claro Crisp Zinc**).

---

## 📖 Capacidades y Funcionalidades Principales (v2.7.2)

### 1. 🗄️ Gestión Integral y Bidireccional de Biblioteca (Notion API)
- Conexión directa mediante *Internal Integration Token* de Notion sin intermediarios (Supabase eliminado).
- Control exhaustivo de campos: Título, Estado (*Por jugar*, *Jugando*, *Jugado*), Plataforma, Horas Jugadas, Fechas de Inicio y Culminación, Calificación en estrellas (1-5), Tiempos HowLongToBeat (Principal, Extra, 100%), Géneros, Portada y Reseña/Notas personales.
- Sincronización transparente con actualización optimista en la interfaz para cambios instantáneos.

### 2. ⚡ Rendimiento Extremo, Caché Offline (0 ms) & Smart Sync
- Almacenamiento local en disco con `SharedPreferences` que retiene la última instantánea serializada de la biblioteca.
- Patrón **Stale-While-Revalidate**: La aplicación inicia en **0 ms** mostrando inmediatamente todos los títulos y actualiza en segundo plano cualquier cambio de Notion.
- **Smart Sync:** Antes de descargar la base de datos completa, consulta de forma ultrarrápida (1 registro) si la fecha `last_edited_time` en Notion difiere de la caché local. Si no hay cambios, finaliza al instante sin transferencias redundantes.
- Timeout HTTP estricto (15 segundos) y garantía de desactivación del spinner en la barra de herramientas.

### 3. 🎨 Arquitectura de Temas Dinámicos & Sistema de Diseño Victor Engineer
- **Modo Oscuro (Obsidian Zinc):** Fondo ultra profundo `#09090B`, tarjetas `#121215`, bordes `#27272A` y acento rojo carmesí `#DC2626`.
- **Modo Claro (Crisp Zinc):** Fondo limpio `#FAFAFA`, tarjetas blancas `#FFFFFF`, bordes sutiles `#E4E4E7`, texto `#09090B` y acento rojo `#DC2626`.
- **Filtros Adaptativos de Alto Contraste:** Chips de estado y menús desplegables (`Plataforma`, `Género`, `Orden`) que se adaptan con fondo blanco puro y bordes zinc definidos en modo claro, eliminando bloques oscuros huérfanos.
- **Alternancia Instantánea (`ThemeManager`):** Toggle de 1 clic en la barra superior (`Icons.light_mode_rounded` / `Icons.dark_mode_rounded`) y selector de 3 opciones en Configuración (`Oscuro`, `Claro`, `Sistema`).

### 4. 🎛️ Selector de Vista Dual (Grid Cinematográfico vs. Lista Compacta)
- **Grid Cinematográfico:** Tarjetas con portadas a escala completa, resplandor en hover, micro-barra de progreso HLTB y badges de estado.
- **Lista Compacta (`_GameListRow`):** Fila de alta densidad (54px) con miniatura de carátula (36x48), título en `Outfit`, insignias oficiales de plataforma, pill de estado, estrellas y botón rápido `+1h`.
- Preferencia persistida en disco para recordar la vista favorita del usuario.

### 5. 📄 Sistema de Paginación Inteligente con Despeje de FAB
- Selector de densidad: **10**, **25**, **50**, **100** o **Todos** los registros.
- Controles de navegación `< X / Y >` **centrados** en la barra inferior, con margen de seguridad dedicado de 100px a la derecha para que el botón flotante `+ Añadir` nunca colisione con las flechas de paginación.
- Barra inferior estilizada con `AppColors.surface` y borde sutil adaptativo.

### 6. 🎯 Gamificación y Metas Anuales Dinámicas Multi-Año
- Stepper de año `< [Año] >` que permite auditar balances pasados (2024, 2025, 2026) y planificar metas en años futuros (2027 y más allá) sin obsolescencia.
- Metas independientes por año con barra de progreso circular en `#DC2626`.
- **Salón de la Fama / Récords Personales:**
  - 👑 *El Titán* (Juego completado con mayor tiempo acumulado).
  - ⭐ *Obra Maestra* (Juego con 5 estrellas y máxima dedicación).
  - ⚡ *Aventura Ágil* (Juego completado en menor tiempo).
- Medidor de salud de biblioteca (*Backlog Health*) y desglose porcentual de finalización.

### 7. 🖼️ Generador de Tarjeta Social / Reseña Exportable (PNG) Adaptativa
- Captura de alta resolución mediante `RepaintBoundary` (pixel ratio 2.5x).
- **Adaptabilidad Cromática Dinámica:** Detecta el modo visual activo (Claro u Oscuro) y permite conmutar en vivo mediante toggle `[ ☀️ Claro | 🌙 Oscuro ]` antes de exportar.
- Generación de imagen lista para compartir en Discord o redes sociales con branding oficial `VE`, carátula, estrellas, horas, fecha y cita personal.
- Guardado directo en la carpeta `%USERPROFILE%\Downloads` en Windows con sufijo `_Light_` o `_Dark_`.

### 8. 🔍 Búsqueda Inteligente y Autocompletado (RAWG API)
- Búsqueda en catálogo de más de 500,000 videojuegos con carátulas en HD.
- Modal enriquecido para asignar estado, plataforma, fecha de inicio, horas y selección múltiple de géneros con acordeón temático.
- Inserción directa en Notion mediante `createPage` con tolerancia y compatibilidad retroactiva.

---

## 🗺️ Índice de Artefactos del Proyecto

- **Arquitectura del Sistema:** [[PRJ_App_Rastreador_de_Entretenimiento_Personal_architecture|Arquitectura del Sistema v2.7.2]]
- **Contrato de Datos y API:** [[PRJ_App_Rastreador_de_Entretenimiento_Personal_api_spec|Especificación de API Notion y RAWG]]
- **Plan de Implementación:** [[PRJ_App_Rastreador_de_Entretenimiento_Personal_implementation_plan|Plan de Implementación v2.7.2]]
- **Lista de Tareas:** [[PRJ_App_Rastreador_de_Entretenimiento_Personal_task|Checklist de Tareas]]
- **Historial de Versiones:** [[PRJ_App_Rastreador_de_Entretenimiento_Personal_changelog_v1|Changelog v1]]
- **Reporte de Auditoría y Quality Gate:** [[PRJ_App_Rastreador_de_Entretenimiento_Personal_audit_report|Reporte de Auditoría]]
