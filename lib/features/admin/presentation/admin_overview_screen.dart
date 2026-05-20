library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/config/env_config.dart';
import '../../../core/network/dio_client.dart';
import '../../../data/datasources/auth_local_datasource.dart';
import '../../../data/datasources/commerce_remote_datasource.dart';
import '../../../data/models/commerce_models.dart';

class AdminOverviewScreen extends StatefulWidget {
  const AdminOverviewScreen({super.key});

  @override
  State<AdminOverviewScreen> createState() => _AdminOverviewScreenState();
}

class _AdminOverviewScreenState extends State<AdminOverviewScreen> {
  final _authLocal = AuthLocalDataSource();
  AdminPlatformOverviewModel? _overview;
  List<SellerActivityModel> _sellers = const [];
  bool _loading = true;
  String? _error;

  List<double> _buildRevenueTrend(AdminPlatformOverviewModel? data) {
    final revenue = data?.revenueTotal ?? 0;
    final sales = (data?.salesCount ?? 0).toDouble();
    final sellers = (data?.sellersCount ?? 0).toDouble();
    final products = (data?.productsCount ?? 0).toDouble();
    final base = math.max(8.0, revenue / 12000);
    return <double>[
      base * 0.66 + sales * 0.05,
      base * 0.83 + sellers * 0.20,
      base * 0.72 + products * 0.06,
      base * 0.94 + sales * 0.04,
      base * 0.78 + sellers * 0.16,
      base * 0.88 + products * 0.05,
    ];
  }

  List<double> _buildActivityBars(AdminPlatformOverviewModel? data) {
    final sales = (data?.salesCount ?? 0).toDouble();
    final sellers = (data?.sellersCount ?? 0).toDouble();
    final products = (data?.productsCount ?? 0).toDouble();
    return <double>[
      math.max(6, sales * 0.32),
      math.max(6, sellers * 1.6),
      math.max(6, products * 0.45),
      math.max(6, sales * 0.22 + sellers),
      math.max(6, products * 0.28 + sellers * 0.8),
      math.max(6, sales * 0.26),
    ];
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final token = await _authLocal.getAccessToken();
    if (token == null || token.isEmpty) {
      setState(() {
        _loading = false;
        _error = 'Session expirée.';
      });
      return;
    }
    final client = DioClient(
      baseUrl: EnvConfig.apiBaseUrl,
      accessToken: token,
      getRefreshToken: () => _authLocal.getRefreshToken(),
      saveAccessToken: (t) => _authLocal.setAccessToken(t),
    );
    final ds = CommerceRemoteDataSource(client);
    try {
      final overview = await ds.getAdminPlatformOverview();
      final sellers = await ds.getAdminSellersActivity();
      if (!mounted) return;
      setState(() {
        _overview = overview;
        _sellers = sellers;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final overview = _overview;
    final trend = _buildRevenueTrend(overview);
    final bars = _buildActivityBars(overview);
    return Scaffold(
      appBar: AppBar(title: const Text('Administration')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_error != null) ...[
              Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
              const SizedBox(height: 10),
            ],
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              )
            else ...[
              _AdminHeroCard(
                totalRevenue: (overview?.revenueTotal ?? 0).toStringAsFixed(0),
                sellers: overview?.sellersCount ?? 0,
                sales: overview?.salesCount ?? 0,
              ),
              const SizedBox(height: 12),
              _AdminChartsCard(trendSeries: trend, activityBars: bars),
              const SizedBox(height: 12),
              GridView.count(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.35,
                children: [
                  _StatCard(
                    label: 'Vendeurs actifs',
                    value: '${overview?.sellersCount ?? 0}',
                    icon: Icons.group_outlined,
                    tone: const Color(0xFFE8F2FF),
                  ),
                  _StatCard(
                    label: 'Produits total',
                    value: '${overview?.productsCount ?? 0}',
                    icon: Icons.inventory_2_outlined,
                    tone: const Color(0xFFEAF9EF),
                  ),
                  _StatCard(
                    label: 'Ventes total',
                    value: '${overview?.salesCount ?? 0}',
                    icon: Icons.receipt_long_outlined,
                    tone: const Color(0xFFFFF1E6),
                  ),
                  _StatCard(
                    label: 'CA global',
                    value:
                        '${(overview?.revenueTotal ?? 0).toStringAsFixed(0)} CDF',
                    icon: Icons.paid_outlined,
                    tone: const Color(0xFFF2ECFF),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text('Activité par vendeur', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              if (_sellers.isEmpty)
                const Text('Aucun vendeur pour le moment.')
              else
                ..._sellers.map((s) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text(s.username),
                      subtitle: Text(
                        'Produits: ${s.productsCount} • Ventes: ${s.salesCount}',
                      ),
                      trailing: Text('${s.revenue.toStringAsFixed(0)} CDF'),
                    ),
                  );
                }),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.tone,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: tone,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18),
            ),
            const Spacer(),
            Text(label, style: theme.textTheme.bodySmall),
            const SizedBox(height: 2),
            Text(
              value,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminHeroCard extends StatelessWidget {
  const _AdminHeroCard({
    required this.totalRevenue,
    required this.sellers,
    required this.sales,
  });

  final String totalRevenue;
  final int sellers;
  final int sales;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1D4ED8), Color(0xFF2563EB), Color(0xFF0EA5E9)],
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Revenu global', style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 4),
          Text(
            '$totalRevenue CDF',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _HeroMiniChip(label: 'Vendeurs', value: '$sellers'),
              const SizedBox(width: 8),
              _HeroMiniChip(label: 'Ventes', value: '$sales'),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroMiniChip extends StatelessWidget {
  const _HeroMiniChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _AdminChartsCard extends StatelessWidget {
  const _AdminChartsCard({
    required this.trendSeries,
    required this.activityBars,
  });

  final List<double> trendSeries;
  final List<double> activityBars;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Analyse plateforme',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          _AnimatedTrendLine(series: trendSeries),
          const SizedBox(height: 10),
          _AnimatedActivityBars(series: activityBars),
        ],
      ),
    );
  }
}

class _AnimatedTrendLine extends StatelessWidget {
  const _AnimatedTrendLine({required this.series});

  final List<double> series;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 86,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: 1),
        duration: const Duration(milliseconds: 900),
        curve: Curves.easeOutCubic,
        builder: (context, value, _) {
          return CustomPaint(
            painter: _TrendPainter(series: series, progress: value),
          );
        },
      ),
    );
  }
}

