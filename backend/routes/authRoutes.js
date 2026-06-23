const express = require('express');
const router = express.Router();
const { body } = require('express-validator');
const authController = require('../controllers/authController');
const authMiddleware = require('../middleware/auth');
const { handleValidationErrors } = require('../middleware/validation');

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

// GET /api/auth/me (protegido)
router.get('/me', authMiddleware, authController.me);

// POST /api/auth/refresh (protegido)
router.post('/refresh', authMiddleware, authController.refresh);

module.exports = router;
