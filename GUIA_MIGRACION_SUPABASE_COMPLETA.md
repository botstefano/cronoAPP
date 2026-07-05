# Guía Completa de Migración a Supabase + Render

## ✅ Migración Completada - Código Backend Adaptado

He adaptado todo el backend para usar Supabase (PostgreSQL) en lugar de SQL Server.

**Archivos modificados:**
- `backend/package.json` - Cambiado `mssql` → `pg`
- `backend/config/database.js` - Reescrito para PostgreSQL
- `backend/models/User.js` - Reescrito para PostgreSQL
- `backend/models/Cronograma.js` - Reescrito para PostgreSQL
- `backend/.env.production` - Configurado para Supabase

**Archivos nuevos creados:**
- `supabase_schema.sql` - Esquema de tablas para Supabase
- `supabase_function_generacrono.sql` - Función GeneraCrono en PostgreSQL

---

## 📋 Pasos para Completar la Migración

### PASO 1: Crear Cuenta y Proyecto en Supabase

1. Ir a https://supabase.com
2. Click en "Start your project"
3. Registrarse con GitHub (gratis)
4. Crear nuevo proyecto:
   - Name: `cronoapp`
   - Database Password: (crear contraseña segura)
   - Region: Southeast Asia (o cercano a tu ubicación)
5. Esperar 1-2 minutos mientras se crea

### PASO 2: Ejecutar Scripts SQL en Supabase

1. En Supabase Dashboard → SQL Editor
2. Ejecutar `supabase_schema.sql` para crear las tablas
3. Ejecutar `supabase_function_generacrono.sql` para crear la función GeneraCrono
4. Ejecutar `supabase_data_prueba.sql` para insertar datos de prueba con deudas

**Nota sobre los datos de prueba:**
- El script inserta 30 clientes con deudas variadas
- Distribución: 10 clientes con deuda alta, 10 con deuda media, 10 con deuda baja
- TODOS los clientes tienen deuda (ninguno pagado completamente)
- Solo pueden registrarse usuarios que tengan deuda pendiente
- Documentos no existentes en la base de datos NO pueden registrarse (validación en backend)
- Usuario admin: `admin` / `Admin123!`
- Usuario prueba (CL01): `F00100001` / `Cliente123!` (ya creado para testear, sin cronograma)
- Los demás clientes (CL02-CL30) deben registrarse usando su documento
- **Los cronogramas se generan dinámicamente** usando la función GeneraCrono cuando los clientes lo soliciten a través de la API

### PASO 3: Obtener Credenciales de Supabase

1. Supabase Dashboard → Settings → Database
2. Copiar:
   - Connection string
   - Host (ej: `abcxyz.supabase.co`)
   - Database name: `postgres`
   - Username: `postgres`
   - Password

### PASO 4: Migrar Datos de SQL Server a Supabase

**Opción A: Exportar desde SQL Server e Importar a Supabase**

1. **Exportar datos de SQL Server:**
```powershell
# Exportar tabla parametro
sqlcmd -S .\SQLEXPRESS -U sa -P 12345 -d TenebrosaOLTP -Q "SELECT * FROM parametro" -o parametro.csv -s "," -W

# Exportar tabla usuarios
sqlcmd -S .\SQLEXPRESS -U sa -P 12345 -d TenebrosaOLTP -Q "SELECT id, username, password_hash, nombre, activo, created_at FROM usuarios" -o usuarios.csv -s "," -W
```

2. **Importar a Supabase:**
   - Supabase Dashboard → Table Editor
   - Click en "Import data from CSV"
   - Seleccionar el archivo CSV
   - Mapear columnas
   - Importar

**Opción B: Usar datos de prueba (sin migrar datos reales)**

Si no necesitas los 228K+ registros, puedes usar datos de prueba:

```sql
-- Insertar datos de prueba en Supabase SQL Editor
INSERT INTO parametro (parametro, igv, tasaint, tasalegal, fecha, tasadolar, activo, vencidos)
VALUES (1, 0.18, 0.05, 0.10, CURRENT_TIMESTAMP, 3.75, true, 0);

-- Insertar usuario admin
INSERT INTO usuarios (username, password_hash, nombre, activo)
VALUES ('admin', '$2a$10$rOZjGxWxWxWxWxWxWxWxWuWxWxWxWxWxWxWxWxWxWxWxWxWxW', 'Administrador', true);
```

### PASO 5: Actualizar .env.production

Editar `backend/.env.production` con tus credenciales reales de Supabase:

```env
DB_SERVER=tu-proyecto-real.supabase.co
DB_PORT=5432
DB_DATABASE=postgres
DB_USER=postgres
DB_PASSWORD=tu_password_real_supabase
DB_SSL=true
```

### PASO 6: Instalar Dependencias Nuevas

```bash
cd backend
npm install
```

Esto instalará `pg` y eliminará `mssql`.

### PASO 7: Probar Localmente con Supabase

```bash
cd backend
# Crear .env local con credenciales de Supabase
# Copiar variables de .env.production a .env

npm start
```

Probar endpoints:
```bash
curl http://localhost:3000/api/health
```

### PASO 8: Desplegar en Render usando Blueprint

**Opción A: Usando Blueprint (Recomendado - Automático)**

1. **Subir código a GitHub:**
```bash
git add .
git commit -m "Migrado a Supabase con Blueprint de Render"
git push origin main
```

