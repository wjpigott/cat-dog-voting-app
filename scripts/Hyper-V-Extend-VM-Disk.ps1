# Hyper-V VM Disk Extension Script for Windows Server 2025
# Run this in an Administrator PowerShell session

# Variables - Update these to match your VM
$VMName = "YourVMName"  # Replace with your actual VM name
$AdditionalSizeGB = 30   # Adding 30GB

Write-Host "🔍 Finding your Ubuntu VM..." -ForegroundColor Cyan

# List all VMs to help identify the correct one
Get-VM | Select-Object Name, State, @{Name="CPUs";Expression={$_.ProcessorCount}}, @{Name="MemoryGB";Expression={[math]::Round($_.MemoryAssigned/1GB,2)}}

Write-Host "`n📝 Please update the `$VMName variable above with your Ubuntu VM name" -ForegroundColor Yellow
Write-Host "Then run the following commands:" -ForegroundColor Yellow

Write-Host "`n# 1. Stop the VM" -ForegroundColor Green
Write-Host "Stop-VM -Name '$VMName' -Force"

Write-Host "`n# 2. Get the current VHD path and size" -ForegroundColor Green
Write-Host "`$VHD = Get-VMHardDiskDrive -VMName '$VMName' | Select-Object -First 1"
Write-Host "`$VHDPath = `$VHD.Path"
Write-Host "`$CurrentSize = (Get-VHD -Path `$VHDPath).Size"
Write-Host "`$NewSize = `$CurrentSize + ($AdditionalSizeGB * 1GB)"
Write-Host "Write-Host `"Current size: `$([math]::Round(`$CurrentSize/1GB,2)) GB`""
Write-Host "Write-Host `"New size will be: `$([math]::Round(`$NewSize/1GB,2)) GB`""

Write-Host "`n# 3. Resize the VHD" -ForegroundColor Green
Write-Host "Resize-VHD -Path `$VHDPath -SizeBytes `$NewSize"

Write-Host "`n# 4. Start the VM" -ForegroundColor Green
Write-Host "Start-VM -Name '$VMName'"

Write-Host "`n# 5. Verify the new size" -ForegroundColor Green
Write-Host "Get-VHD -Path `$VHDPath | Select-Object Path, @{Name=`"SizeGB`";Expression={[math]::Round(`$_.Size/1GB,2)}}"

Write-Host "`n📋 Alternative: One-liner command (update VM name first):" -ForegroundColor Magenta
Write-Host "Stop-VM -Name 'YourVMName' -Force; `$vhd = (Get-VMHardDiskDrive -VMName 'YourVMName')[0].Path; Resize-VHD -Path `$vhd -SizeBytes ((Get-VHD -Path `$vhd).Size + 30GB); Start-VM -Name 'YourVMName'"