---
tipo: api_spec
proyecto: App_Game_Tracker
version: v3.0.0-planning
estado: en_transicion
fecha: 2026-08-27
tags: [api_spec, backend-architect, sqlite-schema, steam-api, rawg-api, wikipedia-api, rate-limiting, serialization, backup-json, victor-engineer]
---

# 📡 Especificación de API y Contrato de Datos (v3.0.0 Local-First)

Documento técnico elaborado por el rol **Backend-Architect** que formaliza el esquema relacional de **SQLite local**, los contratos de comunicación con **Steam Web API**, **RAWG API**, **Wikipedia API** y los mecanismos de serialización y respaldos offline de acuerdo con la ingeniería inversa de [`games.py`](file:///c:/Users/vmesp/Documents/Cositas/App-Game-Tracker/games.py).

---

## 🗄️ Esquema Relacional de la Base de Datos Local (SQLite DDL)

El archivo de base de datos reside en el almacenamiento seguro de la aplicación (`app_game_tracker.db`).

### 1. Tabla Principal: `games`
```sql
CREATE TABLE IF NOT EXISTS games (
    id TEXT PRIMARY KEY,                       -- UUIDv4 canónico
    title TEXT NOT NULL,                      -- Título oficial del juego
    cover_url TEXT,                           -- URL directa de la carátula en alta definición
    status TEXT NOT NULL DEFAULT 'Por jugar',  -- 'Por jugar', 'Jugando', 'Jugado'
    platform TEXT,                            -- 'PC', 'Playstation 5', 'Nintendo Switch', etc.
    hours_played REAL DEFAULT 0.0,            -- Horas acumuladas (1 decimal, ej. 12.5)
    genres TEXT,                              -- Lista JSON serializada: '["Acción", "RPG"]'
    rating TEXT,                              -- '★' a '★★★★★'
    hltb_main REAL,                           -- Horas estimadas historia principal HLTB
    hltb_completionist REAL,                  -- Horas estimadas completista HLTB
    summary TEXT,                             -- Reseña, reflexiones y notas personales
    link TEXT,                                -- URL de referencia (Wikipedia, Steam, web oficial)
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
- **Propósito:** Permite al usuario ingresar su nombre personalizado de perfil de Steam (ej. `victorengineer`) y convertirlo automáticamente a su identificador numérico de 17 dígitos.
- **Respuesta:** `{ "response": { "steamid": "76561198000000000", "success": 1 } }`.

---

## 🌐 Contrato de Endpoints: RAWG API

- **Base URL:** `https://api.rawg.io/api/games`
- **Búsqueda en vivo:** `GET https://api.rawg.io/api/games?key={RAWG_KEY}&search={query}&page_size=15`
- **Enriquecimiento Automático:** `GET https://api.rawg.io/api/games?key={RAWG_KEY}&search={game_title}&page_size=1`
- **Extracción de Propiedades:**
  - `background_image`: URL HTTPS de portada en alta definición.
  - `genres`: Array de objetos `{ id, name, slug }`.
  - `playtime`: Horas estimadas empleadas como respaldo de HLTB.

---

## 📚 Contrato de Endpoints: Wikipedia API (Referencia Canónica)

- **Endpoint (Español):** `GET https://es.wikipedia.org/w/api.php?action=query&list=search&srsearch={juego} videojuego&format=json&srlimit=1`
- **Endpoint (Inglés):** `GET https://en.wikipedia.org/w/api.php?action=query&list=search&srsearch={juego} video game&format=json&srlimit=1`
- **Formato del Enlace Resultante:** `https://es.wikipedia.org/wiki/{title}`

---

## 💾 Contrato de Portabilidad & Formato de Respaldo JSON (v3.0)

```json
{
  "app": "Victor Engineer - Game Tracker",
  "schema_version": 3,
  "exported_at": "2026-08-27T17:30:00.000Z",
  "total_records": 1,
  "games": [
    {
      "id": "a1b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d",
      "title": "Elden Ring",
      "cover_url": "https://media.rawg.io/media/games/...",
      "status": "Jugado",
      "platform": "PC",
      "hours_played": 124.5,
      "genres": ["Acción", "RPG", "Soulslike"],
      "rating": "★★★★★",
      "hltb_main": 58.0,
      "hltb_completionist": 133.0,
      "summary": "Una de las mejores obras de FromSoftware.",
      "link": "https://es.wikipedia.org/wiki/Elden_Ring",
      "start_date": "2024-03-01",
      "completed_date": "2024-04-15",
      "steam_id": 1245620,
      "created_at": "2024-03-01T10:00:00.000Z",
      "updated_at": "2026-08-27T17:00:00.000Z"
    }
  ]
}
```
*Compatibilidad garantizada con archivos generados en versiones v2.x (esquema Notion con propiedad `records`).*
