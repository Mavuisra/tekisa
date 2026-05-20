library;

import 'package:flutter/material.dart';

class BusinessCategoryProfile {
  const BusinessCategoryProfile({
    required this.key,
    required this.label,
    required this.subtitle,
    required this.headerMetricLabel,
    required this.topPerformerLabel,
    required this.quickSaleTitle,
    required this.inventoryTitle,
    required this.customersTitle,
    required this.customerNounPlural,
    required this.customerNounSingular,
    required this.searchItemHint,
    required this.createItemLabel,
    required this.itemLabelPlural,
    required this.itemLabelSingular,
    required this.primaryGradient,
    required this.accentColor,
    required this.softColor,
    required this.heroIcon,
  });

  final String key;
  final String label;
  final String subtitle;
  final String headerMetricLabel;
  final String topPerformerLabel;
  final String quickSaleTitle;
  final String inventoryTitle;
  final String customersTitle;
  final String customerNounPlural;
  final String customerNounSingular;
  final String searchItemHint;
  final String createItemLabel;
  final String itemLabelPlural;
  final String itemLabelSingular;
  final List<Color> primaryGradient;
  final Color accentColor;
  final Color softColor;
  final IconData heroIcon;
}

class BusinessCategoryProfiles {
  static const _base = Color(0xFF035D8A);
  static const _baseDark = Color(0xFF024A6E);
  static const _softTint = Color(0xFFF1F5F8);

  static const restaurant = BusinessCategoryProfile(
    key: 'restaurant',
    label: 'Restaurant',
    subtitle: 'Service, commandes et rotation des plats',
    headerMetricLabel: 'CA salle & livraison',
    topPerformerLabel: 'Plat vedette',
    quickSaleTitle: 'Commande rapide',
    inventoryTitle: 'Stock cuisine',
    customersTitle: 'Clients & fidelisation',
    customerNounPlural: 'clients',
    customerNounSingular: 'client',
    searchItemHint: 'Rechercher un plat...',
    createItemLabel: 'Nouveau plat',
    itemLabelPlural: 'plats',
    itemLabelSingular: 'plat',
    primaryGradient: [_baseDark, _base],
    accentColor: _base,
    softColor: _softTint,
    heroIcon: Icons.restaurant_menu_rounded,
  );

  static const boutique = BusinessCategoryProfile(
    key: 'boutique',
    label: 'Boutique',
    subtitle: 'Pilotage des ventes et du stock magasin',
    headerMetricLabel: 'CA du jour',
    topPerformerLabel: 'Produit star',
    quickSaleTitle: 'Vente rapide',
    inventoryTitle: 'Stock intelligent',
    customersTitle: 'Clients & fidelisation',
    customerNounPlural: 'clients',
    customerNounSingular: 'client',
    searchItemHint: 'Rechercher un produit...',
    createItemLabel: 'Nouveau produit',
    itemLabelPlural: 'produits',
    itemLabelSingular: 'produit',
    primaryGradient: [_baseDark, _base],
    accentColor: _base,
    softColor: _softTint,
    heroIcon: Icons.storefront_rounded,
  );

  static const pharmacie = BusinessCategoryProfile(
    key: 'pharmacie',
    label: 'Pharmacie',
    subtitle: 'Suivi des ventes et des niveaux de médicaments',
    headerMetricLabel: 'CA officine',
    topPerformerLabel: 'Médicament star',
    quickSaleTitle: 'Dispensation rapide',
    inventoryTitle: 'Stock officine',
    customersTitle: 'Patients & fidelisation',
    customerNounPlural: 'patients',
    customerNounSingular: 'patient',
    searchItemHint: 'Rechercher un medicament...',
    createItemLabel: 'Nouveau medicament',
    itemLabelPlural: 'médicaments',
    itemLabelSingular: 'medicament',
    primaryGradient: [_baseDark, _base],
    accentColor: _base,
    softColor: _softTint,
    heroIcon: Icons.local_pharmacy_rounded,
  );

  static const salonCoiffure = BusinessCategoryProfile(
    key: 'salon_coiffure',
    label: 'Salon de coiffure',
    subtitle: 'Rendez-vous, prestations et ventes produits beaute',
    headerMetricLabel: 'CA prestations & produits',
    topPerformerLabel: 'Prestation vedette',
    quickSaleTitle: 'Encaissement rapide',
    inventoryTitle: 'Stock beaute',
    customersTitle: 'Clients & fidelisation',
    customerNounPlural: 'clients',
    customerNounSingular: 'client',
    searchItemHint: 'Rechercher une prestation ou un produit...',
    createItemLabel: 'Nouvelle prestation',
    itemLabelPlural: 'prestations',
    itemLabelSingular: 'prestation',
    primaryGradient: [_baseDark, _base],
    accentColor: _base,
    softColor: _softTint,
    heroIcon: Icons.content_cut_rounded,
  );

  static BusinessCategoryProfile fromKey(String? key) {
    switch ((key ?? '').toLowerCase()) {
      case 'restaurant':
        return restaurant;
      case 'pharmacie':
        return pharmacie;
      case 'salon':
      case 'salon_coiffure':
      case 'coiffure':
        return salonCoiffure;
      case 'boutique':
      default:
        return boutique;
    }
  }

  static const all = <BusinessCategoryProfile>[
    restaurant,
    boutique,
    pharmacie,
    salonCoiffure,
  ];
}
