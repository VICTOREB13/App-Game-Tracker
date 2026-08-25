---
tipo: task
proyecto: App_Rastreador_de_Entretenimiento
version: v2.2.0
estado: completado
fecha: 2026-08-25
tags: [tareas, checklist, gamer-hub, frontend, backend, devops, auditor]
---

# ✅ Lista de Tareas (Task Checklist) - Iteración v2.2.0

## 🎨 Frontend & UI/UX (`Frontend-UI`)
- [x] (Frontend) Habilitar `assets/images/` en `pubspec.yaml` e integrar el nuevo logo minimalista en `SetupScreen` y AppBar.
- [x] (Frontend) Crear e integrar el componente **Hero Spotlight "Jugando Ahora"** en `dashboard.dart` con barra de progreso y botón `+1h`.
- [x] (Frontend) Implementar menú contextual al mantener presionado (Long Press) en las tarjetas del grid en `dashboard.dart`.
- [x] (Frontend) Crear el componente `PlatformBadge` con colores temáticos de marca y añadir filtro horizontal de plataformas en `dashboard.dart`.
- [x] (Frontend) Rediseñar `game_detail_screen.dart` con encabezado cinematográfico (backdrop blur/gradient), botones de incremento rápido (+30m, +1h, +2h) y ficha técnica HLTB destacada.
- [x] (Frontend) Añadir a `analytics_screen.dart` la **Calculadora de Backlog** y el **Resumen del Año (2026)**.

## ⚙️ Backend & Lógica de Datos (`Backend-Architect`)
- [x] (Backend) Implementar autocompletado de `Fecha de Culminación` al cambiar estado a `"Jugado"`.
- [x] (Backend) Función de actualización optimista de horas para los accesos rápidos sin recargar la pantalla completa.

## 🛡️ Auditoría & Quality Gate (`Systems-Auditor`)
- [x] (Auditor) Validar responsividad del Hero Banner y carruseles tanto en móvil como en PC.
- [x] (Auditor) Verificar integridad de assets en la compilación.
