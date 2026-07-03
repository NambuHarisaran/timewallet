import 'package:flutter/material.dart';

import 'section_card.dart';

/// X9 — an empty state that *shows the value* instead of hiding. A greyed,
/// non-interactive preview of what the card looks like with data, plus one
/// clear CTA. Beats a blank space or a "nothing here yet" dead end.
///
/// The preview is wrapped in IgnorePointer + ExcludeSemantics so it can't be
/// tapped or announced — only the CTA is live. No IntrinsicHeight/LayoutBuilder
/// (web crash guard); a Stack does the overlay.
class EmptyPreview extends StatelessWidget {
  final String title;
  final Widget preview;
  final String cta;
  final VoidCallback onTap;

  const EmptyPreview({
    super.key,
    required this.title,
    required this.preview,
    required this.cta,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: title,
      child: Stack(
        alignment: Alignment.center,
        children: [
          IgnorePointer(
            child: ExcludeSemantics(
              child: Opacity(opacity: 0.38, child: preview),
            ),
          ),
          Positioned.fill(
            child: Center(
              child: FilledButton.tonal(
                onPressed: onTap,
                child: Text(cta),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
