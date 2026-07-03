import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/theme/app_colors.dart';
import '../../core/time/duration_format.dart';
import '../../core/util/category_defaults.dart';
import '../../data/models/expense.dart';
import '../../services/receipt_scanner.dart';
import '../../state/app_providers.dart';
import '../../widgets/first_time_tip.dart';
import 'expense_commit.dart';

class AddExpenseScreen extends ConsumerStatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  ConsumerState<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends ConsumerState<AddExpenseScreen> {
  final _amount = TextEditingController();
  final _note = TextEditingController();
  String _categoryId = 'food';
  NeedWant _needWant = NeedWant.need;
  // Once the user sets need/want by hand we stop overriding it from category.
  bool _needWantTouched = false;
  bool _showMore = false;
  bool _scanning = false;

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  double get _value => double.tryParse(_amount.text) ?? 0;

  void _pickCategory(String id) {
    setState(() {
      _categoryId = id;
      if (!_needWantTouched) _needWant = defaultNeedWant(id);
    });
  }

  void _setNeedWant(NeedWant v) {
    setState(() {
      _needWant = v;
      _needWantTouched = true;
    });
  }

  /// Snap or pick a receipt → on-device OCR → prefill the amount for review.
  /// We never auto-save; the user always confirms the guessed total.
  Future<void> _scanReceipt() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take a photo'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Pick from gallery'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      final file =
          await ImagePicker().pickImage(source: source, imageQuality: 85);
      if (file == null) return;
      setState(() => _scanning = true);
      final scan = await ReceiptScanner().scan(file.path);
      if (!mounted) return;
      if (scan.amount != null) {
        _amount.text = scan.amount!.round().toString();
        messenger.showSnackBar(SnackBar(
            content: Text('Found ₹${scan.amount!.round()} — check it’s right')));
      } else {
        messenger.showSnackBar(const SnackBar(
            content: Text('Couldn’t read a total — type it in')));
      }
    } catch (_) {
      messenger.showSnackBar(
          const SnackBar(content: Text('Scan failed — try again or type it in')));
    } finally {
      if (mounted) setState(() => _scanning = false);
    }
  }

  void _commit({required bool hold}) => commitExpense(
        context,
        ref,
        amount: _value,
        categoryId: _categoryId,
        needWant: _needWant,
        hold: hold,
        note: _note.text,
      );

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final profile = ref.watch(profileOrDefaultProvider);
    final minutes = profile.engine.minutesFor(_value);
    final isWant = _needWant == NeedWant.want;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add expense'),
        actions: [
          IconButton(
            tooltip: 'Scan receipt',
            onPressed: _scanning ? null : _scanReceipt,
            icon: _scanning
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.document_scanner_outlined),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 12),
          Center(
            child: IntrinsicWidth(
              child: TextField(
                controller: _amount,
                autofocus: true,
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (_) => setState(() {}),
                style: t.displayLarge?.copyWith(fontSize: 48),
                decoration: const InputDecoration(
                  prefixText: '₹ ',
                  filled: false,
                  border: InputBorder.none,
                  hintText: '0',
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              _value <= 0
                  ? 'Enter an amount'
                  : profile.tracksTime
                      ? '= ${TimeFormat.longForm(minutes, hoursPerDay: profile.hoursPerDay)} of your life'
                      : profile.monthlyMoney > 0
                          ? '= ${(_value / profile.monthlyMoney * 100).toStringAsFixed(1)}% of your monthly budget'
                          : '',
              style: t.titleLarge?.copyWith(color: AppColors.time),
            ),
          ),
          const SizedBox(height: 28),
          Text('Category', style: t.labelSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ExpenseCategory.all.map((c) {
              final active = c.id == _categoryId;
              return ChoiceChip(
                avatar: Icon(c.icon, size: 18),
                label: Text(c.label),
                selected: active,
                onSelected: (_) => _pickCategory(c.id),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          // Need/Want defaults from the category; one tap flips it. The full
          // control (and the note) live under "More options" so the common
          // path is just amount + category.
          _NeedWantChip(isWant: isWant, onTap: () => _setNeedWant(
              isWant ? NeedWant.need : NeedWant.want)),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => setState(() => _showMore = !_showMore),
              icon: Icon(_showMore ? Icons.expand_less : Icons.expand_more,
                  size: 20),
              label: Text(_showMore ? 'Fewer options' : 'More options'),
            ),
          ),
          // Kept out of the tree when collapsed (not just hidden) so the
          // common path stays amount + category.
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            alignment: Alignment.topCenter,
            child: _showMore
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const FirstTimeTip(
                        id: 'needwant',
                        icon: Icons.balance,
                        title: 'Need or Want?',
                        body:
                            'Tag honestly. Wants can be put on a 24h hold so you decide with a clear head — and reclaim the work-time if you skip.',
                      ),
                      SegmentedButton<NeedWant>(
                        segments: const [
                          ButtonSegment(
                              value: NeedWant.need, label: Text('Need')),
                          ButtonSegment(
                              value: NeedWant.want, label: Text('Want')),
                        ],
                        selected: {_needWant},
                        onSelectionChanged: (s) => _setNeedWant(s.first),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _note,
                        textCapitalization: TextCapitalization.sentences,
                        maxLength: 80,
                        decoration: const InputDecoration(
                          labelText: 'Note (optional)',
                          hintText: 'What was it for?',
                          prefixIcon: Icon(Icons.notes),
                        ),
                      ),
                    ],
                  )
                : const SizedBox(width: double.infinity),
          ),
          const SizedBox(height: 8),
          if (isWant) ...[
            OutlinedButton(
              onPressed: _value > 0 ? () => _commit(hold: true) : null,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
              child: const Text('Hold 24h — think it over'),
            ),
            const SizedBox(height: 12),
          ],
          FilledButton(
            onPressed: _value > 0 ? () => _commit(hold: false) : null,
            child: Text(isWant ? 'Buy now' : 'Save'),
          ),
        ],
      ),
    );
  }
}

/// Compact need/want indicator that flips on tap — replaces the always-visible
/// SegmentedButton in the common path.
class _NeedWantChip extends StatelessWidget {
  final bool isWant;
  final VoidCallback onTap;
  const _NeedWantChip({required this.isWant, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final color = isWant ? AppColors.accent : AppColors.positive;
    return Align(
      alignment: Alignment.centerLeft,
      child: ActionChip(
        avatar: Icon(isWant ? Icons.shopping_bag_outlined : Icons.check_circle_outline,
            size: 18, color: color),
        label: Text(isWant ? 'Want · tap to change' : 'Need · tap to change',
            style: t.bodyMedium),
        onPressed: onTap,
      ),
    );
  }
}
