library;

import 'business_category_profile.dart';

class DomainAttribute {
  const DomainAttribute({
    required this.name,
    required this.type,
    required this.required,
  });

  final String name;
  final String type;
  final bool required;
}

class DomainEntityBlueprint {
  const DomainEntityBlueprint({
    required this.entity,
    required this.description,
    required this.attributes,
  });

  final String entity;
  final String description;
  final List<DomainAttribute> attributes;
}

class DomainBlueprintCatalog {
  static const Map<String, List<DomainEntityBlueprint>> byCategory = {
    'restaurant': [
      DomainEntityBlueprint(
        entity: 'menu_item',
        description: 'Plat ou boisson vendue',
        attributes: [
          DomainAttribute(name: 'name', type: 'string', required: true),
          DomainAttribute(name: 'category', type: 'string', required: true),
          DomainAttribute(name: 'price', type: 'decimal', required: true),
          DomainAttribute(name: 'prep_time_min', type: 'int', required: false),
          DomainAttribute(name: 'is_available', type: 'bool', required: true),
        ],
      ),
      DomainEntityBlueprint(
        entity: 'restaurant_order',
        description: 'Commande client en salle/livraison',
        attributes: [
          DomainAttribute(name: 'order_number', type: 'string', required: true),
          DomainAttribute(name: 'service_type', type: 'string', required: true),
          DomainAttribute(name: 'table_ref', type: 'string', required: false),
          DomainAttribute(name: 'status', type: 'string', required: true),
          DomainAttribute(
            name: 'total_amount',
            type: 'decimal',
            required: true,
          ),
        ],
      ),
    ],
    'pharmacie': [
      DomainEntityBlueprint(
        entity: 'medicine',
        description: 'Produit medicamenteux avec suivi lot/expiration',
        attributes: [
          DomainAttribute(name: 'name', type: 'string', required: true),
          DomainAttribute(name: 'sku', type: 'string', required: true),
          DomainAttribute(name: 'dosage', type: 'string', required: false),
          DomainAttribute(name: 'expiry_date', type: 'date', required: false),
          DomainAttribute(
            name: 'requires_prescription',
            type: 'bool',
            required: true,
          ),
        ],
      ),
      DomainEntityBlueprint(
        entity: 'prescription_sale',
        description: 'Vente basee sur ordonnance',
        attributes: [
          DomainAttribute(name: 'patient_name', type: 'string', required: true),
          DomainAttribute(name: 'doctor_name', type: 'string', required: false),
          DomainAttribute(
            name: 'prescription_ref',
            type: 'string',
            required: false,
          ),
          DomainAttribute(
            name: 'total_amount',
            type: 'decimal',
            required: true,
          ),
          DomainAttribute(name: 'sold_at', type: 'datetime', required: true),
        ],
      ),
    ],
    'boutique': [
      DomainEntityBlueprint(
        entity: 'retail_product',
        description: 'Article de vente detail',
        attributes: [
          DomainAttribute(name: 'name', type: 'string', required: true),
          DomainAttribute(name: 'sku', type: 'string', required: true),
          DomainAttribute(name: 'unit_price', type: 'decimal', required: true),
          DomainAttribute(name: 'stock_qty', type: 'int', required: true),
          DomainAttribute(name: 'brand', type: 'string', required: false),
        ],
      ),
      DomainEntityBlueprint(
        entity: 'retail_sale',
        description: 'Transaction de caisse',
        attributes: [
          DomainAttribute(name: 'sale_ref', type: 'string', required: true),
          DomainAttribute(
            name: 'customer_name',
            type: 'string',
            required: false,
          ),
          DomainAttribute(
            name: 'payment_method',
            type: 'string',
            required: true,
          ),
          DomainAttribute(
            name: 'total_amount',
            type: 'decimal',
            required: true,
          ),
          DomainAttribute(name: 'sold_at', type: 'datetime', required: true),
        ],
      ),
    ],
    'salon_coiffure': [
      DomainEntityBlueprint(
        entity: 'service_catalog',
        description: 'Prestation coiffure/beaute',
        attributes: [
          DomainAttribute(name: 'name', type: 'string', required: true),
          DomainAttribute(name: 'duration_min', type: 'int', required: true),
          DomainAttribute(name: 'base_price', type: 'decimal', required: true),
          DomainAttribute(
            name: 'stylist_level',
            type: 'string',
            required: false,
          ),
          DomainAttribute(name: 'active', type: 'bool', required: true),
        ],
      ),
      DomainEntityBlueprint(
        entity: 'appointment',
        description: 'Rendez-vous client avec coiffeur',
        attributes: [
          DomainAttribute(name: 'client_name', type: 'string', required: true),
          DomainAttribute(
            name: 'stylist_name',
            type: 'string',
            required: false,
          ),
          DomainAttribute(name: 'start_at', type: 'datetime', required: true),
          DomainAttribute(name: 'status', type: 'string', required: true),
          DomainAttribute(
            name: 'estimated_total',
            type: 'decimal',
            required: false,
          ),
        ],
      ),
    ],
  };

  static List<DomainEntityBlueprint> forProfile(
    BusinessCategoryProfile profile,
  ) {
    return byCategory[profile.key] ?? const [];
  }
}
