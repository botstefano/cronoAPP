-- Actualizar contraseña del usuario F00100001 a "Cliente123!"
-- Hash generado con bcrypt (cost 10)
UPDATE usuarios 
SET password_hash = '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy'
WHERE username = 'F00100001';
