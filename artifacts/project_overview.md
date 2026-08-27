---
tipo: overview
proyecto: App_Rastreador_de_Entretenimiento
estado: activo
version: v2.7.1
fecha: 2026-08-26
tags: [proyecto, overview, notion, flutter, entretenimiento, gaming, victor-engineer, light-mode, dark-mode, multi-year, offline-cache]
---

# 🚀 Visión General del Proyecto: Rastreador de Entretenimiento

Aplicación multiplataforma de grado profesional (Windows Desktop x64 y Android) desarrollada en **Flutter 3.22+**, conectada directamente a la **API de Notion** como base de datos en la nube sin intermediarios, enriquecida con metadatos de **RAWG API** y diseñada bajo la identidad visual de marca personal **Victor Engineer** (acento Rojo `#DC2626`, tipografías Google Fonts `Outfit` + `Inter`, y soporte nativo dual de **Modo Oscuro Obsidian Zinc** y **Modo Claro Crisp Zinc**).

---

## 📖 Capacidades y Funcionalidades Principales (v2.7.1)

### 1. 🗄️ Gestión Integral y Bidireccional de Biblioteca (Notion API)
- Conexión directa mediante *Internal Integration Token* de Notion sin intermediarios (Supabase eliminado).
- Control exhaustivo de campos: Título, Estado (*Por jugar*, *Jugando*, *Jugado*), Plataforma, Horas Jugadas, Fechas de Inicio y Culminación, Calificación en estrellas (1-5), Tiempos HowLongToBeat (Principal, Extra, 100%), Géneros, Portada y Reseña/Notas personales.
- Sincronización transparente con actualización optimista en la interfaz para cambios instantáneos.

### 2. ⚡ Rendimiento Extremo y Caché Persistente Offline (0 ms Cold-Start)
- Almacenamiento local en disco con `SharedPreferences` que retiene la última instantánea serializada de la biblioteca.
- Patrón **Stale-While-Revalidate**: La aplicación inicia en **0 ms** mostrando inmediatamente todos los títulos y actualiza en segundo plano cualquier cambio de Notion.
- Modo de contingencia sin conexión (*Offline Mode*) con indicador sutil en pantalla si la red no está disponible o Notion tiene latencia.

### 3. 🎨 Arquitectura de Temas Dinámicos & Sistema de Diseño Victor Engineer
- **Modo Oscuro (Obsidian Zinc):** Fondo ultra profundo `#09090B`, tarjetas `#121215`, bordes `#27272A` y acento rojo carmesí `#DC2626`.
- **Modo Claro (Crisp Zinc):** Fondo limpio `#FAFAFA`, tarjetas blancas `#FFFFFF`, bordes sutiles `#E4E4E7`, texto `#09090B` y acento rojo `#DC2626`.
- **Alternancia Instantánea (`ThemeManager`):** Toggle de 1 clic en la barra superior (`Icons.light_mode_rounded` / `Icons.dark_mode_rounded`) y selector de 3 opciones en Configuración (`Oscuro`, `Claro`, `Sistema`).

### 4. 🎛️ Selector de Vista Dual (Grid Cinematográfico vs. Lista Compacta)
- **Grid Cinematográfico:** Tarjetas con portadas a escala completa, resplandor en hover, micro-barra de progreso HLTB y badges de estado.
- **Lista Compacta (`_GameListRow`):** Fila de alta densidad (54px) con miniatura de carátula (36x48), título en `Outfit`, insignias oficiales de plataforma, pill de estado, estrellas y botón rápido `+1h`.
- Preferencia persistida en disco para recordar la vista favorita del usuario.

### 5. 📄 Sistema de Paginación Inteligente
- Selector de densidad: **10**, **25**, **50**, **100** o **Todos** los registros.
- Controles inferiores con botones estilizados `< Anterior`, indicador de `Página X de Y` y `Siguiente >`.
- Reseteo automático a la primera página al filtrar o realizar búsquedas en tiempo real.

### 6. 🎯 Gamificación y Metas Anuales Dinámicas Multi-Año
- Stepper de año `< [Año] >` que permite auditar balances pasados (2024, 2025, 2026) y planificar metas en años futuros (2027 y más allá) sin obsolescencia.
- Metas independientes por año con barra de progreso circular en `#DC2626`.
- **Salón de la Fama / Récords Personales:**
  - 👑 *El Titán* (Juego completado con mayor tiempo acumulado).
  - ⭐ *Obra Maestra* (Juego con 5 estrellas y máxima dedicación).
  - ⚡ *Aventura Ágil* (Juego completado en menor tiempo).
- Medidor de salud de biblioteca (*Backlog Health*) y desglose porcentual de finalización.

### 7. 🖼️ Generador de Tarjeta Social / Reseña Exportable (PNG)
- Captura de alta resolución mediante `RepaintBoundary` (pixel ratio 2.5x).
- Generación de imagen lista para compartir en Discord o redes sociales con branding oficial `VE`, carátula, estrellas, horas, fecha y cita personal.
- Guardado directo en la carpeta `%USERPROFILE%\Downloads` en Windows.

### 8. 🔍 Búsqueda Inteligente y Autocompletado (RAWG API)
- Búsqueda en catálogo de más de 500,000 videojuegos con carátulas en HD.
- Modal enriquecido para asignar estado, plataforma, fecha de inicio, horas y selección múltiple de géneros con acordeón temático.
- Inserción directa en Notion mediante `createPage` con tolerancia y compatibilidad retroactiva.

---

## 🗺️ Índice de Artefactos del Proyecto

- **Arquitectura del Sistema:** [[PRJ_App_Rastreador_de_Entretenimiento_architecture|Arquitectura del Sistema v2.7.1]]
- **Contrato de Datos y API:** [[PRJ_App_Rastreador_de_Entretenimiento_api_spec|Especificación de API Notion y RAWG]]
- **Plan de Implementación:** [[PRJ_App_Rastreador_de_Entretenimiento_implementation_plan|Plan de Implementación v2.7.1]]
- **Lista de Tareas:** [[PRJ_App_Rastreador_de_Entretenimiento_task|Checklist de Tareas]]
- **Historial de Versiones:** [[PRJ_App_Rastreador_de_Entretenimiento_changelog_v1|Changelog v1]]
- **Reporte de Auditoría y Quality Gate:** [[PRJ_App_Rastreador_de_Entretenimiento_audit_report|Reporte de Auditoría]]
