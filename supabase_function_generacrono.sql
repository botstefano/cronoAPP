-- Función GeneraCrono para PostgreSQL (Supabase)
-- Equivalente al stored procedure de SQL Server

CREATE OR REPLACE FUNCTION GeneraCrono(
    p_documento CHAR(9),
    p_tipodoc CHAR(1),
    p_nrocuotas INTEGER
)
RETURNS TABLE (
    nrocuota INTEGER,
    documento CHAR(9),
    tipodoc CHAR(1),
    importe NUMERIC(9,2),
    interes NUMERIC(9,2),
    igvinteres NUMERIC(9,2),
    fevence TIMESTAMP,
    fepago TIMESTAMP,
    estado CHAR(1),
    idmediopago CHAR(2),
    idpunto CHAR(2),
    idbanco CHAR(2)
) AS $$
DECLARE
    v_igv NUMERIC(8,2);
    v_tasaint NUMERIC(8,2);
    v_totaldeuda NUMERIC(9,2);
    v_cuotabase NUMERIC(9,2);
    v_interes NUMERIC(9,2);
    v_igvinteres NUMERIC(9,2);
    v_fechainicio TIMESTAMP;
    v_i INTEGER;
BEGIN
    -- Obtener parámetros activos
    SELECT igv, tasaint INTO v_igv, v_tasaint
    FROM parametro
    WHERE activo = true
    ORDER BY parametro DESC
    LIMIT 1;
    
    -- Obtener total de deuda del documento
    SELECT SUM(dd.cantidad * dd.precunit) INTO v_totaldeuda
    FROM detadoc dd
    WHERE dd.documento = p_documento AND dd.tipodoc = p_tipodoc;
    
    -- Verificar si ya existe cronograma
    IF EXISTS (
        SELECT 1 FROM cronograma 
        WHERE documento = p_documento AND tipodoc = p_tipodoc
    ) THEN
        RAISE EXCEPTION 'El cronograma ya fue generado para este documento';
    END IF;
    
    -- Calcular cuota base
    v_cuotabase := v_totaldeuda / p_nrocuotas;
    
    -- Obtener fecha inicial (fecha del documento)
    SELECT fecha INTO v_fechainicio
    FROM documento
    WHERE documento = p_documento AND tipodoc = p_tipodoc;
    
    -- Generar cuotas
    FOR v_i IN 1..p_nrocuotas LOOP
        -- Calcular interés
        v_interes := v_cuotabase * (v_tasaint / 100);
        
        -- Calcular IGV del interés
        v_igvinteres := v_interes * v_igv;
        
        -- Calcular fecha de vencimiento (30 días por cuota)
        INSERT INTO cronograma (
            nrocuota,
            documento,
            tipodoc,
            importe,
            interes,
            igvinteres,
            fevence,
            fepago,
            estado,
            idmediopago,
            idpunto,
            idbanco
        ) VALUES (
            v_i,
            p_documento,
            p_tipodoc,
            v_cuotabase,
            v_interes,
            v_igvinteres,
            v_fechainicio + (v_i * INTERVAL '30 days'),
            NULL,
            'P', -- Pendiente
            NULL,
            NULL,
            NULL
        );
    END LOOP;
    
    -- Retornar el cronograma generado
    RETURN QUERY
    SELECT 
        nrocuota,
        documento,
        tipodoc,
        importe,
        interes,
        igvinteres,
        fevence,
        fepago,
        estado,
        idmediopago,
        idpunto,
        idbanco
    FROM cronograma
    WHERE documento = p_documento AND tipodoc = p_tipodoc
    ORDER BY nrocuota;
END;
$$ LANGUAGE plpgsql;
