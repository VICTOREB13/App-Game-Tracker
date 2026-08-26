---
tipo: plan
proyecto: App_Rastreador_de_Entretenimiento
version: v2.4.0
estado: activo
fecha: 2026-08-25
tags: [plan, branding, victor-engineer, design-system, red-accent, anti-slop, frontend-ui]
---

# 📋 Plan de Implementación: Rediseño Visual "Victor Engineer" Signature Red (v2.4.0)

## 🎯 Objetivo
Transformar toda la interfaz de la aplicación adoptando la identidad visual y estilo de marca personal de **Victor Engineer** extraída de su web oficial (`Homepage`), eliminando cualquier aspecto genérico ("anti-slop") y consolidando una estética de software premium de ingeniería.

---

## 🎨 Sistema de Diseño Victor Engineer (Design Tokens)

### 1. Paleta Cromática
- **Fondo Principal (Scaffold):** `#09090B` (Zinc-950 / Obsidian puro).
- **Superficies y Tarjetas:** `#121215` / `#18181B` (Zinc-900 con bordes sutiles `#27272A` / `rgba(255, 255, 255, 0.08)`).
- **Acento Primario de Marca:** `#DC2626` (Red-600) & `#EF4444` (Red-500) con resplandores `rgba(220, 38, 38, 0.25)`.
- **Texto Primario:** `#FAFAFA` (Zinc-50).
- **Texto Secundario:** `#A1A1AA` (Zinc-400).
- **Texto Muted:** `#71717A` (Zinc-500).
- **Estados de Juego:**
  - `Jugando`: `#DC2626` (Rojo Victor Engineer con indicador de pulso).
  - `Jugado`: `#10B981` (Verde Esmeralda de culminación).
  - `Por jugar`: `#F59E0B` (Ámbar cálido de backlog).

### 2. Tipografía Oficial
- **Display / Titulares / Marca:** `GoogleFonts.outfit()` (Tipografía display oficial de Victor Engineer).
- **Cuerpo / Controles / Números:** `GoogleFonts.inter()` (Legibilidad técnica).

### 3. Logotipo e Isotipo de Marca
- Icono oficial `VE` (`#DC2626` squircle con tipografía blanca gruesa).
- Encabezados de marca: `Victor` + `Engineer` (en rojo).

---

## 🛠️ Tareas de Implementación

- [ ] (Frontend) Actualizar `main.dart` con los tokens de color globales de Victor Engineer (`#09090B`, `#DC2626`, `Outfit` + `Inter`).
- [ ] (Frontend) Rediseñar `dashboard.dart` con la barra superior de marca `Victor Engineer`, Hero Spotlight en rojo de marca, chips y menú unificado.
- [ ] (Frontend) Rediseñar `setup_screen.dart` con la estética Victor Engineer, el isotipo `VE` y gradientes de resplandor carmesí.
- [ ] (Frontend) Actualizar `game_detail_screen.dart` con encabezados en `Outfit`, botones de acción rápida en rojo y ficha cinematográfica ajustada.
- [ ] (Frontend) Actualizar `search_screen.dart` y `analytics_screen.dart` con la nueva paleta y tipografía coherente.
- [ ] (Auditor) Validar consistencia visual, contraste de color accesible (WCAG AA) y armonía de diseño.
