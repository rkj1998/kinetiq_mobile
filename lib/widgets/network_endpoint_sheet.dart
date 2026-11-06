import 'package:flutter/material.dart';
import '../models/endpoint_config.dart';
import '../services/storage/secure_key_store.dart';

class NetworkEndpointSheet extends StatefulWidget {
  final EndpointConfig currentConfig;
  final ValueChanged<EndpointConfig> onConfigSaved;

  const NetworkEndpointSheet({
    super.key,
    required this.currentConfig,
    required this.onConfigSaved,
  });

  static void show(
    BuildContext context, {
    required EndpointConfig currentConfig,
    required ValueChanged<EndpointConfig> onConfigSaved,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => NetworkEndpointSheet(
        currentConfig: currentConfig,
        onConfigSaved: onConfigSaved,
      ),
    );
  }

  @override
  State<NetworkEndpointSheet> createState() => _NetworkEndpointSheetState();
}

class _NetworkEndpointSheetState extends State<NetworkEndpointSheet> {
  late TextEditingController _nameController;
  late TextEditingController _urlController;
  late TextEditingController _keyController;
  late TextEditingController _modelController;
  late EndpointType _type;
  late bool _isLocal;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentConfig.name);
    _urlController = TextEditingController(text: widget.currentConfig.baseUrl);
    _keyController = TextEditingController(text: widget.currentConfig.apiKey);
    _modelController = TextEditingController(text: widget.currentConfig.selectedModel);
    _type = widget.currentConfig.type;
    _isLocal = widget.currentConfig.isLocal;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _urlController.dispose();
    _keyController.dispose();
    _modelController.dispose();
    super.dispose();
  }

  void _applyPreset(EndpointConfig preset) async {
    final savedKey = await SecureKeyStore.getApiKey(preset.id);
    setState(() {
      _nameController.text = preset.name;
      _urlController.text = preset.baseUrl;
      _keyController.text = savedKey ?? preset.apiKey;
      _modelController.text = preset.selectedModel;
      _type = preset.type;
      _isLocal = preset.isLocal;
    });
  }

  void _saveAndClose() async {
    final apiKey = _keyController.text.trim();
    final baseUrl = _urlController.text.trim();
    final model = _modelController.text.trim();
    final name = _nameController.text.trim().isNotEmpty ? _nameController.text.trim() : 'Custom Endpoint';

    // Persist to encrypted secure storage on device
    await SecureKeyStore.saveApiKey(widget.currentConfig.id, apiKey);
    await SecureKeyStore.saveActiveEndpointId(widget.currentConfig.id);
    await SecureKeyStore.saveCustomEndpointDetails(baseUrl: baseUrl, model: model);

    final updated = EndpointConfig(
      id: widget.currentConfig.id,
      name: name,
      type: _type,
      baseUrl: baseUrl,
      apiKey: apiKey,
      selectedModel: model,
      availableModels: [model, ...widget.currentConfig.availableModels.toSet()],
      isLocal: _isLocal,
    );
    widget.onConfigSaved(updated);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF10131F),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(top: BorderSide(color: Color(0xFF23283B), width: 1.5)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.hub_rounded, color: Color(0xFF10B981), size: 24),
                const SizedBox(width: 10),
                const Text(
                  'Neural Endpoint & BYOK',
                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, size: 20, color: Colors.grey),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'Connect directly to cloud LLM inference, local LAN servers (Ollama/vLLM), or custom endpoints.',
              style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
            ),
            const SizedBox(height: 16),

            // Quick Preset Chips
            const Text('Quick Providers:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey)),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: EndpointConfig.defaultPresets.map((preset) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ActionChip(
                      backgroundColor: const Color(0xFF1A1E2F),
                      side: const BorderSide(color: Color(0xFF282E47)),
                      avatar: Icon(
                        preset.isLocal ? Icons.lan_rounded : Icons.cloud_done_rounded,
                        size: 16,
                        color: preset.isLocal ? const Color(0xFF10B981) : const Color(0xFF6366F1),
                      ),
                      label: Text(
                        preset.name.split('(').first.trim(),
                        style: const TextStyle(fontSize: 12, color: Colors.white),
                      ),
                      onPressed: () => _applyPreset(preset),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),

            // Base URL Field
            const Text('API Base URL', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey)),
            const SizedBox(height: 6),
            TextField(
              controller: _urlController,
              style: const TextStyle(fontSize: 14, color: Colors.white),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFF161926),
                hintText: 'https://api.groq.com/openai/v1 or http://192.168.1.x:11434/v1',
                hintStyle: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                prefixIcon: const Icon(Icons.link, size: 18, color: Colors.grey),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 12),

            // API Key Field
            const Text('API Key / Token (Blank for local endpoints)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey)),
            const SizedBox(height: 6),
            TextField(
              controller: _keyController,
              obscureText: true,
              style: const TextStyle(fontSize: 14, color: Colors.white),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFF161926),
                hintText: 'gsk_... / sk-... / ollama',
                hintStyle: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                prefixIcon: const Icon(Icons.key_rounded, size: 18, color: Colors.grey),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 12),

            // Model Identifier
            const Text('Model Identifier', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey)),
            const SizedBox(height: 6),
            TextField(
              controller: _modelController,
              style: const TextStyle(fontSize: 14, color: Colors.white),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFF161926),
                hintText: 'openai/gpt-oss-120b, llama3.2:latest, etc.',
                hintStyle: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                prefixIcon: const Icon(Icons.smart_toy_rounded, size: 18, color: Colors.grey),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 20),

            // Save Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.check, color: Colors.white, size: 20),
                label: const Text(
                  'Apply & Connect Neural Endpoint',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15),
                ),
                onPressed: _saveAndClose,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
