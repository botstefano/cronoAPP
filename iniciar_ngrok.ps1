# Script para iniciar ngrok y mostrar instrucciones
# Ejecutar como: .\iniciar_ngrok.ps1

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Iniciando ngrok para SQL Server" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Ruta a ngrok (CAMBIAR ESTA RUTA según donde instalaste ngrok)
$ngrokPath = "C:\ngrok\ngrok.exe"

if (-not (Test-Path $ngrokPath)) {
    Write-Host "ERROR: No se encontró ngrok en: $ngrokPath" -ForegroundColor Red
    Write-Host "Por favor, edita este script y cambia la ruta a ngrok.exe" -ForegroundColor Yellow
    exit 1
}

Write-Host "Iniciando ngrok en el puerto 1433..." -ForegroundColor Green
Write-Host ""

# Iniciar ngrok en una ventana separada
Start-Process $ngrokPath -ArgumentList "tcp 1433" -WindowStyle Normal

Write-Host "ngrok iniciado en una ventana separada." -ForegroundColor Green
Write-Host ""
Write-Host "========================================" -ForegroundColor Yellow
Write-Host "  INSTRUCCIONES IMPORTANTES" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Yellow
Write-Host ""
Write-Host "1. Ve a la ventana de ngrok que se abrió" -ForegroundColor White
Write-Host "2. Busca la línea que dice: 'Forwarding'" -ForegroundColor White
Write-Host "3. Copia el puerto (ejemplo: 12345)" -ForegroundColor White
Write-Host "4. Ve a Render Dashboard" -ForegroundColor White
Write-Host "5. Actualiza la variable DB_PORT con el nuevo puerto" -ForegroundColor White
Write-Host "6. Haz 'Deploy Changes' en Render" -ForegroundColor White
Write-Host ""
Write-Host "========================================" -ForegroundColor Yellow
Write-Host "  Para detener ngrok:" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Yellow
Write-Host ""
Write-Host "Presiona cualquier tecla para detener ngrok..." -ForegroundColor Cyan
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

# Detener ngrok
Write-Host ""
Write-Host "Deteniendo ngrok..." -ForegroundColor Red
Get-Process ngrok -ErrorAction SilentlyContinue | Stop-Process -Force
Write-Host "ngrok detenido." -ForegroundColor Green
