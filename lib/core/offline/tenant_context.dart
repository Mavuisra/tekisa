library;

import '../../data/datasources/auth_local_datasource.dart';

class TenantContext {
  const TenantContext({
    required this.tenantId,
    required this.userId,
    required this.businessCategory,
  });

  final String tenantId;
  final String userId;
  final String businessCategory;

  static TenantContext? current() {
    final user = AuthLocalDataSource().getUser();
    if (user == null || user.id.trim().isEmpty) {
      return null;
    }
    final category = _sanitize(user.businessCategory ?? 'default');
    final userId = _sanitize(user.id);
    final rawCompany = (user.companyName ?? '').trim();
    final scope = rawCompany.isNotEmpty ? _sanitize(rawCompany) : userId;
    return TenantContext(
      tenantId: '${category}_$scope',
      userId: userId,
      businessCategory: category,
    );
  }

  static String _sanitize(String raw) {
    final value = raw.trim().toLowerCase();
    if (value.isEmpty) {
      return 'default';
    }
    return value.replaceAll(RegExp(r'[^a-z0-9_]'), '_');
  }
}
