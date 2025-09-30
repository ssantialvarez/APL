# INTEGRANTES DEL GRUPO
# - Santiago Alvarez
# - Federico Loiero
# - Federico Rossendy

<#
    .SYNOPSIS 
    Analiza los resultados de encuestas de satisfacción de clientes.

    .DESCRIPTION 
    El script para analiza los resultados de encuestas de satisfacción de clientes de un servicio de 
    atención al cliente. Los datos se registran diariamente en archivos de texto, con cada encuesta en una 
    línea. 
    El archivo de registro tiene un formato de campos fijos, donde la posición de cada campo indica su 
    significado, y los campos están separados por un pipe (|). El nombre del archivo tendrá la fecha de registro 
    de las encuestas. 

    .PARAMETER directorio
    Ruta del directorio con archivos de encuestas (.txt).

    .PARAMETER archivo
    Ruta completa del archivo JSON de salida. No usar con archivo

    .PARAMETER pantalla
    Muestra la salida por pantalla. No usar con pantalla

    .EXAMPLE
    PS> .\ejercicio1.ps1 -directorio ./encuestas -archivo ./salida.json
        { 
            "2025-06-30": { 
                "Telefono": { 
                "tiempo_respuesta_promedio": 7.8, 
                "nota_satisfaccion_promedio": 2 
                }, 
            }, 
            "2025-07-01": { 
                "Telefono": { 
                "tiempo_respuesta_promedio": 7.8, 
                "nota_satisfaccion_promedio": 2 
                }, 
                "Email": { 
                "tiempo_respuesta_promedio": 120, 
                "nota_satisfaccion_promedio": 5 
                }, 
                "Chat": { 
                "tiempo_respuesta_promedio": 2.1, 
                "nota_satisfaccion_promedio": 3 
                } 
            }
        }

    .INPUTS
    Ninguno. No puedes canalizar elementos a traves del pipeline.

    .OUTPUTS
    System.Text.Json.

    .FUNCTIONALITY
    El script procesa todos los archivos de encuestas en un directorio, calcula el tiempo de respuesta 
    promedio y la nota de satisfacción promedio por canal de atención y por día. El resultado es ser un archivo o una 
    impresión en pantalla, ambas en formato JSON.
#>
Param(
    [Parameter(Mandatory=$true)]
    [string]
    $Directorio,

    [Parameter(Mandatory=$false)]
    [string]
    $Archivo = "",

    [Parameter(Mandatory=$false)]
    [switch]
    $Pantalla = $false
)


if (-not $Pantalla -and -not $Archivo) {
    Write-Error "No se especificó archivo de salida ni pantalla."
    exit 1
}
if ($Pantalla -and $Archivo) {
    Write-Error "Argumentos conflictivos: no se puede usar -Pantalla y -Archivo juntos."
    exit 1
}

$archivos = Get-ChildItem -Path $Directorio -Filter *.txt
if ($archivos.Count -eq 0) {
    Write-Error "Directorio vacío: $Directorio"
    exit 1
}

# Leer y procesar todos los archivos
$encuestas = @()
foreach ($file in $archivos) {
    $lines = Get-Content $file.FullName | Where-Object { $_.Trim() -ne "" }
    $encuestas += $lines
}

# Procesar datos: agrupar por fecha y canal, calcular promedios
$agrupado = @{}
foreach ($line in $encuestas) {
    $parts = $line -split '\|'
    if ($parts.Count -lt 5) { continue }
    $fecha = ($parts[1] -split ' ')[0].Trim()
    $canal = $parts[2].Trim()
    $tiempo = [double]$parts[3]
    $nota = [double]$parts[4]
    if (-not $agrupado.ContainsKey($fecha)) { $agrupado[$fecha] = @{} }
    if (-not $agrupado[$fecha].ContainsKey($canal)) { $agrupado[$fecha][$canal] = @() }
    $agrupado[$fecha][$canal] += [PSCustomObject]@{ tiempo = $tiempo; nota = $nota }
}

# Construir JSON
$result = @{}
foreach ($fecha in $agrupado.Keys) {
    $result[$fecha] = @{}
    foreach ($canal in $agrupado[$fecha].Keys) {
        $datos = $agrupado[$fecha][$canal]
        $tiempoProm = ($datos | Measure-Object -Property tiempo -Average).Average
        $notaProm = ($datos | Measure-Object -Property nota -Average).Average
        $result[$fecha][$canal] = @{ 
            tiempo_respuesta_promedio = [math]::Round($tiempoProm,3)
            nota_satisfaccion_promedio = [math]::Round($notaProm,3)
        }
    }
}

$json = $result | ConvertTo-Json -Depth 5

if ($Pantalla) {
    Write-Output $json
} else {
    Set-Content -Path $Archivo -Value $json
}
exit 0
