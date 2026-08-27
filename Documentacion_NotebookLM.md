# 🎮 Rastreador de Entretenimiento Personal (App Game Tracker v3.0.5) - Documentación Técnica y Deep Research para NotebookLM

Este documento contiene la investigación profunda (Deep Research) y la especificación técnica completa del proyecto **Rastreador de Entretenimiento Personal (App Game Tracker)** en su versión **v3.0.5 Local-First**. Está estructurado y optimizado específicamente para ser procesado, indexado y analizado por **Google NotebookLM**.

---

## 1. Visión General y Ecosistema Arquitectónico

El proyecto **App Game Tracker** es una solución multiplataforma de grado profesional desarrollada en **Flutter** para **Windows Desktop (x64 nativo)** y **Android**. Su objetivo primordial es brindar al usuario soberanía total y privacidad absoluta sobre la gestión, auditoría y analítica de su biblioteca de videojuegos.

A diferencia de soluciones tradicionales dependientes de servidores en la nube lentos, autenticaciones externas o bases de datos como servicio (BaaS) con cuotas y latencias variables, la versión **v3.0.5** adopta una arquitectura **100% Local-First** impulsada por **SQLite 3**:
- **Cold Start de 0 ms:** La aplicación no realiza ninguna petición de red para inicializarse ni para renderizar el panel principal.
- **Operación Offline Continua:** Todas las funciones de biblioteca, filtrado, analíticas, edición de fichas y cálculo de metas anuales operan sin conexión a internet.
- **Consultas Indexadas en < 2 ms:** Aceleración por índices B-Tree en la base de datos local.
- **Soberanía y Privacidad:** La colección de juegos y horas no se envía a servidores de terceros; reside exclusivamente en el dispositivo del usuario (`%APPDATA%` en Windows o almacenamiento interno protegido en Android).

---

## 2. Capa de Frontend y Sistema de Diseño (Flutter & Victor Engineer)