2. **Crear Blueprint en Render:**
   - Ir a [Render Dashboard](https://dashboard.render.com)
   - Click en "New +" → "Blueprint"
   - Conectar el repositorio de GitHub
   - Render leerá automáticamente el archivo `render.yaml`
   - Click en "Apply Changes" para crear el servicio
   - Esperar el despliegue (2-3 minutos)

3. **Obtener URL de Render:**
   - Esperar a que Render termine el build
   - Obtener la URL: `https://cronoapp-backend.onrender.com`

**Opción B: Manual**

1. **Subir código a GitHub:**
```bash
git add .
git commit -m "Migrado a Supabase (PostgreSQL)"
git push origin main
```

2. **Crear Web Service en Render:**
   - Render Dashboard → "New +" → "Web Service"
   - Conectar repositorio GitHub
   - Configuración:
     - Build Command: `cd backend && npm install`
     - Start Command: `cd backend && npm start`
   - Environment Variables (usar valores de .env.production):
     ```
     PORT=3000
     NODE_ENV=production
     DB_SERVER=db.dcwxtyovlxdhspopbrqw.supabase.co
     DB_PORT=5432
     DB_DATABASE=postgres
     DB_USER=postgres
     DB_PASSWORD=U!VRQ8kF_/gf9Fu
     DB_SSL=true
     JWT_SECRET=cronoapp_2026_clave_secreta
     JWT_EXPIRES_IN=24h
     CORS_ORIGIN=*
     RATE_LIMIT_WINDOW_MS=900000
     RATE_LIMIT_MAX=100
     ```
   - "Create Web Service"

3. **Obtener URL de Render:**
   - Esperar a que Render termine el build
   - Obtener la URL: `https://cronoapp-api.onrender.com`

### PASO 9: Generar APK

1. **Actualizar API URL en Flutter:**
   - Editar `flutter_app/lib/services/api_service.dart`
   - Cambiar `_isProduction = true`
   - Cambiar `_productionUrl` a tu URL de Render

2. **Generar APK:**
```bash
cd flutter_app
flutter build apk --release
```

3. **Instalar en celular:**
   - APK estará en: `flutter_app/build/app/outputs/flutter-apk/app-release.apk`
   - Transferir al celular e instalar

---

## 📊 Resumen de Cambios en el Código

### Cambios de Sintaxis SQL Server → PostgreSQL

| SQL Server | PostgreSQL |
|------------|-------------|
| `SELECT TOP 5 *` | `SELECT * LIMIT 5` |
| `@parametro` | `$1, $2, $3` |
| `GETDATE()` | `NOW()` |
| `@@IDENTITY` | `RETURNING *` |
| `ISNULL()` | `COALESCE()` |
| `recordset` | `rows` |
| `rowsAffected` | `rowCount` |
| `request().input()` | Parámetros en array |
| `execute('SP')` | `SELECT * FROM function()` |

### Archivos Modificados

**backend/package.json:**
- ❌ `"mssql": "^10.0.2"`
- ✅ `"pg": "^8.11.3"`

**backend/config/database.js:**
- ❌ `const sql = require('mssql')`
- ✅ `const { Pool } = require('pg')`
- ❌ `pool.request().input()`
- ✅ `query(text, params)`

**backend/models/User.js:**
- ❌ `const pool = await getPool()`
- ✅ `const result = await query()`
- ❌ `@username`
- ✅ `$1`
- ❌ `result.recordset[0]`
- ✅ `result.rows[0]`

**backend/models/Cronograma.js:**
- ❌ `execute('GeneraCrono')`
- ✅ `SELECT * FROM GeneraCrono($1, $2, $3)`
- ❌ `GETDATE()`
- ✅ `NOW()`
- ❌ `TOP 1`
- ✅ `LIMIT 1`

---

## ⚠️ Notas Importantes

### Sobre la Migración de Datos

**Si migras los 228K+ registros:**
- La migración puede tardar varias horas
- Supabase tiene límites en el tier gratuito (500MB)
- Considera migrar solo datos de prueba para tu tarea

**Si usas datos de prueba:**
- Más rápido (5-10 minutos)
- Suficiente para demostrar funcionalidad
- Puedes migrar datos reales más tarde si lo necesitas

### Sobre la Función GeneraCrono

La función PostgreSQL `GeneraCrono` que creé:
- ✅ Genera cronogramas automáticamente
- ✅ Calcula intereses e IGV
- ✅ Crea cuotas con fechas de vencimiento
- ✅ Valida que no exista cronograma previo
- ⚠️ Usa lógica simplificada (30 días por cuota)

Puedes ajustar la lógica según tus necesidades específicas.

---

## 🎯 Ventajas de Supabase + Render

- ✅ **Totalmente gratis** (Supabase: 500MB, Render: tier gratuito)
- ✅ **Sin tarjeta de crédito**
- ✅ **Base de datos en la nube** (no depende de tu PC)
- ✅ **URL estable** (no cambia como ngrok)
- ✅ **Escalable** (puedes crecer si lo necesitas)
- ✅ **Profesional** (infraestructura moderna)

---

## 📞 ¿Necesitas Ayuda?

Si encuentras problemas:
1. Verifica que las credenciales de Supabase sean correctas
2. Asegúrate de que los scripts SQL se ejecutaron correctamente
3. Revisa los logs de Render si hay errores de conexión
4. Prueba localmente antes de desplegar en Render

---

## 🔄 Revertir Cambios (si necesario)

Si necesitas volver a SQL Server:

```bash
cd backend
git checkout HEAD -- package.json config/database.js models/User.js models/Cronograma.js
npm install
```

Luego actualiza `.env.production` para usar SQL Server nuevamente.
