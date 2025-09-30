# INTEGRANTES DEL GRUPO
# - Santiago Alvarez
# - Federico Loiero
# - Federico Rossendy

<#
    .SYNOPSIS 
    Demonio para monitorear un repositorio Git y detectar credenciales o datos sensibles que se hayan subido por error.

    .DESCRIPTION 
    El demonio lee un archivo de configuración que contiene una lista de palabras clave o patrones regex 
    a buscar (por ejemplo, password, API_KEY, "API_KEY = "). Cada vez que detecta una nueva modificación en 
    la rama principal del repositorio, el demonio escanea los archivos modificados. 
    Si encuentra alguna coincidencia, registra una alerta en un archivo de log con el nombre del archivo, 
    el patrón encontrado y la fecha. El script se ejecuta en segundo plano, liberando la terminal.  

    .PARAMETER repo
    Ruta del repositorio Git a monitorear.

    .PARAMETER configuracion
    Ruta del archivo de configuración que contiene la lista de patrones a buscar.

    .PARAMETER log
    Ruta del archivo de logs que contiene la lista de eventos identificados.

    .PARAMETER kill
    Flag para detener el demonio. Solo se usa junto con -r / -repo y debe validar que exista un demonio en ejecución.

    .EXAMPLE
    PS> ./audit.ps1 -repo /home/user/myrepo -configuracion ./patrones.conf

    Ejemplo de salida en el archivo de log:   
    [2025-08-23 11:30:00] Alerta: patrón 'API_KEY' encontrado en el archivo 'config.js'.

    .EXAMPLE
    Ejemplo de archivo de configuración (patrones.conf)
    password  
    API_KEY  
    secret   
    regex:^.*API_KEY\s*=\s*['"].*['"].*$ 

    .NOTES
    Consideraciones: 
    No se puede ejecutar más de un proceso demonio para el mismo repositorio. 
#>

Param (
    [Parameter(Mandatory=$true, ParameterSetName="KillSet")]
    [switch]$Kill,

    [Parameter(Mandatory=$true, ParameterSetName="ConfigSet")]
    [string]$Config,

    [Parameter(Mandatory=$true, ParameterSetName="ConfigSet")]
    [string]$Log,

    [Parameter(Mandatory=$true, ParameterSetName="KillSet")]
    [Parameter(Mandatory=$true, ParameterSetName="ConfigSet")]
    [string]$Repo,

    [switch]$Detach
)

if (-not $Detach) {
    $argsList = @("-File", "`"$PSCommandPath`"", "-Repo", "`"$Repo`"")

    if ($Config) { $argsList += @("-Config", "`"$Config`"") }
    if ($Log)    { $argsList += @("-Log", "`"$Log`"") }
    if ($Kill)   { $argsList += "-Kill" }

    $argsList += "-Detach"

    if ($IsWindows) {
        Start-Process powershell -ArgumentList $argsList -WindowStyle Hidden
    } else {
        # En Linux/macOS no existe -WindowStyle
        Start-Process pwsh -ArgumentList $argsList
    }
    Write-Host "El monitoreo se inició en background (PID liberado)."
    exit
}

# Generar un hash único para el repositorio
$RepoHash = [System.BitConverter]::ToString((New-Object System.Security.Cryptography.SHA1Managed).ComputeHash([System.Text.Encoding]::UTF8.GetBytes($Repo))).Replace("-", "")
$PidFile = (Join-Path ([System.IO.Path]::GetTempPath()) "audit_${RepoHash}.pid")

$LastEvent = @{}

function Confirm-ProcessFile($File) {
    $now = Get-Date
    if ($LastEvent.ContainsKey($File)) {
        $diff = ($now - $LastEvent[$File]).TotalMilliseconds
        if ($diff -lt 500) { # menos de medio segundo → duplicado
            return $false
        }
    }
    $LastEvent[$File] = $now
    return $true
}


# Función para detener el monitoreo
function Stop-Monitoring {
    if (Test-Path $PidFile) {
        $npid = Get-Content $PidFile
        Stop-Process -Id $npid -Force -ErrorAction SilentlyContinue
        Remove-Item $PidFile -Force
        Write-Host "El monitoreo del repositorio $Repo se detuvo correctamente."
    } else {
        Write-Host "No hay un monitoreo activo para el repositorio $Repo." -ForegroundColor Yellow
    }
    exit
}

# Detener el monitoreo si se usa el flag -Kill
if ($Kill) {
    Stop-Monitoring
}

# Verificar si el repositorio es válido
if (-not (Test-Path "$Repo\.git")) {
    Write-Host "Error: El directorio '$Repo' no contiene un repositorio Git válido." -ForegroundColor Red
    exit
}

# Verificar si el archivo de configuración existe
if (-not (Test-Path $Config)) {
    Write-Host "Error: El archivo de configuración '$Config' no existe." -ForegroundColor Red
    exit
}

# Leer patrones del archivo de configuración
$Patterns = Get-Content $Config | ForEach-Object { $_.Trim() }
if (-not $Patterns) {
    Write-Host "Error: El archivo de configuración '$Config' está vacío." -ForegroundColor Red
    exit
}

# Crear el archivo de log si no existe
if (-not (Test-Path $Log)) {
    New-Item -Path $Log -ItemType File | Out-Null
}

# Verificar si ya hay un monitoreo activo
if (Test-Path $PidFile) {
    Write-Host "El repositorio ya tiene un monitoreo activo." -ForegroundColor Yellow
    exit
}

# Función para escanear un archivo en busca de patrones
function Read-File {
    param (
        [string]$File
    )
    
    if (-not (Test-Path $File)) {
        return
    }
    foreach ($Pattern in $Patterns) {
        if ($Pattern -match "^regex:(.+)$") {
            $Regex = $Matches[1]
            if (Select-String -Path $File -Pattern $Regex -Quiet) {
                Add-Content -Path $Log -Value "[$(Get-Date)] ALERTA: patrón '$Regex' encontrado en $File"
            }
        } else {
            if (Select-String -Path $File -Pattern $Pattern -Quiet ) {
                Add-Content -Path $Log -Value "[$(Get-Date)] ALERTA: patrón '$Pattern' encontrado en $File"
            }
        }
    }
}

# Función para monitorear el repositorio
function Watch-Repo {
    Write-Host "Iniciando monitoreo del repositorio $Repo..."
    $Watcher = New-Object System.IO.FileSystemWatcher
    $Watcher.Path = $Repo
    $Watcher.IncludeSubdirectories = $true
    $Watcher.EnableRaisingEvents = $true
    
    Register-ObjectEvent -InputObject $Watcher -EventName Created -Action {
        if (Confirm-ProcessFile $Event.SourceEventArgs.FullPath) {
            Start-Sleep -Milliseconds 200
            Read-File -File $Event.SourceEventArgs.FullPath
        }
    } | Out-Null

    Register-ObjectEvent -InputObject $Watcher -EventName Changed -Action {
        if (Confirm-ProcessFile $Event.SourceEventArgs.FullPath) {
            Start-Sleep -Milliseconds 200
            Read-File -File $Event.SourceEventArgs.FullPath
        }
    } | Out-Null

    Register-ObjectEvent -InputObject $Watcher -EventName Deleted -Action {
        Add-Content -Path $Log -Value "[$(Get-Date)] Archivo eliminado: $($Event.SourceEventArgs.FullPath)"
    } | Out-Null

    # Guardar el PID del proceso
    $npid = $PID
    Set-Content -Path $PidFile -Value $npid

    # Mantener el proceso en ejecución
    while ($true) {
        Start-Sleep -Seconds 1
    }
}

# Iniciar el monitoreo
Watch-Repo