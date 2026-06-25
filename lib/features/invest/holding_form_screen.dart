import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/models/holding.dart';
import '../../state/app_providers.dart';
import '../../widgets/responsive_body.dart';

/// Add (holding == null) or edit an existing holding. Phase 1: prices manual.
class HoldingFormScreen extends ConsumerStatefulWidget {
  final Holding? holding;
  const HoldingFormScreen({super.key, this.holding});

  @override
  ConsumerState<HoldingFormScreen> createState() => _HoldingFormScreenState();
}

class _HoldingFormScreenState extends ConsumerState<HoldingFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _symbol;
  late final TextEditingController _units;
  late final TextEditingController _buyPrice;
  late final TextEditingController _currentPrice;

  late AssetType _type;
  late DateTime _buyDate;
  String? _purity; // gold only

  static const _purities = ['24k', '22k', '18k'];

  bool get _isEdit => widget.holding != null;

  @override
  void initState() {
    super.initState();
    final h = widget.holding;
    _type = h?.type ?? AssetType.stock;
    _buyDate = h?.buyDate ?? DateTime.now();
    _purity = h?.type == AssetType.gold ? (h?.meta ?? '22k') : h?.meta;
    _name = TextEditingController(text: h?.name ?? '');
    _symbol = TextEditingController(text: h?.symbol ?? '');
    _units = TextEditingController(text: h == null ? '' : _trim(h.units));
    _buyPrice =
        TextEditingController(text: h == null ? '' : _trim(h.buyPrice));
    _currentPrice = TextEditingController(
        text: h?.manualPrice == null ? '' : _trim(h!.manualPrice!));
  }

  String _trim(double v) =>
      v % 1 == 0 ? v.toStringAsFixed(0) : v.toString();

  @override
  void dispose() {
    _name.dispose();
    _symbol.dispose();
    _units.dispose();
    _buyPrice.dispose();
    _currentPrice.dispose();
    super.dispose();
  }

  String _unitWord() => _type.unitLabel;

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _buyDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _buyDate = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final units = double.parse(_units.text);
    final buyPrice = double.parse(_buyPrice.text);
    final current = _currentPrice.text.trim().isEmpty
        ? null
        : double.tryParse(_currentPrice.text);
    final meta = _type == AssetType.gold ? _purity : null;
    final symbol =
        _symbol.text.trim().isEmpty ? null : _symbol.text.trim().toUpperCase();

    final actions = ref.read(appActionsProvider);
    if (_isEdit) {
      await actions.saveHolding(widget.holding!.copyWith(
        type: _type,
        name: _name.text.trim(),
        symbol: symbol,
        units: units,
        buyPrice: buyPrice,
        buyDate: _buyDate,
        manualPrice: current,
        clearManualPrice: current == null,
        meta: meta,
      ));
    } else {
      await actions.addHolding(
        type: _type,
        name: _name.text.trim(),
        symbol: symbol,
        units: units,
        buyPrice: buyPrice,
        buyDate: _buyDate,
        manualPrice: current,
        meta: meta,
      );
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final dateLabel = DateFormat('d MMM yyyy').format(_buyDate);
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Edit holding' : 'Add holding')),
      body: ResponsiveBody(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Asset type
              Wrap(
                spacing: 8,
                children: AssetType.values.map((ty) {
                  return ChoiceChip(
                    avatar: Icon(ty.icon, size: 18),
                    label: Text(ty.label),
                    selected: _type == ty,
                    onSelected: (_) => setState(() {
                      _type = ty;
                      if (ty == AssetType.gold) _purity ??= '22k';
                    }),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _name,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: 'Name',
                  hintText: _type == AssetType.gold
                      ? 'e.g. Sovereign gold'
                      : _type == AssetType.stock
                          ? 'e.g. Reliance'
                          : 'e.g. Bitcoin',
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Enter a name' : null,
              ),
              if (_type == AssetType.gold) ...[
                const SizedBox(height: 16),
                Text('Purity',
                    style: Theme.of(context).textTheme.labelSmall),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  children: _purities.map((p) {
                    return ChoiceChip(
                      label: Text(p),
                      selected: _purity == p,
                      onSelected: (_) => setState(() => _purity = p),
                    );
                  }).toList(),
                ),
              ],
              const SizedBox(height: 16),
              TextFormField(
                controller: _units,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                ],
                decoration: InputDecoration(
                    labelText: 'Quantity (${_unitWord()})'),
                validator: _positive,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _buyPrice,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                ],
                decoration: InputDecoration(
                  labelText: 'Buy price per ${_singular()}',
                  prefixText: '₹ ',
                ),
                validator: _positive,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _currentPrice,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                ],
                decoration: InputDecoration(
                  labelText: 'Current price per ${_singular()} (optional)',
                  helperText: 'Leave blank — live price auto-fills for stocks (with ticker) & gold',
                  prefixText: '₹ ',
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null;
                  final n = double.tryParse(v);
                  return (n == null || n < 0) ? 'Invalid price' : null;
                },
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.event),
                title: const Text('Buy date'),
                subtitle: Text(dateLabel),
                trailing: const Icon(Icons.chevron_right),
                onTap: _pickDate,
              ),
              if (_type == AssetType.stock ||
                  _type == AssetType.mutualFund) ...[
                const SizedBox(height: 8),
                TextFormField(
                  controller: _symbol,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    labelText: _type == AssetType.mutualFund
                        ? 'Scheme code (optional)'
                        : 'Ticker symbol (optional)',
                    hintText:
                        _type == AssetType.mutualFund ? '118726' : 'RELIANCE.NS',
                    helperText: _type == AssetType.mutualFund
                        ? 'AMFI scheme code — live NAV via mfapi.in'
                        : 'Needed for live prices (NSE = .NS, BSE = .BO)',
                  ),
                  validator: (v) {
                    final s = (v ?? '').trim();
                    if (s.isEmpty) return null;
                    return RegExp(r'^[A-Za-z0-9.\-]{1,15}$').hasMatch(s)
                        ? null
                        : 'Letters, numbers, . and - only (max 15)';
                  },
                ),
              ],
              const SizedBox(height: 28),
              FilledButton(
                onPressed: _save,
                style:
                    FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                child: Text(_isEdit ? 'Save changes' : 'Add holding'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _singular() => switch (_type) {
        AssetType.stock => 'share',
        AssetType.gold => 'gram',
        AssetType.other => 'unit',
        AssetType.mutualFund => 'unit',
      };

  String? _positive(String? v) {
    final n = double.tryParse(v ?? '');
    return (n == null || n <= 0) ? 'Enter a number > 0' : null;
  }
}
