import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

/// Small tappable "?" affordance that explains a concept in plain language.
///
/// Used next to jargon (Earned today, On hold, Reclaimed, …) so new users can
/// learn a term at the exact spot it appears, without a separate tutorial.
class InfoDot extends StatelessWidget {
  final String title;
  final String body;

  /// Icon/foreground colour. Defaults to a muted dot; pass white on gradient
  /// hero cards.
  final Color? color;

  const InfoDot({
    super.key,
    required this.title,
    required this.body,
    this.color,
  });

  void _show(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        final t = Theme.of(ctx).textTheme;
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: t.titleLarge),
              const SizedBox(height: 12),
              Text(body, style: t.bodyLarge?.copyWith(height: 1.5)),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.darkMuted;
    return InkResponse(
      onTap: () => _show(context),
      radius: 22,
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: Icon(Icons.info_outline, size: 18, color: c),
      ),
    );
  }
}
