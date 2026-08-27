---
tipo: api_spec
proyecto: App_Rastreador_de_Entretenimiento_Personal
version: v2.8.4
estado: activo
fecha: 2026-08-27
tags: [api_spec, backend-architect, notion-api, rawg-api, data-contracts, rate-limiting, serialization, smart-sync, backup-json, fix-400]
---

# 📡 Especificación de API y Contrato de Datos (v2.8.4)

Documento técnico elaborado por el rol **Backend-Architect** que formaliza los contratos de datos, modelos de entidad, esquemas de propiedades en Notion, endpoints REST consumidos y mecanismos de rate limiting, persistencia local y respaldos offline.

---

## 🗄️ Esquema de la Base de Datos (Notion Database Schema)

La base de datos principal reside en Notion. Cada registro (fila) es una `Page` cuyas propiedades (`properties`) siguen la siguiente estructura canónica:

| Propiedad Notion | Tipo Notion | Tipo Dart | Valores / Rango | Descripción |
| :--- | :--- | :--- | :--- | :--- |
| **`Título`** | `title` | `String` | Texto no vacío | Nombre oficial del videojuego |
| **`Estado`** | `status` / `select` | `String` | `'Por jugar'`, `'Jugando'`, `'Jugado'` | Estado actual de avance del jugador |
| **`Plataforma`** | `select` | `String?` | `'PC'`, `'Playstation 5'`, `'Nintendo Switch'`, etc. | Plataforma en la que se disfruta el juego |
| **`Horas Jugadas`** | `number` | `num` | $\ge 0$ | Horas acumuladas de partida registradas |
| **`Calificación`** | `select` | `String?` | `'★'` a `'★★★★★'` | Puntuación personal en estrellas (`\u2605` y `\u2730`) |
| **`Fecha de Inicio`** | `date` | `DateTime?` | Formato ISO 8601 (`YYYY-MM-DD`) | Fecha en que se inició la aventura |
| **`Fecha de Culminación (primera campaña)`** | `date` | `DateTime?` | Formato ISO 8601 (`YYYY-MM-DD`) | Fecha en que se finalizó el juego |
| **`HLTB Principal`** | `number` | `num?` | $\ge 0$ | Horas estimadas HowLongToBeat (Main Story) |
| **`HLTB Completista`** | `number` | `num?` | $\ge 0$ | Horas estimadas HLTB (Completionist) |
| **`Géneros`** | `multi_select` | `List<String>` | Lista de etiquetas | Géneros y temáticas del título |
| **`Portada`** | `files` | `String?` | URL externa válida | Enlace a la imagen de portada externa |
| **`Resumen`** | `rich_text` | `String?` | Texto plano / Markdown | Comentario personal, análisis y recuerdos |
| **`Link`** | `url` | `String?` | URL válida | Enlace de referencia (Wikipedia, Steam, etc.) |

---

## 🛡️ Contrato de Manejo de Portadas & Protección Error 400 (v2.8.4)

Notion impone una regla estricta de validación en su API (`validation_error`):
> *"A file with type `external` cannot contain a Notion hosted file url. Use type `file`."*

Cuando un usuario sube un archivo directamente a Notion, Notion genera una URL interna de AWS S3 (`prod-files-secure.s3...`). Si una aplicación cliente envía esa URL como `external`, Notion responde con **HTTP 400**.

### Reglas de Construcción en `toNotionProperties` y `NotionParser`:
1. **Omitir Portada Inalterada:** Al ejecutar `_saveChanges()`, si `currentCover.trim() == originalCover.trim()`, la propiedad `Portada` se excluye del payload PATCH. Esto asegura que la imagen original alojada en Notion permanezca intacta.
2. **Filtro de URLs S3 en `buildExternalFile`:** Si una URL contiene `amazonaws.com`, `prod-files-secure` o `notion-static.com`, se bloquea su emisión como archivo externo para evitar el rechazo de validación.
3. **Manejo de Nulos y Cadenas Vacías:**
   - `buildSelect(null)` $\rightarrow$ `{'select': null}` (unsets selection cleanly).
   - `buildUrl(null)` $\rightarrow$ `{'url': null}`.
   - `buildDate(null)` $\rightarrow$ `{'date': null}`.
   - `buildRichText(null)` $\rightarrow$ `{'rich_text': []}`.
   - `buildMultiSelect([])` $\rightarrow$ `{'multi_select': []}`.

---

## 🌐 Endpoints de la API de Notion (`v1`)

- **Base URL:** `https://api.notion.com/v1`
- **Headers Obligatorios:**
  - `Authorization: Bearer <notion_internal_token>`
  - `Notion-Version: 2022-06-28`
  - `Content-Type: application/json`

