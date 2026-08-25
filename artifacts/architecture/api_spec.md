---
tipo: api_spec
proyecto: Nombre_Del_Proyecto
version: v0.1.0
estado: activo
tags: [proyecto, api, backend]
---

# Especificación de API y Modelos de Datos

> **Instrucción para Backend-Architect:** Diseña aquí los modelos de base de datos y los endpoints de la API (REST/GraphQL) antes de escribir código. El Frontend-UI usará este documento para consumir los datos.

## 🗄️ Modelos de Base de Datos
- **Modelo:** `User`
  - Atributos: `id`, `name`, `email`
  - Índices: `[tenant_id]`

## 📡 Endpoints de la API
- **GET /api/resource**
  - Descripción: Obtiene recursos.
  - Respuesta: `200 OK`
