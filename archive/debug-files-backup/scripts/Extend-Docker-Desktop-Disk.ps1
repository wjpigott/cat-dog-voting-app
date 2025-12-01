# Docker Desktop Kubernetes Disk Extension

# 1. Open Docker Desktop
# 2. Go to Settings -> Resources -> Advanced
# 3. Increase the "Disk image size" by 30GB
# 4. Click "Apply & Restart"

# Alternative: Command line approach
# Stop Docker Desktop
Stop-Process -Name "Docker Desktop" -Force -ErrorAction SilentlyContinue

# Increase Docker Desktop disk size via registry (adjust as needed)
$dockerConfigPath = "$env:APPDATA\Docker\settings.json"
if (Test-Path $dockerConfigPath) {
    $config = Get-Content $dockerConfigPath | ConvertFrom-Json
    $currentSize = $config.diskSizeMiB
    $newSize = $currentSize + 30720  # Add 30GB (30 * 1024 MB)
    $config.diskSizeMiB = $newSize
    $config | ConvertTo-Json -Depth 10 | Set-Content $dockerConfigPath
    Write-Host "Docker disk size increased from $currentSize MB to $newSize MB"
}

# Restart Docker Desktop
Start-Process "C:\Program Files\Docker\Docker\Docker Desktop.exe"