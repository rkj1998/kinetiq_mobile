import 'package:flutter_test/flutter_test.dart';
import 'package:kinetiq_mobile/models/agent_memory.dart';
import 'package:kinetiq_mobile/models/agent_character.dart';

void main() {
  group('AgentMemory Tests', () {
    test('serializes and deserializes correctly', () {
      const memory = AgentMemory(
        userName: 'Satoshi',
        userBio: 'Decentralized systems researcher',
        customInstructions: 'Keep answers concise and cryptographic.',
        facts: [
          MemoryFact(
            id: 'fact-1',
            text: 'Specializes in peer-to-peer protocols',
            category: 'Domain',
            timestampMillis: 1000,
          ),
        ],
      );

      final raw = memory.serialize();
      final parsed = AgentMemory.deserialize(raw);

      expect(parsed.userName, 'Satoshi');
      expect(parsed.userBio, 'Decentralized systems researcher');
      expect(parsed.customInstructions, 'Keep answers concise and cryptographic.');
      expect(parsed.facts.length, 1);
      expect(parsed.facts.first.text, 'Specializes in peer-to-peer protocols');
      expect(parsed.facts.first.category, 'Domain');
    });

    test('toPromptContext formats memory blocks for ReAct prompt', () {
      const memory = AgentMemory(
        userName: 'Ada',
        userBio: 'Mathematical programmer',
        facts: [
          MemoryFact(
            id: 'fact-code',
            text: 'Prefers Dart and Kotlin',
            category: 'Coding',
            timestampMillis: 2000,
          ),
        ],
      );

      final contextStr = memory.toPromptContext();
      expect(contextStr, contains('[PERSISTENT AGENT MEMORY & USER CONTEXT]'));
      expect(contextStr, contains('- User Name: Ada'));
      expect(contextStr, contains('- User Profile: Mathematical programmer'));
      expect(contextStr, contains('* [Coding] Prefers Dart and Kotlin'));
      expect(contextStr, contains('[END OF MEMORY CONTEXT]'));
    });
  });

  group('AgentCharacter Tests', () {
    test('contains Antigravity preset as default', () {
      final defaultChar = AgentCharacter.presets.first;
      expect(defaultChar.id, 'antigravity');
      expect(defaultChar.name, 'Antigravity');
      expect(defaultChar.tag, 'Quantum Elegance');
    });

    test('copyWith properly updates custom name and soul', () {
      final defaultChar = AgentCharacter.presets.first;
      final custom = defaultChar.copyWith(
        name: 'Aura-9',
        defaultSystemPrompt: 'You are Aura-9, an autonomous researcher.',
        bitmojiFaceStyle: 'muse',
      );

      expect(custom.name, 'Aura-9');
      expect(custom.defaultSystemPrompt, 'You are Aura-9, an autonomous researcher.');
      expect(custom.bitmojiFaceStyle, 'muse');
      expect(custom.id, defaultChar.id);
    });
  });
}
