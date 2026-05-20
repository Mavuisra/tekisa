/// Configuration d'environnement : URLs API selon debug/release et plateforme.
/// En debug, pointe vers l'API locale (FastAPI) sans rien configurer.
library;

import 'package:flutter/foundation.dart';

// Conditionnel pour éviter dart:io sur le web
import 'env_config_io.dart'
    if (dart.library.html) 'env_config_stub.dart'
    as env_io;

/// URLs et mode API (local / prod)
class EnvConfig {
  EnvConfig._();

  static String _normalizeBaseUrl(String raw) {
    // 0.0.0.0 n'est pas une cible valide côté navigateur/mobile client.
    return raw.replaceAll('0.0.0.0', 'localhost');
  }

  /// URL de base REST (sans slash final). Ex: http://127.0.0.1:8000/api/v1
  static String get apiBaseUrl {
    const fromEnv = String.fromEnvironment('API_BASE_URL', defaultValue: '');
    if (fromEnv.isNotEmpty) return _normalizeBaseUrl(fromEnv);

    if (kReleaseMode) {
      return _normalizeBaseUrl('https://tekisa.pythonanywhere.com/api/v1');
    }

    // Mode debug : API locale selon la plateforme
    return _normalizeBaseUrl(env_io.getLocalApiBaseUrl());
  }

  /// URL WebSocket (mode concours). En local, pas de WS par défaut.
  static String get wsUrl {
    const fromEnv = String.fromEnvironment('WS_URL', defaultValue: '');
    if (fromEnv.isNotEmpty) return _normalizeBaseUrl(fromEnv);
    if (kReleaseMode) return _normalizeBaseUrl('https://ws.cisnetkids.cd');
    return _normalizeBaseUrl(env_io.getLocalWsUrl());
  }

  static bool get isLocalApi =>
      apiBaseUrl.contains('localhost') ||
      apiBaseUrl.contains('127.0.0.1') ||
      apiBaseUrl.contains('10.0.2.2');

  /// URL backend fixe en dev (127.0.0.1:8000/api/v1)
  static const String devApiBaseUrl = 'http://127.0.0.1:8000/api/v1';
}
