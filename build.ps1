#!/usr/bin/env pwsh
param(
    [switch]$BuildOnly,
    [switch]$Help,
    [string]$ConfigFile
)

$ProjectRoot = $PSScriptRoot
$ImageName = "kioskbuilder"
$ImageTag = "latest"

function Build-Image {
    Write-Host "Building Docker image..."
    docker build -t "$ImageName`:$ImageTag" -f "$ProjectRoot\docker\Dockerfile" $ProjectRoot
}

function Show-Help {
    Write-Host "Usage: .\build.ps1 [options] <config.yml>"
    Write-Host ""
    Write-Host "Options:"
    Write-Host "  -BuildOnly     Only build the Docker image, don't run it"
    Write-Host "  -Help          Show this help message"
    Write-Host ""
    Write-Host "Example:"
    Write-Host "  .\build.ps1 example.yml"
}

if ($Help) {
    Show-Help
    exit 0
}

if (-not $ConfigFile -and $args.Count -gt 0) {
    $ConfigFile = $args[0]
}

if (-not $ConfigFile -and -not $BuildOnly) {
    Show-Help
    exit 1
}

if ($ConfigFile) {
    if (-not [System.IO.Path]::IsPathRooted($ConfigFile)) {
        $ConfigFile = Join-Path $PWD $ConfigFile
    }

    if (-not (Test-Path $ConfigFile)) {
        Write-Host "Error: Config file does not exist: $ConfigFile"
        exit 1
    }
}

Build-Image

if ($BuildOnly) {
    Write-Host "Docker image built successfully"
    exit 0
}

$ConfigDir = [System.IO.Path]::GetDirectoryName($ConfigFile)
$ConfigFilename = [System.IO.Path]::GetFileName($ConfigFile)

Write-Host "Running KioskBuilder with config: $ConfigFile"

docker run --rm -it `
    --privileged `
    -v "${ConfigFile}:/config.yml" `
    -v "${ConfigDir}:/output" `
    "${ImageName}:${ImageTag}"
