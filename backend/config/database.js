const sql = require('mssql');

const dbConfig = {
  server: process.env.DB_SERVER || 'localhost',
  port: parseInt(process.env.DB_PORT) || 1433,
  database: process.env.DB_DATABASE || 'TenebrosaOLTP',
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  options: {
    encrypt: process.env.DB_ENCRYPT === 'true',
    trustServerCertificate: process.env.DB_TRUST_SERVER_CERTIFICATE === 'true',
    enableArithAbort: true,
  },
  pool: {
    max: 10,
    min: 0,
  },
  connectionTimeout: 30000,
  requestTimeout: 30000,
};

let pool = null;

const getPool = async () => {
  if (!pool) {
    pool = await sql.connect(dbConfig);
    console.log('✅ Conexión a SQL Server establecida');
  }
  return pool;
};

const closePool = async () => {
  if (pool) {
    await pool.close();
    pool = null;
    console.log('🔌 Conexión a SQL Server cerrada');
  }
};

module.exports = { sql, getPool, closePool };
