$FPVMName = Read-Host "Please enter the name of the file server you wish to pull share information from"
$DCVMName = Read-Host "Please enter the name of the domain controller you wish to add the policy to"
$PolicyName = Read-Host "Please enter the name you wish to give this mapped drive policy"
$GPOLocation = Read-Host "Enter the location of the backed up template GPO on $DCVMName (for example, C:\GPOs\{backupID})"
$GPORoot = $GPOLocation.substring(0, $GPOLocation.LastIndexOf('\'))
$BackupID = $GPOLocation.Replace($GPORoot+"\", "")
Write-Host "Please enter in credentials that have rights to add and import Group Policy objects, for example a Domain Administrator"
$DomainCredential = Get-Credential -Message "Enter Credentials for VM access"


Write-Host "STOP!" -ForegroundColor White -BackgroundColor Red
Write-Host "DO NOT CLOSE THIS WINDOW" -ForegroundColor White -BackgroundColor Red
Write-Host "Please connect to $FPVMName and create the necessary shares"
Read-Host "When finished, press enter in this window"


$Shares =  Invoke-Command -VMName $FPVMName -Credential $DomainCredential -ScriptBlock{Get-SmbShare | Where-Object {$_.Special -ne "True"}}
$SharesNewNodeCount = $Shares.Count - 1

Write-Host "I've located $($Shares.count) shares:"
$Shares.Name
$ConfirmShares = Read-Host "Is this correct? (y/n)"

if ($ConfirmShares -eq "y"){
    #Let the fun begin...
    $ShareLetter = @{}
    foreach ($Share in $Shares.name){
        $ShareLetter.$Share = Read-Host "Enter letter to use for $Share"
    }
    $MapDriveXMLLocation = "$($GPOLocation)\DomainSysvol\GPO\User\Preferences\Drives\Drives.xml"
    Invoke-Command -VMName $DCVMName -Credential $DomainCredential -ScriptBlock {
        Write-Host "Importing XML Config for mapped drives"
        [xml]$MapDriveXML = Get-Content $using:MapDriveXMLLocation
        if ($using:Shares.count -ge 2){
            Write-Host "Updating mapping count to match the $($using:Shares.count) shares"
            for ($i=1; $i -le $using:SharesNewNodeCount; $i++){
                $NodeToClone = @($MapDriveXML.Drives.Drive)[-1].Clone()  
                $MapDriveXML.Drives.AppendChild($NodeToClone)
                $MapDriveXML.Save($using:MapDriveXMLLocation)
            }
            Write-Host "Created new nodes"
        }
        for ($i=0; $i -le $using:SharesNewNodeCount; $i++){
            #import vars for expressions
            $LoopLetter = $using:ShareLetter
            $LoopShares = $using:Shares
            Write-Host "Updating Share" ($i+1) "of" ($using:SharesNewNodeCount+1)
            #UID
            $NewUID = '{'+[guid]::NewGuid().ToString()+'}'
            Write-Host "Changing UID" $MapDriveXML.Drives.Drive[$i].uid "to new unique value" $NewUID
            Start-Sleep -Seconds 3
            $MapDriveXML.Drives.Drive[$i].uid = $NewUID
            #Letter
            Write-Host "Letter"
            Write-Host "Changing letter" $MapDriveXML.Drives.Drive[$i].Properties.letter "to" $LoopLetter.$($LoopShares.Name[$i])
            Start-Sleep -Seconds 3
            $MapDriveXML.Drives.Drive[$i].Properties.letter = $LoopLetter.$($LoopShares.Name[$i])
            #Name
            Write-Host "Name"
            Write-Host "Changing name" $MapDriveXML.Drives.Drive[$i].name "to $($LoopLetter.$($LoopShares.Name[$i])):"
            Start-Sleep -Seconds 3
            $MapDriveXML.Drives.Drive[$i].name = $LoopLetter.$($LoopShares.Name[$i]) + ":"
            #Path
            Write-Host "Path"
            Write-Host "Changing path" $MapDriveXML.Drives.Drive[$i].Properties.path "to" "\\$($using:FPVMName)\$($LoopShares.Name[$i])"
            Start-Sleep -Seconds 3
            $MapDriveXML.Drives.Drive[$i].Properties.path = "\\$($using:FPVMName)\$($LoopShares.Name[$i])"
            #Label
            Write-Host "Label"
            Write-Host "Changing label" $MapDriveXML.Drives.Drive[$i].Properties.label "to" $LoopShares.Name[$i]
            Start-Sleep -Seconds 3
            $MapDriveXML.Drives.Drive[$i].Properties.label = $LoopShares.Name[$i]
            $MapDriveXML.Save($using:MapDriveXMLLocation)
        }
        $GPOLocation = Get-ADDomain | Select-Object DistinguishedName | ForEach-Object {$_.DistinguishedName}
        Write-Host "Creating new GPO"
        New-GPO -Name $using:PolicyName | New-GPLink -Target $GPOLocation
        Write-Host "Importing modified backup"
        Import-GPO -BackupID $using:BackupID -TargetName $using:PolicyName -Path $using:GPORoot
        Write-Host "All done!"
    }
}

$ShareLetter
$BackupID
$GPORoot




