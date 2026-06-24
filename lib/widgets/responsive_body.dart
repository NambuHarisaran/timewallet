import 'package:flutter/material.dart';

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
    Widget content = ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Padding(padding: padding, child: child),
    );

    if (scrollable) {
      // Scrolls when content is taller than the viewport; Center vertically
      // aligns it when shorter. No IntrinsicHeight/LayoutBuilder — those break
      // on subtrees (Wrap, chips) that don't support intrinsic dimensions.
      content = SingleChildScrollView(child: content);
    }

    return SafeArea(child: Center(child: content));
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
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
