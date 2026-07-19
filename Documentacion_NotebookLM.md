# Rastreador de Entretenimiento Next Level - Documentación de Deep Research (NotebookLM)

Este documento contiene la investigación profunda (Deep Research) y la documentación técnica completa del proyecto **Rastreador de Entretenimiento Next Level**. Está optimizado para ser procesado por Google NotebookLM, estructurando la información en las áreas clave de Aplicaciones Web, Frontend, Backend y la integración con Notion API.

---

## 1. Aplicaciones Web y Ecosistema Global
El proyecto se concibe como una solución moderna para el seguimiento y gestión de videojuegos ("Game Tracker"). La arquitectura está diseñada de forma multiplataforma. Aunque la base principal actual es una aplicación construida con Flutter, el framework permite exportar fácilmente el proyecto como una **Aplicación Web** (PWA o Single Page Application). 

- **Arquitectura de Software**: Cliente-Servidor (Serverless Backend).
- **Flujo de Trabajo**: El usuario puede ver su biblioteca de juegos, filtrarlos por estados (Jugando, Completado, Por Jugar, etc.) y visualizar analíticas avanzadas.
- **Escalabilidad Web**: Al estar basado en Flutter para el cliente y Supabase para el backend, su despliegue web requiere mínima refactorización, lo que permite unificar la experiencia en web y móvil bajo una misma base de código.

---

## 2. Frontend (Flutter)
El Frontend está desarrollado con **Flutter** utilizando el lenguaje **Dart**. Es responsable de la interfaz de usuario (UI), la gestión del estado y la interacción directa con el backend (Supabase).

### Estructura de Directorios y Archivos Clave
- `lib/main.dart`: Punto de entrada de la aplicación. Configura la inicialización de Supabase usando variables de entorno (`.env`) y maneja la redirección según el estado de autenticación (Login vs Dashboard). Cuenta con un tema oscuro y moderno implementado con `Google Fonts` (Outfit).
- `lib/models/`:
  - `game.dart`: Define el modelo de datos de un Videojuego, con propiedades como título, URL de portada, estado, horas jugadas, plataforma, tags, género y proveedor (ej. Steam, Xbox).
  - `profile.dart`: Maneja la información del perfil del usuario.
- `lib/screens/`:
  - `login_screen.dart`: Pantalla de inicio de sesión gestionada a través de Supabase Auth.
  - `dashboard.dart`: Pantalla principal de "Mi Biblioteca". Permite listar, filtrar (por estado y A-Z/Recientes) y visualizar la colección en un Grid adaptativo.
  - `analytics_screen.dart`: Visualización de datos usando la librería `fl_chart`. Incluye gráficos de torta (distribución de estados) y gráficos de barras apiladas (dominancia de plataformas).
  - `game_detail_screen.dart`: Interfaz para la visualización detallada y edición manual de un juego.
  - `search_screen.dart` y `settings_screen.dart`: Pantallas para búsqueda y configuración del perfil.
- `lib/services/`:
  - `sync_service.dart`: Servicio que orquesta la comunicación con las *Edge Functions* de Supabase para disparar la sincronización de juegos desde plataformas externas como Steam, PSN o Xbox.

### Tecnologías Frontend
- **Framework**: Flutter (SDK >= 3.2.0)
- **Librerías Críticas**: `supabase_flutter`, `flutter_dotenv`, `google_fonts`, `fl_chart` (analíticas interactivas), `cached_network_image`.

---

## 3. Backend (Supabase & Edge Functions)
El proyecto utiliza **Supabase** como backend como servicio (BaaS), aprovechando su base de datos PostgreSQL, el servicio de autenticación y su motor de Edge Functions.

### Edge Functions: `sync-games`
Ubicado en `supabase/functions/sync-games/index.ts`, este componente serverless (escrito en TypeScript y ejecutado sobre Deno) es el motor de sincronización automática.

- **Flujo de Sincronización**:
  1. Recibe un POST con la acción (ej. `sync-steam`), `userId` y `providerId`.
  2. Consulta la API externa (ej. API oficial de Steam usando `STEAM_KEY` y `steamid`).
  3. Procesa y mapea la respuesta (juegos, horas de juego, última vez jugado) y hace un "upsert" en la tabla `games` de Supabase.
- **Enriquecimiento de Metadatos (RAWG)**: 
  Si el juego es nuevo y no existe previamente, el backend llama a la API de **RAWG** (`RAWG_KEY`) para obtener metadatos enriquecidos de forma automática, tales como la URL de la portada (`background_image`), géneros y etiquetas.
- **Auditoría**: Registra cada intento de sincronización en la tabla `sync_logs` para control de errores y monitoreo.

---

## 4. Notion y su API: Análisis e Integración
El código fuente revela que el ecosistema asume a Notion como un posible `provider` (proveedor) de información, evidenciado en el fallback predeterminado de los análisis: `provider ?? 'Notion'`. Aunque la fuente de verdad primaria es Supabase, la integración con la API de Notion abre vectores funcionales muy potentes que se recomiendan explorar.

### Arquitectura de Integración Recomendada con Notion API:
1. **Sincronización Bidireccional (Backup y Productividad)**:
   - Se puede utilizar la **Notion API** para volcar y mantener sincronizada la biblioteca de juegos desde Supabase hacia una base de datos (Database) en el entorno de Notion del usuario.
   - **Endpoints clave**: `POST https://api.notion.com/v1/pages` para crear un registro en la base de datos de Notion, configurando propiedades (`properties`) como `Status` (tipo Select), `Hours` (tipo Number), y `Platform` (tipo Select).
2. **Dashboard de Segunda Pantalla**:
   - Los usuarios enfocados en la productividad suelen rastrear su vida en Notion. Al integrar la API, la app puede enviar hooks cuando el estado de un juego cambia a "Completado", actualizando instantáneamente la base de datos de Notion correspondiente mediante el endpoint `PATCH https://api.notion.com/v1/pages/{page_id}`.
3. **Flujo de Implementación**:
   - Crear una nueva *Edge Function* en Supabase (ej. `sync-notion`).
   - Requerir OAuth 2.0 o que el usuario ingrese un `NOTION_API_KEY` (Integration Token) y el `Database ID` directamente en el `settings_screen.dart` del frontend.
   - Utilizar un cron job en Supabase (o webhooks locales de Flutter) para ejecutar la sincronización periódicamente y evitar saturar la API (Rate Limits).

---
*Fin del Documento. Documentación generada específicamente para ingesta y análisis en NotebookLM.*
