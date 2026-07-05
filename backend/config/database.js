const { Pool } = require('pg');

const pool = new Pool({
  host: process.env.DB_SERVER || 'localhost',
  port: parseInt(process.env.DB_PORT) || 5432,
  database: process.env.DB_DATABASE || 'postgres',
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  ssl: process.env.DB_SSL === 'true' ? { rejectUnauthorized: false } : false,
  max: 10,
  min: 0,
  connectionTimeoutMillis: 30000,
  idleTimeoutMillis: 30000,
});

// Manejo de errores de conexión
pool.on('error', (err) => {
  console.error('Unexpected error on idle client', err);
  process.exit(-1);
});

const query = async (text, params) => {
  const start = Date.now();
  try {
    const res = await pool.query(text, params);
    const duration = Date.now() - start;
    console.log('Executed query', { text, duration, rows: res.rowCount });
    return res;
  } catch (error) {
    console.error('Database query error:', error);
    throw error;
  }
};

const closePool = async () => {
  await pool.end();
  console.log('🔌 Conexión a PostgreSQL cerrada');
};

module.exports = { query, pool, closePool };