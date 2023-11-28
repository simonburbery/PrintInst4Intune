
PrintInst4Intune
 
 Caters for drivers that prompt durign install - this is usually because the certificate used to sign the driver is either not trusted or has expired. 
 The script will import certs into the root store to allow silent installation. 

 NOTE: Expired certs will still prompt and require a later driver package to be downloaded.
 
 Installs any driver signing certificates (cer) and print drivers (inf) found within a source folder
 Extract all print drivers into the same folder as the script - run in system context 

 The commented part of the script will add the printers to the user session, set printer preferences (greyscale, single sided) and set a default printer
 The part of the script starting with <### and ending with ###> can be separated out and deployed separately to add the printers and set default.    

 Deploy in System context to groups of users.

 TO DO: A 'Default printer' selector the user can click on the desktop to easily change their default.  
 
