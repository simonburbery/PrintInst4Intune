# Add printers, set properties and default printer

$rootfolder     = "c:\temp\"                                      # for intune or other deployment software use $rootfolder = ".\"
Set-Location $rootfolder
$inputfile      = $rootfolder + "PrinterDetails.txt"              # tab delimited file containing columns 'printername' 'drivername' 'ipaddress' 'port' 'location'
$colour         = $false                                          # $false for greyscale, $true for colour
$duplex         = "Onesided"                                      # default to one-sided, can be set to TwoSidedLongEdge or TwoSidedShortEdge
$logfile        = "$rootfolder" + "_PrintInst4intune.log"         # for intune use $logfile = "$env:TEMP" + "\_PrintInst4intune.log"

$null = Start-Transcript $logfile -Append -Force

$printerdetails = Import-Csv $inputfile -Delimiter "`t" 

foreach ($printer in $printerdetails) {
    $printername    = $printer.PrinterName
    $drivername     = $printer.DriverName
    $ipaddress      = $printer.IPAddress
#    $port           = $printer.Port
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
    }
# Set default printer

# if deploying with groups, you may have two queues for the printer 
# i.e. one to add the printer and another to add the printer and make it default. In this situation we can set the default printer using only the Class and Invoke-CimMethod lines without an if statement.
# or we could use an if statement using the location or another column. e.g. HR,Sales,Accounts or AKL,WLG,CHC. 
# Add column(s) and data to the input file to cater for your scenario.
if ($printername -eq "AKL-Default") {
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
# }

$null = Stop-Transcript -f
Clear-Host

if ($warningcount -eq 0) {
    Write-Output ""
    Write-Output "No errors occurred - printers added successfully"
    Write-Output "Log file saved to $logfile." 
} else {
    Write-Output ""
    Write-Output "There were $warningcount errors - please review $logfile"
  }
