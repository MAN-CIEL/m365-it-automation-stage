# Automatisation M365 & Gouvernance IT - Stage Nutrisens (2025)

Ce dépôt rassemble les travaux et scripts PowerShell réalisés au cours de mon stage de fin d'études au sein du service IT de l'entreprise **Nutrisens** à Chaponost (69630), en 2025. 

L'objectif principal était de piloter de A à Z la modernisation, la sécurisation et l'automatisation complète de la gestion des listes de diffusion et des groupes de sécurité de l'entreprise, aux niveaux national et international.

---

## 🎯 Contexte & Enjeux du Projet

Avec l'évolution de l'infrastructure de Nutrisens, la gestion manuelle ou purement locale des listes de diffusion n'était plus adaptée. Les défis majeurs du projet consistaient à :
1. **Garantir le dynamisme :** Mettre à jour automatiquement les listes selon les données RH de chaque collaborateur (lieu de travail `Office` et entreprise `Company`).
2. **Piloter la transition Cloud :** Passer d'un modèle d'administration *On-Premises* (Active Directory local) à un modèle moderne cloud natif (*Exchange Online* et *Entra ID*).
3. **Automatiser en toute sécurité :** Contourner l'authentification multifacteur (MFA) obligatoire de manière conforme, grâce à des processus *unattended* basés sur le protocole OAuth 2.0 (Application Registrations et certificats).
4. **Renforcer la gouvernance :** Mettre sous contrôle la sécurité des flux d'e-mails (MailInBlack) et responsabiliser les propriétaires métiers de données (*Data Owners*).

---

## 🌿 Structure du Dépôt (Branches)

Pour une meilleure lisibilité, ce projet a été segmenté en 3 branches thématiques indépendantes. Cliquez sur les liens pour accéder directement aux codes sources et à leur documentation spécifique :

### 1. 📂 [Branche `sync-distribution-lists`](../../tree/sync-distribution-lists) — Synchronisation des Listes de Diffusion
* **Objectif :** Orchestration de la mise à jour des listes nationales et internationales en fonction du lieu et de l'entreprise des utilisateurs.
* **Évolution :** Contient la V1 historique (`ancien_script_exclu_ad.ps1`) basée exclusivement sur l'AD, ainsi que la solution finale de production (`script_final.ps1`) intégrée à Exchange Online via une application Entra ID.
* **Gestion des cas particuliers :** Intégration de fichiers d'exceptions RH à chaud pour adapter finement le besoin métier.

### 2. 📂 [Branche `mailinblack-automation`](../../tree/mailinblack-automation) — Sécurisation & Intégration MailInBlack
* **Objectif :** Automatisation du peuplement des groupes de sécurité synchronisés avec la solution de protection de messagerie MailInBlack (MIB).
* **Technique :** Utilisation conjointe du module `ExchangeOnlineManagement` et des API natives de `Microsoft.Graph`.
* **Logique métier :** Isolation des comptes humains cloud uniques (`UserMailbox` non on-prem) d'un côté, et regroupement des boîtes génériques/partagées (`SharedMailbox`) de l'autre pour une conformité de filtrage et de licence parfaite.

### 3. 📂 [Branche `exchange-governance-reporting`](../../tree/exchange-governance-reporting) — Audit, Reporting & Relance des Propriétaires
* **Objectif :** Mettre en place un cycle de vie sain pour les listes de diffusion de l'entreprise et assurer le suivi IT.
* **Outils :** 
  * Un script d'envoi ponctuel de rapport de membres sous forme de structure HTML propre pour les responsables opérationnels.
  * Un script automatisé de gouvernance (`script-mail-proprios.ps1`) qui filtre les listes cloud, ignore les comptes d'administration et interpelle directement par mail les propriétaires métiers pour auditer l'utilité et la composition de leurs listes (*anti-group-sprawl*).

---

## 🛠️ Technologies & Compétences Clés Clés

* **Langages :** PowerShell (v5.1 / v7+)
* **Écosystème Microsoft 365 :** Exchange Online Management, Microsoft Graph API, Entra ID (Azure AD).
* **Sécurité IAM :** Authentification par certificat (Certificate-Based Authentication), Gestion d'applications d'entreprise, Token OAuth 2.0, Principe du moindre privilège.
* **Exploitation :** Windows Task Planner (Planificateur de tâches), gestion avancée de logs et historique glissant (Rétention automatique sur 4 semaines).

---

## 📝 Note de Confidentialité
*Tous les scripts et fichiers de configuration fournis dans ce dépôt ont été rigoureusement anonymisés (suppression des ID d'applications réels, empreintes de certificats, noms de domaines et données nominatives des collaborateurs) conformément aux règles de confidentialité de l'entreprise Nutrisens.*

---
💬 *Projet piloté et développé de A à Z en autonomie dans le cadre d'un stage au sein du service IT de Nutrisens (2025).*
