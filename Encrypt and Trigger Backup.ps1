# Written and tested using Powershell 7
# Before running, setup PowerShell client with
# Install-Module -Name Cohesity.PowerShell
#

#Import Modules
Import-Module -Name Cohesity.PowerShell

#==== global variables ===================================================================================

#Set path to FileCryptography.psm1 Module Example= "C:\FileCryptography.psm1"
import-module "<Path to directory>\FileCryptography.psm1"

#set path to target directory Example= "C:\Data_to_Encrypt"
$FileTargetPath = "<Path to encrypt>"
#target file types - example '*.txt,*.xml,*.jpg' 
$TargetFiles = '*'
#Cohesity Cluster IP
$CohesityCluster = "<IP Address>"
#Cohesity Protection Job Name
$CohesityProtectionJob = "<Cohesity Protection Job Name>"
#set encrypted file extension
$EncExtension = ".encrypted"
#set AES encryption key - A new key can be generated with "New-CryptographyKey -Algorithm AES -AsPlaintext" command once FileCryptography module is loaded.

#END ==== global variables ===============================================================================

#import crypto functions

import-module $FileSourcePath\FileCryptography.psm1
$key = New-CryptographyKey -AsPlainText



#do not edit below here

Connect-CohesityCluster -Credential (Get-Credential) -Server $CohesityCluster

#find files to encrypt
$FileList = get-childitem -path $FileTargetPath\* -Include $TargetFiles -Recurse -force | where { ! $_.PSIsContainer }
#Select discovered files to encrypt
$FileCount = (get-childitem -path $FileTargetPath\* -Include $TargetFiles -Recurse -force | Measure-Object).Count



#encrypt each file

    foreach ($file in $FileList)
    {
        Write-Host "Encrypting $file"
        Protect-File $file -Algorithm AES -KeyAsPlainText $key -Suffix $EncExtension -RemoveSource
    }
    Write-Host "Encrypted $FileCount files." | Start-Sleep -Seconds 10



if (Start-CohesityProtectionJob -Name $CohesityProtectionJob -RunType KRegular) 
{
  
    Write-Output "Starting Cohesity Backup Job"
    Start-Sleep -Seconds 5
    while ( Get-CohesityProtectionJobRun -jobname $CohesityProtectionJob -NumRuns 1 | where-object {$PSItem.backuprun.status -eq "kRunning"} ) {
    Write-Output "Waiting for Cohesity Backup Job Complete"
            Start-Sleep -Seconds 5    
        }
        
    Disconnect-CohesityCluster 
}

else {

    Write-Output "Unable to connect to the cluster.  Please check IP and credentials."
}
