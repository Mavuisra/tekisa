library;

double _toDouble(dynamic value, {double fallback = 0}) {
  if (value == null) return fallback;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? fallback;
  return fallback;
}

int _toInt(dynamic value, {int fallback = 0}) {
  if (value == null) return fallback;
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}

bool _toBool(dynamic value, {bool fallback = false}) {
  if (value == null) return fallback;
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final normalized = value.trim().toLowerCase();
    return normalized == '1' || normalized == 'true' || normalized == 'yes';
  }
  return fallback;
}

class CommerceProductModel {
  const CommerceProductModel({
    required this.id,
    required this.name,
    required this.sku,
    required this.unitPrice,
    required this.costPrice,
    required this.stockQuantity,
    required this.reorderThreshold,
    required this.isActive,
  });

  final int id;
  final String name;
  final String sku;
  final double unitPrice;
  final double costPrice;
  final int stockQuantity;
  final int reorderThreshold;
  final bool isActive;

  factory CommerceProductModel.fromJson(Map<String, dynamic> json) {
    return CommerceProductModel(
      id: _toInt(json['id']),
      name: json['name'] as String? ?? '',
      sku: json['sku'] as String? ?? '',
      unitPrice: _toDouble(json['unit_price']),
      costPrice: _toDouble(json['cost_price']),
      stockQuantity: _toInt(json['stock_quantity']),
      reorderThreshold: _toInt(json['reorder_threshold']),
      isActive: json['is_active'] as bool? ?? true,
    );
  }
}

class StockOverviewItemModel {
  const StockOverviewItemModel({
    required this.id,
    required this.name,
    required this.sku,
    required this.stockQuantity,
    required this.reorderThreshold,
    required this.isCritical,
    required this.velocity,
    this.lastStockAddAt,
    this.lastStockAddBy,
    this.lastStockAddQty = 0,
  });

  final int id;
  final String name;
  final String sku;
  final int stockQuantity;
  final int reorderThreshold;
  final bool isCritical;
  final String velocity;
  final String? lastStockAddAt;
  final String? lastStockAddBy;
  final int lastStockAddQty;

  factory StockOverviewItemModel.fromJson(Map<String, dynamic> json) {
    return StockOverviewItemModel(
      id: _toInt(json['id']),
      name: json['name'] as String? ?? '',
      sku: json['sku'] as String? ?? '',
      stockQuantity: _toInt(json['stock_quantity']),
      reorderThreshold: _toInt(json['reorder_threshold']),
      isCritical: json['is_critical'] as bool? ?? false,
      velocity: json['velocity'] as String? ?? 'stable',
      lastStockAddAt: json['last_stock_add_at'] as String?,
      lastStockAddBy: json['last_stock_add_by'] as String?,
      lastStockAddQty: _toInt(json['last_stock_add_qty']),
    );
  }
}

class StockMovementTraceModel {
  const StockMovementTraceModel({
    required this.id,
    required this.productId,
    required this.productName,
    required this.sku,
    required this.movementType,
    required this.quantity,
    required this.reason,
    required this.balanceAfter,
    required this.addedBy,
    required this.createdAt,
    required this.reference,
  });

  final int id;
  final int productId;
  final String productName;
  final String sku;
  final String movementType;
  final int quantity;
  final String reason;
  final int balanceAfter;
  final String addedBy;
  final String createdAt;
  final String reference;

  factory StockMovementTraceModel.fromJson(Map<String, dynamic> json) {
    return StockMovementTraceModel(
      id: _toInt(json['id']),
      productId: _toInt(json['product_id']),
      productName: json['product_name'] as String? ?? '',
      sku: json['sku'] as String? ?? '',
      movementType: json['movement_type'] as String? ?? '',
      quantity: _toInt(json['quantity']),
      reason: json['reason'] as String? ?? '',
      balanceAfter: _toInt(json['balance_after']),
      addedBy: json['added_by'] as String? ?? '',
      createdAt: json['created_at'] as String? ?? '',
      reference: json['reference'] as String? ?? '',
    );
  }
}

class SalesSummaryModel {
  const SalesSummaryModel({
    required this.todayRevenue,
    required this.transactions,
    required this.averageTicket,
  });

