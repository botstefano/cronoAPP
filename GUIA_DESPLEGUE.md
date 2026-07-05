# Guía de Despliegue Completo - CronoApp

## 📋 Resumen del Proceso

**Opción 1: Azure SQL (Requiere tarjeta de crédito)**
1. **Azure SQL Database** - Importar bacpac (30 días trial)
2. **Render** - Desplegar backend Node.js (gratis)
3. **Flutter** - Generar APK Android (gratis)
4. **Configuración** - Conectar todo

**Opción 2: ngrok + SQL Server Local (Totalmente gratis)**
1. **ngrok** - Exponer SQL Server local (gratis)
2. **Render** - Desplegar backend Node.js (gratis)
3. **Flutter** - Generar APK Android (gratis)
4. **Configuración** - Conectar todo
5. **Limitación:** Tu PC debe estar encendida, URL cambia cada reinicio

**Opción 3: IP Pública + Port Forwarding (Totalmente gratis)**
1. **IP Pública** - Exponer SQL Server local (gratis)
2. **Render** - Desplegar backend Node.js (gratis)
3. **Flutter** - Generar APK Android (gratis)
4. **Configuración** - Conectar todo
5. **Limitación:** Tu PC debe estar encendida, requiere configuración de router

**Para tu tarea universitaria, recomiendo Opción 3 (IP Pública) - totalmente gratis, sin tarjeta de crédito, y URL estable.**

---

## 🌐 OPCIÓN 2: ngrok + SQL Server Local (Totalmente Gratis)

**Ver guía completa en `GUIA_NGROK.md`**

### Resumen rápido:

1. **Instalar ngrok** - Descargar de https://ngrok.com/download
2. **Configurar SQL Server** - Habilitar TCP/IP en SQL Server Configuration Manager
3. **Iniciar ngrok** - Ejecutar `.\iniciar_ngrok.ps1` o `ngrok tcp 1433`
4. **Obtener puerto** - ngrok mostrará el puerto (ej: 12345)
5. **Actualizar Render** - Cambiar `DB_PORT` en Render con el puerto de ngrok
6. **Usar la app** - APK conectará a Render → ngrok → tu PC

**Para presentación:**
- Iniciar ngrok 30 minutos antes
- Mantener PC encendida durante toda la presentación
- No cerrar ngrok hasta terminar

---

## 🌐 OPCIÓN 3: IP Pública + Port Forwarding (Totalmente Gratis)

**Ver guía completa en `GUIA_IP_PUBLICA.md`**

### Resumen rápido:

1. **Obtener IP pública** - Visitar https://whatismyip.com
2. **Configurar SQL Server** - Habilitar TCP/IP en SQL Server Configuration Manager
3. **Configurar firewall** - Abrir puerto 1433 en Windows Firewall
4. **Configurar router** - Port forwarding del puerto 1433 a tu PC
5. **Actualizar .env.production** - Usar tu IP pública como DB_SERVER
6. **Desplegar en Render** - Usar variables de entorno de opción 3

**Para presentación:**
- Configurar todo con anticipación (router, firewall, SQL Server)
- Mantener PC encendida durante toda la presentación
- URL estable (no cambia como ngrok)

**Ventajas:**
- URL estable (no cambia)
- Sin límites de tiempo
- Totalmente gratis

**Desventajas:**
- Configuración más compleja (router)
- Menos seguro (expone IP pública)
- Tu PC debe estar encendida

---

## 🗄️ OPCIÓN 1: Azure SQL Database (30 días trial - Requiere tarjeta de crédito)

### 1.1 Crear cuenta Azure
- Ir a https://portal.azure.com
- Crear cuenta nueva con email estudiantil (si aplica)
- Obtener $200 crédito gratis por 30 días

### 1.2 Crear servidor SQL
1. Azure Portal → "SQL Servers" → "Create"
2. Configuración:
   - Server name: `cronoapp-server` (o nombre único)
   - Location: East US (o cercano a tu ubicación)
   - Authentication: SQL authentication
   - Admin username: `sqladmin`
   - Password: (crear contraseña segura)
3. Review + Create

### 1.3 Crear base de datos
1. En el servidor creado → "Databases" → "Create"
2. Configuración:
   - Database name: `TenebrosaOLTP`
   - Compute + storage: "Basic" (5GB, ~$5/mes)
3. Review + Create

### 1.4 Configurar firewall
1. En el servidor → "Firewalls and virtual networks"
2. Agregar regla:
   - Rule name: `Render`
   - Start IP: `0.0.0.0`
   - End IP: `255.255.255.255`
   - (Permite acceso desde cualquier IP - para desarrollo)
3. "Save"

### 1.5 Importar archivo bacpac
1. En la base de datos creada → "Overview"
2. Click en "Import database"
3. Seleccionar tu archivo `.bacpac`
4. Esperar el proceso (puede tardar varios minutos)