### 1. Consultar Base de Datos (`POST /databases/{database_id}/query`)
- **Propósito:** Recuperar todos los juegos registrados con ordenamiento cronológico.
- **Request Body:**
  ```json
  {
    "page_size": 100,
    "sorts": [
      {
        "timestamp": "last_edited_time",
        "direction": "descending"
      }
    ],
    "start_cursor": null
  }
  ```
- **Respuesta:** `200 OK` con `{ "results": [ ... ], "has_more": false, "next_cursor": null }`.

### 2. Crear Juego / Página (`POST /pages`)
- **Propósito:** Registrar un nuevo juego desde el buscador RAWG en la base de datos de Notion.
- **Request Body:**
  ```json
  {
    "parent": { "database_id": "DATABASE_UUID" },
    "properties": {
      "Título": { "title": [{ "text": { "content": "Elden Ring" } }] },
      "Estado": { "status": { "name": "Jugando" } },
      "Plataforma": { "select": { "name": "PC" } },
      "Horas Jugadas": { "number": 12.5 },
      "Fecha de Inicio": { "date": { "start": "2026-08-26" } },
      "Géneros": { "multi_select": [{ "name": "RPG" }, { "name": "Soulslike" }] },
      "Portada": { "files": [{ "name": "cover", "type": "external", "external": { "url": "https://..." } }] },
      "HLTB Principal": { "number": 58 }
    }
  }
  ```
- **Respuesta:** `200 OK` con el objeto `Page` recién creado y su `id`.

### 3. Actualizar Propiedades del Juego (`PATCH /pages/{page_id}`)
- **Propósito:** Incrementar horas (`+1h`), cambiar estado, editar calificación, fechas o notas.
- **Request Body:**
  ```json
  {
    "properties": {
      "Horas Jugadas": { "number": 13.5 },
      "Estado": { "status": { "name": "Jugado" } },
      "Fecha de Culminación (primera campaña)": { "date": { "start": "2026-08-26" } }
    }
  }
  ```
- **Respuesta:** `200 OK` con el objeto `Page` actualizado.

### 4. Deserialización de Excepciones (`NotionApiException`)
- Si Notion retorna un código distinto de 200, la respuesta cruda JSON se almacena en `responseBody`.
- El getter `detailedMessage` parsea `json.decode(responseBody)['message']`, entregando explicaciones legibles (e.g. *"Invalid status option"*, *"Contains invalid url"*) directamente al usuario.

---

## 💾 Especificación del Esquema de Respaldo JSON (`BackupService` v2.8.0)

El servicio `BackupService` exporta e importa la biblioteca completa bajo la siguiente estructura JSON canónica:

```json
{
  "app": "tracker_app",
  "version": "2.8.4",
  "exported_at": "2026-08-27T12:00:00.000Z",
  "total_games": 102,
  "games": [
    {
      "id": "2c294bde-8dc7-8037-aad0-edb9fd13108a",
      "title": "Overwatch 2",
      "status": "Jugado",
      "platform": "PC",
      "hours_played": 749.0,
      "rating": "★★★★✰",
      "genres": ["Shooter"],
      "hltb_main": 94.58,
      "hltb_completionist": 589.7,
      "cover_url": "https://media.rawg.io/media/games/4ea/4ea507ceebeabb43edbc09468f5aaac6.jpg",
      "summary": "Notas personales...",
      "link": "https://es.wikipedia.org/wiki/Overwatch_2",
      "start_date": "2025-12-07T00:00:00.000Z",
      "completed_date": "2025-12-10T00:00:00.000Z"
    }
  ]
}
```

---

## 🚦 Control de Concurrencia y Rate Limiting

Para cumplir estrictamente con los límites de Notion API (máximo 3 peticiones por segundo sin incurrir en errores `429 Too Many Requests`), el servicio `NotionService` implementa una cola FIFO de promesas con espaciado de 333 ms entre peticiones y reintentos con backoff exponencial.

---

## 🎮 API de Metadatos RAWG

- **Base URL:** `https://api.rawg.io/api/games`
- **Endpoint:** `GET https://api.rawg.io/api/games?key={rawg_api_key}&search={query}&page_size=15`
- **Campos Mapeados:**
  - `name`: Título del juego.
  - `background_image`: URL de carátula en alta definición.
  - `released`: Fecha de lanzamiento oficial.
  - `playtime`: Estimación de horas de duración promedio.
  - `genres`: Lista de géneros que se comparan y normalizan con la lista del catálogo interno.
