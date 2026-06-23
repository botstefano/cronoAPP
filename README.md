# CronoApp — Sistema de Cronogramas de Pago

Aplicación completa (backend API + app móvil Flutter) para generar cronogramas de pago fraccionado a partir del stored procedure `GeneraCrono` en SQL Server.

---

## Arquitectura

```
┌──────────────────────────────────────────────────────┐
│                    MOBILE APP (Flutter)               │
│  LoginScreen → DashboardScreen → GenerarCrono        │
│               → HistorialScreen                      │
│  State: Provider  │  HTTP: Dio  │  Storage: SecureStorage│
└──────────────────────┬───────────────────────────────┘
                       │ HTTPS / JSON
┌──────────────────────▼───────────────────────────────┐
│              BACKEND API (Node.js + Express)          │
│  /api/auth/login        JWT Auth                     │
│  /api/cronograma/generar   → GeneraCrono SP          │
│  /api/cronograma/:doc/:tipo                          │
│  /api/cronograma/historial                           │
│  /api/parametros                                     │
│  Middleware: Helmet, Rate-limit, JWT verify          │
└──────────────────────┬───────────────────────────────┘
                       │ mssql pool
┌──────────────────────▼───────────────────────────────┐
│           SQL SERVER — TenebrosaOLTP                  │
│  SP: GeneraCrono  │  Tablas: parametro, documento    │
│                   │          detadoc, cronograma      │
└──────────────────────────────────────────────────────┘
```

---

## Estructura de archivos

```
cronograma-project/
├── backend/
│   ├── server.js              # Entry point, middleware, rutas
│   ├── .env.example           # Variables de entorno (copiar a .env)
│   ├── Dockerfile
│   ├── config/
│   │   ├── database.js        # Conexión SQL Server (pool mssql)
│   │   └── logger.js          # Winston logging
│   ├── middleware/
│   │   ├── auth.js            # JWT verify middleware
│   │   └── validation.js      # express-validator error handler
│   ├── models/
│   │   ├── User.js            # Operaciones de usuario en BD
│   │   └── Cronograma.js      # SP GeneraCrono + queries
│   ├── controllers/
│   │   ├── authController.js
│   │   └── cronogramaController.js
│   └── routes/
│       ├── authRoutes.js
│       └── cronogramaRoutes.js
├── flutter_app/
│   ├── lib/
│   │   ├── main.dart          # Entry point + AuthGate
│   │   ├── models/            # user.dart, cronograma.dart
│   │   ├── providers/         # auth_provider.dart, cronograma_provider.dart
│   │   ├── screens/           # login, dashboard, generar, historial
│   │   ├── services/          # api_service.dart (Dio)
│   │   ├── utils/             # validators.dart, app_theme.dart
│   │   └── widgets/           # cuota_card.dart, loading_widget.dart
│   └── pubspec.yaml
├── sql/
│   └── 01_setup_datos_prueba.sql
└── docs/
    ├── CronoApp_Postman_Collection.json
    └── README.md (este archivo)
```

---

## Instalación — Backend

### 1. Prerequisitos
- Node.js 18+
- SQL Server con la BD `TenebrosaOLTP` y el SP `GeneraCrono`

### 2. Configurar entorno

```bash
cd backend
cp .env.example .env
# Editar .env con tus credenciales de SQL Server y JWT_SECRET
```

### 3. Instalar dependencias e iniciar

```bash
npm install
npm run dev       # Desarrollo (nodemon)
npm start         # Producción
```

### 4. Verificar

```
GET http://localhost:3000/api/health
```

### 5. Ejecutar datos de prueba en SQL Server

```sql
-- Ejecutar: sql/01_setup_datos_prueba.sql
```

### 6. Con Docker

```bash
docker build -t cronoapp-api .
docker run -p 3000:3000 --env-file .env cronoapp-api
```

---

## Instalación — Flutter App

### 1. Prerequisitos
- Flutter SDK 3.0+
- Android Studio o VS Code con extensión Flutter

### 2. Configurar URL del backend

Editar `lib/services/api_service.dart`:

