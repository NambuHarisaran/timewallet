import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

/// One plotted line: evenly-spaced [points] on the x-axis.
class LineSeries {
  final String label;
  final List<double> points;
  final Color color;
  const LineSeries(this.label, this.points, this.color);
}

/// Pure-Flutter multi-line chart (no chart package — `fl_chart` was removed
/// earlier over a Windows-Defender/DDC file-lock). Draws a baseline grid, the
/// series lines, a soft fill under a single series, and a legend.
class SimpleLineChart extends StatelessWidget {
  final List<LineSeries> series;
  final double height;

  /// Formats the top-of-axis value (e.g. ₹1.2 Cr) and the x-end label.
  final String Function(double maxY) yTopLabel;
  final String Function(int lastIndex) xEndLabel;
  final String xStartLabel;

  const SimpleLineChart({
    super.key,
    required this.series,
    required this.yTopLabel,
    required this.xEndLabel,
    this.xStartLabel = '0',
    this.height = 200,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final maxY = series
        .expand((s) => s.points)
        .fold(0.0, (a, b) => math.max(a, b))
        .toDouble();
    final lastIndex = series.fold(
        0, (a, s) => math.max(a, s.points.length - 1));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: height,
          width: double.infinity,
          child: CustomPaint(
            painter: _LinePainter(
              series: series,
              maxY: maxY == 0 ? 1 : maxY,
              lastIndex: lastIndex == 0 ? 1 : lastIndex,
              gridColor: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              labelColor: isDark ? AppColors.darkMuted : AppColors.lightMuted,
              topLabel: yTopLabel(maxY),
              xStart: xStartLabel,
              xEnd: xEndLabel(lastIndex),
            ),
          ),
        ),
        if (series.length > 1) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 6,
            children: [for (final s in series) _Legend(s.label, s.color)],
          ),
        ],
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  final String label;
  final Color color;
  const _Legend(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 3,
          decoration: BoxDecoration(
              color: color, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _LinePainter extends CustomPainter {
  final List<LineSeries> series;
  final double maxY;
  final int lastIndex;
  final Color gridColor;
  final Color labelColor;
  final String topLabel;
  final String xStart;
  final String xEnd;

  _LinePainter({
    required this.series,
    required this.maxY,
    required this.lastIndex,
    required this.gridColor,
    required this.labelColor,
    required this.topLabel,
    required this.xStart,
    required this.xEnd,
  });

  static const double _leftPad = 8;
  static const double _bottomPad = 22;
  static const double _topPad = 18;

  @override
  void paint(Canvas canvas, Size size) {
    final chartW = size.width - _leftPad;
    final chartH = size.height - _bottomPad - _topPad;
    final originY = _topPad + chartH;

    final grid = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    // Horizontal gridlines (4 bands).
    for (var g = 0; g <= 4; g++) {
      final y = _topPad + chartH * g / 4;
      canvas.drawLine(Offset(_leftPad, y), Offset(size.width, y), grid);
    }

    double dx(int i) => _leftPad + chartW * (i / lastIndex);
    double dy(double v) => originY - chartH * (v / maxY);

    for (final s in series) {
      if (s.points.isEmpty) continue;
      final path = Path();
      for (var i = 0; i < s.points.length; i++) {
        final p = Offset(dx(i), dy(s.points[i]));
        if (i == 0) {
          path.moveTo(p.dx, p.dy);
        } else {
          path.lineTo(p.dx, p.dy);
        }
      }
      // Soft fill under the line when there's only one series.
      if (series.length == 1) {
        final fill = Path.from(path)
          ..lineTo(dx(s.points.length - 1), originY)
          ..lineTo(dx(0), originY)
          ..close();
        canvas.drawPath(
          fill,
          Paint()
            ..shader = ui.Gradient.linear(
              Offset(0, _topPad),
              Offset(0, originY),
              [s.color.withValues(alpha: 0.28), s.color.withValues(alpha: 0.02)],
            ),
        );
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = s.color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..strokeJoin = StrokeJoin.round
          ..strokeCap = StrokeCap.round,
      );
    }

    _text(canvas, topLabel, Offset(_leftPad, 0), labelColor);
    _text(canvas, xStart, Offset(_leftPad, originY + 6), labelColor);
    _text(canvas, xEnd, Offset(size.width, originY + 6), labelColor,
        alignRight: true);
  }

  void _text(Canvas canvas, String s, Offset at, Color color,
      {bool alignRight = false}) {
    final tp = TextPainter(
      text: TextSpan(
          text: s, style: TextStyle(color: color, fontSize: 10)),
      textDirection: ui.TextDirection.ltr,
    )..layout();
    final dx = alignRight ? at.dx - tp.width : at.dx;
    tp.paint(canvas, Offset(dx, at.dy));
  }

  @override
  bool shouldRepaint(_LinePainter old) =>
      old.series != series || old.maxY != maxY || old.lastIndex != lastIndex;
}

// ===========================================================================
// Donut
// ===========================================================================

class DonutSlice {
  final String label;
  final double value;
  final Color color;
  const DonutSlice(this.label, this.value, this.color);
}

/// A donut/ring chart for proportional splits (asset allocation). Pure
/// CustomPaint; legend rendered by the caller or via [showLegend].
class DonutChart extends StatelessWidget {
  final List<DonutSlice> slices;
  final double size;
  final String? centerTop;
  final String? centerBottom;
  final bool showLegend;

  const DonutChart({
    super.key,
    required this.slices,
    this.size = 160,
    this.centerTop,
    this.centerBottom,
    this.showLegend = true,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final ring = SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _DonutPainter(slices),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (centerTop != null)
                Text(centerTop!,
                    style: t.titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold)),
              if (centerBottom != null)
                Text(centerBottom!, style: t.bodySmall),
            ],
          ),
        ),
      ),
    );
    if (!showLegend) return ring;
    return Row(
      children: [
        ring,
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final s in slices) ...[
                Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                          color: s.color,
                          borderRadius: BorderRadius.circular(3)),
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(s.label, style: t.bodyMedium)),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _DonutPainter extends CustomPainter {
  final List<DonutSlice> slices;
  _DonutPainter(this.slices);

  @override
  void paint(Canvas canvas, Size size) {
    final total = slices.fold(0.0, (a, s) => a + s.value);
    if (total <= 0) return;
    final stroke = size.width * 0.18;
    final rect = Rect.fromLTWH(stroke / 2, stroke / 2,
        size.width - stroke, size.height - stroke);
    var start = -math.pi / 2;
    for (final s in slices) {
      final sweep = (s.value / total) * 2 * math.pi;
      canvas.drawArc(
        rect,
        start,
        sweep - 0.04, // tiny gap between slices
        false,
        Paint()
          ..color = s.color
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..strokeCap = StrokeCap.butt,
      );
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(_DonutPainter old) => old.slices != slices;
}
