import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../services/share_service.dart';
import '../../state/app_providers.dart';

/// Branded shareable "money as time" card. The card is rasterised via
/// RepaintBoundary and shared as a PNG (Android share sheet / web download),
/// carrying the "Tracked by TimeWallet" badge into every export.
class ShareCardScreen extends ConsumerStatefulWidget {
  final String headline;
  const ShareCardScreen({super.key, required this.headline});

  @override
  ConsumerState<ShareCardScreen> createState() => _ShareCardScreenState();
}

class _ShareCardScreenState extends ConsumerState<ShareCardScreen> {
  final GlobalKey _cardKey = GlobalKey();
  int _style = 0;
  bool _sharing = false;

  static const _gradients = [
    [Color(0xFF5B8DEF), Color(0xFF2B4C8C)],
    [Color(0xFFFFB454), Color(0xFFB9762A)],
    [Color(0xFF3DD68C), Color(0xFF1E7A4D)],
    [Color(0xFF1C2530), Color(0xFF0B0F14)],
  ];

  Future<void> _shareAsImage() async {
    setState(() => _sharing = true);
    String? message;
    try {
      final bytes = await ShareService.capturePng(_cardKey);
      if (bytes == null) {
        message = 'Could not render the card — try again.';
      } else {
        ref.read(analyticsServiceProvider).shareImage();
        message = await ShareService.shareImage(bytes,
            caption: '${widget.headline} — tracked by TimeWallet');
      }
    } catch (_) {
      message = 'Sharing failed — try again.';
    } finally {
      if (mounted) {
        setState(() => _sharing = false);
        if (message != null) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(message)));
        }
      }
    }
  }

  void _copyCaption() {
    Clipboard.setData(ClipboardData(
        text: '${widget.headline} — tracked by TimeWallet'));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copied! Paste it anywhere.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final g = _gradients[_style];
    return Scaffold(
      appBar: AppBar(title: const Text('Share as time')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: AspectRatio(
                  aspectRatio: 4 / 5,
                  // The boundary is what gets exported — card only, no chrome.
                  child: RepaintBoundary(
                    key: _cardKey,
                    child: Container(
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: g,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.hourglass_bottom,
                              size: 40, color: Colors.white),
                          const Spacer(),
                          Text(
                            widget.headline,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 30,
                              fontWeight: FontWeight.w800,
                              height: 1.2,
                            ),
                          ),
                          const Spacer(),
                          const _TrackedBadge(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_gradients.length, (i) {
                final active = i == _style;
                return GestureDetector(
                  onTap: () => setState(() => _style = i),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 5),
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: _gradients[i]),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: active ? AppColors.time : Colors.transparent,
                        width: 2,
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(54)),
                    onPressed: _sharing ? null : _shareAsImage,
                    icon: _sharing
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.ios_share),
                    label: const Text('Share as image'),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                      minimumSize: const Size(54, 54),
                      padding: const EdgeInsets.symmetric(horizontal: 14)),
                  onPressed: _copyCaption,
                  child: const Icon(Icons.copy, size: 20),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// The pill badge baked into every exported card.
class _TrackedBadge extends StatelessWidget {
  const _TrackedBadge();

  @override
  Widget build(BuildContext context) {
    // FittedBox: the badge scales down instead of overflowing when the card
    // renders narrow (small phones, tests).
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.hourglass_bottom, size: 15, color: Colors.white),
            SizedBox(width: 6),
            Text(
              'Tracked by TimeWallet',
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
