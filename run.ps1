<#
.SYNOPSIS
    Local Docker automation for The-Board (Windows).

.DESCRIPTION
    Wraps docker-compose.yml to build the app image from this folder,
    start the Postgres + Node stack, wait for health, and surface URLs / logs.

    Run from the project root (where docker-compose.yml lives) in PowerShell.

.PARAMETER Action
    up       (default) build (cached) + start + wait for health
    rebuild  force --no-cache rebuild, then start
    fresh    wipe DB volume + rebuild + start (DESTROYS local data)
    logs     tail logs for both services
    stop     stop containers (data preserved)
    down     stop + remove containers (volume preserved)
    status   show container + health status
    shell    open a shell in the running app container
    psql     open psql against the running db container

.PARAMETER AppPort
    Host port the Node container listens on. Default: 3001 (matches docker-compose.yml).

.PARAMETER DbPort
    Host port Postgres is published on. Default: 5432.

.PARAMETER HealthTimeoutSeconds
    Seconds to wait for the stack to become healthy. Default: 120.

.PARAMETER Yes
    Reserved for future non-destructive prompts. NOTE: 'fresh' always
    requires the typed confirmation phrase and cannot be bypassed.

.EXAMPLE
    powershell -ExecutionPolicy Bypass -File .\run.ps1

.EXAMPLE
    powershell -ExecutionPolicy Bypass -File .\run.ps1 rebuild

.EXAMPLE
    powershell -ExecutionPolicy Bypass -File .\run.ps1 fresh -Yes
#>

[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [ValidateSet('up','rebuild','fresh','logs','stop','down','status','shell','psql','help')]
    [string]$Action = 'up',

    [int]$AppPort = 3001,
    [int]$DbPort = 5432,
    [int]$HealthTimeoutSeconds = 120,
    [switch]$Yes
)

$ErrorActionPreference = 'Stop'
Set-Location -Path $PSScriptRoot

$AppUrl = "http://localhost:$AppPort"

function Write-Log  { param($m) Write-Host "[run]  $m" -ForegroundColor Cyan }
function Write-Ok   { param($m) Write-Host "[ok]   $m" -ForegroundColor Green }
function Write-Warn2{ param($m) Write-Host "[warn] $m" -ForegroundColor Yellow }
function Die        { param($m) Write-Host "[err]  $m" -ForegroundColor Red; exit 1 }

# Resolve `docker compose` (v2) vs legacy `docker-compose`
function Resolve-Compose {
    $null = & docker compose version 2>$null
    if ($LASTEXITCODE -eq 0) { return @('docker','compose') }
    if (Get-Command docker-compose -ErrorAction SilentlyContinue) { return @('docker-compose') }
    Die "docker compose not found. Install Docker Desktop or the compose plugin."
}
$Script:DC = Resolve-Compose

function Invoke-Compose {
    param([Parameter(ValueFromRemainingArguments=$true)] [string[]]$Args)
    $exe, $rest = $Script:DC[0], $Script:DC[1..($Script:DC.Count-1)]
    & $exe @rest @Args
    return $LASTEXITCODE
}

function Require-Docker {
    if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
        Die "docker CLI not found in PATH. Install Docker Desktop."
    }
    & docker info *> $null
    if ($LASTEXITCODE -ne 0) {
        Die "Docker daemon not reachable. Start Docker Desktop and retry."
    }
}

function Test-PortInUse {
    param([int]$Port)
    try {
        $conns = Get-NetTCPConnection -State Listen -LocalPort $Port -ErrorAction Stop
        return [bool]$conns
    } catch { return $false }
}

function Get-ComposeProjectName {
    if ($env:COMPOSE_PROJECT_NAME) { return $env:COMPOSE_PROJECT_NAME }
    # docker compose normalizes: lowercase the dir name, strip chars not in [a-z0-9_-]
    $name = (Split-Path -Leaf $PSScriptRoot).ToLower()
    return ($name -replace '[^a-z0-9_-]', '')
}

function Get-DbVolumeName { return "$(Get-ComposeProjectName)_db-data" }

function Test-DbVolumePresent {
    & docker volume inspect (Get-DbVolumeName) *> $null
    return ($LASTEXITCODE -eq 0)
}

function Show-DbDetection {
    $vol = Get-DbVolumeName
    if (Test-DbVolumePresent) {
        Write-Ok "Existing database volume detected ($vol) - preserving data."
        Write-Log "Init scripts in models/*.sql will NOT run (Postgres only seeds an empty volume)."
        Write-Log "Use '.\run.ps1 fresh' if you intentionally want to wipe and re-seed."
    } else {
        Write-Log "No existing database volume found - Postgres will initialize from models/*.sql."
    }
}

function Preflight-Ports {
    foreach ($p in @($AppPort, $DbPort)) {
        if (Test-PortInUse -Port $p) {
            Write-Warn2 "Port $p is already in use on the host."
            Write-Warn2 "If it's a previous run, '.\run.ps1 down' first; otherwise free the port."
        }
    }
}

