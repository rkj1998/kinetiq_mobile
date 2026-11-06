import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'models/agent_character.dart';
import 'models/endpoint_config.dart';
import 'services/llm/openai_adapter.dart';
import 'services/tools/tool_registry.dart';
import 'services/tools/mock_time_tool.dart';
import 'services/tools/web_tools.dart';
import 'services/agent/react_loop.dart';
import 'services/storage/secure_key_store.dart';
import 'widgets/agent_avatar.dart';
import 'widgets/character_selector_sheet.dart';
import 'widgets/network_endpoint_sheet.dart';
import 'widgets/agent_browser_sheet.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  runApp(const KinetiqApp());
}

class KinetiqApp extends StatelessWidget {
  const KinetiqApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kinetiq',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF07080D),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF6366F1),
          secondary: Color(0xFF10B981),
          surface: Color(0xFF0F111A),
        ),
      ),
      home: const KinetiqChatScreen(),
    );
  }
}

class ChatEntry {
  final String role;
  final String text;
  final List<AgentStep> steps;
  final AgentCharacter character;
  final String? browserUrl;

  ChatEntry({
    required this.role,
    required this.text,
    this.steps = const [],
    required this.character,
    this.browserUrl,
  });
}

class KinetiqChatScreen extends StatefulWidget {
  const KinetiqChatScreen({super.key});

  @override
  State<KinetiqChatScreen> createState() => _KinetiqChatScreenState();
}

class _KinetiqChatScreenState extends State<KinetiqChatScreen> {
  final TextEditingController _promptController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<ChatEntry> _history = [];
  List<AgentStep> _currentTurnSteps = [];
  bool _isProcessing = false;

  AgentCharacter _currentCharacter = AgentCharacter.presets.first; // Muse by default
  EndpointConfig _currentEndpoint = EndpointConfig.defaultPresets.first; // Groq Cloud by default
  late final ToolRegistry _registry;

  AgentMood get _currentMood {
    if (!_isProcessing) return AgentMood.idle;
    if (_currentTurnSteps.any((s) => s.type == StepType.toolCall)) {
      return AgentMood.executing;
    }
    return AgentMood.thinking;
  }

  @override
  void initState() {
    super.initState();
    _registry = ToolRegistry()
      ..registerTool(GetSystemTimeTool())
      ..registerTool(WebSearchTool())
      ..registerTool(FetchPageTextTool());
    _loadSavedPreferences();
  }

