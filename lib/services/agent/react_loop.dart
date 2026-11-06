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

  ReActAgent({
    required this.client,
    required this.registry,
    this.model = 'llama-3.3-70b-versatile',
    this.maxTurns = 5,
  });

  Stream<AgentStep> run({
    required String userPrompt,
    List> history = const [],
  }) async* {
    final messages = List>.from(history);
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
        yield AgentStep(
          type: StepType.error,
          title: 'API Error',
          content: e.toString(),
        );
        break;
      }

      if (responseMessage.containsKey('tool_calls') &&
          responseMessage['tool_calls'] != null) {
        messages.add(responseMessage);

        final toolCalls = responseMessage['tool_calls'] as List;
        for (var call in toolCalls) {
          final functionName = call['function']['name'];
          final rawArgs = call['function']['arguments'];
          final callId = call['id'];

          final Map<String, dynamic> arguments =
              rawArgs is String ? jsonDecode(rawArgs) : (rawArgs ?? {});

          yield AgentStep(
            type: StepType.toolCall,
            title: functionName,
            content: rawArgs.toString(),
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
        final finalContent = responseMessage['content']?.toString() ?? '';
        yield AgentStep(
          type: StepType.finalAnswer,
          title: 'Response',
          content: finalContent,
        );
        break;
      }
    }
  }
}