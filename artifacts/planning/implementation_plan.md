---
tipo: plan
proyecto: App_Rastreador_de_Entretenimiento
version: v2.3.0
estado: activo
fecha: 2026-08-25
tags: [plan, ui-refactor, dashboard-filters, clean-toolbar, ux-optimization]
---

# 📋 Plan de Implementación: Reorganización y Limpieza de Barra de Filtros (v2.3.0)

## 🎯 Diagnóstico del Problema Visual Actual

En el Dashboard actual existen **dos filas apiladas** de controles:
1. **Fila 1:** Chips de Estado + Dropdown de Orden + Dropdown de Género.
2. **Fila 2:** Carrusel horizontal de Plataformas (12+ chips).

**Problemas detectados:**
- Saturación visual y desalineación en pantallas grandes y móviles.
- Demasiado espacio vertical consumido antes de ver las carátulas de los juegos.
- Competencia visual entre estados, consolas y géneros en tiras horizontales desconectadas.

---

## 💡 Opciones de Solución de Diseño

### 🌟 Opción 1: Barra Unificada de Filtros (Clean Unified Toolbar) — [RECOMENDADA]
- **Estructura en 1 sola fila:**
  - **Izquierda:** Segmented Control limpio para los estados: `[ Todos | Jugando | Por jugar | Jugado ]`.
  - **Derecha:** Tres botones desplegables elegantes estilo dropdown pill:
    - 🎮 `Plataforma: Todas ▾` (Menú emergente con iconos oficiales).
    - 🏷️ `Género: Todos ▾`.
    - ↕️ `Ordenar ▾`.
- **Beneficios:** Reduce la altura visual en un 50%, unifica todos los controles en una sola línea armónica y se ve nativo tanto en PC como en móvil.

### 🎛️ Opción 2: Botón de Filtros Avanzados en Modal / Drawer
- Mantener en pantalla únicamente los estados principales `[ Todos | Jugando | Por jugar | Jugado ]`.
- Un botón flotante o en AppBar `[ 🎛️ Filtros ]` que abre un modal inferior (en móvil) o popover (en PC) con selectores dedicados de Plataformas y Géneros.

### 📂 Opción 3: Acordeón Desplegable de Plataformas
- Mantener los estados y debajo un botón colapsable `[ Mostrar Filtros de Consola (12) ▾ ]`.

---

## 🛠️ Plan de Tareas Propuesto para Opción 1

- [ ] (Frontend) Rediseñar el contenedor superior de `dashboard.dart` a una barra unificada en una sola fila.
- [ ] (Frontend) Implementar el dropdown de Plataformas con iconos temáticos en lugar del carrusel horizontal apilado.
- [ ] (Frontend) Compactar los dropdowns de Género y Ordenamiento en botones pill estilizados con indicadores activos.
- [ ] (Frontend) Añadir botón de reset rápido cuando haya filtros activos de consola o género.
- [ ] (Auditor) Verificar adaptabilidad responsive en resoluciones de móvil (scroll horizontal suave de la barra) y PC (alineación justificada).
