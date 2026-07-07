# Instrucciones para crear el APK de CronoApp

## Requisitos previos

### 1. Instalar Flutter SDK ✅ (Ya instalado en E:\crono\flutter)

Flutter ya está instalado en tu sistema.

### 2. Instalar Android SDK ⚠️ (Requerido)

Para crear el APK necesitas el Android SDK. Tienes dos opciones:

#### Opción A: Instalar Android Studio (Recomendado)
1. Descarga Android Studio: https://developer.android.com/studio
2. Instálalo con las opciones por defecto
3. Durante la instalación, se instalará automáticamente el Android SDK
4. Android Studio se instalará en: `C:\Users\TU_USUARIO\AppData\Local\Android\Sdk`

#### Opción B: Instalar solo Command-line Tools
1. Descarga "Command line tools only" desde: https://developer.android.com/studio#command-tools
2. Extrae en una carpeta, por ejemplo: `C:\Android\Sdk`
3. Configura la variable de entorno `ANDROID_HOME` apuntando a esa carpeta

### 3. Habilitar Developer Mode en Windows ✅ (Ya habilitado)

El modo desarrollador ya está habilitado en tu sistema.

### 4. Verificar instalación
Abre PowerShell y ejecuta:
```powershell
flutter doctor
```

Resuelve cualquier problema que indique flutter doctor.

## Crear el APK

Una vez que Flutter esté instalado:

### Opción 1: Usar el script PowerShell (recomendado)
```powershell
cd e:\crono\cronoAPP
.\build_apk.ps1
```

### Opción 2: Manualmente
```powershell
cd e:\crono\cronoAPP\flutter_app
flutter pub get
flutter build apk --release
```

## Instalar el APK

El APK se generará en: `flutter_app\build\app\outputs\flutter-apk\app-release.apk`

### Instalar via ADB (con dispositivo conectado)
```powershell
adb install flutter_app\build\app\outputs\flutter-apk\app-release.apk
```

### Instalar manualmente
1. Copia el archivo `app-release.apk` a tu dispositivo Android
2. Abre el archivo en el dispositivo
3. Habilita "Instalar apps de fuentes desconocidas" si es necesario
4. Instala la app

## Configuración de la app

La app ya está configurada para:
- ✅ Conectarse al backend: `https://cronoapp-backend.onrender.com/api`
- ✅ Funcionar en Android 10+
- ✅ Consumir pocos recursos (optimizado)
- ✅ Permisos de INTERNET habilitados

## Credenciales de prueba

Usuario: `admin`
Contraseña: `Admin123!`

(El usuario admin debe existir en la base de datos Supabase)
