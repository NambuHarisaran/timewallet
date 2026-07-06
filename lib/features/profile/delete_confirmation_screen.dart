import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_colors.dart';
import '../../widgets/responsive_body.dart';
import '../../widgets/section_card.dart';

class DeleteConfirmationScreen extends StatelessWidget {
  const DeleteConfirmationScreen({super.key});

  Future<void> _proceedToDeletion(BuildContext context) async {
    final url = Uri.parse('https://www.aqro.in/timewallet/delete-account');
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(
          url,
          mode: LaunchMode.externalApplication,
        );
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open deletion page in browser.')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error launching page: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Delete Account'),
        elevation: 0,
      ),
      body: ContentWidth(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(),
              Icon(
                Icons.warning_amber_rounded,
                size: 80,
                color: AppColors.warn,
              ),
              const SizedBox(height: 24),
              Text(
                'Delete your TimeWallet account?',
                style: t.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Deleting your account is permanent. All your settings, logged work hours, goals, and expense histories will be permanently removed.',
                style: t.bodyMedium?.copyWith(
                  height: 1.5,
                  color: AppColors.muted(context),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SectionCard(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: AppColors.accent),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          'You will be redirected to the secure aqrostudios web portal to confirm and complete your account deletion request.',
                          style: t.bodyMedium?.copyWith(
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(flex: 2),
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.warn,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => _proceedToDeletion(context),
                    child: const Text(
                      'Proceed to Deletion',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      'Cancel and Keep Account',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.text(context),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
