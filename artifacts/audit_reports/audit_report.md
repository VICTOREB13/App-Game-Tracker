---
tipo: audit_report
proyecto: Nombre_Del_Proyecto
veredicto: PASS
estado: activo
fecha: AAAA-MM-DD
tags: [proyecto, audit, quality-gate]
---

# Reporte de Auditoría y Quality Gate

> **Instrucción para Systems-Auditor:** Este documento es el guardián del despliegue. Ningún código pasa a producción si el estatus final de este documento no es PASS. Llena las matrices de evaluación antes de dar el veredicto final.

## 🧪 Matriz de Pruebas Automatizadas
- [ ] Pruebas Unitarias Ejecutadas.
- [ ] Pruebas de Integración Ejecutadas.

## 📊 Auditoría de Rendimiento y DOM
- [ ] Consultas N+1 verificadas (No deben existir).
- [ ] Cantidad máxima de nodos DOM por vista (Límite 1400 nodos).

## 🛡️ SecOps (Seguridad)
- [ ] Escaneo de dependencias (npm audit / composer audit).
- [ ] Prevención IDOR y RBAC verificado.

---

## 🚦 Veredicto Final
**Status:** [PASS / FAIL]
*(Si es FAIL, describe qué agente debe arreglar qué cosa y reasigna en el task.md)*
