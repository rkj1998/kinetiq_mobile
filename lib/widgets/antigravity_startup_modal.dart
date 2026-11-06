import 'package:flutter/material.dart';
import '../models/app_theme_config.dart';
import 'antigravity_logo.dart';

class AntigravityStartupModal extends StatelessWidget {
  final AppThemeConfig theme;
  final String agentName;
  final VoidCallback onOpenCustomization;

  const AntigravityStartupModal({
    super.key,
    required this.theme,
    required this.agentName,
    required this.onOpenCustomization,
  });

  static void show(
    BuildContext context, {
    required AppThemeConfig theme,
    required String agentName,
    required VoidCallback onOpenCustomization,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AntigravityStartupModal(
        theme: theme,
        agentName: agentName,
        onOpenCustomization: onOpenCustomization,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: BoxDecoration(
        color: theme.surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border(top: BorderSide(color: theme.borderColor, width: 1.5)),
        boxShadow: theme.subtleShadow,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: theme.textSecondary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(height: 24),
            AntigravityLogo(
              size: 100,
              theme: theme,
            ),
            const SizedBox(height: 20),
            Text(
              'Welcome to $agentName',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: theme.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Google & Apple simplicity meets autonomous AI edge reasoning.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: theme.textSecondary),
            ),
            const SizedBox(height: 24),
            _buildFeatureRow(
              icon: Icons.psychology_outlined,
              title: 'Autonomous ReAct Reasoning',
              desc: 'Thinks, decides, searches the live web, and executes tools directly.',
            ),
            const SizedBox(height: 14),
            _buildFeatureRow(
              icon: Icons.shield_outlined,
              title: 'Private Keystore & Local Memory',
              desc: 'Remembers your preferences and encrypts API keys on device.',
            ),
            const SizedBox(height: 14),
            _buildFeatureRow(
              icon: Icons.palette_outlined,
              title: 'Tailored Aesthetic & Light/Dark',
              desc: 'From clean Google Antigravity white to deep Obsidian OLED.',
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      onOpenCustomization();
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: theme.primaryAccent),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      'Customize',
                      style: TextStyle(
                        color: theme.primaryAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: theme.primaryAccent,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Start Exploring',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureRow({
    required IconData icon,
    required String title,
    required String desc,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: theme.primaryAccent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: theme.primaryAccent, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: theme.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: TextStyle(fontSize: 12, color: theme.textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
