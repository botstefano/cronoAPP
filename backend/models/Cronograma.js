const { query } = require('../config/database');
const logger = require('../config/logger');

class Cronograma {
  /**
   * Ejecuta la función GeneraCrono y retorna el cronograma generado.
   */
  static async generar(documento, tipodoc, nroCuotas) {
    try {
      const result = await query(
        `SELECT * FROM GeneraCrono($1, $2, $3)`,
        [documento, tipodoc, nroCuotas]
      );
      return result.rows;
    } catch (error) {
      logger.error(`Error ejecutando GeneraCrono: ${error.message}`);
      throw error;
    }
  }

  /**
   * Consulta un cronograma ya generado.
   */
  static async consultar(documento, tipodoc) {
    try {
      const result = await query(
        `SELECT nrocuota, importe, interes, igvinteres, 
                importe + interes + igvinteres AS valorcuota, fevence, estado
         FROM cronograma
         WHERE documento = $1 AND tipodoc = $2
         ORDER BY nrocuota`,
        [documento, tipodoc]
      );
      return result.rows;
    } catch (error) {
      logger.error(`Error consultando cronograma: ${error.message}`);
      throw error;
    }
  }

  /**
   * Lista todos los cronogramas (agrupados por documento).
   */
  static async historial(cliente, documento, page = 1, pageSize = 20) {
    try {
      const offset = (page - 1) * pageSize;
      const result = await query(
        `SELECT 
           c.documento, 
           c.tipodoc,
           COUNT(c.nrocuota) AS "totalCuotas",
           SUM(c.importe) AS "totalImporte",
           SUM(c.importe + c.interes + c.igvinteres) AS "totalConInteres",
           MIN(c.fevence) AS "primerVencimiento",
           MAX(c.fevence) AS "ultimoVencimiento",
           d.cliente
         FROM cronograma c
         LEFT JOIN documento d ON c.documento = d.documento AND c.tipodoc = d.tipodoc
         WHERE d.cliente = $1 OR c.documento = $2
         GROUP BY c.documento, c.tipodoc, d.cliente
         ORDER BY MIN(c.fevence) DESC
         LIMIT $3 OFFSET $4`,
        [cliente, documento, pageSize, offset]
      );
      
      const countResult = await query(
        `SELECT COUNT(DISTINCT c.documento || c.tipodoc) AS total 
         FROM cronograma c
         LEFT JOIN documento d ON c.documento = d.documento AND c.tipodoc = d.tipodoc
         WHERE d.cliente = $1 OR c.documento = $2`,
        [cliente, documento]
      );
      
      return {
        data: result.rows,
        total: parseInt(countResult.rows[0].total),
        page,
        pageSize,
      };
    } catch (error) {
      logger.error(`Error obteniendo historial: ${error.message}`);
      throw error;
    }
  }

  /**
   * Verifica si un documento existe en la tabla documento.
   */
  static async validarDocumento(documento, tipodoc) {
    try {
      const result = await query(
        `SELECT d.documento, d.tipodoc, d.cliente, d.pagado,
                (SELECT SUM(dd.cantidad * dd.precunit)
                 FROM detadoc dd
                 WHERE dd.documento = d.documento AND dd.tipodoc = d.tipodoc) AS totaldeuda
         FROM documento d
         WHERE d.documento = $1 AND d.tipodoc = $2`,
        [documento, tipodoc]
      );
      return result.rows[0] || null;
    } catch (error) {
      logger.error(`Error validando documento: ${error.message}`);
      throw error;
    }
  }

  /**
   * Obtiene los parámetros activos (IGV y tasa de interés).
   */
  static async getParametros() {
    try {
      const result = await query(
        `SELECT igv, tasaint FROM parametro WHERE activo = true ORDER BY parametro DESC LIMIT 1`
      );
      return result.rows[0] || null;
    } catch (error) {
      logger.error(`Error obteniendo parámetros: ${error.message}`);
      throw error;
    }
  }

  /**
   * Registra el pago simulado de una cuota de cronograma.
   */
  static async registrarPago(documento, tipodoc, nroCuota) {
    try {
      const result = await query(
        `UPDATE cronograma
         SET estado = 'c', fepago = NOW()
         WHERE documento = $1 AND tipodoc = $2 AND nrocuota = $3`,
        [documento, tipodoc, nroCuota]
      );
      return result.rowCount > 0;
    } catch (error) {
      logger.error(`Error registrando pago de cuota: ${error.message}`);
      throw error;
    }
  }

  /**
   * Obtiene todos los documentos de un cliente
   */
  static async getDocumentosCliente(clienteId) {
    try {
      const result = await query(
        `SELECT 
           d.documento, 
           d.tipodoc,
           (SELECT SUM(dd.cantidad * dd.precunit)
           FROM detadoc dd
           WHERE dd.documento = d.documento AND dd.tipodoc = d.tipodoc) AS totalDeuda,
           d.pagado,
           d.fecha
         FROM documento d
         WHERE d.cliente = $1
         ORDER BY d.fecha DESC`,
        [clienteId]
      );
      return result.rows;
    } catch (error) {
      logger.error(`Error obteniendo documentos del cliente ${clienteId}: ${error.message}`);
      throw error;
    }
  }
}

module.exports = Cronograma;
