# Fichier contenant la liste des serveurs
$ServerList = "C:\Scripts\serveurs.txt"

# Fichier de sortie
$OutputFile = "C:\Scripts\Ping_Report.csv"

# Tableau de résultats
$Results = @()

foreach ($Server in (Get-Content $ServerList)) {
    if ($Server -ne "") {
        Write-Host "Test du serveur : $Server" -ForegroundColor Cyan
        
        $Ping = Test-Connection -ComputerName $Server -Count 1 -Quiet
        
        if ($Ping) {
            $Status = "OK"
            Write-Host "$Server répond au ping." -ForegroundColor Green
        } else {
            $Status = "KO"
            Write-Host "$Server ne répond PAS au ping." -ForegroundColor Red
        }

        # Ajout au tableau
        $Results += [PSCustomObject]@{
            Serveur = $Server
            Statut  = $Status
            Date    = (Get-Date)
        }
    }
}

# Export CSV final
$Results | Export-Csv -Path $OutputFile -NoTypeInformation -Delimiter ";"

Write-Host "----------------------------------------------"
Write-Host "Test terminé. Rapport disponible ici :" -ForegroundColor Yellow
Write-Host $OutputFile -ForegroundColor Yellow
Write-Host "----------------------------------------------"
