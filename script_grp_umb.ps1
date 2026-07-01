Set-Location "C:\SCRIPTS_AD\MIB-groupe_securite"

# Partie logs
$logFolder = "logs"
Add-Type -AssemblyName System.Globalization
$calendar = [System.Globalization.CultureInfo]::CurrentCulture.Calendar
$weekRule = [System.Globalization.CultureInfo]::CurrentCulture.DateTimeFormat.CalendarWeekRule
$firstDay = [System.Globalization.CultureInfo]::CurrentCulture.DateTimeFormat.FirstDayOfWeek
$weekNumber = $calendar.GetWeekOfYear((Get-Date), $weekRule, $firstDay)

$year = (Get-Date).Year
$logPath = "$logFolder\maj_grp_umb_${year}_Semaine${weekNumber}.txt"
$date = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
Add-Content -Path $logPath -Value "`n--- Exécution du script : $date ---"

# Nettoyage des anciens logs
$logFiles = Get-ChildItem -Path $logFolder -Filter "maj_grp_umb_*.txt" | Sort-Object LastWriteTime -Descending
$filesToDelete = $logFiles | Select-Object -Skip 4
foreach ($file in $filesToDelete) {
    Remove-Item $file.FullName -Force
}

if (-not (Get-Module -Name microsoft.graph)) {
	Import-Module Microsoft.Graph.Users -ErrorAction Stop
	Import-Module Microsoft.Graph.Groups -ErrorAction Stop
	connect-mggraph -AppId "id-app-entra-mggraph-123" -CertificateThumbprint "CERTICAT_APP_ENTRA_MGGRAPH_123" -TenantId "id-user-privilegie-123" -nowelcome
}

if (-not (Get-Module -Name ExchangeOnlineManagement)) {
	Import-Module ExchangeOnlineManagement -ErrorAction Stop
	Connect-ExchangeOnline -AppId "id-app-entra-exchangeonline-456" -CertificateThumbprint "CERTICAT_APP_ENTRA_EXCHANGEONLINE_456" -Organization "domaine.organisation.com"
}

$groupId = "id-groupe-usermailbox"

# Purge du groupe
$users = Get-MgGroupMember -GroupId $groupId -All
if ($users) {
    Write-Host "Début purge groupe MIB pour les UserMailBox"
    foreach ($user in $users) {
        Remove-MgGroupMemberByRef -GroupId $groupId -DirectoryObjectId $user.Id
    }
    Write-Host "Fin purge groupe MIB pour les UserMailBox"
    Add-Content -Path $logPath -Value "$($users.Count) membres supprimés du groupe MIB pour les UserMailBox"
} else {
    Write-Host "Aucun membre à supprimer dans le groupe."
    Add-Content -Path $logPath -Value "Aucun membre supprimé du groupe MIB pour les UserMailBox"
}

# Récupération des boîtes aux lettres à exclure
$excludedMailboxes = Get-Mailbox -RecipientTypeDetails SharedMailbox, RoomMailbox -ResultSize Unlimited | Select-Object -ExpandProperty UserPrincipalName

# Récupération des utilisateurs Azure AD internes non synchronisés (non on-premise)
$aadUsers = Get-MgUser -Filter "userType eq 'Member'" -All | Where-Object { $_.OnPremisesSyncEnabled -ne $true } | Select-Object Id, UserPrincipalName

$addedCount = 0
Write-Host "Début de la mise à jour du groupe MIB pour les UserMailBox"

foreach ($user in $aadUsers) {
    if ($excludedMailboxes -notcontains $user.UserPrincipalName) {
        try {
            New-MgGroupMemberByRef -GroupId $groupId -BodyParameter @{
                "@odata.id" = "https://graph.microsoft.com/v1.0/directoryObjects/$($user.Id)"
            }
            $addedCount++
        } catch {
            Write-Warning "Erreur lors de l'ajout de $($user.UserPrincipalName) : $_"
        }
    }
}

Add-Content -Path $logPath -Value "$addedCount utilisateurs ajoutés au groupe MIB pour les UserMailBox après mise à jour"