  final double todayRevenue;
  final int transactions;
  final double averageTicket;

  factory SalesSummaryModel.fromJson(Map<String, dynamic> json) {
    return SalesSummaryModel(
      todayRevenue: _toDouble(json['today_revenue']),
      transactions: _toInt(json['transactions']),
      averageTicket: _toDouble(json['average_ticket']),
    );
  }
}

class CartItemInput {
  const CartItemInput({required this.productId, required this.quantity});

  final int productId;
  final int quantity;

  Map<String, dynamic> toJson() {
    return {'product_id': productId, 'quantity': quantity};
  }
}

class AdminPlatformOverviewModel {
  const AdminPlatformOverviewModel({
    required this.sellersCount,
    required this.productsCount,
    required this.salesCount,
    required this.revenueTotal,
  });

  final int sellersCount;
  final int productsCount;
  final int salesCount;
  final double revenueTotal;

  factory AdminPlatformOverviewModel.fromJson(Map<String, dynamic> json) {
    return AdminPlatformOverviewModel(
      sellersCount: _toInt(json['sellers_count']),
      productsCount: _toInt(json['products_count']),
      salesCount: _toInt(json['sales_count']),
      revenueTotal: _toDouble(json['revenue_total']),
    );
  }
}

class SellerActivityModel {
  const SellerActivityModel({
    required this.sellerId,
    required this.username,
    required this.phone,
    required this.productsCount,
    required this.salesCount,
    required this.revenue,
  });

  final int sellerId;
  final String username;
  final String phone;
  final int productsCount;
  final int salesCount;
  final double revenue;

  factory SellerActivityModel.fromJson(Map<String, dynamic> json) {
    return SellerActivityModel(
      sellerId: _toInt(json['seller_id']),
      username: json['username'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      productsCount: _toInt(json['products_count']),
      salesCount: _toInt(json['sales_count']),
      revenue: _toDouble(json['revenue']),
    );
  }
}

class CustomerSummaryModel {
  const CustomerSummaryModel({
    required this.id,
    required this.fullName,
    required this.phone,
    required this.segment,
    required this.salesCount,
    required this.totalSpent,
    this.lastPurchaseAt,
  });

  final int id;
  final String fullName;
  final String phone;
  final String segment;
  final int salesCount;
  final double totalSpent;
  final String? lastPurchaseAt;

  factory CustomerSummaryModel.fromJson(Map<String, dynamic> json) {
    return CustomerSummaryModel(
      id: _toInt(json['id']),
      fullName: json['full_name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      segment: json['segment'] as String? ?? 'regular',
      salesCount: _toInt(json['sales_count']),
      totalSpent: _toDouble(json['total_spent']),
      lastPurchaseAt: json['last_purchase_at'] as String?,
    );
  }
}

class CommerceCustomerModel {
  const CommerceCustomerModel({
    required this.id,
    required this.fullName,
    required this.phone,
    required this.email,
    required this.segment,
    required this.notes,
  });

  final int id;
  final String fullName;
  final String phone;
  final String email;
  final String segment;
  final String notes;

  factory CommerceCustomerModel.fromJson(Map<String, dynamic> json) {
    return CommerceCustomerModel(
      id: _toInt(json['id']),
      fullName: json['full_name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      email: json['email'] as String? ?? '',
      segment: json['segment'] as String? ?? 'regular',
      notes: json['notes'] as String? ?? '',
    );
  }
}

class SupplierProductModel {
  const SupplierProductModel({
    required this.id,
    this.sourceProductId,
    required this.name,
    required this.price,
    required this.isAvailable,
    this.imageUrl = '',
    this.stockQuantity = 0,
  });

  final int id;
  final int? sourceProductId;
  final String name;
  final double price;
  final bool isAvailable;
  final String imageUrl;
  final int stockQuantity;

