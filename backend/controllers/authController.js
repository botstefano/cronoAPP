const jwt = require('jsonwebtoken');
const User = require('../models/User');
const logger = require('../config/logger');
const { sql, getPool } = require('../config/database');

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

  /**
   * POST /api/auth/register
   * Body: { documento, tipodoc, password }
   */
  register: async (req, res) => {
    try {
      const { documento, tipodoc, password } = req.body;
      const username = documento.trim();

      // 1. Verificar si el documento existe en la base de datos (tabla documento)
      const pool = await getPool();
      const docResult = await pool
        .request()
        .input('documento', sql.VarChar(20), username)
        .input('tipodoc', sql.Char(1), tipodoc)
        .query(
          `SELECT Cliente FROM documento WHERE Documento = @documento AND TipoDoc = @tipodoc`
        );

      const doc = docResult.recordset[0];
      if (!doc) {
        logger.warn(`Intento de registro fallido: documento ${username} (${tipodoc}) no existe.`);
        return res.status(400).json({
          success: false,
          message: 'El documento ingresado no existe en el sistema',
        });
      }

      // 2. Verificar si el documento ya está registrado como usuario
      const existingUser = await User.findByUsername(username);
      if (existingUser) {
        logger.warn(`Intento de registro fallido: documento ${username} ya registrado.`);
        return res.status(409).json({
          success: false,
          message: 'El documento ya está registrado en el sistema',
        });
      }

      // 3. Crear contraseña encriptada y registrar
      const passwordHash = await User.hashPassword(password);
      const nombreCliente = doc.Cliente ? doc.Cliente.trim() : `Cliente ${username}`;

      const created = await User.register(username, passwordHash, nombreCliente);
      if (!created) {
        throw new Error('No se pudo insertar el usuario');
      }

      logger.info(`Usuario registrado exitosamente: ${username} (${nombreCliente})`);
      res.status(201).json({
        success: true,
        message: 'Usuario registrado exitosamente',
      });
    } catch (error) {
      logger.error(`Error en registro: ${error.message}`);
      res.status(500).json({
        success: false,
        message: 'Error interno del servidor',
      });
    }
  },

  /**
   * PUT /api/auth/profile
   * Body: { nombre, currentPassword, newPassword }
   */
  updateProfile: async (req, res) => {
    try {
      const { nombre, currentPassword, newPassword } = req.body;
      const userId = req.user.id;

      // 1. Obtener usuario actual para validar contraseña
      const pool = await getPool();
      const userResult = await pool
        .request()
        .input('id', sql.Int, userId)
        .query('SELECT password_hash FROM usuarios WHERE id = @id');
      
      const user = userResult.recordset[0];
      if (!user) {
        return res.status(404).json({ success: false, message: 'Usuario no encontrado' });
      }

      let passwordHash = null;
      if (newPassword) {
        if (!currentPassword) {
          return res.status(400).json({ success: false, message: 'Se requiere la contraseña actual para cambiarla' });
        }
        // Validar contraseña actual
        const passwordValid = await User.validatePassword(currentPassword, user.password_hash);
        if (!passwordValid) {
          return res.status(401).json({ success: false, message: 'Contraseña actual incorrecta' });
        }
        passwordHash = await User.hashPassword(newPassword);
      }

      const updated = await User.updateProfile(userId, nombre, passwordHash);
      if (!updated) {
        return res.status(400).json({ success: false, message: 'No se pudo actualizar el perfil' });
      }

      logger.info(`Perfil actualizado para usuario ID: ${userId} (${nombre})`);
      res.json({
        success: true,
        message: 'Perfil actualizado exitosamente',
        data: {
          nombre,
        }
      });
    } catch (error) {
      logger.error(`Error actualizando perfil: ${error.message}`);
      res.status(500).json({ success: false, message: 'Error interno del servidor' });
    }
  },
};

module.exports = authController;
