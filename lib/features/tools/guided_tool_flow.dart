import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../widgets/entrance.dart';
import '../../widgets/responsive_body.dart';
import '../../widgets/section_card.dart';

/// One step of a guided tool: a plain-language question, the input control
/// that answers it, and a short summary of the current answer for the chips
/// on the result page.
class ToolQuestion {
  final String question;
  final String? help;

  /// Short name shown on the result-page chip (e.g. "Monthly").
  final String label;

  /// Current answer as display text (e.g. "₹5,000").
  final String answer;
  final Widget input;

  const ToolQuestion({
    required this.question,
    this.help,
    required this.label,
    required this.answer,
    required this.input,
  });
}

/// Typeform-style wrapper used by the Plan-tab tools: asks one question per
/// screen, then shows ONLY the output (big number, chart). Every answer stays
/// editable through chips on the result page, so returning users can tweak a
/// single input without re-running the whole flow.
///
/// [embedded] drops the Scaffold/AppBar and renders as a plain Column with the
/// buttons inline — for hosts that already scroll and have their own chrome
/// (e.g. the debt engine's tab view).
class GuidedToolFlow extends StatefulWidget {
  final String title;
  final Color accent;
  final List<ToolQuestion> questions;

  /// Output-only widgets shown once every question is answered.
  final List<Widget> results;
  final bool embedded;

  const GuidedToolFlow({
    super.key,
    this.title = '',
    required this.questions,
    required this.results,
    this.accent = AppColors.accent,
    this.embedded = false,
  });

  @override
  State<GuidedToolFlow> createState() => _GuidedToolFlowState();
}

class _GuidedToolFlowState extends State<GuidedToolFlow> {
  int _step = 0;

  /// Set when a chip on the result page jumped back to one question — the
  /// primary button then returns straight to the result instead of walking
  /// through the remaining questions again.
  bool _editing = false;

  bool get _onResult => _step >= widget.questions.length;

  void _next() {
    setState(() {
      _step = _editing ? widget.questions.length : _step + 1;
      _editing = false;
    });
  }

  void _back() {
    setState(() {
      if (_editing) {
        _step = widget.questions.length;
        _editing = false;
      } else if (_step > 0) {
        _step--;
      }
    });
  }

  void _edit(int i) => setState(() {
        _step = i;
        _editing = true;
      });

  void _startOver() => setState(() {
        _step = 0;
        _editing = false;
      });

  @override
  Widget build(BuildContext context) {
    final content = AnimatedSwitcher(
      duration: Motion.base,
      switchInCurve: Motion.emphasized,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, a) => FadeTransition(
        opacity: a,
        child: SlideTransition(
          position: Tween(begin: const Offset(0, 0.03), end: Offset.zero)
              .animate(a),
          child: child,
        ),
      ),
      child: KeyedSubtree(
        key: ValueKey(_onResult ? 'result' : 'q$_step'),
        child: _onResult ? _resultBody(context) : _questionBody(context),
      ),
    );

    if (widget.embedded) return content;

    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      bottomNavigationBar: _onResult ? null : _questionBar(context),
      body: ContentWidth(child: content),
    );
  }

  // ---- Question step -------------------------------------------------------

  Widget _questionBody(BuildContext context) {
    final children = _questionChildren(context);
    if (widget.embedded) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ...children,
          const SizedBox(height: 16),
          _buttonRow(context),
        ],
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      children: children,
    );
  }

  List<Widget> _questionChildren(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final q = widget.questions[_step];
    final n = widget.questions.length;

    return [
      Text(
        n == 1 ? 'ONE QUESTION' : 'QUESTION ${_step + 1} OF $n',
        style: t.labelSmall?.copyWith(
            color: widget.accent,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2),
      ),
      const SizedBox(height: 10),
      ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(
          value: (_step + 1) / (n + 1),
          minHeight: 4,
          backgroundColor: AppColors.border(context),
          valueColor: AlwaysStoppedAnimation(widget.accent),
        ),
      ),
      const SizedBox(height: 24),
      Text(q.question,
          style: t.headlineMedium?.copyWith(fontWeight: FontWeight.w700)),
      if (q.help != null) ...[
        const SizedBox(height: 8),
        Text(q.help!,
            style: t.bodyMedium?.copyWith(color: AppColors.muted(context))),
      ],
      const SizedBox(height: 24),
      SectionCard(child: q.input),
    ];
  }

  Widget _buttonRow(BuildContext context) {
    final last = _step == widget.questions.length - 1;
    return Row(
      children: [
        if (_step > 0 || _editing) ...[
          OutlinedButton(
            style: OutlinedButton.styleFrom(
                minimumSize: const Size(64, 54),
                padding: const EdgeInsets.symmetric(horizontal: 16)),
            onPressed: _back,
            child: const Icon(Icons.arrow_back, size: 20),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: widget.accent,
                minimumSize: const Size.fromHeight(54)),
            onPressed: _next,
            child: Text(_editing
                ? 'Update result'
                : last
                    ? 'See my result'
                    : 'Continue'),
          ),
        ),
      ],
    );
  }

  Widget _questionBar(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: _buttonRow(context),
      ),
    );
  }

  // ---- Result page (output only) -------------------------------------------

  Widget _resultBody(BuildContext context) {
    final children = _resultChildren(context);
    if (widget.embedded) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: children,
    );
  }

  List<Widget> _resultChildren(BuildContext context) {
    final t = Theme.of(context).textTheme;
    var i = 0;
    return [
      for (final r in widget.results) ...[
        Entrance(index: i++, child: r),
        const SizedBox(height: 16),
      ],
      Entrance(
        index: i,
        child: SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('YOUR ANSWERS',
                  style: t.labelSmall?.copyWith(
                      fontWeight: FontWeight.w800, letterSpacing: 1.2)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (var q = 0; q < widget.questions.length; q++)
                    ActionChip(
                      avatar: Icon(Icons.edit, size: 14, color: widget.accent),
                      label: Text(
                          '${widget.questions[q].label} · ${widget.questions[q].answer}'),
                      onPressed: () => _edit(q),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _startOver,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Start over'),
                ),
              ),
            ],
          ),
        ),
      ),
    ];
  }
}
