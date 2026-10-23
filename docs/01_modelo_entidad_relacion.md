# Fase 1: Modelo Entidad-Relación (DER) - Sistema de Inventario Aduanero

## 1. Contexto y Propósito del Sistema
El presente sistema modela el control de inventario de mercancías bajo régimen aduanero y custodia fiscal en depósitos aduaneros, permitiendo la trazabilidad desde el arribo y declaración aduanera (DUA) de las mercancías, su ubicación física en bodega, su estado fiscal (en custodia, retenida, levante autorizado) y las inspecciones físicas o documentales (aforos) realizadas por las autoridades aduaneras.

---

## 2. Diagrama Entidad-Relación (Mermaid ERD)

```mermaid
erDiagram
    importador ||--o{ declaracion_aduanera : "consigna / tramita"
    deposito_aduanero ||--o{ declaracion_aduanera : "alberga operacion"
    declaracion_aduanera ||--|{ mercancia_inventario : "ampara"
    categoria_arancelaria ||--o{ mercancia_inventario : "clasifica"
    mercancia_inventario ||--o{ inspeccion_aduanera : "recibe"

    importador {
        int id_importador PK
        varchar numero_identificacion UK "NIT / RUC / Cedula juridica"
        varchar razon_social
        varchar pais_origen
        varchar telefono
        varchar correo_contacto
        text direccion
        boolean activo
        timestamptz fecha_registro
    }

    deposito_aduanero {
        int id_deposito PK
        varchar codigo_deposito UK "Ej: DEP-SJO-01"
        varchar nombre
        varchar tipo_deposito "temporal | fiscal | franco | refrigerado"
        numeric capacidad_maxima_m3
        varchar ubicacion_puerto_aeropuerto
        varchar responsable
        boolean activo
    }

    categoria_arancelaria {
        int id_categoria PK
        varchar codigo_arancelario UK "Codigo armonizado HS/SAC"
        varchar descripcion
        numeric tasa_arancelaria_porcentaje
        boolean requiere_permiso_especial
    }

    declaracion_aduanera {
        int id_declaracion PK
        varchar numero_declaracion UK "Ej: DUA-2026-001234"
        int id_importador FK
        int id_deposito FK
        varchar tipo_regimen "importacion_definitiva | deposito_fiscal | transito_aduanero | admision_temporal"
        varchar canal_aforo "verde | amarillo | rojo"
        varchar estado_declaracion "registrada | en_revision | autorizada | rechazada | liquidada"
        timestamptz fecha_presentacion
        timestamptz fecha_levante
    }

    mercancia_inventario {
        int id_mercancia PK
        int id_declaracion FK
        int id_categoria FK
        varchar codigo_bulto UK "Etiqueta tracking aduanero"
        varchar descripcion_comercial
        int cantidad_bultos
        numeric peso_bruto_kg
        numeric valor_cif_usd
        varchar ubicacion_especifica
        varchar estado_mercancia "en_custodia | bloqueada_aforo | con_levante | despachada | en_abandono"
        timestamptz fecha_ingreso
        timestamptz fecha_salida
    }

    inspeccion_aduanera {
        int id_inspeccion PK
        int id_mercancia FK
        varchar numero_acta UK "Ej: ACTA-INSP-2026-001"
        varchar tipo_aforo "documental | fisico | escaner_rayos_x"
        varchar nombre_inspector
        varchar resultado "conforme | no_conforme_ajuste_tributario | no_conforme_comiso | pendiente_dictamen"
        text observaciones
        timestamptz fecha_inspeccion
    }
```

---

## 3. Diccionario de Datos y Reglas de Negocio

### 3.1. Tablas Fuertes / Padres (Sin dependencias foráneas directas)
1. **`importador`**: Almacena las empresas o personas jurídicas responsables legales de la carga ingresada al país.
   - Restricciones: `numero_identificacion` es `UNIQUE` y `NOT NULL`. Validación de formato de correo en `correo_contacto`.
2. **`deposito_aduanero`**: Almacenes autorizados por la Dirección General de Aduanas para la custodia de mercancías.
   - Restricciones: `capacidad_maxima_m3 > 0`. `tipo_deposito` restringido a valores válidos aduaneros.
3. **`categoria_arancelaria`**: Catálogo oficial de partidas arancelarias según el Sistema Arancelario Centroamericano (SAC) o Sistema Armonizado (HS).
   - Restricciones: `tasa_arancelaria_porcentaje BETWEEN 0 AND 100`.

### 3.2. Tablas Hijas y Transaccionales
4. **`declaracion_aduanera`**: Trámite de declaración que ampara la importación de un conjunto de mercancías.
   - Dependencias: Llaves foráneas obligatorias hacia `importador` y `deposito_aduanero`.
   - Restricciones: `canal_aforo` (verde, amarillo, rojo). `fecha_levante >= fecha_presentacion` cuando exista.
5. **`mercancia_inventario`**: Registro físico de cada lote, bulto o contenedor almacenado físicamente en el depósito aduanero.
   - Dependencias: Llaves foráneas hacia `declaracion_aduanera` y `categoria_arancelaria`.
   - Restricciones: `cantidad_bultos > 0`, `peso_bruto_kg > 0`, `valor_cif_usd >= 0`. `fecha_salida >= fecha_ingreso`. Estados finitos de custodia.
6. **`inspeccion_aduanera`**: Registro de control aduanero y actuaciones fiscales sobre mercancías seleccionadas por canal o criterio de riesgo.
   - Dependencias: Llave foránea hacia `mercancia_inventario`.
   - Restricciones: `numero_acta` único. Tipo de aforo y resultado tipificados bajo `CHECK`.

---

## 4. Orden de Creación y Dependencias (DDL)
1. `importador` (Padre)
2. `deposito_aduanero` (Padre)
3. `categoria_arancelaria` (Padre)
4. `declaracion_aduanera` (Hija de importador y deposito_aduanero)
5. `mercancia_inventario` (Hija de declaracion_aduanera y categoria_arancelaria)
6. `inspeccion_aduanera` (Hija de mercancia_inventario)
