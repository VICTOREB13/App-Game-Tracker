import streamlit as st
import pandas as pd
import plotly.express as px
import requests

# --- CONFIGURACIÓN ---
try:
    NOTION_TOKEN = st.secrets["NOTION_TOKEN"]
    DB_ID = st.secrets["DB_ID"]
except:
    st.error("❌ Faltan claves.")
    st.stop()

HEADERS = {
    "Authorization": f"Bearer {NOTION_TOKEN}",
    "Notion-Version": "2022-06-28",
    "Content-Type": "application/json"
}

st.set_page_config(page_title="Dashboard", layout="centered")

# --- CSS ---
st.markdown("""
    <style>
    /* Estilos nativos de Notion */
    html, body, [class*="css"] {
        font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Helvetica, "Apple Color Emoji", Arial, sans-serif, "Segoe UI Emoji", "Segoe UI Symbol" !important;
    }
    footer {visibility: hidden;}
    header {visibility: hidden;}
    .block-container {padding: 0rem 0.5rem 0.5rem 0.5rem;}
    .metric-container {
        display: flex;
        justify-content: space-between;
        background-color: rgba(255, 255, 255, 0.03);
        border: 1px solid rgba(255, 255, 255, 0.05);
        padding: 12px 10px;
        border-radius: 8px;
        margin-bottom: 5px;
    }
    .metric-box {text-align: center; width: 48%;}
    .metric-label {font-size: 13px; opacity: 0.7; margin: 0; font-weight: 500;}
    .metric-value {font-size: 28px; font-weight: bold; color: #5B8BF6; margin-top: 2px;}
    .metric-icon {font-size: 14px; margin-right: 4px;}
    h5 {margin-bottom: 0px; padding-top: 15px; font-size: 15px; font-weight: 600; color: #E8E8E8; opacity: 0.9;}
    </style>
    """, unsafe_allow_html=True)

@st.cache_data(ttl=300) # Se actualiza cada 5 minutos
def cargar_datos_notion():
    url = f"https://api.notion.com/v1/databases/{DB_ID}/query"
    juegos = []
    has_more = True
    cursor = None
    
    while has_more:
        payload = {}
        if cursor: payload["start_cursor"] = cursor
        
        try:
            r = requests.post(url, headers=HEADERS, json=payload)
            if r.status_code != 200: return pd.DataFrame()
            
            data = r.json()
            
            for p in data.get("results", []):
                props = p["properties"]
                
                # 1. EXTRACCIÓN SEGURA DEL NOMBRE
                # Si no tiene nombre, lo saltamos (esto elimina filas vacías reales)
                nombre = "Sin Nombre"
                try:
                    if "Título" in props and props["Título"]["title"]:
                        nombre = props["Título"]["title"][0]["text"]["content"]
                    elif "Name" in props and props["Name"]["title"]:
                        nombre = props["Name"]["title"][0]["text"]["content"]
                    else:
                        continue # Si literalmente no tiene título, no es un juego
                except: continue

                # 2. EXTRACCIÓN SEGURA DE PROPIEDADES
                # Usamos .get() encadenado para que nunca falle si falta un dato
                try:
                    # Estado
                    estado = props.get("Estado", {}).get("status", {})
                    estado_nombre = estado.get("name", "Sin Estado") if estado else "Sin Estado"
                    
                    # Horas
                    horas = props.get("Horas Jugadas", {}).get("number", 0)
                    if horas is None: horas = 0
                    
                    # Plataforma
                    plat_obj = props.get("Plataforma", {}).get("select", {})
                    plat_nombre = plat_obj.get("name", "Desconocido") if plat_obj else "Desconocido"
                    
                    juegos.append({
                        "Juego": nombre,
                        "Estado": estado_nombre,
                        "Horas": horas,
                        "Plataforma": plat_nombre
                    })
                except:
                    # Si falla algo raro, guardamos lo mínimo para que cuente en el total
                    juegos.append({
                        "Juego": nombre,
                        "Estado": "Error Lectura",
                        "Horas": 0,
                        "Plataforma": "Error"
                    })

            has_more = data.get("has_more", False)
            cursor = data.get("next_cursor")
            
        except:
            has_more = False
            
    return pd.DataFrame(juegos)

# --- INTERFAZ ---

df = cargar_datos_notion()

if not df.empty:
    total = len(df)
    horas = int(df['Horas'].sum())
    
    st.markdown(f"""
        <div class="metric-container">
            <div class="metric-box">
                <p class="metric-label"><span class="metric-icon">🎮</span>Juegos</p>
                <p class="metric-value">{total}</p>
            </div>
            <div style="border-left: 1px solid rgba(255,255,255,0.1);"></div>
            <div class="metric-box">
                <p class="metric-label"><span class="metric-icon">⏳</span>Horas</p>
                <p class="metric-value">{horas}</p>
            </div>
        </div>
    """, unsafe_allow_html=True)

    orden_estados = ["Por jugar", "Jugando", "Jugado"]
    colores = {
        "Por jugar": "#E3A008",
        "Jugando": "#2563EB",
        "Jugado": "#DC2626",
        "Sin Estado": "#9CA3AF",
        "Desconocido": "#9CA3AF"
    }

    st.markdown("##### 📌 Estado")
    fig_bar = px.histogram(
        df, x="Estado", color="Estado",
        category_orders={"Estado": orden_estados},
        color_discrete_map=colores,
        text_auto=True
    )
    fig_bar.update_traces(
        hovertemplate='<b>%{x}</b><br>Juegos: %{y}<extra></extra>',
        marker_line_width=0,
        textfont_color="white",
        textfont_size=13
    )
    fig_bar.update_layout(
        showlegend=False, paper_bgcolor='rgba(0,0,0,0)', plot_bgcolor='rgba(0,0,0,0)',
        xaxis_title=None, yaxis_title=None,
        xaxis=dict(showgrid=False, tickfont=dict(size=12, color='rgba(255,255,255,0.7)')), 
        yaxis=dict(showgrid=False, showticklabels=False),
        margin=dict(l=0, r=0, t=5, b=0), height=180,
        dragmode=False
    )
    st.plotly_chart(fig_bar, use_container_width=True, config={'displayModeBar': False})

    st.markdown("##### 🕹️ Plataformas")
    fig_pie = px.pie(df, names='Plataforma', values='Horas', hole=0.65)
    fig_pie.update_traces(
        textposition='inside', 
        textinfo='percent',
        hovertemplate='<b>%{label}</b><br>Horas: %{value}<br>Porcentaje: %{percent}<extra></extra>',
        marker=dict(line=dict(color='rgba(0,0,0,0)', width=0))
    )
    fig_pie.update_layout(
        showlegend=False, paper_bgcolor='rgba(0,0,0,0)',
        margin=dict(l=10, r=10, t=10, b=10), height=210,
        annotations=[dict(text='Horas', x=0.5, y=0.5, font_size=14, font_color='rgba(255,255,255,0.7)', showarrow=False)],
        dragmode=False
    )
    st.plotly_chart(fig_pie, use_container_width=True, config={'displayModeBar': False})

else:
    st.info("Cargando o sin datos...")
