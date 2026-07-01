# 📂 Synchronisation des Listes de Diffusion (Lieux & Entreprises)

Cette branche contient les scripts développés pour automatiser la mise à jour des listes de diffusion de Nutrisens selon des critères RH géographiques (`Office`) et structurels (`Company`)[cite: 1, 5].

## 📄 Fichiers inclus
* `ancien_script_exclu_ad.ps1` : La première version historique du projet qui ciblait uniquement l'Active Directory local (On-Premises)[cite: 1].
* `script_final.ps1` : La solution finale déployée en production qui bascule sur Exchange Online pour une intégration cloud native directe[cite: 5].
* `ld_lieux-entreprises.txt` : Fichier de paramètres (CSV sans entête) faisant la correspondance entre le nom de la liste, la valeur du filtre et le type (LIEU/ENTREPRISE)[cite: 4, 5].
* `exceptions-ajouter.txt` & `exceptions-supp.txt` : Fichiers de configuration permettant à l'équipe IT de forcer l'ajout ou l'exclusion de certains utilisateurs (cas particuliers RH)[cite: 1, 2, 3].
* `log_modele.txt` : Exemple du rendu visuel des logs hebdomadaires générés en production[cite: 6].

## ⚙️ Détails Techniques & Évolution
La V1 (`ancien_script...`) présentait des limites de performance (boucle de suppression membre par membre dans l'AD) et imposait un délai de réplication via Azure AD Connect[cite: 1]. 

La version finale (`script_final.ps1`) modernise le processus en se connectant directement à Exchange Online[cite: 5]. Pour permettre une automatisation totale via le Planificateur de tâches Windows (mode *unattended*) malgré le MFA obligatoire, le script utilise une **Application Entra ID dédiée** avec une authentification par **certificat** (protocole OAuth 2.0 via l'empreinte thumbprint)[cite: 5].

## 🚀 Comment l'utiliser (Déploiement)
1. Télécharger les scripts et les placer dans le répertoire cible (ex: `C:\Scripts\Listes_Diffusion\`).
2. Mettre à jour le chemin dans la commande `Set-Location` au début du script[cite: 1, 5].
3. Renseigner l'AppId et le CertificateThumbprint générés sur votre portail Microsoft Entra ID[cite: 5].
4. Planifier l'exécution du script final via le Planificateur de tâches Windows (ex: toutes les nuits).