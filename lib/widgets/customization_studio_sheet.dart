import 'package:flutter/material.dart';
import '../models/agent_character.dart';
import '../models/agent_memory.dart';
import '../models/app_theme_config.dart';
import '../models/endpoint_config.dart';
import '../services/storage/secure_key_store.dart';
import '../services/llm/openai_adapter.dart';
import 'agent_avatar.dart';

class CustomizationStudioSheet extends StatefulWidget {
  final AppThemeConfig currentTheme;
  final AgentCharacter currentCharacter;
  final String customAgentName;
  final AgentMemory currentMemory;
  final EndpointConfig currentEndpoint;
  final Function({
    required AppThemeConfig theme,
    required AgentCharacter character,
    required String agentName,
    required AgentMemory memory,
    required EndpointConfig endpoint,
  }) onSave;

  const CustomizationStudioSheet({
    super.key,
    required this.currentTheme,
    required this.currentCharacter,
    required this.customAgentName,
    required this.currentMemory,
    required this.currentEndpoint,
    required this.onSave,
  });

  static void show(
    BuildContext context, {
    required AppThemeConfig currentTheme,
    required AgentCharacter currentCharacter,
    required String customAgentName,
    required AgentMemory currentMemory,
    required EndpointConfig currentEndpoint,
    required Function({
      required AppThemeConfig theme,
      required AgentCharacter character,
      required String agentName,
      required AgentMemory memory,
      required EndpointConfig endpoint,
    }) onSave,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => CustomizationStudioSheet(
        currentTheme: currentTheme,
        currentCharacter: currentCharacter,
        customAgentName: customAgentName,
        currentMemory: currentMemory,
        currentEndpoint: currentEndpoint,
        onSave: onSave,
      ),
    );
  }

  @override
  State<CustomizationStudioSheet> createState() => _CustomizationStudioSheetState();
}

