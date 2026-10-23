# Especificación de Requisitos y Guía de Verificación: Laboratorio 3

**Proyecto:** Sistema de Inventario Aduanero y Custodia Fiscal  
**Tecnologías:** PostgreSQL 16/17, n8n Workflow Automation, LLM / AI Agents, SQL DDL/DML, Git  
**Propósito del Archivo:** Fuente de verdad (*Single Source of Truth*) para la auditoría, control de calidad y verificación integral del avance del proyecto.

---

## 1. Resumen del Caso y Objetivo

### 1.1. Contexto del Caso de Negocio
El laboratorio aborda la gestión y control del flujo de mercancías que ingresan a territorio aduanero bajo regímenes suspensivos y definitivos. En los almacenes fiscales y depósitos aduaneros, es imperativo mantener una trazabilidad milimétrica de cada bulto, lote o contenedor desde su arribo y consignación mediante la Declaración Aduanera (DUA / Póliza), su almacenamiento en ubicaciones físicas específicas dentro de las bodegas, hasta su autorización de desalmacenaje (levante fiscal), abandono o retención por inspección física/documental (aforo rojo o amarillo).

Cualquier discrepancia en el inventario o la liquidación de impuestos arancelarios conlleva implicaciones legales y fiscales de alto impacto. Por tanto, el sistema exige un modelado relacional con consistencia matemática estricta y restricciones de integridad que impidan anomalías operativas.

### 1.2. Objetivo General
Diseñar, implementar y documentar un sistema integral de inventario aduanero que articule:
1. Un **Modelo Entidad-Relación (DER)** normalizado hasta Tercera Forma Normal (3FN).
2. La implementación física en **PostgreSQL** mediante scripts reproducibles (DDL, DML y consultas analíticas de verificación).
3. Una arquitectura de **Defensa en Profundidad** basada en el **Principio de Mínimo Privilegio**, creando un rol de base de datos con permisos exclusivos de solo lectura (`SELECT`).
4. Un **Agente de Inteligencia Artificial en n8n** conectado a la base de datos como herramienta (*Tool*), capaz de responder consultas operativas en lenguaje natural sin riesgo de vulneración o manipulación de datos.
5. Un **Documento de Investigación Académico** riguroso (de 3 a 6 páginas) que fundamente teórica y técnicamente cada componente implementado y transparente el uso de IA generativa.

---

## 2. Entregables y Nombres de Archivo Solicitados

La estructura del repositorio debe organizarse de forma modular bajo las siguientes rutas y nombres de archivo estandarizados:

```text
├── docs/
│   ├── 01_modelo_entidad_relacion.md              # Documentación del DER y diccionario de datos
│   └── documento_investigacion_inventario_aduanero.md # Informe de investigación teórico-práctico (3-6 págs)
├── sql/
│   ├── 01_creacion_tablas.sql                     # Script DDL: creación ordenada de tablas y restricciones
│   ├── 02_insercion_datos.sql                     # Script DML: población de datos ficticios pero realistas
│   ├── 03_seguridad_agente_readonly.sql           # Configuración de seguridad y rol de solo lectura
│   └── 04_consultas_verificacion.sql              # Batería de consultas analíticas y pruebas de integridad
├── n8n/
│   ├── workflow_inventario_aduanero.json          # Flujo exportado de n8n (sin credenciales privadas)
│   ├── agente_inventario_aduanero_prompt.md       # System Message y directrices de consulta del agente
│   └── guia_configuracion_n8n.md                 # Guía de importación, credenciales y casos de prueba
├── .gitignore                                     # Exclusión de credenciales, variables de entorno y temporales
├── README.md                                      # Documentación general y navegación del proyecto
└── REQUISITOS_LAB3.md                             # Especificación oficial de requerimientos y checklist
```

---

## 3. Requisitos del Documento de Investigación

