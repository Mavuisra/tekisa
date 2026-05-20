## MVP 90 jours - CisnetKids

### Phase 1 (Semaines 1–4) – Fondations

- Backend
  - Initialiser le projet Django/DRF, modèle utilisateur, multi-tenant par `school_id`.
  - Implémenter les modèles: `School`, `Classroom`, `Subject`, `AcademicYear`, `Term`, `User`, `ParentProfile`, `TeacherProfile`, `StudentProfile`, `Enrollment`.
  - Mettre en place JWT + OTP SMS (flux de base) pour les parents.
- Mobile
  - Créer le squelette Flutter (Clean Architecture), navigation, thème.
  - Écran de connexion OTP et intégration basique avec l’API.
- Infra
  - Docker local (web, db, redis), configuration Nginx de base.

### Phase 2 (Semaines 5–8) – Fonctionnalités cœur école

- Backend
  - Notes: `Assessment`, `Grade`, agrégation moyenne simple par matière/terme.
  - Présences: `AttendanceRecord` avec endpoints pour marquer présence/retard/absence.
  - Paiements: `Invoice`, `Payment` avec simulation Mobile Money.
  - Messagerie: `Conversation`, `Message` parent ↔ école.
  - Notifications: SMS/push abstraites, envoi via Celery (au moins en mode mock).
- Mobile
  - Dashboard parent (résumé enfant).
  - Écrans: notes (liste + courbe simple), absences, factures + statut de paiement, messagerie simple.
- Qualité
  - Pagination DRF sur tous les endpoints de liste.
  - Première passe d’optimisation des requêtes (`select_related`, `prefetch_related`).

### Phase 3 (Semaines 9–12) – Finitions, analytique & prêt au pilote

- Backend
  - Génération de bulletins PDF par terme (tâches Celery).
  - Moteur de détection simple des élèves à risque (`StudentRiskScore`) basé sur des règles.
  - Logging avancé, métriques de performance clés.
- Mobile
  - Cache offline (Hive/SQLite) pour: résumé, notes, présences, factures, messages récents.
  - Service de synchronisation automatique + état “dernier sync”.
  - Optimisation UX pour Android bas de gamme (images légères, listes paginées).
- Ops
  - Pipeline CI/CD complet vers un VPS Linux.
  - Sauvegardes quotidiennes Postgres + restauration test.
  - Déploiement pilote sur quelques écoles à Kinshasa, collecte de feedback et itérations rapides.

