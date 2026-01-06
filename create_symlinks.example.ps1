# Script de PowerShell para crear symlinks en Windows
# IMPORTANTE: Ejecutar como Administrador
#
# ESTE ES UN ARCHIVO DE EJEMPLO
# Genera tu propio script ejecutando: python setup_symlinks.py

# Verifica que el script se esté ejecutando como administrador
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "ERROR: Este script debe ejecutarse como Administrador" -ForegroundColor Red
    Write-Host "Haz clic derecho en PowerShell y selecciona 'Ejecutar como administrador'" -ForegroundColor Yellow
    Read-Host 'Presiona Enter para salir'
    exit 1
}

# Directorio raíz del proyecto
$ProjectRoot = "C:/Users/Usuario/Documents/mi-proyecto"

Write-Host '=' -NoNewline -ForegroundColor Cyan
Write-Host ('=' * 78) -ForegroundColor Cyan
Write-Host 'Creando symlinks para Prefect Workflows' -ForegroundColor Green
Write-Host '=' -NoNewline -ForegroundColor Cyan
Write-Host ('=' * 78) -ForegroundColor Cyan

# Symlink 1: ../outputs/cultivos -> C:/Users/Usuario/OneDrive/Datos/Cultivos
$Source1 = "$ProjectRoot/outputs/cultivos"
$Target1 = "C:/Users/Usuario/OneDrive - MI EMPRESA/Documentos/Datos/Cultivos"

Write-Host 'Procesando symlink 1/3...' -ForegroundColor Yellow
Write-Host "  Origen: $Source1"
Write-Host "  Destino: $Target1"

# Crear directorio de destino si no existe
if (-not (Test-Path $Target1)) {
    New-Item -ItemType Directory -Path $Target1 -Force | Out-Null
    Write-Host "  [OK] Directorio de destino creado" -ForegroundColor Green
}

# Eliminar directorio de origen si existe (para crear el symlink)
if (Test-Path $Source1) {
    Remove-Item -Path $Source1 -Recurse -Force
    Write-Host "  [OK] Directorio de origen eliminado" -ForegroundColor Green
}

# Crear el symlink
try {
    New-Item -ItemType SymbolicLink -Path $Source1 -Target $Target1 -Force | Out-Null
    Write-Host "  [OK] Symlink creado exitosamente" -ForegroundColor Green
} catch {
    Write-Host "  [ERROR] Error creando symlink: $_" -ForegroundColor Red
}

# Symlink 2: ../outputs/muestreos -> C:/Users/Usuario/OneDrive/Datos/Muestreos
$Source2 = "$ProjectRoot/outputs/muestreos"
$Target2 = "C:/Users/Usuario/OneDrive - MI EMPRESA/Documentos/Datos/Muestreos"

Write-Host 'Procesando symlink 2/3...' -ForegroundColor Yellow
Write-Host "  Origen: $Source2"
Write-Host "  Destino: $Target2"

# Crear directorio de destino si no existe
if (-not (Test-Path $Target2)) {
    New-Item -ItemType Directory -Path $Target2 -Force | Out-Null
    Write-Host "  [OK] Directorio de destino creado" -ForegroundColor Green
}

# Eliminar directorio de origen si existe (para crear el symlink)
if (Test-Path $Source2) {
    Remove-Item -Path $Source2 -Recurse -Force
    Write-Host "  [OK] Directorio de origen eliminado" -ForegroundColor Green
}

# Crear el symlink
try {
    New-Item -ItemType SymbolicLink -Path $Source2 -Target $Target2 -Force | Out-Null
    Write-Host "  [OK] Symlink creado exitosamente" -ForegroundColor Green
} catch {
    Write-Host "  [ERROR] Error creando symlink: $_" -ForegroundColor Red
}

# Symlink 3: ../outputs/Backup_Databaler -> C:/Users/Usuario/OneDrive/Backups
$Source3 = "$ProjectRoot/outputs/Backup_Databaler"
$Target3 = "C:/Users/Usuario/OneDrive - MI EMPRESA/Documentos/Backups"

Write-Host 'Procesando symlink 3/3...' -ForegroundColor Yellow
Write-Host "  Origen: $Source3"
Write-Host "  Destino: $Target3"

# Crear directorio de destino si no existe
if (-not (Test-Path $Target3)) {
    New-Item -ItemType Directory -Path $Target3 -Force | Out-Null
    Write-Host "  [OK] Directorio de destino creado" -ForegroundColor Green
}

# Eliminar directorio de origen si existe (para crear el symlink)
if (Test-Path $Source3) {
    Remove-Item -Path $Source3 -Recurse -Force
    Write-Host "  [OK] Directorio de origen eliminado" -ForegroundColor Green
}

# Crear el symlink
try {
    New-Item -ItemType SymbolicLink -Path $Source3 -Target $Target3 -Force | Out-Null
    Write-Host "  [OK] Symlink creado exitosamente" -ForegroundColor Green
} catch {
    Write-Host "  [ERROR] Error creando symlink: $_" -ForegroundColor Red
}

Write-Host ''
Write-Host '=' -NoNewline -ForegroundColor Cyan
Write-Host ('=' * 78) -ForegroundColor Cyan
Write-Host 'Proceso completado' -ForegroundColor Green
Write-Host '=' -NoNewline -ForegroundColor Cyan
Write-Host ('=' * 78) -ForegroundColor Cyan
Write-Host ''
Write-Host 'NOTA: Este es un ejemplo. Genera tu propio script ejecutando:' -ForegroundColor Yellow
Write-Host '      python setup_symlinks.py' -ForegroundColor Yellow

Read-Host 'Presiona Enter para salir'
