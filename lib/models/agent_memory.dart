import 'dart:convert';

class MemoryFact {
  final String id;
  final String text;
  final String category;
  final int timestampMillis;

  const MemoryFact({
    required this.id,
    required this.text,
    this.category = 'General',
    this.timestampMillis = 0,
  });

  DateTime get createdAt => DateTime.fromMillisecondsSinceEpoch(timestampMillis);

  Map<String, dynamic> toJson() => {
    'id': id,
    'text': text,
    'category': category,
    'timestampMillis': timestampMillis,
  };

  factory MemoryFact.fromJson(Map<String, dynamic> json) => MemoryFact(
    id: json['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
    text: json['text'] as String? ?? '',
    category: json['category'] as String? ?? 'General',
    timestampMillis: json['timestampMillis'] as int? ?? 0,
  );
}

class AgentMemory {
  final String userName;
  final String userBio;
  final String customInstructions;
  final List<MemoryFact> facts;

  const AgentMemory({
    this.userName = 'Explorer',
    this.userBio = 'AI Technologist and Creator',
    this.customInstructions = 'Provide direct, elegant, and highly structured answers. Format code cleanly and think deeply.',
    this.facts = const [
      MemoryFact(
        id: 'pref-concise',
        text: 'Prefers clean, modern, and production-ready code with no placeholders.',
        category: 'Preferences',
        timestampMillis: 0,
      ),
      MemoryFact(
        id: 'pref-speed',
        text: 'Values high execution velocity, autonomous research, and verified sources.',
        category: 'Workstyle',
        timestampMillis: 0,
      ),
    ],
  });

  AgentMemory copyWith({
    String? userName,
    String? userBio,
    String? customInstructions,
    List<MemoryFact>? facts,
  }) {
    return AgentMemory(
      userName: userName ?? this.userName,
      userBio: userBio ?? this.userBio,
      customInstructions: customInstructions ?? this.customInstructions,
      facts: facts ?? this.facts,
    );
  }

  String toPromptContext() {
    final buffer = StringBuffer();
    buffer.writeln('\n[PERSISTENT AGENT MEMORY & USER CONTEXT]');
    if (userName.isNotEmpty) {
      buffer.writeln('- User Name: $userName');
    }
    if (userBio.isNotEmpty) {
      buffer.writeln('- User Profile: $userBio');
    }
    if (customInstructions.isNotEmpty) {
      buffer.writeln('- Standing Directives: $customInstructions');
    }
    if (facts.isNotEmpty) {
      buffer.writeln('- Remembered Facts:');
      for (final fact in facts) {
        buffer.writeln('  * [${fact.category}] ${fact.text}');
      }
    }
    buffer.writeln('[END OF MEMORY CONTEXT]\n');
    return buffer.toString();
  }

  Map<String, dynamic> toJson() => {
    'userName': userName,
    'userBio': userBio,
    'customInstructions': customInstructions,
    'facts': facts.map((f) => f.toJson()).toList(),
  };

  factory AgentMemory.fromJson(Map<String, dynamic> json) {
    return AgentMemory(
      userName: json['userName'] as String? ?? 'Explorer',
      userBio: json['userBio'] as String? ?? 'AI Technologist and Creator',
      customInstructions: json['customInstructions'] as String? ?? '',
      facts: (json['facts'] as List<dynamic>?)
              ?.map((f) => MemoryFact.fromJson(f as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  String serialize() => jsonEncode(toJson());

  static AgentMemory deserialize(String? raw) {
    if (raw == null || raw.trim().isEmpty) return const AgentMemory();
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return AgentMemory.fromJson(decoded);
    } catch (_) {
      return const AgentMemory();
    }
  }
}
