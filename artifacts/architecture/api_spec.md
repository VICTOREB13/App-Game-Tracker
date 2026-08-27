---
tipo: api_spec
proyecto: App_Game_Tracker
version: v3.0.5
estado: activo
fecha: 2026-08-27
tags: [api_spec, backend-architect, sqlite-schema, steam-api, howlongtobeat-api, rawg-api, wikipedia-api, rate-limiting, serialization, backup-json, victor-engineer, v3.0.5]
---

# 📡 Especificación de API y Contrato de Datos (v3.0.5 Local-First)

Documento técnico elaborado por el rol **Backend-Architect** que formaliza el esquema relacional de **SQLite local**, los contratos de comunicación con **Steam Web API**, **HowLongToBeat API**, **RAWG API**, **Wikipedia Wikimedia API** y los mecanismos de serialización y respaldos offline de acuerdo con la arquitectura v3.0.5.

---

## 🗄️ Esquema Relacional de la Base de Datos Local (SQLite DDL)

El archivo de base de datos reside en el almacenamiento seguro de la aplicación (`tracker.db` / `app_game_tracker.db`).

### 1. Tabla Principal: `games`
```sql
CREATE TABLE IF NOT EXISTS games (
    id TEXT PRIMARY KEY,                       -- UUIDv4 canónico
    title TEXT NOT NULL,                      -- Título oficial del juego (máx. 255 chars)
    cover_url TEXT,                           -- URL web remota o ruta absoluta local a archivo en covers/
    status TEXT NOT NULL DEFAULT 'Por jugar',  -- 'Por jugar', 'Jugando', 'Jugado'
    platform TEXT,                            -- 'PC', 'Playstation 5', 'Nintendo Switch', 'Xbox', etc.
    hours_played REAL DEFAULT 0.0,            -- Horas acumuladas (1 decimal, ej. 12.5)
    genres TEXT,                              -- Lista JSON serializada: '["Acción", "RPG", "Aventura"]'
    rating TEXT,                              -- '★' a '★★★★★' o NULL ('Sin calificar')
    hltb_main REAL,                           -- Horas estimadas historia principal HLTB
    hltb_completionist REAL,                  -- Horas estimadas completista HLTB
    summary TEXT,                             -- Reseña, reflexiones y notas personales (máx. 2000 chars)
    link TEXT,                                -- URL de referencia (Wikipedia o web oficial)
    start_date TEXT,                          -- Formato ISO 8601: 'YYYY-MM-DD'
    completed_date TEXT,                      -- Formato ISO 8601: 'YYYY-MM-DD'
    steam_id INTEGER,                         -- AppID oficial de Steam
    created_at TEXT NOT NULL,                 -- Fecha y hora de creación ISO 8601
    updated_at TEXT NOT NULL                  -- Fecha y hora de última modificación ISO 8601
);

-- Índices B-Tree de aceleración de consultas (< 2 ms)
CREATE INDEX IF NOT EXISTS idx_games_steam_id ON games(steam_id);
CREATE INDEX IF NOT EXISTS idx_games_status ON games(status);
CREATE INDEX IF NOT EXISTS idx_games_platform ON games(platform);
CREATE INDEX IF NOT EXISTS idx_games_title ON games(title);
```

---

## 🎮 Contrato de Endpoints: Steam Web API

### 1. Obtener Juegos Propios Comprados (`GetOwnedGames`)
- **Endpoint:** `GET https://api.steampowered.com/IPlayerService/GetOwnedGames/v0001/`
- **Parámetros:**
  - `key`: Steam Web API Key
  - `steamid`: SteamID64 (17 dígitos)
  - `include_appinfo`: `true`
  - `include_played_free_games`: `true`
  - `format`: `json`
- **Respuesta Canónica:**
  ```json
  {
    "response": {
      "game_count": 142,
      "games": [
        {
          "appid": 1086940,
          "name": "Baldur's Gate 3",
          "playtime_forever": 5340,
          "img_icon_url": "..."
        }
      ]
    }
  }
  ```

### 2. Obtener Juegos Recientes & Family Sharing (`GetRecentlyPlayedGames`)
- **Endpoint:** `GET https://api.steampowered.com/IPlayerService/GetRecentlyPlayedGames/v0001/`
- **Propósito:** Detectar títulos compartidos mediante **Family Sharing** y horas de juego actualizadas en las últimas dos semanas.
- **Parámetros:**
  - `key`: Steam Web API Key
  - `steamid`: SteamID64
  - `format`: `json`

