# 🎮 App Game Tracker (v3.1.3)

> **Rastreador de Videojuegos y Entretenimiento Personal Local-First para Windows y Android.**  
> Desarrollado con ❤️ por **[Victor Engineer](https://victorengineer.fyi)**.

[![Licencia MIT](https://img.shields.io/badge/Licencia-MIT-red.svg)](LICENSE)
[![Flutter](https://img.shields.io/badge/Flutter-3.22+-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Motor](https://img.shields.io/badge/Almacenamiento-SQLite%20FFI-003B57?logo=sqlite&logoColor=white)](https://www.sqlite.org)
[![Steam](https://img.shields.io/badge/Steam%20Web-API%20Sync-171a21?logo=steam&logoColor=white)](https://steamcommunity.com/dev)
[![Sitio Oficial](https://img.shields.io/badge/Autor-victorengineer.fyi-DC2626)](https://victorengineer.fyi)

---

## 🌟 Descripción General

**App Game Tracker** es una aplicación multiplataforma moderna, elegante y de latencia cero diseñada para llevar el registro definitivo de tu biblioteca de videojuegos. 

A diferencia de soluciones dependientes de la nube lenta o bases de datos de terceros, la versión **v3.1.3** adopta una arquitectura **100% Local-First** impulsada por **SQLite** con límites defensivos de optimización de memoria, servicio nativo de HowLongToBeat, selector visual de plataformas, CRUD integral con borrado de campos opcionales, privacidad total y funcionamiento offline continuo en **Windows (PC)** y **Android**.

---

## ✨ Características Principales

- ⚡ **Arquitectura Local-First (SQLite):**
  - Almacenamiento local ultrarrápido con consultas indexadas por B-Tree (`status`, `platform`, `steam_id`, `title`).
  - Totalmente funcional sin conexión a internet ni dependencias externas.
  - Optimización en caliente mediante comando `VACUUM`.

- 🔄 **Sincronización Inteligente con Steam Web API:**
  - Importación y actualización automática de horas jugadas mediante llamada dual (`GetOwnedGames` + `GetRecentlyPlayedGames`).
  - **Soporte de Family Sharing:** detecta y cataloga títulos jugados mediante préstamo familiar.
  - **Filtro de Ruido (30 Minutos):** descarta automáticamente juegos con menos de 0.5 horas registradas.
  - **Matching Tri-Fase Resiliente:** coincidencia por `AppID` $\rightarrow$ Nombre normalizado $\rightarrow$ Similitud difusa Sørensen-Dice / Levenshtein (> 0.90).
  - **Auto-Culminación por HowLongToBeat:** si tus horas registradas superan la historia principal (`hltb_main`), el juego se marca automáticamente como *Jugado* con fecha de finalización.

- 🖼️ **Gestión Híbrida de Carátulas (Web + Galería Local):**
  - Renderizado universal de imágenes remotas (`https://`) y archivos locales en disco.
  - Selector nativo de archivos y galería (`file_picker`) que copia de forma segura la portada a la carpeta persistente del sistema (`app_documents/covers/`).

- 🌐 **Enriquecimiento de Metadatos (RAWG, HowLongToBeat & Wikipedia):**
  - Autocompletado de portadas de alta definición, plataformas de lanzamiento y todos los géneros de RAWG sin restricciones.
  - Búsqueda integrada de resúmenes y enlaces oficiales en Wikipedia con cabeceras Wikimedia conformes.
  - Selector visual interactivo de plataformas con chips táctiles, logos oficiales y detección inteligente.

- 📦 **Portabilidad y Respaldo Total (JSON):**
  - Exportación con un solo clic de tu biblioteca completa a tu carpeta de *Descargas*.
  - Restauración instantánea desde respaldos locales, texto JSON o datasets externos.
  - Compatible con formatos heredados y estructura canónica v3.0.

- 🎨 **Diseño Visual de Grado Premium:**
  - Paleta refinada Zinc & Crimson Red (`#DC2626`).
  - Tipografías modernas Google Fonts (*Outfit* e *Inter*).
  - Modos Oscuro, Claro y Automático del Sistema.
  - Hero Spotlight cinemático, filtros interactivos y analíticas de horas y metas anuales.

---

## 🚀 Instalación y Descarga

Puedes descargar los instaladores precompilados de la última versión estable directamente desde la sección de **[Releases](https://github.com/VICTOREB13/App-Game-Tracker/releases)**:

- **Windows x64 (PC):** Descarga `App-Game-Tracker-Windows-x64.zip`, descomprímelo y ejecuta `tracker_app.exe`.
- **Android:** Descarga `App-Game-Tracker-Android.apk` e instálalo en tu dispositivo móvil.

---

## 🛠️ Configuración Inicial

### 1. Obtener Steam Web API Key y SteamID
1. Ingresa a [Steam Community Dev](https://steamcommunity.com/dev/apikey) e inicia sesión para generar tu **Steam Web API Key**.
2. En la aplicación, ve a **Configuración** $\rightarrow$ **Sincronización con Steam**.
3. Ingresa tu API Key y tu **SteamID64** (o tu apodo / vanity URL de perfil y presiona el botón de búsqueda para resolverlo automáticamente).
4. Pulsa **Probar Conexión** y luego **Sincronizar Ahora**.

### 2. Obtener RAWG API Key (Opcional)
1. Regístrate gratuitamente en [rawg.io/apidocs](https://rawg.io/apidocs) para obtener tu clave personal.
2. Pégala en **Configuración** $\rightarrow$ **Búsqueda & Metadatos (RAWG)** para disfrutar de autocompletado en el buscador.

### 3. Probar con Datos Ficticios de Ejemplo
El repositorio incluye el archivo [`sample_games_library.json`](sample_games_library.json) con 12 títulos realistas (Elden Ring, Cyberpunk 2077, Zelda TotK, Hollow Knight, etc.). Puedes cargarlo directamente desde el diálogo de **Importar JSON** en la pantalla de Configuración.

---

## 💻 Compilación desde el Código Fuente

### Prerrequisitos
- [Flutter SDK](https://docs.flutter.dev/get-started/install) 3.22.0 o superior.
- Para Windows: Visual Studio 2022 con la carga de trabajo *"Desarrollo para el escritorio con C++"*.
- Para Android: Android SDK y Java 17.

```bash
# 1. Clonar el repositorio
git clone https://github.com/VICTOREB13/App-Game-Tracker.git
cd App-Game-Tracker/frontend

# 2. Restaurar dependencias
flutter pub get

# 3. Ejecutar en modo desarrollo
flutter run -d windows
# O para Android:
flutter run -d android

# 4. Compilar binarios de producción
flutter build windows --release
flutter build apk --release
```

---

## 🏗️ Arquitectura de Software

```
frontend/lib/
├── models/
│   └── game.dart               # Modelo canónico de Videojuego (SQLite & JSON)
├── services/
│   ├── database_service.dart   # Persistencia SQLite FFI / Android
│   ├── steam_service.dart      # Sincronización Steam, Family Sharing y HLTB
│   ├── metadata_service.dart   # Enriquecimiento con RAWG y Wikipedia
│   ├── string_normalizer.dart  # Limpieza de títulos y similitud difusa (> 0.90)
│   ├── backup_service.dart     # Motor de exportación/importación JSON
│   └── theme_manager.dart      # Gestor reactivo de temas (Oscuro/Claro/Sistema)
├── screens/
│   ├── dashboard.dart          # Panel principal, Spotlight y catálogo interactivo
│   ├── game_detail_screen.dart # Ficha del juego, contador de horas y selector de carátula
│   ├── search_screen.dart      # Explorador de títulos y adición manual
│   ├── analytics_screen.dart   # Estadísticas, gráficos y metas anuales
│   └── settings_screen.dart    # Configuración de SQLite, Steam, RAWG y respaldos
└── widgets/
    ├── app_cover_image.dart    # Renderizado híbrido unificado (Web / Galería Local)
    └── platform_helper.dart    # Normalización de badges de plataformas
```

---

## 📄 Licencia

Este proyecto se distribuye bajo la licencia **MIT**. Para más detalles, consulta el archivo [LICENSE](LICENSE).

---

## 👨‍💻 Autor y Enlaces

- **Autor:** Victor Engineer
- **Sitio Web Oficial:** [https://victorengineer.fyi](https://victorengineer.fyi)
- **Repositorio:** [VICTOREB13/App-Game-Tracker](https://github.com/VICTOREB13/App-Game-Tracker)
