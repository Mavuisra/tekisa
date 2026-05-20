/// Implémentation plateforme (Android / iOS / desktop) pour les URLs locales.
library;

import 'dart:io' show Platform;

/// Backend Django (CisnetKids). Base = http://127.0.0.1:8000/api/v1
/// Android émulateur : 10.0.2.2 = machine hôte.
/// Appareil physique : --dart-define=API_BASE_URL=http://IP:8000/api/v1
String getLocalApiBaseUrl() {
  const base = 'http://127.0.0.1:8000/api/v1';
  if (Platform.isAndroid) {
    return 'http://10.0.2.2:8000/api/v1';
  }
  return base;
}

String getLocalWsUrl() {
  if (Platform.isAndroid) {
    return 'http://10.0.2.2:8000';
  }
  return 'http://127.0.0.1:8000';
}
