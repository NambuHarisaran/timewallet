import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_colors.dart';
import '../state/app_providers.dart';

/// A one-time inline explainer. Render it only when the concept it teaches
/// first becomes relevant (e.g. the first overtime, the first hold). It shows
/// a dismissible card the first time, persists a per-id seen flag, then never
/// shows again. This is progressive disclosure — teach in context, not in a
/// wall of jargon up front.
class FirstTimeTip extends ConsumerStatefulWidget {
  final String id;
  final String title;
  final String body;
  final IconData icon;

  const FirstTimeTip({
    super.key,
    required this.id,
    required this.title,
    required this.body,
    this.icon = Icons.lightbulb_outline,
  });

  @override
  ConsumerState<FirstTimeTip> createState() => _FirstTimeTipState();
}

class _FirstTimeTipState extends ConsumerState<FirstTimeTip> {
  static const _prefix = 'tip_';
  late bool _seen;

  @override
  void initState() {
    super.initState();
    _seen =
        ref.read(sharedPrefsProvider).getBool('$_prefix${widget.id}') ?? false;
  }

  void _dismiss() {
    ref.read(sharedPrefsProvider).setBool('$_prefix${widget.id}', true);
    setState(() => _seen = true);
  }

  @override
  Widget build(BuildContext context) {
    if (_seen) return const SizedBox.shrink();
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
        decoration: BoxDecoration(
          color: AppColors.accent.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.accent.withValues(alpha: 0.35)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(widget.icon, size: 20, color: AppColors.accent),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.title,
                      style: t.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(widget.body,
                      style: t.bodySmall
                          ?.copyWith(color: AppColors.darkMuted, height: 1.35)),
                ],
              ),
            ),
            IconButton(
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.close, size: 18),
              color: AppColors.darkMuted,
              onPressed: _dismiss,
              tooltip: 'Got it',
            ),
          ],
        ),
      ),
    );
  }
}
