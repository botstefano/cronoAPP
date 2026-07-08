-- Actualizar contraseña del usuario F00100001 a "Cliente123!"
-- Ejecutar este script en el SQL Editor de Supabase
-- https://supabase.com/dashboard/project/dcwxtyovlxdhspopbrqw/sql

UPDATE usuarios 
SET password_hash = '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy'
WHERE username = 'F00100001';

-- Verificar la actualización
SELECT username, nombre, activo, cliente_id 
FROM usuarios 
WHERE username = 'F00100001';
