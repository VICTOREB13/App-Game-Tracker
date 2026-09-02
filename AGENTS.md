# Protocolo de Orquestación de Agentes y Subagentes (Teamwork)

Este workspace opera bajo la metodología de **Prototipado Evolutivo** implementada a través de un **Orquestador Principal** y un **Pool de Subagentes Especializados**.

---

## 1. Asignación de Modelos de IA
* **Agente Principal (Chat / Orquestador):** Debe configurarse con **Gemini 3.1 Pro (High)**. Actúa permanentemente con la habilidad `Project-Planner`.
* **Subagentes Autónomos:** Se ejecutan con **Gemini 3.7 Flash (High)**. Cada uno asume su rol especializado en un contexto aislado:
  * `Backend-Architect` (.agents/skills/backend-architect/SKILL.md)
  * `Frontend-UI` (.agents/skills/frontend-ui/SKILL.md)
  * `Systems-Auditor` (.agents/skills/systems-auditor/SKILL.md)
  * `DevOps-Engineer` (.agents/skills/devops-engineer/SKILL.md)

---

## 2. Regla Fundamental de Ejecución (No Coding en Chat Principal)
1. El **Agente Principal (Project-Planner)** tiene estrictamente prohibido escribir código de producción, tests o dockerfiles directamente en el chat raíz.
2. Su función exclusiva es:
   - Investigar el repositorio.
   - Diseñar la arquitectura técnica en `artifacts/architecture/architecture.md`.
   - Redactar el plan en `artifacts/planning/implementation_plan.md`.
   - Desglosar las tareas atómicas en `artifacts/planning/task.md`.
   - Despachar **subagentes** con **Gemini 3.7 Flash (High)** para cada tarea técnica.
   - Monitorear el progreso y presentar los resultados finales al usuario.

---

## 3. Bus de Comunicación por Artefactos (`artifacts/`)
Los subagentes no comparten ventana de chat; su punto de sincronización son los archivos en disco:
* **Entradas para Backend/Frontend:** `architecture.md`, `implementation_plan.md` y `task.md`.
* **Salida de Backend / Entrada de Frontend:** `api_spec.md`.
* **Salida de Auditoría / Bloqueo de Despliegue:** `audit_reports/audit_report.md` (`Status: PASS` obligatorio para DevOps).
* **Historial de Versiones:** `changelog_vX.md`.
