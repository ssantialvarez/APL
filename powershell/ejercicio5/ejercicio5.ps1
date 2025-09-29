<#
.SYNOPSIS
    Consulta información de países utilizando la API de REST Countries.

.DESCRIPTION
    Este script permite buscar información de países por nombre utilizando la API pública de REST Countries.
    Los resultados se almacenan en un archivo de caché con un TTL (time to live) configurable para evitar consultas repetidas.

.PARAMETER nombre
    Nombre o nombres de los países a buscar, separados por comas.

.PARAMETER ttl
    Tiempo en segundos durante el cual los resultados en caché son válidos.

.EXAMPLE
    .\ejercicio5.ps1 -nombre "argentina,chile" -ttl 60
    Consulta información de los países "argentina" y "chile" con un TTL de 60 segundos para la caché.
#>

param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$nombre,
    [Parameter(Mandatory = $true, Position = 1)]
    [int]$ttl
)

$ErrorActionPreference = "Stop"
$NOMBRES = $nombre -split ","
$TTL = $ttl
$cacheDir = "cache"
if (-not (Test-Path $cacheDir)) { New-Item -ItemType Directory -Path $cacheDir | Out-Null }

function Get-CountryInfo($pais) {
    $url = "https://restcountries.com/v3.1/name/$pais"
    try {
        $response = Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 10
        return @{status = $response.StatusCode; body = $response.Content }
    }
    catch {
        return @{status = 404; body = "" }
    }
}

foreach ($pais in $NOMBRES) {
    Write-Host ""
    Write-Host "Nombre del país: $pais"
    $paisLimpio = $pais.Trim().Trim('"')
    $cacheFile = Join-Path $cacheDir ("$paisLimpio.json")
    $body = $null
    $status = 0

    if (Test-Path $cacheFile) {
        Write-Host "Cargando información de caché para el país $pais"
        $fileMtime = (Get-Item $cacheFile).LastWriteTimeUtc
        $age = [int]((Get-Date).ToUniversalTime() - $fileMtime).TotalSeconds
        if ($age -gt $TTL) {
            Write-Host "La caché ha expirado (edad ${age}s > ${TTL}s)"
            Write-Host "Obteniendo información en tiempo real para el país $pais"
            $result = Get-CountryInfo $pais
            $status = $result.status
            $body = $result.body
            if ($status -eq 200) { $body | Out-File -Encoding utf8 $cacheFile }
        }
        else {
            $body = Get-Content $cacheFile -Raw
            $status = 200
        }
    }
    else {
        Write-Host "Obteniendo información en tiempo real para el país $pais"
        $result = Get-CountryInfo $pais
        $status = $result.status
        $body = $result.body
        if ($status -eq 200) { $body | Out-File -Encoding utf8 $cacheFile }
    }

    if ($status -ne 200) {
        Write-Host "Error: País no encontrado"
        continue
    }

    $json = $null
    try { $json = $body | ConvertFrom-Json } catch { Write-Host "Error de parseo JSON"; continue }
    $info = $json[0]
    $nombre = $info.name.common
    $capital = $info.capital[0]
    $region = $info.region
    $poblacion = $info.population

    # Obtener moneda correctamente del objeto currencies
    $moneda_codigo = $null
    $moneda_nombre = $null
    if ($info.currencies) {
        $moneda = $info.currencies.PSObject.Properties | Select-Object -First 1
        if ($moneda) {
            $moneda_codigo = $moneda.Name
            $moneda_nombre = $moneda.Value.name
        }
    }

    Write-Host "País: $nombre"
    Write-Host "Capital: $capital"
    Write-Host "Región: $region"
    Write-Host "Población: $poblacion"
    Write-Host "Moneda: $moneda_nombre ($moneda_codigo)"
}
