# Installs any driver signing certificates (cer) and print drivers (inf) found within a source folder
# Place extracted driver packages in a Drivers subfolder - run in system context.

# run with Administrative rights, or for Intune deploy in System context to groups of users

$rootfolder     = $PSScriptRoot
$driverSourceFolder = Join-Path $rootfolder "Drivers"             # this folder is removed after a successful setup
$inputfile      = Join-Path $rootfolder "PrinterDetails.txt"      # tab delimited file containing columns 'printername' 'drivername' 'ipaddress' 'port' 'location'
# moved to PrintInst4intune-user.ps1 ==> $colour         = $false         # default to black only, set to $true for colour
# moved to PrintInst4intune-user.ps1 ==> $duplex         = "Onesided"     # default to one-sided, can be set to TwoSidedLongEdge or TwoSidedShortEdge
$filterinf      = "*.inf"                                         # the files that enable the import and installation of printer drivers
$filtercer      = "*.cer"                                         # the certificate files that may exist in the source structure
$certstoreroot  = "Cert:\LocalMachine\Root"                       # the local machine root certificate store to which cer files are imported
$certstoretrusted  = "Cert:\LocalMachine\TrustedPublisher"        # the local machine trusted publisher certificate store to which cer files are imported
$logfile        = Join-Path $rootfolder "_PrintInst4intune.log"
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
if (-not(Test-Path -LiteralPath $driverSourceFolder -PathType Container -ErrorAction Ignore)) {
    $null = Stop-Transcript
    throw "The driver source folder $driverSourceFolder does not exist!"
}

$cerdetail  = Get-ChildItem -LiteralPath $driverSourceFolder -Filter $filtercer -File -Recurse
$infdetail  = Get-ChildItem -LiteralPath $driverSourceFolder -Filter $filterinf -File -Recurse

if ($null -eq $cerdetail) {
    Write-Output "No certificates found in $driverSourceFolder..."
    Write-Output "***"
} else {
    Clear-Host
    Write-Output "" 
    Write-Output "Installing certificates found in $driverSourceFolder..."
    Write-Output "" 
    
    foreach ($cer in $cerdetail) {
        $cerpath   = $cer.FullName
        try {
            Import-Certificate -FilePath $cerpath -CertStoreLocation $certstoreroot -ErrorAction Stop | Out-Null
            Import-Certificate -FilePath $cerpath -CertStoreLocation $certstoretrusted -ErrorAction Stop | Out-Null
        } catch {
            Write-Warning "!!! Failed to install certificate from ${cerpath}: $($_.Exception.Message)"
            Write-Output "***"
            $warningcount = $warningcount + 1
        }
    }    
}

if ($null -eq $infdetail) {
    $null = Stop-Transcript
    throw "No INF files found in $driverSourceFolder... exiting."
} else {
    Clear-Host
    Write-Output "" 
    Write-Output "Importing drivers found in $driverSourceFolder..."
    Write-Output "" 
    
    foreach ($inf in $infdetail) {
        $infpath = $inf.FullName
    
        try {
            & pnputil.exe /add-driver $infpath /install
            $pnputilExitCode = $LASTEXITCODE
            if ($pnputilExitCode -ne 0) {
                Write-Warning "!!! Failed to import drivers from ${infpath} (pnputil exit code $pnputilExitCode)"
                Write-Output "***"
                $warningcount = $warningcount + 1
            } else {
                Write-Output "Successfully imported drivers from $infpath"
                Write-Output "***"
            }
        } catch {
            Write-Warning "!!! Failed to run pnputil for ${infpath}: $($_.Exception.Message)"
            Write-Output "***"
            $warningcount = $warningcount + 1
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

if ($warningcount -eq 0) {
    try {
        Remove-Item -LiteralPath $driverSourceFolder -Recurse -Force -ErrorAction Stop
        Write-Output "Removed driver source folder $driverSourceFolder"
    } catch {
        Write-Warning "!!! Driver setup succeeded, but failed to remove ${driverSourceFolder}: $($_.Exception.Message)"
        $warningcount = $warningcount + 1
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
