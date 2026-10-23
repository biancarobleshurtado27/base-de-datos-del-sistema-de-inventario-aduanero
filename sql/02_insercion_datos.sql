-- ============================================================================
-- LABORATORIO: SISTEMA DE INVENTARIO ADUANERO
-- ARCHIVO: 02_insercion_datos.sql
-- DESCRIPCION: Script DML para la insercion de datos ficticios, realistas 
--              y consistentes con las restricciones del esquema.
-- ORDEN DE INSERCION:
--   1. Tablas padre: importador, deposito_aduanero, categoria_arancelaria.
--   2. Tablas hijas: declaracion_aduanera, mercancia_inventario, inspeccion_aduanera.
-- ============================================================================

-- 1. POBLACION DE TABLAS PADRE

-- Insercion en importador
INSERT INTO importador (id_importador, numero_identificacion, razon_social, pais_origen, telefono, correo_contacto, direccion, activo, fecha_registro)
VALUES 
    (1, '3-101-445892', 'Logistica Global del Caribe S.A.', 'Costa Rica', '+506-2244-1100', 'operaciones@logisticadelcaribe.com', 'Parque Industrial Zeta, Bodega 14, Cartago', true, '2025-01-10 08:30:00-06'),
    (2, '9-002-331890', 'TechParts International Corp', 'Estados Unidos', '+1-305-555-0199', 'customs@techpartscorp.com', '8400 NW 25th St, Doral, FL 33198', true, '2025-02-15 09:15:00-06'),
    (3, '3-101-778234', 'Distribuidora Medica Panamericana Ltda.', 'Panama', '+507-260-4488', 'importaciones@medpanama.com', 'Zona Libre de Colon, Manzana 8, Calle 15', true, '2025-03-01 10:00:00-06'),
    (4, '3-102-998811', 'AgroComercial del Valle S.A.', 'Colombia', '+57-601-344-9000', 'aduanas@agrodevalle.com', 'Zona Franca de Bogota, Edificio Central Of. 402', true, '2025-03-12 11:30:00-06'),
    (5, '3-101-120055', 'Moda y Confecciones del Pacifico S.A.', 'Mexico', '+52-55-5890-1234', 'logistica@modapacifico.mx', 'Av. Insurgentes Sur 1450, Ciudad de Mexico', true, '2025-04-05 14:00:00-06');

-- Sincronizar secuencia de importador
SELECT setval(pg_get_serial_sequence('importador', 'id_importador'), COALESCE(MAX(id_importador), 1)) FROM importador;


-- Insercion en deposito_aduanero
INSERT INTO deposito_aduanero (id_deposito, codigo_deposito, nombre, tipo_deposito, capacidad_maxima_m3, ubicacion_puerto_aeropuerto, responsable, activo)
VALUES 
    (1, 'DEP-AER-01', 'Terminal de Carga Aerea Santamaria', 'temporal', 12500.00, 'Aeropuerto Internacional Juan Santamaria (SJO)', 'Carlos Alvarado Mora', true),
    (2, 'DEP-MAR-02', 'Almacen Fiscal Portuario Moin', 'fiscal', 45000.00, 'Terminal de Contenedores de Moin, Limon', 'Mariana Solano Rojas', true),
    (3, 'DEP-ZFR-03', 'Deposito Aduanero Franco El Coyol', 'franco', 28000.00, 'Zona Franca El Coyol, Alajuela', 'Esteban Chaves Monge', true),
    (4, 'DEP-REF-04', 'Terminal Frigorifica del Pacifico Caldera', 'refrigerado', 8500.00, 'Puerto Caldera, Esparza, Puntarenas', 'Lorena Fonseca Castro', true);

-- Sincronizar secuencia de deposito_aduanero
SELECT setval(pg_get_serial_sequence('deposito_aduanero', 'id_deposito'), COALESCE(MAX(id_deposito), 1)) FROM deposito_aduanero;