El Frontend está desarrollado con **Flutter 3.22+** sobre el lenguaje **Dart**. Implementa un sistema de diseño propio y estilizado conforme a la identidad de marca personal **Victor Engineer** ([victorengineer.fyi](https://victorengineer.fyi)).

### Componentes y Vistas Clave
- `lib/main.dart`: Inicializa el motor de base de datos local `DatabaseService` y el gestor de temas `ThemeManager`, arrancando inmediatamente en el dashboard principal con cero retraso.
- `lib/models/game.dart`: Modelo de dominio canónico.
  - **Patrón Sentinel (`_sentinel`):** Implementado en `copyWith` para distinguir de manera rigurosa entre un parámetro omitido (conserva el valor actual) y un valor `null` explícito (permite vaciar enlaces, portadas, resúmenes y calificaciones en SQLite).
  - **Límites Defensivos de Memoria:** Clamping transparente de recursos (títulos a 255 caracteres, resúmenes a 2000, URLs a 2048, géneros a 20 elementos de 50 caracteres y horas entre 0 y 99,999) para evitar saturación de memoria.
- `lib/screens/dashboard.dart`: Panel maestro con selector de vista dual:
  - **Grid Cinematográfico:** Tarjetas con elevación, micro-barra de progreso HLTB, indicador de estado y animación en hover.
  - **Lista Compacta (`_GameListRow`):** Fila de alta densidad (54px) con miniatura, logotipos oficiales de plataforma, pill de estado, estrellas y botón rápido `+1h`.
  - **Paginación Inteligente:** Opciones de 10, 25, 50, 100 o Todos con controles centrados y margen de seguridad para evitar colisiones con el botón flotante.
- `lib/screens/game_detail_screen.dart`: Ficha cinemática del juego. Incluye selector dual de carátulas (URL web o archivo local de galería), botón de búsqueda rápida en HowLongToBeat con auto-completado de horas, campo de enlace enciclopédico de Wikipedia con botón de borrado de un toque y selector de calificación.
- `lib/screens/search_screen.dart`: Buscador en vivo contra RAWG API.
  - **Selector Visual de Plataformas:** Sustituye los menús desplegables tradicionales por chips interactivos con logotipos vectoriales de fabricantes.
  - **Detección Automática:** Lee las plataformas oficiales del juego devueltas por RAWG y las muestra filtradas con opción de expandir a "+ Otras plataformas".
  - **Captura Ilimitada de Géneros:** Extrae todos los géneros provistos por RAWG sin restricciones de lista cerrada.
  - **Auto-Enlace Wikipedia:** Asigna automáticamente el enlace oficial enciclopédico antes de guardar en SQLite.
- `lib/screens/analytics_screen.dart`: Hub de estadísticas, salud del backlog, distribución porcentual por estado y plataforma, metas anuales dinámicas multi-año y Salón de la Fama (*El Titán*, *Obra Maestra*, *Aventura Ágil*).
- `lib/screens/settings_screen.dart`: Centro de configuración y mantenimiento:
  - Optimización en caliente de SQLite (`VACUUM`).
  - Sincronización manual de Steam con resolución de Vanity URL.
  - Acción masiva **"Buscar Metadatos HLTB en mi Biblioteca"**.
  - Acción masiva **"Sincronizar Géneros, Portadas y Wikipedia"**.
  - Exportación e importación de copias de seguridad JSON.
- `lib/widgets/app_cover_image.dart`: Widget de renderizado híbrido inteligente que discrimina automáticamente entre URLs remotas (`CachedNetworkImage`) y archivos locales en disco (`Image.file`).
- `lib/widgets/platform_helper.dart`: Motor gráfico de marcas con logotipos vectoriales oficiales (PlayStation, Xbox, Steam, Nintendo Switch, GOG, Epic) y paletas semánticas asociadas.

---

## 3. Capa de Datos Local-First (SQLite 3)

El almacenamiento principal está orquestado por `DatabaseService` (`lib/services/database_service.dart`), utilizando `sqflite_common_ffi` en Windows Desktop y `sqflite` nativo en Android.

### Esquema DDL y Aceleración B-Tree
```sql
CREATE TABLE IF NOT EXISTS games (
    id TEXT PRIMARY KEY,                       -- UUIDv4 canónico
    title TEXT NOT NULL,                      -- Título oficial (máx 255)
    cover_url TEXT,                           -- URL remota o ruta local
    status TEXT NOT NULL DEFAULT 'Por jugar',  -- 'Por jugar', 'Jugando', 'Jugado'
    platform TEXT,                            -- 'PC', 'Playstation 5', etc.
    hours_played REAL DEFAULT 0.0,            -- Horas jugadas
    genres TEXT,                              -- JSON array serializado
    rating TEXT,                              -- '★' a '★★★★★' o NULL
    hltb_main REAL,                           -- Horas Campaña HLTB
    hltb_completionist REAL,                  -- Horas 100% HLTB
    summary TEXT,                             -- Notas y reflexiones personales
    link TEXT,                                -- URL oficial (Wikipedia)
    start_date TEXT,                          -- YYYY-MM-DD
    completed_date TEXT,                      -- YYYY-MM-DD
    steam_id INTEGER,                         -- AppID de Steam
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_games_steam_id ON games(steam_id);
CREATE INDEX IF NOT EXISTS idx_games_status ON games(status);
CREATE INDEX IF NOT EXISTS idx_games_platform ON games(platform);
CREATE INDEX IF NOT EXISTS idx_games_title ON games(title);
```

---

## 4. Integraciones y Servicios de Red On-Demand

Aunque el almacenamiento es local-first, la aplicación consume APIs públicas y servicios especializados para enriquecer la biblioteca a demanda del usuario:

### 1. Steam Web API (`SteamService`)
- **Consulta Dual:** `GetOwnedGames` (biblioteca propia comprada) + `GetRecentlyPlayedGames` (juegos jugados mediante **Family Sharing**).
- **Filtro de Ruido (30 Minutos):** Ignora automáticamente juegos con menos de 0.5 horas registradas.
- **Emparejamiento Tri-Fase (`StringNormalizer`):**
  1. Coincidencia por `steam_id`.
  2. Coincidencia exacta por nombre limpio (remueve `™`, `®`, signos de puntuación).
  3. Coincidencia por similitud difusa (algoritmo Sørensen-Dice / Levenshtein con ratio $> 0.90$).
- **Auto-Culminación por HLTB:** Si las horas jugadas acumuladas alcanzan o superan la duración de la historia principal (`hltb_main`), el juego se marca de inmediato como *Jugado* con fecha de finalización automática.

### 2. Servicio Nativo HowLongToBeat (`HltbService`)
- Cliente HTTP directo contra la API interna moderna de HowLongToBeat (`/api/search/site/init` y `/api/search/site`).
- Gestión automática de tokens de seguridad (`x-auth-token`, `x-hp-key`, `x-hp-val`) y reintentos transparentes.
- Extrae la duración en horas de la **Historia Principal** y **Completista 100%**.

### 3. RAWG Video Games Database API (`MetadataService`)
- Catálogo de más de 500,000 videojuegos para autocompletado de portadas de alta resolución, fechas de lanzamiento y plataformas de lanzamiento.
- Captura de todos los géneros sin truncamiento ni listas cerradas.

### 4. Wikimedia Wikipedia API (`MetadataService`)
- Motor de búsqueda enciclopédico con sanitización de títulos, consulta cruzada bilingüe (`es`/`en`) y cabecera de contacto oficial `User-Agent: GameTracker/3.0 (victorengineer.fyi; contact@victorengineer.fyi)`.

---

## 5. Portabilidad, Seguridad y Ciclo de Vida CI/CD

- **Portabilidad JSON (`BackupService`):** Exportación completa de la biblioteca a la carpeta de Descargas en formato JSON canónico v3.0 e importación retrocompatible con esquemas antiguos.
- **Dataset de Prueba (`sample_games_library.json`):** Colección de 12 títulos de prueba incluida en la raíz para pruebas inmediatas tras la instalación.
- **Firma Persistente de Android (`release.keystore`):** Keystore dedicado con validez de 27 años (hasta 2054) que erradica conflictos de actualización en Android.
- **GitHub Actions CI/CD (`release.yml`):** Compilación y publicación automática en tags (`v*`) generando artefactos portables para Windows x64 (ZIP) y Android (APK).
- **Protección de Workflows:** Blindaje en `.github/workflows/sync-docs.yml` para aislar secretos y bóvedas en forks externos.
