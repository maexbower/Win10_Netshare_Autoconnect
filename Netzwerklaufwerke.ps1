Add-Type –AssemblyName System.Windows.Forms
Import-Module .\Get-IniContent.psm1
$global:INI_File_Name = "netzwerklaufwerke.INI"
$global:INI_File_Path = "${env:USERPROFILE}"
$global:INI_Current_File = ""
function CheckINIFileExisting ($path) {
    if (${env:DEBUG} -ne ""){
        Write-Debug "DEBUG Aktiv nutze INI in Ausführungsverzeichnis, falls vorhanden."
        if (Test-Path -Path ".\${global:INI_File_Name}") {
            Write-Debug "DEBUG Aktiv nutze INI .\${global:INI_File_Name}"
            $global:INI_Current_File = ".\${global:INI_File_Name}"
            return $true
        }
    }
    if (-not (Test-Path -Path $path)) {
        $retry = [System.Windows.Forms.MessageBox]::Show("Einstellungsdatei für das automatische verbinden der Laufwerke nicht gefunden. Stellen Sie sicher, dass die Datei ${global:INI_File_Path}\${global:INI_File_Name} exitiert.","Einstellungsdatei Fehlt",[System.Windows.Forms.MessageBoxButtons]::RetryCancel,[System.Windows.Forms.MessageBoxIcon]::Exclamation)  
        if($retry -eq "retry"){
            CheckINIFileExisting $path
        }else{
            return $false
        }
    }else{
        Write-Debug "DEBUG Aktiv nutze INI ${path}"
        $global:INI_Current_File = "${path}"
        return $true
    }
}
function checkeLaufwerk ([System.Collections.DictionaryEntry]$ShareEntry) {
    $shareName = $ShareEntry.Key
    foreach ( $entry in $ShareEntry.Value ) {
        switch ($entry.key) {
            "LokalesLaufwerk" { [String]$lokalesLaufwerk = $entry.value }
            "RemotePasswort" { $remotePassword = $entry.value }
            "RemoteUser" { $remoteUser = $entry.value }
            "RemotePfad" { $remotePfad = $entry.value }
            Default { Write-Debug "Unbekannte Eigenschaft in Konfiguration"}
        }
    }
    $secpasswd = ConvertTo-SecureString $remotePassword -AsPlainText -Force
    $mycreds = New-Object System.Management.Automation.PSCredential ( $remoteUser, $secpasswd )
    mountLaufwerk ($lokalesLaufwerk,$remotePfad,$mycreds,$shareName)
}
function mountLaufwerk ($lokalesLaufwerk, $remotePfad, [SecureString] $pscredentials, $shareName) {
    Write-Debug "Binde Laufwerk ein:"
    Out-String $lokalesLaufwerk | Write-Debug
    Out-String $remotePfad | Write-Debug
    Out-String $pscredentials | Write-Debug
    Out-String $shareName | Write-Debug
    New-PSDrive -Name $lokalesLaufwerk -Root $remotePfad -Persist -PSProvider "FileSystem" -Credential $pscredentials -Description $shareName
}

if (CheckINIFileExisting "${global:INI_File_Path}\${global:INI_File_Name}") {
    Write-Debug -Message "Einstellungsdatei ${global:INI_Current_File} konnte gelesen werden"
   
    $INI_Content = Get-IniContent ${global:INI_Current_File}
    Write-Debug -Message "Alle eingelesenen Einstellungen:" 
    Out-String -InputObject $INI_Content | Write-Debug
    ForEach ( $Share in $INI_Content.getEnumerator() ) {
        Write-Debug "Verarbeite"
        Out-String -InputObject $Share | Write-Debug
        checkeLaufwerk $Share
    }
    
}else{ 
    Write-Error -Category ObjectNotFound -message "Einstellungsdatei ${global:INI_File_Path}\${global:INI_File_Name} konnte nicht gefunden werden."
}
