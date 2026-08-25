---
tipo: plan
proyecto: App-Rastreador-de-Entretenimiento
version: v2.1.0
estado: activo
fecha: 2026-08-25
tags: [plan, search-ui, dashboard-filter, pc-desktop, notion]
---

# 📋 Plan de Implementación: Búsqueda Avanzada, Filtro en Biblioteca y Soporte PC (v2.1)

## 🎯 Objetivo de la Iteración

Elevar la experiencia de usuario y alcance multiplataforma de la aplicación mediante:
1. **Modal Enriquecido al Añadir Juegos (`SearchScreen`):** Permitir configurar fecha de inicio, horas iniciales, plataforma, estado, calificación y selección de géneros mediante un menú desplegable/acordeón intuitivo y ergonómico.
2. **Buscador / Filtro en Tiempo Real en la Biblioteca (`DashboardScreen`):** Barra de búsqueda integrada en la cabecera para filtrar instantáneamente por título de juego dentro de los juegos ya cargados de Notion.
3. **Adaptación y Compilación para PC Desktop (Windows):** Layout responsivo en grids y diálogos, y flujo automatizado en GitHub Actions para generar el binario `.zip` de Windows.

---

## 🛠️ Desglose de Tareas por Agente Especializado

### 1. `Frontend-UI` (Experiencia de Usuario y Vistas)
- **Modal de Adición de Juegos (`search_screen.dart`):**
  - Reemplazar el `AlertDialog` básico por un modal completo/scrollable (`SingleChildScrollView` con `BoxConstraints(maxWidth: 550)`).
  - Selector de **Fecha de Inicio** con `showDatePicker` y botón de reset.
  - Campo numérico para **Horas Jugadas Iniciales**.
  - **Menú Desplegable / Expandible de Géneros:** Crear componente `ExpansionTile` o dropdown de acordeón con chips interactivos para seleccionar/deseleccionar géneros fácilmente sin saturar la pantalla.
  - Precargar géneros sugeridos desde RAWG y combinarlos con la lista oficial de Notion.
- **Buscador en Vivo en Biblioteca (`dashboard.dart`):**
  - Añadir botón de búsqueda en el `AppBar` que despliegue un campo de texto con animación o transición limpia.
  - Filtrado reactivo en memoria: combinar filtro de texto (`_searchQuery`) con filtro de estado (`_selectedStatusFilter`).
  - Mostrar estado vacío descriptivo cuando no haya coincidencias de búsqueda.
- **Diseño Responsivo Desktop (`dashboard.dart` y temas):**
  - Reemplazar `SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2)` por `SliverGridDelegateWithMaxCrossAxisExtent` (max width ~200-240px) para que en pantallas de PC se muestren de 4 a 6 columnas automáticamente de forma fluida.

### 2. `Backend-Architect` (Integración y Parsers)
- Verificar y asegurar que los campos enviados desde `SearchScreen` (`startDate`, `hoursPlayed`, `genres`, `rating`, `coverUrl`, `hltbMain`) se mapeen sin discrepancias a través de `NotionParser` y `NotionService.createPage`.

### 3. `DevOps-Engineer` (Automatización CI/CD para PC)
- Crear el workflow de GitHub Actions `.github/workflows/build_windows.yml` para compilar automáticamente la versión de Windows (`flutter build windows --release`) y empaquetar el binario en un `.zip` descargable en los artifacts de GitHub.

### 4. `Systems-Auditor` (Quality Gate)
- Auditar la ausencia de regresiones en móvil y PC, verificar rate-limiting en Notion y validar responsive breakpoints.

---

## 🔄 Criterios de Aceptación

1. Al pulsar sobre cualquier juego en la búsqueda de RAWG, se abre un diálogo completo y responsivo donde el usuario puede definir fecha de inicio, horas, plataforma, estado y géneros en un selector desplegable.
2. Al pulsar "Añadir", la página creada en Notion incluye todos estos campos correctamente formateados.
3. En el Dashboard existe un botón/buscador para encontrar cualquier juego de la biblioteca por nombre en tiempo real.
4. El Dashboard se adapta visualmente tanto a pantallas de teléfono móvil (2 columnas) como a pantallas anchas de PC (múltiples columnas con proporción estética).
5. Existe un workflow de CI funcional para compilar la versión de Windows.
