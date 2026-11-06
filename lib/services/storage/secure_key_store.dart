import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../models/agent_memory.dart';
import '../../models/app_theme_config.dart';

class SecureKeyStore {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    wOptions: WindowsOptions(),
  );

  static const String _keyPrefix = 'kinetiq_api_key_';
  static const String _activePersonaKey = 'kinetiq_active_persona';
  static const String _activeEndpointKey = 'kinetiq_active_endpoint';
  static const String _customBaseUrlKey = 'kinetiq_custom_base_url';
  static const String _customModelKey = 'kinetiq_custom_model';

  // New personalization & memory storage keys
  static const String _customAgentNameKey = 'kinetiq_custom_agent_name';
  static const String _customSoulPromptKey = 'kinetiq_custom_soul_prompt';
  static const String _agentMemoryKey = 'kinetiq_agent_memory';
  static const String _autonomousTasksKey = 'kinetiq_autonomous_tasks';
  static const String _themeStyleKey = 'kinetiq_theme_style';
  static const String _themeAccentKey = 'kinetiq_theme_accent';
  static const String _kineticAnimKey = 'kinetiq_kinetic_animations';

  static Future<void> saveApiKey(String endpointId, String apiKey) async {
    await _storage.write(key: '$_keyPrefix$endpointId', value: apiKey);
  }

  static Future<String?> getApiKey(String endpointId) async {
    return await _storage.read(key: '$_keyPrefix$endpointId');
  }

  static Future<void> saveActivePersona(String personaId) async {
    await _storage.write(key: _activePersonaKey, value: personaId);
  }

  static Future<String?> getActivePersona() async {
    return await _storage.read(key: _activePersonaKey);
  }

  static Future<void> saveActiveEndpointId(String endpointId) async {
    await _storage.write(key: _activeEndpointKey, value: endpointId);
  }

  static Future<String?> getActiveEndpointId() async {
    return await _storage.read(key: _activeEndpointKey);
  }

  static Future<void> saveCustomEndpointDetails({
    required String baseUrl,
    required String model,
  }) async {
    await _storage.write(key: _customBaseUrlKey, value: baseUrl);
    await _storage.write(key: _customModelKey, value: model);
  }

  static Future<Map<String, String?>> getCustomEndpointDetails() async {
    final url = await _storage.read(key: _customBaseUrlKey);
    final model = await _storage.read(key: _customModelKey);
    return {'baseUrl': url, 'model': model};
  }

  // --- Agent Custom Name & Soul ---
  static Future<void> saveCustomAgentName(String name) async {
    await _storage.write(key: _customAgentNameKey, value: name);
  }

  static Future<String?> getCustomAgentName() async {
    return await _storage.read(key: _customAgentNameKey);
  }

  static Future<void> saveCustomSoulPrompt(String prompt) async {
    await _storage.write(key: _customSoulPromptKey, value: prompt);
  }

  static Future<String?> getCustomSoulPrompt() async {
    return await _storage.read(key: _customSoulPromptKey);
  }

  // --- Persistent Agent Memory & Customer Data ---
  static Future<void> saveAgentMemory(AgentMemory memory) async {
    await _storage.write(key: _agentMemoryKey, value: memory.serialize());
  }

  static Future<AgentMemory> getAgentMemory() async {
    final raw = await _storage.read(key: _agentMemoryKey);
    return AgentMemory.deserialize(raw);
  }

  // --- Grok Bot & Muse Autonomous Tasks Store ---
  static Future<void> saveAutonomousTasks(String serializedTasks) async {
    await _storage.write(key: _autonomousTasksKey, value: serializedTasks);
  }

  static Future<String?> getAutonomousTasks() async {
    return await _storage.read(key: _autonomousTasksKey);
  }

  // --- Themes & Visual Appearance ---
  static Future<void> saveThemeStyle(ThemeStyle style) async {
    await _storage.write(key: _themeStyleKey, value: style.name);
  }

  static Future<ThemeStyle> getThemeStyle() async {
    final val = await _storage.read(key: _themeStyleKey);
    if (val == null) return ThemeStyle.antigravityLight;
    return ThemeStyle.values.firstWhere(
      (s) => s.name == val,
      orElse: () => ThemeStyle.antigravityLight,
    );
  }

  static Future<void> saveThemeAccent(ThemeAccent accent) async {
    await _storage.write(key: _themeAccentKey, value: accent.name);
  }

  static Future<ThemeAccent> getThemeAccent() async {
    final val = await _storage.read(key: _themeAccentKey);
    if (val == null) return ThemeAccent.googleBlue;
    return ThemeAccent.values.firstWhere(
      (a) => a.name == val,
      orElse: () => ThemeAccent.googleBlue,
    );
  }

  static Future<void> saveKineticAnimations(bool enabled) async {
    await _storage.write(key: _kineticAnimKey, value: enabled.toString());
  }

  static Future<bool> getKineticAnimations() async {
    final val = await _storage.read(key: _kineticAnimKey);
    if (val == null) return true;
    return val.toLowerCase() == 'true';
  }
}
