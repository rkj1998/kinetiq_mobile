import 'dart:convert';
import '../llm/openai_adapter.dart';
import '../tools/tool_registry.dart';

enum StepType { thought, toolCall, toolResult, finalAnswer, error }

class AgentStep {
  final StepType type;
  final String title;
  final String content;

  AgentStep({required this.type, required this.title, required this.content});
}

class ReActAgent {
  final OpenAIAdapter client;
  final ToolRegistry registry;
  final String model;
  final int maxTurns;
  final String? systemPrompt;
  final String? memoryContext;

  ReActAgent({
    required this.client,
    required this.registry,
    this.model = 'llama-3.3-70b-versatile',
    this.maxTurns = 6,
    this.systemPrompt,
    this.memoryContext,
  });

  Stream<AgentStep> run({
    required String userPrompt,
    List<Map<String, dynamic>> history = const [],
  }) async* {
    final messages = <Map<String, dynamic>>[];
    final promptBuffer = StringBuffer();

    if (systemPrompt != null && systemPrompt!.trim().isNotEmpty) {
      promptBuffer.writeln(systemPrompt!.trim());
    }
    if (memoryContext != null && memoryContext!.trim().isNotEmpty) {
      promptBuffer.writeln(memoryContext!.trim());
    }

    // Explicit Tool Calling Directive for open weights models like Qwen, Llama & DeepSeek
    promptBuffer.writeln(
      '\nIMPORTANT INSTRUCTIONS ON TOOLS:\n'
      'You are equipped with real tools (autonomous_cloud_task, web_search, fetch_page_text, python_computer_tool, get_system_time).\n'
      'When the user asks you to search, open a browser, run code, or execute an action, YOU MUST EXECUTE the corresponding tool call.\n'
      'Do not merely print the tool arguments or code block in text if you intended to execute it; call the function directly.\n'
      'Once tool results are returned to you, synthesize them into a concise, direct, helpful answer for the user.'
    );

    if (promptBuffer.isNotEmpty) {
      messages.add({'role': 'system', 'content': promptBuffer.toString().trim()});
    }
    messages.addAll(history);
    messages.add({'role': 'user', 'content': userPrompt});

    final tools = registry.getAllToolSchemas();
    int turns = 0;

    while (turns < maxTurns) {
      turns++;
      yield AgentStep(
        type: StepType.thought,
        title: 'Reasoning',
        content: 'Analyzing state and evaluating tool execution...',
      );

      Map<String, dynamic> responseMessage;
      try {
        responseMessage = await client.sendChatCompletion(
          model: model,
          messages: messages,
          tools: tools,
        );
      } catch (e) {
        final errorMsg = e.toString();
        yield AgentStep(
          type: StepType.error,
          title: 'API Connection Error',
          content: errorMsg,
        );
        yield AgentStep(
          type: StepType.finalAnswer,
          title: 'Error Details',
          content: '⚠️ **Unable to complete request from $model**\n\n'
              'Error: `$errorMsg`\n\n'
              '**Troubleshooting:**\n'
              '• Ensure your PC tunnel or local server is running.\n'
              '• Verify the model `$model` is loaded in Ollama.\n'
              '• Check the live PC terminal logs to see the incoming request.',
        );
        break;
      }

      // 1. Check native OpenAI-compatible tool_calls
      List<dynamic>? toolCalls;
      if (responseMessage.containsKey('tool_calls') &&
          responseMessage['tool_calls'] != null &&
          (responseMessage['tool_calls'] as List).isNotEmpty) {
        toolCalls = responseMessage['tool_calls'] as List;
      }

      // 2. Fallback: Parse markdown or raw JSON tool calls emitted in content by open-weights models (Qwen, Llama, DeepSeek)
      final rawContent = responseMessage['content']?.toString() ?? '';
      if (toolCalls == null || toolCalls.isEmpty) {
        toolCalls = _extractToolCallsFromContent(rawContent, registry);
      }

      if (toolCalls != null && toolCalls.isNotEmpty) {
        messages.add(responseMessage);

        for (var call in toolCalls) {
          final functionName = call['function']['name'] as String;
          final rawArgs = call['function']['arguments'];
          final callId = call['id'] ?? 'call_${DateTime.now().millisecondsSinceEpoch}';

          final Map<String, dynamic> arguments = rawArgs is String
              ? (jsonDecode(rawArgs) as Map<String, dynamic>)
              : (rawArgs is Map<String, dynamic> ? rawArgs : <String, dynamic>{});

          yield AgentStep(
            type: StepType.toolCall,
            title: functionName,
            content: rawArgs is String ? rawArgs : jsonEncode(rawArgs),
          );

          final result = await registry.executeTool(functionName, arguments);

          yield AgentStep(
            type: StepType.toolResult,
            title: '$functionName Result',
            content: result,
          );

          messages.add({
            'role': 'tool',
            'tool_call_id': callId,
            'name': functionName,
            'content': result,
          });
        }
      } else {
        yield AgentStep(
          type: StepType.finalAnswer,
          title: 'Response',
          content: rawContent,
        );
        break;
      }
    }
  }

  /// Extracts function calls from JSON blocks emitted in content by Qwen / Llama / DeepSeek
  static List<dynamic>? _extractToolCallsFromContent(String text, ToolRegistry registry) {
    if (text.isEmpty) return null;
    final validToolNames = registry.getAllToolNames();

    // Check for JSON markdown code blocks: ```json ... ``` or raw { "name": "...", "arguments": ... }
    final jsonRegex = RegExp(r'\{[\s\S]*?"(?:name|action)"[\s\S]*?\}');
    final matches = jsonRegex.allMatches(text);

    for (final match in matches) {
      try {
        final parsed = jsonDecode(match.group(0)!);
        if (parsed is Map<String, dynamic>) {
          String? name = parsed['name']?.toString();
          Map<String, dynamic>? arguments;

          if (parsed.containsKey('arguments')) {
            final args = parsed['arguments'];
            arguments = args is Map<String, dynamic> ? args : (args is String ? jsonDecode(args) : null);
          } else if (parsed.containsKey('parameters')) {
            final args = parsed['parameters'];
            arguments = args is Map<String, dynamic> ? args : null;
          }

          // If the model output { "name": "autonomous_cloud_task", "arguments": { ... } }
          if (name != null && validToolNames.contains(name)) {
            return [
              {
                'id': 'call_${DateTime.now().millisecondsSinceEpoch}',
                'type': 'function',
                'function': {
                  'name': name,
                  'arguments': arguments ?? <String, dynamic>{},
                },
              }
            ];
          }
        }
      } catch (_) {}
    }

    return null;
  }
}
