import 'package:flutter/material.dart';
import '../models/agent_character.dart';
import 'agent_avatar.dart';

class CharacterSelectorSheet extends StatelessWidget {
  final AgentCharacter currentCharacter;
  final ValueChanged<AgentCharacter> onCharacterSelected;

  const CharacterSelectorSheet({
    super.key,
    required this.currentCharacter,
    required this.onCharacterSelected,
  });

  static void show(
    BuildContext context, {
    required AgentCharacter currentCharacter,
    required ValueChanged<AgentCharacter> onCharacterSelected,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => CharacterSelectorSheet(
        currentCharacter: currentCharacter,
        onCharacterSelected: onCharacterSelected,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      decoration: const BoxDecoration(
        color: Color(0xFF10131F),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(top: BorderSide(color: Color(0xFF23283B), width: 1.5)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.face_retouching_natural, color: Color(0xFF8B5CF6), size: 24),
              const SizedBox(width: 10),
              const Text(
                'Choose Your AI Persona',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close, size: 20, color: Colors.grey),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Each persona features custom neural tuning, reasoning styles, and avatar reactive animations.',
            style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
          ),
          const SizedBox(height: 20),
          ...AgentCharacter.presets.map((character) {
            final isSelected = character.id == currentCharacter.id;
            return GestureDetector(
              onTap: () {
                onCharacterSelected(character);
                Navigator.pop(context);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF1E2235) : const Color(0xFF141724),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isSelected ? character.primaryColor : const Color(0xFF222638),
                    width: isSelected ? 2 : 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: character.glowColor.withValues(alpha: 0.25),
                            blurRadius: 16,
                            spreadRadius: 1,
                          ),
                        ]
                      : [],
                ),
                child: Row(
                  children: [
                    AgentAvatar(
                      character: character,
                      size: 46,
                      mood: isSelected ? AgentMood.thinking : AgentMood.idle,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                character.name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: character.primaryColor.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  character.tag,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: character.glowColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            character.role,
                            style: const TextStyle(fontSize: 12, color: Color(0xFFCBD5E1)),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            character.description,
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    if (isSelected)
                      Icon(Icons.check_circle_rounded, color: character.glowColor, size: 22),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
