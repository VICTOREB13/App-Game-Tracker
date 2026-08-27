import json
import time
import requests
import os
import urllib.parse
from datetime import date
from difflib import SequenceMatcher
from howlongtobeatpy import HowLongToBeat

# ==================== CONFIGURACIÓN ====================
# Leemos secretos (Con .strip() para evitar errores de cabeceras en GitHub Actions)
NOTION_TOKEN = os.environ.get("NOTION_TOKEN", "").strip()
RAWG_KEY = os.environ.get("RAWG_KEY", "").strip()
STEAM_KEY = os.environ.get("STEAM_KEY", "").strip()
STEAM_USER_ID = os.environ.get("STEAM_USER_ID", "").strip()

# ID DE TU BASE DE DATOS (Ahora desde variables de entorno)
DB_ID = os.environ.get("DB_ID_GAMES", "").strip()

HEADERS_NOTION = {
    "Authorization": f"Bearer {NOTION_TOKEN}",
    "Notion-Version": "2022-06-28",
    "Content-Type": "application/json"
}

# Estados FINALES: si el juego ya tiene uno de estos, NO se cambia automáticamente.
# Solo "Jugado" es el estado final. Los activos (Por Jugar, Jugando) SÍ se auto-completan.
ESTADOS_FINALES = ["Jugado"]
# =======================================================

# --- UTILIDADES ---
def limpiar_nombre(n):
    """Borra símbolos de marca y puntuación para una comparación justa"""
    if not n: return ""
    # Símbolos que suelen causar duplicados si no coinciden
    for char in ['™', '®', '©', ':', '.', ',', '!', '?', '-', '_', '(', ')']:
        n = n.replace(char, ' ')
    # Normalización: minúsculas, espacios extra fuera y orden de palabras limpio
    return " ".join(n.lower().split()).strip()

def similar(a, b):
    """Calcula qué tan parecidos son dos nombres (0 a 1)"""
    return SequenceMatcher(None, limpiar_nombre(a), limpiar_nombre(b)).ratio()

def obtener_nombre_pagina(props):
    """Extrae el nombre del juego desde las propiedades de una página de Notion"""
    if "Título" in props and props["Título"]["title"]:
        return props["Título"]["title"][0]["text"]["content"]
    elif "Name" in props and props["Name"]["title"]:
        return props["Name"]["title"][0]["text"]["content"]
    return ""

# --- 1. NOTION: LECTURA Y ESCRITURA ---
def obtener_todos_juegos_notion():
    url = f"https://api.notion.com/v1/databases/{DB_ID}/query"
    juegos = {}
    has_more = True
    cursor = None
    
    print("📂 Leyendo Notion...")
    while has_more:
        payload = {}
        if cursor: payload["start_cursor"] = cursor
        
        try:
            r = requests.post(url, headers=HEADERS_NOTION, json=payload)
            data = r.json()
            results = data.get("results", [])
            
            for page in results:
                props = page["properties"]
                nombre = obtener_nombre_pagina(props)
                if nombre:
                    juegos[nombre] = page
            
            has_more = data.get("has_more", False)
            cursor = data.get("next_cursor")
        except Exception as e:
            print(f"Error leyendo Notion: {e}")
            break
            
    return juegos

def crear_juego_notion(nombre, steam_appid, horas):
    url = "https://api.notion.com/v1/pages"
    
    properties = {
        "Título": {"title": [{"text": {"content": nombre}}]},
        "Steam ID": {"number": steam_appid},
        "Horas Jugadas": {"number": round(horas, 1)},
        "Plataforma": {"select": {"name": "PC"}},
        "Estado": {"status": {"name": "Jugado" if horas > 1 else "Por Jugar"}}
    }
    
    # Si ya tiene horas jugadas, registramos la fecha de inicio como hoy
    if horas > 0:
        properties["Fecha de Inicio"] = {"date": {"start": date.today().isoformat()}}
    
    payload = {
        "parent": {"database_id": DB_ID},
        "properties": properties
    }
    
    r = requests.post(url, headers=HEADERS_NOTION, json=payload)
    if r.status_code == 200:
        print(f"✨ CREADO en Notion: {nombre}")
    else:
        print(f"❌ Error creando {nombre}: {r.status_code} - {r.text}")

