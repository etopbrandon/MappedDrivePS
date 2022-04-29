# MappedDrivePS
Powershell script to create a drive mapping GPO from available shares on file server from a Hyper-V Host. This script can be run standalone, or integrated into an existing VM deployment script (recommended) 

# How to use

 1. Create a template GPO
 - Create a new GPO, the name doesn't matter
 - Edit the GPO to add User Configuration -> Preferences -> Windows Settings -> Drive Maps
 - Create a new drive map. Set the action to update. Fill any text into Location such as the placeholder "\\map". Put similar placeholders in Label As and Drive Letter. Configure any additional properties to apply to all mappings under Connect As, Hide/show options, and Common tab
 - Right click the policy object in GPMC, select "Back Up". Save the backup then place anywhere on the domain controller to update (ie: C:\GPOs)
2. Run the script
- Run this script **on the Hyper-V host**
- Follow instructions provided by the script. When prompted to enter the backup location, include the folder with the backup GUID (ie: C:\GPOs\\{25da2714-bec6-4644-9f76-100010ace49b} )
- When finished, the GPO will automatically be linked to the root of the domain. You may move this link as needed, or edit the New-GPLink target on like 79 if integrating with other scripts
