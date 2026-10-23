-- ============================================================================
-- LABORATORIO 3: SISTEMA DE INVENTARIO ADUANERO Y CUSTODIA FISCAL
-- ARCHIVO: Apellido_Nombre_Aduana_Lab3.sql
-- GESTOR: PostgreSQL 15 / 16 / 17
-- ============================================================================
-- 1. ENCABEZADO
-- ============================================================================
-- INTEGRANTES: [PERSONALIZAR: TU NOMBRE COMPLETO, EJ. BIANCA ROBLES HURTADO]
-- CARNÉ / ID:  [PERSONALIZAR: TU NÚMERO DE CARNÉ / CÉDULA]
-- CURSO:       Bases de Datos I / II - Laboratorio 3
-- FECHA:       23 de Octubre de 2026
-- PROPÓSITO:
--   Implementar el esquema físico completo, normalizado en 3FN, para el Sistema
--   de Inventario Aduanero en PostgreSQL. El archivo es 100% idempotente, crea
--   las 13 entidades del DER aprobado, inserta un mínimo de 15 registros
--   coherentes por tabla y ejecuta 9 consultas analíticas de negocio complejas.
-- ============================================================================

-- ============================================================================
-- 2. LIMPIEZA SEGURA PARA PERMITIR REEJECUCIÓN IDEMPOTENTE (HIJAS -> PADRES)
-- ============================================================================
DROP TABLE IF EXISTS movimiento_inventario CASCADE;
DROP TABLE IF EXISTS inspeccion CASCADE;
DROP TABLE IF EXISTS inventario_bodega CASCADE;
DROP TABLE IF EXISTS detalle_declaracion CASCADE;
DROP TABLE IF EXISTS declaracion_aduanera CASCADE;
DROP TABLE IF EXISTS bodega CASCADE;
DROP TABLE IF EXISTS contenedor CASCADE;
DROP TABLE IF EXISTS producto CASCADE;
DROP TABLE IF EXISTS partida_arancelaria CASCADE;
DROP TABLE IF EXISTS funcionario CASCADE;
DROP TABLE IF EXISTS agente_aduanal CASCADE;
DROP TABLE IF EXISTS importador_exportador CASCADE;
DROP TABLE IF EXISTS pais CASCADE;

-- ============================================================================
-- 3. CREACIÓN DE TABLAS (DDL: ESTRUCTURA, PK, FK Y RESTRICCIONES)
-- ============================================================================

-- 3.1. Catálogo de Países
CREATE TABLE pais (
    id_pais SERIAL PRIMARY KEY,
    codigo_alfa2 VARCHAR(2) NOT NULL UNIQUE,
    codigo_alfa3 VARCHAR(3) NOT NULL UNIQUE,
    nombre VARCHAR(100) NOT NULL UNIQUE,
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT chk_pais_alfa2 CHECK (LENGTH(codigo_alfa2) = 2),
    CONSTRAINT chk_pais_alfa3 CHECK (LENGTH(codigo_alfa3) = 3)
);

COMMENT ON TABLE pais IS 'Catálogo oficial de países de residencia fiscal, origen y procedencia (ISO 3166-1)';