class _AnimatedActivityBars extends StatelessWidget {
  const _AnimatedActivityBars({required this.series});

  final List<double> series;

  @override
  Widget build(BuildContext context) {
    final maxValue = series.isEmpty ? 1.0 : series.reduce(math.max);
    return SizedBox(
      height: 66,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(series.length, (index) {
          final ratio = maxValue <= 0 ? 0.1 : (series[index] / maxValue);
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: ratio),
                duration: Duration(milliseconds: 450 + (index * 70)),
                curve: Curves.easeOutBack,
                builder: (context, value, _) {
                  return Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      height: math.max(8, 62 * value),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: const Color(0xFF2563EB).withValues(alpha: 0.85),
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _TrendPainter extends CustomPainter {
  _TrendPainter({required this.series, required this.progress});

  final List<double> series;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    if (series.length < 2) return;
    final maxV = series.reduce(math.max);
    final minV = series.reduce(math.min);
    final span = math.max(1.0, maxV - minV);
    final points = <Offset>[];
    for (var i = 0; i < series.length; i++) {
      final x = (i / (series.length - 1)) * size.width;
      final normalized = (series[i] - minV) / span;
      final y = size.height - (normalized * (size.height - 12)) - 6;
      points.add(Offset(x, y));
    }
    final grid = Paint()
      ..color = const Color(0xFF94A3B8).withValues(alpha: 0.25)
      ..strokeWidth = 1;
    for (var i = 1; i <= 3; i++) {
      final dy = (size.height / 4) * i;
      canvas.drawLine(Offset(0, dy), Offset(size.width, dy), grid);
    }
    final line = Path()..moveTo(points.first.dx, points.first.dy);
    final drawCount = math.max(2, (points.length * progress).ceil());
    for (var i = 1; i < drawCount; i++) {
      line.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(
      line,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 2.2
        ..color = const Color(0xFF1D4ED8),
    );
    canvas.drawCircle(
      points[drawCount - 1],
      3.6,
      Paint()..color = const Color(0xFF0EA5E9),
    );
  }

  @override
  bool shouldRepaint(covariant _TrendPainter oldDelegate) {
    return oldDelegate.series != series || oldDelegate.progress != progress;
  }
}
