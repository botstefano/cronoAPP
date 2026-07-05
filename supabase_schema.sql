-- Esquema PostgreSQL para Supabase - CronoApp
-- Basado en el archivo 1.sql (SQL Server)
-- Solo incluye las tablas necesarias para el backend CronoApp

-- Habilitar extensión para UUID (si se necesita en el futuro)
-- CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Tabla: PARAMETRO
DROP TABLE IF EXISTS parametro CASCADE;
CREATE TABLE parametro (
    parametro INTEGER PRIMARY KEY,
    igv NUMERIC(8,2) NOT NULL,
    tasaint NUMERIC(8,2) NOT NULL,
    tasalegal NUMERIC(8,2) NOT NULL,
    fecha TIMESTAMP NOT NULL,
    tasadolar NUMERIC(9,2) NOT NULL,
    activo BOOLEAN NOT NULL,
    vencidos SMALLINT NOT NULL
);

-- Tabla: DOCUMENTO
DROP TABLE IF EXISTS documento CASCADE;
CREATE TABLE documento (
    documento CHAR(9) NOT NULL,
    tipodoc CHAR(1) NOT NULL,
    proveedor CHAR(4),
    pedido CHAR(9),
    cliente CHAR(4),
    fecha TIMESTAMP NOT NULL,
    estado CHAR(1) NOT NULL,
    docrefer CHAR(9),
    personal CHAR(2),
    pagado NUMERIC(9,2) NOT NULL DEFAULT 0,
    idtienda CHAR(2) NOT NULL,
    formapago CHAR(1),
    hora TIME,
    PRIMARY KEY (documento, tipodoc)
);

-- Tabla: DETADOC
DROP TABLE IF EXISTS detadoc CASCADE;
CREATE TABLE detadoc (
    documento CHAR(9) NOT NULL,
    tipodoc CHAR(1) NOT NULL,
    producto CHAR(5) NOT NULL,
    cantidad NUMERIC(9,2) NOT NULL,
    igv NUMERIC(9,2) NOT NULL,
    precunit NUMERIC(9,2) NOT NULL,
    PRIMARY KEY (documento, tipodoc, producto)
);

-- Tabla: CRONOGRAMA
DROP TABLE IF EXISTS cronograma CASCADE;
CREATE TABLE cronograma (
    nrocuota INTEGER NOT NULL,
    documento CHAR(9) NOT NULL,
    tipodoc CHAR(1) NOT NULL,
    importe NUMERIC(9,2) NOT NULL,
    interes NUMERIC(9,2) NOT NULL,
    igvinteres NUMERIC(9,2) NOT NULL,
    fevence TIMESTAMP NOT NULL,
    fepago TIMESTAMP,
    estado CHAR(1) NOT NULL,
    idmediopago CHAR(2),
    idpunto CHAR(2),
    idbanco CHAR(2),
    PRIMARY KEY (nrocuota, documento, tipodoc)
);

-- Tabla: usuarios
DROP TABLE IF EXISTS usuarios CASCADE;
CREATE TABLE usuarios (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    nombre VARCHAR(100) NOT NULL,
    activo BOOLEAN NOT NULL DEFAULT true,
    cliente_id CHAR(4), -- Referencia al cliente en tabla documento
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Índices para mejorar rendimiento
CREATE INDEX IF NOT EXISTS idx_documento_tipodoc ON documento(tipodoc);
CREATE INDEX IF NOT EXISTS idx_documento_fecha ON documento(fecha);
CREATE INDEX IF NOT EXISTS idx_documento_cliente ON documento(cliente);
CREATE INDEX IF NOT EXISTS idx_detadoc_documento ON detadoc(documento);
CREATE INDEX IF NOT EXISTS idx_cronograma_documento ON cronograma(documento);
CREATE INDEX IF NOT EXISTS idx_cronograma_estado ON cronograma(estado);

-- Datos iniciales para PARAMETRO (ejemplo)
INSERT INTO parametro (parametro, igv, tasaint, tasalegal, fecha, tasadolar, activo, vencidos)
VALUES (1, 0.18, 0.05, 0.10, CURRENT_TIMESTAMP, 3.75, true, 0)
ON CONFLICT (parametro) DO NOTHING;

-- Datos iniciales para usuarios (admin)
INSERT INTO usuarios (username, password_hash, nombre, activo)
VALUES ('admin', '$2a$10$rOZjGxWxWxWxWxWxWxWxWuWxWxWxWxWxWxWxWxWxWxWxWxWxW', 'Administrador', true)
ON CONFLICT (username) DO NOTHING;