  factory SupplierProductModel.fromJson(Map<String, dynamic> json) {
    return SupplierProductModel(
      id: _toInt(json['id']),
      sourceProductId: json['source_product_id'] == null
          ? null
          : _toInt(json['source_product_id']),
      name: json['name'] as String? ?? '',
      price: _toDouble(json['price']),
      isAvailable: _toBool(json['is_available'], fallback: true),
      imageUrl: json['image_url'] as String? ?? '',
      stockQuantity: _toInt(json['stock_quantity']),
    );
  }
}

class SupplierProfileModel {
  const SupplierProfileModel({
    required this.id,
    required this.userId,
    required this.businessName,
    required this.description,
    required this.phone,
    required this.isActive,
    required this.businessDomain,
    this.latitude,
    this.longitude,
    required this.commune,
    required this.quarter,
    required this.avenue,
    required this.profileImageUrl,
    required this.coverImageUrl,
    required this.supportWhatsapp,
    this.distanceKm,
    required this.products,
  });

  final int id;
  final int userId;
  final String businessName;
  final String description;
  final String phone;
  final bool isActive;
  final String businessDomain;
  final double? latitude;
  final double? longitude;
  final String commune;
  final String quarter;
  final String avenue;
  final String profileImageUrl;
  final String coverImageUrl;
  final String supportWhatsapp;
  final double? distanceKm;
  final List<SupplierProductModel> products;

  factory SupplierProfileModel.fromJson(Map<String, dynamic> json) {
    final productRows = (json['products'] as List<dynamic>? ?? [])
        .map(
          (e) => SupplierProductModel.fromJson(
            Map<String, dynamic>.from(e as Map),
          ),
        )
        .toList();

    final rawLat = json['latitude'];
    final rawLng = json['longitude'];
    final rawDistance = json['distance_km'];
    return SupplierProfileModel(
      id: _toInt(json['id']),
      userId: _toInt(json['user_id']),
      businessName: json['business_name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      isActive: _toBool(json['is_active'], fallback: false),
      businessDomain: json['business_domain'] as String? ?? 'other',
      latitude: rawLat == null ? null : _toDouble(rawLat),
      longitude: rawLng == null ? null : _toDouble(rawLng),
      commune: json['commune'] as String? ?? '',
      quarter: json['quarter'] as String? ?? '',
      avenue: json['avenue'] as String? ?? '',
      profileImageUrl: json['profile_image_url'] as String? ?? '',
      coverImageUrl: json['cover_image_url'] as String? ?? '',
      supportWhatsapp: json['support_whatsapp'] as String? ?? '',
      distanceKm: rawDistance == null ? null : _toDouble(rawDistance),
      products: productRows,
    );
  }
}

class SupplierConversationModel {
  const SupplierConversationModel({
    required this.id,
    required this.supplierId,
    required this.supplierName,
    required this.supplierPhone,
    required this.supplierImageUrl,
    required this.lastMessagePreview,
  });

  final int id;
  final int supplierId;
  final String supplierName;
  final String supplierPhone;
  final String supplierImageUrl;
  final String lastMessagePreview;

  factory SupplierConversationModel.fromJson(Map<String, dynamic> json) {
    return SupplierConversationModel(
      id: _toInt(json['id']),
      supplierId: _toInt(json['supplier']),
      supplierName: json['supplier_name'] as String? ?? '',
      supplierPhone: json['supplier_phone'] as String? ?? '',
      supplierImageUrl: json['supplier_image_url'] as String? ?? '',
      lastMessagePreview: json['last_message_preview'] as String? ?? '',
    );
  }
}

class SupplierMessageModel {
  const SupplierMessageModel({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.senderCompany,
    required this.messageType,
    required this.content,
    required this.voiceUrl,
    required this.createdAt,
  });

  final int id;
  final int senderId;
  final String senderName;
  final String senderCompany;
  final String messageType;
  final String content;
  final String voiceUrl;
  final String createdAt;

  factory SupplierMessageModel.fromJson(Map<String, dynamic> json) {
    final senderName =
        (json['sender_name'] as String? ??
                json['sender_full_name'] as String? ??
                json['sender_display_name'] as String? ??
                '')
            .trim();
    final senderCompany =
        (json['sender_company'] as String? ??
                json['sender_company_name'] as String? ??
                json['sender_business_name'] as String? ??
                '')
            .trim();
    return SupplierMessageModel(
      id: _toInt(json['id']),
      senderId: _toInt(json['sender_id']),
      senderName: senderName,
      senderCompany: senderCompany,
      messageType: json['message_type'] as String? ?? 'text',
      content: json['content'] as String? ?? '',
      voiceUrl: json['voice_url'] as String? ?? '',
      createdAt: json['created_at'] as String? ?? '',
    );
  }
}

class SupplierOrderItemModel {
  const SupplierOrderItemModel({
    required this.id,
    required this.supplierProductId,
    required this.productName,
    required this.unitPrice,
    required this.quantity,
    required this.lineTotal,
  });

