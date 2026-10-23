-- ============================================================================
-- LABORATORIO: SISTEMA DE INVENTARIO ADUANERO
-- ARCHIVO: 01_creacion_tablas.sql
-- DESCRIPCION: Script DDL para la creacion de tablas, llaves primarias, 
--              llaves foraneas, restricciones de integridad y comentarios.
-- ORDEN DE EJECUCION:
--   1. Eliminacion de tablas en orden inverso (hijas primero).
--   2. Creacion de tablas padre: importador, deposito_aduanero, categoria_arancelaria.
--   3. Creacion de tablas hijas: declaracion_aduanera, mercancia_inventario, inspeccion_aduanera.
-- ============================================================================

-- 1. ELIMINACION IDEMPOTENTE (de hijas a padres)
DROP TABLE IF EXISTS inspeccion_aduanera CASCADE;
DROP TABLE IF EXISTS mercancia_inventario CASCADE;
DROP TABLE IF EXISTS declaracion_aduanera CASCADE;
DROP TABLE IF EXISTS categoria_arancelaria CASCADE;
DROP TABLE IF EXISTS deposito_aduanero CASCADE;
DROP TABLE IF EXISTS importador CASCADE;

-- 2. TABLAS PADRE

-- Tabla: importador
CREATE TABLE importador (
    id_importador SERIAL PRIMARY KEY,
    numero_identificacion VARCHAR(20) NOT NULL UNIQUE,
    razon_social VARCHAR(150) NOT NULL,
    pais_origen VARCHAR(60) NOT NULL,
    telefono VARCHAR(20) NOT NULL,
    correo_contacto VARCHAR(100) NOT NULL,
    direccion TEXT NOT NULL,
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_importador_correo CHECK (correo_contacto ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$')
);

COMMENT ON TABLE importador IS 'Registro de personas fisicas o juridicas autorizadas para realizar operaciones de importacion';
COMMENT ON COLUMN importador.id_importador IS 'Identificador unico secuencial del importador';
COMMENT ON COLUMN importador.numero_identificacion IS 'Identificacion tributaria o cedula juridica unica';
COMMENT ON COLUMN importador.razon_social IS 'Nombre legal o razon social registrada';
COMMENT ON COLUMN importador.pais_origen IS 'Pais de residencia fiscal o domicilio legal';
COMMENT ON COLUMN importador.telefono IS 'Numero de contacto operativo';
COMMENT ON COLUMN importador.correo_contacto IS 'Correo electronico oficial para notificaciones aduaneras';
COMMENT ON COLUMN importador.direccion IS 'Domicilio fiscal completo';
COMMENT ON COLUMN importador.activo IS 'Estado de operacion del importador (true = habilitado, false = suspendido)';
COMMENT ON COLUMN importador.fecha_registro IS 'Fecha y hora en que se creo el registro del importador';


-- Tabla: deposito_aduanero
CREATE TABLE deposito_aduanero (
    id_deposito SERIAL PRIMARY KEY,
    codigo_deposito VARCHAR(20) NOT NULL UNIQUE,
    nombre VARCHAR(120) NOT NULL,
    tipo_deposito VARCHAR(50) NOT NULL,
    capacidad_maxima_m3 NUMERIC(10,2) NOT NULL,
    ubicacion_puerto_aeropuerto VARCHAR(100) NOT NULL,
    responsable VARCHAR(100) NOT NULL,
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT chk_deposito_tipo CHECK (tipo_deposito IN ('temporal', 'fiscal', 'franco', 'refrigerado')),
    CONSTRAINT chk_deposito_capacidad CHECK (capacidad_maxima_m3 > 0)
);

COMMENT ON TABLE deposito_aduanero IS 'Instalaciones y bodegas aduaneras habilitadas para la custodia de mercancias';
COMMENT ON COLUMN deposito_aduanero.id_deposito IS 'Identificador unico secuencial del deposito';
COMMENT ON COLUMN deposito_aduanero.codigo_deposito IS 'Codigo unico oficial asignado por la autoridad aduanera';
COMMENT ON COLUMN deposito_aduanero.nombre IS 'Nombre comercial del almacen o deposito fiscal';
COMMENT ON COLUMN deposito_aduanero.tipo_deposito IS 'Clasificacion de la instalacion (temporal, fiscal, franco, refrigerado)';
COMMENT ON COLUMN deposito_aduanero.capacidad_maxima_m3 IS 'Capacidad volumetrica total en metros cubicos';
COMMENT ON COLUMN deposito_aduanero.ubicacion_puerto_aeropuerto IS 'Ubicacion geografica de la terminal de ingreso o puerto';
COMMENT ON COLUMN deposito_aduanero.responsable IS 'Nombre del gerente de operaciones o custodio fiscal';
COMMENT ON COLUMN deposito_aduanero.activo IS 'Indicador de operatividad del deposito';


-- Tabla: categoria_arancelaria
CREATE TABLE categoria_arancelaria (
    id_categoria SERIAL PRIMARY KEY,
    codigo_arancelario VARCHAR(20) NOT NULL UNIQUE,
    descripcion VARCHAR(255) NOT NULL,
    tasa_arancelaria_porcentaje NUMERIC(5,2) NOT NULL DEFAULT 0.00,
    requiere_permiso_especial BOOLEAN NOT NULL DEFAULT FALSE,
    CONSTRAINT chk_categoria_tasa CHECK (tasa_arancelaria_porcentaje >= 0.00 AND tasa_arancelaria_porcentaje <= 100.00)
);

COMMENT ON TABLE categoria_arancelaria IS 'Clasificacion arancelaria de mercancias segun la nomenclatura internacional armonizada';
COMMENT ON COLUMN categoria_arancelaria.id_categoria IS 'Identificador unico secuencial de la clasificacion arancelaria';
COMMENT ON COLUMN categoria_arancelaria.codigo_arancelario IS 'Partida arancelaria oficial (SAC / HS Code)';
COMMENT ON COLUMN categoria_arancelaria.descripcion IS 'Descripcion tecnica de la familia de mercancias';
COMMENT ON COLUMN categoria_arancelaria.tasa_arancelaria_porcentaje IS 'Porcentaje base de arancel de importacion aplicable';
COMMENT ON COLUMN categoria_arancelaria.requiere_permiso_especial IS 'Indica si amerita notas tecnicas de salud, fitosanitarias o seguridad';


-- 3. TABLAS HIJAS Y TRANSACCIONALES

-- Tabla: declaracion_aduanera
CREATE TABLE declaracion_aduanera (
    id_declaracion SERIAL PRIMARY KEY,
    numero_declaracion VARCHAR(30) NOT NULL UNIQUE,
    id_importador INT NOT NULL REFERENCES importador(id_importador) ON DELETE RESTRICT,
    id_deposito INT NOT NULL REFERENCES deposito_aduanero(id_deposito) ON DELETE RESTRICT,
    tipo_regimen VARCHAR(50) NOT NULL,
    canal_aforo VARCHAR(20) NOT NULL DEFAULT 'verde',
    estado_declaracion VARCHAR(30) NOT NULL DEFAULT 'registrada',
    fecha_presentacion TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_levante TIMESTAMPTZ NULL,
    CONSTRAINT chk_declaracion_regimen CHECK (tipo_regimen IN (
        'importacion_definitiva',
        'deposito_fiscal',
        'transito_aduanero',
        'admision_temporal'
    )),
    CONSTRAINT chk_declaracion_canal CHECK (canal_aforo IN ('verde', 'amarillo', 'rojo')),
    CONSTRAINT chk_declaracion_estado CHECK (estado_declaracion IN (
        'registrada',
        'en_revision',
        'autorizada',
        'rechazada',
        'liquidada'
    )),
    CONSTRAINT chk_declaracion_fechas CHECK (fecha_levante IS NULL OR fecha_levante >= fecha_presentacion)
);

COMMENT ON TABLE declaracion_aduanera IS 'Documento aduanero unico (DUA o poliza) que formaliza la destinacion de la carga';
COMMENT ON COLUMN declaracion_aduanera.id_declaracion IS 'Identificador unico secuencial de la declaracion';
COMMENT ON COLUMN declaracion_aduanera.numero_declaracion IS 'Numero oficial de declaracion aduanera generado por el sistema aduanero';
COMMENT ON COLUMN declaracion_aduanera.id_importador IS 'Referencia foranea al importador responsable';
COMMENT ON COLUMN declaracion_aduanera.id_deposito IS 'Referencia foranea al deposito aduanero donde ingresa la mercancia';
COMMENT ON COLUMN declaracion_aduanera.tipo_regimen IS 'Regimen aduanero al que se somete la carga';
COMMENT ON COLUMN declaracion_aduanera.canal_aforo IS 'Canal de selectividad asignado por riesgo (verde: levante inmediato, amarillo: documental, rojo: fisico)';
COMMENT ON COLUMN declaracion_aduanera.estado_declaracion IS 'Fase actual del tramite aduanero';
COMMENT ON COLUMN declaracion_aduanera.fecha_presentacion IS 'Fecha y hora de transmision y registro del documento';
COMMENT ON COLUMN declaracion_aduanera.fecha_levante IS 'Fecha y hora de autorizacion del retiro de la mercancia';


-- Tabla: mercancia_inventario
CREATE TABLE mercancia_inventario (
    id_mercancia SERIAL PRIMARY KEY,
    id_declaracion INT NOT NULL REFERENCES declaracion_aduanera(id_declaracion) ON DELETE RESTRICT,
    id_categoria INT NOT NULL REFERENCES categoria_arancelaria(id_categoria) ON DELETE RESTRICT,
    codigo_bulto VARCHAR(40) NOT NULL UNIQUE,
    descripcion_comercial VARCHAR(255) NOT NULL,
    cantidad_bultos INT NOT NULL,
    peso_bruto_kg NUMERIC(10,2) NOT NULL,
    valor_cif_usd NUMERIC(14,2) NOT NULL,
    ubicacion_especifica VARCHAR(50) NOT NULL,
    estado_mercancia VARCHAR(30) NOT NULL DEFAULT 'en_custodia',
    fecha_ingreso TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_salida TIMESTAMPTZ NULL,
    CONSTRAINT chk_mercancia_cantidad CHECK (cantidad_bultos > 0),
    CONSTRAINT chk_mercancia_peso CHECK (peso_bruto_kg > 0),
    CONSTRAINT chk_mercancia_valor CHECK (valor_cif_usd >= 0.00),
    CONSTRAINT chk_mercancia_estado CHECK (estado_mercancia IN (
        'en_custodia',
        'bloqueada_aforo',
        'con_levante',
        'despachada',
        'en_abandono'
    )),
    CONSTRAINT chk_mercancia_fechas CHECK (fecha_salida IS NULL OR fecha_salida >= fecha_ingreso)
);

COMMENT ON TABLE mercancia_inventario IS 'Inventario fisico detallado de bultos y articulos bajo custodia aduanera';
COMMENT ON COLUMN mercancia_inventario.id_mercancia IS 'Identificador unico secuencial del lote de mercancia';
COMMENT ON COLUMN mercancia_inventario.id_declaracion IS 'Referencia foranea a la declaracion aduanera asociada';
COMMENT ON COLUMN mercancia_inventario.id_categoria IS 'Referencia foranea a la clasificacion arancelaria correspondiente';
COMMENT ON COLUMN mercancia_inventario.codigo_bulto IS 'Codigo unico de etiqueta o numero de seguimiento aduanero';
COMMENT ON COLUMN mercancia_inventario.descripcion_comercial IS 'Descripcion clara y precisa del producto comercial';
COMMENT ON COLUMN mercancia_inventario.cantidad_bultos IS 'Cantidad de cajas, paquetes o bultos fisicos';
COMMENT ON COLUMN mercancia_inventario.peso_bruto_kg IS 'Peso total del lote con embalaje en kilogramos';
COMMENT ON COLUMN mercancia_inventario.valor_cif_usd IS 'Valor en aduanas (Costo, Seguro y Flete) expresado en dolares';
COMMENT ON COLUMN mercancia_inventario.ubicacion_especifica IS 'Coordenada fisica interna dentro del deposito (ej. pasillo, rack, estante)';
COMMENT ON COLUMN mercancia_inventario.estado_mercancia IS 'Condicion operativa y fiscal de la mercancia';
COMMENT ON COLUMN mercancia_inventario.fecha_ingreso IS 'Fecha y hora de descarga y entrada fisica al inventario';
COMMENT ON COLUMN mercancia_inventario.fecha_salida IS 'Fecha y hora de desalmacenaje o salida efectiva';


-- Tabla: inspeccion_aduanera
CREATE TABLE inspeccion_aduanera (
    id_inspeccion SERIAL PRIMARY KEY,
    id_mercancia INT NOT NULL REFERENCES mercancia_inventario(id_mercancia) ON DELETE RESTRICT,
    numero_acta VARCHAR(30) NOT NULL UNIQUE,
    tipo_aforo VARCHAR(30) NOT NULL,
    nombre_inspector VARCHAR(100) NOT NULL,
    resultado VARCHAR(35) NOT NULL,
    observaciones TEXT NOT NULL,
    fecha_inspeccion TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_inspeccion_aforo CHECK (tipo_aforo IN ('documental', 'fisico', 'escaner_rayos_x')),
    CONSTRAINT chk_inspeccion_resultado CHECK (resultado IN (
        'conforme',
        'no_conforme_ajuste_tributario',
        'no_conforme_comiso',
        'pendiente_dictamen'
    ))
);

COMMENT ON TABLE inspeccion_aduanera IS 'Bitacora oficial de actuaciones fiscalizadoras y aforos aduaneros practicados';
COMMENT ON COLUMN inspeccion_aduanera.id_inspeccion IS 'Identificador unico secuencial de la inspeccion';
COMMENT ON COLUMN inspeccion_aduanera.id_mercancia IS 'Referencia foranea a la mercancia examinada';
COMMENT ON COLUMN inspeccion_aduanera.numero_acta IS 'Numero unico correlativo del acta de aforo aduanero';
COMMENT ON COLUMN inspeccion_aduanera.tipo_aforo IS 'Modalidad de revision ejecutada';
COMMENT ON COLUMN inspeccion_aduanera.nombre_inspector IS 'Nombre del funcionario o aforador aduanero responsable';
COMMENT ON COLUMN inspeccion_aduanera.resultado IS 'Dictamen final de la revision aduanera';
COMMENT ON COLUMN inspeccion_aduanera.observaciones IS 'Detalle tecnico de hallazgos o justificacion del dictamen';
COMMENT ON COLUMN inspeccion_aduanera.fecha_inspeccion IS 'Fecha y hora en que se concluyo la inspeccion';

-- 4. INDICES RECOMENDADOS PARA RENDIMIENTO
CREATE INDEX idx_declaracion_importador ON declaracion_aduanera(id_importador);
CREATE INDEX idx_declaracion_deposito ON declaracion_aduanera(id_deposito);
CREATE INDEX idx_mercancia_declaracion ON mercancia_inventario(id_declaracion);
CREATE INDEX idx_mercancia_categoria ON mercancia_inventario(id_categoria);
CREATE INDEX idx_mercancia_estado ON mercancia_inventario(estado_mercancia);
CREATE INDEX idx_inspeccion_mercancia ON inspeccion_aduanera(id_mercancia);