-- Insercion en categoria_arancelaria
INSERT INTO categoria_arancelaria (id_categoria, codigo_arancelario, descripcion, tasa_arancelaria_porcentaje, requiere_permiso_especial)
VALUES 
    (1, '8471.30.00.00', 'Laptops y maquinas automaticas para procesamiento de datos portatiles', 0.00, false),
    (2, '3004.90.99.00', 'Medicamentos dosificados para uso terapeutico humano', 0.00, true),
    (3, '8708.29.90.00', 'Partes y accesorios de carrocerias para vehiculos automotores', 14.00, false),
    (4, '6109.10.00.00', 'Camisetas de punto confeccionadas de algodon puro', 13.00, false),
    (5, '0804.30.00.00', 'Pinas frescas o secas para consumo y distribucion', 10.00, true),
    (6, '2208.30.00.00', 'Whiskies y bebidas espirituosas destiladas envasadas', 30.00, true);

-- Sincronizar secuencia de categoria_arancelaria
SELECT setval(pg_get_serial_sequence('categoria_arancelaria', 'id_categoria'), COALESCE(MAX(id_categoria), 1)) FROM categoria_arancelaria;


-- 2. POBLACION DE TABLAS HIJAS

-- Insercion en declaracion_aduanera
INSERT INTO declaracion_aduanera (id_declaracion, numero_declaracion, id_importador, id_deposito, tipo_regimen, canal_aforo, estado_declaracion, fecha_presentacion, fecha_levante)
VALUES 
    (1, 'DUA-2026-000101', 2, 1, 'importacion_definitiva', 'verde', 'liquidada', '2026-03-01 09:00:00-06', '2026-03-01 11:30:00-06'),
    (2, 'DUA-2026-000102', 3, 3, 'deposito_fiscal', 'amarillo', 'autorizada', '2026-03-03 14:20:00-06', '2026-03-04 16:00:00-06'),
    (3, 'DUA-2026-000103', 1, 2, 'importacion_definitiva', 'rojo', 'en_revision', '2026-03-05 08:45:00-06', NULL),
    (4, 'DUA-2026-000104', 4, 4, 'importacion_definitiva', 'rojo', 'en_revision', '2026-03-06 10:10:00-06', NULL),
    (5, 'DUA-2026-000105', 5, 2, 'admision_temporal', 'verde', 'autorizada', '2026-03-07 13:00:00-06', '2026-03-07 15:00:00-06'),
    (6, 'DUA-2026-000106', 2, 1, 'transito_aduanero', 'amarillo', 'registrada', '2026-03-08 11:00:00-06', NULL);

-- Sincronizar secuencia de declaracion_aduanera
SELECT setval(pg_get_serial_sequence('declaracion_aduanera', 'id_declaracion'), COALESCE(MAX(id_declaracion), 1)) FROM declaracion_aduanera;


