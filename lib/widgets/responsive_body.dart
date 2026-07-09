import 'package:flutter/material.dart';

/// The column width a screen should cap itself to for a given available width.
/// Phones fill the viewport (return the caller's [base]); tablets and desktops
/// get a roomier column so the app doesn't look marooned in dead side-space,
/// but stay narrow enough that cards and text lines never stretch unreadably.
double responsiveMaxWidth(double available, double base) {
  if (available >= 900) return base < 720 ? 720 : base;
  if (available >= 600) return base < 600 ? 600 : base;
  return base;
}

/// Centers content and caps its width on large/tablet screens while letting it
/// fill the viewport on phones. Wrap a screen body in this so layouts stay
/// readable on wide displays and never overflow on small ones.
///
/// When [scrollable] is true (default) the child is placed in a
/// [SingleChildScrollView], so tall content on short devices scrolls instead of
/// throwing a render overflow.
class ResponsiveBody extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsets padding;
  final bool scrollable;

  const ResponsiveBody({
    super.key,
    required this.child,
    this.maxWidth = 480,
    this.padding = const EdgeInsets.all(16),
    this.scrollable = true,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cap = responsiveMaxWidth(constraints.maxWidth, maxWidth);
          Widget content = ConstrainedBox(
            constraints: BoxConstraints(maxWidth: cap),
            child: Padding(padding: padding, child: child),
          );
          if (scrollable) {
            // Scrolls when content is taller than the viewport; Center
            // vertically aligns it when shorter. No IntrinsicHeight/
            // LayoutBuilder around the child — those break on subtrees (Wrap,
            // chips) that don't support intrinsic dimensions.
            content = SingleChildScrollView(child: content);
          }
          return Center(child: content);
        },
      ),
    );
  }
}

/// Lays out a list of same-purpose tiles in as many columns as the width
/// allows — one on phones, two on tablets, up to three on wide/desktop. Unlike
/// [GridView] it uses a [Wrap], so tiles keep their natural height (no
/// cross-axis aspect-ratio to guess) and ragged rows never overflow. Put it
/// inside a wide wrapper (e.g. `ContentWidth(maxWidth: 1120)`) so catalog
/// screens actually fill a tablet instead of stranding a narrow column.
class TileGrid extends StatelessWidget {
  final List<Widget> children;
  final double spacing;

  /// A tile never renders narrower than this; the column count is derived from
  /// how many of these fit the available width.
  final double minTileWidth;

  const TileGrid({
    super.key,
    required this.children,
    this.spacing = 12,
    this.minTileWidth = 330,
  });

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final cols =
            ((w + spacing) / (minTileWidth + spacing)).floor().clamp(1, 3);
        if (cols <= 1) {
          return Column(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0) SizedBox(height: spacing),
                children[i],
              ],
            ],
          );
        }
        final tileWidth = (w - spacing * (cols - 1)) / cols;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final child in children)
              SizedBox(width: tileWidth, child: child),
          ],
        );
      },
    );
  }
}

/// Centers and width-caps an already-scrollable child (ListView, PageView,
/// CustomScrollView). Unlike [ResponsiveBody] it adds NO scroll view of its
/// own — use it to stop full-bleed stretch on tablets/wide phones while the
/// child keeps its own scrolling and pull-to-refresh.
class ContentWidth extends StatelessWidget {
  final Widget child;
  final double maxWidth;

  const ContentWidth({super.key, required this.child, this.maxWidth = 480});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cap = responsiveMaxWidth(constraints.maxWidth, maxWidth);
        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: cap),
            child: child,
          ),
        );
      },
    );
  }
}
