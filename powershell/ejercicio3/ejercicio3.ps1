# INTEGRANTES DEL GRUPO
# - Santiago Alvarez
# - Federico Loiero
# - Federico Rossendy

# Script: ejercicio3.ps1
# Uso: .\ejercicio3.ps1 usb,invalid

<#
.SYNOPSIS
Script para contar ocurrencias de palabras clave en archivos .log.

.DESCRIPTION
Este script busca archivos .log en el directorio actual y cuenta las ocurrencias de palabras clave especificadas como argumentos.

.PARAMETER Directorio
Especifica ruta del directorio con los archivos de logs a analizar
.PARAMETER Palabras
Lista de palabras clave a contabilizar, separadas por comas.

.EXAMPLE
\ejercicio3.ps1 usb,invalid
Cuenta las ocurrencias de las palabras "usb" e "invalid" en los archivos .log del directorio actual.

Ejemplo de archivo de entrada (system.log) 

Aug 23 10:00:01 server.local kernel: [256.789] USB device plugged in. 
Aug 23 10:00:05 server.local sshd[1234]: Invalid user from 192.168.1.1. 
Aug 23 10:00:10 server.local sudo[5678]: Command not found. 
Aug 23 10:00:15 server.local kernel: [258.123] USB device unplugged. 
Aug 23 10:00:20 server.local sshd[1234]: Invalid user from 192.168.1.2. 
 
Ejemplo de salida 
USB: 2 
Invalid: 2  
 
.NOTES
- El script requiere que existan archivos .log en el directorio actual.
- Las palabras clave no distinguen entre mayúsculas y minúsculas.

#>

[CmdletBinding()]
param (
    [Parameter(Mandatory=$true, Position = 0, HelpMessage = 'Especifica ruta del directorio con los archivos de logs a analizar')]
    [string]$Directorio,

    [Parameter(Mandatory=$true, HelpMessage = 'Lista de palabras clave a contabilizar, separadas por comas.')]
    [string[]]$Palabras
)
# Las palabras clave son los argumentos
$keywordArray = $Palabras

# Buscar archivos .log en el directorio actual
$logFiles = Get-ChildItem -Path $Directorio -Filter *.log

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
