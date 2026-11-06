import 'base_tool.dart';

class GetSystemTimeTool extends BaseTool {
  @override
  String get name => 'get_current_time';

  @override
  String get description => 'Returns the current local device ISO timestamp.';

  @override
  Map<String, dynamic> get parametersSchema => {
    'type': 'object',
    'properties': {},
    'required': [],
  };

  @override
  Future<String> execute(Map<String, dynamic> arguments) async {
    return DateTime.now().toIso8601String();
  }
}
