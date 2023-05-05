
#Common log folder path
$CommonLogPath = "C:\Windows\AzureToTheMax"
#Individual log folder
$IndividualLogPath = "Firefox"
#Log File
$LogFile = "Firefox-Uninstall.log"

#registry app name
$AppName = "Mozilla Firefox (x64 en-US)"

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


Add-Content "$($FullLogFile)" "
$(Get-Date): Firefox uninstall starting." -Force


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

    $value6 = Get-itemproperty $value3 -name "UninstallString"
    $UninstallString = $value6.UninstallString

        #Verify app is now right verion or greater
        Add-Content "$($FullLogFile)" "$(Get-Date): 32-Bit App found, uninstalling!.
        AppName: $($ProgramName)
        MSI code: $($_)
        Version: $($ver)" -Force

        Start-Process "$($UninstallString)" -ArgumentList "/Silent" -Wait

        #Start-Process "msiexec.exe" -ArgumentList "/x $($_) /quiet /norestart" -Wait
        
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

$value6 = Get-itemproperty $value3 -name "UninstallString"
$UninstallString = $value6.UninstallString


        #Verify app is now right verion or greater
        Add-Content "$($FullLogFile)" "$(Get-Date): 64-Bit App found, uninstalling!
        AppName: $($ProgramName)
        MSI code: $($_)
        Version: $($ver)" -Force
    
        Start-Process "$($UninstallString)" -ArgumentList "/Silent" -Wait

        #Start-Process "msiexec.exe" -ArgumentList "/x $($_) /quiet /norestart" -Wait
}
}


#log
Add-Content "$($FullLogFile)" "$(get-date): Firefox UNINSTALL complete on $($env:COMPUTERNAME)" -Force