  Future<void> _loadSavedPreferences() async {
    final savedPersonaId = await SecureKeyStore.getActivePersona();
    if (savedPersonaId != null) {
      final found = AgentCharacter.presets.where((p) => p.id == savedPersonaId);
      if (found.isNotEmpty) {
        setState(() => _currentCharacter = found.first);
      }
    }

    final savedEndpointId = await SecureKeyStore.getActiveEndpointId();
    if (savedEndpointId != null) {
      final found = EndpointConfig.defaultPresets.where((e) => e.id == savedEndpointId);
      if (found.isNotEmpty) {
        _currentEndpoint = found.first;
      }
    }

    final savedKey = await SecureKeyStore.getApiKey(_currentEndpoint.id);
    if (savedKey != null && savedKey.isNotEmpty) {
      setState(() {
        _currentEndpoint = _currentEndpoint.copyWith(apiKey: savedKey);
      });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showCharacterPicker() {
    CharacterSelectorSheet.show(
      context,
      currentCharacter: _currentCharacter,
      onCharacterSelected: (char) async {
        await SecureKeyStore.saveActivePersona(char.id);
        setState(() => _currentCharacter = char);
      },
    );
  }

  void _showEndpointSettings() {
    NetworkEndpointSheet.show(
      context,
      currentConfig: _currentEndpoint,
      onConfigSaved: (config) {
        setState(() => _currentEndpoint = config);
      },
    );
  }

  void _dispatchPrompt() async {
    final query = _promptController.text.trim();
    if (query.isEmpty) return;

    if (_currentEndpoint.apiKey.trim().isEmpty && !_currentEndpoint.isLocal) {
      _showEndpointSettings();
      return;
    }

    _promptController.clear();
    setState(() {
      _history.add(ChatEntry(
        role: 'user',
        text: query,
        character: _currentCharacter,
      ));
      _currentTurnSteps = [];
      _isProcessing = true;
    });
    _scrollToBottom();

    final adapter = OpenAIAdapter(
      apiKey: _currentEndpoint.apiKey.trim(),
      baseUrl: _currentEndpoint.baseUrl.trim(),
    );

    final agent = ReActAgent(
      client: adapter,
      registry: _registry,
      model: _currentEndpoint.selectedModel,
      systemPrompt: _currentCharacter.defaultSystemPrompt,
      maxTurns: 6,
    );

    String finalAnswer = '';
    String? detectedUrl;

    try {
      await for (final step in agent.run(
        userPrompt: query,
        history: [],
      )) {
        setState(() {
          _currentTurnSteps.add(step);
          if (step.type == StepType.finalAnswer) {
            finalAnswer = step.content;
          }
        });

        // Detect if any URL was parsed or visited by web tools
        if (step.type == StepType.toolResult && step.content.contains('http')) {
          final match = RegExp(r'https?:\/\/[^\s\)\"\\]+').firstMatch(step.content);
          if (match != null) {
            detectedUrl = match.group(0);
          }
        }

        _scrollToBottom();
      }
    } catch (e, stack) {
      debugPrint('Agent execution error: $e\n$stack');
      finalAnswer = 'Execution halted: $e';
    }

    setState(() {
      _history.add(ChatEntry(
        role: 'agent',
        text: finalAnswer.isNotEmpty ? finalAnswer : 'Task completed without text output.',
        steps: List.from(_currentTurnSteps),
        character: _currentCharacter,
        browserUrl: detectedUrl,
      ));
      _currentTurnSteps = [];
      _isProcessing = false;
    });
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF07080D),
      appBar: _buildTopNav(),
      body: Column(
        children: [
          _buildQuickActionRail(),
          Expanded(
            child: _history.isEmpty && !_isProcessing
                ? _buildHeroEmptyState()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    itemCount: _history.length + (_isProcessing ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index < _history.length) {
                        final item = _history[index];
                        return item.role == 'user'
                            ? _buildUserMessage(item.text)
                            : _buildAgentMessage(item);
                      } else {
                        return _buildLiveExecutionStatus();
                      }
                    },
                  ),
          ),
          _buildInputBar(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildTopNav() {
    return AppBar(
      backgroundColor: const Color(0xFF0C0E17),
      elevation: 0,
      title: Row(
        children: [
          GestureDetector(
            onTap: _showCharacterPicker,
            child: AgentAvatar(
              character: _currentCharacter,
              mood: _currentMood,
              size: 38,
              showBadge: true,
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _showCharacterPicker,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      _currentCharacter.name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _currentCharacter.primaryColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _currentCharacter.tag,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: _currentCharacter.glowColor,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  _currentEndpoint.isLocal
                      ? 'Local: ${_currentEndpoint.selectedModel}'
                      : '${_currentEndpoint.name.split('(').first.trim()} • ${_currentEndpoint.selectedModel}',
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        // Autonomous Browser Action Button
        IconButton(
          tooltip: 'Open Autonomous Browser',
          icon: const Icon(Icons.public_rounded, size: 21, color: Color(0xFF38BDF8)),
          onPressed: () {
            AgentBrowserSheet.show(
              context,
              initialUrl: 'https://duckduckgo.com',
              title: 'Kinetiq Web Inspector',
            );
          },
        ),

        // Endpoint & BYOK Button
        IconButton(
          tooltip: 'Neural Endpoint Settings',
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFF181C2E),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF262D4A)),
            ),
            child: Icon(
              _currentEndpoint.isLocal ? Icons.lan_rounded : Icons.tune_rounded,
              size: 16,
              color: _currentEndpoint.isLocal ? const Color(0xFF10B981) : const Color(0xFF818CF8),
            ),
          ),
          onPressed: _showEndpointSettings,
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildQuickActionRail() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        color: Color(0xFF0C0E17),
        border: Border(bottom: BorderSide(color: Color(0xFF161926))),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildRailChip(
              icon: Icons.face_retouching_natural,
              label: 'Persona: ${_currentCharacter.name}',
              color: _currentCharacter.glowColor,
              onTap: _showCharacterPicker,
            ),
            const SizedBox(width: 8),
            _buildRailChip(
              icon: _currentEndpoint.isLocal ? Icons.lan : Icons.bolt,
              label: _currentEndpoint.selectedModel.split('/').last,
              color: const Color(0xFFF59E0B),
              onTap: _showEndpointSettings,
            ),
            const SizedBox(width: 8),
            _buildRailChip(
              icon: Icons.language,
              label: 'In-App Webview',
              color: const Color(0xFF06B6D4),
              onTap: () => AgentBrowserSheet.show(context, initialUrl: 'https://duckduckgo.com'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRailChip({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFF141724),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF23283B)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: Color(0xFFCBD5E1), fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroEmptyState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AgentAvatar(
              character: _currentCharacter,
              mood: AgentMood.thinking,
              size: 88,
            ),
            const SizedBox(height: 20),
            Text(
              'Meet ${_currentCharacter.name}',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _currentCharacter.description,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8), height: 1.4),
            ),
            const SizedBox(height: 24),

            // Suggested prompt cards
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                _buildPromptSuggestion('What is the current time?'),
                _buildPromptSuggestion('Search web for latest AI news'),
                _buildPromptSuggestion('Inspect Wikipedia homepage'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPromptSuggestion(String prompt) {
    return GestureDetector(
      onTap: () {
        _promptController.text = prompt;
        _dispatchPrompt();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: const Color(0xFF131622),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF22273D)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_awesome, size: 14, color: _currentCharacter.primaryColor),
            const SizedBox(width: 8),
            Text(prompt, style: const TextStyle(fontSize: 12, color: Colors.white70)),
          ],
        ),
      ),
    );
  }

  Widget _buildUserMessage(String text) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.82),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF2D3249), Color(0xFF1F2333)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(6),
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Text(text, style: const TextStyle(fontSize: 15, color: Colors.white, height: 1.35)),
      ),
    );
  }

  Widget _buildAgentMessage(ChatEntry entry) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Material(
        color: Colors.transparent,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.all(16),
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.92),
          decoration: BoxDecoration(
            color: const Color(0xFF10121C),
            border: Border.all(color: entry.character.primaryColor.withValues(alpha: 0.2)),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Colors.black45,
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Agent identity banner
              Row(
                children: [
                  AgentAvatar(character: entry.character, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    entry.character.name,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: entry.character.glowColor,
                    ),
                  ),
                  const Spacer(),
                  if (entry.browserUrl != null)
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        visualDensity: VisualDensity.compact,
                        backgroundColor: const Color(0xFF06B6D4).withValues(alpha: 0.15),
                      ),
                      icon: const Icon(Icons.open_in_browser, size: 14, color: Color(0xFF38BDF8)),
                      label: const Text('Open Page', style: TextStyle(fontSize: 11, color: Color(0xFF38BDF8))),
                      onPressed: () {
                        AgentBrowserSheet.show(context, initialUrl: entry.browserUrl!);
                      },
                    ),
                ],
              ),
              const SizedBox(height: 10),

              // Execution Action Drawer
              if (entry.steps.isNotEmpty) ...[
                Theme(
                  data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                  child: Material(
                    color: Colors.transparent,
                    child: ExpansionTile(
                      tilePadding: EdgeInsets.zero,
                      collapsedIconColor: Colors.grey,
                      iconColor: entry.character.primaryColor,
                      title: Row(
                        children: [
                          Icon(Icons.commit, size: 16, color: entry.character.primaryColor),
                          const SizedBox(width: 8),
                          Text(
                            'Executed ${entry.steps.where((s) => s.type == StepType.toolCall).length} actions',
                            style: const TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      children: entry.steps.map((s) => _buildStepTile(s)).toList(),
                    ),
                  ),
                ),
                const Divider(color: Color(0xFF1B1E2D), height: 16),
              ],

              // Markdown content
              MarkdownBody(
                data: entry.text,
                styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                  p: const TextStyle(fontSize: 15, height: 1.45, color: Color(0xFFE2E8F0)),
                  code: const TextStyle(backgroundColor: Color(0xFF1B1D2A), color: Color(0xFF93C5FD)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLiveExecutionStatus() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF10121C),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _currentCharacter.primaryColor.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AgentAvatar(character: _currentCharacter, mood: AgentMood.thinking, size: 22),
              const SizedBox(width: 10),
              Text(
                '${_currentCharacter.name} is evaluating...',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _currentCharacter.glowColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ..._currentTurnSteps.map((s) => _buildStepTile(s)),
        ],
      ),
    );
  }

  Widget _buildStepTile(AgentStep step) {
    IconData icon;
    Color color;
    switch (step.type) {
      case StepType.toolCall:
        icon = Icons.build_circle_outlined;
        color = const Color(0xFFF59E0B);
        break;
      case StepType.toolResult:
        icon = Icons.check_circle_outline;
        color = const Color(0xFF10B981);
        break;
      case StepType.thought:
        icon = Icons.psychology_outlined;
        color = _currentCharacter.primaryColor;
        break;
      case StepType.error:
        icon = Icons.error_outline;
        color = Colors.redAccent;
        break;
      default:
        icon = Icons.info_outline;
        color = Colors.grey;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${step.title}: ${step.content}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade400, fontFamily: 'monospace'),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: const BoxDecoration(
        color: Color(0xFF0C0E17),
        border: Border(top: BorderSide(color: Color(0xFF171A26))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF131624),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFF22273D)),
              ),
              child: TextField(
                controller: _promptController,
                style: const TextStyle(fontSize: 15, color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Ask ${_currentCharacter.name} to browse, code, or execute...',
                  hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 13.5),
                  border: InputBorder.none,
                ),
                onSubmitted: (_) => _dispatchPrompt(),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _isProcessing ? null : _dispatchPrompt,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _currentCharacter.primaryColor,
                    _currentCharacter.secondaryColor,
                  ],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _currentCharacter.glowColor.withValues(alpha: 0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                _isProcessing ? Icons.hourglass_top_rounded : Icons.arrow_upward_rounded,
                color: Colors.white,
                size: 21,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
