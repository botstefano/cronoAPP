# Script para construir el APK release de CronoApp
# Requiere Flutter SDK instalado y configurado en PATH
# EJECUTAR COMO ADMINISTRADOR si el Android SDK está en Program Files

# Verificar si se está ejecutando como administrador
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "WARNING: No se está ejecutando como administrador" -ForegroundColor Yellow
    Write-Host "El Android SDK está en Program Files y requiere permisos de administrador" -ForegroundColor Yellow
    Write-Host "Intentando continuar de todas formas..." -ForegroundColor Cyan
    Write-Host ""
}

Write-Host "=== Construyendo APK Release de CronoApp ===" -ForegroundColor Cyan

# Ruta de Flutter
$flutterBinPath = "E:\crono\flutter\bin"

# Verificar si Flutter está instalado
if (-not (Test-Path $flutterBinPath)) {
    Write-Host "ERROR: Flutter no está instalado en: $flutterBinPath" -ForegroundColor Red
    exit 1
}

Write-Host "Flutter encontrado en: $flutterBinPath" -ForegroundColor Green

# Agregar Flutter al PATH temporalmente
$env:PATH = "$flutterBinPath;$env:PATH"

# Configurar Android SDK si existe en rutas comunes
$androidSdkPaths = @(
    "C:\Program Files (x86)\Android\android-sdk",
    "C:\Android\Sdk",
    "$env:LOCALAPPDATA\Android\Sdk",
    "C:\Users\$env:USERNAME\AppData\Local\Android\Sdk"
)

$androidSdkFound = $false
foreach ($path in $androidSdkPaths) {
    if (Test-Path $path) {
        $env:ANDROID_HOME = $path
        $env:ANDROID_SDK_ROOT = $path
        $env:PATH = "$path\platform-tools;$path\tools;$env:PATH"
        Write-Host "Android SDK encontrado en: $path" -ForegroundColor Green
        $androidSdkFound = $true
        break
    }
}

if (-not $androidSdkFound) {
    Write-Host "WARNING: Android SDK no encontrado en rutas comunes" -ForegroundColor Yellow
    Write-Host "Para instalar Android SDK:" -ForegroundColor Yellow
    Write-Host "1. Descargar Android Studio: https://developer.android.com/studio" -ForegroundColor Yellow
    Write-Host "2. O instalar Command-line tools: https://developer.android.com/studio#command-tools" -ForegroundColor Yellow
    Write-Host "3. Configurar la variable de entorno ANDROID_HOME" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Intentando continuar de todas formas..." -ForegroundColor Cyan
}

# Cambiar al directorio de la app Flutter
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$appPath = Join-Path $scriptPath "flutter_app"

if (-not (Test-Path $appPath)) {
    Write-Host "ERROR: No se encontró el directorio flutter_app en: $appPath" -ForegroundColor Red
    exit 1
}

Set-Location $appPath
Write-Host "Directorio de trabajo: $appPath" -ForegroundColor Green

# Obtener dependencias
Write-Host ""
Write-Host "Obteniendo dependencias..." -ForegroundColor Cyan
flutter pub get

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: No se pudieron obtener las dependencias" -ForegroundColor Red
    exit 1
}

# Construir APK release
Write-Host ""
Write-Host "Construyendo APK release..." -ForegroundColor Cyan
Write-Host "Esto puede tomar varios minutos..." -ForegroundColor Yellow

# Detener todos los Gradle daemons para evitar conflictos de puertos
Write-Host "Deteniendo Gradle daemons..." -ForegroundColor Cyan
Stop-Process -Name "java" -Force -ErrorAction SilentlyContinue
Stop-Process -Name "gradle" -Force -ErrorAction SilentlyContinue

# Limpiar caché de Gradle antes de construir
Write-Host "Limpiando caché de Gradle..." -ForegroundColor Cyan
flutter clean

flutter build apk --release

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Falló la construcción del APK" -ForegroundColor Red
    exit 1
}

# Mostrar ubicación del APK
$apkPath = Join-Path $appPath "build\app\outputs\flutter-apk\app-release.apk"

Write-Host ""
Write-Host "=== APK construido exitosamente ===" -ForegroundColor Green
Write-Host "Ubicación: $apkPath" -ForegroundColor Cyan
Write-Host ""
Write-Host "Para instalar en un dispositivo Android:" -ForegroundColor Yellow
Write-Host "1. Conectar el dispositivo via USB con depuración USB habilitada"
Write-Host "2. Ejecutar: adb install $apkPath"
Write-Host "O simplemente copiar el APK al dispositivo e instalar manualmente"
Write-Host ""

# Abrir el directorio donde está el APK
explorer (Split-Path $apkPath)
