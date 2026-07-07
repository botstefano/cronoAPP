const express = require('express');
const router = express.Router();
const { body } = require('express-validator');
const authController = require('../controllers/authController');
const authMiddleware = require('../middleware/auth');
const { handleValidationErrors } = require('../middleware/validation');
const bcrypt = require('bcryptjs');

// POST /api/auth/login
router.post(
  '/login',
  [
    body('username')
      .trim()
      .notEmpty().withMessage('El usuario es requerido')
      .isLength({ min: 3, max: 50 }).withMessage('El usuario debe tener entre 3 y 50 caracteres'),
    body('password')
      .notEmpty().withMessage('La contraseña es requerida')
      .isLength({ min: 6 }).withMessage('La contraseña debe tener al menos 6 caracteres'),
  ],
  handleValidationErrors,
  authController.login
);

// POST /api/auth/register
router.post(
  '/register',
  [
    body('documento')
      .trim()
      .notEmpty().withMessage('El número de documento es requerido')
      .isLength({ min: 1, max: 9 }).withMessage('El documento debe tener máximo 9 caracteres')
      .matches(/^[A-Z0-9]+$/i).withMessage('El documento solo puede contener letras y números'),
    body('tipodoc')
      .trim()
      .notEmpty().withMessage('El tipo de documento es requerido')
      .isLength({ min: 1, max: 1 }).withMessage('El tipo de documento debe ser un carácter')
      .isIn(['F', 'B', 'C']).withMessage('Tipo de documento inválido. Use F, B o C'),
    body('password')
      .notEmpty().withMessage('La contraseña es requerida')
      .isLength({ min: 6 }).withMessage('La contraseña debe tener al menos 6 caracteres'),
  ],
  handleValidationErrors,
  authController.register
);

// GET /api/auth/me (protegido)
router.get('/me', authMiddleware, authController.me);

// POST /api/auth/refresh (protegido)
router.post('/refresh', authMiddleware, authController.refresh);

// PUT /api/auth/profile (protegido)
router.put(
  '/profile',
  authMiddleware,
  [
    body('nombre')
      .trim()
      .notEmpty().withMessage('El nombre es requerido')
      .isLength({ min: 3, max: 100 }).withMessage('El nombre debe tener entre 3 y 100 caracteres'),
    body('newPassword')
      .optional({ checkFalsy: true })
      .isLength({ min: 6 }).withMessage('La nueva contraseña debe tener al menos 6 caracteres'),
  ],
  handleValidationErrors,
  authController.updateProfile
);

// TEMPORAL: Endpoint para actualizar contraseña de prueba
// DELETE ESTE ENDPOINT DESPUÉS DE USAR
router.post('/reset-test-password', async (req, res) => {
  try {
    const { query } = require('../config/database');
    const hash = bcrypt.hashSync('Cliente123!', 10);
    
    const result = await query(
      `UPDATE usuarios 
       SET password_hash = $1
       WHERE username = $2
       RETURNING username, nombre`,
      [hash, 'F00100001']
    );
    
    if (result.rowCount > 0) {
      res.json({
        success: true,
        message: 'Contraseña actualizada',
        user: result.rows[0],
        hash: hash
      });
    } else {
      res.status(404).json({ success: false, message: 'Usuario no encontrado' });
    }
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
});

module.exports = router;
