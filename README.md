# 📂 Automatisation et Sécurisation - Intégration MailInBlack

Cette branche regroupe les scripts conçus pour alimenter automatiquement les groupes de sécurité Microsoft 365 synchronisés avec la solution de protection de messagerie **MailInBlack (MIB)**[cite: 7, 8].

## 📄 Fichiers inclus
* `script_grp_smb.ps1` : Script de gestion et de purge pour le groupe des boîtes aux lettres partagées (`SharedMailbox`)[cite: 7].
* `script_grp_umb.ps1` : Script de gestion pour les boîtes aux lettres utilisateurs humaines (`UserMailbox`) purement cloud[cite: 8].
* `log_modele_smb.txt` & `log_modele_umb.txt` : Modèles de logs générés après exécution, validant les volumes de membres purgés et réaffectés[cite: 9, 10].

## ⚙️ Logique Métier & Filtrage Avancé
Pour répondre aux exigences de conformité et de licences de MailInBlack, deux politiques de filtrages distinctes ont été appliquées :
1. **SharedMailbox :** Le script isole toutes les boîtes partagées de l'organisation pour leur appliquer un profil de filtrage MIB spécifique (souvent exempté de licences individuelles)[cite: 7].
2. **UserMailbox :** Ce script cible uniquement les véritables utilisateurs humains internes (`userType eq 'Member'`)[cite: 8] et applique une double exclusion : il écarte les boîtes de ressources (salles, équipements) et cible spécifiquement les comptes créés dans le cloud (`OnPremisesSyncEnabled -ne $true`)[cite: 8] pour éviter tout conflit avec la synchronisation locale.

## 🛠️ Sécurité de l'Automatisation
Ces scripts exploitent de concert le module `ExchangeOnlineManagement` et le module moderne `Microsoft.Graph`[cite: 7, 8]. L'authentification est totalement durcie pour la production : deux applications Entra ID distinctes sont configurées avec le principe du moindre privilège, et l'accès se fait de manière sécurisée par **certificat** pour contourner le MFA de manière conforme[cite: 7, 8].