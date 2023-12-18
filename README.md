PrintInst4Intune

 Use for modern workplace printing setups i.e. no print server (when they have basic requirements not warranting spend on a cloud printing or other solution).
  
 A two-part script: 
 **Device-targeted script** - PrintInst4Intune.ps1:
 - installs any driver signing certificates (cer) found within a source folder.
 - installs any print drivers (inf)
 - creates TCP/IP printer ports on the workstation.

Prep - list the actual driver names required for the input file (advanced tab on a Windows printer queue); extract all print drivers into a source folder  
 along with the script.
Deploy in System context to devices.

NOTE: _Expired_ certs may still prompt, preventing a silent install.  In this case you need to reach out to the vendor to provide an up-to-date driver package.

 **User-targeted script:**  PrintInst4Intune-user.ps1:
 - Adds any printer connections based on group memebership.
 - Sets the specified printer property defaults.
 - (optional) sets a default printer based on group membership or input file.

 Deploy using System context to groups of users.

 To test:
 1. Download the three folders; SATO, Xerox and Seagull and save them into a folder (named anything you like).
 3. Download PrintInst4intune.ps1, PrintInst4intune-user.ps1 and PrinterDetails.txt and save them into the same folder.
 4. Run an Administrative Terminal or PowerShell session.
 5. Navigate to the folder.
 6. Run .\PrintInst4intune.ps1. You can launch Print Management to see the drivers and ports have been added.
 7. Run .\PrintInst4intune-user.ps1. You will now see the printers have been installed and the AKL printer will be set as default.

I also have a write up about this at my Blog site - https://www.howdoiuseacomputer.com/index.php/2023/12/17/automating-printer-configuration-for-the-modern-workplace/

Cheers, Simon :) 

PrintInst4intune
