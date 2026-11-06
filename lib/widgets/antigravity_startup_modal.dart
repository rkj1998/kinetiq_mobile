import 'package:flutter/material.dart';
import '../models/app_theme_config.dart';
import '../models/agent_character.dart';
import 'agent_avatar.dart';

class AntigravityStartupModal extends StatelessWidget {
  final AppThemeConfig theme;
  final String agentName;
  final AgentCharacter character;
  final VoidCallback onOpenCustomization;

  const AntigravityStartupModal({
    super.key,
    required this.theme,
    required this.agentName,
    required this.character,
    required this.onOpenCustomization,
  });

  static void show(
    BuildContext context, {
    required AppThemeConfig theme,
    required String agentName,
    required AgentCharacter character,
    required VoidCallback onOpenCustomization,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AntigravityStartupModal(
        theme: theme,
        agentName: agentName,
        character: character,
        onOpenCustomization: onOpenCustomization,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final isCompact = media.size.height < 700;
    final avatarSize = isCompact ? 72.0 : 92.0;

    return Container(
      padding: EdgeInsets.fromLTRB(
        24,
        16,
        24,
        media.viewInsets.bottom + (isCompact ? 16 : 28),
      ),
      constraints: BoxConstraints(
        maxHeight: media.size.height * 0.9,
      ),
      decoration: BoxDecoration(
        color: theme.surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border(top: BorderSide(color: theme.borderColor, width: 1.5)),
        boxShadow: theme.subtleShadow,
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
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
              SizedBox(height: isCompact ? 16 : 22),
              // Uniform Bitmoji Bot Avatar with glowing ring
              Center(
                child: AgentAvatar(
                  character: character,
                  size: avatarSize,
                  mood: AgentMood.idle,
                ),
              ),
              SizedBox(height: isCompact ? 14 : 18),
              Text(
                'Welcome to $agentName',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: isCompact ? 20 : 23,
                  fontWeight: FontWeight.w800,
                  color: theme.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Google & Apple simplicity meets autonomous AI edge reasoning.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: isCompact ? 12 : 13,
                  color: theme.textSecondary,
                ),
              ),
              SizedBox(height: isCompact ? 16 : 22),
              _buildFeatureRow(
                icon: Icons.psychology_outlined,
                title: 'Autonomous ReAct Reasoning',
                desc: 'Thinks, decides, searches the live web, and executes tools directly.',
                isCompact: isCompact,
              ),
              SizedBox(height: isCompact ? 10 : 14),
              _buildFeatureRow(
                icon: Icons.shield_outlined,
                title: 'Private Keystore & Local Memory',
                desc: 'Remembers your preferences and encrypts API keys on device.',
                isCompact: isCompact,
              ),
              SizedBox(height: isCompact ? 10 : 14),
              _buildFeatureRow(
                icon: Icons.palette_outlined,
                title: 'Tailored Aesthetic & Light/Dark',
                desc: 'From clean Google Antigravity white to deep Obsidian OLED.',
                isCompact: isCompact,
              ),
              SizedBox(height: isCompact ? 20 : 26),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        onOpenCustomization();
                      },
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: isCompact ? 12 : 14),
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
                        padding: EdgeInsets.symmetric(vertical: isCompact ? 12 : 14),
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
      ),
    );
  }

  Widget _buildFeatureRow({
    required IconData icon,
    required String title,
    required String desc,
    bool isCompact = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(isCompact ? 8 : 10),
          decoration: BoxDecoration(
            color: theme.primaryAccent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: theme.primaryAccent, size: isCompact ? 18 : 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: isCompact ? 13 : 14,
                  fontWeight: FontWeight.w700,
                  color: theme.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: TextStyle(fontSize: isCompact ? 11 : 12, color: theme.textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
