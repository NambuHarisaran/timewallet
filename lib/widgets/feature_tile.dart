import 'package:flutter/material.dart';

import 'pressable.dart';
import 'section_card.dart';

/// Icon-box + title + subtitle row card — the shared tile for Tools, Wealth
/// and hub screens. Built on [Pressable] so every tile gets the spring press
/// and haptic for free.
class FeatureTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  final Widget trailing;

  const FeatureTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
    this.trailing = const Icon(Icons.chevron_right),
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Pressable(
      onTap: onTap,
      child: SectionCard(
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(child: Icon(icon, color: color, size: 26)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: t.titleLarge),
                  const SizedBox(height: 2),
                  Text(subtitle, style: t.bodyMedium),
                ],
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }
}