-- Insercion en mercancia_inventario
INSERT INTO mercancia_inventario (id_mercancia, id_declaracion, id_categoria, codigo_bulto, descripcion_comercial, cantidad_bultos, peso_bruto_kg, valor_cif_usd, ubicacion_especifica, estado_mercancia, fecha_ingreso, fecha_salida)
VALUES 
    (1, 1, 1, 'BLT-2026-A101', 'Lote de 50 laptops Lenovo ThinkPad E14 Gen 5', 50, 115.50, 42500.00, 'Pasillo A - Rack 01 - Bahía 3', 'despachada', '2026-03-01 09:30:00-06', '2026-03-01 12:00:00-06'),
    (2, 1, 1, 'BLT-2026-A102', 'Caja con 80 estaciones de acoplamiento USB-C', 80, 48.00, 7200.00, 'Pasillo A - Rack 01 - Bahía 4', 'despachada', '2026-03-01 09:30:00-06', '2026-03-01 12:00:00-06'),
    (3, 2, 2, 'BLT-2026-B201', 'Pallet refrigerado con 2,000 viales de Insulina Glargina', 20, 240.00, 68000.00, 'Camara Fria 02 - Nivel 1', 'con_levante', '2026-03-03 14:50:00-06', NULL),
    (4, 2, 2, 'BLT-2026-B202', 'Lote de 5,000 tabletas analgesicas en cajas selladas', 50, 310.00, 18500.00, 'Pasillo C - Estante Medico 03', 'con_levante', '2026-03-03 14:50:00-06', NULL),
    (5, 3, 3, 'BLT-2026-C301', 'Contenedor con 120 kits de frenos de disco ventilados', 120, 1850.00, 31200.00, 'Patio Contenedores Moin - Posicion 4B', 'bloqueada_aforo', '2026-03-05 09:15:00-06', NULL),
    (6, 3, 3, 'BLT-2026-C302', 'Lote de amortiguadores delanteros para vehiculo sedan', 60, 920.00, 15400.00, 'Patio Contenedores Moin - Posicion 4C', 'bloqueada_aforo', '2026-03-05 09:15:00-06', NULL),
    (7, 4, 5, 'BLT-2026-D401', 'Cargamento de 400 cajas de pina Golden en contenedor refrigerado', 400, 4800.00, 22000.00, 'Camara Frigorifica Caldera - Bahia Norte', 'bloqueada_aforo', '2026-03-06 10:40:00-06', NULL),
    (8, 5, 4, 'BLT-2026-E501', 'Pallet con 1,200 camisetas deportivas de algodon premium', 40, 520.00, 14400.00, 'Pasillo B - Modulo Textil 12', 'con_levante', '2026-03-07 13:30:00-06', NULL),
    (9, 6, 1, 'BLT-2026-F601', 'Lote de microprocesadores para servidores en transito', 15, 65.00, 58000.00, 'Boveda de Alta Seguridad SJO - Gaveta 08', 'en_custodia', '2026-03-08 11:25:00-06', NULL),
    (10, 3, 6, 'BLT-2026-C303', 'Lote de 300 botellas de Whisky Escoces 12 anos en cajas de madera', 50, 450.00, 28900.00, 'Patio Contenedores Moin - Posicion 5A', 'en_custodia', '2026-03-05 09:15:00-06', NULL);

-- Sincronizar secuencia de mercancia_inventario
SELECT setval(pg_get_serial_sequence('mercancia_inventario', 'id_mercancia'), COALESCE(MAX(id_mercancia), 1)) FROM mercancia_inventario;


-- Insercion en inspeccion_aduanera
INSERT INTO inspeccion_aduanera (id_inspeccion, id_mercancia, numero_acta, tipo_aforo, nombre_inspector, resultado, observaciones, fecha_inspeccion)
VALUES 
    (1, 3, 'ACTA-INSP-2026-001', 'documental', 'Lic. Rodrigo Mendez Fallas', 'conforme', 'Validacion de permisos del Ministerio de Salud completada satisfactoriamente. Cadena de frio certificada.', '2026-03-04 10:30:00-06'),
    (2, 4, 'ACTA-INSP-2026-002', 'documental', 'Lic. Rodrigo Mendez Fallas', 'conforme', 'Documentacion de origen, lote y registro sanitario coincide al 100% con factura comercial.', '2026-03-04 11:15:00-06'),
    (3, 5, 'ACTA-INSP-2026-003', 'fisico', 'Ing. Karla Quesada Venegas', 'no_conforme_ajuste_tributario', 'Se detecto discrepancia en la partida arancelaria declarada. Se requiere ajuste de valor arancelario previo a levante.', '2026-03-05 14:00:00-06'),
    (4, 6, 'ACTA-INSP-2026-004', 'fisico', 'Ing. Karla Quesada Venegas', 'pendiente_dictamen', 'Muestras fisicas enviadas a laboratorio aduanero para verificacion de especificacion tecnica de aleacion.', '2026-03-05 15:30:00-06'),
    (5, 7, 'ACTA-INSP-2026-005', 'fisico', 'Dr. Alvaro Segura Mora', 'pendiente_dictamen', 'Inspeccion fitosanitaria en curso para descarte de plagas cuarentenarias.', '2026-03-06 14:20:00-06');

-- Sincronizar secuencia de inspeccion_aduanera
SELECT setval(pg_get_serial_sequence('inspeccion_aduanera', 'id_inspeccion'), COALESCE(MAX(id_inspeccion), 1)) FROM inspeccion_aduanera;