def actualizar_juego_notion(page, horas_nuevas, steam_id=None):
    """Actualiza un juego existente SOLO si algo realmente cambió.
    Incluye lógica de Fecha de Inicio y auto-culminación por HLTB."""
    props = page["properties"]
    page_id = page["id"]
    nombre = obtener_nombre_pagina(props)
    
    # --- Leer estado actual del juego en Notion ---
    horas_actuales = props.get("Horas Jugadas", {}).get("number") or 0
    tiene_fecha_inicio = props.get("Fecha de Inicio", {}).get("date") is not None
    tiene_fecha_culm = props.get("Fecha de Culminación (primera campaña)", {}).get("date") is not None
    hltb_principal = props.get("HLTB Principal", {}).get("number")
    steam_id_actual = props.get("Steam ID", {}).get("number")
    
    estado_actual = ""
    if "Estado" in props and props["Estado"].get("status"):
        estado_actual = props["Estado"]["status"].get("name", "")
    
    # --- Construir payload solo con lo que necesita cambiar ---
    payload_props = {}
    needs_update = False
    cambios = []  # Para el log
    
    # 1. Horas: solo actualizar si el valor cambió
    if round(horas_nuevas, 1) != round(horas_actuales, 1):
        payload_props["Horas Jugadas"] = {"number": round(horas_nuevas, 1)}
        cambios.append(f"horas {round(horas_actuales, 1)} → {round(horas_nuevas, 1)}")
        needs_update = True
    
    # 2. Steam ID: solo si falta o es diferente
    if steam_id and steam_id_actual != steam_id:
        payload_props["Steam ID"] = {"number": steam_id}
        needs_update = True
    
    # 3. Fecha de Inicio: si tiene horas pero no tiene fecha, la ponemos hoy
    if horas_nuevas > 0 and not tiene_fecha_inicio:
        payload_props["Fecha de Inicio"] = {"date": {"start": date.today().isoformat()}}
        cambios.append("+ fecha inicio")
        needs_update = True
    
    # 4. Auto-Culminación: si las horas superan el HLTB principal y no está finalizado
    if (hltb_principal and hltb_principal > 0
            and horas_nuevas >= hltb_principal
            and estado_actual not in ESTADOS_FINALES):
        payload_props["Estado"] = {"status": {"name": "Jugado"}}
        cambios.append(f"estado → Jugado ({round(horas_nuevas, 1)}h >= {hltb_principal}h HLTB)")
        # También registrar fecha de culminación si no existe
        if not tiene_fecha_culm:
            payload_props["Fecha de Culminación (primera campaña)"] = {
                "date": {"start": date.today().isoformat()}
            }
            cambios.append("+ fecha culminación")
        needs_update = True
    
    # --- Solo enviamos el PATCH si hay algo que actualizar ---
    if not needs_update:
        return
    
    r = requests.patch(
        f"https://api.notion.com/v1/pages/{page_id}",
        headers=HEADERS_NOTION,
        json={"properties": payload_props}
    )
    
    if r.status_code == 200:
        print(f"   ✅ {nombre}: {', '.join(cambios)}")
    else:
        print(f"   ❌ Error actualizando {nombre}: {r.status_code} - {r.text}")

