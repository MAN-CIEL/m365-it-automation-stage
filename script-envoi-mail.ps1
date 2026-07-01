if (-not (Get-Module -Name ExchangeOnlineManagement)) {
	Import-Module ExchangeOnlineManagement
	Connect-ExchangeOnline -UserPrincipalName utilisateur@nutrisens.fr #à changer au déploiement
	Set-ExecutionPolicy Unrestricted -Scope CurrentUser #à enlever lorsque lors de la planification auto
}

#s'initialise sur le bon répertoire
set-location "C:\Users\imanzari\Documents\mail-membres-grp" #à adapter au déploiement

clear-host #nettoie pour visibilité

# Lire les groupes depuis le fichier
$listes = Get-Content -Path "listes_exchange.txt"

# Initialiser le contenu HTML
$htmlBody = "<html><body><pre>Bonjour Chrystelle,

NOM_LISTE est la liste de type lieu pour NOM_ENTREPRISE, et NOM_LISTE est une liste de type lieu egalement pour les utilisateurs nomades.

Ci-dessous leur liste de membres.</pre>"

foreach ($liste in $listes) {
    try {
        $htmlBody += "<h3>Liste : $liste</h3><ul>"

        $membres = Get-DistributionGroupMember -Identity $liste

        if ($membres.Count -eq 0) {
            $htmlBody += "<li><i>Aucun membre trouve</i></li>"
        } else {
            foreach ($membre in $membres) {
                $nom = $membre.DisplayName
                $email = $membre.PrimarySmtpAddress
                $htmlBody += "<li>$nom ($email)</li>"
            }
        }

        $htmlBody += "</ul>"
    } catch {
        $htmlBody += "<p style='color:red;'>Erreur lors du traitement de la liste <b>$liste</b> : $_</p>"
    }
}

$htmlBody += "</body></html>"

Write-Host "Envoi de message a utilisateur@nutrisens.com"
# Envoyer le mail
Send-MailMessage -From "utilisateur@nutrisens.fr" -To "utilisateur@nutrisens.com" -Subject "Liste des membres NOM_ENTREPRISE et nomades" -Body $htmlBody -BodyAsHtml -SmtpServer "smtp.e-liance.net"