class _CustomizationStudioSheetState extends State<CustomizationStudioSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  late AppThemeConfig _theme;
  late AgentCharacter _character;
  late String _agentName;
  late AgentMemory _memory;
  late EndpointConfig _endpoint;

  late TextEditingController _nameController;
  late TextEditingController _soulPromptController;
  late TextEditingController _userNameController;
  late TextEditingController _userBioController;
  late TextEditingController _newFactController;
  late TextEditingController _endpointUrlController;
  late TextEditingController _apiKeyController;
  late TextEditingController _modelController;

  String _newFactCategory = 'Preferences';
  bool _obscureKey = true;
  bool _isFetchingModels = false;
  List<String> _liveDiscoveredModels = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _theme = widget.currentTheme;
    _character = widget.currentCharacter;
    _agentName = widget.customAgentName.isNotEmpty ? widget.customAgentName : widget.currentCharacter.name;
    _memory = widget.currentMemory;
    _endpoint = widget.currentEndpoint;

    _nameController = TextEditingController(text: _agentName);
    _soulPromptController = TextEditingController(text: _character.defaultSystemPrompt);
    _userNameController = TextEditingController(text: _memory.userName);
    _userBioController = TextEditingController(text: _memory.userBio);
    _newFactController = TextEditingController();
    _endpointUrlController = TextEditingController(text: _endpoint.baseUrl);
    _apiKeyController = TextEditingController(text: _endpoint.apiKey);
    _modelController = TextEditingController(text: _endpoint.selectedModel);
    _liveDiscoveredModels = [];
  }

  Future<void> _fetchLiveModelsFromEndpoint() async {
    final url = _endpointUrlController.text.trim();
    if (url.isEmpty) return;

    setState(() {
      _isFetchingModels = true;
    });

    final adapter = OpenAIAdapter(
      apiKey: _apiKeyController.text.trim(),
      baseUrl: url,
    );

    final models = await adapter.fetchAvailableModels();

    setState(() {
      _isFetchingModels = false;
      if (models.isNotEmpty) {
        _liveDiscoveredModels = models;
        if (!_liveDiscoveredModels.contains(_modelController.text.trim())) {
          _modelController.text = _liveDiscoveredModels.first;
        }
      }
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            models.isNotEmpty
                ? 'Discovered ${models.length} models on your PC: ${models.join(", ")}'
                : 'Could not fetch models. Check IP, port 11434, and firewall/OLLAMA_HOST.',
          ),
          backgroundColor: models.isNotEmpty ? const Color(0xFF059669) : const Color(0xFFEF4444),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _soulPromptController.dispose();
    _userNameController.dispose();
    _userBioController.dispose();
    _newFactController.dispose();
    _endpointUrlController.dispose();
    _apiKeyController.dispose();
    _modelController.dispose();
    super.dispose();
  }

  void _saveAllAndDismiss() async {
    final updatedMemory = _memory.copyWith(
      userName: _userNameController.text.trim(),
      userBio: _userBioController.text.trim(),
    );

    final updatedEndpoint = _endpoint.copyWith(
      baseUrl: _endpointUrlController.text.trim(),
      apiKey: _apiKeyController.text.trim(),
      selectedModel: _modelController.text.trim(),
    );

    final updatedCharacter = _character.copyWith(
      defaultSystemPrompt: _soulPromptController.text.trim(),
    );

    // Persist everything
    await SecureKeyStore.saveThemeStyle(_theme.style);
    await SecureKeyStore.saveThemeAccent(_theme.accent);
    await SecureKeyStore.saveKineticAnimations(_theme.enableKineticAnimations);
    await SecureKeyStore.saveCustomAgentName(_nameController.text.trim());
    await SecureKeyStore.saveActivePersona(_character.id);
    await SecureKeyStore.saveCustomSoulPrompt(_soulPromptController.text.trim());
    await SecureKeyStore.saveCustomBitmojiFace(_character.bitmojiFaceStyle);
    await SecureKeyStore.saveAgentMemory(updatedMemory);
    await SecureKeyStore.saveApiKey(updatedEndpoint.id, updatedEndpoint.apiKey);
    await SecureKeyStore.saveActiveEndpointId(updatedEndpoint.id);

    widget.onSave(
      theme: _theme,
      character: updatedCharacter,
      agentName: _nameController.text.trim(),
      memory: updatedMemory,
      endpoint: updatedEndpoint,
    );

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final height = MediaQuery.of(context).size.height * 0.88;

    return Container(
      height: height,
      padding: EdgeInsets.only(bottom: bottomInset),
      decoration: BoxDecoration(
        color: _theme.surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border(
          top: BorderSide(color: _theme.borderColor, width: 1.5),
        ),
        boxShadow: _theme.subtleShadow,
      ),
      child: Column(
        children: [
          _buildDragHandle(),
          _buildHeaderBar(),
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildIdentityTab(),
                _buildMemoryTab(),
                _buildThemeTab(),
                _buildKeysTab(),
              ],
            ),
          ),
          _buildBottomAction(),
        ],
      ),
    );
  }

  Widget _buildDragHandle() {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 8),
      child: Container(
        width: 44,
        height: 5,
        decoration: BoxDecoration(
          color: _theme.textSecondary.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(3),
        ),
      ),
    );
  }

  Widget _buildHeaderBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Row(
        children: [
          AgentAvatar(
            character: _character,
            size: 38,
            mood: AgentMood.idle,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Customization Studio',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: _theme.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
                Text(
                  'Personalize soul, memory, look & neural keys',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: _theme.textSecondary),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.close_rounded, color: _theme.textSecondary),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: _theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _theme.borderColor),
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        dividerColor: Colors.transparent,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          color: _theme.primaryAccent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: _theme.primaryAccent.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        labelColor: Colors.white,
        unselectedLabelColor: _theme.textSecondary,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        tabs: const [
          Tab(icon: Icon(Icons.auto_awesome, size: 16), text: 'Soul & Name'),
          Tab(icon: Icon(Icons.psychology_outlined, size: 16), text: 'Memory Bank'),
          Tab(icon: Icon(Icons.palette_outlined, size: 16), text: 'Theme & Look'),
          Tab(icon: Icon(Icons.key_outlined, size: 16), text: 'Keys & Models'),
        ],
      ),
    );
  }

  // --- TAB 1: Soul & Name ---
  Widget _buildIdentityTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Live Avatar Card with Custom Name
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: _theme.cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _theme.borderColor),
          ),
          child: Row(
            children: [
              AgentAvatar(
                character: _character,
                size: 64,
                mood: AgentMood.thinking,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _nameController.text.isNotEmpty ? _nameController.text : _character.name,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: _theme.textPrimary,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _character.role,
                      style: TextStyle(fontSize: 12, color: _theme.textSecondary),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _theme.primaryAccent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _theme.primaryAccent.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        _character.tag,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: _theme.primaryAccent,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),
        Text(
          'Agent Name',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: _theme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _nameController,
          onChanged: (val) => setState(() => _agentName = val),
          style: TextStyle(color: _theme.textPrimary, fontSize: 15),
          decoration: InputDecoration(
            hintText: 'e.g. Antigravity, Jarvis, Nova, Kinetiq',
            hintStyle: TextStyle(color: _theme.textSecondary.withValues(alpha: 0.6)),
            filled: true,
            fillColor: _theme.inputBackgroundColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: _theme.borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: _theme.borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: _theme.primaryAccent, width: 2),
            ),
          ),
        ),

        const SizedBox(height: 20),
        Text(
          'Choose Neural Archetype & Persona',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: _theme.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 115,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: AgentCharacter.presets.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, idx) {
              final preset = AgentCharacter.presets[idx];
              final isSel = preset.id == _character.id;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _character = preset;
                    if (_nameController.text.trim().isEmpty ||
                        AgentCharacter.presets.any((p) => p.name == _nameController.text.trim())) {
                      _nameController.text = preset.name;
                    }
                    _soulPromptController.text = preset.defaultSystemPrompt;
                  });
                },
                child: Container(
                  width: 120,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSel ? _theme.primaryAccent.withValues(alpha: 0.15) : _theme.cardColor,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isSel ? _theme.primaryAccent : _theme.borderColor,
                      width: isSel ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AgentAvatar(
                        character: preset,
                        size: 38,
                        mood: isSel ? AgentMood.thinking : AgentMood.idle,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        preset.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: _theme.textPrimary,
                        ),
                      ),
                      Text(
                        preset.tag,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10,
                          color: isSel ? _theme.primaryAccent : _theme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 20),
        Text(
          'Avatar Face & Bitmoji Style',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: _theme.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Choose the visual Bitmoji optics and face expression for your model.',
          style: TextStyle(fontSize: 11.5, color: _theme.textSecondary),
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              {'id': 'antigravity', 'name': 'Antigravity (Gentle)', 'sub': 'Quantum Blinks'},
              {'id': 'muse', 'name': 'Muse (Anime/Creative)', 'sub': 'Large Expressive'},
              {'id': 'titan', 'name': 'Titan (Tactical)', 'sub': 'Wide Cyber Optics'},
              {'id': 'cipher', 'name': 'Cipher (Neon Scout)', 'sub': 'Dual Scanner'},
              {'id': 'spark', 'name': 'Spark (Lightning)', 'sub': 'Dynamic Angles'},
            ].map((style) {
              final styleId = style['id']!;
              final isFaceSel = (_character.bitmojiFaceStyle.isNotEmpty
                  ? _character.bitmojiFaceStyle
                  : _character.id) == styleId;
              final previewChar = _character.copyWith(bitmojiFaceStyle: styleId);

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _character = _character.copyWith(bitmojiFaceStyle: styleId);
                  });
                },
                child: Container(
                  margin: const EdgeInsets.only(right: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isFaceSel ? _theme.primaryAccent.withValues(alpha: 0.16) : _theme.cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isFaceSel ? _theme.primaryAccent : _theme.borderColor,
                      width: isFaceSel ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      AgentAvatar(
                        character: previewChar,
                        size: 32,
                        mood: isFaceSel ? AgentMood.thinking : AgentMood.idle,
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            style['name']!,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isFaceSel ? _theme.primaryAccent : _theme.textPrimary,
                            ),
                          ),
                          Text(
                            style['sub']!,
                            style: TextStyle(fontSize: 10, color: _theme.textSecondary),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        const SizedBox(height: 22),
        Row(
          children: [
            Icon(Icons.psychology, size: 18, color: _theme.primaryAccent),
            const SizedBox(width: 8),
            Text(
              'Agent Soul & Core Instructions',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: _theme.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Defines the persona tone, reasoning depth, and behavioral directives.',
          style: TextStyle(fontSize: 12, color: _theme.textSecondary),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _soulPromptController,
          maxLines: 4,
          style: TextStyle(color: _theme.textPrimary, fontSize: 13),
          decoration: InputDecoration(
            filled: true,
            fillColor: _theme.inputBackgroundColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: _theme.borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: _theme.borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: _theme.primaryAccent, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  // --- TAB 2: Memory & Context ---
  Widget _buildMemoryTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _theme.primaryAccent.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _theme.primaryAccent.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Icon(Icons.shield_outlined, color: _theme.primaryAccent, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Local Private Memory: Stored encrypted on your device. Injected seamlessly into every agent execution step.',
                  style: TextStyle(fontSize: 12, color: _theme.textPrimary),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 18),
        Text(
          'User Identity & Context',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: _theme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _userNameController,
          style: TextStyle(color: _theme.textPrimary, fontSize: 14),
          decoration: InputDecoration(
            labelText: 'Your Name / Handle',
            labelStyle: TextStyle(color: _theme.textSecondary),
            filled: true,
            fillColor: _theme.inputBackgroundColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: _theme.borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: _theme.borderColor),
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _userBioController,
          style: TextStyle(color: _theme.textPrimary, fontSize: 14),
          decoration: InputDecoration(
            labelText: 'Your Role / Background Context',
            labelStyle: TextStyle(color: _theme.textSecondary),
            hintText: 'e.g. Lead Software Engineer, Designer, Researcher',
            filled: true,
            fillColor: _theme.inputBackgroundColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: _theme.borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: _theme.borderColor),
            ),
          ),
        ),

        const SizedBox(height: 22),
        Row(
          children: [
            Text(
              'Remembered Facts (${_memory.facts.length})',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: _theme.textPrimary,
              ),
            ),
            const Spacer(),
            TextButton.icon(
              icon: const Icon(Icons.add_circle_outline, size: 16),
              label: const Text('Add Fact', style: TextStyle(fontSize: 12)),
              onPressed: _showAddFactDialog,
            ),
          ],
        ),
        const SizedBox(height: 6),
        if (_memory.facts.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _theme.cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _theme.borderColor),
            ),
            child: Center(
              child: Text(
                'No custom facts saved yet. Add your favorite preferences, projects, or shortcuts!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: _theme.textSecondary),
              ),
            ),
          )
        else
          ..._memory.facts.map((fact) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: _theme.cardColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _theme.borderColor),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _theme.primaryAccent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      fact.category,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: _theme.primaryAccent,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      fact.text,
                      style: TextStyle(fontSize: 13, color: _theme.textPrimary),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete_outline, size: 18, color: _theme.textSecondary),
                    onPressed: () {
                      setState(() {
                        _memory = _memory.copyWith(
                          facts: _memory.facts.where((f) => f.id != fact.id).toList(),
                        );
                      });
                    },
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  void _showAddFactDialog() {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: _theme.surfaceColor,
          title: Text('Add Memory Fact', style: TextStyle(color: _theme.textPrimary)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _newFactController,
                autofocus: true,
                style: TextStyle(color: _theme.textPrimary),
                decoration: InputDecoration(
                  hintText: 'e.g. Always write code with comments',
                  hintStyle: TextStyle(color: _theme.textSecondary),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: ['Preferences', 'Workstyle', 'Project', 'General'].map((cat) {
                  final isSel = _newFactCategory == cat;
                  return ChoiceChip(
                    label: Text(cat),
                    selected: isSel,
                    onSelected: (val) {
                      setDialogState(() => _newFactCategory = cat);
                    },
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final txt = _newFactController.text.trim();
                if (txt.isNotEmpty) {
                  setState(() {
                    _memory = _memory.copyWith(
                      facts: [
                        ..._memory.facts,
                        MemoryFact(
                          id: DateTime.now().millisecondsSinceEpoch.toString(),
                          text: txt,
                          category: _newFactCategory,
                          timestampMillis: DateTime.now().millisecondsSinceEpoch,
                        ),
                      ],
                    );
                  });
                  _newFactController.clear();
                  Navigator.pop(ctx);
                }
              },
              child: const Text('Save Fact'),
            ),
          ],
        ),
      ),
    );
  }

  // --- TAB 3: Theme & Look ---
  Widget _buildThemeTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Visual Architecture & Palette',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: _theme.textPrimary,
          ),
        ),
        const SizedBox(height: 12),

        // Theme Style Cards
        ...ThemeStyle.values.map((style) {
          final isSel = style == _theme.style;
          final String title;
          final String desc;
          final IconData icon;

          switch (style) {
            case ThemeStyle.antigravityLight:
              title = 'Google Antigravity (Clean Light)';
              desc = 'Minimalist, airy, modern Apple & Google clean surfaces.';
              icon = Icons.wb_sunny_outlined;
              break;
            case ThemeStyle.antigravityNebula:
              title = 'Antigravity Nebula (Dark Slate)';
              desc = 'Gentle soothing cosmic dark slate. Elegant and easy on eyes.';
              icon = Icons.nightlight_outlined;
              break;
            case ThemeStyle.obsidianOled:
              title = 'Obsidian OLED (Pure Black)';
              desc = 'Zero-light true black for OLED battery saving and high contrast.';
              icon = Icons.brightness_2;
              break;
            case ThemeStyle.cyberTitanium:
              title = 'Cyber Titanium (Space Zinc)';
              desc = 'Apple space-gray and titanium metallic aesthetics.';
              icon = Icons.blur_on;
              break;
          }

          return GestureDetector(
            onTap: () => setState(() => _theme = _theme.copyWith(style: style)),
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSel ? _theme.primaryAccent.withValues(alpha: 0.12) : _theme.cardColor,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isSel ? _theme.primaryAccent : _theme.borderColor,
                  width: isSel ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(icon, color: isSel ? _theme.primaryAccent : _theme.textSecondary, size: 24),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: _theme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          desc,
                          style: TextStyle(fontSize: 11, color: _theme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  if (isSel)
                    Icon(Icons.check_circle_rounded, color: _theme.primaryAccent, size: 20),
                ],
              ),
            ),
          );
        }),

        const SizedBox(height: 20),
        Text(
          'Primary Accent Aura',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: _theme.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: ThemeAccent.values.map((accent) {
            final isSel = accent == _theme.accent;
            final testTheme = _theme.copyWith(accent: accent);
            final color = testTheme.primaryAccent;

            return GestureDetector(
              onTap: () => setState(() => _theme = _theme.copyWith(accent: accent)),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isSel ? color.withValues(alpha: 0.2) : _theme.cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSel ? color : _theme.borderColor,
                    width: isSel ? 2 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      accent.name[0].toUpperCase() + accent.name.substring(1),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                        color: _theme.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _theme.cardColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _theme.borderColor),
          ),
          child: Row(
            children: [
              Icon(Icons.waves, color: _theme.primaryAccent),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Kinetic Orbital Animations',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: _theme.textPrimary,
                      ),
                    ),
                    Text(
                      'Interactive zero-gravity spin and pulsating avatar aura.',
                      style: TextStyle(fontSize: 11, color: _theme.textSecondary),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _theme.enableKineticAnimations,
                activeTrackColor: _theme.primaryAccent,
                onChanged: (val) {
                  setState(() => _theme = _theme.copyWith(enableKineticAnimations: val));
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- TAB 4: Keys & Models ---
  Widget _buildKeysTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _theme.primaryAccent.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _theme.primaryAccent.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Icon(Icons.lock_outline, color: _theme.primaryAccent, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'BYOK Encryption: Keys are sealed inside Android Keystore (EncryptedSharedPreferences) and never leave your device.',
                  style: TextStyle(fontSize: 12, color: _theme.textPrimary),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 18),
        Text(
          'Neural Provider Presets',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: _theme.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 90,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: EndpointConfig.defaultPresets.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, idx) {
              final preset = EndpointConfig.defaultPresets[idx];
              final isSel = preset.id == _endpoint.id;

              return GestureDetector(
                onTap: () async {
                  final savedKey = await SecureKeyStore.getApiKey(preset.id);
                  setState(() {
                    _endpoint = preset;
                    _endpointUrlController.text = preset.baseUrl;
                    _modelController.text = preset.selectedModel;
                    _apiKeyController.text = savedKey ?? preset.apiKey;
                    _liveDiscoveredModels = [];
                  });
                },
                child: Container(
                  width: 140,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSel ? _theme.primaryAccent.withValues(alpha: 0.15) : _theme.cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSel ? _theme.primaryAccent : _theme.borderColor,
                      width: isSel ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Icon(
                            preset.isLocal ? Icons.wifi : Icons.cloud_outlined,
                            size: 16,
                            color: isSel ? _theme.primaryAccent : _theme.textSecondary,
                          ),
                          const Spacer(),
                          if (isSel)
                            Icon(Icons.check_circle, size: 14, color: _theme.primaryAccent),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        preset.name.split('(').first.trim(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: _theme.textPrimary,
                        ),
                      ),
                      Text(
                        preset.selectedModel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 10, color: _theme.textSecondary),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 20),
        Row(
          children: [
            Text(
              'Base API URL',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: _theme.textPrimary,
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: _isFetchingModels ? null : _fetchLiveModelsFromEndpoint,
              icon: _isFetchingModels
                  ? SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(strokeWidth: 2, color: _theme.primaryAccent),
                    )
                  : Icon(Icons.sync_rounded, size: 14, color: _theme.primaryAccent),
              label: Text(
                _isFetchingModels ? 'Connecting...' : 'Fetch Models',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _theme.primaryAccent),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        TextField(
          controller: _endpointUrlController,
          style: TextStyle(color: _theme.textPrimary, fontSize: 14),
          decoration: InputDecoration(
            hintText: 'e.g. http://192.168.1.X:11434/v1 or https://api.groq.com/openai/v1',
            filled: true,
            fillColor: _theme.inputBackgroundColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: _theme.borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: _theme.borderColor),
            ),
          ),
        ),

        const SizedBox(height: 16),
        Row(
          children: [
            Text(
              'Target Model Name',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: _theme.textPrimary,
              ),
            ),
            const Spacer(),
            if (_liveDiscoveredModels.isNotEmpty)
              Text(
                '${_liveDiscoveredModels.length} available',
                style: TextStyle(fontSize: 11, color: _theme.textSecondary),
              ),
          ],
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _modelController,
          style: TextStyle(color: _theme.textPrimary, fontSize: 14),
          decoration: InputDecoration(
            hintText: 'e.g. qwen2.5-coder:14b, qwen2.5-coder:7b, llama3:latest',
            filled: true,
            fillColor: _theme.inputBackgroundColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: _theme.borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: _theme.borderColor),
            ),
          ),
        ),

        if (_liveDiscoveredModels.isNotEmpty) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.25)),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle_outline, color: Color(0xFF10B981), size: 16),
                const SizedBox(width: 8),
                Text(
                  'Live Models Discovered (${_liveDiscoveredModels.length}):',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _liveDiscoveredModels.map((m) {
                final isCurrent = _modelController.text.trim() == m;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ActionChip(
                    backgroundColor: isCurrent ? _theme.primaryAccent : _theme.cardColor,
                    side: BorderSide(color: isCurrent ? _theme.primaryAccent : _theme.borderColor),
                    avatar: Icon(
                      m.contains('qwen') ? Icons.psychology : Icons.memory,
                      size: 14,
                      color: isCurrent ? Colors.white : _theme.primaryAccent,
                    ),
                    label: Text(
                      m,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                        color: isCurrent ? Colors.white : _theme.textPrimary,
                      ),
                    ),
                    onPressed: () {
                      setState(() {
                        _modelController.text = m;
                      });
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        ],

        const SizedBox(height: 16),
        Text(
          'Secret API Key',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: _theme.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _apiKeyController,
          obscureText: _obscureKey,
          style: TextStyle(color: _theme.textPrimary, fontSize: 14),
          decoration: InputDecoration(
            hintText: _endpoint.isLocal ? 'Not required for local LAN' : 'gsk_... or sk-...',
            filled: true,
            fillColor: _theme.inputBackgroundColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: _theme.borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: _theme.borderColor),
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureKey ? Icons.visibility_off : Icons.visibility,
                color: _theme.textSecondary,
              ),
              onPressed: () => setState(() => _obscureKey = !_obscureKey),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomAction() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _theme.surfaceColor,
        border: Border(top: BorderSide(color: _theme.borderColor)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _saveAllAndDismiss,
            style: ElevatedButton.styleFrom(
              backgroundColor: _theme.primaryAccent,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_outline, size: 20),
                SizedBox(width: 8),
                Text(
                  'Apply Customization & Save',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