function Wait-ForHealth {
    Write-Log "Waiting for stack to become healthy (timeout ${HealthTimeoutSeconds}s)..."
    $deadline = (Get-Date).AddSeconds($HealthTimeoutSeconds)
    $dbOk = $false; $appOk = $false

    while ((Get-Date) -lt $deadline) {
        if (-not $dbOk) {
            & $Script:DC[0] @($Script:DC[1..($Script:DC.Count-1)]) exec -T db pg_isready -U postgres -d board *> $null
            if ($LASTEXITCODE -eq 0) { Write-Ok "db is accepting connections"; $dbOk = $true }
        }
        if (-not $appOk -and $dbOk) {
            try {
                $r = Invoke-WebRequest -UseBasicParsing -Uri $AppUrl -TimeoutSec 2 -ErrorAction Stop
                if ($r.StatusCode -ge 200) { Write-Ok "app is responding at $AppUrl"; $appOk = $true }
            } catch { }
        }
        if ($dbOk -and $appOk) { return $true }
        Start-Sleep -Seconds 2
    }

    Write-Warn2 "Health check timed out. Recent logs:"
    Invoke-Compose logs --tail=40 | Out-Null
    return $false
}

function Print-Summary {
    Write-Host ""
    Write-Host "===== The-Board is up =====" -ForegroundColor Green
    Write-Host "  App:        $AppUrl"
    Write-Host "  Board UI:   $AppUrl/board"
    Write-Host "  Postgres:   localhost:$DbPort  (user=postgres db=board)"
    Write-Host ""
    Write-Host "Handy commands:"
    Write-Host "  .\run.ps1 logs     # tail logs"
    Write-Host "  .\run.ps1 status   # container + health status"
    Write-Host "  .\run.ps1 shell    # shell into app container"
    Write-Host "  .\run.ps1 psql     # psql into db container"
    Write-Host "  .\run.ps1 down     # stop and remove containers"
    Write-Host ""
}

function Confirm-Destructive {
    param([string]$Message)
    if ($Yes) { return $true }
    $reply = Read-Host "$Message [y/N]"
    return ($reply -match '^(y|yes)$')
}

function Cmd-Up {
    Require-Docker
    Show-DbDetection
    Preflight-Ports
    Write-Log "Building images from $(Split-Path -Leaf $PSScriptRoot)..."
    Invoke-Compose build | Out-Null
    if ($LASTEXITCODE -ne 0) { Die "docker compose build failed." }
    Write-Log "Starting stack in detached mode..."
    Invoke-Compose up -d | Out-Null
    if ($LASTEXITCODE -ne 0) { Die "docker compose up failed." }
    if (-not (Wait-ForHealth)) { Die "Stack failed to come up cleanly." }
    Print-Summary
}

function Cmd-Rebuild {
    Require-Docker
    Show-DbDetection
    Write-Log "Forcing image rebuild (no cache)..."
    Invoke-Compose build --no-cache | Out-Null
    if ($LASTEXITCODE -ne 0) { Die "docker compose build failed." }
    Invoke-Compose up -d | Out-Null
    if ($LASTEXITCODE -ne 0) { Die "docker compose up failed." }
    if (-not (Wait-ForHealth)) { Die "Stack failed to come up cleanly." }
    Print-Summary
}

function Cmd-Fresh {
    Require-Docker
    $phrase = "This will delete my database"
    $vol = Get-DbVolumeName
    $present = Test-DbVolumePresent
    Write-Warn2 "============================================================"
    Write-Warn2 " DANGER: This will permanently DELETE the Postgres volume."
    if ($present) {
        Write-Warn2 " Target volume: $vol  (EXISTS - has data)"
    } else {
        Write-Warn2 " Target volume: $vol  (not present - nothing to lose)"
    }
    Write-Warn2 " All tickets, technicians, reports, and users will be lost."
    Write-Warn2 "============================================================"
    Write-Host ""
    Write-Host "To proceed, type the following phrase exactly:" -ForegroundColor Yellow
    Write-Host "  $phrase" -ForegroundColor Yellow
    $reply = Read-Host "Confirmation"
    if ($reply -cne $phrase) { Die "Phrase did not match. Aborted (no changes made)." }
    Invoke-Compose down -v | Out-Null
    Invoke-Compose build --no-cache | Out-Null
    if ($LASTEXITCODE -ne 0) { Die "docker compose build failed." }
    Invoke-Compose up -d | Out-Null
    if ($LASTEXITCODE -ne 0) { Die "docker compose up failed." }
    if (-not (Wait-ForHealth)) { Die "Stack failed to come up cleanly." }
    Print-Summary
}

function Cmd-Logs   { Require-Docker; Invoke-Compose logs -f --tail=100 }
function Cmd-Stop   { Require-Docker; Invoke-Compose stop | Out-Null;  Write-Ok "Stopped (data preserved)." }
function Cmd-Down   { Require-Docker; Invoke-Compose down | Out-Null;  Write-Ok "Containers removed (volume preserved)." }
function Cmd-Status { Require-Docker; Invoke-Compose ps }
function Cmd-Shell  { Require-Docker; Invoke-Compose exec app sh }
function Cmd-Psql   { Require-Docker; Invoke-Compose exec db psql -U postgres -d board }

switch ($Action) {
    'up'      { Cmd-Up }
    'rebuild' { Cmd-Rebuild }
    'fresh'   { Cmd-Fresh }
    'logs'    { Cmd-Logs }
    'stop'    { Cmd-Stop }
    'down'    { Cmd-Down }
    'status'  { Cmd-Status }
    'shell'   { Cmd-Shell }
    'psql'    { Cmd-Psql }
    'help'    { Get-Help -Full $PSCommandPath }
}
