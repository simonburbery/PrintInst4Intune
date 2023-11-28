# 
# Installs any driver signing certificates (cer) and print drivers (inf) found within a source folder
# Extract all print drivers into the same folder as the script - run in system context 
#
# [Optional] can also add the printers to the user session, set printer preferences and set a default printer
#            Or that part of the script starting with <### and ending with ###> can be separated out and deployed separately to add printers    
#
# run with Administrative rights, or for Intune deploy in System context to groups of devices or users
Set-Location C:\Temp
$rootfolder     = "c:\temp\"                                      # for intune use $rootfolder = ".\" 
$inputfile      = "$rootfolder" + "AddPrinterInputFile.txt"       # tab delimited file containing columns 'printername' 'drivername' 'ipaddress' 'port' 'location'
$colour         = $false                                          # default to black only, set to $true for colour
$duplex         = "Onesided"                                      # default to one-sided, can be set to TwoSidedLongEdge or TwoSidedShortEdge
$filterinf      = "*.inf"                                         # the files in the root folder structure that enable the import and installation of printer drivers 
$filtercer      = "*.cer"                                         # the certificate files that may exist in the source structure
$certstore      = "cert:\LocalMachine\Root"                       # the local machine certificate store to which cer files are imported
$logfile        = "$rootfolder" + "_PrintInsts4intune.log"        # for intune use $logfile = "$env:TEMP" + "\_printinst4intune.log"
$warningcount   = 0                                               # any actions that fail increment this counter

$null = Start-Transcript -Path $logfile

$x = 300
Do {
    Restart-Service Spooler
    Start-Sleep -Seconds 1
    $x = $x - 1
    if ($x -eq 0) { 
        throw "Spooler did not restart!" 
    }
} until (Get-Service Spooler | Where-Object { $_.Status -eq "Running" })

if (-not(Test-Path -Path $rootfolder -ErrorAction Ignore)) {
    throw "The root folder $rootfolder does not exist!"
}
if (-not(Test-Path -Path $inputfile -ErrorAction Ignore)) {
    throw "The input file $inputfile does not exist!"
}

$cerdetail  = Get-ChildItem -Path $rootfolder -Filter $filtercer -File -Recurse
$infdetail  = Get-ChildItem -Path $rootfolder -Filter $filterinf -File -Recurse

Clear-Host
Write-Output "" 
Write-Output "Installing any certificates found in $rootfolder..."
Write-Output ""

foreach ($cer in $cerdetail) {
    $cerpath   = $cer.FullName
    Import-Certificate -FilePath $cerpath -CertStoreLocation $certstore
}

Clear-Host
Write-Output "" 
Write-Output "Importing any drivers found in $rootfolder..."
Write-Output "" 

foreach ($inf in $infdetail) {
    $infpath          = $inf.FullName

Start-Process "Pnputil.exe" -ArgumentList "/add-driver $infpath /install" -Wait
    if ($? -ne "True") {
        Write-Warning "!!! Failed to import drivers from $infpath"
        $warningcount = $warningcount + 1
    } else {
        Write-Output ""
        Write-Output "Successfully imported drivers from $infpath"
        Write-Output ""
      }
}

Clear-Host
Write-Output ""
Write-Output "Adding drivers, ports and printers specified in $inputfile..."
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
        $warningcount = $warningcount + 1
    } else {
        Write-Output "Successfully added $drivername driver for $printername"
        Write-Output ""
      }

if (-not(Get-PrinterPort -Name "tcpip_$ipaddress" -ErrorAction Ignore)) { 
    Add-PrinterPort -Name "tcpip_$ipaddress" -PrinterHostAddress $ipaddress -PortNumber $port
        if ($? -ne "True") {    
            Write-Warning "!!! Failed to add tcpip_$ipaddress port for $printername"
            $warningcount = $warningcount + 1
        } else {
            Write-Output "Successfully added tcpip_$ipaddress port for $printername"
            Write-Output ""
          }
} else {
    Write-Output "Port tcpip_$ipaddress exists... skipping"
    Write-Output ""
  }
}

# <### Add printers and set properties

# Uncomment this section or run it as a separate script, depending on whether you can deploy all drivers and all printers in one script.
# You could install many drivers in one package, then use this part of the script deployed with different input files to add printers / set as default. 
# NOTE: Use the system context in your user targeted deployments as it is required to set the print configurations (at this stage unconfirmed) 

$rootfolder     = "c:\temp\"                                      # for intune use $rootfolder = ".\" 
$inputfile      = "$rootfolder" + "AddPrinterInputFile.txt"       # tab delimited file containing columns 'printername' 'drivername' 'ipaddress' 'port' 'location'
$colour         = $false                                          # $false for greyscale, $true for colour
$duplex         = "Onesided"                                      # default to one-sided, can be set to TwoSidedLongEdge or TwoSidedShortEdge
$logfile        = "$rootfolder" + "_PrintInsts4intune.log"        # for intune use $logfile = "$env:TEMP" + "\_addprinters4intune.log"

$printerdetails = Import-Csv $inputfile -Delimiter "`t" 

foreach ($printer in $printerdetails) {
    $printername    = $printer.PrinterName
    $drivername     = $printer.DriverName
    $ipaddress      = $printer.IPAddress
    $port           = $printer.Port
    $location       = $printer.location

if (-not(Get-Printer -Name $printername -ErrorAction Ignore)) {
    Add-Printer -Name $printername -DriverName $drivername -PortName "tcpip_$ipaddress" -Comment "$ipaddress - $drivername" -Location $location
        if ($? -ne "True") {    
            Write-Warning "Failed to add $printername"
            $warningcount = $warningcount + 1
        } else {
            Write-Output "Success adding $printername"
            Write-Output ""
          }
} else {
    Write-Output "Printer $printername exists... skipping"
    Write-Output ""
  }

Set-PrintConfiguration -PrinterName $printername -Color $colour -DuplexingMode $duplex
    if ($? -ne "True") {    
        Write-Warning "!!! Failed to set properties for $printername"
        $warningcount = $warningcount + 1
    } else {
        Write-Output "Success setting properties for $printername"
        Write-Output ""
      }

# Set default printer

# if deploying to groups we can set the default printer using only the Class and Invoke-CimMethod lines.
# or we could use an if statement using the location or another column. e.g. HR,Sales,Accounts or AKL,WLG,CHC. 
# Add column(s) and data to the input file to cater for your needs.
if ($location -eq "AKL") {
    $defaultprinter = Get-CimInstance -Class Win32_Printer -Filter "Name='$printername'"
    Invoke-CimMethod -InputObject $defaultprinter -MethodName SetDefaultPrinter
        if ($? -ne "True") {    
            Write-Warning "!!! Failed to set $printername as default"
            $warningcount = $warningcount + 1
    } else {
        Write-Output "Success setting $printername as default"
        Write-Output ""
      }
}
}

# ###>

$null = Stop-Transcript
Clear-Host

    if ($warningcount -eq 0) {
        Write-Output ""
        Write-Output "No errors occurred - all system print components installed successfully"
        Write-Output "Log file saved to $logfile." 
    } else {
        Write-Output ""
        Write-Output "There were $warningcount errors - please review $logfile"
    }
