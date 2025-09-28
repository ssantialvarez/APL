# Script: ejercicio1.ps1
# Uso: .\ejercicio1.ps1 -Directorio <ruta> [-Archivo <salida.json>] [-Pantalla] [-Help]

param(
    [string]$Directorio = "",
    [string]$Archivo = "",
    [switch]$Pantalla = $false,
    [switch]$Help = $false
)

function Show-Help {
    Write-Host @"
Uso: ejercicio1.ps1 -Directorio <DIR> [-Archivo <FILE>] [-Pantalla] [-Help]

Opciones:
  -Directorio <DIR>   Ruta del directorio con archivos de encuestas (.txt)
  -Archivo <FILE>     Ruta completa del archivo JSON de salida. No usar con -Pantalla
  -Pantalla           Muestra la salida por pantalla. No usar con -Archivo
  -Help               Muestra este mensaje de ayuda
"@
    exit 0
}

if ($Help) { Show-Help }
if (-not $Directorio) {
    Write-Error "No se ingresó la ruta del directorio."
    exit 1
}
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
