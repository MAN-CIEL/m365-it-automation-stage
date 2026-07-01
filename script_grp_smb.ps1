set-location "C:\SCRIPTS_AD\MIB-groupe_securite" # S'initialise sur le bon répertoire

# Partie logs (création, fréquence, nombres...)
$logFolder = "logs" # Dossier des logs

# Méthode pour récupérer le numéro de semaine
Add-Type -AssemblyName System.Globalization
$calendar = [System.Globalization.CultureInfo]::CurrentCulture.Calendar
$weekRule = [System.Globalization.CultureInfo]::CurrentCulture.DateTimeFormat.CalendarWeekRule
$firstDay = [System.Globalization.CultureInfo]::CurrentCulture.DateTimeFormat.FirstDayOfWeek
$weekNumber = $calendar.GetWeekOfYear((Get-Date), $weekRule, $firstDay)

# Crée un fichier de log hebdomadaire
$year = (Get-Date).Year
$logPath = "$logFolder\maj_grp_mib_smb_${year}_Semaine${weekNumber}.txt"
$date = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
Add-Content -Path $logPath -Value "`n--- Exécution du script : $date ---"

# Supprime les anciens fichiers de log (garde les 4 plus récents)
$logFiles = Get-ChildItem -Path $logFolder -Filter "maj_grp_mib_smb_*.txt" | Sort-Object LastWriteTime -Descending
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
 
$groupId = "id-groupe-sharedmailbox"
 
# Récupère les membres actuels du groupe
$users = Get-MgGroupMember -GroupId $groupId -all
 
# Purge du groupe
if ($users) {
    Write-Host "Début purge groupe NOM_GROUPE_SHAREDMAILBOX"
    foreach ($user in $users) {
        Remove-MgGroupMemberByRef -GroupId $groupId -DirectoryObjectId $user.Id
    }
    Write-Host "Fin purge groupe NOM_GROUPE_SHAREDMAILBOX"
    Add-Content -Path $logPath -Value "$($users.Count) membres supprimés du groupe NOM_GROUPE_SHAREDMAILBOX"
} else {
    Write-Host "Aucun membre à supprimer dans le groupe."
    Add-Content -Path $logPath -Value "Aucun membre supprimé du groupe NOM_GROUPE_SHAREDMAILBOX"
}
 
# Récupère toutes les boîtes aux lettres partagées
$sharedMailboxes = Get-Mailbox -RecipientTypeDetails SharedMailbox -ResultSize Unlimited | Select-Object UserPrincipalName
 
# Récupère uniquement les utilisateurs Azure AD internes (UserType = Member)
$aadUsers = Get-MgUser -Filter "userType eq 'Member'" -All | Select-Object Id, UserPrincipalName
 
$addedCount = 0 # Initialisation d'une variable qui donne le nombre d'utilisateurs ajoutés au groupe
 
Write-Host "Début de la mise à jour du groupe NOM_GROUPE_SHAREDMAILBOX"
 
# Ajout de chaque utilisateur concerné dans le groupe
foreach ($smb in $sharedMailboxes) {
    $aadUser = $aadUsers | Where-Object { $_.UserPrincipalName -eq $smb.UserPrincipalName }
    if ($aadUser) {
        # Ajout via référence
        New-MgGroupMemberByRef -GroupId $groupId -BodyParameter @{
            "@odata.id" = "https://graph.microsoft.com/v1.0/directoryObjects/$($aadUser.Id)"
        }
        $addedCount++
    }
}
 
Add-Content -Path $logPath -Value "$addedCount utilisateurs ajoutés au groupe NOM_GROUPE_SHAREDMAILBOX après mise à jour"