### 3. Resolución de Vanity URL a SteamID64 (`ResolveVanityURL`)
- **Endpoint:** `GET https://api.steampowered.com/ISteamUser/ResolveVanityURL/v0001/`
- **Propósito:** Convierte el nombre de usuario de la URL personalizada del perfil (ej. `victorengineer`) en su SteamID64 numérico.
- **Respuesta:** `{ "response": { "steamid": "76561198000000000", "success": 1 } }`.

---

## ⏱️ Contrato de Endpoints: HowLongToBeat Native API (`HltbService`)

### 1. Inicialización de Sesión y Tokens de Seguridad
- **Endpoint:** `GET https://howlongtobeat.com/api/search/site/init`
- **Cabeceras:** `User-Agent: Mozilla/5.0 ...`, `Referer: https://howlongtobeat.com/`
- **Respuesta:**
  ```json
  {
    "token": "a1b2c3d4...",
    "hpKey": "x-hp-key-name",
    "hpVal": "x-hp-val-data"
  }
  ```

### 2. Búsqueda de Título y Extracción de Tiempos
- **Endpoint:** `POST https://howlongtobeat.com/api/search/site`
- **Cabeceras:**
  - `x-auth-token: {token}`
  - `{hpKey}: {hpVal}`
  - `Content-Type: application/json`
  - `Referer: https://howlongtobeat.com/`
- **Cuerpo de Petición (Payload):**
  ```json
  {
    "searchType": "games",
    "searchTerms": ["Elden", "Ring"],
    "searchPage": 1,
    "size": 5,
    "searchOptions": {
      "games": {
        "userId": 0,
        "platform": "",
        "sortCategory": "popular",
        "rangeCategory": "main",
        "rangeTime": { "min": null, "max": null },
        "gameplay": { "perspective": "", "flow": "", "genre": "", "difficulty": "" },
        "rangeYear": { "min": "", "max": "" },
        "modifier": ""
      }
    }
  }
  ```
- **Campos Mapeados:**
  - `comp_main`: Segundos de historia principal $\rightarrow$ Convertidos a horas (`seconds / 3600`).
  - `comp_100`: Segundos completista 100% $\rightarrow$ Convertidos a horas (`seconds / 3600`).

---

## 🌐 Contrato de Endpoints: RAWG API

- **Base URL:** `https://api.rawg.io/api/games`
- **Búsqueda en vivo:** `GET https://api.rawg.io/api/games?key={RAWG_KEY}&search={query}&page_size=15`
- **Enriquecimiento Automático:** `GET https://api.rawg.io/api/games?key={RAWG_KEY}&search={game_title}&page_size=1`
- **Extracción de Propiedades:**
  - `background_image`: URL HTTPS de portada en alta definición.
  - `genres`: Array completo de objetos `{ id, name, slug }` sin filtrado ni truncamiento.
  - `platforms`: Array de objetos `{ platform: { id, name, slug } }` para detección automática de plataformas de lanzamiento.

---

## 📚 Contrato de Endpoints: Wikimedia Wikipedia API

- **Búsqueda en Español:** `GET https://es.wikipedia.org/w/api.php`
- **Búsqueda en Inglés (Fallback):** `GET https://en.wikipedia.org/w/api.php`
- **Parámetros:**
  - `action`: `query`
  - `list`: `search`
  - `srsearch`: `{titulo_sanitizado} videojuego` (o `video game` en fallback inglés)
  - `format`: `json`
  - `srlimit`: `1`
- **Cabeceras Obligatorias:**
  - `User-Agent: GameTracker/3.0 (victorengineer.fyi; contact@victorengineer.fyi)`
- **Construcción de URL Canónica:**
  `https://{lang}.wikipedia.org/wiki/{title.replaceAll(' ', '_')}`

---

## 📦 Contrato de Respaldo y Restauración JSON (v3.0)

Estructura canónica generada y consumida por `BackupService`:
```json
{
  "version": "3.0.5",
  "exported_at": "2026-08-27T18:00:00.000Z",
  "app": "App Game Tracker",
  "total_games": 42,
  "games": [
    {
      "id": "550e8400-e29b-41d4-a716-446655440000",
      "title": "Elden Ring",
      "cover_url": "https://media.rawg.io/media/games/...",
      "status": "Jugado",
      "platform": "PC",
      "hours_played": 124.5,
      "genres": ["Action", "RPG", "Open World"],
      "rating": "★★★★★",
      "hltb_main": 58.5,
      "hltb_completionist": 133.0,
      "summary": "Una de las mejores experiencias de rol y acción de la historia.",
      "link": "https://es.wikipedia.org/wiki/Elden_Ring",
      "start_date": "2024-02-25",
      "completed_date": "2024-04-12",
      "steam_id": 1245620,
      "created_at": "2024-02-25T10:00:00.000Z",
      "updated_at": "2026-08-27T18:00:00.000Z"
    }
  ]
}
```
