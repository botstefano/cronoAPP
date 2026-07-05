const Cronograma = require('../models/Cronograma');
const logger = require('../config/logger');

const cronogramaController = {
  /**
   * POST /api/cronograma/generar
   * Body: { documento, tipodoc, nroCuotas }
   */
  generar: async (req, res) => {
    const { documento, tipodoc, nroCuotas } = req.body;
    const user = req.user.username;
    const userClient = req.user.nombre;

    try {
      logger.info(`[${user}] Generando cronograma: doc=${documento}, tipo=${tipodoc}, cuotas=${nroCuotas}`);

      // Validar que el documento pertenece al usuario
      const doc = await Cronograma.validarDocumento(documento, tipodoc);
      if (!doc) {
        return res.status(404).json({
          success: false,
          message: 'Documento ingresado no existe',
        });
      }
      if (doc.Cliente !== userClient && doc.Documento.trim() !== user) {
        logger.warn(`[${user}] Intento no autorizado de generar cronograma para doc=${documento}`);
        return res.status(403).json({
          success: false,
          message: 'No tiene permisos para operar sobre este documento',
        });
      }

      const cuotas = await Cronograma.generar(documento, tipodoc, parseInt(nroCuotas));

      const cronogramaFormateado = cuotas.map((c) => ({
        nroCuota: c.NroCuota,
        importe: parseFloat(c.Importe).toFixed(2),
        interes: parseFloat(c.Interes).toFixed(2),
        igvInteres: parseFloat(c.IgvInteres).toFixed(2),
        valorCuota: parseFloat(c.ValorCuota).toFixed(2),
        feVence: c.feVence,
        estado: c.estado,
      }));

      logger.info(`[${user}] Cronograma generado exitosamente: ${cuotas.length} cuotas`);

      res.status(201).json({
        success: true,
        data: {
          documento: documento.trim(),
          tipodoc,
          fechaGeneracion: new Date().toISOString(),
          totalCuotas: cuotas.length,
          cronograma: cronogramaFormateado,
        },
      });
    } catch (error) {
      // Los errores del SP vienen en error.message o error.originalError?.info?.message
      const spMessage =
        error.originalError?.info?.message ||
        error.message ||
        'Error desconocido';

      logger.error(`[${user}] Error generando cronograma: ${spMessage}`);

      // Detectar errores conocidos del SP
      if (spMessage.includes('no existe')) {
        return res.status(404).json({
          success: false,
          message: 'Documento ingresado no existe',
          detail: spMessage,
        });
      }
      if (spMessage.includes('ya fue generado')) {
        return res.status(409).json({
          success: false,
          message: 'El cronograma ya fue generado para este documento',
          detail: spMessage,
        });
      }
      if (spMessage.includes('parametros')) {
        return res.status(422).json({
          success: false,
          message: 'No existen parámetros activos en el sistema',
          detail: spMessage,
        });
      }

      res.status(500).json({
        success: false,
        message: 'Error al generar el cronograma',
        detail: process.env.NODE_ENV === 'development' ? spMessage : undefined,
      });
    }
  },

  /**
   * GET /api/cronograma/:documento/:tipodoc
   */
  consultar: async (req, res) => {
    const { documento, tipodoc } = req.params;
    const user = req.user.username;
    const userClient = req.user.nombre;

    try {
      // Validar que el documento pertenece al usuario
      const doc = await Cronograma.validarDocumento(documento, tipodoc);
      if (!doc) {
        return res.status(404).json({
          success: false,
          message: 'Documento no encontrado',
        });
      }
      if (doc.Cliente !== userClient && doc.Documento.trim() !== user) {
        logger.warn(`[${user}] Intento no autorizado de consultar cronograma para doc=${documento}`);
        return res.status(403).json({
          success: false,
          message: 'No tiene permisos para ver este cronograma',
        });
      }

      const cuotas = await Cronograma.consultar(documento, tipodoc);

      if (!cuotas || cuotas.length === 0) {
        return res.status(404).json({
          success: false,
          message: 'No se encontró cronograma para este documento',
        });
      }

      const cronogramaFormateado = cuotas.map((c) => ({
        nroCuota: c.NroCuota,
        importe: parseFloat(c.Importe).toFixed(2),
        interes: parseFloat(c.Interes).toFixed(2),
        igvInteres: parseFloat(c.IgvInteres).toFixed(2),
        valorCuota: parseFloat(c.ValorCuota).toFixed(2),
        feVence: c.feVence,
        estado: c.estado,
      }));

      res.json({
        success: true,
        data: {
          documento: documento.trim(),
          tipodoc,
          totalCuotas: cuotas.length,
          cronograma: cronogramaFormateado,
        },
      });
    } catch (error) {
      logger.error(`Error consultando cronograma: ${error.message}`);
      res.status(500).json({ success: false, message: 'Error interno' });
    }
  },

  /**
   * GET /api/cronograma/historial?page=1&pageSize=20
   */
  historial: async (req, res) => {
    try {
      const page = parseInt(req.query.page) || 1;
      const pageSize = Math.min(parseInt(req.query.pageSize) || 20, 100);
      const user = req.user.username;
      const userClient = req.user.nombre;

      const result = await Cronograma.historial(userClient, user, page, pageSize);

      res.json({
        success: true,
        data: result.data,
        pagination: {
          total: result.total,
          page: result.page,
          pageSize: result.pageSize,
          totalPages: Math.ceil(result.total / result.pageSize),
        },
      });
    } catch (error) {
      logger.error(`Error obteniendo historial: ${error.message}`);
      res.status(500).json({ success: false, message: 'Error interno' });
    }
  },

  /**
   * GET /api/parametros
   */
  getParametros: async (req, res) => {
    try {
      const params = await Cronograma.getParametros();

      if (!params) {
        return res.status(404).json({
          success: false,
          message: 'No existen parámetros activos configurados',
        });
      }

      res.json({
        success: true,
        data: {
          igv: parseFloat(params.Igv),
          tasaInteres: parseFloat(params.TasaInt),
        },
      });
    } catch (error) {
      logger.error(`Error obteniendo parámetros: ${error.message}`);
      res.status(500).json({ success: false, message: 'Error interno' });
    }
  },

  /**
   * POST /api/documento/validar
   * Body: { documento, tipodoc }
   */
  validarDocumento: async (req, res) => {
    const { documento, tipodoc } = req.body;
    const user = req.user.username;
    const userClient = req.user.nombre;

    try {
      const doc = await Cronograma.validarDocumento(documento, tipodoc);

      if (!doc) {
        return res.status(404).json({
          success: false,
          message: 'Documento no encontrado en el sistema',
        });
      }

      // Validar pertenencia
      if (doc.Cliente !== userClient && doc.Documento.trim() !== user) {
        logger.warn(`[${user}] Intento no autorizado de validar documento doc=${documento}`);
        return res.status(403).json({
          success: false,
          message: 'No tiene permisos sobre este documento',
        });
      }

      res.json({
        success: true,
        data: {
          documento: doc.Documento.trim(),
          tipodoc: doc.TipoDoc,
          cliente: doc.Cliente,
          pagado: parseFloat(doc.pagado || 0).toFixed(2),
          totalDeuda: parseFloat(doc.totalDeuda || 0).toFixed(2),
        },
      });
    } catch (error) {
      logger.error(`Error validando documento: ${error.message}`);
      res.status(500).json({ success: false, message: 'Error interno' });
    }
  },
};

module.exports = cronogramaController;
