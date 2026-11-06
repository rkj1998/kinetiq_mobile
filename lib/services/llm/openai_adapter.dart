import 'package:dio/dio.dart';

class OpenAIAdapter {
  final Dio _dio = Dio();
  final String apiKey;
  final String baseUrl;

  OpenAIAdapter({
    required this.apiKey,
    this.baseUrl = 'https://api.groq.com/openai/v1',
  });

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
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
      ),
    );

    return response.data['choices'][0]['message'] as Map<String, dynamic>;
  }
}
