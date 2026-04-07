import json
import time
import requests
import os

# ==================== CONFIGURACIÓN ====================
# Intenta leer las claves de las variables de entorno (Para GitHub Actions)
# Si no las encuentra, usa las que ponemos aquí por defecto (Para tu PC)

NOTION_TOKEN = os.environ.get("NOTION_TOKEN", "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")
RAWG_KEY = os.environ.get("RAWG_KEY", "2d28c05e7c414d4e86d9cd7a766008a1")

# ID de tu Base de Datos NUEVA (La única que importa ahora)
DB_ID = "29094bde8dc781519c47cd00ce3e7e46"
# =======================================================

HEADERS_NOTION = {
    "Authorization": f"Bearer {NOTION_TOKEN}",
    "Notion-Version": "2022-06-28",
    "Content-Type": "application/json"
}

# --- 1. BUSCADOR WIKIPEDIA (ESPAÑOL -> INGLÉS) ---
def buscar_wikipedia(juego):
    queries = [juego, f"{juego} (videojuego)", f"{juego} (video game)"]
    
    # Intento 1: Español
    for q in queries:
        try:
            r = requests.get("https://es.wikipedia.org/w/api.php", 
                           params={"action": "opensearch", "search": q, "limit": 1, "format": "json"}, 
                           timeout=3)
            if r.json()[3]: return r.json()[3][0]
        except: pass

    # Intento 2: Inglés (Fallback)
    for q in queries:
        try:
            r = requests.get("https://en.wikipedia.org/w/api.php", 
                           params={"action": "opensearch", "search": q, "limit": 1, "format": "json"}, 
                           timeout=3)
            if r.json()[3]: return r.json()[3][0]
        except: pass
    return None

# --- 2. BUSCADOR RAWG (IMAGEN Y GÉNERO) ---
def buscar_rawg(juego):
    try:
        r = requests.get("https://api.rawg.io/api/games", 
                       params={"key": RAWG_KEY, "search": juego, "page_size": 1}, 
                       timeout=5)
        data = r.json()
        
        if data["results"]:
            g = data["results"][0]
            img = g.get("background_image")
            
            # Extraer y traducir género
            gen_name = None
            if g.get("genres"):
                gen_name = g["genres"][0]["name"]
                traductor = {
                    "Action": "Acción", "Adventure": "Aventura", "RPG": "Rol",
                    "Strategy": "Estrategia", "Shooter": "Shooter", "Puzzle": "Puzle",
                    "Platformer": "Plataformas", "Fighting": "Lucha", "Racing": "Carreras",
                    "Simulation": "Simulación", "Sports": "Deportes", "Indie": "Indie",
                    "Massively Multiplayer": "MMO"
                }
                gen_name = traductor.get(gen_name, gen_name)
            
            return img, gen_name
    except Exception as e:
        print(f"Error conectando a RAWG: {e}")
    return None, None

# --- 3. LECTURA DE NOTION ---
def obtener_juegos_incompletos():
    url = f"https://api.notion.com/v1/databases/{DB_ID}/query"
    juegos = []
    has_more = True
    cursor = None
    
    print("🔍 Escaneando tu biblioteca en busca de juegos incompletos...")
    
    while has_more:
        payload = {}
        if cursor: payload["start_cursor"] = cursor
        
        r = requests.post(url, headers=HEADERS_NOTION, json=payload)
        data = r.json()
        
        if "results" not in data:
            print("Error leyendo Notion. Revisa el Token.")
            break
            
        juegos.extend(data["results"])
        has_more = data.get("has_more", False)
        cursor = data.get("next_cursor")
    return juegos

# --- 4. ACTUALIZACIÓN ---
def rellenar_juego(page):
    props = page["properties"]
    
    # Obtener Nombre
    try:
        if "Título" in props:
            nombre = props["Título"]["title"][0]["text"]["content"]
        else:
            nombre = props["Name"]["title"][0]["text"]["content"]
    except:
        return # Si no tiene nombre, ignorar

    # --- CHEQUEO DE QUÉ FALTA ---
    falta_foto = True
    if "Portada" in props and props["Portada"]["files"]: falta_foto = False
    
    falta_link = True
    if "Link" in props and props["Link"]["url"]: falta_link = False
    
    falta_genero = True
    if "Géneros" in props and props["Géneros"]["select"]: falta_genero = False

    # Si tiene todo, no hacemos nada
    if not (falta_foto or falta_link or falta_genero):
        return

    print(f"🛠️  Procesando: {nombre}...")

    # --- BÚSQUEDAS ---
    img_rawg, gen_rawg = None, None
    link_wiki = None

    if falta_foto or falta_genero:
        img_rawg, gen_rawg = buscar_rawg(nombre)
    
    if falta_link:
        link_wiki = buscar_wikipedia(nombre)

    # --- PREPARAR CAMBIOS ---
    payload = {"properties": {}}
    
    # 1. Foto (Portada, Icono, Cover)
    if falta_foto and img_rawg:
        payload["properties"]["Portada"] = {
            "files": [{"type": "external", "name": "Cover", "external": {"url": img_rawg}}]
        }
        payload["cover"] = {"type": "external", "external": {"url": img_rawg}}
        payload["icon"] = {"type": "external", "external": {"url": img_rawg}}

    # 2. Género
    if falta_genero and gen_rawg:
        payload["properties"]["Géneros"] = {"select": {"name": gen_rawg}}

    # 3. Link
    if falta_link and link_wiki:
        payload["properties"]["Link"] = {"url": link_wiki}

    # --- ENVIAR A NOTION ---
    if payload["properties"] or "cover" in payload:
        requests.patch(f"https://api.notion.com/v1/pages/{page['id']}", headers=HEADERS_NOTION, json=payload)
        print(f"   ✅ Actualizado: {nombre}")
    else:
        print(f"   ⚠️ No se encontraron datos nuevos para: {nombre}")
    
    time.sleep(1) # Pausa para ser amable con las APIs

# --- MAIN ---
if __name__ == "__main__":
    lista_juegos = obtener_juegos_incompletos()
    print(f"📂 Total de juegos en base de datos: {len(lista_juegos)}")
    
    for juego in lista_juegos:
        rellenar_juego(juego)
        
    print("\n✨ ¡Todo listo! Tu colección está al día.")