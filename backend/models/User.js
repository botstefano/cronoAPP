const { query } = require('../config/database');
const bcrypt = require('bcryptjs');
const logger = require('../config/logger');

class User {
  /**
   * Busca un usuario por username en la base de datos.
   * NOTA: Se asume una tabla 'usuarios' con columnas: id, username, password_hash, nombre, activo
   * Si no existe, se puede adaptar a la estructura real.
   */
  static async findByUsername(username) {
    try {
      const result = await query(
        `SELECT id, username, password_hash, nombre, activo 
         FROM usuarios 
         WHERE username = $1 AND activo = true`,
        [username]
      );
      return result.rows[0] || null;
    } catch (error) {
      logger.error(`Error buscando usuario ${username}: ${error.message}`);
      throw error;
    }
  }

  static async register(username, passwordHash, nombre) {
    try {
      const result = await query(
        `INSERT INTO usuarios (username, password_hash, nombre, activo)
         VALUES ($1, $2, $3, true)
         RETURNING id`,
        [username, passwordHash, nombre]
      );
      return result.rowCount > 0;
    } catch (error) {
      logger.error(`Error registrando usuario ${username}: ${error.message}`);
      throw error;
    }
  }

  static async validatePassword(plainPassword, hashedPassword) {
    return bcrypt.compare(plainPassword, hashedPassword);
  }

  static async hashPassword(plainPassword) {
    return bcrypt.hash(plainPassword, 12);
  }

  static async updateProfile(id, nombre, passwordHash) {
    try {
      let queryText = 'UPDATE usuarios SET nombre = $1';
      const params = [nombre];
      let paramIndex = 2;

      if (passwordHash) {
        queryText += ', password_hash = $' + paramIndex;
        params.push(passwordHash);
        paramIndex++;
      }
      
      queryText += ' WHERE id = $' + paramIndex;
      params.push(id);
      
      const result = await query(queryText, params);
      return result.rowCount > 0;
    } catch (error) {
      logger.error(`Error actualizando perfil de usuario ID ${id}: ${error.message}`);
      throw error;
    }
  }

  /**
   * Crea usuario de prueba (solo para desarrollo/seed)
   */
  static async createDemoUser() {
    try {
      const hashedPwd = await this.hashPassword('Admin123!');
      await query(
        `INSERT INTO usuarios (username, password_hash, nombre, activo)
         VALUES ($1, $2, $3, true)
         ON CONFLICT (username) DO NOTHING`,
        ['admin', hashedPwd, 'Administrador']
      );
      logger.info('Usuario demo creado o ya existente');
    } catch (error) {
      logger.warn(`No se pudo crear usuario demo: ${error.message}`);
    }
  }

  /**
   * Verifica si un cliente tiene deuda pendiente en la base de datos
   * Solo pueden registrarse usuarios que tengan deuda
   */
  static async clienteTieneDeuda(clienteId) {
    try {
      const result = await query(
        `SELECT 
          COUNT(DISTINCT d.documento) as total_documentos,
          SUM(d.pagado) as total_pagado,
          (SELECT SUM(dd.cantidad * dd.precunit)
           FROM detadoc dd
           WHERE dd.documento IN (SELECT documento FROM documento WHERE cliente = $1)) as total_deuda
         FROM documento d
         WHERE d.cliente = $1`,
        [clienteId]
      );

      if (result.rows.length === 0) {
        return false; // Cliente no existe
      }

      const row = result.rows[0];
      const totalDeuda = parseFloat(row.total_deuda || 0);
      const totalPagado = parseFloat(row.total_pagado || 0);

      // Tiene deuda si el total pagado es menor que el total de deuda
      // O si tiene documentos sin pagar completamente
      return totalPagado < totalDeuda;
    } catch (error) {
      logger.error(`Error verificando deuda del cliente ${clienteId}: ${error.message}`);
      throw error;
    }
  }
}

module.exports = User;
