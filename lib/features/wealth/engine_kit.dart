import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/util/formatters.dart';
import '../../widgets/section_card.dart';

/// ₹ formatter shared across the Wealth engines (no decimals).
final money = moneyFmt;

/// Compact ₹ for chart axes: ₹1.2 Cr / ₹45.0 L / ₹8,000.
String moneyShort(double v) {
  if (v.abs() >= 10000000) return '₹${(v / 10000000).toStringAsFixed(2)} Cr';
  if (v.abs() >= 100000) return '₹${(v / 100000).toStringAsFixed(1)} L';
  if (v.abs() >= 1000) return '₹${(v / 1000).toStringAsFixed(0)}k';
  return '₹${v.toStringAsFixed(0)}';
}

/// AppBar + scrollable body used by every engine screen.
class EngineScaffold extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const EngineScaffold({super.key, required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: children,
      ),
    );
  }
}

/// Slider with a tap-to-type value (for precision the discrete steps can't hit).
/// Lifted from the Tools calculators so both tabs share one control.
class EngineSlider extends StatelessWidget {
  final String label;
  final double value, min, max;
  final int divisions;
  final ValueChanged<double> onChanged;
  final String display;
  final Color accent;

  const EngineSlider(
    this.label,
    this.value,
    this.min,
    this.max,
    this.divisions,
    this.onChanged,
    this.display, {
    super.key,
    this.accent = AppColors.accent,
  });

  static String _plain(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);

  Future<void> _editValue(BuildContext context) async {
    final ctrl = TextEditingController(text: _plain(value));
    final entered = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(label),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
          decoration: InputDecoration(
            hintText: 'Enter exact value',
            helperText: 'Allowed range ${_plain(min)} – ${_plain(max)}',
          ),
          onSubmitted: (s) => Navigator.pop(ctx, double.tryParse(s)),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, double.tryParse(ctrl.text)),
            child: const Text('Set'),
          ),
        ],
      ),
    );
    if (entered != null) onChanged(entered.clamp(min, max).toDouble());
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(child: Text(label, style: t.bodyMedium)),
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => _editValue(context),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(display,
                        style: t.bodyLarge?.copyWith(
                            color: accent, fontWeight: FontWeight.w600)),
                    const SizedBox(width: 4),
                    Icon(Icons.edit, size: 14, color: accent),
                  ],
                ),
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: accent,
            thumbColor: accent,
            overlayColor: accent.withValues(alpha: 0.15),
          ),
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

/// Wraps a set of input controls in the standard card.
class EngineInputs extends StatelessWidget {
  final List<Widget> children;
  const EngineInputs({super.key, required this.children});

  @override
  Widget build(BuildContext context) =>
      SectionCard(child: Column(children: children));
}

/// Single big-number result with an optional footnote.
class EngineResult extends StatelessWidget {
  final String headline, value;
  final String? footnote;
  final Color accent;
  const EngineResult({
    super.key,
    required this.headline,
    required this.value,
    this.footnote,
    this.accent = AppColors.accent,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(headline, style: t.labelSmall),
          const SizedBox(height: 4),
          Text(value, style: t.displayLarge?.copyWith(color: accent)),
          if (footnote != null) ...[
            const SizedBox(height: 8),
            Text(footnote!, style: t.bodyMedium),
          ],
        ],
      ),
    );
  }
}

/// A labelled row inside a result card (e.g. instrument → corpus).
class EngineStatRow extends StatelessWidget {
  final Color dot;
  final String label;
  final String value;
  final String? sub;
  const EngineStatRow(
      {super.key,
      required this.dot,
      required this.label,
      required this.value,
      this.sub});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration:
                BoxDecoration(color: dot, borderRadius: BorderRadius.circular(3)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: t.bodyLarge),
                if (sub != null) Text(sub!, style: t.bodySmall),
              ],
            ),
          ),
          Text(value,
              style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
