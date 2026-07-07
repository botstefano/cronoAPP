require('dotenv').config();
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const rateLimit = require('express-rate-limit');
const { closePool } = require('./config/database');
const logger = require('./config/logger');

// Rutas
const authRoutes = require('./routes/authRoutes');
const cronogramaRoutes = require('./routes/cronogramaRoutes');

const app = express();
const PORT = process.env.PORT || 3000;

// Trust proxy para Render - configuración específica para evitar bypass de rate limiting
// Usamos 1 para confiar en el primer proxy (Render)
app.set('trust proxy', 1);

// ─── Seguridad ───────────────────────────────────────────────
app.use(helmet());
app.use(cors({
  origin: process.env.CORS_ORIGIN || '*',
  methods: ['GET', 'POST', 'PUT', 'DELETE'],
  allowedHeaders: ['Content-Type', 'Authorization'],
}));

// Rate limiting global
const limiter = rateLimit({
  windowMs: parseInt(process.env.RATE_LIMIT_WINDOW_MS) || 15 * 60 * 1000,
  max: parseInt(process.env.RATE_LIMIT_MAX) || 100,
  message: {
    success: false,
    message: 'Demasiadas peticiones. Por favor espere unos minutos.',
  },
  standardHeaders: true,
  legacyHeaders: false,
});
app.use('/api/', limiter);

// Rate limiting estricto para login
const loginLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutos
  max: 10,
  message: {
    success: false,
    message: 'Demasiados intentos de login. Intente en 15 minutos.',
  },
});
app.use('/api/auth/login', loginLimiter);

// ─── Middleware general ───────────────────────────────────────
app.use(express.json({ limit: '10kb' }));
app.use(express.urlencoded({ extended: true }));
app.use(morgan('combined', {
  stream: { write: (msg) => logger.info(msg.trim()) },
}));

// ─── Rutas ───────────────────────────────────────────────────
app.use('/api/auth', authRoutes);
app.use('/api/cronograma', cronogramaRoutes);

// Ruta de salud
app.get('/api/health', (req, res) => {
  res.json({
    success: true,
    message: 'API de Cronogramas funcionando correctamente',
    timestamp: new Date().toISOString(),
    version: require('./package.json').version,
  });
});

// ─── 404 handler ─────────────────────────────────────────────
app.use((req, res) => {
  res.status(404).json({
    success: false,
    message: `Ruta no encontrada: ${req.method} ${req.originalUrl}`,
  });
});

// ─── Error handler global ────────────────────────────────────
app.use((err, req, res, next) => {
  logger.error(`Error no manejado: ${err.stack}`);
  res.status(500).json({
    success: false,
    message: 'Error interno del servidor',
    ...(process.env.NODE_ENV === 'development' && { detail: err.message }),
  });
});

// ─── Iniciar servidor ────────────────────────────────────────
const server = app.listen(PORT, () => {
  logger.info(`🚀 Servidor corriendo en puerto ${PORT} [${process.env.NODE_ENV || 'development'}]`);
  logger.info(`📋 Health check: http://localhost:${PORT}/api/health`);
});

// Graceful shutdown
process.on('SIGTERM', async () => {
  logger.info('SIGTERM recibido. Cerrando servidor...');
  server.close(async () => {
    await closePool();
    logger.info('Servidor cerrado correctamente');
    process.exit(0);
  });
});

process.on('unhandledRejection', (reason, promise) => {
  logger.error(`Unhandled Rejection at: ${promise}, reason: ${reason}`);
});

module.exports = app;
