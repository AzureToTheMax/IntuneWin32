#Firefox install at startup


#Common log folder path
$CommonLogPath = "C:\Windows\AzureToTheMax"
#Individual log folder
$IndividualLogPath = "Firefox"
#Log File
$LogFile = "Firefox-At-Startup.log"

#Registry app name
$AppName = "Mozilla Firefox (x64 en-US)"
#Registry App version
$AppVersion = [Version]"112.0.2"
#Executable name
$ProcessName = "firefox"

#How long to sleep is MSIExec is busy
$MSIBusySleepTime = 30

$FullLogPath = "$($CommonLogPath)\$($IndividualLogPath)"
$FullLogFile = "$($CommonLogPath)\$($IndividualLogPath)\$($LogFile)"

#Don't touch this.
$tracked = 0


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




#Region Functions
Function CheckMSIStatus{
    <#
    .SYNOPSIS
    Check the MSI installer status to see if it is busy. If busy, wait X time and check again. 
    Only when free will this exit and then allow the script to proceed. Call this function right before running any MSI installer.
    
    .NOTES
    Author:      Maxton Allen
    Contact:     @AzureToTheMax
    Created:     2023-04-23
    Updated:     
    #>
    
    do {
        try
        {
            $Mutex = [System.Threading.Mutex]::OpenExisting("Global\_MSIExecute");
            $Mutex.Dispose();
            Write-Warning "Warning: An installer is currently running."
            Add-Content "$($FullLogFile)" "$(get-date): Warning: MSI Installer is busy! Waiting $($MSIBusySleepTime) seconds!" -Force
            start-sleep -Seconds $MSIBusySleepTime
        }
        catch
        {
            Write-Host "An installer is not currently runnning."
            Add-Content "$($FullLogFile)" "$(get-date): MSI Installer is NOT busy! Proceeding." -Force
            $Mutex = $null
        }
    } while ($null -ne $Mutex)
    }

#endregion






#start script

#log
Add-Content "$($FullLogFile)" "

$(get-date): Firefox install starting on $($env:COMPUTERNAME)" -Force


#Kill FireFox - cycles through all instances.
#Use this to verify a process is not running or kill it if it is.
if (Get-Process $ProcessName){
    write-host "$($ProcessName) is currently running!"

    Add-Content "$($FullLogFile)" "$(get-date): $($ProcessName) is currently running! Ending process(s)!" -Force
    Get-Process $ProcessName | ForEach-Object {
    write-host $_.ID
    Stop-Process -Id $_.ID -Force
    }
    
    } else {
    Add-Content "$($FullLogFile)" "$(get-date): $($ProcessName) is NOT currently running. Continuing." -Force
    }



#Check for busy MSI
CheckMSIStatus
#Upgrade or install Anyconnect Core
Add-Content "$($FullLogFile)" "$(get-date): Firefox MSI starting." -Force
Start-Process -FilePath "$($FullLogPath)\FireFoxSetup.msi" -ArgumentList "/qn" -Wait
Add-Content "$($FullLogFile)" "$(get-date): Firefox MSI complete." -Force

#log
Add-Content "$($FullLogFile)" "$(get-date): Firefox install complete on $($env:COMPUTERNAME)"

start-sleep -Seconds 3




#################################################
#verify install worked
#32-Bit
$value1 = (Get-ChildItem 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*') | Get-ItemProperty -name 'DisplayName' -ErrorAction SilentlyContinue
$value2 = $value1 | Where-Object {$_."Displayname" -eq "$($AppName)"} | Select-Object PSChildName -ErrorAction SilentlyContinue
$value2 = $value2.PSChildName

    If ($value2 -eq $null){
        Add-Content "$($FullLogFile)" "$(Get-Date): No 32-bit $($AppName) found." -Force

    } Else {
    $value2 | ForEach-Object -Process {
    $value3 = "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\" + "$($_)"
    $value4 = Get-itemproperty $value3 -name "displayversion"
    $ver = $value4.displayversion

    $value5 = Get-itemproperty $value3 -name "DisplayName"
    $ProgramName = $value5.DisplayName

        #Verify app is now right verion or greater
        if ($ver -ge $AppVersion){
        Add-Content "$($FullLogFile)" "$(Get-Date): 32-Bit App found and version check passed.
        AppName: $($ProgramName)
        MSI code: $($_)
        Version: $($ver)" -Force
        
        Add-Content "$($FullLogFile)" "$(get-date): $($AppName) install successful!"
        $tracked = $tracked + 1

        } else {
        Add-Content "$($FullLogFile)" "$(get-date): No 32-Bit app found."

        }
    }
}

#64-Bit
$value1 = (Get-ChildItem 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*') | Get-ItemProperty -name 'DisplayName' -ErrorAction SilentlyContinue
$value2 = $value1 | Where-Object {$_."Displayname" -eq "$($AppName)"} | Select-Object PSChildName -ErrorAction SilentlyContinue
$value2 = $value2.PSChildName

If ($value2 -eq $null){
    Add-Content "$($FullLogFile)" "$(Get-Date): No 64-bit $($AppName) found." -Force
} Else {
$value2 | ForEach-Object -Process {
$value3 = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\" + "$($_)"
#write-host "Value3 = $($value3)"
$value4 = Get-itemproperty $value3 -name "displayversion"
$ver = $value4.displayversion

$value5 = Get-itemproperty $value3 -name "DisplayName"
$ProgramName = $value5.DisplayName

        #Verify app is now right verion or greater
        if ($ver -ge $AppVersion){
            Add-Content "$($FullLogFile)" "$(Get-Date): 64-Bit App found and version check passed.
            AppName: $($ProgramName)
            MSI code: $($_)
            Version: $($ver)" -Force
            
            Add-Content "$($FullLogFile)" "$(get-date): $($AppName) install successful!"
            $tracked = $tracked + 1
    
            } else {
            Add-Content "$($FullLogFile)" "$(get-date): No 64-Bit app found."
    
            }
}
}


#Only if the app was found do we perform cleanup and complete correctly.
if ($tracked -ge 1){
    Add-Content "$($FullLogFile)" "$(Get-Date): App detected, cleanup starting." -Force

    #remove items
    Remove-Item "$($FullLogPath)\FireFoxSetup.msi" -Force

    start-sleep -Seconds 3

    #remove scheduled task
    Unregister-ScheduledTask -TaskName "Firefox Install" -Confirm:$false

    Add-Content "$($FullLogFile)" "$(get-date): Cleanup complete on $($env:COMPUTERNAME).
Ending." -Force

    exit 0

} else {
    Add-Content "$($FullLogFile)" "$(Get-Date): Failure: Tracked staus indicates failure to detect app. Cleaup will not proceed!" -Force
    exit 1

}





