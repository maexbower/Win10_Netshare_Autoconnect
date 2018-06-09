Add-Type –AssemblyName System.Windows.Forms
$INI_File_Path = "${env:USERPROFILE}\netzwerklaufwerke.INI"
function CheckINIFileExisting ($path) {
    if (-not (Test-Path -Path $INI_File_Path)) {
        $retry = [System.Windows.Forms.MessageBox]::Show("Einstellungsdatei für das automatische verbinden der Laufwerke nicht gefunden. Stellen Sie sicher, dass die Datei ${INI_File_Path} exitiert.","Einstellungsdatei Fehlt",[System.Windows.Forms.MessageBoxButtons]::RetryCancel,[System.Windows.Forms.MessageBoxIcon]::Exclamation)  
        if($retry -eq "retry"){
            CheckINIFileExisting $INI_File_Path
        }else{
            return $false
        }
    }else{
        return $true
    }
}
function checkeLaufwerk ($ShareEntry) {
    $lokalesLaufwerk = $ShareEntry("LokalesLaufwerk")
    $remotePfad = $ShareEntry("RemotePfad")
    $shareName = $ShareEntry.Name
    $secpasswd = ConvertTo-SecureString $ShareEntry("RemotePasswort") -AsPlainText -Force
    $mycreds = New-Object System.Management.Automation.PSCredential ($ShareEntry("RemoteUser"), $secpasswd)
    mountLaufwerk($lokalesLaufwerk,$remotePfad,$mycreds,$shareName)
}
function mountLaufwerk ($lokalesLaufwerk, $remotePfad, $pscredentials, $shareName) {
    Write-Debug "Binde Laufwerk ein:"
    Out-String $lokalesLaufwerk | Write-Debug
    Out-String $remotePfad | Write-Debug
    Out-String $pscredentials | Write-Debug
    Out-String $shareName | Write-Debug
    New-PSDrive -Name $lokalesLaufwerk -Root $remotePfad -Persist -PSProvider "FileSystem" -Credential $pscredentials -Description $shareName
}

if (CheckINIFileExisting $INI_File_Path) {
    Write-Debug -Message "Einstellungsdatei ${INI_File_Path} konnte gelesen werden"
   
    $INI_Content = Get-IniContent $INI_File_Path
    Write-Debug -Message "Alle eingelesenen Einstellungen:" 
    Out-String -InputObject $INI_Content | Write-Debug
    ForEach ( $Share in $INI_Content.getEnumerator() ) {
        Write-Debug "Verarbeite"
        Out-String -InputObject $Share | Write-Debug
        checkeLaufwerk $Share
    }
    
}else{ 
    Write-Error -Category ObjectNotFound -message "Einstellungsdatei ${INI_File_Path} konnte nicht gefunden werden."
}

