# CisnetKids – Architecture

Application éducative gamifiée pour enfants (programme scolaire RDC).  
Clean Architecture + Riverpod + Dio + WebSocket + Hive.

## Structure des dossiers

```
lib/
├── main.dart                 # Point d'entrée, init Hive, ProviderScope
├── app_router.dart           # go_router : routes + redirect auth
│
├── core/
│   ├── constants/            # API URLs, endpoints, Ws events, Storage keys, MathSkill
│   ├── theme/                # AppColors, AppTheme
│   ├── errors/               # AppException, NetworkException, AuthException, etc.
│   ├── network/              # DioClient (interceptors auth + erreurs)
│   └── di/                   # Riverpod providers (Dio, Hive, repos, socket)
│
├── domain/
│   ├── entities/             # UserEntity, MathQuestionEntity, ProgressEntity
│   └── repositories/         # AuthRepository, QuestionRepository, ProgressRepository
│
├── data/
│   ├── models/               # UserModel, MathQuestionModel, AuthTokensModel, etc. (fromJson/toJson)
│   ├── datasources/          # Auth remote/local, Question remote, Progress remote
│   ├── repositories/         # Impl des repositories (Auth, Question, Progress)
│   └── services/             # ContestSocketService (WebSocket concours)
│
└── presentation/
    ├── providers/            # auth_provider, contest_provider, training_provider
    ├── screens/              # Splash, Login, Register, Dashboard, Contest, Training
    └── (widgets/)             # À ajouter si besoin (boutons, cartes réutilisables)
```

## Flux principaux

- **Auth** : Login/Register → AuthRepository (remote + local) → JWT en secure storage, user en Hive → `authNotifierProvider` + `accessTokenProvider`.
- **Concours** : `ContestSocketService` (socket_io_client) → join_room, new_question, submit_answer, score_update → `contestNotifierProvider` (family roomId/userId/token).
- **Entraînement** : `QuestionRepository` → GET /question, POST /answer → correction + explication → `trainingNotifierProvider`.

## Backend attendu

- **REST** : POST /auth/login, POST /auth/register, GET /question, POST /answer, GET /progress.
- **WebSocket** : join_room, new_question, submit_answer, answer_result, score_update.

## Commandes utiles

```bash
flutter pub get
# Optionnel : génération Freezed/JSON (si vous réactivez les modèles Freezed)
dart run build_runner build --delete-conflicting-outputs
flutter run
```

## Remarques

- Les modèles data sont en classes manuelles (fromJson/toJson) pour éviter la codegen par défaut. Vous pouvez réintroduire Freezed + build_runner si besoin.
- JWT : stocké dans `flutter_secure_storage`, injecté dans Dio via `accessTokenProvider` et mis à jour au login/logout/refresh.
- Hive : une box `cisnetkids_user` (String) pour le cache utilisateur (JSON).
