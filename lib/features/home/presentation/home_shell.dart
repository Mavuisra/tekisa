library;

import 'dart:async';
import 'dart:ui';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:salomon_bottom_bar/salomon_bottom_bar.dart';

import '../../../core/business/business_category_profile.dart';
import '../../../core/offline/sync_orchestrator.dart';
import '../../../data/datasources/auth_local_datasource.dart';
import '../../commerce/presentation/commerce_dashboard_screen.dart';
import '../../commerce/presentation/cash_desk_screen.dart';
import '../../commerce/presentation/inventory_screen.dart';
import '../../commerce/presentation/quick_sale_screen.dart';
import '../../commerce/presentation/salon_service_screen.dart';
import '../../commerce/presentation/sales_journal_screen.dart';
import '../../commerce/presentation/supplier_network_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  final _authLocal = AuthLocalDataSource();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  Timer? _bannerTimer;
  int _index = 0;
  bool _wasOffline = false;
  String? _syncBannerMessage;
  Color _syncBannerColor = const Color(0xFF035D8A);

  @override
  void initState() {
    super.initState();
    _initConnectivityMonitor();
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _bannerTimer?.cancel();
    super.dispose();
  }

  Future<void> _initConnectivityMonitor() async {
    final initial = await Connectivity().checkConnectivity();
    _wasOffline = initial.every((r) => r == ConnectivityResult.none);
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      results,
    ) {
      _handleConnectivityChange(results);
    });
  }

  void _handleConnectivityChange(List<ConnectivityResult> results) {
    final isOnline = results.any((r) => r != ConnectivityResult.none);
    if (!isOnline) {
      _wasOffline = true;
      _showBanner(
        message: 'Mode hors ligne actif. Vos operations seront synchronisees.',
        color: const Color(0xFF92400E),
        autoHide: false,
      );
      return;
    }

    if (_wasOffline) {
      _wasOffline = false;
      _syncNowAfterReconnect();
    }
  }

  Future<void> _syncNowAfterReconnect() async {
    _showBanner(
      message: 'Connexion retablie. Synchronisation en cours...',
      color: const Color(0xFF035D8A),
      autoHide: false,
    );
    try {
      await SyncOrchestrator.instance.flushQueue();
      if (!mounted) return;
      _showBanner(
        message: 'Synchronisation effectuee avec succes.',
        color: const Color(0xFF047857),
      );
    } catch (_) {
      if (!mounted) return;
      _showBanner(
        message: 'Connexion retablie, synchronisation en attente.',
        color: const Color(0xFF92400E),
      );
    }
  }

  void _showBanner({
    required String message,
    required Color color,
    bool autoHide = true,
  }) {
    _bannerTimer?.cancel();
    if (!mounted) return;
    setState(() {
      _syncBannerMessage = message;
      _syncBannerColor = color;
    });
    if (!autoHide) return;
    _bannerTimer = Timer(const Duration(seconds: 4), () {
      if (!mounted) return;
      setState(() => _syncBannerMessage = null);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final user = _authLocal.getUser();
    final role = (user?.role ?? 'seller').toLowerCase();
    final profile = BusinessCategoryProfiles.fromKey(user?.businessCategory);
    final isSalon = profile.key == 'salon_coiffure';
    final isCashier = role == 'cashier' || role == 'caissier';
    final pages = isCashier
        ? const <Widget>[CashDeskScreen(), SalesJournalScreen()]
        : isSalon
        ? const <Widget>[
            CommerceDashboardScreen(),
            SalonServiceScreen(),
            SupplierNetworkScreen(),
            SalesJournalScreen(),
          ]
        : const <Widget>[
            CommerceDashboardScreen(),
            QuickSaleScreen(),
            InventoryScreen(),
            SupplierNetworkScreen(),
            SalesJournalScreen(),
          ];
    final safeIndex = _index >= pages.length ? 0 : _index;

    return Scaffold(
      body: Stack(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: pages[safeIndex],
          ),
          if (_syncBannerMessage != null)
            SafeArea(
              child: Align(
                alignment: Alignment.topCenter,
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: _syncBannerColor,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    _syncBannerMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: isDark
                  ? theme.colorScheme.surface.withValues(alpha: 0.82)
                  : Colors.white.withValues(alpha: 0.78),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(14),
              ),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.12)
                    : Colors.white.withValues(alpha: 0.76),
                width: 0.8,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.06),
                  blurRadius: 18,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SalomonBottomBar(
              currentIndex: safeIndex,
              onTap: (value) => setState(() => _index = value),
              selectedItemColor: theme.colorScheme.primary,
              unselectedItemColor: isDark
                  ? Colors.white70
                  : const Color(0xFF65676B),
              items: isCashier
                  ? [
                      SalomonBottomBarItem(
                        icon: const Icon(Icons.account_balance_wallet_outlined),
                        activeIcon: const Icon(Icons.account_balance_wallet),
                        title: const Text('Caisse'),
                      ),
                      SalomonBottomBarItem(
                        icon: const Icon(Icons.table_chart_outlined),
                        activeIcon: const Icon(Icons.table_chart),
                        title: const Text('Ventes'),
                      ),
                    ]
                  : isSalon
                  ? [
                      SalomonBottomBarItem(
                        icon: const Icon(Icons.space_dashboard_outlined),
                        activeIcon: const Icon(Icons.space_dashboard),
                        title: const Text('Pilotage'),
                      ),
                      SalomonBottomBarItem(
                        icon: const Icon(Icons.content_cut_outlined),
                        activeIcon: const Icon(Icons.content_cut),
                        title: const Text('Prestations'),
                      ),
                      SalomonBottomBarItem(
                        icon: const Icon(Icons.groups_outlined),
                        activeIcon: const Icon(Icons.storefront),
                        title: const Text('Fournisseurs'),
                      ),
                      SalomonBottomBarItem(
                        icon: const Icon(Icons.table_chart_outlined),
                        activeIcon: const Icon(Icons.table_chart),
                        title: const Text('Ventes'),
                      ),
                    ]
                  : [
                      SalomonBottomBarItem(
                        icon: const Icon(Icons.space_dashboard_outlined),
                        activeIcon: const Icon(Icons.space_dashboard),
                        title: const Text('Pilotage'),
                      ),
                      SalomonBottomBarItem(
                        icon: const Icon(Icons.point_of_sale_outlined),
                        activeIcon: const Icon(Icons.point_of_sale),
                        title: const Text('Vendre'),
                      ),
                      SalomonBottomBarItem(
                        icon: const Icon(Icons.inventory_2_outlined),
                        activeIcon: const Icon(Icons.inventory_2),
                        title: const Text('Stock'),
                      ),
                      SalomonBottomBarItem(
                        icon: const Icon(Icons.groups_outlined),
                        activeIcon: const Icon(Icons.storefront),
                        title: const Text('Fournisseurs'),
                      ),
                      SalomonBottomBarItem(
                        icon: const Icon(Icons.table_chart_outlined),
                        activeIcon: const Icon(Icons.table_chart),
                        title: const Text('Ventes'),
                      ),
                    ],
            ),
          ),
        ),
      ),
    );
  }
}
