import 'base_tool.dart';

class ToolRegistry {
  final Map<String, BaseTool> _registeredTools = {};

  void registerTool(BaseTool tool) {
    _registeredTools[tool.name] = tool;
  }

  List<Map<String, dynamic>> getAllToolSchemas() {
    return _registeredTools.values.map((t) => t.toOpenAISchema()).toList();
  }

  Set<String> getAllToolNames() {
    return _registeredTools.keys.toSet();
  }

  Future<String> executeTool(String name, Map<String, dynamic> arguments) async {
    final tool = _registeredTools[name];
    if (tool == null) {
      return 'Error: Tool "$name" not found.';
    }
    try {
      return await tool.execute(arguments);
    } catch (e) {
      return 'Error executing tool "$name": $e';
    }
  }
}
