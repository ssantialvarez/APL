# INTEGRANTES DEL GRUPO
# - Santiago Alvarez
# - Federico Loiero
# - Federico Rossendy

# Script: ejercicio3.ps1
# Uso: .\ejercicio3.ps1 usb,invalid

if ($args.Count -eq 0) {
    Write-Host "Uso: .\ejercicio3.ps1 palabra1 palabra2 ..."
    exit 1
}

# Las palabras clave son los argumentos
$keywordArray = $args

# Buscar archivos .log en el directorio actual
$logFiles = Get-ChildItem -Path . -Filter *.log

if ($logFiles.Count -eq 0) {
    Write-Host "No se encontraron archivos .log en el directorio."
    exit 1
}

foreach ($kw in $keywordArray) {
    $count = 0
    foreach ($file in $logFiles) {
        $content = Get-Content $file.FullName
        foreach ($line in $content) {
            if ($line -match "(?i)$kw") {
                $count++
            }
        }
    }
    Write-Host ("{0}: {1}" -f ($kw.Substring(0,1).ToUpper()+$kw.Substring(1).ToLower()), $count)
}
