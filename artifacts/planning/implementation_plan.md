---
tipo: plan
proyecto: App_Rastreador_de_Entretenimiento
version: v2.2.0
estado: activo
fecha: 2026-08-25
tags: [plan, gamer-hub, hero-spotlight, zero-friction, platform-badges, cinematic-detail, backlog-calculator]
---

# 📋 Plan de Implementación: Gamer Hub & Experiencia de Entretenimiento (v2.2.0)

## 🎯 Objetivo de la Iteración

Transformar el rastreador de videojuegos en una experiencia inmersiva de nivel profesional (*Gamer Hub*), implementando las 5 áreas clave de mejora funcional y visual, junto con el nuevo isotipo de entretenimiento.

---

## 🚀 Desglose de Funcionalidades

### 1. 🌟 Hero Banner "Jugando Ahora" (Dashboard)
- Renderizar un banner panorámico destacado en la parte superior del `DashboardScreen` cuando existan juegos en estado `"Jugando"`.
- Barra de progreso neón integrada que compara `Horas Jugadas` vs `HLTB Principal` (ej: `28h / 45h - 62%`).
- Botón rápido `+1h` directo en el banner para registrar sesiones de juego al instante sin entrar a editar.

### 2. ⚡ Microinteracciones y Registro Rápido ("Zero Friction")
- **Botones de incremento rápido en `GameDetailScreen`:** Botones accesibles (`+30m`, `+1h`, `+2h`) que incrementan el contador de horas y guardan automáticamente.
- **Autocompletado de Fecha de Culminación:** Al cambiar el estado a `"Jugado"`, si la fecha de culminación está vacía, se asigna automáticamente la fecha del día (`DateTime.now()`).
- **Menú Contextual Rápido (Long Press):** Mantener presionada una tarjeta de juego en el grid para desplegar un modal rápido con acciones: *Cambiar Estado*, *Sumar +1h*, o *Eliminar*.

### 3. 🎮 Logos de Plataformas e Insignias Neón + Filtro Secundario
- Componente `PlatformBadge` que mapea cada plataforma a su color de marca característico (PlayStation Azul, Switch Rojo, Xbox Verde, PC/Steam Cyan) e icono representativo.
- Carrusel horizontal secundario en el Dashboard para filtrar la biblioteca por plataforma específica ("Todas", "PC", "Playstation 5", "Nintendo Switch", etc.).

### 4. 🖼️ Pantalla de Detalle Cinematográfica (Hero Backdrop & Ficha Técnica)
- Encabezado con efecto de fondo panorámico en degradado negro sobre la carátula del juego.
- Bloque de métricas rápidas: Calificación en estrellas destacada, Tiempos HowLongToBeat completos (*Historia Principal*, *Completista 100%*), y tags de géneros estilizados.

### 5. 📊 Gamificación & "Backlog Pulse" en Analíticas
- **Calculadora de Backlog:** Métrica en `AnalyticsScreen` que suma las horas estimadas de todos los títulos en *"Por jugar"* y proyecta el tiempo total pendiente.
- **Resumen del Año en Curso (2026):** Contador de títulos completados en el año actual y promedio de horas por juego completado.

### 6. 🎨 Nuevo Logo de Entretenimiento (Asset & UI)
- Actualización de `pubspec.yaml` para incluir el asset `assets/images/app_logo.jpg`.
- Integración del nuevo isotipo en la pantalla de bienvenida (`SetupScreen`), app bar icons y branding del proyecto.

---

## 🛠️ Asignación de Tareas por Rol

- **`Frontend-UI`:** Construcción del `HeroBanner`, `PlatformBadge`, rediseño cinemático de `GameDetailScreen`, carrusel de plataformas y actualización de `SetupScreen` con el nuevo logo.
- **`Backend-Architect`:** Lógica de actualización optimista de horas (+1h), cálculo de progreso HLTB y auto-asignación de fecha de culminación.
- **`Systems-Auditor`:** Verificación de rendimiento en animaciones, responsive breakpoints en móvil y PC, y control de linter.
- **`DevOps-Engineer`:** Asegurar empaquetado de assets en compilaciones de Android (APK) y Windows (PC ZIP).
