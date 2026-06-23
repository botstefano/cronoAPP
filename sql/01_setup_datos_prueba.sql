-- ============================================================
-- SCRIPT DE SETUP PARA TenebrosaOLTP
-- Ejecutar en SQL Server Management Studio
-- ============================================================

USE TenebrosaOLTP;
GO

-- ─── Tabla de parámetros ────────────────────────────────────
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'parametro')
BEGIN
    CREATE TABLE parametro (
        id      INT IDENTITY(1,1) PRIMARY KEY,
        IGV     NUMERIC(9,2) NOT NULL,
        tasaint NUMERIC(9,2) NOT NULL,
        activo  BIT NOT NULL DEFAULT 1
    );
END
GO

-- ─── Tabla de documentos ────────────────────────────────────
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'documento')
BEGIN
    CREATE TABLE documento (
        documento   CHAR(9)     NOT NULL,
        tipodoc     CHAR(1)     NOT NULL,
        fechadoc    DATETIME    DEFAULT GETDATE(),
        descripcion VARCHAR(200),
        CONSTRAINT PK_documento PRIMARY KEY (documento, tipodoc)
    );
END
GO

-- ─── Tabla de detalle de documentos ─────────────────────────
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'detadoc')
BEGIN
    CREATE TABLE detadoc (
        id        INT IDENTITY(1,1) PRIMARY KEY,
        documento CHAR(9)      NOT NULL,
        tipodoc   CHAR(1)      NOT NULL,
        item      SMALLINT     NOT NULL,
        descrip   VARCHAR(200),
        cantidad  INT          NOT NULL DEFAULT 1,
        precunit  NUMERIC(9,2) NOT NULL,
        CONSTRAINT FK_detadoc_doc FOREIGN KEY (documento, tipodoc)
            REFERENCES documento(documento, tipodoc)
    );
END
GO

-- ─── Tabla de cronograma ─────────────────────────────────────
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'cronograma')
BEGIN
    CREATE TABLE cronograma (
        NroCuota   INT          NOT NULL,
        Documento  CHAR(9)      NOT NULL,
        TipoDoc    CHAR(1)      NOT NULL,
        Importe    NUMERIC(9,2) NOT NULL,
        Interes    NUMERIC(9,2) NOT NULL,
        IgvInteres NUMERIC(9,2) NOT NULL,
        feVence    DATETIME     NOT NULL,
        CONSTRAINT PK_cronograma PRIMARY KEY (NroCuota, Documento, TipoDoc)
    );
END
GO

-- ─── Tabla de usuarios (para la API) ────────────────────────
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'usuarios')
BEGIN
    CREATE TABLE usuarios (
        id            INT IDENTITY(1,1) PRIMARY KEY,
        username      VARCHAR(50)  NOT NULL UNIQUE,
        password_hash VARCHAR(255) NOT NULL,
        nombre        VARCHAR(100) NOT NULL,
        activo        BIT          NOT NULL DEFAULT 1,
        created_at    DATETIME     DEFAULT GETDATE()
    );
END
GO

-- ─── Datos de prueba ─────────────────────────────────────────

-- Parámetros: IGV=18%, Tasa interés=2%
DELETE FROM parametro;
INSERT INTO parametro (IGV, tasaint, activo) VALUES (18.00, 2.00, 1);

-- Documentos de prueba
DELETE FROM detadoc;
DELETE FROM documento;

INSERT INTO documento (documento, tipodoc, descripcion) VALUES
('F00000001', 'F', 'Factura — Empresa XYZ'),
('F00000002', 'F', 'Factura — Cliente ABC'),
('B00000001', 'B', 'Boleta — Venta retail'),
('C00000001', 'C', 'Comprobante — Servicio');

-- Detalles (para calcular deuda)
INSERT INTO detadoc (documento, tipodoc, item, descrip, cantidad, precunit) VALUES
-- Factura F00000001: 3 items = S/ 2,000 total
('F00000001', 'F', 1, 'Laptop Dell XPS',    1,  1200.00),
('F00000001', 'F', 2, 'Monitor 27"',         1,   500.00),
('F00000001', 'F', 3, 'Teclado mecánico',    5,    60.00),

-- Factura F00000002: 2 items = S/ 850 total
('F00000002', 'F', 1, 'Silla ergonómica',    2,   350.00),
('F00000002', 'F', 2, 'Auriculares BT',      1,   150.00),

-- Boleta B00000001: 1 item = S/ 320 total
('B00000001', 'B', 1, 'Tablet Android 10"',  1,   320.00),

-- Comprobante C00000001: 1 item = S/ 1,500 total
('C00000001', 'C', 1, 'Servicio Desarrollo', 1,  1500.00);

GO

PRINT '✅ Datos de prueba insertados correctamente';
PRINT '';
PRINT 'Documentos disponibles para probar:';
PRINT '  F00000001 — F  (Deuda: S/ 2,000.00)';
PRINT '  F00000002 — F  (Deuda: S/ 850.00)';
PRINT '  B00000001 — B  (Deuda: S/ 320.00)';
PRINT '  C00000001 — C  (Deuda: S/ 1,500.00)';
PRINT '';
PRINT 'Parámetros: IGV=18%, Tasa interés=2%';
GO

-- ─── Verificación del SP ─────────────────────────────────────
-- Probar: EXEC GeneraCrono 'F00000001', 'F', 6
-- Resultado esperado: 6 cuotas de S/333.33 c/u
