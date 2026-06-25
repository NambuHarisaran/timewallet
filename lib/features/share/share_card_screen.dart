import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';

/// Branded shareable "money as time" card. (Export-to-image is a V2 add-on;
/// here we render the card and offer copy-to-clipboard of the headline.)
class ShareCardScreen extends StatefulWidget {
  final String headline;
  const ShareCardScreen({super.key, required this.headline});

  @override
  State<ShareCardScreen> createState() => _ShareCardScreenState();
}

class _ShareCardScreenState extends State<ShareCardScreen> {
  int _style = 0;

  static const _gradients = [
    [Color(0xFF5B8DEF), Color(0xFF2B4C8C)],
    [Color(0xFFFFB454), Color(0xFFB9762A)],
    [Color(0xFF3DD68C), Color(0xFF1E7A4D)],
    [Color(0xFF1C2530), Color(0xFF0B0F14)],
  ];

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
                        Row(
                          children: const [
                            Icon(Icons.access_time,
                                color: Colors.white70, size: 18),
                            SizedBox(width: 6),
                            Text('made with TimeWallet',
                                style: TextStyle(
                                    color: Colors.white70, fontSize: 14)),
                          ],
                        ),
                      ],
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
            FilledButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: widget.headline));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Copied! Paste it anywhere.')),
                );
              },
              icon: const Icon(Icons.copy),
              label: const Text('Copy caption'),
            ),
          ],
        ),
      ),
    );
  }
}
