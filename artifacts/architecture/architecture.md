---
tipo: architecture
proyecto: App-Rastreador-de-Entretenimiento
estado: activo
fecha: 2026-08-25
tags: [arquitectura, flutter, notion-api, rawg-api, desktop-responsive]
---

# 🏛️ Arquitectura del Sistema: Rastreador de Entretenimiento

## 🛠️ Stack Tecnológico

- **Frontend / Core:** Flutter 3.22+ (Dart >= 3.2.0 < 4.0.0)
- **Plataformas Soportadas:** Android (APK Fat) & Windows Desktop (PC x64)
- **Base de Datos / Backend Principal:** Notion API v1 (`2022-06-28`) con Internal Integration Token
- **Capa de Red:** `http` / `dio` con Rate Limiter encolado (3 req/s máx) y caché en memoria (TTL 60s)
- **Proveedor de Metadatos de Juegos:** RAWG Video Games Database API
- **Almacenamiento Local de Preferencias:** `shared_preferences` (Token de Notion, Database ID, RAWG Key)
- **Diseño & UI:** Sistema de diseño personalizado "Arcade Noir" (Google Fonts: *Space Grotesk* + *Inter*), componentes responsivos con soporte móvil y desktop.

---

## 📐 Diagrama de Arquitectura

```mermaid
graph TD
    User["Usuario (Móvil / PC Desktop)"]
    
    subgraph FlutterApp["Flutter Application (Arcade Noir UI)"]
        UI["Screens (Dashboard, Search, Detail, Analytics, Settings, Setup)"]
        RespGrid["Responsive Layout Builder (Mobile: 2 cols | Tablet: 3-4 cols | Desktop: 4-6 cols)"]
        State["Local State & Cache Manager (TTL 60s)"]
        NotionSvc["NotionService (Queue, Rate Limiter <= 3 req/s)"]
        Parser["NotionParser (Notion Block/Property <-> Game Model)"]
        Prefs["SharedPreferences (Notion Token, DB ID, RAWG Key)"]
    end
    
    subgraph ExternalServices["Servicios Externos"]
        NotionAPI["Notion API v1 (Database: Games)"]
        RAWGAPI["RAWG Video Games Database API"]
    end

    User --> UI
    UI --> RespGrid
    UI --> State
    State --> NotionSvc
    NotionSvc --> Parser
    NotionSvc --> NotionAPI
    UI --> RAWGAPI
    UI --> Prefs
    NotionSvc --> Prefs
```

---

## 🖥️ Estrategia Responsiva Desktop / PC

1. **Grid Responsivo en Dashboard:**
   - En lugar de `crossAxisCount: 2` estático, se utiliza `SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 220, childAspectRatio: 0.65)` o cálculo dinámico por ancho de pantalla.
2. **Modales y Diálogos con Constraints:**
   - Todos los diálogos (`showDialog`, modal bottom sheets) tendrán un ancho máximo acotado (`BoxConstraints(maxWidth: 550)`) centrado en pantallas panorámicas.
3. **CI/CD Multiplataforma:**
   - GitHub Actions para compilar APK de Android (`build_apk.yml`) y Ejecutable de Windows (`build_windows.yml`).
