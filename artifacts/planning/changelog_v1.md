---
tipo: changelog
proyecto: App-Rastreador-de-Entretenimiento
version: v2.1.0
estado: completado
fecha: 2026-08-25
tags: [proyecto, changelog, versiones]
---

# Registro de Cambios (Changelog) - Rastreador de Entretenimiento

Todos los cambios notables de este proyecto se documentarán en este archivo.
El formato está basado en [Keep a Changelog](https://keepachangelog.com/es-ES/1.0.0/), y este proyecto se adhiere a [Semantic Versioning](https://semver.org/lang/es/).

## [2.1.0] - 2026-08-25

### Added
- **Modal avanzado al añadir juegos (`SearchScreen`):** Interfaz enriquecida con selección de fecha de inicio con DatePicker, horas jugadas iniciales, selector de estado y plataforma.
- **Selector desplegable de géneros:** Menú colapsable estilo acordeón con chips interactivos para selección múltiple cómoda y rápida, precargando sugerencias de RAWG y opciones de Notion.
- **Buscador en tiempo real en la biblioteca (`DashboardScreen`):** Campo de búsqueda interactivo en el AppBar para filtrar juegos por título, plataforma o género al instante.
- **Soporte y build para Windows (PC Desktop):** Workflow de CI en GitHub Actions (`build_windows.yml`) para compilar y empaquetar el ejecutable de PC (`.zip`).
- **Diseño responsivo móvil/escritorio:** Adaptación dinámica del grid de juegos en el Dashboard con `SliverGridDelegateWithMaxCrossAxisExtent` (ajuste fluido a 2 columnas en móvil y 4-6 columnas en PC).

---

## [2.0.0] - 2026-07-19
### Added
- Migración completa de backend: Reemplazo total de Supabase por Notion API directa.
- Creación de `NotionService` con rate limiter (3 req/s máx) y caché en memoria (TTL 60s).
- Creación de `NotionParser` para traducción bidireccional entre propiedades de Notion y modelos Dart.
- Nueva pantalla `SetupScreen` para configuración de Integration Token y Database ID.
- Rediseño visual "Arcade Noir" con Google Fonts (*Space Grotesk* + *Inter*) y paleta neón.

### Removed
- Eliminación de todas las dependencias y archivos residuales de Supabase (Auth, Storage, Edge Functions).
