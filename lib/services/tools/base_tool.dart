abstract class BaseTool {
  String get name;
  String get description;
  Map<String, dynamic> get parametersSchema;

  Map<String, dynamic> toOpenAISchema() {
    return {
      'type': 'function',
      'function': {
        'name': name,
        'description': description,
        'parameters': parametersSchema,
      },
    };
  }

  Future<String> execute(Map<String, dynamic> arguments);
}