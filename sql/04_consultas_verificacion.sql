-- ============================================================================
-- LABORATORIO: SISTEMA DE INVENTARIO ADUANERO
-- ARCHIVO: 04_consultas_verificacion.sql
-- DESCRIPCION: Bateria de consultas analiticas de verificacion y evidencia.
--              Permiten corroborar la integridad referencial, el correcto
--              funcionamiento de los JOINs y la coherencia del negocio aduanero.
-- ============================================================================

-- CONSULTA 1: Trazabilidad Integral de Mercancias en Inventario
-- Objetivo: Comprobar la integridad entre las 6 tablas del sistema mediante un JOIN completo.
SELECT 
    m.codigo_bulto,
    m.descripcion_comercial,
    c.codigo_arancelario,
    i.razon_social AS importador,
    d.nombre AS deposito_almacen,
    dec.numero_declaracion,
    dec.canal_aforo,
    m.ubicacion_especifica,
    m.peso_bruto_kg,
    m.valor_cif_usd,
    m.estado_mercancia,
    COALESCE(insp.resultado, 'sin_aforo_requerido') AS resultado_inspeccion,
    COALESCE(insp.nombre_inspector, 'N/A') AS inspector_a_cargo
FROM mercancia_inventario m
INNER JOIN declaracion_aduanera dec ON m.id_declaracion = dec.id_declaracion
INNER JOIN importador i ON dec.id_importador = i.id_importador
INNER JOIN deposito_aduanero d ON dec.id_deposito = d.id_deposito
INNER JOIN categoria_arancelaria c ON m.id_categoria = c.id_categoria
LEFT JOIN inspeccion_aduanera insp ON m.id_mercancia = insp.id_mercancia
ORDER BY m.id_mercancia ASC;


-- CONSULTA 2: Reporte de Mercancias Bloqueadas o en Aforo Fisico
-- Objetivo: Identificar bultos retenidos que no pueden ser retirados por actuaciones fiscales.
SELECT 
    m.codigo_bulto,
    m.descripcion_comercial,
    dec.numero_declaracion,
    dec.canal_aforo,
    insp.numero_acta,
    insp.tipo_aforo,
    insp.resultado,
    insp.observaciones,
    insp.fecha_inspeccion
FROM mercancia_inventario m
INNER JOIN declaracion_aduanera dec ON m.id_declaracion = dec.id_declaracion
INNER JOIN inspeccion_aduanera insp ON m.id_mercancia = insp.id_mercancia
WHERE m.estado_mercancia = 'bloqueada_aforo'
ORDER BY insp.fecha_inspeccion DESC;


-- CONSULTA 3: Resumen de Inventario Valorizado y Capacidad por Deposito
-- Objetivo: Analisis agregado para administradores aduaneros (volumen, peso y valor CIF total).
SELECT 
    d.codigo_deposito,
    d.nombre AS nombre_deposito,
    d.tipo_deposito,
    d.capacidad_maxima_m3,
    COUNT(m.id_mercancia) AS total_lotes_en_custodia,
    SUM(m.cantidad_bultos) AS total_bultos_unidades,
    ROUND(SUM(m.peso_bruto_kg), 2) AS peso_acumulado_kg,
    ROUND(SUM(m.valor_cif_usd), 2) AS valor_cif_total_usd
FROM deposito_aduanero d
LEFT JOIN declaracion_aduanera dec ON d.id_deposito = dec.id_deposito
LEFT JOIN mercancia_inventario m ON dec.id_declaracion = m.id_declaracion AND m.estado_mercancia != 'despachada'
GROUP BY d.id_deposito, d.codigo_deposito, d.nombre, d.tipo_deposito, d.capacidad_maxima_m3
ORDER BY valor_cif_total_usd DESC NULLS LAST;


-- CONSULTA 4: Mercancias con Levante Autorizado Pendientes de Retiro
-- Objetivo: Identificar mercancias que ya cumplieron todos los tramites y estan listas para desalmacenaje.
SELECT 
    m.codigo_bulto,
    m.descripcion_comercial,
    i.razon_social AS importador,
    i.telefono AS telefono_contacto,
    d.nombre AS deposito,
    m.ubicacion_especifica,
    dec.fecha_levante
FROM mercancia_inventario m
INNER JOIN declaracion_aduanera dec ON m.id_declaracion = dec.id_declaracion
INNER JOIN importador i ON dec.id_importador = i.id_importador
INNER JOIN deposito_aduanero d ON dec.id_deposito = d.id_deposito
WHERE m.estado_mercancia = 'con_levante'
ORDER BY dec.fecha_levante ASC;


-- ============================================================================
-- 5. PRUEBAS DE RESISTENCIA Y VALIDADORES DE RESTRICCIONES (CONSTRAINTS)
-- ============================================================================

-- VALIDACION A: Intentar insertar correo con formato invalido (Debe fallar por chk_importador_correo)
-- INSERT INTO importador (numero_identificacion, razon_social, pais_origen, telefono, correo_contacto, direccion)
-- VALUES ('9-999-999', 'Empresa Invalida', 'CR', '111', 'correo_sin_arroba', 'San Jose');

-- VALIDACION B: Intentar insertar peso negativo (Debe fallar por chk_mercancia_peso)
-- INSERT INTO mercancia_inventario (id_declaracion, id_categoria, codigo_bulto, descripcion_comercial, cantidad_bultos, peso_bruto_kg, valor_cif_usd, ubicacion_especifica)
-- VALUES (1, 1, 'BLT-TEST-FAIL', 'Carga Invalida', 10, -50.00, 1000.00, 'Bahia 1');

-- VALIDACION C: Intentar insertar canal de aforo no permitido (Debe fallar por chk_declaracion_canal)
-- INSERT INTO declaracion_aduanera (numero_declaracion, id_importador, id_deposito, tipo_regimen, canal_aforo)
-- VALUES ('DUA-ERR-001', 1, 1, 'importacion_definitiva', 'azul');
