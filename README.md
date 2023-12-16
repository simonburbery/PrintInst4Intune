PrintInst4Intune

 Used for modern workplace printing setups (when they have basic requirements not warranting spend on a cloud printing solution).
  
 A two-part script: 
 **Device-targeted script** - PrintInst4Intune.ps1:
 - installs any driver signing certificates (cer) found within a source folder.
 - installs and print drivers (inf)
 **Prep - list the actual driver names required for the input file (advanced tab on a Windows printer queue); extract all print drivers into a source folder along with the script.
 Deploy in System context to devices.
 **
 NOTE: _Expired_ certs may still prompt, preventing a silent install.  In this case you need to reach out to the vendor to provide an up-to-date driver package.

 **User-targeted script:**  PrintInst4Intune-user.ps1:
 - Adds any printer connections based on group memebership.
 - Sets the specified printer property defaults.
 - (optional) sets a default printer based on group membership or input file.

 Deploy using System context to groups of users.

PrintInst4intune
