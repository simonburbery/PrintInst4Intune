PrintInst4Intune

 Use for modern workplace printing setups i.e. no print server (for basic requirements not warranting spend on a cloud printing or other solution).
  
 A two-part script: 
 **Device-targeted script** - PrintInst4Intune.ps1:
 - installs any driver signing certificates (cer) found within a source folder.
 - installs any print drivers (inf)
 - creates TCP/IP printer ports on the workstation.

Prep - list the actual driver names required for the input file (advanced tab on a Windows printer queue); put all extracted print drivers and certificates in a dedicated `Drivers` subfolder alongside the scripts. The device-targeted script removes this folder only after setup completes without errors.
Deploy in System context to devices.

NOTE: _Expired_ certs may still prompt, preventing a silent install.  In this case you need to reach out to the vendor to provide an up-to-date driver package.

 **User-targeted script:**  PrintInst4Intune-user.ps1:
 - Adds any printer connections based on group memebership.
 - Sets the specified printer property defaults.
 - (optional) sets a default printer based on group membership or input file.

 Deploy using System context to groups of users.

 To test:
 1. Download the driver folders (SATO, Xerox and Seagull) into a `Drivers` subfolder.
 2. Download PrintInst4intune.ps1, PrintInst4intune-user.ps1 and PrinterDetails.txt into the parent folder.
 3. Run an Administrative Terminal or PowerShell session.
 4. Navigate to the parent folder.
 5. Run .\PrintInst4intune.ps1. You can launch Print Management to see the drivers and ports have been added. On success, the `Drivers` subfolder is deleted.
 6. Run .\PrintInst4intune-user.ps1. You will now see the printers have been installed and the AKL printer will be set as default.

I also have a write up about this at my Blog site - https://www.howdoiuseacomputer.com/index.php/2023/12/17/automating-printer-configuration-for-the-modern-workplace/

Cheers, Simon :) 

PrintInst4intune
