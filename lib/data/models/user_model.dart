/// Modèle utilisateur (data) - sérialisation API / stockage
library;

import '../../domain/entities/user_entity.dart';

class UserModel {
  const UserModel({
    required this.id,
    required this.role,
    this.email,
    this.username,
    this.phone,
    this.businessCategory,
    this.companyName,
    this.companyTradeName,
    this.legalForm,
    this.rccm,
    this.idnat,
    this.nif,
    this.companyEmail,
    this.companyPhone,
    this.companyCountry,
    this.companyProvince,
    this.companyCity,
    this.companyCommune,
    this.companyQuarter,
    this.companyAvenue,
    this.companyNumber,
    this.displayName,
    this.avatarUrl,
    this.niveau,
    this.totalScore,
  });

  final String id;
  final String role;
  final String? email;
  final String? username;
  final String? phone;
  final String? businessCategory;
  final String? companyName;
  final String? companyTradeName;
  final String? legalForm;
  final String? rccm;
  final String? idnat;
  final String? nif;
  final String? companyEmail;
  final String? companyPhone;
  final String? companyCountry;
  final String? companyProvince;
  final String? companyCity;
  final String? companyCommune;
  final String? companyQuarter;
  final String? companyAvenue;
  final String? companyNumber;
  final String? displayName;
  final String? avatarUrl;
  final int? niveau;
  final int? totalScore;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    return UserModel(
      id: id?.toString() ?? '',
      email: json['email'] as String?,
      username: json['username'] as String?,
      phone: json['phone'] as String?,
      businessCategory:
          json['business_category'] as String? ??
          json['businessCategory'] as String?,
      companyName: json['company_name'] as String?,
      companyTradeName: json['company_trade_name'] as String?,
      legalForm: json['legal_form'] as String?,
      rccm: json['rccm'] as String?,
      idnat: json['idnat'] as String?,
      nif: json['nif'] as String?,
      companyEmail: json['company_email'] as String?,
      companyPhone: json['company_phone'] as String?,
      companyCountry: json['company_country'] as String?,
      companyProvince: json['company_province'] as String?,
      companyCity: json['company_city'] as String?,
      companyCommune: json['company_commune'] as String?,
      companyQuarter: json['company_quarter'] as String?,
      companyAvenue: json['company_avenue'] as String?,
      companyNumber: json['company_number'] as String?,
      role: json['role'] as String? ?? 'seller',
      displayName:
          json['display_name'] as String? ?? json['displayName'] as String?,
      avatarUrl: json['avatar_url'] as String? ?? json['avatarUrl'] as String?,
      niveau: json['niveau'] as int? ?? json['level'] as int?,
      totalScore: json['total_score'] as int? ?? json['totalScore'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (email != null) 'email': email,
      if (username != null) 'username': username,
      if (phone != null) 'phone': phone,
      if (businessCategory != null) 'business_category': businessCategory,
      if (companyName != null) 'company_name': companyName,
      if (companyTradeName != null) 'company_trade_name': companyTradeName,
      if (legalForm != null) 'legal_form': legalForm,
      if (rccm != null) 'rccm': rccm,
      if (idnat != null) 'idnat': idnat,
      if (nif != null) 'nif': nif,
      if (companyEmail != null) 'company_email': companyEmail,
      if (companyPhone != null) 'company_phone': companyPhone,
      if (companyCountry != null) 'company_country': companyCountry,
      if (companyProvince != null) 'company_province': companyProvince,
      if (companyCity != null) 'company_city': companyCity,
      if (companyCommune != null) 'company_commune': companyCommune,
      if (companyQuarter != null) 'company_quarter': companyQuarter,
      if (companyAvenue != null) 'company_avenue': companyAvenue,
      if (companyNumber != null) 'company_number': companyNumber,
      'role': role,
      if (displayName != null) 'display_name': displayName,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
      if (niveau != null) 'niveau': niveau,
      if (totalScore != null) 'total_score': totalScore,
    };
  }

  UserEntity toEntity() => UserEntity(
    id: id,
    email: email ?? username ?? phone ?? '',
    role: UserRole.fromString(role),
    displayName: displayName ?? username,
    avatarUrl: avatarUrl,
    niveau: niveau,
    totalScore: totalScore,
  );
}
