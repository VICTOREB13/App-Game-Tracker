---
tipo: changelog
proyecto: App_Rastreador_de_Entretenimiento
version: v2.4.0
estado: activo
fecha: 2026-08-25
tags: [proyecto, changelog, versiones, victor-engineer, signature-red, anti-slop, frontend-ui]
---

# Registro de Cambios (Changelog) - Rastreador de Entretenimiento

Todos los cambios notables de este proyecto se documentarán en este archivo.
El formato está basado en [Keep a Changelog](https://keepachangelog.com/es-ES/1.0.0/), y este proyecto se adhiere a [Semantic Versioning](https://semver.org/lang/es/).

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

## [2.0.0] - 2026-07-19
### Added
- Migración completa a Notion API directa con rate limiter y caché en memoria.
- Eliminación de Supabase.
- Rediseño visual "Arcade Noir".
