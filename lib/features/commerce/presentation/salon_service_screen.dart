library;

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/offline/tenant_context.dart';
import '../../../data/datasources/salon_local_datasource.dart';
import '../../../data/models/salon_models.dart';

class SalonServiceScreen extends StatefulWidget {
  const SalonServiceScreen({super.key});

  @override
  State<SalonServiceScreen> createState() => _SalonServiceScreenState();
}

class _SalonServiceScreenState extends State<SalonServiceScreen> {
  static const _primary = Color(0xFF035D8A);
  static const _softBlue = Color(0xFFE9EFF3);
  final SalonLocalDataSource _source = SalonLocalDataSource();
  final ImagePicker _imagePicker = ImagePicker();
  final TextEditingController _clientController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  String _paymentMethod = 'cash';

  bool _loading = true;
  bool _submitting = false;
  SalonTodayStats? _stats;
  List<SalonServiceModel> _services = const [];
  List<SalonStylistModel> _stylists = const [];
  List<SalonStaffUserModel> _staffUsers = const [];
  List<SalonSaleModel> _recentSales = const [];
  final Set<String> _selectedServiceIds = <String>{};
  SalonStylistModel? _selectedStylist;
  String _search = '';

  static const _categoryOrder = <String>[
    'beaute',
    'coiffure',
    'onglerie',
    'maquillage',
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _clientController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final tenant = TenantContext.current();
    if (tenant == null) {
      if (!mounted) return;
      setState(() => _loading = false);
      return;
    }
    await _source.ensureSeeded(tenant.tenantId);
    final services = await _source.getServices(tenant.tenantId);
    final stylists = await _source.getStylists(tenant.tenantId);
    final staffUsers = await _source.getStaffUsers(tenant.tenantId);
    final stats = await _source.getTodayStats(tenant.tenantId);
    final recent = await _source.listRecentSales(tenant.tenantId, limit: 8);
    if (!mounted) return;
    setState(() {
      _services = services;
      _stylists = stylists;
      _staffUsers = staffUsers;
      _selectedServiceIds.removeWhere(
        (id) => !services.any((service) => service.id == id),
      );
      _selectedStylist =
          _selectedStylist ?? (stylists.isNotEmpty ? stylists.first : null);
      _stats = stats;
      _recentSales = recent;
      _loading = false;
    });
  }

