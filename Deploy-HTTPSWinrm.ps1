$servers = @(
"SVOPALPROBDVIN1.afbiodiversite.fr",
"SVOPALPROWBVIN1.afbiodiversite.fr",
"SVOPALRECBDVIN1.afbiodiversite.fr",
"SVOPALRECVIN1.afbiodiversite.fr",
"SVSQLVIN1.afbiodiversite.fr",
"SVTESTGEOVIN1.afbiodiversite.fr",
"SVVIRTVIN1.afbiodiversite.fr",
"SVVIRTVIN2.afbiodiversite.fr",
"SVW094ADRODCP1.afbiodiversite.fr",
"SVW094WSUSPDT.afbiodiversite.fr"
)

$Username = "afbiodiversite\adminopenja"
$SecurePassword = Read-Host "Entrez le mot de passe" -AsSecureString
$Cred = New-Object PSCredential ($Username, $SecurePassword)

foreach ($RemotePC in $servers) {

    Write-Host "Connexion à $RemotePC ..." -ForegroundColor Cyan

    try {
        $session = New-PSSession -ComputerName $RemotePC -Credential $Cred -ErrorAction Stop
        
        Invoke-Command -Session $session -ScriptBlock {
            # Récupère le certificat correspondant au serveur
            $Cert = Get-ChildItem Cert:\LocalMachine\My |
                    Where-Object { $_.Subject -like "*$env:COMPUTERNAME*" } |
                    Select-Object -First 1

            if (!$Cert) {
                Write-Error "Aucun certificat correspondant trouvé."
                return
            }

            # Création du listener HTTPS
            New-Item -Path WSMan:\LocalHost\Listener `
                     -Transport HTTPS `
                     -Address * `
                     -CertificateThumbprint $Cert.Thumbprint `
                     -Force
        }

        Remove-PSSession $session
    }
    catch {
        Write-Host "Erreur sur $RemotePC : $($_.Exception.Message)" -ForegroundColor Red
    }
}
