# Sistema de Inventario Aduanero 🚢📦

Laboratorio universitario de Bases de Datos con **PostgreSQL** y **n8n**.

---

## 📌 Estado del Proyecto y Fases de Entrega

- [x] **Fase 1: Modelo Entidad-Relación (DER)**
  - Documento: [`docs/01_modelo_entidad_relacion.md`](docs/01_modelo_entidad_relacion.md)
  - Cobertura: Entidades padre e hijas, restricciones de integridad, cardinalidad y diagrama Mermaid.
- [x] **Fase 2: Script SQL de Creación (DDL) y Población (DML)**
  - DDL: [`sql/01_creacion_tablas.sql`](sql/01_creacion_tablas.sql)
  - DML: [`sql/02_insercion_datos.sql`](sql/02_insercion_datos.sql)
- [x] **Fase 3: Seguridad y Usuario de Solo Lectura para el Agente**
  - Script: [`sql/03_seguridad_agente_readonly.sql`](sql/03_seguridad_agente_readonly.sql)
- [x] **Fase 4: Flujo n8n y Prompt de Consulta del Agente**
  - Prompt: [`n8n/agente_inventario_aduanero_prompt.md`](n8n/agente_inventario_aduanero_prompt.md)
  - Workflow exportado: [`n8n/workflow_inventario_aduanero.json`](n8n/workflow_inventario_aduanero.json)
  - Guía de configuración: [`n8n/guia_configuracion_n8n.md`](n8n/guia_configuracion_n8n.md)
- [x] **Fase 5: Guía de Validación y Consultas de Prueba**
  - Consultas analíticas y pruebas de restricciones: [`sql/04_consultas_verificacion.sql`](sql/04_consultas_verificacion.sql)
- [x] **Documento de Investigación Académico (3 a 6 páginas)**
  - Informe completo: [`docs/documento_investigacion_inventario_aduanero.md`](docs/documento_investigacion_inventario_aduanero.md)

---

## 🏛️ Estructura del Repositorio

```text
├── docs/
│   └── 01_modelo_entidad_relacion.md  # DER detallado y diccionario de datos
├── sql/
│   ├── 01_creacion_tablas.sql          # Tablas DDL ordenadas (padre -> hijas)
│   ├── 02_insercion_datos.sql          # Datos ficticios realistas (DML)
│   ├── 03_seguridad_agente_readonly.sql# Rol y usuario de solo lectura (SELECT)
│   └── 04_consultas_verificacion.sql   # Pruebas de validación analíticas
├── n8n/
│   ├── agente_inventario_aduanero_prompt.md # Prompt del agente y reglas de consulta
│   └── workflow_inventario_aduanero.json    # Workflow exportado de n8n
└── README.md
```
