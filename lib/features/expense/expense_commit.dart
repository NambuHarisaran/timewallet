import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/time/duration_format.dart';
import '../../data/models/expense.dart';
import '../../state/app_providers.dart';
import '../../widgets/celebrate.dart';

/// One shared commit path for the full Add-expense screen and the quick-add
/// sheet (mirrors the showAddGoalSheet precedent — one copy of the offline-safe
/// write, first-spend celebration and Undo so they can't drift).
///
/// Mood is always [Mood.neutral] here: it left the capture form (X2) and is now
/// gathered later in the weekly review. The model field is kept so the review
/// can write it back.
void commitExpense(
  BuildContext context,
  WidgetRef ref, {
  required double amount,
  required String categoryId,
  required NeedWant needWant,
  required bool hold,
  String note = '',
}) {
  if (amount <= 0) return;
  final profile = ref.read(profileOrDefaultProvider);
  final minutes = profile.engine.minutesFor(amount);

  final isFirstSpend =
      (ref.read(expensesProvider).asData?.value ?? const []).isEmpty;

  // NOT awaited (offline-first writes only ack after sync) — but a genuine
  // failure, e.g. a rules rejection, surfaces on the app messenger (U5).
  final appMessenger = ScaffoldMessenger.of(context);
  final actions = ref.read(appActionsProvider);
  final r = actions.addExpenseTracked(
    amount: amount,
    categoryId: categoryId,
    mood: Mood.neutral,
    needWant: needWant,
    timeCostMinutes: minutes,
    hold: hold,
    note: note,
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
            ? "That's ${(amount / profile.monthlyMoney * 100).toStringAsFixed(1)}% of your month — your first spend, logged."
            : 'Your first spend, logged.';
    messenger.showSnackBar(
      SnackBar(content: Text(reframe), duration: const Duration(seconds: 4)),
    );
  } else {
    // Mistakes shouldn't force a trip to the ledger — instant Undo.
    final label = profile.tracksTime && minutes > 0
        ? 'Added ₹${amount.toStringAsFixed(0)} — ${TimeFormat.hm(minutes, hoursPerDay: profile.hoursPerDay)} of life'
        : 'Added ₹${amount.toStringAsFixed(0)}';
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