-- 3.2. Importadores y Exportadores
CREATE TABLE importador_exportador (
    id_operador SERIAL PRIMARY KEY,
    numero_identificacion VARCHAR(25) NOT NULL UNIQUE,
    razon_social VARCHAR(150) NOT NULL,
    tipo_operador VARCHAR(20) NOT NULL,
    id_pais INTEGER NOT NULL,
    correo VARCHAR(100) NOT NULL,
    telefono VARCHAR(25) NOT NULL,
    direccion TEXT NOT NULL,
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_operador_tipo CHECK (tipo_operador IN ('importador', 'exportador', 'ambos')),
    CONSTRAINT chk_operador_correo CHECK (correo ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'),
    CONSTRAINT fk_operador_pais FOREIGN KEY (id_pais) REFERENCES pais(id_pais) ON DELETE RESTRICT
);

COMMENT ON TABLE importador_exportador IS 'Operadores de comercio exterior acreditados ante el ministerio de hacienda y aduanas';

-- 3.3. Agentes Aduanales
CREATE TABLE agente_aduanal (
    id_agente SERIAL PRIMARY KEY,
    codigo_licencia VARCHAR(25) NOT NULL UNIQUE,
    nombre_agencia VARCHAR(120) NOT NULL,
    nombre_agente_responsable VARCHAR(100) NOT NULL,
    correo VARCHAR(100) NOT NULL UNIQUE,
    telefono VARCHAR(25) NOT NULL,
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT chk_agente_correo CHECK (correo ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$')
);

COMMENT ON TABLE agente_aduanal IS 'Auxiliares de la función pública aduanera acreditados para confeccionar declaraciones';

-- 3.4. Funcionarios de Aduana (Con Relación Recursiva de Jerarquía)
CREATE TABLE funcionario (
    id_funcionario SERIAL PRIMARY KEY,
    numero_empleado VARCHAR(20) NOT NULL UNIQUE,
    nombre_completo VARCHAR(120) NOT NULL,
    cargo VARCHAR(80) NOT NULL,
    correo_institucional VARCHAR(100) NOT NULL UNIQUE,
    id_supervisor INTEGER,
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT chk_func_correo CHECK (correo_institucional ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'),
    CONSTRAINT fk_func_supervisor FOREIGN KEY (id_supervisor) REFERENCES funcionario(id_funcionario) ON DELETE SET NULL
);

COMMENT ON TABLE funcionario IS 'Personal oficial de la aduana con relación jerárquica recursiva (supervisor a subordinado)';

-- 3.5. Partidas Arancelarias (Sistema Armonizado / SAC)
CREATE TABLE partida_arancelaria (
    id_partida SERIAL PRIMARY KEY,
    codigo_partida VARCHAR(12) NOT NULL UNIQUE,
    descripcion TEXT NOT NULL,
    tasa_arancel_porcentaje NUMERIC(5,2) NOT NULL,
    tasa_iva_porcentaje NUMERIC(5,2) NOT NULL,
    requiere_permiso BOOLEAN NOT NULL DEFAULT FALSE,
    CONSTRAINT chk_arancel_pct CHECK (tasa_arancel_porcentaje BETWEEN 0.00 AND 100.00),
    CONSTRAINT chk_iva_pct CHECK (tasa_iva_porcentaje BETWEEN 0.00 AND 100.00)
);

COMMENT ON TABLE partida_arancelaria IS 'Clasificación arancelaria y alícuotas tributarias oficiales';

-- 3.6. Catálogo Maestro de Productos
CREATE TABLE producto (
    id_producto SERIAL PRIMARY KEY,
    codigo_sku VARCHAR(30) NOT NULL UNIQUE,
    nombre_comercial VARCHAR(120) NOT NULL,
    descripcion_tecnica TEXT NOT NULL,
    id_partida INTEGER NOT NULL,
    unidad_medida VARCHAR(20) NOT NULL,
    peso_unitario_kg NUMERIC(10,3) NOT NULL,
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT chk_prod_unidad CHECK (unidad_medida IN ('unidades', 'kg', 'litros', 'cajas', 'metros', 'toneladas')),
    CONSTRAINT chk_prod_peso CHECK (peso_unitario_kg > 0),
    CONSTRAINT fk_producto_partida FOREIGN KEY (id_partida) REFERENCES partida_arancelaria(id_partida) ON DELETE RESTRICT
);

COMMENT ON TABLE producto IS 'Catálogo de bienes comerciales con especificaciones técnicas y clasificación arancelaria';

-- 3.7. Contenedores Intermodales
CREATE TABLE contenedor (
    id_contenedor SERIAL PRIMARY KEY,
    numero_contenedor VARCHAR(15) NOT NULL UNIQUE,
    tipo_contenedor VARCHAR(20) NOT NULL,
    tara_kg NUMERIC(8,2) NOT NULL,
    capacidad_maxima_kg NUMERIC(10,2) NOT NULL,
    id_pais_procedencia INTEGER NOT NULL,
    estado_contenedor VARCHAR(25) NOT NULL DEFAULT 'patio_aduanero',
    CONSTRAINT chk_cont_tipo CHECK (tipo_contenedor IN ('dry_20', 'dry_40', 'reefer_40', 'open_top', 'flat_rack')),
    CONSTRAINT chk_cont_tara CHECK (tara_kg > 0),
    CONSTRAINT chk_cont_capacidad CHECK (capacidad_maxima_kg > tara_kg),
    CONSTRAINT chk_cont_estado CHECK (estado_contenedor IN ('en_transito', 'patio_aduanero', 'desconsolidado', 'liberado', 'retornado')),
    CONSTRAINT fk_contenedor_pais FOREIGN KEY (id_pais_procedencia) REFERENCES pais(id_pais) ON DELETE RESTRICT
);

COMMENT ON TABLE contenedor IS 'Unidades de transporte intermodal fiscalizadas con país de procedencia';

-- 3.8. Bodegas y Recintos Fiscales
CREATE TABLE bodega (
    id_bodega SERIAL PRIMARY KEY,
    codigo_bodega VARCHAR(20) NOT NULL UNIQUE,
    nombre VARCHAR(100) NOT NULL,
    tipo_bodega VARCHAR(30) NOT NULL,
    capacidad_m3 NUMERIC(10,2) NOT NULL,
    ubicacion_geografica VARCHAR(120) NOT NULL,
    responsable_bodega VARCHAR(100) NOT NULL,
    activa BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT chk_bodega_tipo CHECK (tipo_bodega IN ('fiscal', 'temporal', 'refrigerada', 'sustancias_peligrosas', 'patio_contenedores')),
    CONSTRAINT chk_bodega_capacidad CHECK (capacidad_m3 > 0)
);

COMMENT ON TABLE bodega IS 'Instalaciones habilitadas para el depósito y custodia temporal de mercancías bajo control aduanero';

-- 3.9. Declaraciones Aduaneras (DUA / Pólizas)
CREATE TABLE declaracion_aduanera (
    id_declaracion SERIAL PRIMARY KEY,
    numero_declaracion VARCHAR(30) NOT NULL UNIQUE,
    id_operador INTEGER NOT NULL,
    id_agente INTEGER NOT NULL,
    id_contenedor INTEGER,
    tipo_regimen VARCHAR(30) NOT NULL,
    canal_aforo VARCHAR(15) NOT NULL DEFAULT 'verde',
    estado_declaracion VARCHAR(25) NOT NULL DEFAULT 'registrada',
    valor_cif_total_usd NUMERIC(14,2) NOT NULL,
    total_tributos_usd NUMERIC(14,2) NOT NULL DEFAULT 0.00,
    fecha_presentacion TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_levante TIMESTAMPTZ,
    CONSTRAINT chk_dec_regimen CHECK (tipo_regimen IN ('importacion_definitiva', 'exportacion_definitiva', 'deposito_fiscal', 'transito_aduanero', 'admision_temporal')),
    CONSTRAINT chk_dec_canal CHECK (canal_aforo IN ('verde', 'amarillo', 'rojo')),
    CONSTRAINT chk_dec_estado CHECK (estado_declaracion IN ('registrada', 'en_aforo', 'con_levante', 'retenida', 'liquidada', 'anulada')),
    CONSTRAINT chk_dec_cif CHECK (valor_cif_total_usd >= 0),
    CONSTRAINT chk_dec_tributos CHECK (total_tributos_usd >= 0),
    CONSTRAINT chk_dec_fechas CHECK (fecha_levante IS NULL OR fecha_levante >= fecha_presentacion),
    CONSTRAINT fk_dec_operador FOREIGN KEY (id_operador) REFERENCES importador_exportador(id_operador) ON DELETE RESTRICT,
    CONSTRAINT fk_dec_agente FOREIGN KEY (id_agente) REFERENCES agente_aduanal(id_agente) ON DELETE RESTRICT,
    CONSTRAINT fk_dec_contenedor FOREIGN KEY (id_contenedor) REFERENCES contenedor(id_contenedor) ON DELETE SET NULL
);

COMMENT ON TABLE declaracion_aduanera IS 'Documento oficial aduanero (DUA) que formaliza la destinación aduanera y el aforo';

-- 3.10. Detalle de Declaración (Resolución N:M entre Declaración y Producto)
CREATE TABLE detalle_declaracion (
    id_detalle SERIAL PRIMARY KEY,
    id_declaracion INTEGER NOT NULL,
    numero_linea INTEGER NOT NULL,
    id_producto INTEGER NOT NULL,
    cantidad NUMERIC(12,2) NOT NULL,
    precio_unitario_usd NUMERIC(12,2) NOT NULL,
    valor_cif_linea_usd NUMERIC(14,2) NOT NULL,
    monto_arancel_usd NUMERIC(14,2) NOT NULL DEFAULT 0.00,
    estado_linea VARCHAR(20) NOT NULL DEFAULT 'aprobada',
    CONSTRAINT unq_dec_linea UNIQUE (id_declaracion, numero_linea),
    CONSTRAINT chk_det_linea CHECK (numero_linea > 0),
    CONSTRAINT chk_det_cantidad CHECK (cantidad > 0),
    CONSTRAINT chk_det_precio CHECK (precio_unitario_usd > 0),
    CONSTRAINT chk_det_cif CHECK (valor_cif_linea_usd > 0),
    CONSTRAINT chk_det_arancel CHECK (monto_arancel_usd >= 0),
    CONSTRAINT chk_det_estado CHECK (estado_linea IN ('aprobada', 'retenida_aforo', 'rechazada')),
    CONSTRAINT fk_det_declaracion FOREIGN KEY (id_declaracion) REFERENCES declaracion_aduanera(id_declaracion) ON DELETE CASCADE,
    CONSTRAINT fk_det_producto FOREIGN KEY (id_producto) REFERENCES producto(id_producto) ON DELETE RESTRICT
);

COMMENT ON TABLE detalle_declaracion IS 'Líneas de partidas de la DUA resolviendo la relación N:M con producto (3FN)';

-- 3.11. Inventario en Bodega (Normalizado en 3FN estricta vía detalle_declaracion)
CREATE TABLE inventario_bodega (
    id_inventario SERIAL PRIMARY KEY,
    id_bodega INTEGER NOT NULL,
    id_detalle INTEGER NOT NULL,
    ubicacion_especifica VARCHAR(50) NOT NULL,
    cantidad_disponible NUMERIC(12,2) NOT NULL DEFAULT 0.00,
    cantidad_retenida NUMERIC(12,2) NOT NULL DEFAULT 0.00,
    estado_fiscal VARCHAR(25) NOT NULL DEFAULT 'en_custodia',
    fecha_ingreso TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_ultimo_movimiento TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT unq_inv_posicion UNIQUE (id_bodega, id_detalle, ubicacion_especifica),
    CONSTRAINT chk_inv_disponible CHECK (cantidad_disponible >= 0),
    CONSTRAINT chk_inv_retenida CHECK (cantidad_retenida >= 0),
    CONSTRAINT chk_inv_positivo CHECK (cantidad_disponible + cantidad_retenida > 0),
    CONSTRAINT chk_inv_estado CHECK (estado_fiscal IN ('en_custodia', 'retenido_fiscal', 'autorizado_despacho', 'despachado', 'abandono_legal')),
    CONSTRAINT fk_inv_bodega FOREIGN KEY (id_bodega) REFERENCES bodega(id_bodega) ON DELETE RESTRICT,
    CONSTRAINT fk_inv_detalle FOREIGN KEY (id_detalle) REFERENCES detalle_declaracion(id_detalle) ON DELETE RESTRICT
);

COMMENT ON TABLE inventario_bodega IS 'Control físico de inventario en bodega diferenciando saldo libre y retenido (3FN)';

-- 3.12. Movimientos de Inventario (Bitácora Inmutable)
CREATE TABLE movimiento_inventario (
    id_movimiento SERIAL PRIMARY KEY,
    id_inventario INTEGER NOT NULL,
    tipo_movimiento VARCHAR(25) NOT NULL,
    cantidad NUMERIC(12,2) NOT NULL,
    id_funcionario INTEGER NOT NULL,
    motivo_observacion TEXT NOT NULL,
    fecha_movimiento TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_mov_tipo CHECK (tipo_movimiento IN ('ingreso_inicial', 'bloqueo_aforo', 'desbloqueo_levante', 'traslado_interno', 'despacho_final', 'ajuste_inventario')),
    CONSTRAINT chk_mov_cantidad CHECK (cantidad > 0),
    CONSTRAINT fk_mov_inventario FOREIGN KEY (id_inventario) REFERENCES inventario_bodega(id_inventario) ON DELETE CASCADE,
    CONSTRAINT fk_mov_funcionario FOREIGN KEY (id_funcionario) REFERENCES funcionario(id_funcionario) ON DELETE RESTRICT
);

COMMENT ON TABLE movimiento_inventario IS 'Bitácora transaccional inmutable para trazabilidad y auditoría de inventario aduanero';

-- 3.13. Inspecciones y Aforos Aduaneros
CREATE TABLE inspeccion (
    id_inspeccion SERIAL PRIMARY KEY,
    numero_acta VARCHAR(30) NOT NULL UNIQUE,
    id_declaracion INTEGER NOT NULL,
    id_detalle INTEGER,
    id_funcionario_aforador INTEGER NOT NULL,
    tipo_inspeccion VARCHAR(25) NOT NULL,
    resultado VARCHAR(30) NOT NULL,
    observaciones TEXT NOT NULL,
    fecha_inspeccion TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_insp_tipo CHECK (tipo_inspeccion IN ('documental', 'fisica_aforo', 'no_intrusiva_escaner')),
    CONSTRAINT chk_insp_resultado CHECK (resultado IN ('conforme', 'no_conforme_ajuste', 'no_conforme_comiso', 'dictamen_pendiente')),
    CONSTRAINT fk_insp_declaracion FOREIGN KEY (id_declaracion) REFERENCES declaracion_aduanera(id_declaracion) ON DELETE CASCADE,
    CONSTRAINT fk_insp_detalle FOREIGN KEY (id_detalle) REFERENCES detalle_declaracion(id_detalle) ON DELETE SET NULL,
    CONSTRAINT fk_insp_funcionario FOREIGN KEY (id_funcionario_aforador) REFERENCES funcionario(id_funcionario) ON DELETE RESTRICT
);

COMMENT ON TABLE inspeccion IS 'Actas de aforo documental, físico o escáner realizadas por funcionarios aduaneros';


-- ============================================================================
-- 4. POBLACIÓN DE DATOS (DML: MÍNIMO 15 REGISTROS COHERENTES POR TABLA)
-- ============================================================================

-- 4.1. Inserción en 'pais' (15 registros)
INSERT INTO pais (codigo_alfa2, codigo_alfa3, nombre, activo) VALUES
('CR', 'CRI', 'Costa Rica', true),
('US', 'USA', 'Estados Unidos', true),
('CN', 'CHN', 'China', true),
('DE', 'DEU', 'Alemania', true),
('MX', 'MEX', 'México', true),
('PA', 'PAN', 'Panamá', true),
('CO', 'COL', 'Colombia', true),
('JP', 'JPN', 'Japón', true),
('BR', 'BRA', 'Brasil', true),
('ES', 'ESP', 'España', true),
('KR', 'KOR', 'Corea del Sur', true),
('NL', 'NLD', 'Países Bajos', true),
('CL', 'CHL', 'Chile', true),
('GT', 'GTM', 'Guatemala', true),
('VN', 'VNM', 'Vietnam', true);

-- 4.2. Inserción en 'importador_exportador' (15 registros)
INSERT INTO importador_exportador (numero_identificacion, razon_social, tipo_operador, id_pais, correo, telefono, direccion, activo, fecha_registro) VALUES
('3101001234', 'Corporación Logística Global S.A.', 'ambos', 1, 'aduanas@clg.co.cr', '+506 2200-1001', 'San José, La Uruca, Complejo Industrial 4', true, '2025-01-15 08:30:00-06'),
('3101005678', 'Importadora Tecnológica del Valle S.A.', 'importador', 1, 'compras@itvcr.com', '+506 2222-4500', 'Heredia, Zona Franca Metropolitana', true, '2025-02-10 09:15:00-06'),
('3101009012', 'Alimentos y Granos del Pacífico S.A.', 'importador', 1, 'operaciones@aligranos.com', '+506 2661-3030', 'Puntarenas, Esparza, Carretera a Caldera', true, '2025-03-01 10:00:00-06'),
('3101003456', 'Distribuidora Farmacéutica Central S.A.', 'ambos', 1, 'regulatorio@farma-central.com', '+506 2290-8800', 'San José, Pavas, Frente a Embajada Americana', true, '2025-03-20 11:20:00-06'),
('3101007890', 'Textiles y Modas de Centroamérica S.A.', 'importador', 1, 'import@textilesmoda.cr', '+506 2440-1290', 'Alajuela, Parque Industrial El Coyol', true, '2025-04-05 13:45:00-06'),
('US-EIN-99211', 'Miami Freight & Trading LLC', 'exportador', 2, 'dispatch@miamifreight.us', '+1 305-555-0199', '1200 NW 78th Ave, Doral, FL 33126', true, '2025-04-18 14:00:00-06'),
('CN-TAX-88123', 'Shenzhen Precision Electronics Co.', 'exportador', 3, 'global@szprecision.cn', '+86 755-8899-0011', 'Baoan District, Shenzhen, Guangdong', true, '2025-05-02 16:30:00-06'),
('DE-HRB-77441', 'Bavaria Maschinenbau GmbH', 'exportador', 4, 'export@bavaria-maschinen.de', '+49 89-3210-440', 'Industriestrasse 12, München, Bayern', true, '2025-05-15 08:00:00-06'),
('MX-RFC-55442', 'Agropecuaria Mexicana del Norte S.A.', 'exportador', 5, 'ventas@agronorte.com.mx', '+52 55-5678-9000', 'Av. Insurgentes Sur 1400, CDMX', true, '2025-06-01 10:10:00-06'),
('PA-RUC-11223', 'Colón Free Zone Re-Exporting Corp.', 'ambos', 6, 'trade@colon-reexport.pa', '+507 441-2030', 'Zona Libre de Colón, Manzana 15, Galera 3', true, '2025-06-12 12:00:00-06'),
('CO-NIT-90033', 'Cafés y Cacaos Colombianos S.A.S.', 'exportador', 7, 'comercio@cafescacao.co', '+57 1-600-4550', 'Calle 26 # 68-35, Bogotá', true, '2025-06-25 15:30:00-06'),
('JP-COR-00192', 'Yokohama Automotive Spares Inc.', 'exportador', 8, 'overseas@yokohama-spares.jp', '+81 45-222-3344', 'Naka Ward, Yokohama, Kanagawa', true, '2025-07-08 09:40:00-06'),
('BR-CNPJ-1290', 'Santos Soluçoes Químicas Ltda.', 'exportador', 9, 'exportacao@santosquimica.br', '+55 13-3200-1122', 'Porto de Santos, São Paulo', true, '2025-07-20 11:50:00-06'),
('ES-CIF-44556', 'Iberia Vinos & Aceites Gourmet S.L.', 'exportador', 10, 'pedidos@iberiagourmet.es', '+34 91-456-7890', 'Paseo de la Castellana 80, Madrid', true, '2025-08-01 14:15:00-06'),
('3101009988', 'Agroexportadora del Trópico Verde S.A.', 'exportador', 1, 'logistica@tropicoverde.cr', '+506 2710-4400', 'Limón, Guápiles, Ruta 32 km 55', true, '2025-08-15 16:00:00-06');

-- 4.3. Inserción en 'agente_aduanal' (15 registros)
INSERT INTO agente_aduanal (codigo_licencia, nombre_agencia, nombre_agente_responsable, correo, telefono, activo) VALUES
('LIC-ADU-001', 'Agencia de Aduanas Intermodal S.A.', 'Carlos Solís Brenes', 'csolis@aduanas-intermodal.cr', '+506 2258-0011', true),
('LIC-ADU-002', 'Aduanas y Logística del Caribe S.A.', 'Marta Fonseca Chaves', 'mfonseca@aducaribe.com', '+506 2798-2233', true),
('LIC-ADU-003', 'Despachos Aduaneros del Pacífico S.A.', 'Jorge Ramírez Arroyo', 'jramirez@despachospacifico.cr', '+506 2663-9988', true),
('LIC-ADU-004', 'Trans-Aduanas Aeropuerto S.A.', 'Lucía Valverde Rojas', 'lvalverde@transaduanas.co.cr', '+506 2441-5544', true),
('LIC-ADU-005', 'Operaciones Aduanales Frontera Norte S.A.', 'Roberto Campos Guillén', 'rcampos@frontera-norte.cr', '+506 2470-1122', true),
('LIC-ADU-006', 'Aduanera Integral Metropolitana S.A.', 'Silvia Vega Morales', 'svega@aduanera-metropol.com', '+506 2234-7788', true),
('LIC-ADU-007', 'Panam Customs & Logistics S.A.', 'Andrés Mora Cordero', 'amora@panamcustoms.cr', '+506 2289-4455', true),
('LIC-ADU-008', 'Servicios Aduaneros Moín S.A.', 'Elena Castillo Alvarado', 'ecastillo@aduanasmoin.cr', '+506 2758-6677', true),
('LIC-ADU-009', 'Global Customs Brokers CR S.A.', 'Fernando Navarro Soto', 'fnavarro@globalcustoms.cr', '+506 2260-1234', true),
('LIC-ADU-010', 'Trámites Fiscales San José S.A.', 'Patricia Jiménez Ruiz', 'pjimenez@tramitesfiscales.cr', '+506 2221-9080', true),
('LIC-ADU-011', 'Comercio & Aduana del Sur S.A.', 'Manuel Barquero Umaña', 'mbarquero@aduanasdelsur.cr', '+506 2771-3322', true),
('LIC-ADU-012', 'Alianza Aduanera Centroamericana S.A.', 'Gabriela Cordero Marín', 'gcordero@alianzaaduanera.com', '+506 2433-8877', true),
('LIC-ADU-013', 'QuickCustoms Express S.A.', 'David Salazar Méndez', 'dsalazar@quickcustoms.cr', '+506 2293-6611', true),
('LIC-ADU-014', 'Consorcio Aduanal Caldera S.A.', 'Raquel Porras Villalobos', 'rporras@aduanacaldera.com', '+506 2634-1100', true),
('LIC-ADU-015', 'Soluciones de Despacho Aduanero S.A.', 'Esteban Montero Segura', 'emontero@solucionesaduaneras.cr', '+506 2244-9900', true);

-- 4.4. Inserción en 'funcionario' (15 registros con jerarquía recursiva)
-- Nivel 1: Director General (sin supervisor)
INSERT INTO funcionario (id_funcionario, numero_empleado, nombre_completo, cargo, correo_institucional, id_supervisor, activo) VALUES
(1, 'EMP-DGA-001', 'Lic. Guillermo Arias Valverde', 'Director General de Aduanas', 'guillermo.arias@hacienda.go.cr', NULL, true);

-- Nivel 2: Supervisores y Jefes de Aforo (supervisados por id 1)
INSERT INTO funcionario (id_funcionario, numero_empleado, nombre_completo, cargo, correo_institucional, id_supervisor, activo) VALUES
(2, 'EMP-DGA-002', 'Ing. Sandra Cordero Vargas', 'Jefa de División de Fiscalización y Riesgo', 'sandra.cordero@hacienda.go.cr', 1, true),
(3, 'EMP-DGA-003', 'Lic. Rodrigo Pacheco Monge', 'Administrador de Aduana Santamaría', 'rodrigo.pacheco@hacienda.go.cr', 1, true),
(4, 'EMP-DGA-004', 'Lic. Marcela Quirós Benavides', 'Administradora de Aduana Puerto Moín', 'marcela.quiros@hacienda.go.cr', 1, true);

-- Nivel 3: Aforadores e Inspectores (supervisados por jefes 2, 3 y 4)
INSERT INTO funcionario (id_funcionario, numero_empleado, nombre_completo, cargo, correo_institucional, id_supervisor, activo) VALUES
(5, 'EMP-DGA-005', 'Lic. Randall Mora Solano', 'Inspector Aforador Técnico', 'randall.mora@hacienda.go.cr', 2, true),
(6, 'EMP-DGA-006', 'Licda. Karen Brenes Ortiz', 'Inspectora Aforadora de Carga', 'karen.brenes@hacienda.go.cr', 2, true),
(7, 'EMP-DGA-007', 'Ing. Walter Chinchilla Fallas', 'Aforador Especialista Químico', 'walter.chinchilla@hacienda.go.cr', 2, true),
(8, 'EMP-DGA-008', 'Lic. Oscar Zúñiga Céspedes', 'Aforador de Depósitos Fiscales', 'oscar.zuniga@hacienda.go.cr', 3, true),
(9, 'EMP-DGA-009', 'Licda. Natalia Soto Calderón', 'Inspectora Aérea y Courier', 'natalia.soto@hacienda.go.cr', 3, true),
(10, 'EMP-DGA-010', 'Ing. Luis Diego Alpízar Umaña', 'Inspector de Terminal de Carga', 'luis.alpizar@hacienda.go.cr', 3, true),
(11, 'EMP-DGA-011', 'Lic. Esteban Carvajal Méndez', 'Aforador Portuario de Moín', 'esteban.carvajal@hacienda.go.cr', 4, true),
(12, 'EMP-DGA-012', 'Licda. Mónica Gamboa Rojas', 'Inspectora de Escáner y Rayos X', 'monica.gamboa@hacienda.go.cr', 4, true),
(13, 'EMP-DGA-013', 'Ing. Felipe Venegas Castro', 'Aforador Técnico de Maquinaria', 'felipe.venegas@hacienda.go.cr', 4, true),
(14, 'EMP-DGA-014', 'Licda. Andrea Picado Hidalgo', 'Inspectora de Aforo Físico', 'andrea.picado@hacienda.go.cr', 3, true),
(15, 'EMP-DGA-015', 'Lic. Víctor Hugo Masís Leitón', 'Auditor de Valoración Aduanera', 'victor.masis@hacienda.go.cr', 2, true);

SELECT setval('funcionario_id_funcionario_seq', 15);

-- 4.5. Inserción en 'partida_arancelaria' (15 registros)
INSERT INTO partida_arancelaria (codigo_partida, descripcion, tasa_arancel_porcentaje, tasa_iva_porcentaje, requiere_permiso) VALUES
('8471.30.00.00', 'Máquinas automáticas para tratamiento o procesamiento de datos, portátiles (Laptops y tablets)', 0.00, 13.00, false),
('8517.13.00.00', 'Teléfonos inteligentes (Smartphones) y teléfonos para redes celulares', 0.00, 13.00, true),
('8471.70.00.00', 'Unidades de memoria y almacenamiento de datos (Discos duros SSD, memorias flash)', 0.00, 13.00, false),
('3004.90.00.00', 'Medicamentos dosificados para uso humano (antibióticos y analgésicos)', 0.00, 2.00, true),
('1006.30.00.00', 'Arroz semiblanqueado o blanqueado, incluso pulido o glaseado', 35.00, 1.00, true),
('8703.23.00.00', 'Vehículos automóviles de turismo con motor de émbolo > 1500 cc pero <= 3000 cc', 30.00, 13.00, true),
('6109.10.00.00', 'T-shirts, camisetas de punto de algodón para hombre o mujer', 14.00, 13.00, false),
('6403.99.00.00', 'Calzado con suela de caucho, plástico o cuero natural', 15.00, 13.00, false),
('0901.21.00.00', 'Café tostado, sin descafeinar, en grano o molido', 15.00, 1.00, true),
('8429.51.00.00', 'Cargadoras y palas cargadoras de carga frontal autopropulsadas (Maquinaria pesada)', 5.00, 13.00, false),
('2204.21.00.00', 'Vino de uvas frescas en recipientes con capacidad <= 2 litros', 15.00, 13.00, true),
('3808.91.00.00', 'Insecticidas y productos fitosanitarios para la agricultura', 5.00, 13.00, true),
('8528.52.00.00', 'Monitores capaces de conectarse directamente a máquinas automáticas de procesamiento', 5.00, 13.00, false),
('9018.90.00.00', 'Instrumentos y aparatos de medicina, cirugía, odontología o veterinaria', 0.00, 2.00, true),
('2008.20.00.00', 'Piñas preparadas o conservadas, enlatadas o en pulpa', 15.00, 13.00, false);

-- 4.6. Inserción en 'producto' (15 registros)
INSERT INTO producto (codigo_sku, nombre_comercial, descripcion_tecnica, id_partida, unidad_medida, peso_unitario_kg, activo) VALUES
('SKU-LAP-001', 'Laptop Lenovo ThinkPad T14 Gen 4', 'Procesador Intel i7 13va Gen, 32GB RAM DDR5, SSD 1TB NVMe, Pantalla 14 FHD', 1, 'unidades', 1.450, true),
('SKU-LAP-002', 'Apple MacBook Air 13 M2', 'Chip Apple M2 8-core CPU, 16GB memoria unificada, 512GB SSD, Space Gray', 1, 'unidades', 1.240, true),
('SKU-PHO-001', 'Samsung Galaxy S24 Ultra 5G', 'Smartphone 256GB Titanium Gray, Pantalla AMOLED 6.8 120Hz, Cámara 200MP', 2, 'unidades', 0.232, true),
('SKU-PHO-002', 'Apple iPhone 15 Pro Max', 'Capacidad 256GB Titanio Natural, Pantalla Super Retina XDR 6.7, USB-C', 2, 'unidades', 0.221, true),
('SKU-SSD-001', 'Kingston SSD NV2 1TB PCIe 4.0', 'Unidad de estado sólido M.2 2280 NVMe, Lectura hasta 3500MB/s', 3, 'unidades', 0.007, true),
('SKU-MED-001', 'Amoxicilina + Ácido Clavulánico 875mg', 'Caja x 20 comprimidos recubiertos, laboratorio farmacéutico certificado GMP', 4, 'cajas', 0.065, true),
('SKU-GRA-001', 'Arroz Blanco Grano Entero 99% Puro', 'Saco de 50 kg de arroz grado de calidad 99/1 importado de grano largo', 5, 'cajas', 50.000, true),
('SKU-VEH-001', 'Toyota RAV4 2.5L Gasolina 4x4', 'Vehículo SUV 5 puertas año 2026, transmisión automática, 203 HP', 6, 'unidades', 1650.000, true),
('SKU-TEX-001', 'Camisetas Polo 100% Algodón Pima', 'Pack industrial de 100 camisetas talla surtida, gramaje 200 g/m2', 7, 'cajas', 22.500, true),
('SKU-CAL-001', 'Zapatos de Seguridad Industrial Punta Acero', 'Calzado ergonómico con plantilla antiperforación y suela antideslizante', 8, 'cajas', 1.350, true),
('SKU-CAF-001', 'Café Gourmet Tarrazú Tostado en Grano', 'Bolsa de 1 kg con válvula desgasificadora, tueste medio origen certificado', 9, 'kg', 1.050, true),
('SKU-MAQ-001', 'Minicargador Frontal Caterpillar 226D3', 'Motor diesel Cat C2.2 turbo 67 hp, capacidad de carga operativa 705 kg', 10, 'unidades', 2650.000, true),
('SKU-VIN-001', 'Vino Tinto Rioja Reserva Tempranillo', 'Caja de 6 botellas de 750 ml, crianza de 36 meses en roble francés', 11, 'cajas', 8.200, true),
('SKU-MON-001', 'Monitor Dell UltraSharp 27 4K USB-C', 'Panel IPS UHD 3840x2160, 99% sRGB, Hub USB-C con Power Delivery 90W', 13, 'unidades', 6.800, true),
('SKU-MED-002', 'Monitor de Signos Vitales Portátil Multiparámetro', 'Equipo hospitalario con módulo ECG, SpO2, NIBP, pantalla LCD 12.1 pulgadas', 14, 'unidades', 4.500, true);

-- 4.7. Inserción en 'contenedor' (15 registros)
INSERT INTO contenedor (numero_contenedor, tipo_contenedor, tara_kg, capacidad_maxima_kg, id_pais_procedencia, estado_contenedor) VALUES
('MSCU1029384', 'dry_40', 3750.00, 30480.00, 3, 'desconsolidado'),
('MSCU5544332', 'dry_40', 3800.00, 30480.00, 3, 'patio_aduanero'),
('MAEU7711223', 'dry_40', 3720.00, 30480.00, 2, 'desconsolidado'),
('MAEU9988776', 'dry_20', 2250.00, 24000.00, 2, 'patio_aduanero'),
('CMAU4455667', 'reefer_40', 4400.00, 29500.00, 10, 'patio_aduanero'),
('HLCU1122334', 'flat_rack', 5200.00, 40000.00, 4, 'desconsolidado'),
('ONEU8833221', 'dry_40', 3700.00, 30480.00, 8, 'desconsolidado'),
('COSU3344556', 'dry_40', 3820.00, 30480.00, 3, 'patio_aduanero'),
('EGLV9944112', 'dry_20', 2200.00, 24000.00, 6, 'liberado'),
('SEGU5566778', 'dry_40', 3740.00, 30480.00, 5, 'desconsolidado'),
('TCKU1234567', 'dry_40', 3790.00, 30480.00, 7, 'patio_aduanero'),
('ZIMU9876543', 'dry_20', 2280.00, 24000.00, 2, 'liberado'),
('MSCU9900112', 'reefer_40', 4450.00, 29500.00, 9, 'patio_aduanero'),
('CMAU8811229', 'open_top', 3900.00, 30000.00, 4, 'en_transito'),
('MAEU3344118', 'dry_40', 3760.00, 30480.00, 2, 'patio_aduanero');

-- 4.8. Inserción en 'bodega' (15 registros)
INSERT INTO bodega (codigo_bodega, nombre, tipo_bodega, capacidad_m3, ubicacion_geografica, responsable_bodega, activa) VALUES
('BOD-SJO-01', 'Almacén Fiscal La Uruca Central', 'fiscal', 12500.00, 'San José, La Uruca', 'Lic. Esteban Mora Vega', true),
('BOD-MOI-01', 'Terminal de Almacenamiento Portuario Moín', 'fiscal', 45000.00, 'Limón, Puerto Moín', 'Ing. Carlos Barboza Ruiz', true),
('BOD-CAL-01', 'Depósito Aduanero Puerto Caldera', 'fiscal', 30000.00, 'Puntarenas, Puerto Caldera', 'Lic. Andrés Gamboa Castro', true),
('BOD-AER-01', 'Terminal de Carga Aérea Juan Santamaría', 'temporal', 8500.00, 'Alajuela, Aeropuerto SJO', 'Licda. Laura Villalobos Soto', true),
('BOD-COY-01', 'Almacén Fiscal Coyol Logística', 'fiscal', 22000.00, 'Alajuela, El Coyol', 'Ing. Roberto Méndez Cruz', true),
('BOD-REF-01', 'Cámara Fría Aduanera Santamaría', 'refrigerada', 3200.00, 'Alajuela, Aeropuerto SJO', 'Lic. Diego Navarro Umaña', true),
('BOD-REF-02', 'Frigorífico Portuario Moín', 'refrigerada', 7800.00, 'Limón, Moín', 'Licda. Karen Solano Quirós', true),
('BOD-PAT-01', 'Patio de Contenedores Moín Terminal', 'patio_contenedores', 60000.00, 'Limón, Moín', 'Cap. Mario Brenes Arce', true),
('BOD-PAT-02', 'Patio Intermodal Caldera Pacífico', 'patio_contenedores', 40000.00, 'Puntarenas, Caldera', 'Ing. Alonso Porras Chaves', true),
('BOD-PEÑ-01', 'Recinto Fiscal Frontera Peñas Blancas', 'fiscal', 6500.00, 'Guanacaste, Frontera Norte', 'Lic. Mauricio Salas Gómez', true),
('BOD-CAN-01', 'Depósito Aduanero Frontera Paso Canoas', 'fiscal', 5800.00, 'Puntarenas, Frontera Sur', 'Licda. Silvia Vega Ramos', true),
('BOD-HER-01', 'Bodega Aduanera Metropolitana Heredia', 'fiscal', 15000.00, 'Heredia, San Joaquín', 'Lic. Javier Monge Alpízar', true),
('BOD-PEL-01', 'Depósito Especial de Sustancias Peligrosas', 'sustancias_peligrosas', 2500.00, 'Alajuela, El Coyol', 'Ing. Químico Fabio Castro', true),
('BOD-CART-01', 'Almacén Fiscal del Valle Central Cartago', 'fiscal', 9200.00, 'Cartago, Parque Industrial', 'Licda. Rocío Guzmán Leitón', true),
('BOD-LIB-01', 'Terminal de Carga Daniel Oduber Quirós', 'temporal', 4100.00, 'Guanacaste, Aeropuerto LIR', 'Lic. Nelson Cordero Vargas', true);

-- 4.9. Inserción en 'declaracion_aduanera' (15 registros, incluyendo fechas en Octubre 2026)
INSERT INTO declaracion_aduanera (id_declaracion, numero_declaracion, id_operador, id_agente, id_contenedor, tipo_regimen, canal_aforo, estado_declaracion, valor_cif_total_usd, total_tributos_usd, fecha_presentacion, fecha_levante) VALUES
(1, 'DUA-2026-OCT-001', 2, 1, 1, 'importacion_definitiva', 'verde', 'con_levante', 43500.00, 5655.00, '2026-10-02 09:30:00-06', '2026-10-03 14:00:00-06'),
(2, 'DUA-2026-OCT-002', 1, 2, 3, 'importacion_definitiva', 'rojo', 'en_aforo', 125000.00, 16250.00, '2026-10-05 10:15:00-06', NULL),
(3, 'DUA-2026-OCT-003', 3, 3, 4, 'importacion_definitiva', 'amarillo', 'con_levante', 38000.00, 13680.00, '2026-10-08 11:00:00-06', '2026-10-10 16:30:00-06'),
(4, 'DUA-2026-OCT-004', 4, 4, NULL, 'importacion_definitiva', 'rojo', 'retenida', 75000.00, 1500.00, '2026-10-12 14:20:00-06', NULL),
(5, 'DUA-2026-OCT-005', 1, 1, 7, 'importacion_definitiva', 'verde', 'con_levante', 68000.00, 8840.00, '2026-10-15 08:45:00-06', '2026-10-16 11:10:00-06'),
(6, 'DUA-2026-OCT-006', 5, 5, 2, 'deposito_fiscal', 'verde', 'registrada', 54000.00, 0.00, '2026-10-18 13:00:00-06', NULL),
(7, 'DUA-2026-OCT-007', 2, 6, 8, 'importacion_definitiva', 'rojo', 'en_aforo', 98000.00, 12740.00, '2026-10-20 15:30:00-06', NULL),
(8, 'DUA-2026-OCT-008', 15, 8, NULL, 'exportacion_definitiva', 'verde', 'liquidada', 48500.00, 0.00, '2026-10-21 09:00:00-06', '2026-10-21 16:00:00-06'),
(9, 'DUA-2026-OCT-009', 1, 9, 6, 'admision_temporal', 'amarillo', 'con_levante', 115000.00, 0.00, '2026-10-22 10:40:00-06', '2026-10-23 10:00:00-06'),
(10, 'DUA-2026-OCT-010', 4, 10, 5, 'importacion_definitiva', 'verde', 'con_levante', 32000.00, 640.00, '2026-10-23 08:30:00-06', '2026-10-23 13:15:00-06'),
(11, 'DUA-2026-SEP-001', 1, 1, 10, 'importacion_definitiva', 'verde', 'liquidada', 89000.00, 11570.00, '2026-09-10 10:00:00-06', '2026-09-12 15:00:00-06'),
(12, 'DUA-2026-SEP-002', 2, 2, 11, 'deposito_fiscal', 'amarillo', 'con_levante', 62000.00, 0.00, '2026-09-15 14:00:00-06', '2026-09-16 11:00:00-06'),
(13, 'DUA-2026-SEP-003', 3, 3, 12, 'transito_aduanero', 'verde', 'liquidada', 41000.00, 0.00, '2026-09-22 09:30:00-06', '2026-09-23 16:30:00-06'),
(14, 'DUA-2026-AGO-001', 1, 14, 13, 'importacion_definitiva', 'rojo', 'liquidada', 150000.00, 19500.00, '2026-08-05 11:20:00-06', '2026-08-10 14:00:00-06'),
(15, 'DUA-2026-AGO-002', 5, 15, 15, 'importacion_definitiva', 'verde', 'liquidada', 29000.00, 7830.00, '2026-08-18 08:15:00-06', '2026-08-19 12:45:00-06');

SELECT setval('declaracion_aduanera_id_declaracion_seq', 15);

-- 4.10. Inserción en 'detalle_declaracion' (20 registros resolviendo N:M)
INSERT INTO detalle_declaracion (id_detalle, id_declaracion, numero_linea, id_producto, cantidad, precio_unitario_usd, valor_cif_linea_usd, monto_arancel_usd, estado_linea) VALUES
(1, 1, 1, 1, 30.00, 1450.00, 43500.00, 0.00, 'aprobada'),
(2, 2, 1, 3, 80.00, 1100.00, 88000.00, 0.00, 'retenida_aforo'),
(3, 2, 2, 4, 30.00, 1233.33, 37000.00, 0.00, 'retenida_aforo'),
(4, 3, 1, 7, 800.00, 47.50, 38000.00, 13300.00, 'aprobada'),
(5, 4, 1, 6, 2500.00, 30.00, 75000.00, 0.00, 'retenida_aforo'),
(6, 5, 1, 5, 2000.00, 34.00, 68000.00, 0.00, 'aprobada'),
(7, 6, 1, 9, 600.00, 90.00, 54000.00, 7560.00, 'aprobada'),
(8, 7, 1, 2, 50.00, 1200.00, 60000.00, 0.00, 'retenida_aforo'),
(9, 7, 2, 14, 100.00, 380.00, 38000.00, 1900.00, 'aprobada'),
(10, 8, 1, 11, 5000.00, 9.70, 48500.00, 0.00, 'aprobada'),
(11, 9, 1, 12, 1.00, 115000.00, 115000.00, 5750.00, 'aprobada'),
(12, 10, 1, 15, 16.00, 2000.00, 32000.00, 0.00, 'aprobada'),
(13, 11, 1, 8, 2.00, 44500.00, 89000.00, 26700.00, 'aprobada'),
(14, 12, 1, 13, 1000.00, 62.00, 62000.00, 9300.00, 'aprobada'),
(15, 13, 1, 10, 820.00, 50.00, 41000.00, 6150.00, 'aprobada'),
(16, 14, 1, 1, 60.00, 1400.00, 84000.00, 0.00, 'aprobada'),
(17, 14, 2, 2, 55.00, 1200.00, 66000.00, 0.00, 'aprobada'),
(18, 15, 1, 9, 300.00, 96.66, 29000.00, 4060.00, 'aprobada'),
(19, 1, 2, 5, 500.00, 35.00, 17500.00, 0.00, 'aprobada'),
(20, 3, 2, 10, 200.00, 52.00, 10400.00, 1560.00, 'aprobada');

SELECT setval('detalle_declaracion_id_detalle_seq', 20);

-- 4.11. Inserción en 'inventario_bodega' (18 registros, vinculados a bodegas y detalles)
INSERT INTO inventario_bodega (id_inventario, id_bodega, id_detalle, ubicacion_especifica, cantidad_disponible, cantidad_retenida, estado_fiscal, fecha_ingreso, fecha_ultimo_movimiento) VALUES
(1, 1, 1, 'Pasillo A - Rack 01 - Bahía 1', 30.00, 0.00, 'autorizado_despacho', '2026-10-02 14:00:00-06', '2026-10-03 15:00:00-06'),
(2, 2, 2, 'Pasillo C - Rack 04 - Bahía 2', 0.00, 80.00, 'retenido_fiscal', '2026-10-05 11:30:00-06', '2026-10-06 09:00:00-06'),
(3, 2, 3, 'Pasillo C - Rack 04 - Bahía 3', 0.00, 30.00, 'retenido_fiscal', '2026-10-05 11:30:00-06', '2026-10-06 09:00:00-06'),
(4, 3, 4, 'Zona Granos - Silo Norte 02', 800.00, 0.00, 'autorizado_despacho', '2026-10-08 15:00:00-06', '2026-10-10 17:00:00-06'),
(5, 4, 5, 'Jaula de Seguridad - Rack F-01', 0.00, 2500.00, 'retenido_fiscal', '2026-10-12 16:00:00-06', '2026-10-13 10:30:00-06'),
(6, 5, 6, 'Pasillo B - Rack 02 - Bahía 4', 2000.00, 0.00, 'autorizado_despacho', '2026-10-15 11:00:00-06', '2026-10-16 14:00:00-06'),
(7, 1, 7, 'Pasillo D - Rack 10 - Nivel 2', 600.00, 0.00, 'en_custodia', '2026-10-18 14:30:00-06', '2026-10-18 14:30:00-06'),
(8, 2, 8, 'Pasillo C - Rack 05 - Bahía 1', 0.00, 50.00, 'retenido_fiscal', '2026-10-20 16:00:00-06', '2026-10-21 08:30:00-06'),
(9, 2, 9, 'Pasillo E - Rack 01 - Bahía 2', 100.00, 0.00, 'en_custodia', '2026-10-20 16:00:00-06', '2026-10-21 11:00:00-06'),
(10, 6, 12, 'Cámara Fría Médica - Estante 3', 16.00, 0.00, 'autorizado_despacho', '2026-10-23 09:00:00-06', '2026-10-23 14:00:00-06'),
(11, 9, 11, 'Patio Caldera - Bloque F-12', 1.00, 0.00, 'autorizado_despacho', '2026-10-22 13:00:00-06', '2026-10-23 10:30:00-06'),
(12, 12, 13, 'Patio Metropolitano - Carril 04', 2.00, 0.00, 'despachado', '2026-09-10 14:00:00-06', '2026-09-12 16:00:00-06'),
(13, 7, 14, 'Cámara 02 - Pasillo Vino B-01', 1000.00, 0.00, 'en_custodia', '2026-09-15 15:30:00-06', '2026-09-16 11:30:00-06'),
(14, 10, 15, 'Andén Frontera - Nave 01', 820.00, 0.00, 'despachado', '2026-09-22 11:00:00-06', '2026-09-23 17:00:00-06'),
(15, 1, 16, 'Pasillo A - Rack 03 - Bahía 1', 60.00, 0.00, 'despachado', '2026-08-05 14:00:00-06', '2026-08-11 10:00:00-06'),
(16, 5, 17, 'Pasillo B - Rack 01 - Bahía 1', 55.00, 0.00, 'despachado', '2026-08-05 14:00:00-06', '2026-08-11 11:00:00-06'),
(17, 3, 18, 'Pasillo D - Rack 08 - Nivel 1', 300.00, 0.00, 'despachado', '2026-08-18 10:00:00-06', '2026-08-20 14:00:00-06'),
(18, 5, 19, 'Pasillo B - Rack 02 - Bahía 5', 500.00, 0.00, 'autorizado_despacho', '2026-10-02 14:30:00-06', '2026-10-03 15:30:00-06');

SELECT setval('inventario_bodega_id_inventario_seq', 18);

-- 4.12. Inserción en 'movimiento_inventario' (18 registros de bitácora)
INSERT INTO movimiento_inventario (id_movimiento, id_inventario, tipo_movimiento, cantidad, id_funcionario, motivo_observacion, fecha_movimiento) VALUES
(1, 1, 'ingreso_inicial', 30.00, 8, 'Recepción conforme en bodega Santamaría amparada en DUA-2026-OCT-001', '2026-10-02 14:05:00-06'),
(2, 1, 'desbloqueo_levante', 30.00, 8, 'Canal verde confirmado, levante fiscal otorgado por sistema DGA', '2026-10-03 14:10:00-06'),
(3, 2, 'ingreso_inicial', 80.00, 11, 'Descarga de contenedor MSCU5544332 en Moín', '2026-10-05 11:35:00-06'),
(4, 2, 'bloqueo_aforo', 80.00, 11, 'Notificación de canal rojo selectivo por fiscalización de valor', '2026-10-06 09:05:00-06'),
(5, 3, 'ingreso_inicial', 30.00, 11, 'Recepción de teléfonos iPhones en bodega de Moín', '2026-10-05 11:40:00-06'),
(6, 3, 'bloqueo_aforo', 30.00, 11, 'Retención preventiva para verificación de números IMEI y homologación SUTEL', '2026-10-06 09:10:00-06'),
(7, 4, 'ingreso_inicial', 800.00, 8, 'Ingreso a silos de granos procedentes de Caldera', '2026-10-08 15:10:00-06'),
(8, 4, 'desbloqueo_levante', 800.00, 8, 'Aforo documental conforme, visto bueno fitosanitario MAG aprobado', '2026-10-10 16:35:00-06'),
(9, 5, 'ingreso_inicial', 2500.00, 9, 'Recepción de carga farmacéutica aérea en aeropuerto', '2026-10-12 16:15:00-06'),
(10, 5, 'bloqueo_aforo', 2500.00, 9, 'Bloqueo inmediato: lote no coincide con el registro sanitario del Ministerio de Salud', '2026-10-13 10:35:00-06'),
(11, 6, 'ingreso_inicial', 2000.00, 8, 'Ingreso de unidades de disco duro SSD en bodega Coyol', '2026-10-15 11:15:00-06'),
(12, 7, 'ingreso_inicial', 600.00, 8, 'Ingreso de textiles bajo régimen de depósito fiscal', '2026-10-18 14:40:00-06'),
(13, 8, 'ingreso_inicial', 50.00, 11, 'Ingreso de computadoras portátiles Apple en Moín', '2026-10-20 16:10:00-06'),
(14, 8, 'bloqueo_aforo', 50.00, 11, 'Retención para aforo físico por sospecha de subfacturación CIF', '2026-10-21 08:35:00-06'),
(15, 10, 'ingreso_inicial', 16.00, 9, 'Ingreso a cámara fría de equipos médicos de monitoreo', '2026-10-23 09:15:00-06'),
(16, 11, 'ingreso_inicial', 1.00, 8, 'Ingreso de maquinaria en patio intermodal Caldera', '2026-10-22 13:10:00-06'),
(17, 12, 'despacho_final', 2.00, 8, 'Salida física de vehículos nacionalizados con levante', '2026-09-12 16:05:00-06'),
(18, 14, 'despacho_final', 820.00, 8, 'Cierre de tránsito aduanero internacional en frontera', '2026-09-23 17:05:00-06');

SELECT setval('movimiento_inventario_id_movimiento_seq', 18);

-- 4.13. Inserción en 'inspeccion' (16 registros con funcionarios y observaciones)
INSERT INTO inspeccion (id_inspeccion, numero_acta, id_declaracion, id_detalle, id_funcionario_aforador, tipo_inspeccion, resultado, observaciones, fecha_inspeccion) VALUES
(1, 'ACTA-2026-AF-001', 1, 1, 5, 'documental', 'conforme', 'Documentación comercial, factura, BL y certificado de origen en regla. Valor CIF aceptado.', '2026-10-02 11:00:00-06'),
(2, 'ACTA-2026-AF-002', 2, 2, 11, 'fisica_aforo', 'dictamen_pendiente', 'Aforo físico realizado en bodega Moín. Se detectan discrepancias en el valor declarado de los smartphones. Se remite muestra a valoración aduanera.', '2026-10-06 10:30:00-06'),
(3, 'ACTA-2026-AF-003', 2, 3, 11, 'fisica_aforo', 'conforme', 'Conteo físico de iPhones coincide exactamente con 30 unidades declaradas. Precintos intactos.', '2026-10-06 11:15:00-06'),
(4, 'ACTA-2026-AF-004', 3, 4, 7, 'documental', 'conforme', 'Certificado fitosanitario MAG de arroz verificado en sistema SIVEPA. Aranceles cancelados al 35%.', '2026-10-09 14:00:00-06'),
(5, 'ACTA-2026-AF-005', 4, 5, 6, 'fisica_aforo', 'no_conforme_ajuste', 'Inspección de medicamentos: lote 2026-MED difiere de la autorización de desalmacenaje del Ministerio de Salud. Mercancía queda retenida.', '2026-10-13 11:00:00-06'),
(6, 'ACTA-2026-AF-006', 7, 8, 11, 'fisica_aforo', 'no_conforme_ajuste', 'Aforo físico de laptops MacBook: el precio unitario declarado de $1200 es inferior a la base de datos de precios de referencia ($1450). Se apertura ajuste tributario.', '2026-10-21 09:30:00-06'),
(7, 'ACTA-2026-AF-007', 7, 9, 12, 'no_intrusiva_escaner', 'conforme', 'Escaneo por rayos X de bultos de monitores sin anomalías de densidad ni compartimentos ocultos.', '2026-10-21 10:45:00-06'),
(8, 'ACTA-2026-AF-008', 9, 11, 13, 'fisica_aforo', 'conforme', 'Verificación física de número de serie y horómetro de minicargador frontal Cat 226D3. Régimen temporal autorizado.', '2026-10-22 14:00:00-06'),
(9, 'ACTA-2026-AF-009', 10, 12, 14, 'documental', 'conforme', 'Revisión técnica de monitores de signos vitales: certificados de calibración médica de fábrica conformes.', '2026-10-23 11:30:00-06'),
(10, 'ACTA-2026-AF-010', 11, 13, 5, 'fisica_aforo', 'conforme', 'Inspección vehicular física: números de chasis (VIN) y motor coinciden con la declaración aduanera.', '2026-09-11 09:15:00-06'),
(11, 'ACTA-2026-AF-011', 12, 14, 8, 'documental', 'conforme', 'Revisión documental de vinos bajo régimen suspensivo de depósito fiscal. Carga intacta.', '2026-09-15 16:00:00-06'),
(12, 'ACTA-2026-AF-012', 13, 15, 6, 'no_intrusiva_escaner', 'conforme', 'Inspección no intrusiva de tránsito internacional en aduana de Peñas Blancas. Precinto fiscal conforme.', '2026-09-22 14:30:00-06'),
(13, 'ACTA-2026-AF-013', 14, 16, 5, 'fisica_aforo', 'conforme', 'Aforo físico por canal rojo de laptops Lenovo: números de serie y especificaciones coinciden.', '2026-08-08 10:00:00-06'),
(14, 'ACTA-2026-AF-014', 14, 17, 5, 'fisica_aforo', 'conforme', 'Revisión física de laptops MacBook: factura comercial y certificados validados con el fabricante.', '2026-08-08 11:30:00-06'),
(15, 'ACTA-2026-AF-015', 15, 18, 14, 'documental', 'conforme', 'Comprobación de partida arancelaria y liquidación de impuestos de calzado importado.', '2026-08-19 10:15:00-06'),
(16, 'ACTA-2026-AF-016', 4, NULL, 15, 'documental', 'no_conforme_comiso', 'Auditoría forense de valor: importador no logró demostrar trazabilidad bancaria de la transferencia al proveedor exterior. Se inicia proceso de comiso administrativo.', '2026-10-14 15:45:00-06');

SELECT setval('inspeccion_id_inspeccion_seq', 16);


-- ============================================================================
-- 5. BATERÍA DE CONSULTAS ANALÍTICAS SELECT (8 O MÁS CONSULTAS DE NEGOCIO)
-- ============================================================================

-- ----------------------------------------------------------------------------
-- CONSULTA 1: Declaraciones de importación presentadas en el mes de octubre
-- Pregunta de Negocio: ¿Cuáles declaraciones bajo régimen de importación definitiva
-- ingresaron durante el mes de octubre de 2026, qué importador las tramitó, cuál
-- fue su canal de aforo asignado y su valor CIF liquidado?
-- ----------------------------------------------------------------------------
SELECT 
    da.numero_declaracion,
    ie.razon_social AS importador,
    aa.nombre_agencia AS agencia_aduanal,
    da.tipo_regimen,
    da.canal_aforo,
    da.estado_declaracion,
    da.valor_cif_total_usd,
    da.total_tributos_usd,
    TO_CHAR(da.fecha_presentacion, 'YYYY-MM-DD HH24:MI') AS fecha_presentacion
FROM declaracion_aduanera da
INNER JOIN importador_exportador ie ON da.id_operador = ie.id_operador
INNER JOIN agente_aduanal aa ON da.id_agente = aa.id_agente
WHERE da.tipo_regimen = 'importacion_definitiva'
  AND da.fecha_presentacion >= '2026-10-01 00:00:00-06'
  AND da.fecha_presentacion < '2026-11-01 00:00:00-06'
ORDER BY da.fecha_presentacion DESC;


-- ----------------------------------------------------------------------------
-- CONSULTA 2: Mercancías retenidas por bodega
-- Pregunta de Negocio: ¿Qué productos se encuentran actualmente retenidos o bloqueados
-- por aforo en cada bodega fiscal, indicando la ubicación física, cantidad y DUA?
-- ----------------------------------------------------------------------------
SELECT 
    b.codigo_bodega,
    b.nombre AS bodega_custodia,
    p.codigo_sku,
    p.nombre_comercial AS producto,
    da.numero_declaracion,
    ib.ubicacion_especifica,
    ib.cantidad_retenida,
    p.unidad_medida,
    ib.estado_fiscal,
    TO_CHAR(ib.fecha_ingreso, 'YYYY-MM-DD') AS fecha_ingreso
FROM inventario_bodega ib
INNER JOIN bodega b ON ib.id_bodega = b.id_bodega
INNER JOIN detalle_declaracion dd ON ib.id_detalle = dd.id_detalle
INNER JOIN producto p ON dd.id_producto = p.id_producto
INNER JOIN declaracion_aduanera da ON dd.id_declaracion = da.id_declaracion
WHERE ib.cantidad_retenida > 0 
   OR ib.estado_fiscal = 'retenido_fiscal'
ORDER BY b.codigo_bodega ASC, ib.cantidad_retenida DESC;


-- ----------------------------------------------------------------------------
-- CONSULTA 3: País con más contenedores ingresados
-- Pregunta de Negocio: ¿Cuál es el ranking de países de procedencia con mayor volumen
-- de contenedores ingresados al sistema aduanero y qué porcentaje representan?
-- ----------------------------------------------------------------------------
SELECT 
    p.codigo_alfa2,
    p.nombre AS pais_procedencia,
    COUNT(c.id_contenedor) AS total_contenedores,
    ROUND(COUNT(c.id_contenedor) * 100.0 / (SELECT COUNT(*) FROM contenedor), 2) AS porcentaje_total,
    SUM(c.capacidad_maxima_kg - c.tara_kg) AS carga_util_maxima_ton
FROM contenedor c
INNER JOIN pais p ON c.id_pais_procedencia = p.id_pais
GROUP BY p.codigo_alfa2, p.nombre
ORDER BY total_contenedores DESC, pais_procedencia ASC;


-- ----------------------------------------------------------------------------
-- CONSULTA 4: Importador con mayor valor total declarado (Valor CIF acumulado)
-- Pregunta de Negocio: ¿Cuáles importadores acumulan el mayor valor económico CIF
-- declarado ante la aduana, cuántas operaciones han tramitado y cuánto han tributado?
-- ----------------------------------------------------------------------------
SELECT 
    ie.numero_identificacion,
    ie.razon_social AS importador,
    p.nombre AS pais_origen,
    COUNT(da.id_declaracion) AS total_declaraciones_tramitadas,
    SUM(da.valor_cif_total_usd) AS valor_cif_acumulado_usd,
    SUM(da.total_tributos_usd) AS tributos_totales_pagados_usd,
    ROUND(AVG(da.valor_cif_total_usd), 2) AS promedio_cif_por_declaracion_usd
FROM importador_exportador ie
INNER JOIN declaracion_aduanera da ON ie.id_operador = da.id_operador
INNER JOIN pais p ON ie.id_pais = p.id_pais
GROUP BY ie.numero_identificacion, ie.razon_social, p.nombre
ORDER BY valor_cif_acumulado_usd DESC;


-- ----------------------------------------------------------------------------
-- CONSULTA 5: Inspecciones con observaciones y funcionario responsable
-- Pregunta de Negocio: ¿Cuáles aforos o inspecciones aduaneras presentaron anomalías,
-- ajustes o comisos, cuál fue la observación técnica y quién fue el funcionario y su supervisor?
-- ----------------------------------------------------------------------------
SELECT 
    i.numero_acta,
    da.numero_declaracion,
    i.tipo_inspeccion,
    i.resultado,
    f_aforador.nombre_completo AS funcionario_aforador,
    f_aforador.cargo AS cargo_aforador,
    COALESCE(f_supervisor.nombre_completo, 'Dirección General') AS supervisor_a_cargo,
    i.observaciones,
    TO_CHAR(i.fecha_inspeccion, 'YYYY-MM-DD HH24:MI') AS fecha_inspeccion
FROM inspeccion i
INNER JOIN declaracion_aduanera da ON i.id_declaracion = da.id_declaracion
INNER JOIN funcionario f_aforador ON i.id_funcionario_aforador = f_aforador.id_funcionario
LEFT JOIN funcionario f_supervisor ON f_aforador.id_supervisor = f_supervisor.id_funcionario
WHERE i.observaciones IS NOT NULL 
  AND TRIM(i.observaciones) <> ''
  AND i.resultado IN ('no_conforme_ajuste', 'no_conforme_comiso', 'dictamen_pendiente')
ORDER BY i.fecha_inspeccion DESC;


-- ----------------------------------------------------------------------------
-- CONSULTA 6: Stock consolidado de productos en todas las bodegas
-- Pregunta de Negocio: ¿Cuál es la disponibilidad física y fiscal de cada producto
-- (saldo disponible vs. saldo retenido) distribuido en los diferentes almacenes fiscales?
-- ----------------------------------------------------------------------------
SELECT 
    p.codigo_sku,
    p.nombre_comercial,
    pa.codigo_partida AS partida_arancelaria,
    b.nombre AS bodega_almacen,
    SUM(ib.cantidad_disponible) AS stock_disponible,
    SUM(ib.cantidad_retenida) AS stock_retenido,
    SUM(ib.cantidad_disponible + ib.cantidad_retenida) AS stock_total_en_bodega,
    p.unidad_medida
FROM producto p
INNER JOIN partida_arancelaria pa ON p.id_partida = pa.id_partida
INNER JOIN detalle_declaracion dd ON p.id_producto = dd.id_producto
INNER JOIN inventario_bodega ib ON dd.id_detalle = ib.id_detalle
INNER JOIN bodega b ON ib.id_bodega = b.id_bodega
GROUP BY p.codigo_sku, p.nombre_comercial, pa.codigo_partida, b.nombre, p.unidad_medida
ORDER BY p.codigo_sku ASC, stock_total_en_bodega DESC;


-- ----------------------------------------------------------------------------
-- CONSULTA 7: Trazabilidad y auditoría de movimientos de inventario
-- Pregunta de Negocio: ¿Cuál es el historial cronológico de movimientos de bodega,
-- qué tipo de operación se realizó, quién la autorizó y cuál fue la justificación?
-- ----------------------------------------------------------------------------
SELECT 
    mi.id_movimiento,
    TO_CHAR(mi.fecha_movimiento, 'YYYY-MM-DD HH24:MI:SS') AS fecha_hora,
    mi.tipo_movimiento,
    p.nombre_comercial AS producto,
    b.codigo_bodega,
    b.nombre AS bodega,
    mi.cantidad,
    p.unidad_medida,
    f.nombre_completo AS funcionario_autorizador,
    f.cargo,
    mi.motivo_observacion
FROM movimiento_inventario mi
INNER JOIN inventario_bodega ib ON mi.id_inventario = ib.id_inventario
INNER JOIN bodega b ON ib.id_bodega = b.id_bodega
INNER JOIN detalle_declaracion dd ON ib.id_detalle = dd.id_detalle
INNER JOIN producto p ON dd.id_producto = p.id_producto
INNER JOIN funcionario f ON mi.id_funcionario = f.id_funcionario
ORDER BY mi.fecha_movimiento DESC;


-- ----------------------------------------------------------------------------
-- CONSULTA 8: Resumen estadístico por régimen aduanero y canal de aforo
-- Pregunta de Negocio: ¿Cómo se distribuyen las declaraciones por tipo de régimen y
-- canal de aforo (verde, amarillo, rojo), cuál es el volumen CIF y la recaudación generada?
-- ----------------------------------------------------------------------------
SELECT 
    da.tipo_regimen,
    da.canal_aforo,
    COUNT(da.id_declaracion) AS total_declaraciones,
    SUM(da.valor_cif_total_usd) AS valor_cif_total_usd,
    SUM(da.total_tributos_usd) AS recaudacion_tributaria_usd,
    ROUND(AVG(da.valor_cif_total_usd), 2) AS promedio_cif_usd
FROM declaracion_aduanera da
GROUP BY da.tipo_regimen, da.canal_aforo
ORDER BY da.tipo_regimen ASC, total_declaraciones DESC;


-- ----------------------------------------------------------------------------
-- CONSULTA 9 (BONUS): Jerarquía del personal aduanero y aforos ejecutados
-- Pregunta de Negocio: ¿Cómo está conformada la cadena de mando entre supervisores
-- y aforadores, y cuántas inspecciones ha realizado cada funcionario subordinado?
-- ----------------------------------------------------------------------------
SELECT 
    COALESCE(sup.nombre_completo, 'DESPACHO DEL DIRECTOR GENERAL') AS supervisor_inmediato,
    sup.cargo AS cargo_supervisor,
    sub.numero_empleado AS carnet_aforador,
    sub.nombre_completo AS funcionario_aforador,
    sub.cargo AS cargo_aforador,
    COUNT(i.id_inspeccion) AS total_aforos_realizados,
    COUNT(CASE WHEN i.resultado = 'no_conforme_ajuste' THEN 1 END) AS aforos_con_ajuste_tributario,
    COUNT(CASE WHEN i.resultado = 'no_conforme_comiso' THEN 1 END) AS aforos_con_comiso
FROM funcionario sub
LEFT JOIN funcionario sup ON sub.id_supervisor = sup.id_funcionario
LEFT JOIN inspeccion i ON sub.id_funcionario = i.id_funcionario_aforador
GROUP BY sup.nombre_completo, sup.cargo, sub.numero_empleado, sub.nombre_completo, sub.cargo
ORDER BY supervisor_inmediato ASC, total_aforos_realizados DESC;

-- ============================================================================
-- FIN DEL SCRIPT: Apellido_Nombre_Aduana_Lab3.sql
-- ============================================================================