# --- 2. STEAM ---
def obtener_juegos_steam():
    """Obtiene juegos de Steam combinando dos fuentes:
    - GetOwnedGames: juegos comprados por el usuario
    - GetRecentlyPlayedGames: juegos recientes (incluye Family Sharing)
    Retorna un dict {appid: {name, appid, playtime_forever}}"""
    
    juegos = {}
    
    # 1. Juegos propios (comprados)
    try:
        url = (f"http://api.steampowered.com/IPlayerService/GetOwnedGames/v0001/"
               f"?key={STEAM_KEY}&steamid={STEAM_USER_ID}&format=json"
               f"&include_appinfo=true&include_played_free_games=true")
        r = requests.get(url)
        data = r.json()
        for g in data["response"].get("games", []):
            juegos[g["appid"]] = g
        print(f"   📦 Juegos propios: {len(juegos)}")
    except Exception as e:
        print(f"   ⚠️ Error obteniendo juegos propios: {e}")
    
    # 2. Juegos recientes (incluye Family Sharing de las últimas 2 semanas)
    try:
        url = (f"http://api.steampowered.com/IPlayerService/GetRecentlyPlayedGames/v0001/"
               f"?key={STEAM_KEY}&steamid={STEAM_USER_ID}&format=json")
        r = requests.get(url)
        data = r.json()
        recientes = data["response"].get("games", [])
        nuevos_compartidos = 0
        for g in recientes:
            aid = g["appid"]
            if aid not in juegos:
                # Este juego NO está en los propios → es Family Sharing u otro
                juegos[aid] = g
                nuevos_compartidos += 1
            else:
                # Ya lo tenemos, pero el playtime reciente puede ser más actual
                # GetRecentlyPlayedGames también trae playtime_forever
                if g.get("playtime_forever", 0) > juegos[aid].get("playtime_forever", 0):
                    juegos[aid]["playtime_forever"] = g["playtime_forever"]
        if nuevos_compartidos > 0:
            print(f"   👨‍👩‍👧‍👦 Juegos de Family Sharing detectados: {nuevos_compartidos}")
        print(f"   🎮 Total combinado: {len(juegos)} juegos")
    except Exception as e:
        print(f"   ⚠️ Error obteniendo juegos recientes: {e}")
    
    return juegos

def sincronizar_steam(juegos_notion):
    if not STEAM_KEY or not STEAM_USER_ID:
        print("⚠️ Saltando Steam: Falta API Key o User ID en Secrets.")
        return

    print("🚀 Conectando con Steam...")
    
    try:
        # Obtener juegos de ambas fuentes (propios + Family Sharing)
        juegos_steam = obtener_juegos_steam()
        
        # Diccionarios auxiliares para búsqueda rápida en Notion
        juegos_notion_limpios = {limpiar_nombre(n): p for n, p in juegos_notion.items()}
        
        # Índice por Steam ID para encontrar juegos que ya existen con ID conocido
        juegos_por_steam_id = {}
        for n, p in juegos_notion.items():
            sid = p["properties"].get("Steam ID", {}).get("number")
            if sid:
                juegos_por_steam_id[int(sid)] = p

        actualizados = 0
        creados = 0

        for appid, g in juegos_steam.items():
            nombre_steam = g["name"]
            horas = g["playtime_forever"] / 60
            
            # FILTRO: Solo procesamos juegos con más de 30 minutos
            if horas < 0.5:
                continue

            # Buscamos si ya existe en Notion (3 estrategias)
            page = None
            nombre_steam_limpio = limpiar_nombre(nombre_steam)

            # Intento 1: Búsqueda por Steam ID (la más confiable)
            if appid in juegos_por_steam_id:
                page = juegos_por_steam_id[appid]
            # Intento 2: Búsqueda exacta por nombre (limpio)
            elif nombre_steam_limpio in juegos_notion_limpios:
                page = juegos_notion_limpios[nombre_steam_limpio]
            else:
                # Intento 3: Búsqueda por similitud (Fuzzy matching)
                for nombre_notion_limpio, p in juegos_notion_limpios.items():
                    if SequenceMatcher(None, nombre_steam_limpio, nombre_notion_limpio).ratio() > 0.9:
                        page = p
                        break
            
            if page:
                # Juego existe → actualizar solo si cambió algo
                actualizar_juego_notion(page, horas, appid)
                actualizados += 1
            else:
                # Juego nuevo → crear
                crear_juego_notion(nombre_steam, appid, horas)
                creados += 1
            
            # Respetar rate-limit de Notion (máx 3 req/s)
            time.sleep(0.4)
        
        print(f"\n   📊 Resumen Steam: {actualizados} revisados, {creados} nuevos creados.")
                
    except Exception as e:
        print(f"❌ Error Steam: {e}")

# --- 3. PROVEEDORES DE DATOS (HLTB, Wiki, RAWG) ---

def buscar_hltb(juego):
    try:
        results = HowLongToBeat().search(juego)
        if results and len(results) > 0:
            best = results[0]
            return best.main_story, best.completionist
    except: pass
    return None, None

