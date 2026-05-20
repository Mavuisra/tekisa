/// Exceptions et gestion d'erreurs centralisée
library;

import 'package:equatable/equatable.dart';

/// Exception métier de l'application
abstract class AppException implements Exception {
  String get message;
  String? get code;

  @override
  String toString() => 'Exception: $message';
}

/// Erreur réseau (timeout, pas de connexion, etc.)
class NetworkException extends AppException with EquatableMixin {
  @override
  final String message;
  @override
  final String? code;
  final int? statusCode;

  NetworkException({
    this.message = 'Erreur de connexion. Vérifiez votre réseau.',
    this.code,
    this.statusCode,
  });

  @override
  List<Object?> get props => [message, code, statusCode];

  @override
  String toString() => 'Exception: $message';
}

/// Erreur d'authentification (401, token expiré, etc.)
class AuthException extends AppException with EquatableMixin {
  @override
  final String message;
  @override
  final String? code;

  AuthException({
    this.message = 'Session expirée. Veuillez vous reconnecter.',
    this.code,
  });

  @override
  List<Object?> get props => [message, code];

  @override
  String toString() => 'Exception: $message';
}

/// Erreur serveur (5xx)
class ServerException extends AppException with EquatableMixin {
  @override
  final String message;
  @override
  final String? code;
  final int? statusCode;

  ServerException({
    this.message = 'Le serveur est temporairement indisponible.',
    this.code,
    this.statusCode,
  });

  @override
  List<Object?> get props => [message, code, statusCode];

  @override
  String toString() => 'Exception: $message';
}

/// Erreur de validation (champs invalides)
class ValidationException extends AppException with EquatableMixin {
  @override
  final String message;
  @override
  final String? code;
  final Map<String, List<String>>? errors;

  ValidationException({
    this.message = 'Données invalides',
    this.code,
    this.errors,
  });

  @override
  List<Object?> get props => [message, code, errors];

  @override
  String toString() => 'Exception: $message';
}

/// Erreur inconnue
class UnknownException extends AppException with EquatableMixin {
  @override
  final String message;
  @override
  final String? code;

  UnknownException([
    this.message = 'Une erreur inattendue est survenue.',
    this.code,
  ]);

  @override
  List<Object?> get props => [message, code];

  @override
  String toString() => 'Exception: $message';
}

/// Requête stockée localement et synchronisée plus tard.
class QueuedForSyncException extends AppException with EquatableMixin {
  @override
  final String message;
  @override
  final String? code;

  QueuedForSyncException({
    this.message =
        'Mode hors ligne: action enregistree et en attente de synchronisation.',
    this.code = 'queued_for_sync',
  });

  @override
  List<Object?> get props => [message, code];

  @override
  String toString() => 'Exception: $message';
}
