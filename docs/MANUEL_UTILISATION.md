# Manuel d'usage - CisnetKids Commerce

Ce manuel explique l'utilisation quotidienne de l'application mobile pour les activites commerce (boutique, restaurant, pharmacie, salon de coiffure).

## 1) Installation de l'application

- Installer l'APK correspondant au telephone:
  - `app-arm64-v8a-release.apk` (recommande pour la majorite des appareils Android recents)
  - `app-armeabi-v7a-release.apk` (anciens appareils 32 bits)
- Activer l'installation depuis une source inconnue dans Android si necessaire.
- Ouvrir l'application apres installation.

## 2) Premiere connexion

### Creer un compte

1. Ouvrir l'ecran d'inscription.
2. Renseigner:
   - Identifiant
   - Mot de passe
   - Telephone
   - Categorie metier (Boutique / Restaurant / Pharmacie / Salon de coiffure)
   - Informations entreprise
3. Valider.

### Se connecter

1. Saisir identifiant + mot de passe.
2. Valider.
3. L'application charge l'interface adaptee au profil selectionne.

## 3) Navigation principale

- **Pilotage**: indicateurs journaliers (CA, transactions, performances).
- **Vendre / Prestations**:
  - Boutique/Restaurant/Pharmacie: ventes rapides.
  - Salon: selection services + coiffeur + paiement.
- **Stock**: disponible pour les profils a stock (pas pour salon).
- **Clients**: consultation et ajout de clients/patients.

## 4) Mode hors ligne (offline-first)

L'application fonctionne meme sans internet sur les operations principales.

- Les donnees deja chargees restent accessibles localement.
- Les actions d'ecriture sont stockees en file d'attente locale.
- Des qu'internet revient, la synchronisation se fait automatiquement.
- Une banniere indique le mode hors ligne.

## 5) Utilisation par profil

## Boutique / Restaurant / Pharmacie

### Vente rapide

1. Rechercher et ajouter les articles.
2. Selectionner (optionnel) un client.
3. Choisir le mode de paiement.
4. Valider l'encaissement.

### Stock

- Consulter les niveaux de stock.
- Ajouter du stock.
- Voir l'historique des mouvements.

### Clients

- Creer un client/patient.
- Suivre les clients inactifs.

## Salon de coiffure

### Encaissement de prestations

1. Rechercher ou parcourir les prestations par categorie:
   - Beaute
   - Coiffure
   - Onglerie
   - Maquillage
2. Selectionner une ou plusieurs prestations.
3. Choisir le coiffeur.
4. Saisir le client (optionnel).
5. Choisir le paiement (Cash / Mobile Money).
6. Valider.

### Administration salon

Depuis le menu en haut a droite:

- **Ajouter prestation** avec attributs:
  - Code
  - Nom
  - Categorie
  - Description
  - Image (URL ou via galerie/camera)
  - Prix
  - Duree
  - Populaire (oui/non)
  - Active (oui/non)
- **Creer coiffeur / caissier**:
  - Nom complet
  - Username
  - Telephone
  - Role (coiffeur ou caissier)
  - PIN (optionnel)

### Statistiques salon

- Gain du jour
- Nombre de prestations
- Ticket moyen
- Top coiffeur

## 6) Bonnes pratiques d'exploitation

- Utiliser un seul compte par employe pour une meilleure tracabilite.
- Verifier regulierement les statistiques de pilotage.
- En zone reseau instable, continuer a travailler normalement: la synchro sera automatique.
- Garder des codes prestation clairs et uniques.

## 7) Depannage rapide

### "Session expiree"
- Se reconnecter.

### Les donnees semblent ne pas se mettre a jour
- Tirer vers le bas pour actualiser.
- Verifier la connexion internet.

### Actions faites hors ligne non visibles cote serveur
- Verifier le retour reseau.
- Attendre la synchronisation automatique.

### Erreur d'installation APK
- Verifier l'architecture du telephone (arm64-v8a recommande).
- Reinstaller l'APK adequat.

## 8) Securite et exploitation pro

- Pour diffusion interne test: APK release suffit.
- Pour production store:
  - utiliser un `applicationId` final
  - signer avec une cle release dediee
  - preferer un bundle `AAB` pour Google Play.
