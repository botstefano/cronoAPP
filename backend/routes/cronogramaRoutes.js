const express = require('express');
const router = express.Router();
const { body, param, query } = require('express-validator');
const cronogramaController = require('../controllers/cronogramaController');
const authMiddleware = require('../middleware/auth');
const { handleValidationErrors } = require('../middleware/validation');

// Todas las rutas requieren autenticación
router.use(authMiddleware);

// POST /api/cronograma/generar
router.post(
  '/generar',
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
    body('nroCuotas')
      .notEmpty().withMessage('El número de cuotas es requerido')
      .isInt({ min: 1, max: 36 }).withMessage('El número de cuotas debe ser entre 1 y 36'),
  ],
  handleValidationErrors,
  cronogramaController.generar
);

// GET /api/cronograma/historial
router.get(
  '/historial',
  [
    query('page').optional().isInt({ min: 1 }).withMessage('Página inválida'),
    query('pageSize').optional().isInt({ min: 1, max: 100 }).withMessage('Tamaño de página inválido'),
  ],
  handleValidationErrors,
  cronogramaController.historial
);

// GET /api/cronograma/:documento/:tipodoc
router.get(
  '/:documento/:tipodoc',
  [
    param('documento')
      .trim()
      .isLength({ min: 1, max: 9 }).withMessage('Documento inválido'),
    param('tipodoc')
      .trim()
      .isIn(['F', 'B', 'C']).withMessage('Tipo de documento inválido'),
  ],
  handleValidationErrors,
  cronogramaController.consultar
);

// GET /api/parametros
router.get('/parametros', cronogramaController.getParametros);

// GET /api/documentos-cliente
router.get('/documentos-cliente', cronogramaController.getDocumentosCliente);

// POST /api/documento/validar
router.post(
  '/documento/validar',
  [
    body('documento')
      .trim()
      .notEmpty().withMessage('El documento es requerido')
      .isLength({ min: 1, max: 9 }).withMessage('Documento inválido'),
    body('tipodoc')
      .trim()
      .notEmpty().withMessage('El tipo de documento es requerido')
      .isIn(['F', 'B', 'C']).withMessage('Tipo inválido'),
  ],
  handleValidationErrors,
  cronogramaController.validarDocumento
);

// POST /api/cronograma/pagar
router.post(
  '/pagar',
  [
    body('documento')
      .trim()
      .notEmpty().withMessage('El documento es requerido')
      .isLength({ min: 1, max: 9 }).withMessage('Documento inválido'),
    body('tipodoc')
      .trim()
      .notEmpty().withMessage('El tipo de documento es requerido')
      .isIn(['F', 'B', 'C']).withMessage('Tipo inválido'),
    body('nroCuota')
      .notEmpty().withMessage('El número de cuota es requerido')
      .isInt({ min: 1 }).withMessage('Número de cuota debe ser un número entero válido'),
  ],
  handleValidationErrors,
  cronogramaController.pagarCuota
);

module.exports = router;
