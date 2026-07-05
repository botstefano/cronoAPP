require('dotenv').config({ path: '.env.production' });
const { query } = require('./config/database');

async function testConnection() {
  try {
    console.log('🔌 Probando conexión a Supabase...');
    console.log('📍 Host:', process.env.DB_SERVER);
    console.log('📍 Database:', process.env.DB_DATABASE);
    console.log('📍 User:', process.env.DB_USER);
    
    const result = await query('SELECT NOW() as current_time');
    console.log('✅ Conexión exitosa!');
    console.log('🕐 Hora del servidor:', result.rows[0].current_time);
    
    // Verificar tablas
    const tables = await query(`
      SELECT table_name 
      FROM information_schema.tables 
      WHERE table_schema = 'public'
      ORDER BY table_name
    `);
    console.log('📊 Tablas en la base de datos:');
    tables.rows.forEach(row => console.log('  -', row.table_name));
    
    // Verificar usuarios
    const users = await query('SELECT COUNT(*) as count FROM usuarios');
    console.log('👥 Total usuarios:', users.rows[0].count);
    
    // Verificar documentos
    const docs = await query('SELECT COUNT(*) as count FROM documento');
    console.log('📄 Total documentos:', docs.rows[0].count);
    
    process.exit(0);
  } catch (error) {
    console.error('❌ Error de conexión:', error.message);
    process.exit(1);
  }
}

testConnection();