  Future<void> _openAddServiceSheet() async {
    final tenant = TenantContext.current();
    if (tenant == null) return;
    final codeCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final descriptionCtrl = TextEditingController();
    final imageCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final durationCtrl = TextEditingController();
    String category = 'coiffure';
    bool isPopular = false;
    bool active = true;
    bool saving = false;
    String imageDataUrl = '';

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 8,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Nouvelle prestation',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: codeCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Code prestation *',
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Nom prestation *',
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: category,
                      decoration: const InputDecoration(
                        labelText: 'Categorie *',
                      ),
                      items: _categoryOrder
                          .map(
                            (c) => DropdownMenuItem(
                              value: c,
                              child: Text(_categoryLabel(c)),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setModalState(() => category = value);
                      },
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: descriptionCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: imageCtrl,
                      decoration: const InputDecoration(
                        labelText: 'URL image (optionnel)',
                        hintText: 'https://...',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: saving
                                ? null
                                : () async {
                                    final picked = await _pickImageAsDataUrl(
                                      ImageSource.gallery,
                                    );
                                    if (picked == null || !context.mounted)
                                      return;
                                    setModalState(() {
                                      imageDataUrl = picked;
                                      imageCtrl.text = '';
                                    });
                                  },
                            icon: const Icon(Icons.photo_library_outlined),
                            label: const Text('Galerie'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: saving
                                ? null
                                : () async {
                                    final picked = await _pickImageAsDataUrl(
                                      ImageSource.camera,
                                    );
                                    if (picked == null || !context.mounted)
                                      return;
                                    setModalState(() {
                                      imageDataUrl = picked;
                                      imageCtrl.text = '';
                                    });
                                  },
                            icon: const Icon(Icons.photo_camera_outlined),
                            label: Text(kIsWeb ? 'Camera*' : 'Camera'),
                          ),
                        ),
                      ],
                    ),
                    if (imageDataUrl.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      if (_decodeDataUrl(imageDataUrl) case final bytes?)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: Image.memory(
                            bytes,
                            height: 120,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: priceCtrl,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Prix (CDF) *',
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: durationCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Duree (min) *',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Prestation populaire'),
                      value: isPopular,
                      onChanged: (value) =>
                          setModalState(() => isPopular = value),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Prestation active'),
                      value: active,
                      onChanged: (value) => setModalState(() => active = value),
                    ),
                    const SizedBox(height: 8),
                    FilledButton(
                      onPressed: saving
                          ? null
                          : () async {
                              final code = codeCtrl.text.trim();
                              final name = nameCtrl.text.trim();
                              final description = descriptionCtrl.text.trim();
                              final price = double.tryParse(
                                priceCtrl.text.trim(),
                              );
                              final duration = int.tryParse(
                                durationCtrl.text.trim(),
                              );
                              if (code.isEmpty ||
                                  name.isEmpty ||
                                  price == null ||
                                  duration == null ||
                                  duration <= 0) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Renseigne les champs obligatoires correctement.',
                                    ),
                                  ),
                                );
                                return;
                              }
                              setModalState(() => saving = true);
                              await _source.addService(
                                tenantId: tenant.tenantId,
                                code: code,
                                name: name,
                                category: category,
                                description: description,
                                imageUrl: imageDataUrl.isNotEmpty
                                    ? imageDataUrl
                                    : imageCtrl.text.trim(),
                                price: price,
                                durationMinutes: duration,
                                isPopular: isPopular,
                                active: active,
                              );
                              if (!context.mounted) return;
                              Navigator.of(context).pop();
                              await _load();
                            },
                      child: saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Enregistrer prestation'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<String?> _pickImageAsDataUrl(ImageSource source) async {
    try {
      final xFile = await _imagePicker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1280,
      );
      if (xFile == null) return null;
      final bytes = await xFile.readAsBytes();
      final mime = _guessMimeType(xFile.name);
      return 'data:$mime;base64,${base64Encode(bytes)}';
    } catch (_) {
      return null;
    }
  }

  String _guessMimeType(String fileName) {
    final name = fileName.toLowerCase();
    if (name.endsWith('.png')) return 'image/png';
    if (name.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }

  Uint8List? _decodeDataUrl(String dataUrl) {
    final idx = dataUrl.indexOf(',');
    if (!dataUrl.startsWith('data:') || idx <= 0) return null;
    try {
      final payload = dataUrl.substring(idx + 1);
      return base64Decode(payload);
    } catch (_) {
      return null;
    }
  }

  Future<void> _openAddStaffSheet() async {
    final tenant = TenantContext.current();
    if (tenant == null) return;
    final fullNameCtrl = TextEditingController();
    final usernameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final pinCtrl = TextEditingController();
    String role = 'coiffeur';
    bool saving = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 8,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Creer utilisateur salon',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: fullNameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Nom complet *',
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: usernameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Nom utilisateur *',
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Telephone *',
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: role,
                      decoration: const InputDecoration(labelText: 'Role *'),
                      items: const [
                        DropdownMenuItem(
                          value: 'coiffeur',
                          child: Text('Coiffeur'),
                        ),
                        DropdownMenuItem(
                          value: 'caissier',
                          child: Text('Caissier'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setModalState(() => role = value);
                      },
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: pinCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Code PIN (optionnel)',
                      ),
                    ),
                    const SizedBox(height: 10),
                    FilledButton(
                      onPressed: saving
                          ? null
                          : () async {
                              final fullName = fullNameCtrl.text.trim();
                              final username = usernameCtrl.text.trim();
                              final phone = phoneCtrl.text.trim();
                              if (fullName.isEmpty ||
                                  username.isEmpty ||
                                  phone.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Nom, username et telephone sont obligatoires.',
                                    ),
                                  ),
                                );
                                return;
                              }
                              setModalState(() => saving = true);
                              await _source.createStaffUser(
                                tenantId: tenant.tenantId,
                                fullName: fullName,
                                username: username,
                                phone: phone,
                                role: role,
                                pinCode: pinCtrl.text.trim(),
                              );
                              if (!context.mounted) return;
                              Navigator.of(context).pop();
                              await _load();
                            },
                      child: saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Creer utilisateur'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _submit() async {
    final tenant = TenantContext.current();
    final stylist = _selectedStylist;
    final selectedServices = _services
        .where((service) => _selectedServiceIds.contains(service.id))
        .toList();
    if (tenant == null ||
        selectedServices.isEmpty ||
        stylist == null ||
        _submitting) {
      return;
    }
    setState(() => _submitting = true);
    double total = 0;
    for (final service in selectedServices) {
      await _source.recordSale(
        tenantId: tenant.tenantId,
        service: service,
        stylist: stylist,
        paymentMethod: _paymentMethod,
        clientName: _clientController.text.trim(),
      );
      total += service.price;
    }
    _clientController.clear();
    _selectedServiceIds.clear();
    await _load();
    if (!mounted) return;
    setState(() => _submitting = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${selectedServices.length} prestation(s) enregistree(s) - ${total.toStringAsFixed(0)} CDF',
        ),
      ),
    );
  }

  String _categoryLabel(String category) {
    switch (category) {
      case 'beaute':
        return 'Beauté';
      case 'coiffure':
        return 'Coiffure';
      case 'onglerie':
        return 'Onglerie';
      case 'maquillage':
        return 'Maquillage';
      default:
        return category;
    }
  }

  IconData _categoryIcon(String category) {
    switch (category) {
      case 'beaute':
        return Icons.spa_outlined;
      case 'coiffure':
        return Icons.content_cut_rounded;
      case 'onglerie':
        return Icons.back_hand_outlined;
      case 'maquillage':
        return Icons.brush_outlined;
      default:
        return Icons.style_outlined;
    }
  }

  List<SalonServiceModel> _servicesForCategory(String category) {
    final q = _search.trim().toLowerCase();
    return _services.where((service) {
      final byCategory = service.category.toLowerCase() == category;
      if (!byCategory) return false;
      if (q.isEmpty) return true;
      return service.name.toLowerCase().contains(q) ||
          service.code.toLowerCase().contains(q) ||
          _categoryLabel(service.category).toLowerCase().contains(q);
    }).toList();
  }

  void _toggleService(SalonServiceModel service) {
    setState(() {
      if (_selectedServiceIds.contains(service.id)) {
        _selectedServiceIds.remove(service.id);
      } else {
        _selectedServiceIds.add(service.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final stats = _stats;
    final selectedServices = _services
        .where((service) => _selectedServiceIds.contains(service.id))
        .toList();
    final selectedTotal = selectedServices.fold<double>(
      0,
      (sum, service) => sum + service.price,
    );
    return Scaffold(
      appBar: AppBar(
        title: const Text('Salon - Services'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'service') {
                await _openAddServiceSheet();
              } else if (value == 'staff') {
                await _openAddStaffSheet();
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'service',
                child: Text('Ajouter prestation'),
              ),
              PopupMenuItem(
                value: 'staff',
                child: Text('Creer coiffeur / caissier'),
              ),
            ],
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _StatsHeader(stats: stats),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _searchController,
                    onChanged: (value) => setState(() => _search = value),
                    decoration: const InputDecoration(
                      hintText: 'Rechercher un service ou une categorie',
                      prefixIcon: Icon(Icons.search_rounded),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    '1) Choisir la prestation',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  ..._categoryOrder.map((category) {
                    final rows = _servicesForCategory(category);
                    if (rows.isEmpty && _search.isNotEmpty) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: _CategoryCarousel(
                        title: _categoryLabel(category),
                        icon: _categoryIcon(category),
                        services: rows,
                        selectedServiceIds: _selectedServiceIds,
                        onTap: _toggleService,
                      ),
                    );
                  }),
                  if (selectedServices.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _softBlue,
                        borderRadius: BorderRadius.circular(3),
                        border: Border.all(
                          color: _primary.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Text(
                        '${selectedServices.length} service(s) selectionne(s) • Total ${selectedTotal.toStringAsFixed(0)} CDF',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  Text(
                    '2) Choisir le coiffeur',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedStylist?.id,
                    decoration: const InputDecoration(
                      labelText: 'Coiffeur',
                      prefixIcon: Icon(Icons.person_outline_rounded),
                    ),
                    items: _stylists
                        .map(
                          (stylist) => DropdownMenuItem<String>(
                            value: stylist.id,
                            child: Text(stylist.fullName),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      final selected = _stylists
                          .where((e) => e.id == value)
                          .toList();
                      if (selected.isEmpty) return;
                      setState(() => _selectedStylist = selected.first);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _clientController,
                    decoration: const InputDecoration(
                      labelText: 'Client (optionnel)',
                      hintText: 'Nom du client',
                      prefixIcon: Icon(Icons.badge_outlined),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    '3) Paiement',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('Cash'),
                        selected: _paymentMethod == 'cash',
                        onSelected: (_) =>
                            setState(() => _paymentMethod = 'cash'),
                      ),
                      ChoiceChip(
                        label: const Text('Mobile Money'),
                        selected: _paymentMethod == 'mobile_money',
                        onSelected: (_) =>
                            setState(() => _paymentMethod = 'mobile_money'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  FilledButton.icon(
                    onPressed: _submitting ? null : _submit,
                    icon: _submitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check_circle_outline_rounded),
                    label: Text(
                      selectedServices.isEmpty
                          ? 'Valider la prestation'
                          : 'Valider ${selectedServices.length} service(s) (${selectedTotal.toStringAsFixed(0)} CDF)',
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Equipe salon',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  if (_staffUsers.isEmpty)
                    const Text('Aucun utilisateur salon.')
                  else
                    ..._staffUsers.map(
                      (staff) => ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 0,
                        ),
                        leading: CircleAvatar(
                          child: Icon(
                            staff.role == 'coiffeur'
                                ? Icons.content_cut_rounded
                                : Icons.point_of_sale_rounded,
                          ),
                        ),
                        title: Text(staff.fullName),
                        subtitle: Text(
                          '${staff.role} • @${staff.username} • ${staff.phone}',
                        ),
                      ),
                    ),
                  const SizedBox(height: 18),
                  Text(
                    'Dernieres prestations',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  if (_recentSales.isEmpty)
                    const Text('Aucune prestation enregistree aujourd\'hui.')
                  else
                    ..._recentSales.map(
                      (sale) => ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 0,
                        ),
                        leading: const CircleAvatar(
                          child: Icon(Icons.content_cut_rounded),
                        ),
                        title: Text(
                          '${sale.serviceName} - ${sale.amount.toStringAsFixed(0)} CDF',
                        ),
                        subtitle: Text(
                          '${sale.stylistName} • ${sale.paymentMethod == 'cash' ? 'Cash' : 'Mobile Money'}'
                          '${sale.clientName.isEmpty ? '' : ' • ${sale.clientName}'}',
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}

class _CategoryCarousel extends StatelessWidget {
  const _CategoryCarousel({
    required this.title,
    required this.icon,
    required this.services,
    required this.selectedServiceIds,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final List<SalonServiceModel> services;
  final Set<String> selectedServiceIds;
  final ValueChanged<SalonServiceModel> onTap;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final cardWidth = width < 380 ? 205.0 : 235.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: const Color(0xFF035D8A)),
            const SizedBox(width: 6),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 188,
          child: services.isEmpty
              ? const Center(
                  child: Text(
                    'Aucun service dans cette categorie.',
                    style: TextStyle(color: Color(0xFF6B7280)),
                  ),
                )
              : ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: services.length,
                  separatorBuilder: (_, index) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final service = services[index];
                    final selected = selectedServiceIds.contains(service.id);
                    return _ServiceCard(
                      width: cardWidth,
                      service: service,
                      selected: selected,
                      onTap: () => onTap(service),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _ServiceCard extends StatelessWidget {
  const _ServiceCard({
    required this.width,
    required this.service,
    required this.selected,
    required this.onTap,
  });

  final double width;
  final SalonServiceModel service;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final borderColor = selected
        ? const Color(0xFF035D8A)
        : const Color(0xFFE5E7EB);
    return AnimatedScale(
      duration: const Duration(milliseconds: 180),
      scale: selected ? 1.0 : 0.985,
      child: InkWell(
        borderRadius: BorderRadius.circular(3),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          width: width,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: borderColor, width: selected ? 1.6 : 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFF4F8FB), Color(0xFFE9EFF3)],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 112,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: _buildImage(service.imageUrl),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                service.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                service.code,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(
                  fontSize: 10.5,
                  color: const Color(0xFF024A6E),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '${service.price.toStringAsFixed(0)} CDF • ${service.durationMinutes} min',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: 11,
                  color: const Color(0xFF4B5563),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImage(String source) {
    if (source.isEmpty) {
      return _fallbackImage();
    }
    if (source.startsWith('data:image')) {
      final idx = source.indexOf(',');
      if (idx <= 0) return _fallbackImage();
      try {
        final bytes = base64Decode(source.substring(idx + 1));
        return Image.memory(
          bytes,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _fallbackImage(),
        );
      } catch (_) {
        return _fallbackImage();
      }
    }
    return Image.network(
      source,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => _fallbackImage(),
    );
  }

  Widget _fallbackImage() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF2B7AA3), Color(0xFF035D8A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 32),
      ),
    );
  }
}

class _StatsHeader extends StatelessWidget {
  const _StatsHeader({required this.stats});

  final SalonTodayStats? stats;

  @override
  Widget build(BuildContext context) {
    final data = stats;
    final revenue = data?.totalRevenue ?? 0;
    final count = data?.totalSales ?? 0;
    final avg = data?.averageTicket ?? 0;
    final topStylist = data?.topStylist ?? '—';
    final topRevenue = data?.topStylistRevenue ?? 0;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFE9EFF3),
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: const Color(0x33035D8A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Gain du jour: ${revenue.toStringAsFixed(0)} CDF',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: const Color(0xFF024A6E),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Prestations: $count • Ticket moyen: ${avg.toStringAsFixed(0)} CDF',
          ),
          const SizedBox(height: 2),
          Text(
            'Top coiffeur: $topStylist (${topRevenue.toStringAsFixed(0)} CDF)',
          ),
        ],
      ),
    );
  }
}
