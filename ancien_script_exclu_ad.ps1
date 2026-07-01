# Vérifie si le module ActiveDirectory est déjà importé
if (-not (Get-Module -Name ActiveDirectory)) {
	# Tente de l'importer
	Import-Module ActiveDirectory -ErrorAction Stop
}

#s'initialise sur le bon répertoire
set-location "C:\SCRIPTS_AD\Listes_Diffusion\maj_grp_ad" #à adapter au déploiement

clear-host #nettoie pour visibilité

#Partie logs (création, fréquence, nombres...)
# Dossier des logs
$logFolder = "logs"

#Méthode pour récupérer le numéro de semaine
Add-Type -AssemblyName System.Globalization
$calendar = [System.Globalization.CultureInfo]::CurrentCulture.Calendar
$weekRule = [System.Globalization.CultureInfo]::CurrentCulture.DateTimeFormat.CalendarWeekRule
$firstDay = [System.Globalization.CultureInfo]::CurrentCulture.DateTimeFormat.FirstDayOfWeek
$weekNumber = $calendar.GetWeekOfYear((Get-Date), $weekRule, $firstDay)

#crée un fichier de log hebdomadaire
$year = (Get-Date).Year
$logPath = "$logFolder\log_maj_grp_${year}_Semaine${weekNumber}.txt"
$date = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
Add-Content -Path $logPath -Value "`n--- Exécution du script : $date ---"

# Supprime les anciens fichiers de log (garde les 4 plus récents)
$logFiles = Get-ChildItem -Path $logFolder -Filter "log_maj_grp_*.txt" | Sort-Object LastWriteTime -Descending
$filesToDelete = $logFiles | Select-Object -Skip 4
foreach ($file in $filesToDelete) {
    Remove-Item $file.FullName -Force
}

# Charger les lignes du fichier text de paramètre
$lines = Get-Content "grp_lieux-entreprises.txt"

#traitement et maj
foreach ($line in $lines) {
    # Séparer les éléments de la ligne
    $parts = $line.Split(",")
    $groupName = $parts[0]
    $filterValue = $parts[1]
    $filterType = $parts[2]

    Write-Host "Traitement du groupe : $groupName"
	Add-Content -Path $logPath -Value "Traitement du groupe : $groupName"
    # Vider le groupe
	try {
		Get-ADGroupMember -Identity $groupName -ErrorAction Stop | ForEach-Object { #arrête l'exécution du script en cas d'erreurs et la capture
	        Remove-ADGroupMember -Identity $groupName -Members $_ -Confirm:$false
	    	}
	   	Add-Content -Path $logPath -Value "  Groupe vidé avec succès."
	    } catch {
	        Add-Content -Path $logPath -Value "  Erreur lors du vidage du groupe : $_"
			continue
	    }


    # Déterminer le type du filtre
    try {
		if ($filterType -eq "LIEU") {
			$users = Get-ADUser -Filter {Office -eq $filterValue -and EmailAddress -like "*" -and Enabled -eq $true} -Properties Office, EmailAddress
		} elseif ($filterType -eq "ENTREPRISE") {
			$users = Get-ADUser -Filter {Company -eq $filterValue -and EmailAddress -like "*" -and Enabled -eq $true} -Properties Company, EmailAddress
		} else {
			Write-Warning "Type inconnu pour la ligne : $line"
			Add-Content -Path $logPath -Value "  Type inconnu : $filterType pour la ligne $line"
			continue
		}

		# Ajouter les utilisateurs au groupe
		foreach ($user in $users) {
			Add-ADGroupMember -Identity $groupName -Members $user.SamAccountName
		}

		Write-Host "Groupe $groupName mis a jour avec $($users.Count) utilisateurs."
		Add-Content -Path $logPath -Value "  $($users.Count) utilisateurs ajoutés au groupe."
	} catch {
		Add-Content -Path $logPath -Value "  Erreur lors de l'ajout des utilisateurs : $_"
    }

}

# traitement des exceptions
# Exceptions utilisateurs à ajouter à plusieurs groupes après maj
$parametres = Get-Content "exceptions-ajouter.txt"

foreach ($ligne in $parametres) {
    $infos = $ligne.Split(",")
    $mailUtilisateur = $infos[0]
    $nomGroupe = $infos[1]

	try {
		$utilisateur = Get-ADUser -Filter {EmailAddress -eq $mailUtilisateur} -Properties EmailAddress -ErrorAction Stop
		Add-ADGroupMember -Identity $nomGroupe -Members $utilisateur -ErrorAction Stop
		Write-Host "Ajout de $($utilisateur.EmailAddress) au groupe $nomGroupe."
		Add-Content -Path $logPath -Value "Ajout de $($utilisateur.EmailAddress) au groupe $nomGroupe."
	} catch {
		Write-Warning "Erreur lors de l'ajout de $mailUtilisateur au groupe $nomGroupe : $_"
		Add-Content -Path $logPath -Value "Erreur lors de l'ajout de $mailUtilisateur au groupe $nomGroupe : $_"
	}
}

# Utilisateurs exceptions à supprimer de groupes après maj
$fichier = Get-Content "exceptions-supp.txt"

foreach ($lignes in $fichier) {
    $params = $lignes.Split(",")
    $mail = $params[0]
    $groupe = $params[1]

	try {
		$suppression = Get-ADUser -Filter {EmailAddress -eq $mail} -Properties EmailAddress -ErrorAction Stop
		Remove-ADGroupMember -Identity $groupe -Members $suppression -Confirm:$false -ErrorAction Stop
		Write-Host "Suppression de $($suppression.EmailAddress) au groupe $groupe."
		Add-Content -Path $logPath -Value "Suppression de $($suppression.EmailAddress) au groupe $groupe."
	} catch {
		Write-Warning "Erreur lors de la suppression de $mail au groupe $groupe : $_"
		Add-Content -Path $logPath -Value "Erreur lors de la suppression de $mail au groupe $groupe : $_"
	}
}