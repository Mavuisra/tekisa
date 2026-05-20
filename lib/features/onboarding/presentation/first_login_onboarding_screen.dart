library;

import 'package:flutter/material.dart';

class FirstLoginOnboardingScreen extends StatefulWidget {
  const FirstLoginOnboardingScreen({
    super.key,
    required this.userRole,
    required this.onFinished,
    required this.onContactSupport,
  });

  final String userRole;
  final Future<void> Function() onFinished;
  final Future<void> Function() onContactSupport;

  @override
  State<FirstLoginOnboardingScreen> createState() =>
      _FirstLoginOnboardingScreenState();
}

class _FirstLoginOnboardingScreenState
    extends State<FirstLoginOnboardingScreen> {
  final PageController _controller = PageController();
  int _page = 0;
  bool _finishing = false;

  List<_OnboardingData> get _pages {
    final role = widget.userRole.toLowerCase();
    final isCashier = role == 'cashier' || role == 'caissier';
    final isSeller = role == 'seller' || role == 'vendeur';
    final isTeacher = role == 'teacher';
    final isAdmin =
        role == 'admin' || role == 'super_admin' || role == 'school_admin';

    if (isCashier) {
      return const [
        _OnboardingData(
          icon: Icons.account_balance_wallet_outlined,
          title: 'Bienvenue caissier',
          description:
              'Vous gérez la caisse du jour : entrées, sorties et solde en temps réel.',
        ),
        _OnboardingData(
          icon: Icons.receipt_long_outlined,
          title: 'Depenses justifiees',
          description:
              'Chaque dépense doit avoir un motif clair pour assurer un bon suivi financier.',
        ),
        _OnboardingData(
          icon: Icons.support_agent_rounded,
          title: 'Besoin d’aide ?',
          description:
              'Contactez le propriétaire de l’application via WhatsApp en cas de souci.',
        ),
      ];
    }

    if (isSeller) {
      return const [
        _OnboardingData(
          icon: Icons.point_of_sale_outlined,
          title: 'Bienvenue vendeur',
          description:
              'Enregistrez les ventes rapidement et générez les factures pour chaque client.',
        ),
        _OnboardingData(
          icon: Icons.inventory_2_outlined,
          title: 'Gestion des articles',
          description:
              'Consultez les produits disponibles et suivez les mouvements de stock.',
        ),
        _OnboardingData(
          icon: Icons.support_agent_rounded,
          title: 'Besoin d’aide ?',
          description:
              'Contactez le propriétaire de l’application via WhatsApp en cas de souci.',
        ),
      ];
    }

    if (isTeacher) {
      return const [
        _OnboardingData(
          icon: Icons.school_outlined,
          title: 'Bienvenue enseignant',
          description:
              'Suivez vos classes, présences et notes depuis un seul espace.',
        ),
        _OnboardingData(
          icon: Icons.fact_check_outlined,
          title: 'Suivi pédagogique',
          description:
              'Organisez les évaluations, les présences et les activités de classe.',
        ),
        _OnboardingData(
          icon: Icons.support_agent_rounded,
          title: 'Besoin d’aide ?',
          description:
              'Contactez le propriétaire de l’application via WhatsApp en cas de souci.',
        ),
      ];
    }

    if (isAdmin) {
      return const [
        _OnboardingData(
          icon: Icons.storefront_outlined,
          title: 'Bienvenue administrateur',
          description:
              'Pilotez les ventes, le stock, les clients et les performances de votre entreprise.',
        ),
        _OnboardingData(
          icon: Icons.manage_accounts_outlined,
          title: 'Gestion d’équipe',
          description:
              'Créez les comptes caissier et vendeur selon les rôles de votre personnel.',
        ),
        _OnboardingData(
          icon: Icons.support_agent_rounded,
          title: 'Besoin d’aide ?',
          description:
              'Contactez le propriétaire de l’application via WhatsApp en cas de souci.',
        ),
      ];
    }

    return const [
      _OnboardingData(
        icon: Icons.storefront_outlined,
        title: 'Bienvenue sur TEKISA',
        description:
            'Gérez votre activité quotidienne dans un espace simple, rapide et professionnel.',
      ),
      _OnboardingData(
        icon: Icons.people_outline_rounded,
        title: 'Travail en équipe',
        description:
            'Chaque utilisateur peut avoir un rôle précis pour une gestion claire de l’entreprise.',
      ),
      _OnboardingData(
        icon: Icons.support_agent_rounded,
        title: 'Besoin d’aide ?',
        description:
            'Contactez le propriétaire de l’application via WhatsApp en cas de souci.',
      ),
    ];
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    final lastIndex = _pages.length - 1;
    if (_page < lastIndex) {
      await _controller.nextPage(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOut,
      );
      return;
    }
    if (_finishing) return;
    setState(() => _finishing = true);
    await widget.onFinished();
    if (mounted) {
      setState(() => _finishing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _finishing ? null : _next,
                  child: const Text('Passer'),
                ),
              ),
              Expanded(
                child: PageView(
                  controller: _controller,
                  onPageChanged: (value) => setState(() => _page = value),
                  children: _pages
                      .map(
                        (item) => _OnboardingPage(
                          icon: item.icon,
                          title: item.title,
                          description: item.description,
                        ),
                      )
                      .toList(),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _pages.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _page == index ? 18 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _page == index
                          ? theme.colorScheme.primary
                          : const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: widget.onContactSupport,
                      icon: const Icon(Icons.chat_outlined),
                      label: const Text('WhatsApp'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: _finishing ? null : _next,
                      child: _finishing
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              _page == _pages.length - 1
                                  ? 'Commencer'
                                  : 'Suivant',
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingData {
  const _OnboardingData({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;
}

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 94,
          height: 94,
          decoration: BoxDecoration(
            color: const Color(0xFFE9EFF3),
            borderRadius: BorderRadius.circular(3),
          ),
          child: Icon(icon, size: 46, color: const Color(0xFF035D8A)),
        ),
        const SizedBox(height: 22),
        Text(
          title,
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall?.copyWith(
            color: const Color(0xFF111827),
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          description,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: const Color(0xFF475569),
          ),
        ),
      ],
    );
  }
}
