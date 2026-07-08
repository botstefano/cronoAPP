require('dotenv').config({ path: '.env.production' });
const { Pool } = require('pg');

const pool = new Pool({
  host: process.env.DB_SERVER || 'localhost',
  port: parseInt(process.env.DB_PORT) || 5432,
  database: process.env.DB_DATABASE || 'postgres',
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  ssl: process.env.DB_SSL === 'true' ? { rejectUnauthorized: false } : false,
});

async function updatePassword() {
  try {
    console.log('🔌 Conectando a Supabase...');
    console.log('📍 Host:', process.env.DB_SERVER);
    
    const result = await pool.query(
      `UPDATE usuarios 
       SET password_hash = $1
       WHERE username = $2
       RETURNING username, nombre`,
      ['$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy', 'F00100001']
    );
    
    if (result.rowCount > 0) {
      console.log('✅ Contraseña actualizada exitosamente!');
      console.log('👤 Usuario:', result.rows[0].username);
      console.log('👤 Nombre:', result.rows[0].nombre);
      console.log('🔑 Nueva contraseña: Cliente123!');
    } else {
      console.log('❌ Usuario no encontrado');
    }
    
    await pool.end();
    process.exit(0);
  } catch (error) {
    console.error('❌ Error:', error.message);
    await pool.end();
    process.exit(1);
  }
}

updatePassword();
