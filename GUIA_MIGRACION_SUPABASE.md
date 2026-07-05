# Guía de Migración SQL Server → Supabase (PostgreSQL)

## ⚠️ Advertencia Importante

Esta migración requiere:
- **Reescribir todo el backend** (cambiar driver mssql → pg)
- **Migrar 228K+ registros** manualmente
- **Reescribir stored procedures** (SQL Server → PostgreSQL)
- **Adaptar tipos de datos** y sintaxis SQL
- **Tiempo estimado:** 10-20 horas de trabajo

**Solo recomendado si:**
- Tienes tiempo disponible
- Quieres aprender PostgreSQL
- Necesitas una solución gratuita permanente

---

## 📋 Paso 1: Crear Cuenta en Supabase

### 1.1 Registrarse
1. Ir a https://supabase.com
2. Click en "Start your project"
3. Registrarse con GitHub (gratis)
4. Crear organización (gratis)

### 1.2 Crear Proyecto
1. Click en "New Project"
2. Configuración:
   - Name: `cronoapp`
   - Database Password: (crear contraseña segura)
   - Region: Southeast Asia (o cercano a tu ubicación)
3. Click en "Create new project"
4. Esperar 1-2 minutos mientras se crea

---

## 🗄️ PASO 2: Migración de Esquema (Estructura de Tablas)

### 2.1 Analizar esquema actual SQL Server

Tu esquema actual tiene estas tablas:
- `parametro` (2 registros)
- `documento` (228,262 registros)
- `detadoc` (228,262 registros)
- `cronograma` (228,262 registros)
- `usuarios` (2 registros)

### 2.2 Convertir tipos de datos SQL Server → PostgreSQL

| SQL Server | PostgreSQL | Notas |
|------------|-------------|-------|
| `nvarchar` | `varchar` | PostgreSQL usa varchar para texto |
| `int` | `integer` | Compatible |
| `decimal` | `numeric` | Compatible |
| `datetime` | `timestamp` | Compatible |
| `bit` | `boolean` | Compatible |
| `char` | `char` | Compatible |

### 2.3 Crear tablas en Supabase

**Opción A: Usar SQL Editor de Supabase**

1. En Supabase Dashboard → SQL Editor
2. Ejecutar este script para crear las tablas:

```sql
-- Tabla parametro
CREATE TABLE parametro (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    valor VARCHAR(100) NOT NULL
);

-- Tabla documento
CREATE TABLE documento (
    documento VARCHAR(50) PRIMARY KEY,
    tipodoc VARCHAR(20) NOT NULL,
    proveedor VARCHAR(100),
    pedido VARCHAR(50),
    cliente VARCHAR(100),
    fecha DATE NOT NULL,
    estado VARCHAR(20),
    docrefer VARCHAR(50),
    personal VARCHAR(50),
    pagado BOOLEAN DEFAULT FALSE,
    idtienda VARCHAR(20),
    formapago VARCHAR(50),
    hora TIME
);

-- Tabla detadoc
CREATE TABLE detadoc (
    documento VARCHAR(50) NOT NULL,
    tipodoc VARCHAR(20) NOT NULL,
    producto VARCHAR(100),
    cantidad INTEGER,
    igv NUMERIC(10,2),
    precunit NUMERIC(10,2),
    PRIMARY KEY (documento, tipodoc, producto)
);

-- Tabla cronograma
CREATE TABLE cronograma (
    nrocuota INTEGER PRIMARY KEY,
    documento VARCHAR(50) NOT NULL,
    tipodoc VARCHAR(20) NOT NULL,
    importe NUMERIC(10,2),
    interes NUMERIC(10,2),
    igvinteres NUMERIC(10,2),
    fevence DATE,
    fepago DATE,
    estado VARCHAR(20),
    idmediopago VARCHAR(20),
    idpunto VARCHAR(20),
    idbanco VARCHAR(20)
);

-- Tabla usuarios
CREATE TABLE usuarios (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    nombre VARCHAR(100),
    rol VARCHAR(20) DEFAULT 'user',
    creado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Índices para mejorar rendimiento
CREATE INDEX idx_documento_tipodoc ON documento(tipodoc);
CREATE INDEX idx_documento_fecha ON documento(fecha);
CREATE INDEX idx_detadoc_documento ON detadoc(documento);
CREATE INDEX idx_cronograma_documento ON cronograma(documento);
```

