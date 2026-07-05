require('dotenv').config();
const { getPool, closePool } = require('../config/database');

async function testConnection() {
  console.log('==================================================');
  console.log('🔍 INICIANDO DIAGNÓSTICO DE CONEXIÓN A BASE DE DATOS');
  console.log('==================================================');
  console.log(`📡 Servidor DB : ${process.env.DB_SERVER || 'localhost'}`);
  console.log(`🔌 Puerto      : ${process.env.DB_PORT || '1433'}`);
  console.log(`🗄️ Base Datos  : ${process.env.DB_DATABASE || 'TenebrosaOLTP'}`);
  console.log(`👤 Usuario     : ${process.env.DB_USER || 'sa'}`);
  console.log('--------------------------------------------------');

  try {
    const pool = await getPool();
    console.log('✅ Conexión exitosa a SQL Server.');

    // Probar consulta básica
    const result = await pool.request().query(`
      SELECT COUNT(*) as total_tablas 
      FROM INFORMATION_SCHEMA.TABLES 
      WHERE TABLE_TYPE = 'BASE TABLE'
    `);
    
    console.log(`📊 Tablas de usuario detectadas: ${result.recordset[0].total_tablas}`);
    
    // Verificar que existen las tablas clave del proyecto
    const keyTables = ['usuarios', 'documento', 'detadoc', 'cronograma', 'parametro'];
    const tableCheck = await pool.request().query(`
      SELECT TABLE_NAME 
      FROM INFORMATION_SCHEMA.TABLES 
      WHERE TABLE_NAME IN (${keyTables.map(t => `'${t}'`).join(',')})
    `);

    const foundTables = tableCheck.recordset.map(r => r.TABLE_NAME.toLowerCase());
    console.log('--------------------------------------------------');
    console.log('📋 Estado de tablas clave del sistema:');
    
    keyTables.forEach(table => {
      if (foundTables.includes(table)) {
        console.log(`  [OK] Tabla: ${table}`);
      } else {
        console.log(`  [❌ FALTANTE] Tabla: ${table}`);
      }
    });

  } catch (error) {
    console.error('❌ Error al intentar conectar con la base de datos:');
    console.error(`   ${error.message}`);
    if (error.originalError) {
      console.error(`   Detalle: ${error.originalError.message}`);
    }
  } finally {
    await closePool();
    console.log('==================================================');
  }
}

testConnection();
