# --- Calcul du prochain dimanche à 03h30 ---
$log = "C:\Windows\Temp\Install_SolarWinds_Log.txt"
"[$(Get-Date)] Script exécuté." | Out-File $log -Append
$now = Get-Date
$targetTime = Get-Date -Hour 3 -Minute 30 -Second 0

# Calcul du décalage jusqu'à dimanche
$daysUntilSunday = ([int][DayOfWeek]::Sunday - [int]$now.DayOfWeek)
if ($daysUntilSunday -lt 0) { $daysUntilSunday += 7 }

# Date exacte du prochain dimanche à 03h30
$RunTime = $targetTime.AddDays($daysUntilSunday)

# Format ST et SD pour schtasks.exe
$RunDate = $RunTime.ToString("dd/MM/yyyy")
$RunHour = $RunTime.ToString("HH:mm")

$TaskName = "Installation-Dimanche-0330"

# --- Supprimer la tâche si elle existe ---
schtasks.exe /Delete /TN $TaskName /F >$null 2>&1

# --- Créer la tâche ---
schtasks.exe /Create `
  /TN $TaskName `
  /SC ONCE `
  /RU SYSTEM `
  /RL HIGHEST `
  /TR "shutdown.exe /r /f /t 0" `
  /ST $RunHour `
  /SD $RunDate
