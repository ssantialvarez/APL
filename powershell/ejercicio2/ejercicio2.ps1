# INTEGRANTES DEL GRUPO
# - Santiago Alvarez
# - Federico Loiero
# - Federico Rossendy

<#
.SYNOPSIS
Script para analizar rutas en una red de transporte público.

.DESCRIPTION
Este script analiza una matriz de adyacencia que representa una red de transporte público.
Permite determinar el "hub" de la red o encontrar el camino más corto en tiempo entre estaciones.

.PARAMETER matriz
Ruta del archivo de la matriz de adyacencia.

.PARAMETER hub
Determina qué estación es el "hub" (estación con más conexiones) de la red.
No se puede usar junto con -camino.

.PARAMETER camino
Encuentra el camino más corto en tiempo. No se puede usar junto a -hub.

.PARAMETER separador
Carácter para utilizarse como separador de columnas (por defecto '|').

.EXAMPLE
.
\ejercicio2.ps1 -matriz "mapa1.txt" -hub
Determina el "hub" de la red basado en la matriz proporcionada.

.EXAMPLE
.
\ejercicio2.ps1 -matriz "mapa1.txt" -camino
Encuentra el camino más corto en tiempo entre estaciones basado en la matriz proporcionada.
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory=$true, ParameterSetName="HubSet", HelpMessage = 'Determina qué estación es el "hub" (estación con más conexiones) de la red. No se puede usar junto con -Camino.')]
    [switch]$Hub,

    [Parameter(Mandatory=$true, ParameterSetName="CaminoSet", HelpMessage = 'Encuentra el camino más corto en tiempo. No se puede usar junto a -Hub.')]
    [switch]$Camino,

    [Parameter(Mandatory=$true, ParameterSetName="HubSet", Position = 0, HelpMessage = 'Ruta del archivo de la matriz de adyacencia.')]
    [Parameter(Mandatory=$true, ParameterSetName="CaminoSet", Position = 0, HelpMessage = 'Ruta del archivo de la matriz de adyacencia.')]
    [string]$Matriz,

    [Parameter(HelpMessage = 'Carácter para utilizarse como separador de columnas (por defecto |).')]
    [string]$Separador = '|'
)

# Convertir la ruta a absoluta si es relativa
if (-not (Test-Path -Path $Matriz)) {
    $Matriz = Join-Path -Path (Get-Location) -ChildPath $Matriz
}

try {
    if (-not (Test-Path -Path $Matriz -PathType Leaf)) {
        Write-Error "El archivo de matriz no existe: $Matriz"
        exit 1
    }
}
catch {
    Write-Error "Error al validar la ruta del archivo: $_"
    exit 1
}

# Leer la matriz solo si la ruta es válida
if (-not [string]::IsNullOrWhiteSpace($Matriz)) {
    $lineas = Get-Content -Path $Matriz
}
else {
    Write-Error "La ruta de la matriz es inválida o vacía."
    exit 1
}

Write-Output "## Informe de análisis de red de transporte "

$matrizProcesada = @()
foreach ($linea in $lineas) {
    $linea = $linea -replace '\s', ''
    $valores = $linea -split [regex]::Escape($Separador)
    if ($valores.Count -ne $lineas.Count) {
        Write-Error "La matriz no es cuadrada. Número de valores en la fila: $($valores.Count), Número de filas: $($lineas.Count)"
        exit 1
    }
    $matrizProcesada += ,@($valores | ForEach-Object { [double]$_ })
}

$numFilas = $matrizProcesada.Count
$numColumnas = $matrizProcesada[0].Count

Write-Output "Número de filas: $numFilas, Número de columnas: $numColumnas"

# Validar simetría
for ($i = 0; $i -lt $numFilas; $i++) {
    for ($j = 0; $j -lt $numColumnas; $j++) {
        if ($matrizProcesada[$i][$j] -ne $matrizProcesada[$j][$i]) {
            Write-Error "La matriz no es simétrica en ($i,$j) y ($j,$i)"
            exit 1
        }
    }
}

if ($hub) {
    $maxConexiones = 0
    $hubEstacion = 0
    for ($i = 0; $i -lt $numFilas; $i++) {
        $conexiones = 0
        for ($j = 0; $j -lt $numColumnas; $j++) {
            if ($i -ne $j -and [double]$matrizProcesada[$i][$j] -gt 0) {
                $conexiones++
            }
        }
        if ($conexiones -gt $maxConexiones) {
            $maxConexiones = $conexiones
            $hubEstacion = $i + 1
        }
    }
    Write-Output "**Hub de la red:** Estación $hubEstacion ($maxConexiones conexiones directas)"
    exit 0
}

if ($camino) {
    $infinito = [double]::MaxValue
    $dist = @()
    $next = @()

    for ($i = 0; $i -lt $numFilas; $i++) {
        $dist += , @(0..($numColumnas - 1) | ForEach-Object { if ($_ -eq $i) { 0 } elseif ([double]$matrizProcesada[$i][$_] -gt 0) { [double]$matrizProcesada[$i][$_] } else { $infinito } })
        $next += , @(0..($numColumnas - 1) | ForEach-Object { if ($_ -eq $i) { -1 } elseif ([double]$matrizProcesada[$i][$_] -gt 0) { $_ } else { -1 } })
    }

    for ($k = 0; $k -lt $numFilas; $k++) {
        for ($i = 0; $i -lt $numFilas; $i++) {
            for ($j = 0; $j -lt $numColumnas; $j++) {
                $suma = $dist[$i][$k] + $dist[$k][$j]
                if ($suma -lt $dist[$i][$j]) {
                    $dist[$i][$j] = $suma
                    $next[$i][$j] = $next[$i][$k]
                }
            }
        }
    }

    $tiempoMinimo = $infinito
    for ($i = 0; $i -lt $numFilas; $i++) {
        for ($j = $i + 1; $j -lt $numColumnas; $j++) {
            if ($dist[$i][$j] -lt $tiempoMinimo) {
                $tiempoMinimo = $dist[$i][$j]
            }
        }
    }

    for ($origen = 0; $origen -lt $numFilas; $origen++) {
        for ($destino = $origen + 1; $destino -lt $numColumnas; $destino++) {
            if ($dist[$origen][$destino] -eq $tiempoMinimo) {
                $ruta = @()
                $u = $origen
                while ($u -ne $destino) {
                    $ruta += ($u + 1)
                    $u = $next[$u][$destino]
                    if ($u -eq -1) {
                        Write-Output "No hay camino entre Estación $($origen + 1) y Estación $($destino + 1)"
                        break
                    }
                }
                $ruta += ($destino + 1)
                Write-Output "**Camino más corto: Entre Estación $($origen + 1) y Estación $($destino + 1)**"
                Write-Output "**Tiempo total:** $($dist[$origen][$destino]) minutos"
                Write-Output "**Ruta:** $($ruta -join ' -> ')"
            }
        }
    }
    exit 0
}