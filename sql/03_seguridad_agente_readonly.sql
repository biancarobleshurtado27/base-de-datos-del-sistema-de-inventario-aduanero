-- ============================================================================
-- LABORATORIO: SISTEMA DE INVENTARIO ADUANERO
-- ARCHIVO: 03_seguridad_agente_readonly.sql
-- DESCRIPCION: Configuracion de permisos de Minimo Privilegio (Principle of Least Privilege).
--              Garantiza que el agente de consulta unicamente disponga de permisos
--              SELECT, bloqueando categoricamente INSERT, UPDATE, DELETE, TRUNCATE y DDL.
-- ============================================================================

-- 1. CREACION DE ROL / USUARIO DE LECTURA EXCLUSIVA
-- NOTA DE SEGURIDAD DOCENTE:
-- La contrasena debe definirse como variable de entorno o reemplazarse al momento del despliegue.
-- No se incluyen contrasenas reales en este script entregable.
DO
$$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'agente_consulta') THEN
        CREATE ROLE agente_consulta WITH LOGIN PASSWORD 'CAMBIAR_EN_DESPLIEGUE_SEGURO_2026!';
    END IF;
END
$$;

-- 2. REVOCACION PREVENTIVA DE PRIVILEGIOS POR DEFECTO
REVOKE ALL ON SCHEMA public FROM PUBLIC;
REVOKE ALL ON ALL TABLES IN SCHEMA public FROM agente_consulta;
REVOKE ALL ON ALL SEQUENCES IN SCHEMA public FROM agente_consulta;
REVOKE ALL ON ALL FUNCTIONS IN SCHEMA public FROM agente_consulta;

-- 3. ASIGNACION ESTRICTA DE SOLO LECTURA (SELECT)
GRANT USAGE ON SCHEMA public TO agente_consulta;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO agente_consulta;

-- 4. PRIVILEGIOS POR DEFECTO PARA FUTURAS TABLAS
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO agente_consulta;

-- ============================================================================
-- 5. PRUEBAS DE VALIDACION DE PRIVILEGIOS (EVIDENCIA DE REGLA)
-- ============================================================================
-- Para verificar la efectividad, ejecutar en psql o cliente conectado como 'agente_consulta':
--
-- PRUEBA 1 (DEBE FUNCIONAR):
-- SELECT id_mercancia, codigo_bulto, descripcion_comercial, estado_mercancia FROM mercancia_inventario LIMIT 3;
--
-- PRUEBA 2 (DEBE FALLAR CON "permission denied for table"):
-- INSERT INTO mercancia_inventario (id_declaracion, id_categoria, codigo_bulto, descripcion_comercial, cantidad_bultos, peso_bruto_kg, valor_cif_usd, ubicacion_especifica)
-- VALUES (1, 1, 'BLT-HACK-001', 'Intento no autorizado', 1, 10, 100, 'X');
--
-- PRUEBA 3 (DEBE FALLAR CON "permission denied for table"):
-- UPDATE mercancia_inventario SET estado_mercancia = 'despachada' WHERE id_mercancia = 5;
--
-- PRUEBA 4 (DEBE FALLAR CON "permission denied for table"):
-- DELETE FROM mercancia_inventario WHERE id_mercancia = 1;
--
-- PRUEBA 5 (DEBE FALLAR CON "must be owner of table"):
-- DROP TABLE mercancia_inventario;
-- ============================================================================
