import 'package:flutter/material.dart';

enum AgentMood { idle, thinking, executing, speaking, success, error }

class AgentCharacter {
  final String id;
  final String name;
  final String role;
  final String tag;
  final String description;
  final String avatarSvgSeed;
  final Color primaryColor;
  final Color secondaryColor;
  final Color glowColor;
  final String defaultSystemPrompt;

  const AgentCharacter({
    required this.id,
    required this.name,
    required this.role,
    required this.tag,
    required this.description,
    required this.avatarSvgSeed,
    required this.primaryColor,
    required this.secondaryColor,
    required this.glowColor,
    required this.defaultSystemPrompt,
  });

  static const List<AgentCharacter> presets = [
    AgentCharacter(
      id: 'muse',
      name: 'Muse',
      role: 'Creative & Autonomous Navigator',
      tag: 'Hyper-Creative',
      description: 'Futuristic hyper-agent equipped with interactive browsing, intuitive web reasoning, and visual artistry.',
      avatarSvgSeed: 'muse-cyber',
      primaryColor: Color(0xFF8B5CF6),
      secondaryColor: Color(0xFFEC4899),
      glowColor: Color(0xFFD946EF),
      defaultSystemPrompt: 'You are Muse, an ultra-fast, intuitive next-gen autonomous AI agent. You think step-by-step, use available tools when needed, browse websites dynamically, and deliver clear, aesthetic, and concise responses.',
    ),
    AgentCharacter(
      id: 'titan',
      name: 'Titan',
      role: 'Heavy Systems & Code Architect',
      tag: 'Deep Reasoning',
      description: 'Deep analytical intelligence built for engineering, architecture, code synthesis, and deep research.',
      avatarSvgSeed: 'titan-core',
      primaryColor: Color(0xFF3B82F6),
      secondaryColor: Color(0xFF06B6D4),
      glowColor: Color(0xFF60A5FA),
      defaultSystemPrompt: 'You are Titan, a master software engineer and systems architect. You prioritize precision, structural elegance, complete code solutions, and rigorous logical verification.',
    ),
    AgentCharacter(
      id: 'cipher',
      name: 'Cipher',
      role: 'Cyber Scout & Open Web Crawler',
      tag: 'Autonomous Scout',
      description: 'Rapid reconnaissance agent that scourges the web, checks live feeds, verifies sources, and breaks down raw data.',
      avatarSvgSeed: 'cipher-neon',
      primaryColor: Color(0xFF10B981),
      secondaryColor: Color(0xFF14B8A6),
      glowColor: Color(0xFF34D399),
      defaultSystemPrompt: 'You are Cipher, an agile web researcher and cyber scout. Always leverage search and page-reading tools to verify facts, cross-examine sources, and surface up-to-the-minute real-world intelligence.',
    ),
    AgentCharacter(
      id: 'spark',
      name: 'Spark',
      role: 'Quantum Strategist & Productivity',
      tag: 'High Velocity',
      description: 'Instantaneous action-taker designed for quick workflows, concise briefings, and continuous autonomous assistance.',
      avatarSvgSeed: 'spark-pulse',
      primaryColor: Color(0xFFF59E0B),
      secondaryColor: Color(0xFFEF4444),
      glowColor: Color(0xFFFBBF24),
      defaultSystemPrompt: 'You are Spark, a high-velocity productivity companion. Your communication is crisp, energizing, bulleted, and oriented around rapid execution and direct answers.',
    ),
  ];
}
