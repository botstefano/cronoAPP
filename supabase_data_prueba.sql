-- Datos de Prueba Realistas para Supabase - CronoApp
-- 30 clientes con deudas variadas
-- Solo pueden registrarse usuarios que tengan deudas en la base de datos
-- Documentos no existentes no pueden registrarse
-- Los cronogramas se generan dinámicamente usando la función GeneraCrono

-- Limpiar datos existentes (opcional)
-- TRUNCATE TABLE cronograma;
-- TRUNCATE TABLE detadoc;
-- TRUNCATE TABLE documento;
-- DELETE FROM parametro WHERE parametro > 1;
-- DELETE FROM usuarios WHERE username != 'admin';

-- ============================================
-- Tabla: PARAMETRO
-- ============================================
INSERT INTO parametro (parametro, igv, tasaint, tasalegal, fecha, tasadolar, activo, vencidos)
VALUES 
(1, 0.18, 0.05, 0.10, '2024-01-01', 3.75, true, 0)
ON CONFLICT (parametro) DO NOTHING;

-- ============================================
-- Tabla: usuarios
-- ============================================
-- Usuario admin (puede registrar usuarios)
INSERT INTO usuarios (username, password_hash, nombre, activo, cliente_id)
VALUES 
('admin', '$2a$10$rOZjGxWxWxWxWxWxWxWxWuWxWxWxWxWxWxWxWxWxWxWxWxWxW', 'Administrador', true, NULL)
ON CONFLICT (username) DO NOTHING;