  final int id;
  final int supplierProductId;
  final String productName;
  final double unitPrice;
  final int quantity;
  final double lineTotal;

  factory SupplierOrderItemModel.fromJson(Map<String, dynamic> json) {
    return SupplierOrderItemModel(
      id: _toInt(json['id']),
      supplierProductId: _toInt(json['supplier_product_id']),
      productName: json['product_name'] as String? ?? '',
      unitPrice: _toDouble(json['unit_price']),
      quantity: _toInt(json['quantity']),
      lineTotal: _toDouble(json['line_total']),
    );
  }
}

class SupplierOrderModel {
  const SupplierOrderModel({
    required this.id,
    required this.merchantId,
    required this.supplierId,
    required this.supplierName,
    required this.supplierPhone,
    required this.status,
    required this.notes,
    required this.deliveryCommune,
    required this.totalAmount,
    required this.items,
    required this.createdAt,
  });

  final int id;
  final int merchantId;
  final int supplierId;
  final String supplierName;
  final String supplierPhone;
  final String status;
  final String notes;
  final String deliveryCommune;
  final double totalAmount;
  final List<SupplierOrderItemModel> items;
  final String createdAt;

  factory SupplierOrderModel.fromJson(Map<String, dynamic> json) {
    final rows = (json['items'] as List<dynamic>? ?? [])
        .map(
          (e) => SupplierOrderItemModel.fromJson(
            Map<String, dynamic>.from(e as Map),
          ),
        )
        .toList();
    return SupplierOrderModel(
      id: _toInt(json['id']),
      merchantId: _toInt(json['merchant_id']),
      supplierId: _toInt(json['supplier_id']),
      supplierName: json['supplier_name'] as String? ?? '',
      supplierPhone: json['supplier_phone'] as String? ?? '',
      status: json['status'] as String? ?? 'pending',
      notes: json['notes'] as String? ?? '',
      deliveryCommune: json['delivery_commune'] as String? ?? '',
      totalAmount: _toDouble(json['total_amount']),
      items: rows,
      createdAt: json['created_at'] as String? ?? '',
    );
  }
}

class SupplierOrderItemInput {
  const SupplierOrderItemInput({
    required this.supplierProductId,
    required this.quantity,
  });

  final int supplierProductId;
  final int quantity;

  Map<String, dynamic> toJson() {
    return {'supplier_product_id': supplierProductId, 'quantity': quantity};
  }
}

class WeeklyRevenuePointModel {
  const WeeklyRevenuePointModel({required this.date, required this.revenue});

  final String date;
  final double revenue;

  factory WeeklyRevenuePointModel.fromJson(Map<String, dynamic> json) {
    return WeeklyRevenuePointModel(
      date: json['date'] as String? ?? '',
      revenue: _toDouble(json['revenue']),
    );
  }
}

class TopProductInsightModel {
  const TopProductInsightModel({
    required this.name,
    required this.qty,
    required this.revenue,
  });

  final String name;
  final int qty;
  final double revenue;

