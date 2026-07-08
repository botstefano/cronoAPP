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

// POST /api/auth/register
router.post(
  '/register',
  [
    body('cliente')
      .trim()
      .notEmpty().withMessage('El código de cliente es requerido')
      .isLength({ min: 3, max: 10 }).withMessage('El código de cliente debe tener entre 3 y 10 caracteres')
      .matches(/^CL\d{2}$/i).withMessage('El código de cliente debe tener formato CL00 (ej: CL01, CL02)'),
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

module.exports = router;
