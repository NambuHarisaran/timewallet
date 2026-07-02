import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/theme/app_colors.dart';
import '../../core/time/duration_format.dart';
import '../../data/models/expense.dart';
import '../../services/receipt_scanner.dart';
import '../../state/app_providers.dart';
import '../../widgets/celebrate.dart';
import '../../widgets/first_time_tip.dart';

class AddExpenseScreen extends ConsumerStatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  ConsumerState<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends ConsumerState<AddExpenseScreen> {
  final _amount = TextEditingController();
  final _note = TextEditingController();
  String _categoryId = 'food';
  Mood _mood = Mood.neutral;
  NeedWant _needWant = NeedWant.need;
  bool _scanning = false;

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  double get _value => double.tryParse(_amount.text) ?? 0;

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

  void _commit({required bool hold}) {
    final profile = ref.read(profileOrDefaultProvider);
    final minutes = profile.engine.minutesFor(_value);

    // First-ever logged spend is the activation moment — make it land.
    final isFirstSpend =
        (ref.read(expensesProvider).asData?.value ?? const []).isEmpty;

    // NOT awaited (offline-first writes only ack after sync) — but a genuine
    // failure, e.g. a rules rejection, surfaces on the app messenger (U5).
    final appMessenger = ScaffoldMessenger.of(context);
    final actions = ref.read(appActionsProvider);
    final r = actions.addExpenseTracked(
      amount: _value,
      categoryId: _categoryId,
      mood: _mood,
      needWant: _needWant,
      timeCostMinutes: minutes,
      hold: hold,
      note: _note.text,
    );
    r.done.catchError((_) {
      appMessenger.showSnackBar(const SnackBar(
          content: Text(
              "Couldn't save that expense — check your connection and try again.")));
    });
    HapticFeedback.mediumImpact();

    // Capture the app-level messenger/navigator before popping. ScaffoldMessenger
    // is provided by MaterialApp (above the Navigator), so it outlives this route.
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    if (isFirstSpend && !hold) {
      // Confetti goes into the root overlay, so it keeps playing over the
      // dashboard after this screen pops. Fire it while context is still valid.
      celebrate(context);
    }

    navigator.pop(hold);

    if (isFirstSpend && !hold) {
      final reframe = profile.tracksTime
          ? "That's ${TimeFormat.longForm(minutes, hoursPerDay: profile.hoursPerDay)} of your life — your first spend, in hours."
          : profile.monthlyMoney > 0
              ? "That's ${(_value / profile.monthlyMoney * 100).toStringAsFixed(1)}% of your month — your first spend, logged."
              : 'Your first spend, logged.';
      messenger.showSnackBar(
        SnackBar(content: Text(reframe), duration: const Duration(seconds: 4)),
      );
    } else {
      // Mistakes shouldn't force a trip to the ledger — instant Undo.
      final label = profile.tracksTime && minutes > 0
          ? 'Added ₹${_value.toStringAsFixed(0)} — ${TimeFormat.hm(minutes, hoursPerDay: profile.hoursPerDay)} of life'
          : 'Added ₹${_value.toStringAsFixed(0)}';
      messenger.showSnackBar(SnackBar(
        content: Text(hold ? 'On hold for 24h — decide tomorrow.' : label),
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () => actions.deleteExpense(r.expense.id),
        ),
      ));
    }
  }

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
                onSelected: (_) => setState(() => _categoryId = c.id),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          Text('How do you feel?', style: t.labelSmall),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _moodChip(Mood.good, Icons.sentiment_satisfied_alt),
              _moodChip(Mood.neutral, Icons.sentiment_neutral),
              _moodChip(Mood.bad, Icons.sentiment_very_dissatisfied),
            ],
          ),
          const SizedBox(height: 20),
          const FirstTimeTip(
            id: 'needwant',
            icon: Icons.balance,
            title: 'Need or Want?',
            body:
                'Tag honestly. Wants can be put on a 24h hold so you decide with a clear head — and reclaim the work-time if you skip.',
          ),
          SegmentedButton<NeedWant>(
            segments: const [
              ButtonSegment(value: NeedWant.need, label: Text('Need')),
              ButtonSegment(value: NeedWant.want, label: Text('Want')),
            ],
            selected: {_needWant},
            onSelectionChanged: (s) => setState(() => _needWant = s.first),
          ),
          const SizedBox(height: 20),
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
          const SizedBox(height: 16),
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

  static const _moodLabels = {
    Mood.good: 'Feels good',
    Mood.neutral: 'Feels neutral',
    Mood.bad: 'Feels bad',
  };

  Widget _moodChip(Mood m, IconData icon) {
    final active = m == _mood;
    // Semantics: raw GestureDetector circles are invisible to screen readers;
    // announce as a selectable button (U2).
    return Semantics(
      button: true,
      selected: active,
      label: _moodLabels[m],
      child: GestureDetector(
      onTap: () => setState(() => _mood = m),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: active
              ? AppColors.money.withValues(alpha: 0.18)
              : Colors.transparent,
          shape: BoxShape.circle,
          border: Border.all(
            color: active ? AppColors.money : AppColors.border(context),
            width: 2,
          ),
        ),
        child: Icon(icon,
            size: 28,
            color: active ? AppColors.money : AppColors.muted(context)),
      ),
      ),
    );
  }
}
