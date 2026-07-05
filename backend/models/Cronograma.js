const { sql, getPool } = require('../config/database');
const logger = require('../config/logger');

class Cronograma {
  /**
   * Ejecuta el stored procedure GeneraCrono y retorna el cronograma generado.
   */
  static async generar(documento, tipodoc, nroCuotas) {
    try {
      const pool = await getPool();
      const result = await pool
        .request()
        .input('documento', sql.VarChar(20), documento)
        .input('tipodoc', sql.Char(1), tipodoc)
        .input('NroCuotas', sql.SmallInt, nroCuotas)
        .execute('GeneraCrono');

      return result.recordset;
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
      const pool = await getPool();
      const result = await pool
        .request()
        .input('documento', sql.VarChar(20), documento)
        .input('tipodoc', sql.Char(1), tipodoc)
        .query(
          `SELECT NroCuota, Importe, Interes, IgvInteres, 
                  Importe + Interes + IgvInteres AS ValorCuota, feVence, estado
           FROM cronograma
           WHERE Documento = @documento AND TipoDoc = @tipodoc
           ORDER BY NroCuota`
        );
      return result.recordset;
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
      const pool = await getPool();
      const offset = (page - 1) * pageSize;
      const result = await pool
        .request()
        .input('cliente', sql.VarChar(100), cliente)
        .input('documento', sql.VarChar(20), documento)
        .input('offset', sql.Int, offset)
        .input('pageSize', sql.Int, pageSize)
        .query(
          `SELECT 
             c.Documento AS documento, 
             c.TipoDoc AS tipodoc,
             COUNT(c.NroCuota) AS totalCuotas,
             SUM(c.Importe) AS totalImporte,
             SUM(c.Importe + c.Interes + c.IgvInteres) AS totalConInteres,
             MIN(c.feVence) AS primerVencimiento,
             MAX(c.feVence) AS ultimoVencimiento,
             d.Cliente AS cliente
           FROM cronograma c
           LEFT JOIN documento d ON c.Documento = d.Documento AND c.TipoDoc = d.TipoDoc
           WHERE d.Cliente = @cliente OR c.Documento = @documento
           GROUP BY c.Documento, c.TipoDoc, d.Cliente
           ORDER BY MIN(c.feVence) DESC
           OFFSET @offset ROWS FETCH NEXT @pageSize ROWS ONLY`
        );
      
      const countResult = await pool
        .request()
        .input('cliente', sql.VarChar(100), cliente)
        .input('documento', sql.VarChar(20), documento)
        .query(
          `SELECT COUNT(DISTINCT c.Documento + c.TipoDoc) AS total 
           FROM cronograma c
           LEFT JOIN documento d ON c.Documento = d.Documento AND c.TipoDoc = d.TipoDoc
           WHERE d.Cliente = @cliente OR c.Documento = @documento`
        );
      
      return {
        data: result.recordset,
        total: countResult.recordset[0].total,
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
      const pool = await getPool();
      const result = await pool
        .request()
        .input('documento', sql.VarChar(20), documento)
        .input('tipodoc', sql.Char(1), tipodoc)
        .query(
          `SELECT d.Documento, d.TipoDoc, d.Cliente, d.pagado,
                  (SELECT SUM(dd.Cantidad * dd.PrecUnit)
                   FROM detadoc dd
                   WHERE dd.Documento = d.Documento AND dd.TipoDoc = d.TipoDoc) AS totalDeuda
           FROM documento d
           WHERE d.Documento = @documento AND d.TipoDoc = @tipodoc`
        );
      return result.recordset[0] || null;
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
      const pool = await getPool();
      const result = await pool
        .request()
        .query(`SELECT TOP 1 Igv, TasaInt FROM parametro WHERE activo = 1 ORDER BY Parametro DESC`);
      return result.recordset[0] || null;
    } catch (error) {
      logger.error(`Error obteniendo parámetros: ${error.message}`);
      throw error;
    }
  }
}

module.exports = Cronograma;
