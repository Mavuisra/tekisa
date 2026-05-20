library;

class SalonServiceModel {
  const SalonServiceModel({
    required this.id,
    required this.code,
    required this.name,
    required this.category,
    required this.description,
    required this.imageUrl,
    required this.price,
    required this.durationMinutes,
    required this.isPopular,
    required this.active,
  });

  final String id;
  final String code;
  final String name;
  final String category;
  final String description;
  final String imageUrl;
  final double price;
  final int durationMinutes;
  final bool isPopular;
  final bool active;
}

class SalonStylistModel {
  const SalonStylistModel({
    required this.id,
    required this.fullName,
    required this.active,
  });

  final String id;
  final String fullName;
  final bool active;
}

class SalonStaffUserModel {
  const SalonStaffUserModel({
    required this.id,
    required this.fullName,
    required this.username,
    required this.phone,
    required this.role,
    required this.active,
  });

  final String id;
  final String fullName;
  final String username;
  final String phone;
  final String role;
  final bool active;
}

class SalonSaleModel {
  const SalonSaleModel({
    required this.id,
    required this.serviceName,
    required this.stylistName,
    required this.clientName,
    required this.paymentMethod,
    required this.amount,
    required this.createdAtMs,
  });

  final String id;
  final String serviceName;
  final String stylistName;
  final String clientName;
  final String paymentMethod;
  final double amount;
  final int createdAtMs;
}

class SalonTodayStats {
  const SalonTodayStats({
    required this.totalRevenue,
    required this.totalSales,
    required this.averageTicket,
    required this.topStylist,
    required this.topStylistRevenue,
  });

  final double totalRevenue;
  final int totalSales;
  final double averageTicket;
  final String topStylist;
  final double topStylistRevenue;
}
