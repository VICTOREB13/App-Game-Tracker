---
tipo: task
proyecto: App-Rastreador-de-Entretenimiento
version: v2.1.0
estado: completado
fecha: 2026-08-25
tags: [tareas, checklist, frontend, backend, devops, auditor]
---

# ✅ Lista de Tareas (Task Checklist) - Iteración v2.1.0

## 🎨 Frontend & UX (`Frontend-UI`)
- [x] (Frontend) Rediseñar el diálogo de adición en `search_screen.dart` con modal completo scrollable.
- [x] (Frontend) Añadir selector de Fecha de Inicio (`showDatePicker`) en el diálogo de adición.
- [x] (Frontend) Añadir campo de Horas Jugadas iniciales en el diálogo de adición.
- [x] (Frontend) Implementar menú desplegable/acordeón (`ExpansionTile` / dropdown) para selección multi-chip de Géneros.
- [x] (Frontend) Implementar buscador en tiempo real (`_searchQuery` + live filtering) en `dashboard.dart` con toggle en el AppBar.
- [x] (Frontend) Convertir el grid del `dashboard.dart` a responsivo con `SliverGridDelegateWithMaxCrossAxisExtent` para pantallas de PC/Desktop.

## ⚙️ Backend & Notion Layer (`Backend-Architect`)
- [x] (Backend) Actualizar `_addGameToNotion` en `search_screen.dart` para enviar `Fecha de Inicio`, `Horas Jugadas` y lista depurada de `Géneros` a Notion API.

## 🚀 CI/CD & Plataforma Desktop (`DevOps-Engineer`)
- [x] (DevOps) Crear workflow `.github/workflows/build_windows.yml` para compilar y empaquetar el ejecutable de Windows (Release Fat Zip) vía GitHub Actions.

## 🛡️ Auditoría & Quality Gate (`Systems-Auditor`)
- [x] (Auditor) Ejecutar revisión de código, control de linter y verificación de compatibilidad de tipos en modelos y parsers.