  factory TopProductInsightModel.fromJson(Map<String, dynamic> json) {
    return TopProductInsightModel(
      name: json['name'] as String? ?? '',
      qty: _toInt(json['qty']),
      revenue: _toDouble(json['revenue']),
    );
  }
}

class DecisionInsightModel {
  const DecisionInsightModel({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  factory DecisionInsightModel.fromJson(Map<String, dynamic> json) {
    return DecisionInsightModel(
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String? ?? '',
    );
  }
}

class CommerceInsightsModel {
  const CommerceInsightsModel({
    required this.weeklyRevenue,
    required this.topProducts,
    required this.decisions,
  });

  final List<WeeklyRevenuePointModel> weeklyRevenue;
  final List<TopProductInsightModel> topProducts;
  final List<DecisionInsightModel> decisions;

  factory CommerceInsightsModel.fromJson(Map<String, dynamic> json) {
    final weekly = (json['weekly_revenue'] as List<dynamic>? ?? [])
        .map(
          (e) => WeeklyRevenuePointModel.fromJson(
            Map<String, dynamic>.from(e as Map),
          ),
        )
        .toList();
    final top = (json['top_products'] as List<dynamic>? ?? [])
        .map(
          (e) => TopProductInsightModel.fromJson(
            Map<String, dynamic>.from(e as Map),
          ),
        )
        .toList();
    final decisions = (json['decisions'] as List<dynamic>? ?? [])
        .map(
          (e) => DecisionInsightModel.fromJson(
            Map<String, dynamic>.from(e as Map),
          ),
        )
        .toList();
    return CommerceInsightsModel(
      weeklyRevenue: weekly,
      topProducts: top,
      decisions: decisions,
    );
  }
}

class QuickSaleHistoryItemModel {
  const QuickSaleHistoryItemModel({
    required this.id,
    required this.date,
    required this.time,
    required this.customerName,
    required this.paymentMethod,
    required this.itemsCount,
    required this.subtotal,
    required this.discountAmount,
    required this.total,
    this.status = 'completed',
    this.cancelReason,
    this.canceledAt,
  });

  final int id;
  final String date;
  final String time;
  final String customerName;
  final String paymentMethod;
  final int itemsCount;
  final double subtotal;
  final double discountAmount;
  final double total;
  final String status;
  final String? cancelReason;
  final String? canceledAt;

  factory QuickSaleHistoryItemModel.fromJson(Map<String, dynamic> json) {
    return QuickSaleHistoryItemModel(
      id: _toInt(json['id']),
      date: json['date'] as String? ?? '',
      time: json['time'] as String? ?? '',
      customerName: json['customer_name'] as String? ?? '',
      paymentMethod: json['payment_method'] as String? ?? '',
      itemsCount: _toInt(json['items_count']),
      subtotal: _toDouble(json['subtotal']),
      discountAmount: _toDouble(json['discount_amount']),
      total: _toDouble(json['total']),
      status: json['status'] as String? ?? 'completed',
      cancelReason:
          json['cancel_reason'] as String? ??
          json['cancellation_reason'] as String?,
      canceledAt:
          json['canceled_at'] as String? ?? json['cancelled_at'] as String?,
    );
  }
}

class QuickSaleReceiptItemModel {
  const QuickSaleReceiptItemModel({
    required this.id,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.lineTotal,
  });

  final int id;
  final int productId;
  final String productName;
  final int quantity;
  final double unitPrice;
  final double lineTotal;

  factory QuickSaleReceiptItemModel.fromJson(Map<String, dynamic> json) {
    return QuickSaleReceiptItemModel(
      id: _toInt(json['id']),
      productId: _toInt(json['product']),
      productName: json['product_name'] as String? ?? '',
      quantity: _toInt(json['quantity']),
      unitPrice: _toDouble(json['unit_price']),
      lineTotal: _toDouble(json['line_total']),
    );
  }
}

class QuickSaleReceiptModel {
  const QuickSaleReceiptModel({
    required this.id,
    required this.subtotal,
    required this.discountAmount,
    required this.total,
    required this.paymentMethod,
    required this.status,
    required this.createdAt,
    required this.items,
    this.customerName = '',
    this.cancelReason,
    this.canceledAt,
  });

  final int id;
  final double subtotal;
  final double discountAmount;
  final double total;
  final String paymentMethod;
  final String status;
  final String createdAt;
  final List<QuickSaleReceiptItemModel> items;
  final String customerName;
  final String? cancelReason;
  final String? canceledAt;

  factory QuickSaleReceiptModel.fromJson(Map<String, dynamic> json) {
    final rows = (json['items'] as List<dynamic>? ?? [])
        .map(
          (e) => QuickSaleReceiptItemModel.fromJson(
            Map<String, dynamic>.from(e as Map),
          ),
        )
        .toList();
    return QuickSaleReceiptModel(
      id: _toInt(json['id']),
      subtotal: _toDouble(json['subtotal']),
      discountAmount: _toDouble(json['discount_amount']),
      total: _toDouble(json['total']),
      paymentMethod: json['payment_method'] as String? ?? 'cash',
      status: json['status'] as String? ?? 'completed',
      createdAt: json['created_at'] as String? ?? '',
      items: rows,
      customerName: json['customer_name'] as String? ?? '',
      cancelReason:
          json['cancel_reason'] as String? ??
          json['cancellation_reason'] as String?,
      canceledAt:
          json['canceled_at'] as String? ?? json['cancelled_at'] as String?,
    );
  }
}

class ReceiptVerificationModel {
  const ReceiptVerificationModel({
    required this.valid,
    required this.detail,
    this.reference,
    this.customerName,
    this.receipt,
    this.verifiedAt,
  });

  final bool valid;
  final String detail;
  final String? reference;
  final String? customerName;
  final QuickSaleReceiptModel? receipt;
  final String? verifiedAt;

  factory ReceiptVerificationModel.fromJson(Map<String, dynamic> json) {
    final receiptJson = json['receipt'];
    final receiptMap = receiptJson is Map
        ? Map<String, dynamic>.from(receiptJson)
        : null;
    return ReceiptVerificationModel(
      valid: json['valid'] as bool? ?? false,
      detail: json['detail'] as String? ?? '',
      reference:
          receiptMap?['reference'] as String? ?? json['reference'] as String?,
      customerName:
          receiptMap?['customer_name'] as String? ??
          json['customer_name'] as String?,
      receipt: receiptMap != null
          ? QuickSaleReceiptModel.fromJson(receiptMap)
          : null,
      verifiedAt:
          receiptMap?['verified_at'] as String? ??
          json['verified_at'] as String?,
    );
  }
}

class AiSaleDraftItemModel {
  const AiSaleDraftItemModel({
    required this.productId,
    required this.name,
    required this.sku,
    required this.quantity,
    required this.unitPrice,
    required this.lineTotal,
    required this.stockQuantity,
  });

  final int productId;
  final String name;
  final String sku;
  final int quantity;
  final double unitPrice;
  final double lineTotal;
  final int stockQuantity;

  factory AiSaleDraftItemModel.fromJson(Map<String, dynamic> json) {
    return AiSaleDraftItemModel(
      productId: _toInt(json['product_id']),
      name: json['name'] as String? ?? '',
      sku: json['sku'] as String? ?? '',
      quantity: _toInt(json['quantity']),
      unitPrice: _toDouble(json['unit_price']),
      lineTotal: _toDouble(json['line_total']),
      stockQuantity: _toInt(json['stock_quantity']),
    );
  }
}

class AiSaleUnmatchedModel {
  const AiSaleUnmatchedModel({required this.text, required this.quantity});

  final String text;
  final int quantity;

  factory AiSaleUnmatchedModel.fromJson(Map<String, dynamic> json) {
    return AiSaleUnmatchedModel(
      text: json['text'] as String? ?? '',
      quantity: _toInt(json['quantity'], fallback: 1),
    );
  }
}

class AiSaleDraftModel {
  const AiSaleDraftModel({
    required this.prompt,
    required this.items,
    required this.unmatched,
    required this.warnings,
    required this.paymentMethod,
    required this.customerName,
    required this.total,
  });

  final String prompt;
  final List<AiSaleDraftItemModel> items;
  final List<AiSaleUnmatchedModel> unmatched;
  final List<String> warnings;
  final String paymentMethod;
  final String customerName;
  final double total;

  factory AiSaleDraftModel.fromJson(Map<String, dynamic> json) {
    return AiSaleDraftModel(
      prompt: json['prompt'] as String? ?? '',
      items: (json['items'] as List<dynamic>? ?? [])
          .map(
            (e) => AiSaleDraftItemModel.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList(),
      unmatched: (json['unmatched'] as List<dynamic>? ?? [])
          .map(
            (e) => AiSaleUnmatchedModel.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList(),
      warnings: (json['warnings'] as List<dynamic>? ?? [])
          .map((e) => '$e')
          .toList(),
      paymentMethod: json['payment_method'] as String? ?? 'cash',
      customerName: json['customer_name'] as String? ?? '',
      total: _toDouble(json['total']),
    );
  }
}