---

## 📊 PASO 3: Migración de Datos

### 3.1 Exportar datos de SQL Server

**Opción A: Usar SQL Server Management Studio**

1. SSMS → Click derecho en base de datos → Tasks → Export Data
2. Elegir destino: Flat File (CSV)
3. Exportar cada tabla por separado:
   - `parametro.csv`
   - `documento.csv`
   - `detadoc.csv`
   - `cronograma.csv`
   - `usuarios.csv`

**Opción B: Usar PowerShell**

```powershell
# Exportar tabla parametro
sqlcmd -S .\SQLEXPRESS -U sa -P 12345 -d TenebrosaOLTP -Q "SELECT * FROM parametro" -o parametro.csv -s "," -W

# Exportar tabla documento (puede tardar por 228K registros)
sqlcmd -S .\SQLEXPRESS -U sa -P 12345 -d TenebrosaOLTP -Q "SELECT * FROM documento" -o documento.csv -s "," -W

# Exportar otras tablas...
```

### 3.2 Importar datos a Supabase

**Opción A: Usar CSV Import de Supabase**

1. Supabase Dashboard → Table Editor
2. Click en "Import data from CSV"
3. Seleccionar el archivo CSV
4. Mapear columnas
5. Importar

**Opción B: Usar SQL Editor**

```sql
-- Importar parametro
COPY parametro(nombre, valor)
FROM 'C:/ruta/parametro.csv'
DELIMITER ','
CSV HEADER;

-- Importar documento (puede tardar)
COPY documento(documento, tipodoc, proveedor, pedido, cliente, fecha, estado, docrefer, personal, pagado, idtienda, formapago, hora)
FROM 'C:/ruta/documento.csv'
DELIMITER ','
CSV HEADER;

-- Importar otras tablas...
```

**⚠️ Nota:** Para 228K+ registros, la importación puede tardar varias horas.

---

## 🔧 PASO 4: Reescribir Backend (Node.js)

### 4.1 Cambiar dependencias

```bash
cd backend
npm uninstall mssql
npm install pg
```

### 4.2 Actualizar database.js

**Archivo:** `backend/config/database.js`

```javascript
const { Pool } = require('pg');

const pool = new Pool({
  host: process.env.DB_SERVER || 'localhost',
  port: parseInt(process.env.DB_PORT) || 5432,
  database: process.env.DB_DATABASE || 'cronoapp',
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  ssl: process.env.DB_SSL === 'true' ? { rejectUnauthorized: false } : false,
  max: 10,
  min: 0,
  connectionTimeoutMillis: 30000,
  idleTimeoutMillis: 30000,
});

module.exports = {
  query: (text, params) => pool.query(text, params),
  pool,
  close: () => pool.end(),
};
```

### 4.3 Actualizar modelos

**Archivo ejemplo:** `backend/models/User.js`

```javascript
// Cambiar sintaxis SQL Server → PostgreSQL
const db = require('../config/database');

const User = {
  async findByUsername(username) {
    const result = await db.query(
      'SELECT * FROM usuarios WHERE username = $1',
      [username]
    );
    return result.rows[0];
  },

  async create(userData) {
    const { username, password_hash, nombre, rol } = userData;
    const result = await db.query(
      'INSERT INTO usuarios (username, password_hash, nombre, rol) VALUES ($1, $2, $3, $4) RETURNING *',
      [username, password_hash, nombre, rol || 'user']
    );
    return result.rows[0];
  },
  // ... otros métodos
};

module.exports = User;
```

### 4.4 Cambios de sintaxis SQL

**SQL Server → PostgreSQL:**

| SQL Server | PostgreSQL |
|------------|-------------|
| `SELECT TOP 5 *` | `SELECT * LIMIT 5` |
| `@parametro` | `$1, $2, $3` |
| `GETDATE()` | `NOW()` |
| `@@IDENTITY` | `RETURNING *` |
| `ISNULL()` | `COALESCE()` |

---

## 🔄 PASO 5: Reescribir Stored Procedures

