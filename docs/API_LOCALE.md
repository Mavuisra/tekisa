# Pourquoi le timeout ? (API locale)

Un message du type **"The request took longer than 0:00:45 to receive data"** veut dire : **l’app n’a reçu aucune réponse du serveur**. Ce n’est pas un réglage de durée à augmenter, c’est que la requête ne trouve pas (ou n’atteint pas) ton API.

## Causes possibles

### 1. L’API n’est pas démarrée
L’app envoie les requêtes vers `http://10.0.2.2:8000/v1` (Android) ou `http://127.0.0.1:8000/v1` (iOS). Si aucun serveur n’écoute sur le port 8000, la connexion reste en attente puis **timeout**.

**À faire :** avant de lancer l’app Flutter, démarre l’API :

```bash
cd api
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

Tu dois voir dans le terminal quelque chose comme : `Uvicorn running on http://0.0.0.0:8000`.

### 2. Mauvaise URL utilisée par l’app
En **debug**, l’app doit utiliser l’URL locale (voir dans la console au lancement : `CisnetKids API baseUrl: http://10.0.2.2:8000/v1` ou `http://127.0.0.1:8000/v1`).

- Si tu vois `https://api.cisnetkids.cd/v1`, l’app est en mode prod (ou un build release) : ce serveur peut ne pas exister ou être lent → timeout.
- **À faire :** lance bien en mode debug (`flutter run` sans `--release`). Si tu es sur **appareil physique**, utilise :  
  `flutter run --dart-define=API_BASE_URL=http://IP_DE_TON_PC:8000/v1`  
  (remplace `IP_DE_TON_PC` par l’IP de ta machine sur le réseau, ex. 192.168.1.x).

### 3. Appareil physique (téléphone) sur le même réseau
Sur un vrai téléphone, `10.0.2.2` et `127.0.0.1` ne pointent pas vers ton PC. Il faut que l’app cible l’IP de ton ordinateur.

**À faire :**
1. Sur le PC : `uvicorn main:app --host 0.0.0.0 --port 8000`
2. Trouve l’IP du PC (ex. 192.168.1.10).
3. Lance l’app avec :  
   `flutter run --dart-define=API_BASE_URL=http://192.168.1.10:8000/v1`  
   (en mettant ta vraie IP).

### 4. Flutter Web (navigateur)
Si tu lances l’app en **Chrome / Web** (`flutter run -d chrome`), l’app utilise maintenant **http://localhost:8000/v1** en debug. Vérifie que l’API tourne sur le même ordinateur (`uvicorn main:app --reload --host 0.0.0.0 --port 8000`). L’erreur « XMLHttpRequest onError » vient souvent du fait que l’API n’est pas démarrée ou que l’URL pointait vers la prod.

### 5. Firewall / antivirus
Un firewall ou un antivirus sur le PC peut bloquer le port 8000. Désactive temporairement ou autorise le port 8000 pour les connexions entrantes.

---

## Vérification rapide

1. **API :** dans un navigateur sur le PC, ouvre `http://127.0.0.1:8000/health`. Tu dois voir `{"status":"ok"}`.
2. **App :** au lancement en debug, regarde la console Flutter : la ligne `CisnetKids API baseUrl: ...` doit afficher l’URL locale (pas `https://api.cisnetkids.cd`).
3. **Même machine / même réseau :** émulateur = même machine ; téléphone = même WiFi et IP du PC dans `API_BASE_URL`.

Une fois l’API démarrée et l’URL correcte, le timeout disparaît car le serveur répond.
