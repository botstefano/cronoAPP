# Configuración de IP Pública + Port Forwarding (Opción Gratuita)

## 📋 Resumen

Esta opción expone tu SQL Server local directamente a internet usando tu IP pública y port forwarding en tu router.

**Arquitectura:**
```
Celular (APK) → Render (Node.js) → Tu IP Pública:1433 → Tu PC (SQL Server)
```

---

## ⚠️ Advertencias de Seguridad

**Esta opción expone tu base de datos a internet:**
- ❌ Cualquiera podría intentar conectar a tu SQL Server
- ❌ Tu IP pública queda expuesta
- ❌ Requiere configuración de seguridad adicional

**Solo recomendado para:**
- Presentaciones temporales
- Entornos de desarrollo
- NO para producción

---

## 🌐 PASO 1: Obtener tu IP Pública

1. Ir a https://whatismyip.com
2. Copiar tu IP pública (ej: `190.45.123.45`)
3. **Anota esta IP** - la usarás en la configuración

---

## 🗄️ PASO 2: Configurar SQL Server para TCP/IP

### 2.1 Habilitar TCP/IP
1. Abrir **SQL Server Configuration Manager**
2. Ir a **SQL Server Network Configuration** → **Protocols for SQLEXPRESS**
3. Click derecho en **TCP/IP** → **Enable**
4. Click derecho en **SQL Server (SQLEXPRESS)** → **Restart**

### 2.2 Verificar puerto
1. Click derecho en **TCP/IP** → **Properties**
2. Ir a la pestaña **IP Addresses**
3. Bajar hasta **IPAll**
4. En **TCP Port**, poner `1433` (si está vacío)
5. Click en **OK**
6. Reiniciar SQL Server nuevamente

---

## 🔥 PASO 3: Configurar Firewall de Windows

```powershell
# Ejecutar como Administrador
New-NetFirewallRule -DisplayName "SQL Server" -Direction Inbound -LocalPort 1433 -Protocol TCP -Action Allow
```

### Verificar regla:
1. Abrir **Windows Defender Firewall con seguridad avanzada**
2. Ir a **Reglas de entrada**
3. Verificar que exista "SQL Server" con acción "Permitir"

---

## 📡 PASO 4: Configurar Port Forwarding en Router

### 4.1 Acceder al router
1. Abrir navegador e ir a `192.168.1.1` (o la IP de tu router)
2. Iniciar sesión (usuario: admin, contraseña: admin/admin123 - verificar en tu router)
3. Buscar sección **Port Forwarding** / **Virtual Server** / **NAT**

### 4.2 Configurar regla de port forwarding
Crear nueva regla:
- **Nombre:** SQL Server
- **Protocolo:** TCP
- **Puerto externo:** 1433
- **Puerto interno:** 1433
- **IP interna:** La IP de tu PC (ej: 192.168.1.100)
- **Habilitar:** Yes

### 4.3 Obtener IP de tu PC
```powershell
ipconfig
```
Buscar "IPv4 Address" (ej: 192.168.1.100)

### 4.4 Guardar y aplicar cambios

---

## ✅ PASO 5: Verificar Conexión

### 5.1 Verificar desde tu red local
```powershell
sqlcmd -S TU_IP_LOCAL -U sa -P 12345 -d TenebrosaOLTP -Q "SELECT @@VERSION"
```

### 5.2 Verificar desde internet (opcional)
- Pídele a un amigo que intente conectar desde su casa
- O usa tu celular con datos móviles (no WiFi)
- Ejecutar: `sqlcmd -S TU_IP_PUBLICA -U sa -P 12345 -d TenebrosaOLTP -Q "SELECT @@VERSION"`

---

## ⚙️ PASO 6: Configurar Backend

### 6.1 Actualizar .env.production
Editar `backend/.env.production`:

```env
# Servidor
PORT=3000
NODE_ENV=production

# Base de Datos SQL Azure (Opción 1 - Requiere tarjeta de crédito)
# DB_SERVER=tu-servidor-azure.database.windows.net
# DB_PORT=1433
# DB_DATABASE=TenebrosaOLTP
# DB_USER=tu_usuario_azure
# DB_PASSWORD=tu_password_azure
# DB_ENCRYPT=true
# DB_TRUST_SERVER_CERTIFICATE=false

# Base de Datos SQL Server Local via ngrok (Opción 2 - Gratis, PC debe estar encendida)
# DB_SERVER=0.tcp.ngrok.io
# DB_PORT=12345
# DB_DATABASE=TenebrosaOLTP
# DB_USER=sa
# DB_PASSWORD=12345
# DB_ENCRYPT=false
# DB_TRUST_SERVER_CERTIFICATE=true

# Base de Datos SQL Server Local via IP Pública (Opción 3 - Gratis, PC debe estar encendida)
DB_SERVER=TU_IP_PUBLICA  # Reemplazar con tu IP real (ej: 190.45.123.45)
DB_PORT=1433
DB_DATABASE=TenebrosaOLTP
DB_USER=sa
DB_PASSWORD=12345
DB_ENCRYPT=false
DB_TRUST_SERVER_CERTIFICATE=true

# JWT
JWT_SECRET=cambiar_esto_por_clave_segura_en_produccion
JWT_EXPIRES_IN=24h

# CORS - Agregar dominio de producción
CORS_ORIGIN=https://tu-app-render.onrender.com

# Rate Limiting
RATE_LIMIT_WINDOW_MS=900000
RATE_LIMIT_MAX=100
```

---

## 🚀 PASO 7: Desplegar en Render

Seguir los mismos pasos que en `GUIA_DESPLEGUE.md` pero usando las variables de entorno de la opción 3 (IP pública).

---

## 🔒 PASO 8: Seguridad Adicional (Recomendado)

### 8.1 Crear usuario específico para Render
```sql
-- En SQL Server Management Studio
USE TenebrosaOLTP;
GO

CREATE LOGIN render_user WITH PASSWORD = 'ContraseñaSegura123!';
GO

USE TenebrosaOLTP;
GO
CREATE USER render_user FOR LOGIN render_user;
GO

-- Dar permisos necesarios
ALTER ROLE db_datareader ADD MEMBER render_user;
ALTER ROLE db_datawriter ADD MEMBER render_user;
GO
```

### 8.2 Actualizar .env.production con el nuevo usuario
```env
DB_USER=render_user
DB_PASSWORD=ContraseñaSegura123!
```

### 8.3 Restringir acceso por IP (si tu router lo permite)
- Configurar el router para solo aceptar conexiones desde las IPs de Render
- Esto es más complejo y depende del modelo de router

---

## 📊 Comparación de Opciones

| Opción | Costo | Tarjeta | PC Encendida | Seguridad | Estabilidad |
|--------|-------|---------|--------------|------------|-------------|
| Azure SQL | $5-15/mes | Sí | No | Alta | Alta |
| ngrok | $0 | No | Sí | Media | Baja (cambia URL) |
| IP Pública | $0 | No | Sí | Baja | Alta |

---

## 🎯 Para Presentación

**Ventajas de IP Pública:**
- ✅ URL estable (no cambia como ngrok)
- ✅ No requiere instalar software adicional
- ✅ Totalmente gratis
- ✅ Sin límites de tiempo

**Desventajas:**
- ❌ Configuración más compleja (router)
- ❌ Menos seguro (expone IP pública)
- ❌ Tu PC debe estar encendida

**Recomendación:**
- Si tienes acceso al router y conocimientos de redes: **IP Pública**
- Si prefieres algo más simple: **ngrok**
- Si quieres algo profesional: **Azure SQL**

---

## 🗑️ Limpieza después de la presentación

1. **Eliminar regla de port forwarding** del router
2. **Eliminar regla de firewall** de Windows
3. **Deshabilitar TCP/IP** en SQL Server Configuration Manager
4. **Cambiar contraseña** del usuario SQL (si creaste uno específico)