### 3.1. Formato y Condiciones Generales
* **Extensión requerida:** Borrador original de 3 a 6 páginas (aproximadamente 2,000 a 4,500 palabras).
* **Idioma y estilo:** Español formal, claro, coherente y con terminología técnica precisa.
* **Originalidad:** Redacción explicativa en propias palabras; queda prohibida la copia textual sin cita (*copy-paste*).
* **Citas y fuentes:** Referenciar fuentes bibliográficas y técnicas oficiales y confiables, indicando autor, año, título, URL válida y fecha de consulta.
* **Estructura académica obligatoria:**
  1. Portada sugerida (Universidad, Facultad, Escuela, Curso, Código, Título, Estudiante, Carné, Docente, Fecha y Sede).
  2. Introducción al problema aduanero y solución tecnológica.
  3. Secciones temáticas de desarrollo.
  4. Conclusiones sustantivas.
  5. Referencias bibliográficas formalmente citadas.
  6. Indicadores claros con la etiqueta `[PERSONALIZAR]` en aquellos datos institucionales o reflexiones que el estudiante deba completar.

### 3.2. Contenido Temático Obligatorio (14 Puntos)
1. **Definición de Base de Datos y SGBD:** Concepto de persistencia, concurrencia, mini-mundo y cumplimiento de propiedades ACID.
2. **Comparativa RDBMS vs. NoSQL:** Modelos relacionales frente a documentales/clave-valor; justificación de por qué la fiscalización aduanera exige consistencia inmediata (ACID) y no consistencia eventual (BASE).
3. **Estructuras Relacionales y Tipos de Datos:** Conceptos de tabla (relación), registro (tupla) y campo (atributo); explicación de tipos comunes (`SERIAL`, `INTEGER`, `VARCHAR`, `TEXT`, `NUMERIC`, `BOOLEAN`, `TIMESTAMPTZ`) con aplicaciones al ámbito aduanero.
4. **Claves Primarias, Foráneas y Compuestas:** Definición y función de PK, FK y llaves primarias compuestas.
5. **Cardinalidad y Relaciones:** Tipos de relaciones (1:1, 1:N, N:M) y cómo se implementan físicamente en un motor relacional (migración de llaves y tablas asociativas/intermedias).
6. **Integridad Referencial y Restricciones (Constraints):** Comportamientos ante eliminación/actualización (`RESTRICT`, `CASCADE`, `SET NULL`) y restricciones declarativas `NOT NULL`, `UNIQUE`, `CHECK` y `DEFAULT`.
7. **Lenguaje SQL (DDL y DML):** Definición de sublenguajes; comandos DDL (`CREATE`, `ALTER`, `DROP`, `TRUNCATE`); comandos DML (`INSERT`, `SELECT`, `UPDATE`, `DELETE`); y composición relacional con `INNER JOIN`, `LEFT JOIN`, `RIGHT JOIN` y `FULL JOIN`.
8. **Proceso de Normalización:** Explicación formal de 1FN (atomicidad y eliminación de grupos repetitivos), 2FN (dependencia funcional completa) y 3FN (eliminación de dependencias transitivas), con casos de infracción y corrección aplicados a aduanas.
9. **Diagrama Entidad-Relación (DER):** Modelado conceptual; comparativa entre la notación clásica de Peter Chen (rombos, elipses, rectángulos, cardinalidad min/max) y la notación Pata de Gallo (*Crow's Foot* / Martin).
10. **Evaluación de Motores SGBD y Justificación:** Comparativa técnica entre SQLite, MySQL (InnoDB) y PostgreSQL (arquitectura, tipos de datos, concurrencia MVCC, seguridad); justificación de PostgreSQL para el entorno aduanero.
11. **Ecosistema n8n y Agentes de IA:** Definición de workflow, nodo, trigger, credencial segura, LLM, chatbot tradicional vs. agente de IA (arquitectura ReAct), memoria conversacional y herramientas (*Tools*).
12. **Consulta Segura de Base de Datos:** Principio de Mínimo Privilegio, prevención de inyecciones de prompt y configuración de un rol restringido exclusivamente a `SELECT`.
13. **Marco Conceptual del Dominio Aduanero:**
    * Conceptos de aduana, declaración aduanera (DUA / póliza) y agente aduanal.
    * Sistema Armonizado (SA / HS), partida arancelaria, arancel y determinación de valor en aduanas (**CIF**: Costo, Seguro y Flete).
    * Regímenes aduaneros: **Importación** (definitiva y temporal), **Exportación** (definitiva y temporal/perfeccionamiento pasivo), **Tránsito Aduanero** y **Depósito Aduanero / Fiscal**.
14. **Apartado "Uso de IA" (Transparencia Ética):** Declaración honesta del uso de Antigravity como asistente de pair programming, lista de prompts reales utilizados, metodología de validación manual de código y reflexiones sobre el aprendizaje obtenido, sin afirmar pruebas no realizadas y marcando campos con `[PERSONALIZAR]`.

---

## 4. Requisitos del Diagrama Entidad-Relación (DER)

### 4.1. Esquema de Entidades Mínimo (6 Tablas)
El modelo debe representar fielmente la operativa aduanera y contener al menos 6 tablas divididas en dos niveles:
* **Tablas Fuertes / Padres (independientes):**
  1. `importador`: Personas jurídicas o naturales autorizadas ante la administración tributaria.
  2. `deposito_aduanero`: Almacenes fiscales o bodegas aduaneras autorizadas para la custodia temporal.
  3. `categoria_arancelaria`: Catálogo oficial de partidas del Sistema Armonizado (SAC / HS) con sus tasas arancelarias.
* **Tablas Hijas / Transaccionales (dependientes):**
  4. `declaracion_aduanera`: Trámite formal del DUA, vinculado con el importador y el depósito aduanero.
  5. `mercancia_inventario`: Registro físico individualizado de bultos o lotes en custodia, vinculado a la declaración y a la partida arancelaria.
  6. `inspeccion_aduanera`: Actuaciones de aforo físico, documental o por escáner realizadas por inspectores fiscales sobre mercancías en inventario.

### 4.2. Especificaciones de Modelado
* Diagrama visual renderizable en formato Mermaid (`erDiagram`).
* Identificación explícita de llaves primarias (`PK`) y foráneas (`FK`).
* Cardinalidades correctas en cada extremo (ej. un importador consigna 0 a muchas declaraciones; una declaración pertenece a exactamente un importador).
* Inclusión de diccionario de datos con la descripción de propósito de cada entidad y columna.
* Explicación de las dependencias lógicas y orden secuencial de creación.

---

## 5. Requisitos del Script SQL (PostgreSQL)

### 5.1. Convenciones y Buenas Prácticas
* Nomenclatura estandarizada en minúsculas con guiones bajos (`snake_case`) para esquemas, tablas, columnas y restricciones.
* Nombres de identificadores sin tildes, espacios ni caracteres especiales.
* Comentarios explicativos en español tanto a nivel de código como en el catálogo de PostgreSQL (`COMMENT ON TABLE`, `COMMENT ON COLUMN`).

### 5.2. Script DDL (`sql/01_creacion_tablas.sql`)
* **Idempotencia:** Bloque inicial de eliminación limpia en orden inverso a las dependencias (`DROP TABLE IF EXISTS ... CASCADE` comenzando por tablas hijas).
* **Orden de creación:** Tablas padre primero (`importador`, `deposito_aduanero`, `categoria_arancelaria`) seguidas de las hijas (`declaracion_aduanera`, `mercancia_inventario`, `inspeccion_aduanera`).
* **Integridad de Entidad y Referencial:**
  - `PRIMARY KEY` en todas las tablas mediante tipos autoincrementales (`SERIAL` o `IDENTITY`).
  - `FOREIGN KEY` con cláusulas explícitas (`ON DELETE RESTRICT` o `NO ACTION` en entidades fiscales críticas).
* **Restricciones de Dominio y Negocio:**
  - `NOT NULL` en todas las columnas indispensables para la fiscalización.
  - `UNIQUE` en claves alternativas: número de identificación fiscal, código de depósito, partida arancelaria, número de DUA, código de bulto y número de acta de aforo.
  - `CHECK` para validar dominios finitos:
    - Tipos de depósito: `'temporal'`, `'fiscal'`, `'franco'`, `'refrigerado'`.
    - Regímenes: `'importacion_definitiva'`, `'deposito_fiscal'`, `'transito_aduanero'`, `'admision_temporal'`.
    - Canales de aforo: `'verde'`, `'amarillo'`, `'rojo'`.
    - Estados de declaración: `'registrada'`, `'en_revision'`, `'autorizada'`, `'rechazada'`, `'liquidada'`.
    - Estados de mercancía: `'en_custodia'`, `'bloqueada_aforo'`, `'con_levante'`, `'despachada'`, `'en_abandono'`.
    - Tipos de aforo y resultados de inspección: `'documental'`, `'fisico'`, `'escaner_rayos_x'` / `'conforme'`, `'no_conforme_ajuste_tributario'`, `'no_conforme_comiso'`, `'pendiente_dictamen'`.
    - Valores positivos: `capacidad_maxima_m3 > 0`, `peso_bruto_kg > 0`, `cantidad_bultos > 0`, `valor_cif_usd >= 0`, `tasa_arancelaria_porcentaje BETWEEN 0 AND 100`.
    - Reglas temporales: `fecha_levante >= fecha_presentacion`, `fecha_salida >= fecha_ingreso`.
    - Formato de correo electrónico: expresión regular válida mediante operador `~*`.
  - `DEFAULT` en columnas de estado y marcas de tiempo (`activo DEFAULT TRUE`, `fecha_registro DEFAULT CURRENT_TIMESTAMP`, `estado_mercancia DEFAULT 'en_custodia'`).

### 5.3. Script DML (`sql/02_insercion_datos.sql`)
* Inserción ordenada de registros ficticios pero técnicamente coherentes con la logística comercial.
* Al menos 3 importadores, 3 depósitos aduaneros, 4 categorías arancelarias, 4 declaraciones aduaneras con diversos canales de aforo, 6 lotes de mercancías y 3 actas de inspección con distintos resultados (conforme, no conforme, comiso).

### 5.4. Script de Seguridad (`sql/03_seguridad_agente_readonly.sql`)
* Creación condicional e idempotente del rol `agente_consulta` con capacidad de inicio de sesión (`WITH LOGIN`).
* Revocación completa y preventiva de privilegios predeterminados en el esquema `public`.
* Concesión exclusiva de `GRANT USAGE ON SCHEMA public` y `GRANT SELECT ON ALL TABLES IN SCHEMA public`.
* Aplicación de `ALTER DEFAULT PRIVILEGES` para proteger futuras tablas.
* Inclusión comentada de casos de prueba que demuestren que `SELECT` tiene éxito, mientras que `INSERT`, `UPDATE`, `DELETE` y `DROP` son rechazados con error de permisos insuficientes.

### 5.5. Script de Verificación Analítica (`sql/04_consultas_verificacion.sql`)
* Consulta 1: Trazabilidad integral conectando las 6 tablas con `INNER JOIN` y `LEFT JOIN`.
* Consulta 2: Reporte filtrado de mercancías retenidas o bloqueadas por aforo físico.
* Consulta 3: Agregación estadística de volumen, bultos y valor CIF total por depósito mediante `GROUP BY`, `SUM` y `COUNT`.
* Consulta 4: Detección de mercancías en abandono o tiempo de permanencia prolongado.

---

## 6. Requisitos del Agente en n8n

### 6.1. Componentes del Flujo (`n8n/workflow_inventario_aduanero.json`)
* Estructura exportada en JSON válida para importar directamente en n8n mediante *Import from File*.
* Integración de los nodos mínimos requeridos:
  1. `When chat message received` (Chat Trigger): Punto de entrada para la conversación del usuario.
  2. `AI Agent`: Nodo central de razonamiento basado en LangChain.
  3. `OpenAI Chat Model` (o nodo LLM compatible): Motor de inferencia y generación de lenguaje natural.
  4. `Window Buffer Memory`: Memoria a corto plazo para sostener el contexto de múltiples turnos.
  5. `Postgres Tool`: Herramienta configurada para ejecutar consultas estructuradas en la base de datos aduanera.

### 6.2. Directrices del System Prompt (`n8n/agente_inventario_aduanero_prompt.md`)
* Identidad del asistente: "AduanaBot", especialista en inventario aduanero y custodia fiscal.
* **Regla de oro de seguridad:** Prohibición absoluta de ejecutar o proponer sentencias DML de modificación o DDL.
* Manejo estricto de solicitudes maliciosas o de actualización: rechazo formal citando la política de solo lectura.
* Inclusión completa del esquema de las 6 tablas (nombres exactos de columnas, tipos y valores permitidos).
* Pautas de estilo: respuestas en español profesional, uso de tablas Markdown para listar bultos y advertencias claras sobre mercancías con aforo rojo o retención.

### 6.3. Guía de Configuración y Pruebas (`n8n/guia_configuracion_n8n.md`)
* Instrucciones paso a paso para importar el workflow.
* Instrucciones para vincular credenciales en los nodos sin exponer claves en el repositorio.
* Especificación de al menos 4 casos de prueba verificables:
  1. Consulta de ubicación de bulto específico por código.
  2. Consulta de mercancías con aforo rojo o inspección pendiente.
  3. Consulta agregada de valor CIF total en dólares por depósito.
  4. Intento de modificación o inyección de prompt (demostrando el rechazo seguro).

---

## 7. Requisitos de Seguridad

1. **Principio de Mínimo Privilegio (PoLP):** El agente de IA jamás debe conectarse con credenciales de superusuario (`postgres`) ni con permisos de escritura. Su alcance debe estar acotado formalmente en el motor a `SELECT`.
2. **Defensa en Profundidad (Defense-in-Depth):** La protección de los datos no depende únicamente del System Prompt del LLM (el cual es vulnerable a *Jailbreaks* o inyecciones indirectas), sino de la barrera infranqueable del sistema de control de acceso de PostgreSQL (`permission denied`).
3. **Gestión Segura de Credenciales:**
   * Ningún archivo del repositorio debe contener contraseñas de producción, llaves de API o tokens privados.
   * El archivo `.gitignore` debe excluir explícitamente archivos `.env`, carpetas de entorno virtual, temporales del sistema y credenciales locales.

---

## 8. Rúbrica de Evaluación con Puntajes

| Criterio / Componente | Puntos Máximos | Criterios de Evaluación |
| :--- | :---: | :--- |
| **1. Documento de Investigación Teórico-Práctico** | **30 pts** | - Cubre exhaustivamente los 14 puntos requeridos (15 pts).<br>- Redacción original en español técnico y ejemplos de aduana sin plagio (5 pts).<br>- Extensión de 3 a 6 páginas con portada, introducción, conclusiones y referencias bibliográficas con URL y fecha (5 pts).<br>- Apartado "Uso de IA" transparente, honesto y con etiquetas `[PERSONALIZAR]` (5 pts). |
| **2. Modelado Conceptual y DER** | **15 pts** | - Cobertura de las 6 entidades (3 padres, 3 hijas) y cardinalidades correctas (5 pts).<br>- Diagrama Mermaid ERD renderizable y sintácticamente válido (5 pts).<br>- Diccionario de datos, reglas de negocio y justificación de relaciones (5 pts). |
| **3. Implementación SQL en PostgreSQL (DDL y DML)** | **25 pts** | - Creación ordenada e idempotente de tablas sin errores de sintaxis (5 pts).<br>- Llaves primarias y foráneas con integridad referencial coherente (5 pts).<br>- Restricciones declarativas completas (`NOT NULL`, `UNIQUE`, `CHECK`, `DEFAULT`, expresiones regulares) (10 pts).<br>- Población con datos ficticios realistas y consultas de verificación analítica (5 pts). |
| **4. Seguridad y Mínimo Privilegio** | **15 pts** | - Rol `agente_consulta` con permisos exclusivos `SELECT` (5 pts).<br>- Revocación de privilegios predeterminados y protección de futuras tablas (5 pts).<br>- Evidencia de bloqueo ante intentos de `INSERT`, `UPDATE`, `DELETE` y `DROP` (5 pts). |
| **5. Automatización y Agente de IA en n8n** | **15 pts** | - Flujo JSON funcional y estructurado con Chat Trigger, AI Agent, LLM, Memoria y Postgres Tool (5 pts).<br>- System Prompt con reglas de seguridad, esquema y directrices de respuesta (5 pts).<br>- Guía de configuración con casos de prueba documentados (5 pts). |
| **TOTAL** | **100 pts** | **Evaluación global del proyecto de laboratorio.** |

---

## 9. Checklist de Verificación de Requisitos

> [!IMPORTANT]
> Esta lista de verificación contiene todos los requisitos exigidos para la entrega. No marques ningún requisito como terminado hasta haber auditado y verificado físicamente su cumplimiento en el repositorio.

### 9.1. Entregables y Estructura del Repositorio
- [ ] Existe la carpeta `docs/` con el DER (`01_modelo_entidad_relacion.md`) y el informe de investigación (`documento_investigacion_inventario_aduanero.md`).
- [ ] Existe la carpeta `sql/` con los 4 scripts (`01_creacion_tablas.sql`, `02_insercion_datos.sql`, `03_seguridad_agente_readonly.sql`, `04_consultas_verificacion.sql`).
- [ ] Existe la carpeta `n8n/` con el workflow (`workflow_inventario_aduanero.json`), el prompt (`agente_inventario_aduanero_prompt.md`) y la guía (`guia_configuracion_n8n.md`).
- [ ] Existe el archivo `.gitignore` protegiendo variables de entorno, claves y temporales.
- [ ] Existe el archivo `README.md` documentando la visión general, arquitectura y fases del proyecto.
- [ ] Existe el archivo `REQUISITOS_LAB3.md` como fuente de verdad.

### 9.2. Documento de Investigación Académico
- [ ] Cumple con la extensión exigida de 3 a 6 páginas (2,000 a 4,500 palabras aprox.).
- [ ] Redactado en español claro, formal y con vocabulario propio sin copias literales.
- [ ] Incluye portada sugerida con campos institucionales señalados con `[PERSONALIZAR]`.
- [ ] Incluye introducción formal al problema de gestión de inventarios en aduanas.
- [ ] Explica Punto 1: Base de datos y SGBD (persistencia, ACID, concurrencia).
- [ ] Explica Punto 2: Diferencias entre RDBMS y NoSQL y justificación de ACID en fiscalización aduanera.
- [ ] Explica Punto 3: Tablas, registros, campos y tipos de datos (`SERIAL`, `VARCHAR`, `TEXT`, `NUMERIC`, `BOOLEAN`, `TIMESTAMPTZ`).
- [ ] Explica Punto 4: Claves primarias (PK), foráneas (FK) y llaves compuestas.
- [ ] Explica Punto 5: Relaciones 1:1, 1:N y N:M y su implementación física en tablas.
- [ ] Explica Punto 6: Integridad referencial (`ON DELETE`/`UPDATE`) y restricciones (`NOT NULL`, `UNIQUE`, `CHECK`, `DEFAULT`).
- [ ] Explica Punto 7: DDL y DML (`CREATE`, `INSERT`, `SELECT`, `UPDATE`, `DELETE`) y composición con `JOIN` (`INNER`, `LEFT`, `RIGHT`, `FULL`).
- [ ] Explica Punto 8: Normalización 1FN, 2FN y 3FN con ejemplos de infracción aduanera y solución.
- [ ] Explica Punto 9: DER y comparativa técnica/visual entre notación de Chen y Pata de Gallo (*Crow's Foot*).
- [ ] Explica Punto 10: Comparativa técnica de SQLite, MySQL y PostgreSQL, justificando la elección de PostgreSQL.
- [ ] Explica Punto 11: Ecosistema n8n (workflows, nodos, triggers, credenciales, chatbot vs. AI Agent, LLM y Tools).
- [ ] Explica Punto 12: Consulta segura de base de datos bajo el principio de mínimo privilegio.
- [ ] Explica Punto 13: Dominio aduanero (Aduana, DUA, Agente aduanal, SA/HS, Partida, Arancel, Valor CIF).
- [ ] Explica Punto 13 (Regímenes): Detalla regímenes de **Importación**, **Exportación**, **Tránsito** y **Depósito Aduanero/Fiscal**.
- [ ] Explica Punto 14 (Uso de IA): Declara el uso de Antigravity como asistente de pair programming de forma honesta.
- [ ] Explica Punto 14 (Prompts): Incluye ejemplos literales de los prompts empleados durante el desarrollo.
- [ ] Explica Punto 14 (Aprendizaje): Detalla los conocimientos adquiridos por el estudiante con opciones `[PERSONALIZAR]`.
- [ ] Incluye sección de Conclusiones estructuradas con hallazgos clave.
- [ ] Incluye Referencias Bibliográficas confiables con autor, título, editorial/fuente, URL completa y fecha de consulta.

### 9.3. Modelo Entidad-Relación (DER)
- [ ] Incluye al menos 6 entidades (3 padres: `importador`, `deposito_aduanero`, `categoria_arancelaria`; 3 hijas: `declaracion_aduanera`, `mercancia_inventario`, `inspeccion_aduanera`).
- [ ] Contiene diagrama en Mermaid sintácticamente correcto y legible.
- [ ] Señala claramente las claves primarias (`PK`) y foráneas (`FK`) en cada entidad.
- [ ] Define cardinalidades apropiadas (1:N) entre todas las entidades relacionadas.
- [ ] Incluye diccionario de datos con descripción funcional de cada tabla y columna.
- [ ] Documenta las reglas de negocio asociadas a cada relación.
- [ ] Establece el orden de creación y precedencia de dependencias para el DDL.

### 9.4. Script SQL DDL y DML
- [ ] Todas las tablas, columnas y restricciones usan nomenclatura `snake_case` sin tildes ni caracteres especiales.
- [ ] Contiene bloque idempotente de eliminación (`DROP TABLE IF EXISTS ... CASCADE`) en orden de hijas a padres.
- [ ] Crea las tablas en orden correcto de dependencias (de padres a hijas) sin producir errores de ejecución.
- [ ] Implementa `PRIMARY KEY` en las 6 entidades del modelo.
- [ ] Implementa `FOREIGN KEY` con restricciones referenciales coherentes.
- [ ] Define `NOT NULL` en todos los campos críticos para la fiscalización.
- [ ] Define restricciones `UNIQUE` para identificadores únicos de negocio.
- [ ] Define restricciones `CHECK` para listas cerradas de valores (tipos de depósito, canales de aforo, regímenes, estados).
- [ ] Define restricciones `CHECK` para magnitudes positivas (`peso_bruto_kg > 0`, `capacidad_maxima_m3 > 0`, `tasa_arancelaria BETWEEN 0 AND 100`).
- [ ] Define restricciones `CHECK` para consistencia cronológica (`fecha_levante >= fecha_presentacion`, `fecha_salida >= fecha_ingreso`).
- [ ] Define restricción `CHECK` con expresión regular para validar el formato de correo de contacto.
- [ ] Asigna valores `DEFAULT` coherentes en estados y marcas temporales.
- [ ] Incluye comentarios formales en PostgreSQL (`COMMENT ON TABLE` y `COMMENT ON COLUMN`).
- [ ] El script `02_insercion_datos.sql` inserta datos de prueba coherentes y suficientes para todas las tablas.
- [ ] El script `04_consultas_verificacion.sql` contiene consultas analíticas con `JOIN`, agrupaciones y reportes de aforo.

### 9.5. Seguridad y Usuario de Solo Lectura
- [ ] El script `03_seguridad_agente_readonly.sql` crea el rol `agente_consulta` con capacidad de login.
- [ ] Revoca todos los privilegios sobre el esquema `public` a `PUBLIC`.
- [ ] Revoca permisos de inserción, actualización, eliminación y alteración de tablas al rol `agente_consulta`.
- [ ] Concede exclusivamente `USAGE` en el esquema `public` y `SELECT` en las tablas del sistema.
- [ ] Configura `ALTER DEFAULT PRIVILEGES` para asegurar futuras tablas creadas en el esquema.
- [ ] No expone contraseñas reales ni credenciales sensibles en el código fuente versionado.
- [ ] Incluye comandos de prueba comentados que validan la ejecución exitosa de `SELECT` y el fallo con *permission denied* de `INSERT`, `UPDATE`, `DELETE` y `DROP`.

### 9.6. Automatización y Agente en n8n
- [ ] El archivo `workflow_inventario_aduanero.json` es válido e importable sin errores de esquema.
- [ ] Integra nodo `When chat message received` (Chat Trigger) interactivo.
- [ ] Integra nodo `AI Agent` con configuración de herramientas.
- [ ] Integra nodo de modelo de lenguaje compatible (`OpenAI Chat Model` o equivalente).
- [ ] Integra nodo de memoria conversacional (`Window Buffer Memory`).
- [ ] Integra nodo de herramienta de base de datos (`Postgres Tool`) vinculado con credenciales de solo lectura.
- [ ] El archivo `agente_inventario_aduanero_prompt.md` contiene el System Message con la prohibición explícita de modificación.
- [ ] El System Prompt documenta el esquema completo de las 6 tablas con sus columnas y descripciones.
- [ ] El archivo `guia_configuracion_n8n.md` explica la configuración de credenciales y los 4 casos de prueba verificables.

---

## 10. Pendientes detectados

*(Esta sección se encuentra inicialmente vacía para registrar observaciones, incidencias o tareas pendientes que surjan durante la ejecución o auditoría del proyecto).*
