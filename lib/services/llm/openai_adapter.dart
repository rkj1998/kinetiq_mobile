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
    // 1. Try standard OpenAI compatible /models endpoint
    try {
      final response = await _dio.get(
        '$baseUrl/models',
        options: Options(
          headers: {
            if (apiKey.isNotEmpty && apiKey != 'ollama') 'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
          },
          sendTimeout: const Duration(seconds: 4),
          receiveTimeout: const Duration(seconds: 4),
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

    // 2. Try Ollama native /api/tags endpoint
    try {
      final hostRoot = baseUrl.replaceAll(RegExp(r'/v1/?$'), '');
      final ollamaTagsResp = await _dio.get(
        '$hostRoot/api/tags',
        options: Options(
          sendTimeout: const Duration(seconds: 4),
          receiveTimeout: const Duration(seconds: 4),
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
    final payload = {
      'model': model,
      'messages': messages,
      if (tools != null && tools.isNotEmpty) 'tools': tools,
      'tool_choice': 'auto',
    };

    final response = await _dio.post(
      '$baseUrl/chat/completions',
      data: payload,
      options: Options(
        headers: {
          if (apiKey.isNotEmpty && apiKey != 'ollama') 'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
      ),
    );

    return response.data['choices'][0]['message'] as Map<String, dynamic>;
  }
}
