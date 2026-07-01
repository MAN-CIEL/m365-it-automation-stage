if (-not (Get-Module -Name ExchangeOnlineManagement)) {
	Import-Module ExchangeOnlineManagement
	Connect-ExchangeOnline -AppId "id-app-entra-exchangeonline-789" -CertificateThumbprint "CERTICAT_APP_ENTRA_EXCHANGEONLINE_789" -Organization "domaine.organisation.com"
	#Set-ExecutionPolicy Unrestricted #à enlever lorsque lors de la planification auto
}

Remove-Item -Path "C:\SCRIPTS_AD\Listes_Diffusion\maj_ld_exchange\export-ld\ld_admin.csv" -ErrorAction SilentlyContinue
Remove-Item -Path "C:\SCRIPTS_AD\Listes_Diffusion\maj_ld_exchange\export-ld\ld_autres.csv" -ErrorAction SilentlyContinue

# Initialiser les listes pour les deux exports
$adminld = @()
$autresld = @()

# Récupérer toutes les listes de distribution
Get-DistributionGroup | Where-Object { -not $_.IsDirSynced } | ForEach-Object {
	$nomGroupe = $_.Name
	$proprietaires = $_.ManagedBy
	$membres = Get-DistributionGroupMember -Identity $_.Identity -ErrorAction SilentlyContinue
	$listeMembres = if ($membres) { ($membres | ForEach-Object { $_.PrimarySmtpAddress }) -join "`n" } else { "Aucun membre" }

	if ($proprietaires) {
		# Filtrer les propriétaires non-admin
		$proprietairesNonAdmin = @()
		foreach ($proprietaire in $proprietaires) {
			try {
				$recipient = Get-Recipient -Identity $proprietaire -ErrorAction Stop
				$adresseMail = $recipient.PrimarySmtpAddress.ToString()
			} catch {
				Write-Warning "Impossible de recuperer l'adresse pour le proprietaire : $proprietaire"
				continue
			}

			if ($adresseMail -like "*@*") {
				$objet = [PSCustomObject]@{
					Groupe = $nomGroupe
					Proprietaire = $adresseMail
				}

				if ($adresseMail -eq "admin@nutrisens.fr" -or $adresseMail -eq "admin@les-repas-sante.com") {
					$adminld += $objet
				} else {
					$autresld += $objet
					$proprietairesNonAdmin += $adresseMail
				}
			}
		}

		# Envoi du mail uniquement aux propriétaires non-admin
		foreach ($adresseMail in $proprietairesNonAdmin) {
			$sujet = "Verification de votre liste de distribution $nomGroupe"
			$corps = @"
<!DOCTYPE html>
<html>
<body>
<p>Bonjour,</p>
<p>Vous etes proprietaire de la liste de distribution <strong>$nomGroupe</strong>.<br>
Voici les membres actuels de cette liste :</p>
<pre>$listeMembres</pre>
<p>Nous devons faire la verification de votre liste aupres de vous</p>
<p>Votre liste vous est-elle encore utile ? Si "Non", elle sera automatiquement supprimee.</p>
<p>Si "Oui", est-elle a jour ? Si "Oui", elle ne sera subira aucune modification.</p>
<p>Si "Non", veuillez me communiquer le(s) utilisateur(s) a ajouter/supprimer (ce qui sera egalement fait automatiquement).</p>
<p>Merci</p>
<p>Cordialement,<br>
L’equipe IT, Nutrisens Chaponost</p>
</body>
</html>
"@
			Write-Host "Envoi de message a $adresseMail"
			Send-MailMessage -To $adresseMail -From "servicead@nutrisens.fr" -Subject $sujet -Body $corps -BodyAsHtml -SmtpServer "smtp.e-liance.net" -Port 25
		}
	}	
}

# Exporter les résultats dans deux fichiers CSV
$adminld | Export-Csv -Path "C:\SCRIPTS_AD\Listes_Diffusion\maj_ld_exchange\export-ld\ld_admin.csv" -NoTypeInformation -Encoding UTF8
$autresld | Export-Csv -Path "C:\SCRIPTS_AD\Listes_Diffusion\maj_ld_exchange\export-ld\ld_autres.csv" -NoTypeInformation -Encoding UTF8