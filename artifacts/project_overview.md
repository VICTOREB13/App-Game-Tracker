---
tipo: overview
proyecto: App_Game_Tracker
estado: activo
version: v3.1.0
fecha: 2026-09-01
tags: [proyecto, overview, sqlite, local-first, steam-api, howlongtobeat, rawg-api, wikipedia-api, flutter, entretenimiento, gaming, victor-engineer, open-source, v3.1.0]
---

# 🚀 Visión General del Proyecto: Rastreador de Entretenimiento Personal (v3.1.0)

Aplicación multiplataforma de grado profesional (Windows Desktop x64 y Android) desarrollada en **Flutter 3.22+**, impulsada por un motor de almacenamiento **100% Local-First** con **SQLite**, sincronización inteligente con la **Steam Web API**, servicio nativo de **HowLongToBeat**, enriquecida con metadatos de **RAWG API** y **Wikipedia**, empaquetada como software **Open Source** y diseñada bajo la identidad visual de marca personal **Victor Engineer** (acento Rojo Carmesí `#DC2626`, tipografías Google Fonts `Outfit` + `Inter`, y soporte nativo dual de **Modo Oscuro Obsidian Zinc** y **Modo Claro Crisp Zinc**). Enlace oficial: [victorengineer.fyi](https://victorengineer.fyi).

---

## 📖 Capacidades y Funcionalidades Principales (v3.0.5)

### 1. ⚡ Motor de Base de Datos Local-First (SQLite 3)
- **Cero Latencia (0 ms Cold Start):** Desacople total de bases de datos remotas. La aplicación inicia instantáneamente leyendo la base de datos local SQLite (`app_game_tracker.db` / `tracker.db`).
- **Aceleración Indexada:** Índices B-Tree optimizados en `steam_id`, `status`, `platform` y `title` para consultas y filtrados en menos de 2 ms.
- **Mantenimiento en Caliente:** Soporte de optimización y defragmentación en vivo mediante comando `VACUUM` accesible desde la pantalla de Configuración.
- **Privacidad Absoluta:** La colección y partidas del usuario residen 100% en el almacenamiento local del dispositivo sin fuga de datos a servidores externos.

### 2. 🔄 Sincronización Inteligente con Steam Web API (`SteamService`)
- **Consulta Dual Avanzada:** Combina `GetOwnedGames` (biblioteca propia comprada) con `GetRecentlyPlayedGames` para detectar títulos jugados mediante **Family Sharing** y horas recientes.
- **Filtro de Ruido (30 Minutos):** Descarta automáticamente demos y juegos con menos de 0.5 horas registradas.
- **Algoritmo de Matching Tri-Fase Resiliente:** Coincidencia por `AppID` $\rightarrow$ Nombre normalizado $\rightarrow$ Similitud difusa Sørensen-Dice / Levenshtein ($> 0.90$).
- **Resolución de Vanity URL:** Convierte alias de perfiles públicos de Steam a identificadores numéricos SteamID64 de 17 dígitos automáticamente.
- **Auto-Culminación por HLTB:** Si las horas jugadas acumuladas alcanzan o superan la duración de la historia principal (`hltb_main`), el juego se marca de inmediato como *Jugado* con fecha de finalización automática.

### 3. ⏱️ Servicio Nativo HowLongToBeat (`HltbService`)
- **Cliente HTTP Directo:** Consulta contra la API interna moderna de HowLongToBeat (`/api/search/site/init` y `/api/search/site`) sin requerir claves de API de terceros.
- **Gestión Automatizada de Tokens:** Manejo transparente de cabeceras de seguridad (`x-auth-token`, `x-hp-key`, `x-hp-val`) con reintentos automáticos ante expiración.
- **Extracción Exacta:** Obtención de la duración en horas de la **Historia Principal (Campaña)** y **100% Completista**.
- **Acciones Interactivas:**
  - Botón de búsqueda rápida con spinner reactivo en la ficha de detalle del juego (`GameDetailScreen`).
  - Acción masiva **"Buscar Metadatos HLTB en mi Biblioteca"** en Configuración para enriquecer y auto-culminar juegos en lote.

### 4. 🎮 Selector Visual Interactivo de Plataformas
- **Detección Automática desde RAWG:** Al registrar un juego nuevo, el sistema detecta y presenta únicamente las plataformas oficiales donde fue lanzado (ej. *Elden Ring* muestra directamente `PC`, `Playstation 5`, `Playstation 4` y `Xbox`).
- **Chips Táctiles con Logos de Fabricantes:** Selector basado en tarjetas visuales interactivas con los logotipos oficiales a color de PlayStation, Xbox, Steam/PC, Nintendo Switch, etc.
- **Modo Expandible ("+ Otras plataformas"):** Permite conmutar al catálogo completo de plataformas para juegos retro, emulados o tiendas alternativas (GOG, Epic Games).
- **Formulario Ergonómico:** Menús desplegables con altura máxima restringida (`menuMaxHeight: 220`) evitando cualquier desbordamiento de pantalla.

### 5. 🌐 Enriquecimiento Ilimitado de Géneros y Enlaces de Wikipedia
- **Captura Total de Géneros RAWG:** Eliminación de listas cerradas; todos los géneros devueltos por la API de RAWG se registran dinámicamente en SQLite y se integran en los filtros interactivos.
- **Motor Robusto de Wikipedia:** Búsqueda cruzada bilingüe (`es`/`en`) con sanitización de símbolos de marca (`™`, `®`, `©`), codificación limpia mediante `Uri.https` y cabeceras conforme a las políticas de Wikimedia (`User-Agent: GameTracker/3.0`).
- **Población Automática:** Asignación instantánea del enlace enciclopédico oficial al añadir juegos desde el buscador, sincronizar con Steam o pulsar el botón de brújula en la ficha de detalle.

### 6. 🛠️ CRUD Robusto con Patrón Sentinel (`copyWith`)
- **Soporte Completo de Borrado `NULL`:** Implementación del patrón canónico `_sentinel` en `Game.copyWith`, permitiendo vaciar y actualizar a `NULL` campos opcionales (`link`, `coverUrl`, `summary`, `rating`) de forma definitiva en SQLite sin restauraciones accidentales.
- **Botón de Borrado Rápido:** Botón de un toque (`Icons.clear_rounded`) en el campo de enlace de Wikipedia para vaciarlo instantáneamente antes de guardar.
- **Calificación Flexible:** Soporte para deseleccionar estrellas y regresar a estado 'Sin calificar' (`NULL`).

### 7. 🖼️ Gestión Híbrida de Carátulas (Web + Galería Local)
- **Renderizado Universal (`AppCoverImage`):** Soporte dual fluido de URLs remotas seguras (`https://`) e imágenes locales en disco.
- **Selector Nativo de Archivos (`file_picker`):** Permite subir portadas desde la galería en Android o el explorador de archivos en Windows, copiándolas de forma segura a `app_documents/covers/` para persistencia permanente.

### 8. 🎨 Sistema de Diseño Victor Engineer & Temas Dinámicos
- **Modo Oscuro (Obsidian Zinc):** Fondo ultra profundo `#09090B`, tarjetas `#121215`, bordes `#27272A` y acento rojo carmesí `#DC2626`.
- **Modo Claro (Crisp Zinc):** Fondo limpio `#FAFAFA`, tarjetas blancas `#FFFFFF`, bordes sutiles `#E4E4E7` y acento `#DC2626`.
- **Tipografías:** Google Fonts `Outfit` (títulos y marcas) + `Inter` (cuerpo de texto y analíticas).
- **Selector de Vista Dual:** Alternancia instantánea entre **Grid Cinematográfico** (con hover scale y barras HLTB) y **Lista Compacta de Alta Densidad** (con insignias de plataforma y botón rápido `+1h`).
- **Paginación Centrada:** Selectores de 10, 25, 50, 100 o Todos con margen de seguridad para evitar colisiones con el botón flotante.

### 9. 🎯 Gamificación, Metas Anuales y Tarjetas Sociales
- **Stepper Multi-Año:** Auditoría de balances anuales pasados y planificación de metas futuras.
- **Salón de la Fama:** Récords de *El Titán*, *Obra Maestra* y *Aventura Ágil*.
- **Generador de Tarjetas Exportables (PNG):** Captura a 2.5x pixel ratio con alternancia cromática dinámica para compartir reseñas en redes o Discord.

### 10. 💾 Portabilidad Total y Respaldo JSON Offline
- **Exportación en 1 Clic:** Respaldo completo de la biblioteca en la carpeta de Descargas del usuario.
- **Importador Híbrido Resiliente:** Capacidad de restaurar archivos JSON canónicos v3.0 y copias de seguridad legadas de versiones anteriores.
- **Dataset de Ejemplo:** Archivo `sample_games_library.json` incluido en el repositorio con 12 títulos de prueba listos para importar.

### 11. 🚀 CI/CD Automatizado & Seguridad de Releases
- **Compilación en Tags (`v*`):** Workflow `.github/workflows/release.yml` que genera automáticamente los binarios de Windows x64 (ZIP portable) y Android APK firmado.
- **Firma Permanente (`release.keystore`):** Certificado criptográfico RSA 2048 con validez hasta 2054, permitiendo actualizaciones continuas en Android sin conflictos de paquete.
- **Blindaje de Workflows:** Protección en `sync-docs.yml` para evitar ejecuciones no autorizadas en forks de terceros.

---

## 🗺️ Índice de Artefactos del Proyecto

- **Arquitectura del Sistema:** [[PRJ_App_Game_Tracker_architecture|Arquitectura del Sistema v3.0.5]]
- **Contrato de Datos y API:** [[PRJ_App_Game_Tracker_api_spec|Especificación de API y Contratos SQLite]]
- **Plan de Implementación:** [[PRJ_App_Game_Tracker_implementation_plan|Plan de Implementación v3.0.5]]
- **Lista de Tareas:** [[PRJ_App_Game_Tracker_task|Checklist de Tareas]]
- **Historial de Versiones:** [[PRJ_App_Game_Tracker_changelog_v1|Changelog v1]]
- **Reporte de Auditoría y Quality Gate:** [[PRJ_App_Game_Tracker_audit_report|Reporte de Auditoría]]
