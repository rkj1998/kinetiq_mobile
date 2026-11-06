import 'package:flutter_test/flutter_test.dart';
import 'package:kinetiq_mobile/services/agent/react_loop.dart';
import 'package:kinetiq_mobile/services/tools/tool_registry.dart';
import 'package:kinetiq_mobile/services/tools/web_tools.dart';
import 'package:kinetiq_mobile/services/tools/autonomous_cloud_vm_tool.dart';

void main() {
  group('ReAct Content Tool Parser Tests', () {
    late ToolRegistry registry;

    setUp(() {
      registry = ToolRegistry()
        ..registerTool(WebSearchTool())
        ..registerTool(AutonomousCloudVMTool());
    });

    test('extracts nested JSON tool call from user screenshot', () {
      const userOutput =
          '{"name": "web_search", "arguments": {"query": "software engineer jobs near me"}}';

      final toolCalls = ReActAgent.extractToolCallsFromContent(userOutput, registry);
      expect(toolCalls, isNotNull);
      expect(toolCalls!.length, 1);
      expect(toolCalls.first['function']['name'], 'web_search');
      expect(toolCalls.first['function']['arguments']['query'], 'software engineer jobs near me');
    });

    test('extracts nested JSON with code block markdown formatting', () {
      const userOutput =
          '```json\n{"name": "autonomous_cloud_task", "arguments": {"action": "browse_and_extract", "targetUrl": "https://indeed.com", "taskDescription": "Search jobs", "requiresApproval": false}}\n```';

      final toolCalls = ReActAgent.extractToolCallsFromContent(userOutput, registry);
      expect(toolCalls, isNotNull);
      expect(toolCalls!.length, 1);
      expect(toolCalls.first['function']['name'], 'autonomous_cloud_task');
      expect(toolCalls.first['function']['arguments']['action'], 'browse_and_extract');
      expect(toolCalls.first['function']['arguments']['targetUrl'], 'https://indeed.com');
    });

    test('returns null when text is ordinary conversation', () {
      const normalText = 'Hello! I can help you search for jobs today.';
      final toolCalls = ReActAgent.extractToolCallsFromContent(normalText, registry);
      expect(toolCalls, isNull);
    });
  });
}
