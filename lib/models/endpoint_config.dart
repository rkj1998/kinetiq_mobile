enum EndpointType {
  groq,
  ollama,
  openAi,
  openRouter,
  custom,
}

class EndpointConfig {
  final String id;
  final String name;
  final EndpointType type;
  final String baseUrl;
  final String apiKey;
  final String selectedModel;
  final List<String> availableModels;
  final bool isLocal;

  const EndpointConfig({
    required this.id,
    required this.name,
    required this.type,
    required this.baseUrl,
    required this.apiKey,
    required this.selectedModel,
    required this.availableModels,
    this.isLocal = false,
  });

  EndpointConfig copyWith({
    String? name,
    EndpointType? type,
    String? baseUrl,
    String? apiKey,
    String? selectedModel,
    List<String>? availableModels,
    bool? isLocal,
  }) {
    return EndpointConfig(
      id: id,
      name: name ?? this.name,
      type: type ?? this.type,
      baseUrl: baseUrl ?? this.baseUrl,
      apiKey: apiKey ?? this.apiKey,
      selectedModel: selectedModel ?? this.selectedModel,
      availableModels: availableModels ?? this.availableModels,
      isLocal: isLocal ?? this.isLocal,
    );
  }

  static const defaultPresets = [
    EndpointConfig(
      id: 'groq-cloud',
      name: 'Groq Cloud (Ultra Fast LPU)',
      type: EndpointType.groq,
      baseUrl: 'https://api.groq.com/openai/v1',
      apiKey: '',
      selectedModel: 'openai/gpt-oss-120b',
      availableModels: [
        'openai/gpt-oss-120b',
        'openai/gpt-oss-20b',
        'qwen/qwen3.8-27b',
        'llama-3.3-70b-versatile',
        'llama-3.1-8b-instant',
      ],
      isLocal: false,
    ),
    EndpointConfig(
      id: 'ollama-local',
      name: 'Ollama (Local / Home LAN Server)',
      type: EndpointType.ollama,
      baseUrl: 'http://10.0.2.2:11434/v1', // 10.0.2.2 points to host PC from Android Emulator
      apiKey: 'ollama',
      selectedModel: 'llama3.2:latest',
      availableModels: [
        'llama3.2:latest',
        'qwen2.5-coder:latest',
        'mistral:latest',
        'deepseek-r1:latest',
      ],
      isLocal: true,
    ),
    EndpointConfig(
      id: 'openrouter',
      name: 'OpenRouter (Omni-Model Hub)',
      type: EndpointType.openRouter,
      baseUrl: 'https://openrouter.ai/api/v1',
      apiKey: '',
      selectedModel: 'anthropic/claude-3.5-sonnet',
      availableModels: [
        'anthropic/claude-3.5-sonnet',
        'google/gemini-2.0-flash-exp:free',
        'deepseek/deepseek-chat',
        'meta-llama/llama-3.3-70b-instruct',
      ],
      isLocal: false,
    ),
  ];
}
