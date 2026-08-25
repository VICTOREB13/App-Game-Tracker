---
tipo: changelog
proyecto: App_Rastreador_de_Entretenimiento
version: v2.2.0
estado: completado
fecha: 2026-08-25
tags: [proyecto, changelog, versiones]
---

# Registro de Cambios (Changelog) - Rastreador de Entretenimiento

Todos los cambios notables de este proyecto se documentarán en este archivo.
El formato está basado en [Keep a Changelog](https://keepachangelog.com/es-ES/1.0.0/), y este proyecto se adhiere a [Semantic Versioning](https://semver.org/lang/es/).

## [2.2.0] - 2026-08-25 (Gamer Hub & Minimalist Branding)

### Added
- **Nuevo Logo Minimalista:** Isotipo oficial sobrio con silueta de gamepad sobre squircle oscuro mate en `assets/images/app_logo.jpg` integrado en la app.
- **Hero Spotlight "Jugando Ahora":** Banner interactivo en el Dashboard para títulos activos con barra de progreso HLTB vs Horas y botón rápido `+1h` con actualización optimista.
- **Microinteracciones Zero-Friction:** Botones de incremento rápido (`+30m`, `+1h`, `+2h`), autocompletado inteligente de fecha de culminación y menú contextual por pulsación prolongada (Long Press).
- **Logos de Plataformas & Filtro Dedicado:** Insignias visuales con paletas oficiales de marca (PlayStation, Xbox, Switch, PC) y carrusel de filtrado por consola en el Dashboard.
- **Detalle de Juego Cinematográfico:** Cabecera con degradado inmersivo y panel de tiempos HowLongToBeat enriquecido.
- **Calculadora de Backlog & Stats Anuales:** Métrica de tiempo pendiente en biblioteca y analíticas de juegos completados en el año actual (2026).

---

## [2.1.0] - 2026-08-25
### Added
- Modal avanzado de adición con DatePicker, horas iniciales y selector desplegable de géneros.
- Buscador en tiempo real en la biblioteca dentro del Dashboard.
- Soporte y workflow de compilación para Windows PC (Desktop).
- Layout responsivo con columnas dinámicas para pantallas grandes.

---

## [2.0.0] - 2026-07-19
### Added
- Migración completa a Notion API directa con rate limiter y caché en memoria.
- Eliminación de Supabase.
- Rediseño visual "Arcade Noir".