```dart
static const String baseUrl = 'http://TU_IP_O_DOMINIO:3000/api';
```

### 3. Instalar y ejecutar

```bash
cd flutter_app
flutter pub get
flutter run
```

### 4. Build para producción

```bash
# Android
flutter build apk --release

# iOS
flutter build ios --release
```

---

## Endpoints de la API

| Método | Ruta | Auth | Descripción |
|--------|------|------|-------------|
| `POST` | `/api/auth/login` | ❌ | Login → retorna JWT |
| `GET`  | `/api/auth/me` | ✅ | Perfil del usuario |
| `POST` | `/api/auth/refresh` | ✅ | Renovar token |
| `POST` | `/api/cronograma/generar` | ✅ | Ejecuta SP GeneraCrono |
| `GET`  | `/api/cronograma/:doc/:tipo` | ✅ | Consultar cronograma |
| `GET`  | `/api/cronograma/historial` | ✅ | Listar todos |
| `POST` | `/api/cronograma/documento/validar` | ✅ | Verificar documento |
| `GET`  | `/api/parametros` | ✅ | IGV y tasa vigentes |

---

## Casos de prueba

### ✅ Escenarios exitosos

```bash
# Generar cronograma — 6 cuotas para factura F00000001 (S/ 2,000)
curl -X POST http://localhost:3000/api/cronograma/generar \
  -H "Authorization: Bearer TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"documento":"F00000001","tipodoc":"F","nroCuotas":6}'

# Resultado esperado: 6 cuotas de S/ 333.33 c/u
# Interés por cuota: S/ 6.67  |  IGV del interés: S/ 1.20
```

### ❌ Escenarios de error

| Caso | Respuesta esperada |
|------|-------------------|
| Documento inexistente | 404 `Documento ingresado no existe` |
| Cronograma ya generado | 409 `El cronograma ya fue generado` |
| Sin parámetros activos | 422 `No existen parámetros activos` |
| Token inválido/expirado | 401 |
| Cuotas fuera de rango (0 o 37+) | 400 validación |

---

## Seguridad implementada

- **Bcrypt** (costo 12) para contraseñas
- **JWT** con expiración configurable
- **Helmet** — headers HTTP de seguridad
- **Rate limiting** — 100 req/15min global, 10 intentos/15min en login
- **express-validator** — sanitización de todos los inputs
- **Parámetros SQL** — todos los inputs van como parámetros tipados (no concatenación)
- **Variables de entorno** — ninguna credencial en código

---

## Variables de entorno requeridas

| Variable | Descripción | Ejemplo |
|----------|-------------|---------|
| `PORT` | Puerto del servidor | `3000` |
| `DB_SERVER` | Host SQL Server | `localhost` |
| `DB_PORT` | Puerto SQL Server | `1433` |
| `DB_DATABASE` | Nombre de BD | `TenebrosaOLTP` |
| `DB_USER` | Usuario BD | `sa` |
| `DB_PASSWORD` | Contraseña BD | `MiPassword` |
| `JWT_SECRET` | Clave secreta JWT | `cadena_aleatoria_larga` |
| `JWT_EXPIRES_IN` | Expiración token | `24h` |

---

## Credenciales demo

Después de ejecutar el SQL de setup, crear el usuario admin con:

```bash
# Desde Node.js (temporal)
node -e "
require('dotenv').config();
const User = require('./models/User');
User.createDemoUser().then(() => process.exit(0));
"
```

**Usuario:** `admin`  
**Contraseña:** `Admin123!`

---

## Despliegue en producción

### Backend en Render.com

1. Conectar repositorio GitHub
2. Crear Web Service → Node.js
3. Build command: `npm install`
4. Start command: `node server.js`
5. Agregar variables de entorno en el panel

### App en Play Store

1. Generar keystore: `keytool -genkey -v -keystore key.jks ...`
2. Configurar en `android/key.properties`
3. `flutter build appbundle --release`
4. Subir `.aab` a Google Play Console

---

## Licencia

MIT — Proyecto de demostración técnica.
