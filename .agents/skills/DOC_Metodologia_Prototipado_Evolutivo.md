# Metodología de Prototipado Evolutivo (Adaptada para Agentes)

![Prototipado Evolutivo](./Prototipado%20Evolutivo.png)

El **Prototipado Evolutivo** es el corazón de este ecosistema de desarrollo autónomo. A diferencia de un ciclo de desarrollo en cascada, donde todo se planea de golpe, esta metodología se basa en construir sistemas funcionales rápidamente, evaluar los resultados, y evolucionar el código iteración tras iteración (v0.1, v0.2, v1.0). 

La regla de oro de nuestra adaptación es: **Rápido no significa baja calidad.** Cortamos el alcance (*scope*), no las bases arquitectónicas.

A continuación se detalla cómo cada fase de este ciclo de vida se mapea directamente con los 5 agentes especializados.

---

## 🔄 El Ciclo y los 5 Agentes

### 1. Comunicación (El Punto de Partida)
* **Actor Principal:** `Usuario` (Tú)
* **Descripción:** El ciclo inicia cuando planteas un objetivo o necesidad de negocio. 
* **Transición:** Tu solicitud es procesada por el líder técnico.

### 2. Plan Rápido (YAGNI)
* **Agente a cargo:** `Project-Planner`
* **Descripción:** El Planner divide tu requerimiento en tareas pequeñas y digeribles (MVP). Se basa estrictamente en el principio **YAGNI** (*You Aren't Gonna Need It*) para no sobre-ingeniar.
* **Artefactos Clave:** Define el Tech Stack en `architecture.md`, crea la ruta a seguir en `implementation_plan.md` y delega las responsabilidades en `task.md`. Finalmente, abre la bitácora de la versión en `changelog_vX.md`.

### 3. Modelado y Diseño Rápido
* **Agentes a cargo:** `Backend-Architect` y `Frontend-UI`
* **Descripción:** Antes de tirar una sola línea de código, los especialistas diseñan el contrato de datos. El Backend define las rutas de la API y el modelo de datos. El Frontend concibe la jerarquía visual respetando los límites del DOM.
* **Artefactos Clave:** Se genera el `api_spec.md`. Todo el equipo se alinea en cómo se comunicarán los sistemas.

### 4. Construcción (Desarrollo Central)
* **Agentes a cargo:** `Backend-Architect` y `Frontend-UI`
* **Descripción:** Ambos agentes ejecutan sus tareas en paralelo (o secuencialmente). El Backend levanta la lógica de negocio (evitando el N+1 y cuidando el IDOR), mientras el Frontend consume la API y maqueta los componentes.
* **Restricción:** Siguen el **Protocolo Anti-Alucinación (No Blind Fixes)**. No pueden "adivinar" código; si algo falla, deben inyectar logs e inspeccionar antes de parchar.

### 5. Quality Gate (Evaluación y Auditoría)
* **Agente a cargo:** `Systems-Auditor`
* **Descripción:** El código construido se somete a una barrera de peaje implacable. El Auditor escribe pruebas (Tests), verifica los límites matemáticos del DOM (ej. < 1400 nodos) y escanea las dependencias en busca de vulnerabilidades (`npm audit`).
* **Artefactos Clave:** Emite el `audit_report.md`. 
  * Si el veredicto es `FAIL`, el flujo se devuelve a la Fase 4 (los desarrolladores tienen que arreglarlo).
  * Si el veredicto es `PASS`, se abre la puerta de la Fase 6.

### 6. Despliegue y Entrega
* **Agente a cargo:** `DevOps-Engineer`
* **Descripción:** Al recibir luz verde, el DevOps empaqueta la iteración (Docker), configura el servidor proxy/SSL y lanza la versión ejecutable.
* **Transición:** El prototipo se expone para que lo pruebes.

### 7. Feedback (El Motor de la Evolución)
* **Actor Principal:** `Usuario` (Tú)
* **Descripción:** Pruebas el entregable. El feedback que le des al equipo se convierte en los requisitos de la fase 1 de la *siguiente iteración*. El Planner registra el salto de versión y el ciclo de vida del prototipo evoluciona una vez más.

---

## 🛠️ Conclusión

Esta metodología permite que el ecosistema de 5 agentes opere como una **fábrica de software iterativa sin fricción**. La separación de poderes garantiza que el que diseña no asuma responsabilidades de infraestructura, y que el que escribe el código nunca sea el mismo que evalúa su calidad. Todo respaldado por una red de archivos Markdown (artefactos) que previenen la amnesia de las IAs.
