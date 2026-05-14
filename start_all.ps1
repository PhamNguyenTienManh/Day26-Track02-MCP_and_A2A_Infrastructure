$ErrorActionPreference = "Stop"

# Start all Legal Multi-Agent System services for Windows / PowerShell.
# Registry must start first, then leaf agents, then orchestrators.

$root = Split-Path -Parent $MyInvocation.MyCommand.Path

function Start-ServiceJob {
    param(
        [string]$Name,
        [string]$Module,
        [int]$Port
    )

    Write-Host "Starting $Name on port $Port..."
    return Start-Process `
        -FilePath "uv" `
        -ArgumentList @("run", "python", "-m", $Module) `
        -WorkingDirectory $root `
        -WindowStyle Hidden `
        -PassThru
}

$processes = @()

try {
    $processes += Start-ServiceJob -Name "Registry" -Module "registry" -Port 10000
    Start-Sleep -Seconds 2

    $processes += Start-ServiceJob -Name "Tax Agent" -Module "tax_agent" -Port 10102
    $processes += Start-ServiceJob -Name "Compliance Agent" -Module "compliance_agent" -Port 10103
    Start-Sleep -Seconds 3

    $processes += Start-ServiceJob -Name "Law Agent" -Module "law_agent" -Port 10101
    Start-Sleep -Seconds 3

    $processes += Start-ServiceJob -Name "Customer Agent" -Module "customer_agent" -Port 10100

    Write-Host ""
    Write-Host "All services started:"
    Write-Host "  Registry:         http://localhost:10000"
    Write-Host "  Customer Agent:   http://localhost:10100"
    Write-Host "  Law Agent:        http://localhost:10101"
    Write-Host "  Tax Agent:        http://localhost:10102"
    Write-Host "  Compliance Agent: http://localhost:10103"
    Write-Host ""
    Write-Host "Run the test client in another terminal:"
    Write-Host "  uv run python test_client.py"
    Write-Host ""
    Write-Host "Started process IDs: $($processes.Id -join ', ')"
    Write-Host "Use Stop-Process -Id <pid list> to stop them."
}
catch {
    Write-Error "Failed to start all services: $_"
    foreach ($process in $processes) {
        if ($process -and -not $process.HasExited) {
            Stop-Process -Id $process.Id -Force
        }
    }
    throw
}
