const jwt = require('jsonwebtoken');
const User = require('../models/User');
const logger = require('../config/logger');

const authController = {
  /**
   * POST /api/auth/login
   * Body: { username, password }
   */
  login: async (req, res) => {
    try {
      const { username, password } = req.body;

      const user = await User.findByUsername(username);
      if (!user) {
        logger.warn(`Intento de login fallido para usuario: ${username}`);
        return res.status(401).json({
          success: false,
          message: 'Credenciales incorrectas',
        });
      }

      const passwordValid = await User.validatePassword(password, user.password_hash);
      if (!passwordValid) {
        logger.warn(`Contraseña incorrecta para usuario: ${username}`);
        return res.status(401).json({
          success: false,
          message: 'Credenciales incorrectas',
        });
      }

      const token = jwt.sign(
        {
          id: user.id,
          username: user.username,
          nombre: user.nombre,
        },
        process.env.JWT_SECRET,
        { expiresIn: process.env.JWT_EXPIRES_IN || '24h' }
      );

      logger.info(`Login exitoso: ${username}`);
      res.json({
        success: true,
        data: {
          token,
          user: {
            id: user.id,
            username: user.username,
            nombre: user.nombre,
          },
          expiresIn: process.env.JWT_EXPIRES_IN || '24h',
        },
      });
    } catch (error) {
      logger.error(`Error en login: ${error.message}`);
      res.status(500).json({
        success: false,
        message: 'Error interno del servidor',
      });
    }
  },

  /**
   * GET /api/auth/me
   * Retorna los datos del usuario autenticado.
   */
  me: (req, res) => {
    res.json({
      success: true,
      data: {
        id: req.user.id,
        username: req.user.username,
        nombre: req.user.nombre,
      },
    });
  },

  /**
   * POST /api/auth/refresh
   * Renueva el token JWT.
   */
  refresh: async (req, res) => {
    try {
      const newToken = jwt.sign(
        {
          id: req.user.id,
          username: req.user.username,
          nombre: req.user.nombre,
        },
        process.env.JWT_SECRET,
        { expiresIn: process.env.JWT_EXPIRES_IN || '24h' }
      );

      res.json({
        success: true,
        data: { token: newToken },
      });
    } catch (error) {
      logger.error(`Error renovando token: ${error.message}`);
      res.status(500).json({ success: false, message: 'Error interno' });
    }
  },
};

module.exports = authController;
