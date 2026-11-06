import 'package:dio/dio.dart';

class OpenAIAdapter {
  final Dio _dio = Dio();
  final String apiKey;
  final String baseUrl;

  OpenAIAdapter({
    required this.apiKey,
    this.baseUrl = 'https://api.groq.com/openai/v1',
  });

  /// Fetches the list of models dynamically from either OpenAI/Groq or Ollama endpoints.
  Future<List<String>> fetchAvailableModels() async {
    // Standardize URL: strip trailing slash
    final cleanBase = baseUrl.trim().replaceAll(RegExp(r'/+$'), '');

    // Common headers
    final headers = {
      if (apiKey.isNotEmpty && apiKey != 'ollama') 'Authorization': 'Bearer $apiKey',
      'Content-Type': 'application/json',
      'User-Agent': 'Kinetiq-Mobile/1.0',
    };

    // 1. Try standard OpenAI compatible /models endpoint (e.g. /v1/models or host/models)
    try {
      final modelsUrl = cleanBase.endsWith('/v1') ? '$cleanBase/models' : '$cleanBase/v1/models';
      final response = await _dio.get(
        modelsUrl,
        options: Options(
          headers: headers,
          sendTimeout: const Duration(seconds: 6),
          receiveTimeout: const Duration(seconds: 6),
        ),
      );
      if (response.data is Map && response.data['data'] is List) {
        final list = response.data['data'] as List;
        final ids = list
            .map((m) => m['id']?.toString() ?? '')
            .where((id) => id.isNotEmpty)
            .toList();
        if (ids.isNotEmpty) return ids;
      }
    } catch (_) {}

    // 2. Try cleanBase/models (in case cleanBase didn't have /v1)
    try {
      final response = await _dio.get(
        '$cleanBase/models',
        options: Options(
          headers: headers,
          sendTimeout: const Duration(seconds: 6),
          receiveTimeout: const Duration(seconds: 6),
        ),
      );
      if (response.data is Map && response.data['data'] is List) {
        final list = response.data['data'] as List;
        final ids = list
            .map((m) => m['id']?.toString() ?? '')
            .where((id) => id.isNotEmpty)
            .toList();
        if (ids.isNotEmpty) return ids;
      }
    } catch (_) {}

    // 3. Try Ollama native /api/tags endpoint on root host
    try {
      final hostRoot = cleanBase.replaceAll(RegExp(r'/v1/?$'), '');
      final ollamaTagsResp = await _dio.get(
        '$hostRoot/api/tags',
        options: Options(
          headers: headers,
          sendTimeout: const Duration(seconds: 6),
          receiveTimeout: const Duration(seconds: 6),
        ),
      );
      if (ollamaTagsResp.data is Map && ollamaTagsResp.data['models'] is List) {
        final list = ollamaTagsResp.data['models'] as List;
        final names = list
            .map((m) => m['name']?.toString() ?? '')
            .where((name) => name.isNotEmpty)
            .toList();
        if (names.isNotEmpty) return names;
      }
    } catch (_) {}

    return [];
  }

  Future<Map<String, dynamic>> sendChatCompletion({
    required String model,
    required List<Map<String, dynamic>> messages,
    List<Map<String, dynamic>>? tools,
  }) async {
    final cleanBase = baseUrl.trim().replaceAll(RegExp(r'/+$'), '');
    final endpointUrl = cleanBase.endsWith('/chat/completions')
        ? cleanBase
        : (cleanBase.endsWith('/v1') ? '$cleanBase/chat/completions' : '$cleanBase/v1/chat/completions');

    final payload = {
      'model': model,
      'messages': messages,
      if (tools != null && tools.isNotEmpty) 'tools': tools,
      'tool_choice': 'auto',
    };

    final response = await _dio.post(
      endpointUrl,
      data: payload,
      options: Options(
        headers: {
          if (apiKey.isNotEmpty && apiKey != 'ollama') 'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
          'User-Agent': 'Kinetiq-Mobile/1.0',
        },
      ),
    );

    return response.data['choices'][0]['message'] as Map<String, dynamic>;
  }
}
