/// Barre de compétence (niveau 1-5) avec animation
library;

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

class SkillProgressBar extends StatelessWidget {
  const SkillProgressBar({
    super.key,
    required this.label,
    required this.progress,
    this.max = 5,
    this.animate = true,
    this.duration = const Duration(milliseconds: 800),
  });

  final String label;
  final double progress;
  final double max;
  final bool animate;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final value = (progress / max).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 6),
        animate
            ? TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: value),
                duration: duration,
                curve: Curves.easeOutCubic,
                builder: (context, v, _) => _Bar(value: v),
              )
            : _Bar(value: value),
      ],
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        return Container(
          height: 10,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(3),
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Container(
              width: c.maxWidth * value,
              height: 10,
              decoration: BoxDecoration(
                color: AppColors.accentYellow,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        );
      },
    );
  }
}
