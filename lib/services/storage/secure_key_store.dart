import 'package:flutter_secure_storage/flutter_secure_storage.dart';

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
}
