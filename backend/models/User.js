const { sql, getPool } = require('../config/database');
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
      const pool = await getPool();
      const result = await pool
        .request()
        .input('username', sql.VarChar(50), username)
        .query(
          `SELECT id, username, password_hash, nombre, activo 
           FROM usuarios 
           WHERE username = @username AND activo = 1`
        );
      return result.recordset[0] || null;
    } catch (error) {
      logger.error(`Error buscando usuario ${username}: ${error.message}`);
      throw error;
    }
  }

  static async register(username, passwordHash, nombre) {
    try {
      const pool = await getPool();
      const result = await pool
        .request()
        .input('username', sql.VarChar(50), username)
        .input('password_hash', sql.VarChar(255), passwordHash)
        .input('nombre', sql.VarChar(100), nombre)
        .query(
          `INSERT INTO usuarios (username, password_hash, nombre, activo)
           VALUES (@username, @password_hash, @nombre, 1)`
        );
      return result.rowsAffected[0] > 0;
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
      const pool = await getPool();
      let query = 'UPDATE usuarios SET nombre = @nombre';
      const request = pool.request()
        .input('id', sql.Int, id)
        .input('nombre', sql.VarChar(100), nombre);
      
      if (passwordHash) {
        query += ', password_hash = @password_hash';
        request.input('password_hash', sql.VarChar(255), passwordHash);
      }
      
      query += ' WHERE id = @id';
      
      const result = await request.query(query);
      return result.rowsAffected[0] > 0;
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
      const pool = await getPool();
      const hashedPwd = await this.hashPassword('Admin123!');
      await pool
        .request()
        .input('username', sql.VarChar(50), 'admin')
        .input('password_hash', sql.VarChar(255), hashedPwd)
        .input('nombre', sql.VarChar(100), 'Administrador')
        .query(
          `IF NOT EXISTS (SELECT 1 FROM usuarios WHERE username = @username)
           INSERT INTO usuarios (username, password_hash, nombre, activo)
           VALUES (@username, @password_hash, @nombre, 1)`
        );
      logger.info('Usuario demo creado o ya existente');
    } catch (error) {
      logger.warn(`No se pudo crear usuario demo: ${error.message}`);
    }
  }
}

module.exports = User;
