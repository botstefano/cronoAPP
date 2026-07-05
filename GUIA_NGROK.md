# Configuración de ngrok + SQL Server Local (Opción Gratuita)

## 📋 Resumen

Esta opción permite usar tu base de datos SQL Server local mientras tu PC está encendida, sin necesidad de tarjeta de crédito.

**Arquitectura:**
```
Celular (APK) → Render (Node.js) → ngrok túnel → Tu PC (SQL Server)
```

---

## 🚀 PASO 1: Instalar ngrok

### 1.1 Descargar ngrok
- Ir a https://ngrok.com/download
- Descargar para Windows
- Extraer el archivo .zip

### 1.2 Crear cuenta gratuita
- Ir a https://ngrok.com/signup
- Registrarte (gratis)
- Obtener tu authtoken del dashboard

### 1.3 Configurar ngrok
```bash
# En PowerShell, navegar al directorio de ngrok
cd C:\ruta\donde\extraiste\ngrok

# Autenticar
ngrok config add-authtoken TU_AUTH_TOKEN
```

---

## 🗄️ PASO 2: Configurar SQL Server para TCP/IP

### 2.1 Habilitar TCP/IP en SQL Server
1. Abrir **SQL Server Configuration Manager**
2. Ir a **SQL Server Network Configuration** → **Protocols for SQLEXPRESS**
3. Habilitar **TCP/IP**
4. Click derecho → **Restart** en SQL Server

### 2.2 Verificar puerto
1. En **TCP/IP Properties** → **IP Addresses**
2. Ir a **IPAll**
3. Anotar el **TCP Port** (generalmente 1433)
4. Si está vacío, poner `1433`

### 2.3 Configurar firewall de Windows
```powershell
# Ejecutar como Administrador
New-NetFirewallRule -DisplayName "SQL Server" -Direction Inbound -LocalPort 1433 -Protocol TCP -Action Allow
```

---

## 🌐 PASO 3: Iniciar ngrok para SQL Server

### 3.1 Iniciar túnel TCP
```bash
cd C:\ruta\donde\extraiste\ngrok
ngrok tcp 1433
```

### 3.2 Obtener URL de ngrok
ngrok mostrará algo como:
```
Forwarding  tcp://0.tcp.ngrok.io:12345 -> localhost:1433
```

**Anota la URL:** `0.tcp.ngrok.io:12345`

### 3.3 (Opcional) URL fija con ngrok
La versión gratuita cambia la URL cada vez. Para URL fija necesitas plan pago.

---

## ⚙️ PASO 4: Configurar Backend para ngrok

### 4.1 Actualizar .env.production
Editar `backend/.env.production`:

```env
# Servidor
PORT=3000
NODE_ENV=production

# Base de Datos SQL Server vía ngrok
DB_SERVER=0.tcp.ngrok.io
DB_PORT=12345  # Cambiar por el puerto que te dio ngrok
DB_DATABASE=TenebrosaOLTP
DB_USER=sa
DB_PASSWORD=12345
DB_ENCRYPT=false
DB_TRUST_SERVER_CERTIFICATE=true

# JWT
JWT_SECRET=cronoapp_2026_clave_secreta
JWT_EXPIRES_IN=24h

# CORS
CORS_ORIGIN=*

# Rate Limiting
RATE_LIMIT_WINDOW_MS=900000
RATE_LIMIT_MAX=100
```

**Importante:** Cada vez que reinicies ngrok, el puerto cambiará y tendrás que actualizar `DB_PORT`.

---

## 🚀 PASO 5: Desplegar Backend en Render

### 5.1 Subir código a GitHub
```bash
git add .
git commit -m "Configurado para ngrok"
git push origin main
```

### 5.2 Crear Web Service en Render
1. Render Dashboard → "New +" → "Web Service"
2. Conectar repositorio GitHub
3. Configuración:
   - Name: `cronoapp-api`
   - Build Command: `npm install`
   - Start Command: `node server.js`
4. Environment Variables (usar valores de .env.production):
   ```
   PORT=3000
   NODE_ENV=production
   DB_SERVER=0.tcp.ngrok.io
   DB_PORT=12345
   DB_DATABASE=TenebrosaOLTP
   DB_USER=sa
   DB_PASSWORD=12345
   DB_ENCRYPT=false
   DB_TRUST_SERVER_CERTIFICATE=true
   JWT_SECRET=cronoapp_2026_clave_secreta
   JWT_EXPIRES_IN=24h
   CORS_ORIGIN=*
   RATE_LIMIT_WINDOW_MS=900000
   RATE_LIMIT_MAX=100
   ```
5. "Create Web Service"

---

## 📱 PASO 6: Generar APK

Seguir los pasos en `DESPLEGUE_APK.md` y usar la URL de Render.

---

## ⚠️ PASO 7: Proceso para Usar

### Cada vez que quieras usar la app:

1. **Iniciar ngrok:**
   ```bash
   cd C:\ruta\ngrok
   ngrok tcp 1433
   ```

2. **Obtener nuevo puerto de ngrok** (cambia cada vez)

3. **Actualizar Render:**
   - Ir a Render Dashboard
   - Web Service → Environment
   - Cambiar `DB_PORT` al nuevo puerto
   - Deploy Changes

4. **Esperar a que Render redepliegue** (~2-3 minutos)

5. **Usar la app**

### Para detener:
- Cerrar ngrok (Ctrl+C)
- La app dejará de funcionar (Render no podrá conectar a tu BD)

---

## 🔧 Automatización (Opcional)

### Script para iniciar todo
Crear `iniciar_sistema.ps1`:

```powershell
# Iniciar ngrok
cd C:\ruta\ngrok
Start-Process ngrok -ArgumentList "tcp 1433"

Write-Host "ngrok iniciado. Obtén el puerto del túnel y actualiza en Render."
Write-Host "Presiona Enter para detener ngrok..."
Read-Host

# Detener ngrok
Get-Process ngrok | Stop-Process -Force
```

---

## 📊 Limitaciones de ngrok Gratuito

- ❌ URL cambia cada vez que reinicias
- ❌ Límite de conexiones simultáneas
- ❌ Tiempo de sesión limitado (~8 horas)
- ❌ Tu PC debe estar encendida siempre

---

## 💡 Alternativa: Backend Local + ngrok

Si Render tiene problemas de conexión, puedes:

1. **Correr backend local:**
   ```bash
   cd backend
   npm start
   ```

2. **Exponer backend con ngrok:**
   ```bash
   ngrok http 3000
   ```

3. **Configurar APK para usar URL de ngrok del backend**

4. **Ventaja:** Menos latencia, más control
5. **Desventaja:** Tu PC debe estar encendida y corriendo el backend

---

## 🎯 Para Presentación

**Recomendación:**
1. Iniciar ngrok 30 minutos antes
2. Actualizar Render con el puerto
3. Verificar que funcione
4. Mantener todo encendido durante la presentación
5. No cerrar ngrok hasta terminar
