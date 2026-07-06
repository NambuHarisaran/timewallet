import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/theme/app_colors.dart';
import '../core/util/formatters.dart';

/// Manual numeric entry that replaced the old range sliders across the tools:
/// type the exact value, or tap a preset chip. Values outside [min, max] show
/// an inline error and are NOT committed, so the parent state always holds a
/// valid number; an empty or invalid field is restored to the last committed
/// value on blur.
class ValueField extends StatefulWidget {
  final String label;
  final double value;
  final double min, max;
  final ValueChanged<double> onChanged;

  /// e.g. '₹ ' — a ₹ prefix switches helpers to compact rupee formatting.
  final String prefix;

  /// e.g. '% p.a.', 'yrs'.
  final String suffix;
  final bool decimal;
  final List<double> presets;
  final String Function(double)? presetLabel;
  final Color accent;
  final String? help;

  const ValueField({
    super.key,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.prefix = '',
    this.suffix = '',
    this.decimal = false,
    this.presets = const [],
    this.presetLabel,
    this.accent = AppColors.accent,
    this.help,
  });

  @override
  State<ValueField> createState() => _ValueFieldState();
}

class _ValueFieldState extends State<ValueField> {
  late final TextEditingController _ctrl =
      TextEditingController(text: _plain(widget.value));
  final FocusNode _focus = FocusNode();
  String? _error;

  bool get _isMoney => widget.prefix.contains('₹');

  static String _plain(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);

  String _fmt(double v) => _isMoney ? moneyCompact(v) : _plain(v);

  @override
  void initState() {
    super.initState();
    // Restore the last committed value when the user leaves the field empty
    // or invalid — the parent state never saw the bad input.
    _focus.addListener(() {
      if (_focus.hasFocus) return;
      final v = double.tryParse(_ctrl.text);
      if (v == null || v < widget.min || v > widget.max) {
        setState(() {
          _ctrl.text = _plain(widget.value);
          _error = null;
        });
      }
    });
  }

  @override
  void didUpdateWidget(ValueField old) {
    super.didUpdateWidget(old);
    // External change (preset elsewhere, seeding, clamping) — sync the text,
    // but never while the user is typing in this field.
    if (!_focus.hasFocus && double.tryParse(_ctrl.text) != widget.value) {
      _ctrl.text = _plain(widget.value);
      _error = null;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _handle(String s) {
    final v = double.tryParse(s);
    if (v == null) {
      // Mid-typing ('', '.') — no error yet, no commit.
      setState(() => _error = null);
      return;
    }
    if (v < widget.min || v > widget.max) {
      setState(
          () => _error = 'Enter ${_fmt(widget.min)} – ${_fmt(widget.max)}');
      return;
    }
    setState(() => _error = null);
    widget.onChanged(v);
  }

  void _preset(double p) {
    setState(() {
      _ctrl.text = _plain(p);
      _error = null;
    });
    widget.onChanged(p);
  }

  String get _helper {
    final range = 'Up to ${_fmt(widget.max)}';
    if (_isMoney && widget.value >= 1000) {
      return '${moneyCompact(widget.value)} · $range';
    }
    return range;
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: t.bodyMedium),
        const SizedBox(height: 8),
        TextField(
          controller: _ctrl,
          focusNode: _focus,
          keyboardType: TextInputType.numberWithOptions(decimal: widget.decimal),
          inputFormatters: [
            FilteringTextInputFormatter.allow(
                RegExp(widget.decimal ? r'[0-9.]' : r'[0-9]')),
          ],
          style: t.headlineSmall
              ?.copyWith(color: widget.accent, fontWeight: FontWeight.w700),
          decoration: InputDecoration(
            prefixText: widget.prefix,
            prefixStyle: t.headlineSmall
                ?.copyWith(color: widget.accent, fontWeight: FontWeight.w700),
            suffixText: widget.suffix,
            suffixStyle:
                t.bodyMedium?.copyWith(color: AppColors.muted(context)),
            helperText: widget.help ?? _helper,
            errorText: _error,
          ),
          onChanged: _handle,
        ),
        if (widget.presets.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final p in widget.presets)
                ChoiceChip(
                  label: Text(widget.presetLabel?.call(p) ??
                      (_isMoney ? moneyFmt.format(p) : _plain(p))),
                  selected: widget.value == p,
                  onSelected: (_) => _preset(p),
                ),
            ],
          ),
        ],
      ],
    );
  }
}
