import 'package:flutter_test/flutter_test.dart';
import 'package:kinetiq_mobile/services/llm/openai_adapter.dart';

void main() {
  group('OpenAIAdapter Tests', () {
    test('instantiates with custom baseUrl and apiKey', () {
      final adapter = OpenAIAdapter(
        apiKey: 'ollama',
        baseUrl: 'http://192.168.1.100:11434/v1',
      );

      expect(adapter.apiKey, 'ollama');
      expect(adapter.baseUrl, 'http://192.168.1.100:11434/v1');
    });

    test('returns empty list gracefully when endpoint is unreachable', () async {
      final adapter = OpenAIAdapter(
        apiKey: 'test-key',
        baseUrl: 'http://127.0.0.1:59999/v1',
      );

      final models = await adapter.fetchAvailableModels();
      expect(models, isEmpty);
    });
  });
}
