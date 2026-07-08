import 'package:flutter/material.dart';

import '../core/util/formatters.dart';
import '../data/models/user_profile.dart';

/// Style palette for the Time Card. Index 0–3 mirror the share-card
/// gradients so the profile card and exported cards speak one visual
/// language; the last two give the builder a little more room to play.
const List<List<Color>> timeCardStyles = [
  [Color(0xFF5B8DEF), Color(0xFF2B4C8C)], // ocean
  [Color(0xFFFFB454), Color(0xFFB9762A)], // amber
  [Color(0xFF3DD68C), Color(0xFF1E7A4D)], // mint
  [Color(0xFF1C2530), Color(0xFF0B0F14)], // charcoal
  [Color(0xFF8B6DEF), Color(0xFF41328C)], // violet
  [Color(0xFFE07A8A), Color(0xFF7A2B3C)], // rose
];

/// The user's self-designed identity card (IKEA effect): built during
/// onboarding, then lives at the top of Profile. Bank-card layout — brand
/// row up top, the money-as-time hero in the middle, owner name embossed
/// along the bottom. White text on every gradient by design.
class TimeCard extends StatelessWidget {
  final UserProfile profile;

  /// Overrides the saved style while the user is still designing.
  final int? style;

  const TimeCard({super.key, required this.profile, this.style});

  static const _personaTitle = {
    Persona.student: 'Student',
    Persona.freelancer: 'Freelancer',
    Persona.employee: 'Employee',
    Persona.owner: 'Business owner',
  };

  @override
  Widget build(BuildContext context) {
    final colors =
        timeCardStyles[(style ?? profile.cardStyle) % timeCardStyles.length];
    final fmt = moneyFmt;
    final tracksTime = profile.tracksTime;

    return AspectRatio(
      aspectRatio: 16 / 10,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: colors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.hourglass_bottom, size: 22, color: Colors.white),
                Spacer(),
                Text(
                  'TimeWallet',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              tracksTime ? 'MY TIME IS WORTH' : 'MY MONTHLY BUDGET',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                tracksTime
                    ? '${fmt.format(profile.effectiveHourlyRate)} / hour'
                    : '${fmt.format(profile.monthlyMoney)} / month',
                maxLines: 1,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                ),
              ),
            ),
            const Spacer(),
            // Embossed owner line, bank-card style.
            Text(
              (profile.name.isNotEmpty ? profile.name : 'Time Owner')
                  .toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.6,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              [
                _personaTitle[profile.persona]!,
                if (profile.age > 0) '${profile.age}',
              ].join(' · '),
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tappable swatch row for picking a Time Card style — shared by the
/// onboarding card-builder step and Edit profile so the card stays the
/// user's to change (the IKEA artifact must remain owned, not frozen).
class TimeCardStylePicker extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onSelected;

  const TimeCardStylePicker({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(timeCardStyles.length, (i) {
        final active = i == selected % timeCardStyles.length;
        return GestureDetector(
          onTap: () => onSelected(i),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 5),
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: timeCardStyles[i]),
              shape: BoxShape.circle,
              border: Border.all(
                color: active ? Theme.of(context).colorScheme.primary
                    : Colors.transparent,
                width: 2,
              ),
            ),
            child: active
                ? const Icon(Icons.check, size: 16, color: Colors.white)
                : null,
          ),
        );
      }),
    );
  }
}
