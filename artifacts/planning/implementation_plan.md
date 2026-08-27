---
tipo: plan
proyecto: App_Game_Tracker
version: v3.0.5
estado: culminado
fecha: 2026-08-27
agent: Project-Planner
tags: [plan, v3.0.5, sqlite-local, offline-first, steam-api, howlongtobeat, platform-selector, cover-picker, rawg-api, wikipedia-api, sentinel-pattern, open-source, github-releases, backup-json, victor-engineer]
---

# 📋 Plan de Implementación Maestro v3.0.5: Arquitectura Local-First SQLite, HowLongToBeat, Selector Visual de Plataformas, Enriquecimiento Total & Open Source

Documento maestro orquestado por el rol **Project-Planner** que establece el ciclo completo de evolución arquitectónica del proyecto bajo la metodología **Evolutionary Prototyping**, transformando la aplicación en una solución **100% Local-First** con **SQLite**, servicio nativo de **HowLongToBeat**, selector visual de plataformas, gestión híbrida de portadas, enriquecimiento irrestricto de metadatos y distribución pública Open Source bajo la marca personal **Victor Engineer** ([victorengineer.fyi](https://victorengineer.fyi)).

---

## 🎯 Directrices Clave de la Versión v3.0.5

1. **Preservación Visual Total:** Cero regresiones estéticas. Se conservan intactos el Grid cinematográfico, Lista compacta, filtros adaptativos, paleta Zinc & Crimson Red (`#DC2626`) y temas duales Obsidian Zinc / Crisp Zinc.
2. **Dominio Oficial:** Enlace canónico a **`https://victorengineer.fyi`**.
3. **Gestión Dual de Portadas (URL Web + Galería Local):** Selector nativo `file_picker` con copia persistente segura en `app_documents/covers/` y renderizado universal con `AppCoverImage`.
4. **Sincronización Dual de Steam:** Detección de juegos propios y de Family Sharing (`GetOwnedGames` + `GetRecentlyPlayedGames`), filtro de 30 minutos, normalización de títulos, matching tri-fase y auto-culminación por HLTB.
5. **Servicio Nativo HowLongToBeat:** Cliente HTTP interno con gestión de tokens y consulta interactiva/masiva.
6. **Selector Visual de Plataformas:** Chips interactivos con logotipos de fabricantes y detección automática de plataformas de lanzamiento desde RAWG.
7. **Captura Ilimitada de Géneros y Enlaces de Wikipedia:** Asignación de todos los géneros devueltos por RAWG y búsqueda cruzada en Wikipedia con cabeceras Wikimedia conformes.
8. **Patrón Sentinel en `copyWith`:** Soporte completo para vaciar y guardar campos en `NULL` (enlace, portada, resumen, calificación).
9. **CI/CD de Releases Automatizados:** Despliegue condicionado exclusivamente a tags (`v*`) para compilar Windows x64 ZIP y Android APK firmado con validez hasta 2054.

---

## 🔄 Cronología de Iteraciones Evolutivas (v3.0.0 $\rightarrow$ v3.0.5)

### 🔹 Iteración v3.0.0: Núcleo Local-First & Desacople de Notion
- Reemplazo del backend de Notion por SQLite 3 local con índices B-Tree (`DatabaseService`).
- Creación de `SteamService` replicando al 100% la lógica de `games.py`.
- Creación de `AppCoverImage` para soporte híbrido de imágenes web y archivos locales.
- Creación del pipeline de releases `.github/workflows/release.yml`.

### 🔹 Iteración v3.0.1: Purga de `notionPageId` & Límites Defensivos de Memoria
- Eliminación definitiva del getter heredado `notionPageId` en `Game`.
- Reemplazo de referencias en animaciones Stagger (`ValueKey`), listas y Hero tags por `game.id`.
- Implementación de límites defensivos de variables: títulos (255), resúmenes (2000), URLs (2048), géneros (20x50), horas (0 a 99,999).

### 🔹 Iteración v3.0.2: Servicio Nativo HowLongToBeat (`HltbService`)
- Implementación del cliente HTTP directo contra `/api/search/site/init` y `/api/search/site`.
- Extracción de horas de Campaña y 100% Completista.
- Botón de búsqueda instantánea en `GameDetailScreen`.
- Acción masiva de sincronización HLTB en `SettingsScreen`.

### 🔹 Iteración v3.0.3: Géneros RAWG Ilimitados & Enlaces Oficiales de Wikipedia
- Eliminación del filtro restrictivo que descartaba géneros en inglés de RAWG.
- Reingeniería de `MetadataService.searchWikipedia` con `Uri.https`, sanitización de símbolos y cabecera de contacto Wikimedia.
- Auto-población de enlaces enciclopédicos al guardar juegos o sincronizar con Steam.
- Botón de acción rápida de Wikipedia en la ficha del juego.

### 🔹 Iteración v3.0.4: Selector Visual de Plataformas & Detección Inteligente
- Eliminación del menú desplegable vertical de plataformas que desbordaba la pantalla.
- Introducción de selector visual de chips con logotipos oficiales de fabricantes (`PlatformHelper`).
- Detección automática de las plataformas nativas del juego desde `rawgGame['platforms']`.
- Conmutador para expandir a "+ Otras plataformas".

### 🔹 Iteración v3.0.5: CRUD Integral con Patrón Sentinel & Borrado de Enlaces
- Implementación de `_sentinel` en `Game.copyWith` para distinguir entre argumento omitido y `null` explícito.
- Botón de borrado rápido (`Icons.clear_rounded`) en el campo de enlace de Wikipedia.
- Persistencia exacta de valores `NULL` en SQLite al vaciar enlaces, portadas, resúmenes o restablecer calificaciones.

---

## 🏗️ Desglose de Responsabilidades por Rol

- **`Project-Planner`**: Orquestación de requerimientos, gobernanza de artefactos Obsidian, versionado y changelogs.
- **`Backend-Architect`**: Arquitectura SQLite, modelos relacionales, servicios de red (Steam, HLTB, RAWG, Wikipedia), patrón Sentinel y respaldos JSON.
- **`Frontend-UI`**: Preservación de diseño visual, selector visual de plataformas, integración de acciones rápidas, animaciones y temas Obsidian/Crisp Zinc.
- **`Systems-Auditor`**: Pruebas unitarias, análisis de latencias (< 3 ms), verificación de seguridad y emisión del Quality Gate Report.
- **`DevOps-Engineer`**: Automatización de CI/CD en GitHub Actions, protección de workflows en forks, firma persistente de Android y documentación de lanzamiento.
