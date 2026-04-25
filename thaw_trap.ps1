# "Thaw-Trap" Watcher Script
# Purpose: Detect when the System Drive (C:) becomes THAWED and apply permanent persistence.

$setupScript = "D:\EnterpriseTools\Bin\setup_persistence.ps1"
$persistentLog = "D:\EnterpriseTools\Bin\thaw_trap.log"

Write-Host "Thaw-Trap Watcher active. Monitoring WriteFilter state..." -ForegroundColor Cyan

while ($true) {
    # 1. Check UWF (Unified Write Filter) state
    # If UWF is disabled or 'CurrentSession' is false, the system might be Thawed.
    $uwfStatus = cmd /c "uwfmgr get-config" | Out-String
    
    # 2. Check for common admin/installer processes that indicate maintenance mode
    $installerProcesses = Get-Process | Where-Object { $_.Name -match "setup|installer|msiexec|dism|v3gui" } # v3gui for Deep Freeze

    if ($uwfStatus -match "Current Session: Disabled" -or $null -ne $installerProcesses) {
        Write-Host "THAWED state or Maintenance detected! Initiating Permanent Installation..." -ForegroundColor Green
        
        if (Test-Path $setupScript) {
            # Execute the setup script to bake persistence into C:
            powershell.exe -ExecutionPolicy Bypass -File $setupScript
            
            "$(Get-Date): Persistence applied during Thaw event." | Out-File -FilePath $persistentLog -Append
            
            # Mission accomplished - exit to avoid redundant execution
            break
        }
    }

    # Check every 60 seconds
    Start-Sleep -Seconds 60
}
