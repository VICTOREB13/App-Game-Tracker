---
tipo: changelog
proyecto: App_Rastreador_de_Entretenimiento_Personal
version: v2.8.0
estado: activo
fecha: 2026-08-26
tags: [proyecto, changelog, versiones, v2.8.0, filter-modal-sheet, genre-helper, json-backup, touch-filters, victor-engineer]
---

# Registro de Cambios (Changelog) - Rastreador de Entretenimiento Personal

Todos los cambios notables de este proyecto se documentarán en este archivo.
El formato está basado en [Keep a Changelog](https://keepachangelog.com/es-ES/1.0.0/), y este proyecto se adhiere a [Semantic Versioning](https://semver.org/lang/es/).

## [2.8.0] - 2026-08-26 (QoL & Filter Reorganization, Virtual Normalization & Dual JSON Backup)

### Added & Enhanced
- **Reorganización Táctil de Filtros (`FilterModalSheet`):**
  - Reemplazados los menús desplegables rígidos y kilométricos por un componente modal interactivo y adaptativo (BottomSheet en Android/móvil y Diálogo en escritorio).
  - **Buscador en Tiempo Real:** Campo de texto integrado en la cabecera que permite filtrar géneros y plataformas al instante mientras se teclea.
  - **Conteo Dinámico por Categoría:** Cada opción muestra una pastilla numérica con la cantidad exacta de juegos asociados (ej. `Acción (18)`, `Nintendo Switch (12)`), ordenadas por frecuencia de títulos.
  - **Acción Rápida Todos:** Opción directa para restablecer a *"Todos / Todas"* con 1 solo toque.
- **Normalización Semántica Virtual de Géneros (`GenreHelper`):**
  - Mapeo canónico transparente en memoria que unifica sinónimos bilingües de Notion y RAWG (ej: `Action` $\rightarrow$ `Acción`, `Adventure` $\rightarrow$ `Aventura`, `Racing` $\rightarrow$ `Carreras`, `RPG` $\rightarrow$ `Rol / RPG`).
  - **Cero Modificaciones en Notion:** La base de datos remota no sufre ninguna alteración, eliminando cualquier riesgo de corrupción o rate limits.
  - **Iconografía y Colores Temáticos:** Cada género dispone de un icono semántico dedicado (espadas, mira, mapa, volante, calavera, etc.) y un color característico en lugar del icono genérico anterior.
- **Copia de Seguridad y Portabilidad Local (`BackupService`):**
  - **Exportar Biblioteca (JSON):** Genera y descarga un archivo estructurado `tracker_backup_YYYYMMDD_HHmmss.json` en la carpeta de Descargas con todos los registros y propiedades de la biblioteca.
  - **Importar / Restaurar Biblioteca (JSON):** Modal en Ajustes que detecta respaldos recientes en Descargas y permite restaurar la biblioteca local de inmediato offline o al cambiar de dispositivo.
- **Calidad de Vida en Biblioteca (Dashboard QoL):**
  - **Contador de Filtros Activos:** El botón de limpieza en la barra de herramientas ahora muestra dinámicamente la cantidad de filtros aplicados (`Limpiar (X)`).
  - **Botón de Borrado Rápido en Buscador:** Borrado instantáneo del término de búsqueda con un toque.
- **Pulido Visual del Modal de Filtros (`FilterModalSheet`):**
  - **Eliminación de Barra Negra:** Erradicado el divisor huérfano entre el buscador y la lista que generaba una línea oscura discordante en modo claro.
  - **Bordes Redondeados Completos:** Aplicado radio de curvatura total (`BorderRadius.circular(24)`) y margen inferior flotante con `Clip.antiAlias` para que el modal termine con elegantes bordes redondeados tanto en la parte superior como inferior.
- **Adaptación de Botones Rápidos de Horas en Modo Claro (`GameDetailScreen`):**
  - **Botones de Tiempo (`+30m`, `+1h`, `+2h`):** Adaptados dinámicamente según el tema activo; en modo claro lucen un elegante fondo suave `#FEF2F2` con tipografía carmesí `#DC2626` y borde sutil, eliminando los bloques negros aislados.
  - **Barra de Progreso HLTB:** El track de fondo de la barra de progreso de campaña ahora emplea un gris suave `#E4E4E7` en modo claro en lugar de la barra negra `#27272A`.

## [2.7.2] - 2026-08-26 (Light Mode Contrast Polish, Smart Sync & FAB Clearance)

### Fixed & Enhanced
- **Contraste y Legibilidad en Modo Claro (Anti-Slop):**
  - **Filtros y Chips:** Rediseñados los chips de estado (`Todos`, `Jugando`, `Por jugar`, `Jugado`) con fondo blanco `#FFFFFF`, borde sutil `#E4E4E7` y tipografía de alto contraste cuando no están seleccionados, eliminando cajas oscuras huérfanas en modo claro.
  - **Menús Desplegables (`Plataforma`, `Género`, `Orden`):** Migrados a tokens semánticos `AppColors`, mostrando fondos de superficie reactivos, bordes elegantes y texto oscuro (`#09090B`) con acento rojo `#DC2626` cuando están activos.
  - **Buscador en Biblioteca:** Corregido el color de texto del campo de búsqueda en el AppBar para mostrar texto oscuro sobre fondo claro en vez de blanco invisible.
  - **Hero Spotlight:** Contenedor superior adaptado con superficies suaves y bordes de acento para integrarse con naturalidad en temas claro y oscuro.
- **Paginación Centrada y Despeje de FAB (+ Añadir):**
  - **Resolución de Colisión:** Centrados los controles de navegación `< X / Y >` en la barra inferior mediante espaciadores elásticos (`Spacer`), incorporando una zona de seguridad lateral de 100px a la derecha. El botón flotante `+ Añadir` ya no colisiona ni oculta la flecha de página siguiente.
  - **Fondo de Barra Inferior:** Sustituido el fondo oscuro estático `#0D0D10` por `AppColors.surface(context)` con borde superior semántico.
- **Smart Sync & Optimización de Sincronización con Notion:**
  - **Chequeo Ultrarrápido (Head Check):** Antes de descargar todos los registros, la app consulta únicamente 1 registro remoto ordenado por `last_edited_time`. Si coincide con la marca de tiempo de la caché local, retorna de inmediato sin transferir cientos de registros innecesarios.
  - **Timeout HTTP de Seguridad:** Incorporado un límite estricto de 15 segundos en todas las llamadas de red (`http.get`, `http.post`, `http.patch`) para evitar que la app quede congelada o esperando indefinidamente.
- **Tarjeta Social Exportable Adaptativa (Modo Claro / Oscuro):**
  - La ventana modal de compartir y exportar reseña en PNG (`_showSocialCardDialog`) ahora detecta y adopta automáticamente el modo visual activo del usuario (Claro u Oscuro).
  - Se incorporó un conmutador interactivo `[ ☀️ Claro | 🌙 Oscuro ]` en la cabecera del modal que permite previsualizar y alternar el tema de la postal gráfica antes de exportar.
  - En modo claro, la tarjeta se renderiza con fondo blanco puro `#FFFFFF`, bordes zinc `#E4E4E7`, tipografía oscura `#09090B` y branding `#DC2626`. El archivo exportado se guarda automáticamente con el sufijo `_Light_` o `_Dark_` en la carpeta Descargas.
- **Logotipos de Plataformas de Alto Contraste & Multi-Modo:**
  - **Nintendo Switch:** Generado e implementado el nuevo icono 1:1 Joy-Con (`nintendo_switch_logo.png`) en rojo oficial (`#E60012`), resolviendo el problema de invisibilidad y distorsión que sufría el banner de texto 4:1 en modo oscuro y claro.
  - **Nintendo Retro (DS, Wii, N64):** Generada insignia 1:1 (`nintendo_badge_red.png`) en píldora roja con tipografía blanca nítida, 100% legible sobre fondos oscuros y claros.
  - **Xbox:** Generada esfera 1:1 (`xbox_logo_green.png`) en verde oficial `#107C10`, erradicando el logo negro plano que se perdía en temas oscuros.
  - **Steam / PC:** Corregido el mapeo de recursos para cargar el icono circular azul/blanco (`steam-logo-steam-icon-transparent-free-png.webp`) en vez del texto blanco plano que se camuflaba en modo claro.
  - **GOG & Epic Games:** Creados recursos optimizados (`gog_logo_purple.png` en púrpura oficial y `epic_games_logo_bordered.png` con contorno de escudo protector).
- **Selector de Tema en Pantalla de Conexión (`SetupScreen`):**
  - Incorporada la tarjeta de selección visual de tres opciones (`[ 🌙 Oscuro | ☀️ Claro | 🖥️ Sistema ]`) en la pantalla de conexión y edición de credenciales de Notion.
  - Conectado a `ThemeManager.instance` con reactividad instantánea al hacer clic en cualquiera de las opciones de tema.
  - Añadido soporte de barra superior con botón de regreso (`Navigator.pop`) y restricciones de ancho máximo (520px) para pantallas de escritorio.

---

## [2.7.1] - 2026-08-26 (Hotfix: Notion Page Creation & Build Stability)

### Fixed
- **Corrección de Error de Compilación en `SearchScreen`:**
  - Solucionado el error `The method 'createGame' isn't defined for the type 'NotionService'` en `search_screen.dart` restaurando la invocación canónica `await notion.createPage(notion.gamesDbId, properties)`.
  - Se implementó además el método helper `createGame(properties)` en `NotionService` para garantizar interoperabilidad completa y prevenir regresiones futuras en compilaciones CI de Windows/Linux.

---

## [2.7.0] - 2026-08-26 (Crisp Zinc Light Mode & Cross-App Theme Architecture)

### Added & Polished
- **Modo Claro "Crisp Zinc" (Light Mode):**
  - Integración completa de un tema claro elegante y de alto contraste (fondo `#FAFAFA`, superficies `#FFFFFF`, bordes sutiles `#E4E4E7`, texto `#09090B` y acento rojo Victor Engineer `#DC2626`).
  - Mantenimiento idéntico e intacto del **Modo Oscuro (Obsidian Zinc `#09090B`)**.
  - Toggle directo de 1 clic en la barra superior del `DashboardScreen` con iconos animados de sol/luna.
  - Selector de tema de 3 opciones en `SettingsScreen`: **Oscuro**, **Claro** y **Sistema** (sigue el SO).
  - Persistencia automática de la preferencia en `SharedPreferences` (`preferred_theme_mode`).
- **Arquitectura Centralizada de Color (`AppColors` & `ThemeManager`):**
  - Adaptación transversal en `DashboardScreen`, `AnalyticsScreen`, `GameDetailScreen`, `SearchScreen`, `SettingsScreen` y `SetupScreen`.
  - Degradados adaptativos, filtros, chips de géneros y diálogos que reaccionan instantáneamente sin reiniciar la app.
- **Renovación Completa de `SettingsScreen`:**
  - Sustitución de colores cian/magenta heredados por la paleta oficial Victor Engineer.
  - Tarjetas de estado de conexión, gestión de clave RAWG API, vaciado de caché y metadatos de versión.
- **Refinamiento de Búsqueda RAWG (`SearchScreen`):**
  - Diálogo modal y acordeón de géneros con estilos acordes al tema activo y acento rojo.

---

## [2.6.0] - 2026-08-26 (Definitive Release: Offline Cache, Dual View, Pagination & Gamification)

### Added
- **Caché Persistente Offline (0 ms Cold-Start):**
  - Implementación de almacenamiento serializado local mediante `SharedPreferences` en `NotionService`.
  - Carga inmediata de la biblioteca al iniciar la aplicación sin pantallas de carga previas y sincronización en background (*Stale-While-Revalidate*).
  - Indicador sutil de *"Modo Local"* en caso de falta de conexión a internet o latencia de Notion.
- **Selector de Vista Dual (Grid Cinematográfico vs. Lista Compacta):**
  - Toggle interactivo `[ ⊞ Grid | ☰ Lista ]` en la barra de herramientas del Dashboard con persistencia en disco.
  - Componente de alta densidad `_GameListRow`: miniatura redondeada de carátula (36x48), título en `Outfit`, badge temático de plataforma, estado, barra HLTB, estrellas y botón rápido `+1h`.
- **Sistema de Paginación Inteligente:**
  - Selector de tamaño de página: **10**, **25**, **50**, **100** o **Todos** persistido en memoria local.
  - Controles de navegación con botones estilizados `< Anterior`, indicador de página activa (`Página X de Y`) y `Siguiente >`.
  - Reseteo automático a página 1 al aplicar nuevos filtros o realizar búsquedas en tiempo real.
- **Gamificación Dinámica Multi-Año en Analíticas:**
  - Selector interactivo de año `< [Año] >` que recalcula el balance histórico y permite proyectar metas en años futuros (2025, 2026, 2027...).
  - Meta anual editable (`annual_game_goal_${year}`) con barra de progreso circular en `#DC2626` y badge de logro.
  - **Salón de la Fama / Récords Personales:**
    - 👑 *El Titán* (Juego completado con mayor tiempo acumulado).
    - ⭐ *Obra Maestra* (Juego con 5 estrellas y mayor dedicación).
    - ⚡ *Aventura Ágil* (Juego completado en menor tiempo).
  - Medidor de salud y tasa porcentual de finalización de biblioteca (*Backlog Health*).
- **Generador de Tarjeta Social / Reseña Exportable (PNG):**
  - Botón de exportación en la pantalla de detalle (`GameDetailScreen`).
  - Renderizado de tarjeta estilizada con squircle `VE`, título, plataforma, calificación en estrellas, horas jugadas, fecha de culminación y cita de reseña personal.
  - Captura en alta resolución mediante `RepaintBoundary` (2.5x pixel ratio) y guardado directo en la carpeta `Descargas` del usuario en Windows.

---

## [2.5.0] - 2026-08-25 (Fluid Motion & Microinteractions System)

### Added & Animated
- **Microinteracciones en Tarjetas de Juego (`_GameCard`):**
  - Efecto hover interactivo con escala suave (`1.035`), resplandor carmesí (`#DC2626` 0.22 opacity) y transición de borde en 220ms (`Curves.easeOutCubic`).
  - Respuesta táctil al toque (press down scale `0.97`) en 180ms.
- **Transiciones Cinematográficas Hero:**
  - Vuelo y acople fluido de portadas (`Hero(tag: 'game-cover-${id}')`) entre el grid de biblioteca y la pantalla de detalle (`GameDetailScreen`).
- **Entrada Escalonada del Grid (Staggered Animations):**
  - Cascada de entrada suave con fade-in y desplazamiento vertical (`16px -> 0px`) con curvas cúbicas calculadas por índice (`TweenAnimationBuilder`).
- **Pulsing Glow en Hero Spotlight:**
  - Animación continua de respiración luminosa para el punto de estado `JUGANDO AHORA` con `AnimationController`.
- **Barras de Progreso Animadas:**
  - Llenado progresivo de las barras de progreso HLTB en Dashboard y Game Detail con `TweenAnimationBuilder` (600ms `Curves.easeOutCubic`).
- **Navegación Fluida de Pantallas (`_buildFluidPageRoute`):**
  - Transición personalizada compartida con fade y deslizamiento suave (260ms) para Ficha, Búsqueda, Analíticas y Configuración.

---

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
