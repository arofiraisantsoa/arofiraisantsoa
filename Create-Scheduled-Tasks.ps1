$servers = @("SVOPALPROBDVIN1.afbiodiversite.fr",
"SVOPALPROWBVIN1.afbiodiversite.fr",
"SVOPALRECBDVIN1.afbiodiversite.fr",
"SVOPALRECVIN1.afbiodiversite.fr",
"SVSQLVIN1.afbiodiversite.fr",
"SVTESTGEOVIN1.afbiodiversite.fr",
"SVVIRTVIN1.afbiodiversite.fr",
"SVVIRTVIN2.afbiodiversite.fr",
"SVW094ADRODCP1.afbiodiversite.fr",
"SVW094WSUSPDT.afbiodiversite.fr",
"SVWEBBRE1"
)
$Username = "afbiodiversite\adminopenja"

# Demander le mot de passe une seule fois
$SecurePassword = Read-Host "Entrez le mot de passe" -AsSecureString
$Cred = New-Object System.Management.Automation.PSCredential ($Username, $SecurePassword)
foreach ($RemotePC in $servers) {
    Write-Host "`n=== Traitement de $RemotePC ===" -ForegroundColor White
    try {
        $session = New-PSSession -ComputerName $RemotePC -Credential $Cred -ErrorAction Stop
        Invoke-Command -ComputerName $RemotePC -FilePath "C:\Scripts\Create-tasks-SolarWinds.ps1" -Credential $Cred
		Remove-PSSession $session
	}
	catch [System.Management.Automation.Remoting.PSRemotingTransportException] {
		Write-Host "PSRemoting not enabled"
	}
	catch [System.Management.Automation.CommandNotFoundException] {
		Write-Host "Command not found"
	}
	catch {
        Write-Host "Erreur sur $RemotePC : $($_.Exception.Message)"
    }
}

