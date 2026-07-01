# S'initialise sur le bon répertoire
set-location "C:\SCRIPTS_AD\Listes_Diffusion\maj_ld_lieux-entreprises" #à adapter au déploiement

# Vérifie si le module ExchangeOnlineManagement est déjà importé sinon tente de l'importer 
if (-not (Get-Module -Name ExchangeOnlineManagement)) {
	Import-Module ExchangeOnlineManagement -ErrorAction Stop
	# Connexion à ExchangeOnline via une application Microsoft pour éviter l'authentification forcée
	Connect-ExchangeOnline -AppId "id-app-entra-exchangeonline-789" -CertificateThumbprint "CERTICAT_APP_ENTRA_EXCHANGEONLINE_789" -Organization "domaine.organisation.com"
	#Set-ExecutionPolicy Unrestricted #à enlever lorsque lors de la planification auto
}

#Partie logs (création, fréquence, nombres...)
# Dossier des logs
$dossierLogs = "logs"

#Méthode pour récupérer le numéro de semaine
Add-Type -AssemblyName System.Globalization
$calendar = [System.Globalization.CultureInfo]::CurrentCulture.Calendar
$weekRule = [System.Globalization.CultureInfo]::CurrentCulture.DateTimeFormat.CalendarWeekRule
$firstDay = [System.Globalization.CultureInfo]::CurrentCulture.DateTimeFormat.FirstDayOfWeek
$weekNumber = $calendar.GetWeekOfYear((Get-Date), $weekRule, $firstDay)

#crée un fichier de log hebdomadaire
$year = (Get-Date).Year
$logPath = "$dossierLogs\log_maj_grp_${year}_Semaine${weekNumber}.txt"
$date = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
Add-Content -Path $logPath -Value "`n--- Exécution du script : $date ---"

# Supprime les anciens fichiers de log (garde les 4 plus récents)
$fichierLogs = Get-ChildItem -Path $dossierLogs -Filter "log_maj_grp_*.txt" | Sort-Object LastWriteTime -Descending
$fichiersASupprimer = $fichierLogs | Select-Object -Skip 4
foreach ($file in $fichiersASupprimer) {
    Remove-Item $file.FullName -Force
}

# Lire le fichier de paramètres
$paramFile = "ld_lieux-entreprises.txt"
$params = Get-Content $paramFile | ForEach-Object {
    $parts = $_ -split ","
    [PSCustomObject]@{
        DistributionList = $parts[0]
        LocationOrCompany = $parts[1]
        Type = $parts[2]
    }
}

# Traitement de chaque liste
foreach ($param in $params) {
    $dl = $param.DistributionList

    # Suppression des membres existants
    $oldMembers = Get-DistributionGroupMember -Identity $dl -ErrorAction SilentlyContinue
    $removedCount = 0
    if ($oldMembers) {
        foreach ($member in $oldMembers) {
            Remove-DistributionGroupMember -Identity $dl -Member $member.Identity -Confirm:$false
            $removedCount++
        }
    }

    # Ajout des nouveaux membres
    if ($param.Type -eq "LIEU") {
        $users = Get-User -ResultSize Unlimited | Where-Object {
            $_.Office -eq $param.LocationOrCompany -and
            $_.RecipientTypeDetails -eq 'UserMailbox' -and
            $_.UserPrincipalName -like '*@*' -and
            $_.AccountDisabled -eq $false
        }
    } elseif ($param.Type -eq "ENTREPRISE") {
        $users = Get-User -ResultSize Unlimited | Where-Object {
            $_.Company -eq $param.LocationOrCompany -and
            $_.RecipientTypeDetails -eq 'UserMailbox' -and
            $_.UserPrincipalName -like '*@*' -and
            $_.AccountDisabled -eq $false
        }
    }

    $addedCount = 0
    foreach ($user in $users) {
        Add-DistributionGroupMember -Identity $dl -Member $user.UserPrincipalName -ErrorAction SilentlyContinue
        $addedCount++
    }

    Write-Host "Liste : $dl"
    Write-Host "Membres supprimés : $removedCount"
    Write-Host "Membres ajoutés   : $addedCount"
    Add-Content -Path $logPath -Value "Liste : $dl"
    Add-Content -Path $logPath -Value "  Membres supprimés : $removedCount"
    Add-Content -Path $logPath -Value "  Membres ajoutés   : $addedCount`n"
}

# Traitement des utilisateurs exceptionnels
# Utilisateurs à ajouter à plusieurs groupes après mise à jour
$exceptionsFile = "exceptions-ajouter.txt"
$exceptions = Get-Content $exceptionsFile | ForEach-Object {
    $parts2 = $_ -split ","
    [PSCustomObject]@{
        Email = $parts2[0].Trim()
        DistributionList = $parts2[1].Trim()
    }
}

Add-Content -Path $logPath -Value "`n--- Traitement des utilisateurs exceptionnels ---`n"

foreach ($entry in $exceptions) {
    $user = Get-User -Identity $entry.Email -ErrorAction SilentlyContinue
    if ($user) {
        try {
            Add-DistributionGroupMember -Identity $entry.DistributionList -Member $user.UserPrincipalName -ErrorAction Stop
			Write-Host "Ajouté : $($entry.Email) à $($entry.DistributionList)"
            Add-Content -Path $logPath -Value "Ajouté : $($entry.Email) à $($entry.DistributionList)"
        } catch {
            Add-Content -Path $logPath -Value "Erreur lors de l'ajout de $($entry.Email) à $($entry.DistributionList) : $_"
        }
    } else {
        Add-Content -Path $logPath -Value "Utilisateur introuvable : $($entry.Email)"
    }
}

# Utilisateurs à supprimer de groupes après mise à jour
$exceptionsFile2 = "exceptions-supp.txt"
$exceptions2 = Get-Content $exceptionsFile2 | ForEach-Object {
    $parts3 = $_ -split ","
    [PSCustomObject]@{
        Email = $parts3[0].Trim()
        DistributionList = $parts3[1].Trim()
    }
}

foreach ($entry2 in $exceptions2) {
    $user2 = Get-User -Identity $entry2.Email -ErrorAction SilentlyContinue
    if ($user2) {
        try {
            Remove-DistributionGroupMember -Identity $entry2.DistributionList -Member $user2.UserPrincipalName -Confirm:$false -ErrorAction Stop
			Write-Host "Supprimé : $($entry2.Email) de $($entry2.DistributionList)"
            Add-Content -Path $logPath -Value "Supprimé : $($entry2.Email) de $($entry2.DistributionList)"
        } catch {
            Add-Content -Path $logPath -Value "Erreur lors de la suppression de $($entry2.Email) à $($entry2.DistributionList) : $_"
        }
    } else {
        Add-Content -Path $logPath -Value "Utilisateur introuvable : $($entry2.Email)"
    }
}