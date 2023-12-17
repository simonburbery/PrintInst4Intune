# Installs any driver signing certificates (cer) and print drivers (inf) found within a source folder
# Extract all print drivers into the same folder as the script - run in system context.

# run with Administrative rights, or for Intune deploy in System context to groups of users

$rootfolder     = "c:\temp\"                                      # for intune use $rootfolder = ".\" 
$inputfile      = "$rootfolder" + "PrinterDetails.txt"       # tab delimited file containing columns 'printername' 'drivername' 'ipaddress' 'port' 'location'
# moved to PrintInst4intune-user.ps1 ==> $colour         = $false         # default to black only, set to $true for colour
# moved to PrintInst4intune-user.ps1 ==> $duplex         = "Onesided"     # default to one-sided, can be set to TwoSidedLongEdge or TwoSidedShortEdge
$filterinf      = "*.inf"                                         # the files in the root folder structure that enable the import and installation of printer drivers 
$filtercer      = "*.cer"                                         # the certificate files that may exist in the source structure
$certstoreroot  = "Cert:\LocalMachine\Root"                       # the local machine root certificate store to which cer files are imported
$certstoretrusted  = "Cert:\LocalMachine\TrustedPublisher"        # the local machine trusted publisher certificate store to which cer files are imported
$logfile        = "$rootfolder" + "_PrintInst4intune.log"         # for intune use $logfile = "$env:TEMP" + "\_printinst4intune.log"
$warningcount   = 0                                               # any actions that fail increment this counter

$null = Start-Transcript -Path $logfile

$x = 300
Do {
    Restart-Service Spooler
    Start-Sleep -Seconds 1
    $x = $x - 1
    if ($x -eq 0) { 
        $null = Stop-Transcript
        throw "Spooler did not restart!"
    }
} until (Get-Service Spooler | Where-Object { $_.Status -eq "Running" })

if (-not(Test-Path -Path $rootfolder -ErrorAction Ignore)) {
    $null = Stop-Transcript
    throw "The root folder $rootfolder does not exist!"
}
if (-not(Test-Path -Path $inputfile -ErrorAction Ignore)) {
    $null = Stop-Transcript
    throw "The input file $inputfile does not exist!"
}

$cerdetail  = Get-ChildItem -Path $rootfolder -Filter $filtercer -File -Recurse
$infdetail  = Get-ChildItem -Path $rootfolder -Filter $filterinf -File -Recurse

if ($null -eq $cerdetail) {
    Write-Output "No certificates found in $rootfolder..."
    Write-Output "***"
} else {
    Clear-Host
    Write-Output "" 
    Write-Output "Installing certificates found in $rootfolder..."
    Write-Output "" 
    
    foreach ($cer in $cerdetail) {
        $cerpath   = $cer.FullName
        Import-Certificate -FilePath $cerpath -CertStoreLocation $certstoreroot
        Import-Certificate -FilePath $cerpath -CertStoreLocation $certstoretrusted
    }    
}

if ($null -eq $infdetail) {
    $null = Stop-Transcript
    throw "No INF files found in $rootfolder... exiting."
} else {
    Clear-Host
    Write-Output "" 
    Write-Output "Importing drivers found in $rootfolder..."
    Write-Output "" 
    
    foreach ($inf in $infdetail) {
        $infpath = $inf.FullName
    
    Start-Process "Pnputil.exe" -ArgumentList "/add-driver $infpath /install" -Wait
        if ($? -ne "True") {
            Write-Warning "!!! Failed to import drivers from $infpath"
            Write-Output "***"
            $warningcount = $warningcount + 1
        } else {
            Write-Output "Successfully imported drivers from $infpath"
            Write-Output "***"
          }
    }    
}    

Clear-Host
Write-Output ""
Write-Output "Adding drivers and ports specified in $inputfile..."
Write-Output ""

# import input file
$printerdetails = Import-Csv $inputfile -Delimiter "`t" 

foreach ($printer in $printerdetails) {
    $printername    = $printer.PrinterName
    $drivername     = $printer.DriverName
    $ipaddress      = $printer.IPAddress
    $port           = $printer.Port

Add-PrinterDriver -Name $drivername
    if ($? -ne "True") {    
        Write-Warning "!!! Failed to add $drivername driver for $printername"
        Write-Output "***"
        $warningcount = $warningcount + 1
    } else {
        Write-Output "Successfully added $drivername driver for $printername"
        Write-Output "***"
      }

if (-not(Get-PrinterPort -Name "tcpip_$ipaddress" -ErrorAction Ignore)) { 
    Add-PrinterPort -Name "tcpip_$ipaddress" -PrinterHostAddress $ipaddress -PortNumber $port
        if ($? -ne "True") {    
            Write-Warning "!!! Failed to add tcpip_$ipaddress port for $printername"
            Write-Output "***"
            $warningcount = $warningcount + 1
        } else {
            Write-Output "Successfully added tcpip_$ipaddress port for $printername"
            Write-Output "***"
          }
} else {
    Write-Output "Port tcpip_$ipaddress exists... skipping"
    Write-Output "***"
  }
}

$null = Stop-Transcript
Clear-Host

if ($warningcount -eq 0) {
    Write-Output "***"
    Write-Output "No errors occurred - drivers and ports added successfully"
    Write-Output "Please Note: this script has NOT added any printers to the user session. Use PrintInst4intune-user.ps1 to deploy printers to users."
    Write-Output "Log file saved to $logfile."
    Write-Output "***"
} else {
    Write-Output "***"
    Write-Output "There were $warningcount errors - please review $logfile"
    Write-Output "***"
  }