### 1.6 Obtener datos de conexión
1. En la base de datos → "Connection strings"
2. Copiar el "ADO.NET (SQL Authentication)" string
3. Extraer los datos:
   - Server: `cronoapp-server.database.windows.net`
   - Database: `TenebrosaOLTP`
   - Username: `sqladmin`
   - Password: (tu contraseña)

---

## 🚀 PASO 2: Desplegar Backend en Render

### 2.1 Preparar código para GitHub
```bash
# Asegurarse de que todo esté commiteado
git add .
git commit -m "Preparado para despliegue en producción"
git push origin main
```

### 2.2 Crear cuenta en Render
- Ir a https://render.com
- Crear cuenta con GitHub
- Conectar tu repositorio

### 2.3 Crear Web Service
1. Render Dashboard → "New +" → "Web Service"
2. Conectar tu repositorio GitHub
3. Configuración:
   - Name: `cronoapp-api`
   - Region: Oregon (o cercano)
   - Branch: `main`
   - Runtime: `Node`
   - Build Command: `npm install`
   - Start Command: `node server.js`
4. "Advanced" → "Environment Variables":
   ```
   PORT=3000
   NODE_ENV=production
   DB_SERVER=tu-servidor-azure.database.windows.net
   DB_PORT=1433
   DB_DATABASE=TenebrosaOLTP
   DB_USER=sqladmin
   DB_PASSWORD=tu_password_azure
   DB_ENCRYPT=true
   DB_TRUST_SERVER_CERTIFICATE=false
   JWT_SECRET=cambiar_esto_por_clave_segura_aleatoria
   JWT_EXPIRES_IN=24h
   CORS_ORIGIN=*
   RATE_LIMIT_WINDOW_MS=900000
   RATE_LIMIT_MAX=100
   ```
5. "Create Web Service"

### 2.4 Verificar despliegue
- Esperar a que Render termine el build
- Obtener la URL: `https://cronoapp-api.onrender.com`
- Probar: `https://cronoapp-api.onrender.com/api/health`

---

## 📱 PASO 3: Generar APK Android

### 3.1 Configurar Keystore (ver DESPLEGUE_APK.md)
```bash
cd flutter_app/android
keytool -genkey -v -keystore key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias key
```

### 3.2 Crear archivo key.properties
Crear `flutter_app/android/key.properties`:
```properties
storePassword=TU_CONTRASEÑA
keyPassword=TU_CONTRASEÑA
keyAlias=key
storeFile=key.jks
```

### 3.3 Configurar build.gradle
Editar `flutter_app/android/app/build.gradle.kts` (ver DESPLEGUE_APK.md para detalles)

### 3.4 Actualizar URL de producción
Editar `flutter_app/lib/services/api_service.dart`:
```dart
static const bool _isProduction = true;
static const String _productionUrl = 'https://cronoapp-api.onrender.com/api';
```

### 3.5 Generar APK
```bash
cd flutter_app
flutter build apk --release
```

### 3.6 Instalar en celular
- El APK estará en: `flutter_app/build/app/outputs/flutter-apk/app-release.apk`
- Transferir al celular (USB, email, Google Drive)
- Habilitar "Instalar apps de fuentes desconocidas" en el celular
- Instalar el APK

---

## ✅ PASO 4: Pruebas Finales

### 4.1 Probar backend
```bash
curl https://cronoapp-api.onrender.com/api/health
```

### 4.2 Probar login en la app
- Abrir la app en el celular
- Intentar login con usuario: `admin` / `Admin123!`
- Verificar que funcione

### 4.3 Probar generación de cronograma
- Seleccionar un documento
- Generar cronograma
- Verificar que se muestre correctamente

---

## 🗑️ PASO 5: Limpieza (después de la tarea)

### Importante - Borrar recursos para no pagar
1. **Azure:**
   - Borrar base de datos
   - Borrar servidor SQL
   - Cancelar suscripción si no la necesitas

2. **Render:**
   - Puedes dejar el servicio (es gratis)
   - O borrarlo si no lo necesitas

---

## 📞 Solución de Problemas

### Backend no inicia en Render
- Verificar logs en Render Dashboard
- Revisar variables de entorno
- Verificar que la base de datos sea accesible

### APK no conecta al backend
- Verificar que `_isProduction = true` en api_service.dart
- Verificar que la URL de Render sea correcta
- Verificar que el backend esté corriendo

### Error de conexión a Azure SQL
- Verificar firewall en Azure
- Verificar credenciales
- Verificar que la base de datos exista

---

## 💰 Costos Totales

- **Azure SQL (30 días):** $0 (trial)
- **Render:** $0 (tier gratuito)
- **APK:** $0
- **Total:** $0 (si borras todo antes de 30 días)

---

## 📚 Archivos de Referencia

- `DESPLEGUE_APK.md` - Configuración detallada de keystore
- `backend/.env.production` - Plantilla de variables de entorno
- `flutter_app/lib/services/api_service.dart` - Configuración de API URL