-- Usuario de prueba para cliente CL01 (Juan Perez) - Documento F00100001
-- Este usuario ya está creado para testear, sin cronograma generado
-- Password: Cliente123!
INSERT INTO usuarios (username, password_hash, nombre, activo, cliente_id)
VALUES 
('F00100001', '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'Juan Perez', true, 'CL01')
ON CONFLICT (username) DO NOTHING;

-- ============================================
-- Tabla: DOCUMENTO (30 Clientes con deudas variadas)
-- ============================================

-- GRUPO 1: Deuda Alta (CL01-CL10)
-- CL01 - Juan Perez
INSERT INTO documento (documento, tipodoc, proveedor, pedido, cliente, fecha, estado, docrefer, personal, pagado, idtienda, formapago, hora)
VALUES 
('F00100001', 'F', 'PROV', 'PED001', 'CL01', '2024-01-15', 'A', NULL, '01', 0.00, '01', 'C', '10:30:00'),
('F00100002', 'F', 'PROV', 'PED002', 'CL01', '2024-02-20', 'A', NULL, '01', 0.00, '01', 'E', '14:45:00'),
('B00100001', 'B', 'PROV', 'PED003', 'CL01', '2024-03-10', 'A', NULL, '01', 300.00, '01', 'C', '09:15:00');

-- CL02 - Maria Garcia
INSERT INTO documento (documento, tipodoc, proveedor, pedido, cliente, fecha, estado, docrefer, personal, pagado, idtienda, formapago, hora)
VALUES 
('F00200001', 'F', 'PROV', 'PED004', 'CL02', '2024-02-05', 'A', NULL, '02', 0.00, '01', 'E', '11:00:00'),
('F00200002', 'F', 'PROV', 'PED005', 'CL02', '2024-04-15', 'A', NULL, '02', 0.00, '01', 'C', '16:20:00');

-- CL03 - Carlos Lopez
INSERT INTO documento (documento, tipodoc, proveedor, pedido, cliente, fecha, estado, docrefer, personal, pagado, idtienda, formapago, hora)
VALUES 
('F00300001', 'F', 'PROV', 'PED006', 'CL03', '2024-05-12', 'A', NULL, '01', 0.00, '01', 'E', '09:30:00'),
('F00300002', 'F', 'PROV', 'PED007', 'CL03', '2024-06-20', 'A', NULL, '01', 0.00, '01', 'C', '14:00:00');

-- CL04 - Ana Rodriguez
INSERT INTO documento (documento, tipodoc, proveedor, pedido, cliente, fecha, estado, docrefer, personal, pagado, idtienda, formapago, hora)
VALUES 
('F00400001', 'F', 'PROV', 'PED008', 'CL04', '2024-01-20', 'A', NULL, '02', 0.00, '01', 'C', '14:00:00'),
('F00400002', 'F', 'PROV', 'PED009', 'CL04', '2024-03-25', 'A', NULL, '02', 0.00, '01', 'E', '10:30:00');

-- CL05 - Pedro Martinez
INSERT INTO documento (documento, tipodoc, proveedor, pedido, cliente, fecha, estado, docrefer, personal, pagado, idtienda, formapago, hora)
VALUES 
('F00500001', 'F', 'PROV', 'PED010', 'CL05', '2023-10-15', 'A', NULL, '01', 0.00, '01', 'E', '10:00:00'),
('F00500002', 'F', 'PROV', 'PED011', 'CL05', '2023-11-20', 'A', NULL, '01', 0.00, '01', 'C', '15:30:00');

-- CL06 - Luisa Fernandez
INSERT INTO documento (documento, tipodoc, proveedor, pedido, cliente, fecha, estado, docrefer, personal, pagado, idtienda, formapago, hora)
VALUES 
('F00600001', 'F', 'PROV', 'PED012', 'CL06', '2024-02-10', 'A', NULL, '01', 0.00, '01', 'E', '09:00:00'),
('F00600002', 'F', 'PROV', 'PED013', 'CL06', '2024-04-20', 'A', NULL, '01', 0.00, '01', 'C', '13:45:00');

-- CL07 - Roberto Sanchez
INSERT INTO documento (documento, tipodoc, proveedor, pedido, cliente, fecha, estado, docrefer, personal, pagado, idtienda, formapago, hora)
VALUES 
('F00700001', 'F', 'PROV', 'PED014', 'CL07', '2024-03-05', 'A', NULL, '02', 0.00, '01', 'E', '11:30:00'),
('F00700002', 'F', 'PROV', 'PED015', 'CL07', '2024-05-15', 'A', NULL, '02', 0.00, '01', 'C', '15:00:00');

-- CL08 - Carmen Diaz
INSERT INTO documento (documento, tipodoc, proveedor, pedido, cliente, fecha, estado, docrefer, personal, pagado, idtienda, formapago, hora)
VALUES 
('F00800001', 'F', 'PROV', 'PED016', 'CL08', '2024-01-25', 'A', NULL, '01', 0.00, '01', 'C', '10:15:00'),
('F00800002', 'F', 'PROV', 'PED017', 'CL08', '2024-03-30', 'A', NULL, '01', 0.00, '01', 'E', '14:30:00');

-- CL09 - Miguel Torres
INSERT INTO documento (documento, tipodoc, proveedor, pedido, cliente, fecha, estado, docrefer, personal, pagado, idtienda, formapago, hora)
VALUES 
('F00900001', 'F', 'PROV', 'PED018', 'CL09', '2024-04-10', 'A', NULL, '02', 0.00, '01', 'E', '09:45:00'),
('F00900002', 'F', 'PROV', 'PED019', 'CL09', '2024-06-25', 'A', NULL, '02', 0.00, '01', 'C', '13:15:00');

-- CL10 - Patricia Ramos
INSERT INTO documento (documento, tipodoc, proveedor, pedido, cliente, fecha, estado, docrefer, personal, pagado, idtienda, formapago, hora)
VALUES 
('F01000001', 'F', 'PROV', 'PED020', 'CL10', '2024-02-15', 'A', NULL, '01', 0.00, '01', 'C', '11:00:00'),
('F01000002', 'F', 'PROV', 'PED021', 'CL10', '2024-04-25', 'A', NULL, '01', 0.00, '01', 'E', '15:30:00');

-- GRUPO 2: Deuda Media (CL11-CL20)
-- CL11 - Diego Morales
INSERT INTO documento (documento, tipodoc, proveedor, pedido, cliente, fecha, estado, docrefer, personal, pagado, idtienda, formapago, hora)
VALUES 
('F01100001', 'F', 'PROV', 'PED022', 'CL11', '2024-03-20', 'A', NULL, '01', 0.00, '01', 'E', '10:00:00');

-- CL12 - Laura Vargas
INSERT INTO documento (documento, tipodoc, proveedor, pedido, cliente, fecha, estado, docrefer, personal, pagado, idtienda, formapago, hora)
VALUES 
('F01200001', 'F', 'PROV', 'PED023', 'CL12', '2024-04-05', 'A', NULL, '02', 0.00, '01', 'C', '14:15:00');

-- CL13 - Javier Castro
INSERT INTO documento (documento, tipodoc, proveedor, pedido, cliente, fecha, estado, docrefer, personal, pagado, idtienda, formapago, hora)
VALUES 
('F01300001', 'F', 'PROV', 'PED024', 'CL13', '2024-05-10', 'A', NULL, '01', 0.00, '01', 'E', '09:30:00');

-- CL14 - Sofia Ortega
INSERT INTO documento (documento, tipodoc, proveedor, pedido, cliente, fecha, estado, docrefer, personal, pagado, idtienda, formapago, hora)
VALUES 
('F01400001', 'F', 'PROV', 'PED025', 'CL14', '2024-06-15', 'A', NULL, '02', 0.00, '01', 'C', '13:45:00');

-- CL15 - Andres Jimenez
INSERT INTO documento (documento, tipodoc, proveedor, pedido, cliente, fecha, estado, docrefer, personal, pagado, idtienda, formapago, hora)
VALUES 
('F01500001', 'F', 'PROV', 'PED026', 'CL15', '2024-02-25', 'A', NULL, '01', 0.00, '01', 'E', '10:45:00');

-- CL16 - Monica Ruiz
INSERT INTO documento (documento, tipodoc, proveedor, pedido, cliente, fecha, estado, docrefer, personal, pagado, idtienda, formapago, hora)
VALUES 
('F01600001', 'F', 'PROV', 'PED027', 'CL16', '2024-03-30', 'A', NULL, '02', 0.00, '01', 'C', '15:00:00');

-- CL17 - Ricardo Herrera
INSERT INTO documento (documento, tipodoc, proveedor, pedido, cliente, fecha, estado, docrefer, personal, pagado, idtienda, formapago, hora)
VALUES 
('F01700001', 'F', 'PROV', 'PED028', 'CL17', '2024-04-20', 'A', NULL, '01', 0.00, '01', 'E', '09:15:00');

-- CL18 - Elena Flores
INSERT INTO documento (documento, tipodoc, proveedor, pedido, cliente, fecha, estado, docrefer, personal, pagado, idtienda, formapago, hora)
VALUES 
('F01800001', 'F', 'PROV', 'PED029', 'CL18', '2024-05-25', 'A', NULL, '02', 0.00, '01', 'C', '14:30:00');

-- CL19 - Fernando Mendoza
INSERT INTO documento (documento, tipodoc, proveedor, pedido, cliente, fecha, estado, docrefer, personal, pagado, idtienda, formapago, hora)
VALUES 
('F01900001', 'F', 'PROV', 'PED030', 'CL19', '2024-06-10', 'A', NULL, '01', 0.00, '01', 'E', '10:00:00');

-- CL20 - Isabel Cruz
INSERT INTO documento (documento, tipodoc, proveedor, pedido, cliente, fecha, estado, docrefer, personal, pagado, idtienda, formapago, hora)
VALUES 
('F02000001', 'F', 'PROV', 'PED031', 'CL20', '2024-03-15', 'A', NULL, '02', 0.00, '01', 'C', '13:15:00');

-- GRUPO 3: Deuda Baja (CL21-CL30)
-- CL21 - Omar Reyes
INSERT INTO documento (documento, tipodoc, proveedor, pedido, cliente, fecha, estado, docrefer, personal, pagado, idtienda, formapago, hora)
VALUES 
('F02100001', 'F', 'PROV', 'PED032', 'CL21', '2024-04-30', 'A', NULL, '01', 0.00, '01', 'E', '11:30:00');

-- CL22 - Gladys Navarro
INSERT INTO documento (documento, tipodoc, proveedor, pedido, cliente, fecha, estado, docrefer, personal, pagado, idtienda, formapago, hora)
VALUES 
('F02200001', 'F', 'PROV', 'PED033', 'CL22', '2024-05-05', 'A', NULL, '02', 0.00, '01', 'C', '15:45:00');

-- CL23 - Victor Salazar
INSERT INTO documento (documento, tipodoc, proveedor, pedido, cliente, fecha, estado, docrefer, personal, pagado, idtienda, formapago, hora)
VALUES 
('F02300001', 'F', 'PROV', 'PED034', 'CL23', '2024-06-20', 'A', NULL, '01', 0.00, '01', 'E', '09:00:00');

-- CL24 - Rosa Benitez
INSERT INTO documento (documento, tipodoc, proveedor, pedido, cliente, fecha, estado, docrefer, personal, pagado, idtienda, formapago, hora)
VALUES 
('F02400001', 'F', 'PROV', 'PED035', 'CL24', '2024-07-10', 'A', NULL, '02', 0.00, '01', 'C', '14:15:00');

-- CL25 - Eduardo Medina
INSERT INTO documento (documento, tipodoc, proveedor, pedido, cliente, fecha, estado, docrefer, personal, pagado, idtienda, formapago, hora)
VALUES 
('F02500001', 'F', 'PROV', 'PED036', 'CL25', '2024-04-15', 'A', NULL, '01', 0.00, '01', 'E', '10:30:00');

-- CL26 - Alicia Delgado
INSERT INTO documento (documento, tipodoc, proveedor, pedido, cliente, fecha, estado, docrefer, personal, pagado, idtienda, formapago, hora)
VALUES 
('F02600001', 'F', 'PROV', 'PED037', 'CL26', '2024-05-20', 'A', NULL, '02', 0.00, '01', 'C', '13:45:00');

-- CL27 - Guillermo Romero
INSERT INTO documento (documento, tipodoc, proveedor, pedido, cliente, fecha, estado, docrefer, personal, pagado, idtienda, formapago, hora)
VALUES 
('F02700001', 'F', 'PROV', 'PED038', 'CL27', '2024-06-05', 'A', NULL, '01', 0.00, '01', 'E', '09:15:00');

-- CL28 - Teresa Vega
INSERT INTO documento (documento, tipodoc, proveedor, pedido, cliente, fecha, estado, docrefer, personal, pagado, idtienda, formapago, hora)
VALUES 
('F02800001', 'F', 'PROV', 'PED039', 'CL28', '2024-07-15', 'A', NULL, '02', 0.00, '01', 'C', '14:00:00');

-- CL29 - Hector Castillo
INSERT INTO documento (documento, tipodoc, proveedor, pedido, cliente, fecha, estado, docrefer, personal, pagado, idtienda, formapago, hora)
VALUES 
('F02900001', 'F', 'PROV', 'PED040', 'CL29', '2024-05-10', 'A', NULL, '01', 0.00, '01', 'E', '11:00:00');

-- CL30 - Silvia Lozano
INSERT INTO documento (documento, tipodoc, proveedor, pedido, cliente, fecha, estado, docrefer, personal, pagado, idtienda, formapago, hora)
VALUES 
('F03000001', 'F', 'PROV', 'PED041', 'CL30', '2024-06-25', 'A', NULL, '02', 0.00, '01', 'C', '15:30:00');

-- ============================================
-- Tabla: DETADOC (Detalles para todos los documentos)
-- ============================================
-- Detalle para CL01-CL05 (Deuda Alta)
INSERT INTO detadoc (documento, tipodoc, producto, cantidad, igv, precunit)
VALUES 
('F00100001', 'F', 'PROD1', 10.00, 18.00, 150.00),
('F00100001', 'F', 'PROD2', 5.00, 18.00, 200.00),
('F00100001', 'F', 'PROD3', 3.00, 18.00, 180.00),
('F00100002', 'F', 'PROD1', 8.00, 18.00, 150.00),
('F00100002', 'F', 'PROD4', 2.00, 18.00, 350.00),
('B00100001', 'B', 'PROD2', 15.00, 18.00, 200.00),
('B00100001', 'B', 'PROD5', 4.00, 18.00, 280.00),
('F00200001', 'F', 'PROD1', 5.00, 18.00, 150.00),
('F00200001', 'F', 'PROD3', 2.00, 18.00, 180.00),
('F00200002', 'F', 'PROD4', 10.00, 18.00, 350.00),
('F00200002', 'F', 'PROD5', 3.00, 18.00, 280.00),
('F00300001', 'F', 'PROD1', 3.00, 18.00, 150.00),
('F00300001', 'F', 'PROD2', 2.00, 18.00, 200.00),
('F00300002', 'F', 'PROD3', 5.00, 18.00, 180.00),
('F00300002', 'F', 'PROD4', 2.00, 18.00, 350.00),
('F00400001', 'F', 'PROD1', 8.00, 18.00, 150.00),
('F00400001', 'F', 'PROD4', 4.00, 18.00, 350.00),
('F00400002', 'F', 'PROD2', 6.00, 18.00, 200.00),
('F00400002', 'F', 'PROD5', 3.00, 18.00, 280.00),
('F00500001', 'F', 'PROD1', 12.00, 18.00, 150.00),
('F00500001', 'F', 'PROD2', 8.00, 18.00, 200.00),
('F00500001', 'F', 'PROD3', 5.00, 18.00, 180.00),
('F00500002', 'F', 'PROD4', 6.00, 18.00, 350.00),
('F00500002', 'F', 'PROD5', 3.00, 18.00, 280.00);

-- Detalle para CL06-CL10 (Deuda Alta)
INSERT INTO detadoc (documento, tipodoc, producto, cantidad, igv, precunit)
VALUES 
('F00600001', 'F', 'PROD1', 7.00, 18.00, 150.00),
('F00600001', 'F', 'PROD2', 4.00, 18.00, 200.00),
('F00600002', 'F', 'PROD3', 6.00, 18.00, 180.00),
('F00600002', 'F', 'PROD4', 3.00, 18.00, 350.00),
('F00700001', 'F', 'PROD1', 9.00, 18.00, 150.00),
('F00700001', 'F', 'PROD5', 2.00, 18.00, 280.00),
('F00700002', 'F', 'PROD2', 5.00, 18.00, 200.00),
('F00700002', 'F', 'PROD3', 4.00, 18.00, 180.00),
('F00800001', 'F', 'PROD4', 8.00, 18.00, 350.00),
('F00800001', 'F', 'PROD5', 3.00, 18.00, 280.00),
('F00800002', 'F', 'PROD1', 6.00, 18.00, 150.00),
('F00800002', 'F', 'PROD2', 4.00, 18.00, 200.00),
('F00900001', 'F', 'PROD3', 7.00, 18.00, 180.00),
('F00900001', 'F', 'PROD4', 2.00, 18.00, 350.00),
('F00900002', 'F', 'PROD1', 5.00, 18.00, 150.00),
('F00900002', 'F', 'PROD5', 3.00, 18.00, 280.00),
('F01000001', 'F', 'PROD2', 8.00, 18.00, 200.00),
('F01000001', 'F', 'PROD3', 4.00, 18.00, 180.00),
('F01000002', 'F', 'PROD4', 6.00, 18.00, 350.00),
('F01000002', 'F', 'PROD5', 2.00, 18.00, 280.00);

-- Detalle para CL11-CL20 (Deuda Media)
INSERT INTO detadoc (documento, tipodoc, producto, cantidad, igv, precunit)
VALUES 
('F01100001', 'F', 'PROD1', 5.00, 18.00, 150.00),
('F01100001', 'F', 'PROD2', 3.00, 18.00, 200.00),
('F01200001', 'F', 'PROD3', 4.00, 18.00, 180.00),
('F01200001', 'F', 'PROD4', 2.00, 18.00, 350.00),
('F01300001', 'F', 'PROD1', 6.00, 18.00, 150.00),
('F01300001', 'F', 'PROD5', 2.00, 18.00, 280.00),
('F01400001', 'F', 'PROD2', 4.00, 18.00, 200.00),
('F01400001', 'F', 'PROD3', 3.00, 18.00, 180.00),
('F01500001', 'F', 'PROD4', 5.00, 18.00, 350.00),
('F01500001', 'F', 'PROD5', 2.00, 18.00, 280.00),
('F01600001', 'F', 'PROD1', 7.00, 18.00, 150.00),
('F01600001', 'F', 'PROD2', 3.00, 18.00, 200.00),
('F01700001', 'F', 'PROD3', 4.00, 18.00, 180.00),
('F01700001', 'F', 'PROD4', 2.00, 18.00, 350.00),
('F01800001', 'F', 'PROD1', 6.00, 18.00, 150.00),
('F01800001', 'F', 'PROD5', 2.00, 18.00, 280.00),
('F01900001', 'F', 'PROD2', 5.00, 18.00, 200.00),
('F01900001', 'F', 'PROD3', 3.00, 18.00, 180.00),
('F02000001', 'F', 'PROD4', 4.00, 18.00, 350.00),
('F02000001', 'F', 'PROD5', 2.00, 18.00, 280.00);

-- Detalle para CL21-CL30 (Deuda Baja)
INSERT INTO detadoc (documento, tipodoc, producto, cantidad, igv, precunit)
VALUES 
('F02100001', 'F', 'PROD1', 3.00, 18.00, 150.00),
('F02100001', 'F', 'PROD2', 2.00, 18.00, 200.00),
('F02200001', 'F', 'PROD3', 4.00, 18.00, 180.00),
('F02200001', 'F', 'PROD4', 1.00, 18.00, 350.00),
('F02300001', 'F', 'PROD1', 5.00, 18.00, 150.00),
('F02300001', 'F', 'PROD5', 1.00, 18.00, 280.00),
('F02400001', 'F', 'PROD2', 3.00, 18.00, 200.00),
('F02400001', 'F', 'PROD3', 2.00, 18.00, 180.00),
('F02500001', 'F', 'PROD4', 4.00, 18.00, 350.00),
('F02500001', 'F', 'PROD5', 1.00, 18.00, 280.00),
('F02600001', 'F', 'PROD1', 6.00, 18.00, 150.00),
('F02600001', 'F', 'PROD2', 2.00, 18.00, 200.00),
('F02700001', 'F', 'PROD3', 3.00, 18.00, 180.00),
('F02700001', 'F', 'PROD4', 1.00, 18.00, 350.00),
('F02800001', 'F', 'PROD1', 5.00, 18.00, 150.00),
('F02800001', 'F', 'PROD5', 1.00, 18.00, 280.00),
('F02900001', 'F', 'PROD2', 4.00, 18.00, 200.00),
('F02900001', 'F', 'PROD3', 2.00, 18.00, 180.00),
('F03000001', 'F', 'PROD4', 3.00, 18.00, 350.00),
('F03000001', 'F', 'PROD5', 1.00, 18.00, 280.00);

-- ============================================
-- Tabla: CRONOGRAMA
-- ============================================
-- Los cronogramas se generan dinámicamente usando la función GeneraCrono
-- No se insertan cronogramas pre-generados en este script
-- Los clientes generarán sus cronogramas a través de la API cuando lo necesiten

-- ============================================
-- Resumen de datos insertados
-- ============================================
-- PARAMETRO: 1 registro
-- usuarios: 2 registros (admin + usuario de prueba CL01)
-- DOCUMENTO: 40 documentos (30 clientes)
-- DETADOC: 80 detalles
-- CRONOGRAMA: 0 cuotas (se generan dinámicamente)

-- ============================================
-- Distribución de clientes por nivel de deuda
-- ============================================
-- Deuda Alta (CL01-CL10): 10 clientes, 2-3 documentos cada uno
-- Deuda Media (CL11-CL20): 10 clientes, 1 documento cada uno
-- Deuda Baja (CL21-CL30): 10 clientes, 1 documento cada uno
-- TODOS los clientes tienen deuda (ninguno pagado completamente)

-- ============================================
-- Credenciales de prueba
-- ============================================
-- Usuario admin: admin / Admin123!
-- Usuario prueba (CL01): F00100001 / Cliente123!
-- 
-- Los demás clientes (CL02-CL30) deben registrarse usando su documento
-- Documentos no existentes no pueden registrarse (validación en backend)
-- Los cronogramas se generan dinámicamente usando la función GeneraCrono
