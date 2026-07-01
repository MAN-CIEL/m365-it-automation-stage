# 📂 Gouvernance Exchange, Audit et Reporting Métier

Cette branche met à disposition les outils développés pour assurer le suivi, le cycle de vie et la qualité des données des listes de diffusion de l'entreprise[cite: 12, 13].

## 📄 Fichiers inclus
* `script-envoi-mail.ps1` : Script d'extraction ponctuelle de la composition des listes de diffusion au format HTML à destination des responsables opérationnels[cite: 12].
* `script-mail-proprios.ps1` : Solution automatisée de gouvernance et d'audit des listes de diffusion cloud[cite: 13].
* `listes_exchange.txt` : Fichier contenant les noms des listes de diffusion cibles à auditer[cite: 11, 12].

## ⚙️ Logique de Gouvernance (Anti-Group-Sprawl)
Le script phare de cette section (`script-mail-proprios.ps1`) permet de lutter contre l'obsolescence des groupes dans l'annuaire[cite: 13] :
* Il cible uniquement les listes créées dans le cloud (`IsDirSynced -eq $false`)[cite: 13].
* Il intègre un mécanisme de filtrage pour **ignorer les comptes d'administration IT** (`admin@...`) afin de ne pas saturer l'équipe de support[cite: 13].
* Il envoie de manière autonome un e-mail HTML personnalisé à chaque **propriétaire métier** (*Data Owner*) listant ses membres actuels et lui demandant de valider l'utilité de sa liste[cite: 13]. Si la liste n'est plus utile, elle est planifiée pour suppression, garantissant un annuaire propre[cite: 13].

## 🚀 Évolution Technique
Alors que le premier script utilisait une authentification interactive (`-UserPrincipalName`) pour des lancements manuels à la demande[cite: 12], le script de gouvernance des propriétaires a été entièrement réécrit pour la production en utilisant une connexion non interactive par **certificat d'application Entra ID**[cite: 13], le rendant 100% autonome via le Planificateur de tâches.