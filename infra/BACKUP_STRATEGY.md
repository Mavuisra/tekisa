## Sauvegardes base de données

- **PostgreSQL**:
  - Sauvegarde complète quotidienne avec `pg_dump` vers un stockage objet (par exemple, S3 compatible).
  - Rétention: 7 jours en environnement de test, 30 jours en production.
  - Script cron dans le conteneur `db-backup` (à ajouter) ou sur l'hôte.

- **Stratégie**:
  - Vérifier régulièrement la restaurabilité des sauvegardes sur une base de test.
  - Chiffrer les sauvegardes au repos si possible.

