function Show-Help {
    @"
Usage: .\ejercicio2.ps1 -Matriz <Ruta> [-Hub] [-Camino] [-Separador <Carácter>]

Options:
  -Matriz       Ruta del archivo de la matriz de adyacencia.
  -Hub          Determina qué estación es el "hub" (estación con más conexiones) de la red. No se puede usar junto con -Camino.
  -Camino       Encuentra el camino más corto en tiempo. No se puede usar junto a -Hub.
  -Separador    Carácter para utilizarse como separador de columnas (por defecto '|').
  -Help         Muestra este mensaje de ayuda.
"@
}

# Validar argumentos manualmente
if ($args.Length -eq 0 -or $args -contains '-Help') {
    Show-Help
    exit 0
}

# Inicializar variables
$Matriz = $null
$Hub = $false
$Camino = $false
$Separador = '|'

# Procesar argumentos
for ($i = 0; $i -lt $args.Length; $i++) {
    switch ($args[$i]) {
        '--Matriz' {
            $Matriz = $args[$i + 1]
            $i++
        }
        '-m' {
            $Matriz = $args[$i + 1]
            $i++
        }
        '--Hub' {
            $Hub = $true
        }
        '-h' {
            $Hub = $true
        }
        '--Camino' {
            $Camino = $true
        }
        '-c' {
            $Camino = $true
        }
        '--Separador' {
            $Separador = $args[$i + 1]
            $i++
        }
        '-s' {
            $Separador = $args[$i + 1]
            $i++
        }
        default {
            Write-Error "Argumento no reconocido: $($args[$i])"
            exit 1
        }
    }
}

# Validar que la variable $Matriz no esté vacía
if (-not $Matriz) {
    Write-Error "Debe especificar un archivo válido para la matriz con -Matriz"
    exit 1
}

# Convertir la ruta a absoluta si es relativa
if (-not (Test-Path -Path $Matriz)) {
    $Matriz = Join-Path -Path (Get-Location) -ChildPath $Matriz
}

# Imprimir la ruta calculada para depuración
Write-Output "## Informe de análisis de red de transporte "

try {
    if (-not (Test-Path -Path $Matriz -PathType Leaf)) {
        Write-Error "El archivo de matriz no existe: $Matriz"
        exit 1
    }
} catch {
    Write-Error "Error al validar la ruta del archivo: $_"
    exit 1
}

# Leer la matriz solo si la ruta es válida
if (-not [string]::IsNullOrWhiteSpace($Matriz)) {
    $lineas = Get-Content -Path $Matriz
} else {
    Write-Error "La ruta de la matriz es inválida o vacía."
    exit 1
}

# Leer la matriz
$matriz = @()
foreach ($linea in $lineas) {
    $linea = $linea -replace '\s', ''
    $valores = $linea -split [regex]::Escape($Separador)
    foreach ($valor in $valores) {
        if (-not ($valor -match '^[0-9.]+$')) {
            Write-Error "Valor no numérico en la matriz: $valor"
            exit 1
        }
    }
    $matriz += ,@($valores)
}

$numFilas = $matriz.Count
$numColumnas = $matriz[0].Count

if ($numFilas -ne $numColumnas) {
    Write-Error "La matriz no es cuadrada ($numFilas x $numColumnas)"
    exit 1
}

# Validar simetría
for ($i = 0; $i -lt $numFilas; $i++) {
    for ($j = 0; $j -lt $numColumnas; $j++) {
        if ($matriz[$i][$j] -ne $matriz[$j][$i]) {
            Write-Error "La matriz no es simétrica en ($i,$j) y ($j,$i)"
            exit 1
        }
    }
}

if ($Hub) {
    $maxConexiones = 0
    $hubEstacion = 0
    for ($i = 0; $i -lt $numFilas; $i++) {
        $conexiones = 0
        for ($j = 0; $j -lt $numColumnas; $j++) {
            if ($i -ne $j -and [double]$matriz[$i][$j] -gt 0) {
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

if ($Camino) {
    $infinito = [double]::MaxValue
    $dist = @()
    $next = @()

    for ($i = 0; $i -lt $numFilas; $i++) {
        $dist += ,@(0..($numColumnas - 1) | ForEach-Object { if ($_ -eq $i) { 0 } elseif ([double]$matriz[$i][$_] -gt 0) { [double]$matriz[$i][$_] } else { $infinito } })
        $next += ,@(0..($numColumnas - 1) | ForEach-Object { if ($_ -eq $i) { -1 } elseif ([double]$matriz[$i][$_] -gt 0) { $_ } else { -1 } })
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