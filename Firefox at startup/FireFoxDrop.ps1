#Firefox at startup


#Common log folder path
$CommonLogPath = "C:\Windows\AzureToTheMax"
#Individual log folder
$IndividualLogPath = "Firefox"
#Log File
$LogFile = "Firefox-At-Startup.log"

$FullLogPath = "$($CommonLogPath)\$($IndividualLogPath)"
$FullLogFile = "$($CommonLogPath)\$($IndividualLogPath)\$($LogFile)"


#Create storage dirs if needed
if (Test-Path $CommonLogPath) {
    write-host "Common log folder Folder exists already."
    } else {
    New-Item $CommonLogPath -ItemType Directory -ErrorAction SilentlyContinue > $null 
    $folder = Get-Item "$CommonLogPath" 
    $folder.Attributes = 'Directory','Hidden' 
    }
    
    if (Test-path $FullLogPath) {
    write-host "$($FullLogPath) Folder exists already."
    } else {
    New-Item $FullLogPath -ItemType Directory -ErrorAction SilentlyContinue > $null 
    $folder = Get-Item $FullLogPath 
    $folder.Attributes = 'Directory','Hidden'    
    }    

#log
Add-Content "$($FullLogFile)" "

$(get-date): Firefox install dropping on $($env:COMPUTERNAME)" -Force


#Copy all the files
Copy-Item ".\drop_files\*" "$($FullLogPath)"

#Create the scheduled task
$action = New-ScheduledTaskAction -Execute 'Powershell.exe' -Argument '-NoProfile -WindowStyle Hidden -executionpolicy bypass "C:\Windows\AzureToTheMax\FireFox\FireFox-Install.ps1"'
$trigger = New-ScheduledTaskTrigger -AtStartup
$principal = New-ScheduledTaskPrincipal -UserID "NT AUTHORITY\SYSTEM" -LogonType ServiceAccount -RunLevel Highest
$conditions = New-ScheduledTaskSettingsSet -DisallowDemandStart -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -DontStopOnIdleEnd
Register-ScheduledTask -TaskName "Firefox Install" -Action $action -Trigger $trigger -Principal $principal -Settings $conditions


#Log it
Add-Content "$($FullLogFile)" "$(Get-Date): Firefox drop complete on $($env:COMPUTERNAME)" -Force

exit 0