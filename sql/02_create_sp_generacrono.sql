-- ============================================================
-- STORED PROCEDURE: GeneraCrono
-- Adaptado a la estructura real de TenebrosaOLTP
-- ============================================================

USE TenebrosaOLTP;
GO

-- Si existe, eliminarlo primero
IF EXISTS (SELECT 1 FROM sys.procedures WHERE name = 'GeneraCrono')
BEGIN
    DROP PROCEDURE GeneraCrono;
END
GO

CREATE PROCEDURE GeneraCrono
    @documento VARCHAR(20),
    @tipodoc CHAR(1),
    @NroCuotas SMALLINT
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @totalDeuda DECIMAL(18,2);
    DECLARE @cuotaBase DECIMAL(18,2);
    DECLARE @igv DECIMAL(9,2);
    DECLARE @tasaInteres DECIMAL(9,2);
    DECLARE @fechaInicio DATETIME;
    DECLARE @contador INT;
    DECLARE @importeCuota DECIMAL(18,2);
    DECLARE @interesCuota DECIMAL(18,2);
    DECLARE @igvInteres DECIMAL(18,2);
    DECLARE @fechaVence DATETIME;
    
    -- 1. Validar que el documento existe
    IF NOT EXISTS (
        SELECT 1 FROM documento 
        WHERE Documento = @documento AND TipoDoc = @tipodoc
    )
    BEGIN
        RAISERROR('El documento ingresado no existe', 16, 1);
        RETURN;
    END
    
    -- 2. Validar que no tenga cronograma previo
    IF EXISTS (
        SELECT 1 FROM cronograma 
        WHERE Documento = @documento AND TipoDoc = @tipodoc
    )
    BEGIN
        RAISERROR('El cronograma ya fue generado para este documento', 16, 1);
        RETURN;
    END
    
    -- 3. Validar número de cuotas (1-36)
    IF @NroCuotas < 1 OR @NroCuotas > 36
    BEGIN
        RAISERROR('El número de cuotas debe estar entre 1 y 36', 16, 1);
        RETURN;
    END
    
    -- 4. Obtener parámetros activos
    SELECT TOP 1 
        @igv = Igv, 
        @tasaInteres = TasaInt
    FROM parametro 
    WHERE activo = 1 
    ORDER BY Parametro DESC;
    
    IF @igv IS NULL OR @tasaInteres IS NULL
    BEGIN
        RAISERROR('No existen parámetros activos en el sistema', 16, 1);
        RETURN;
    END
    
    -- 5. Calcular total de deuda desde detadoc
    SELECT @totalDeuda = SUM(Cantidad * PrecUnit)
    FROM detadoc
    WHERE Documento = @documento AND TipoDoc = @tipodoc;
    
    IF @totalDeuda IS NULL OR @totalDeuda = 0
    BEGIN
        RAISERROR('El documento no tiene deuda asociada', 16, 1);
        RETURN;
    END
    
    -- 6. Calcular cuota base (sin interés)
    SET @cuotaBase = @totalDeuda / @NroCuotas;
    
    -- 7. Generar cronograma
    SET @contador = 1;
    SET @fechaInicio = GETDATE();
    
    WHILE @contador <= @NroCuotas
    BEGIN
        -- Calcular fecha de vencimiento (mensual)
        SET @fechaVence = DATEADD(MONTH, @contador, @fechaInicio);
        
        -- Calcular interés de la cuota
        SET @interesCuota = @cuotaBase * (@tasaInteres / 100);
        
        -- Calcular IGV del interés
        SET @igvInteres = @interesCuota * (@igv / 100);
        
        -- Importe de la cuota (base)
        SET @importeCuota = @cuotaBase;
        
        -- Insertar cuota en cronograma
        INSERT INTO cronograma (
            NroCuota, 
            Documento, 
            TipoDoc, 
            Importe, 
            Interes, 
            IgvInteres, 
            feVence, 
            Fepago, 
            estado,
            idMedioPago,
            idPuntoPago,
            idBanco
        )
        VALUES (
            @contador,
            @documento,
            @tipodoc,
            @importeCuota,
            @interesCuota,
            @igvInteres,
            @fechaVence,
            NULL,           -- Fepago se actualiza al pagar
            'p',            -- p = pendiente
            NULL,           -- idMedioPago
            NULL,           -- idPuntoPago
            NULL            -- idBanco
        );
        
        SET @contador = @contador + 1;
    END
    
    -- 8. Retornar el cronograma generado
    SELECT 
        NroCuota, 
        Importe, 
        Interes, 
        IgvInteres, 
        Importe + Interes + IgvInteres AS ValorCuota, 
        feVence,
        estado
    FROM cronograma
    WHERE Documento = @documento AND TipoDoc = @tipodoc
    ORDER BY NroCuota;
    
END
GO

PRINT '✅ Stored Procedure GeneraCrono creado exitosamente';
GO