### 5.1 Stored Procedure GeneraCrono

**SQL Server (actual):**
```sql
CREATE PROCEDURE GeneraCrono
    @Documento VARCHAR(50),
    @TipoDoc VARCHAR(20)
AS
BEGIN
    -- Lógica SQL Server
END
```

**PostgreSQL (equivalente):**
```sql
CREATE OR REPLACE FUNCTION GeneraCrono(p_documento VARCHAR, p_tipodoc VARCHAR)
RETURNS VOID AS $$
BEGIN
    -- Lógica PostgreSQL
    INSERT INTO cronograma (nrocuota, documento, tipodoc, importe, ...)
    VALUES (...);
END;
$$ LANGUAGE plpgsql;
```

### 5.2 Llamar función en backend

```javascript
// SQL Server
await pool.request()
  .input('Documento', sql.VarChar, documento)
  .input('TipoDoc', sql.VarChar, tipodoc)
  .execute('GeneraCrono');

// PostgreSQL
await db.query('SELECT GeneraCrono($1, $2)', [documento, tipodoc]);
```

---

## ⚙️ PASO 6: Actualizar Configuración

### 6.1 Actualizar .env.production

```env
# Servidor
PORT=3000
NODE_ENV=production

# Base de Datos Supabase (PostgreSQL)
DB_SERVER=tu-proyecto.supabase.co
DB_PORT=5432
DB_DATABASE=postgres
DB_USER=postgres
DB_PASSWORD=tu_password_supabase
DB_SSL=true

# JWT
JWT_SECRET=cambiar_esto_por_clave_segura_en_produccion
JWT_EXPIRES_IN=24h

# CORS
CORS_ORIGIN=https://tu-app-render.onrender.com

# Rate Limiting
RATE_LIMIT_WINDOW_MS=900000
RATE_LIMIT_MAX=100
```

### 6.2 Obtener credenciales de Supabase

1. Supabase Dashboard → Settings → Database
2. Copiar:
   - Connection string
   - Host
   - Database name
   - Username
   - Password

---

## 🧪 PASO 7: Pruebas

### 7.1 Probar conexión local

```bash
cd backend
npm start
```

### 7.2 Probar endpoints

```bash
curl http://localhost:3000/api/health
curl -X POST http://localhost:3000/api/auth/login -H "Content-Type: application/json" -d '{"username":"admin","password":"Admin123!"}'
```

### 7.3 Probar generación de cronograma

```bash
curl -X POST http://localhost:3000/api/cronograma/generar \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer TU_TOKEN" \
  -d '{"documento":"DOC001","tipodoc":"FV","importe":1000,"cuotas":12}'
```

---

## 📊 Resumen de Cambios Requeridos

### Archivos a modificar en backend:
- `package.json` - Cambiar mssql → pg
- `config/database.js` - Reescribir configuración
- `models/User.js` - Cambiar sintaxis SQL
- `models/Cronograma.js` - Cambiar sintaxis SQL y stored procedure
- `controllers/authController.js` - Ajustar consultas
- `controllers/cronogramaController.js` - Ajustar consultas
- `routes/*.js` - Sin cambios (solo validaciones)

### Tiempo estimado:
- Migración de esquema: 2-3 horas
- Migración de datos: 2-4 horas
- Reescritura backend: 6-10 horas
- Pruebas y debugging: 2-3 horas
- **Total: 12-20 horas**

---

## 💡 Alternativa: Usar Supabase sin reescribir backend

**NO es posible** porque:
- Supabase solo soporta PostgreSQL
- Tu backend está escrito específicamente para SQL Server
- No hay traductor automático SQL Server → PostgreSQL

---

## 🎯 ¿Vale la pena?

**Sí, si:**
- Tienes 12-20 horas disponibles
- Quieres aprender PostgreSQL
- Necesitas solución gratuita permanente
- Es un proyecto personal/educativo

**No, si:**
- Tienes prisa para la tarea universitaria
- Solo necesitas una solución temporal
- Prefieres usar SQL Server en el futuro

**Para tu tarea universitaria:** Recomiendo usar ngrok (2-3 horas de configuración) en lugar de migrar a Supabase (12-20 horas).
