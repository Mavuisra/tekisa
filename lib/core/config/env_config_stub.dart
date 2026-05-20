/// Stub pour le web (dart:io indisponible). En debug → localhost pour l'API locale.
library;

import 'package:flutter/foundation.dart';

String getLocalApiBaseUrl() {
  if (kDebugMode) {
    final host = Uri.base.host.isNotEmpty ? Uri.base.host : 'localhost';
    // Sur le web, on pointe le backend sur le même host que l'app
    // (utile si accès via IP LAN plutôt que localhost).
    return 'http://$host:8000/api/v1';
  }
  return 'https://api.cisnetkids.cd/api/v1';
}

String getLocalWsUrl() {
  if (kDebugMode) {
    final host = Uri.base.host.isNotEmpty ? Uri.base.host : 'localhost';
    return 'http://$host:8000';
  }
  return 'https://ws.cisnetkids.cd';
}