def buscar_wikipedia(juego):
    busquedas = [{"lang": "es", "q": f"{juego} videojuego"}, {"lang": "en", "q": f"{juego} video game"}]
    headers = {"User-Agent": "NotionBot/1.0"}
    for item in busquedas:
        try:
            r = requests.get(f"https://{item['lang']}.wikipedia.org/w/api.php", 
                           params={"action": "query", "list": "search", "srsearch": item['q'], "format": "json", "srlimit": 1},
                           headers=headers, timeout=3)
            data = r.json()
            if data["query"]["search"]:
                t = data["query"]["search"][0]["title"].replace(" ", "_")
                return f"https://{item['lang']}.wikipedia.org/wiki/{t}"
        except: pass
    return None

def buscar_rawg(juego):
    try:
        r = requests.get("https://api.rawg.io/api/games", params={"key": RAWG_KEY, "search": juego, "page_size": 1}, timeout=5)
        d = r.json()
        if d["results"]:
            g = d["results"][0]
            gen = g["genres"][0]["name"] if g.get("genres") else None
            return g.get("background_image"), gen
    except: pass
    return None, None

# --- 4. RELLENADOR DE METADATOS ---
def rellenar_metadata(juegos_notion):
    print("\n🔍 Revisando metadatos faltantes (HLTB, Fotos, Wiki)...")
    
    for nombre, page in juegos_notion.items():
        props = page["properties"]
        payload = {"properties": {}}
        needs_update = False
        
        # 1. HLTB
        if "HLTB Principal" in props and props["HLTB Principal"]["number"] is None:
            main_h, comp_h = buscar_hltb(nombre)
            if main_h:
                payload["properties"]["HLTB Principal"] = {"number": main_h}
                needs_update = True
            if comp_h:
                payload["properties"]["HLTB Completista"] = {"number": comp_h}
                needs_update = True
            
            # Tras obtener HLTB, verificar auto-culminación inmediata
            if main_h:
                horas_jugadas = props.get("Horas Jugadas", {}).get("number") or 0
                estado_actual = ""
                if "Estado" in props and props["Estado"].get("status"):
                    estado_actual = props["Estado"]["status"].get("name", "")
                
                if horas_jugadas >= main_h and estado_actual not in ESTADOS_FINALES:
                    payload["properties"]["Estado"] = {"status": {"name": "Jugado"}}
                    tiene_fecha_culm = props.get("Fecha de Culminación (primera campaña)", {}).get("date") is not None
                    if not tiene_fecha_culm:
                        payload["properties"]["Fecha de Culminación (primera campaña)"] = {
                            "date": {"start": date.today().isoformat()}
                        }
                    print(f"   🏆 Auto-culminado por HLTB: {nombre} ({horas_jugadas}h >= {main_h}h)")

        # 2. RAWG (Foto/Género)
        falta_foto = not (props.get("Portada", {}).get("files"))
        falta_genero = not (props.get("Géneros", {}).get("multi_select") or props.get("Géneros", {}).get("select"))
        
        if falta_foto or falta_genero:
            img, gen = buscar_rawg(nombre)
            if falta_foto and img:
                payload["properties"]["Portada"] = {"files": [{"type": "external", "name": "Cover", "external": {"url": img}}]}
                payload["cover"] = {"type": "external", "external": {"url": img}}
                payload["icon"] = {"type": "external", "external": {"url": img}}
                needs_update = True
            if falta_genero and gen:
                # Intento de mapeo inteligente a select o multi_select
                if "select" in props["Géneros"]:
                    payload["properties"]["Géneros"] = {"select": {"name": gen}}
                else:
                    payload["properties"]["Géneros"] = {"multi_select": [{"name": gen}]}
                needs_update = True

        # 3. Wikipedia
        if "Link" in props and not props["Link"]["url"]:
            wiki = buscar_wikipedia(nombre)
            if wiki:
                payload["properties"]["Link"] = {"url": wiki}
                needs_update = True

        if needs_update:
            r = requests.patch(f"https://api.notion.com/v1/pages/{page['id']}", headers=HEADERS_NOTION, json=payload)
            if r.status_code == 200:
                print(f"   ✅ Datos actualizados: {nombre}")
            else:
                print(f"   ❌ Error actualizando metadatos de {nombre}: {r.status_code} - {r.text}")
            time.sleep(0.5)

# --- MAIN ---
if __name__ == "__main__":
    current_juegos = obtener_todos_juegos_notion()
    sincronizar_steam(current_juegos)
    current_juegos = obtener_todos_juegos_notion() # Refrescar
    rellenar_metadata(current_juegos)
    print("\n🏁 Sincronización completa.")
