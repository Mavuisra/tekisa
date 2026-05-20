/// Entité utilisateur (domain layer - sans dépendance data)
library;

import 'package:equatable/equatable.dart';

/// Rôle utilisateur principal
enum UserRole {
  eleve,
  parent,
  seller,
  superAdmin,
  schoolAdmin,
  teacher;

  static UserRole fromString(String value) {
    final normalized = value.toLowerCase().replaceAll('_', '');
    return UserRole.values.firstWhere(
      (e) => e.name.toLowerCase().replaceAll('_', '') == normalized,
      orElse: () => UserRole.eleve,
    );
  }
}

/// Entité utilisateur
class UserEntity extends Equatable {
  const UserEntity({
    required this.id,
    required this.email,
    required this.role,
    this.displayName,
    this.avatarUrl,
    this.niveau,
    this.totalScore,
  });

  final String id;
  final String email;
  final UserRole role;
  final String? displayName;
  final String? avatarUrl;

  /// Niveau scolaire ou niveau de jeu (élève)
  final int? niveau;

  /// Score total (élève)
  final int? totalScore;

  bool get isEleve => role == UserRole.eleve;
  bool get isParent => role == UserRole.parent;
  bool get isSeller => role == UserRole.seller;
  bool get isAdmin =>
      role == UserRole.superAdmin || role == UserRole.schoolAdmin;

  @override
  List<Object?> get props => [id, email, role, displayName, niveau, totalScore];
}
