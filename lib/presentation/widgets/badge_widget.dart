import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

class BadgeWidget extends StatelessWidget {
  const BadgeWidget({
    super.key,
    required this.icon,
    this.label,
    this.size = 48,
    this.glow = true,
  });

  final IconData icon;
  final String? label;
  final double size;
  final bool glow;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 500),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  color: AppColors.accentYellow.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                  boxShadow: glow
                      ? [
                          BoxShadow(
                            color: AppColors.accentYellow.withValues(
                              alpha: 0.6,
                            ),
                            blurRadius: 12,
                            spreadRadius: 2,
                          ),
                        ]
                      : null,
                ),
                child: Icon(
                  icon,
                  size: size * 0.6,
                  color: AppColors.accentYellow,
                ),
              ),
              if (label != null) ...[
                const SizedBox(height: 4),
                Text(
                  label!,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
