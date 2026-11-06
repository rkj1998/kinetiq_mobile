import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'models/agent_character.dart';
import 'models/agent_memory.dart';
import 'models/app_theme_config.dart';
import 'models/endpoint_config.dart';
import 'models/autonomous_task.dart';
import 'models/pc_virtual_file.dart';
import 'services/llm/openai_adapter.dart';
import 'services/tools/tool_registry.dart';
import 'services/tools/mock_time_tool.dart';
import 'services/tools/web_tools.dart';
import 'services/tools/autonomous_cloud_vm_tool.dart';
import 'services/tools/python_computer_tool.dart';
import 'services/agent/react_loop.dart';
import 'services/storage/secure_key_store.dart';
import 'widgets/agent_avatar.dart';
import 'widgets/antigravity_logo.dart';
import 'widgets/antigravity_startup_modal.dart';
import 'widgets/customization_studio_sheet.dart';
import 'widgets/agent_browser_sheet.dart';
import 'widgets/teammate_workspace_sheet.dart';
import 'widgets/agent_pc_terminal_sheet.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));
  runApp(const KinetiqApp());
}

class KinetiqApp extends StatefulWidget {
  const KinetiqApp({super.key});

  static KinetiqAppState? of(BuildContext context) =>
      context.findAncestorStateOfType<KinetiqAppState>();

  @override
  State<KinetiqApp> createState() => KinetiqAppState();
}

class KinetiqAppState extends State<KinetiqApp> {
  AppThemeConfig _theme = const AppThemeConfig(
    style: ThemeStyle.antigravityLight,
    accent: ThemeAccent.googleBlue,
  );

  void updateTheme(AppThemeConfig newTheme) {
    setState(() => _theme = newTheme);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kinetiq Antigravity',
      debugShowCheckedModeBanner: false,
      themeMode: _theme.isDark ? ThemeMode.dark : ThemeMode.light,
      theme: _theme.toThemeData(),
      darkTheme: _theme.toThemeData(),
      home: KinetiqChatScreen(
        theme: _theme,
        onThemeChanged: updateTheme,
      ),
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
  final AppThemeConfig theme;
  final ValueChanged<AppThemeConfig> onThemeChanged;

  const KinetiqChatScreen({
    super.key,
    required this.theme,
    required this.onThemeChanged,
  });

  @override
  State<KinetiqChatScreen> createState() => _KinetiqChatScreenState();
}

class _KinetiqChatScreenState extends State<KinetiqChatScreen> {
  final TextEditingController _promptController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<ChatEntry> _history = [];
  List<AgentStep> _currentTurnSteps = [];
  bool _isProcessing = false;

  late AppThemeConfig _theme;
  AgentCharacter _currentCharacter = AgentCharacter.presets.first; // Antigravity default
  String _customAgentName = '';
  AgentMemory _memory = const AgentMemory();
  List<AutonomousTask> _autonomousTasks = AutonomousTask.defaultDemoTasks;
  List<PcVirtualFile> _pcFiles = PcVirtualFile.defaultDemoFiles;
  EndpointConfig _currentEndpoint = EndpointConfig.defaultPresets.first; // Groq Cloud default
  late final ToolRegistry _registry;

  String get _displayName =>
      _customAgentName.isNotEmpty ? _customAgentName : _currentCharacter.name;

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
    _theme = widget.theme;
    _registry = ToolRegistry()
      ..registerTool(GetSystemTimeTool())
      ..registerTool(WebSearchTool())
      ..registerTool(FetchPageTextTool())
      ..registerTool(AutonomousCloudVMTool())
      ..registerTool(PythonComputerTool());
    _loadSavedPreferences();
  }

  @override
  void didUpdateWidget(covariant KinetiqChatScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.theme != widget.theme) {
      setState(() => _theme = widget.theme);
    }
  }

  Future<void> _loadSavedPreferences() async {
    // 1. Theme
    final savedStyle = await SecureKeyStore.getThemeStyle();
    final savedAccent = await SecureKeyStore.getThemeAccent();
    final savedAnim = await SecureKeyStore.getKineticAnimations();
    final loadedTheme = AppThemeConfig(
      style: savedStyle,
      accent: savedAccent,
      enableKineticAnimations: savedAnim,
    );
    widget.onThemeChanged(loadedTheme);

    // 2. Persona & Custom Name
    final savedPersonaId = await SecureKeyStore.getActivePersona();
    if (savedPersonaId != null) {
      final found = AgentCharacter.presets.where((p) => p.id == savedPersonaId);
      if (found.isNotEmpty) {
        _currentCharacter = found.first;
      }
    }
    final savedCustomName = await SecureKeyStore.getCustomAgentName();
    if (savedCustomName != null && savedCustomName.trim().isNotEmpty) {
      _customAgentName = savedCustomName.trim();
    }
    final savedCustomSoul = await SecureKeyStore.getCustomSoulPrompt();
    if (savedCustomSoul != null && savedCustomSoul.trim().isNotEmpty) {
      _currentCharacter = _currentCharacter.copyWith(defaultSystemPrompt: savedCustomSoul);
    }

    // 3. Memory
    final loadedMemory = await SecureKeyStore.getAgentMemory();

    // 3.1 Autonomous Tasks
    final rawTasks = await SecureKeyStore.getAutonomousTasks();
    final loadedTasks = AutonomousTask.deserializeList(rawTasks);

    // 3.2 PC Virtual Files
    final rawFiles = await SecureKeyStore.getPcVirtualFiles();
    final loadedFiles = PcVirtualFile.deserializeList(rawFiles);

    // 4. Endpoint
    final savedEndpointId = await SecureKeyStore.getActiveEndpointId();
    if (savedEndpointId != null) {
      final found = EndpointConfig.defaultPresets.where((e) => e.id == savedEndpointId);
      if (found.isNotEmpty) {
        _currentEndpoint = found.first;
      }
    }
    final savedKey = await SecureKeyStore.getApiKey(_currentEndpoint.id);
    if (savedKey != null && savedKey.isNotEmpty) {
      _currentEndpoint = _currentEndpoint.copyWith(apiKey: savedKey);
    }

    setState(() {
      _theme = loadedTheme;
      _memory = loadedMemory;
      _autonomousTasks = loadedTasks;
      _pcFiles = loadedFiles;
    });
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

  void _openCustomizationStudio() {
    CustomizationStudioSheet.show(
      context,
      currentTheme: _theme,
      currentCharacter: _currentCharacter,
      customAgentName: _displayName,
      currentMemory: _memory,
      currentEndpoint: _currentEndpoint,
      onSave: ({
        required theme,
        required character,
        required agentName,
        required memory,
        required endpoint,
      }) {
        widget.onThemeChanged(theme);
        setState(() {
          _theme = theme;
          _currentCharacter = character;
          _customAgentName = agentName;
          _memory = memory;
          _currentEndpoint = endpoint;
        });
      },
    );
  }

  void _openStartupTour() {
    AntigravityStartupModal.show(
      context,
      theme: _theme,
      agentName: _displayName,
      onOpenCustomization: _openCustomizationStudio,
    );
  }

  void _openTeammateWorkspace() {
    TeammateWorkspaceSheet.show(
      context,
      theme: _theme,
      tasks: _autonomousTasks,
      onTaskApproved: (task) async {
        setState(() {
          final idx = _autonomousTasks.indexWhere((t) => t.id == task.id);
          if (idx != -1) {
            _autonomousTasks[idx] = task;
          }
        });
        await SecureKeyStore.saveAutonomousTasks(AutonomousTask.serializeList(_autonomousTasks));
      },
      onNewTaskSubmitted: (newTask) async {
        setState(() {
          _autonomousTasks.insert(0, newTask);
        });
        await SecureKeyStore.saveAutonomousTasks(AutonomousTask.serializeList(_autonomousTasks));
      },
    );
  }

  void _openPcTerminal() {
    AgentPcTerminalSheet.show(
      context,
      theme: _theme,
      initialFiles: _pcFiles,
      onFilesUpdated: (files) async {
        setState(() => _pcFiles = files);
        await SecureKeyStore.savePcVirtualFiles(PcVirtualFile.serializeList(_pcFiles));
      },
    );
  }

  void _dispatchPrompt() async {
    final query = _promptController.text.trim();
    if (query.isEmpty) return;

    if (_currentEndpoint.apiKey.trim().isEmpty && !_currentEndpoint.isLocal) {
      _openCustomizationStudio();
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

    // Dynamic prompt with persona soul and injected memory context
    final agent = ReActAgent(
      client: adapter,
      registry: _registry,
      model: _currentEndpoint.selectedModel,
      systemPrompt: _currentCharacter.defaultSystemPrompt,
      memoryContext: _memory.toPromptContext(),
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
      backgroundColor: _theme.backgroundColor,
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
      backgroundColor: _theme.surfaceColor,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      titleSpacing: 16,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(color: _theme.borderColor, height: 1),
      ),
      title: Row(
        children: [
          // Animated Antigravity Logo that triggers boost & tour
          AntigravityLogo(
            size: 36,
            theme: _theme,
            onTap: _openStartupTour,
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _openCustomizationStudio,
            child: AgentAvatar(
              character: _currentCharacter,
              mood: _currentMood,
              size: 32,
              showBadge: true,
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _openCustomizationStudio,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      _displayName,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: _theme.textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: _theme.primaryAccent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _currentCharacter.tag,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: _theme.primaryAccent,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 1),
                Text(
                  _currentEndpoint.isLocal
                      ? 'LAN: ${_currentEndpoint.selectedModel}'
                      : '${_currentEndpoint.name.split('(').first.trim()} • ${_currentEndpoint.selectedModel}',
                  style: TextStyle(color: _theme.textSecondary, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        // Agent PC & Python Terminal Action
        IconButton(
          tooltip: 'Agent PC & Python Terminal',
          icon: Icon(Icons.terminal_rounded, size: 21, color: _theme.primaryAccent),
          onPressed: _openPcTerminal,
        ),

        // AI Teammates & Hand-off Workspace Action (Grok Bot & Muse style)
        IconButton(
          tooltip: 'Teammates & Cloud VM Jobs',
          icon: Badge(
            isLabelVisible: _autonomousTasks.any((t) => t.pendingApproval != null),
            backgroundColor: const Color(0xFFD97706),
            label: const Text('!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10)),
            child: Icon(Icons.hub_outlined, size: 21, color: _theme.textSecondary),
          ),
          onPressed: _openTeammateWorkspace,
        ),

        // Autonomous Browser Action
        IconButton(
          tooltip: 'Open Autonomous Browser',
          icon: Icon(Icons.public_rounded, size: 22, color: _theme.textSecondary),
          onPressed: () {
            AgentBrowserSheet.show(
              context,
              initialUrl: 'https://duckduckgo.com',
              title: 'Kinetiq Web Inspector',
            );
          },
        ),

        // Customization Studio & Memory Brain Button
        IconButton(
          tooltip: 'Customization Studio & Brain Settings',
          icon: Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: _theme.cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _theme.borderColor),
            ),
            child: Icon(
              Icons.tune_rounded,
              size: 18,
              color: _theme.primaryAccent,
            ),
          ),
          onPressed: _openCustomizationStudio,
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildQuickActionRail() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: _theme.surfaceColor,
        border: Border(bottom: BorderSide(color: _theme.borderColor)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildRailChip(
              icon: Icons.terminal_rounded,
              label: 'PC: ${_pcFiles.length} files',
              color: const Color(0xFF38BDF8),
              onTap: _openPcTerminal,
            ),
            const SizedBox(width: 8),
            _buildRailChip(
              icon: Icons.hub_outlined,
              label: 'Jobs: ${_autonomousTasks.where((t) => t.status == TaskStatus.running).length} active',
              color: const Color(0xFFD97706),
              onTap: _openTeammateWorkspace,
            ),
            const SizedBox(width: 8),
            _buildRailChip(
              icon: Icons.psychology_outlined,
              label: 'Soul: $_displayName',
              color: _theme.primaryAccent,
              onTap: _openCustomizationStudio,
            ),
            const SizedBox(width: 8),
            _buildRailChip(
              icon: Icons.bookmark_added_outlined,
              label: 'Memory: ${_memory.facts.length} facts',
              color: const Color(0xFF059669),
              onTap: _openCustomizationStudio,
            ),
            const SizedBox(width: 8),
            _buildRailChip(
              icon: Icons.palette_outlined,
              label: _theme.style == ThemeStyle.antigravityLight
                  ? 'Light'
                  : (_theme.style == ThemeStyle.antigravityNebula ? 'Nebula' : 'Dark'),
              color: _theme.secondaryAccent,
              onTap: _openCustomizationStudio,
            ),
            const SizedBox(width: 8),
            _buildRailChip(
              icon: _currentEndpoint.isLocal ? Icons.wifi : Icons.bolt,
              label: _currentEndpoint.selectedModel.split('/').last,
              color: const Color(0xFFD97706),
              onTap: _openCustomizationStudio,
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
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
        decoration: BoxDecoration(
          color: _theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _theme.borderColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: _theme.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroEmptyState() {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning'
        : (hour < 17 ? 'Good afternoon' : 'Good evening');

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Kinetic Antigravity Hero Logo
            AntigravityLogo(
              size: 110,
              theme: _theme,
              onTap: _openStartupTour,
            ),
            const SizedBox(height: 24),
            Text(
              '$greeting, ${_memory.userName}',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: _theme.textPrimary,
                letterSpacing: -0.6,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'How can $_displayName assist your workflow today?',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: _theme.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),

            // Google/Apple Style Quick Starter Chips
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                _buildPromptSuggestion('Run Python script to generate tailored PolicyMe PDF resume', Icons.code),
                _buildPromptSuggestion('Search web for latest open-source AI models', Icons.travel_explore),
                _buildPromptSuggestion('Hand off job application & calendar follow-up to team', Icons.hub_outlined),
                _buildPromptSuggestion('Recall my remembered profile and preferences', Icons.psychology),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPromptSuggestion(String prompt, IconData icon) {
    return GestureDetector(
      onTap: () {
        _promptController.text = prompt;
        _dispatchPrompt();
      },
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.88),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: _theme.cardColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _theme.borderColor),
          boxShadow: _theme.subtleShadow,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: _theme.primaryAccent),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                prompt,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: _theme.textPrimary,
                ),
              ),
            ),
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
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.82),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              _theme.primaryAccent,
              _theme.secondaryAccent,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(22),
            topRight: Radius.circular(6),
            bottomLeft: Radius.circular(22),
            bottomRight: Radius.circular(22),
          ),
          boxShadow: [
            BoxShadow(
              color: _theme.primaryAccent.withValues(alpha: 0.28),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 15,
            color: _theme.userBubbleText,
            height: 1.35,
            fontWeight: FontWeight.w500,
          ),
        ),
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
          padding: const EdgeInsets.all(18),
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.92),
          decoration: BoxDecoration(
            color: _theme.agentBubbleColor,
            border: Border.all(color: _theme.borderColor),
            borderRadius: BorderRadius.circular(24),
            boxShadow: _theme.subtleShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Agent identity banner
              Row(
                children: [
                  AgentAvatar(
                    character: entry.character,
                    size: 26,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _displayName,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: _theme.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  if (entry.browserUrl != null)
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        visualDensity: VisualDensity.compact,
                        backgroundColor: _theme.primaryAccent.withValues(alpha: 0.12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: Icon(Icons.open_in_browser, size: 14, color: _theme.primaryAccent),
                      label: Text(
                        'Inspect URL',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: _theme.primaryAccent,
                        ),
                      ),
                      onPressed: () {
                        AgentBrowserSheet.show(context, initialUrl: entry.browserUrl!);
                      },
                    ),
                ],
              ),
              const SizedBox(height: 12),

              // Execution Action Drawer
              if (entry.steps.isNotEmpty) ...[
                Theme(
                  data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                  child: Material(
                    color: Colors.transparent,
                    child: ExpansionTile(
                      tilePadding: EdgeInsets.zero,
                      collapsedIconColor: _theme.textSecondary,
                      iconColor: _theme.primaryAccent,
                      title: Row(
                        children: [
                          Icon(Icons.commit, size: 16, color: _theme.primaryAccent),
                          const SizedBox(width: 8),
                          Text(
                            'Executed ${entry.steps.where((s) => s.type == StepType.toolCall).length} actions',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: _theme.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      children: entry.steps.map((s) => _buildStepTile(s)).toList(),
                    ),
                  ),
                ),
                Divider(color: _theme.borderColor, height: 16),
              ],

              // Markdown content
              MarkdownBody(
                data: entry.text,
                styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                  p: TextStyle(fontSize: 15, height: 1.45, color: _theme.textPrimary),
                  code: TextStyle(
                    backgroundColor: _theme.cardColor,
                    color: _theme.primaryAccent,
                    fontSize: 13,
                  ),
                  codeblockDecoration: BoxDecoration(
                    color: _theme.cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _theme.borderColor),
                  ),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _theme.agentBubbleColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _theme.primaryAccent.withValues(alpha: 0.35)),
        boxShadow: _theme.subtleShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AgentAvatar(
                character: _currentCharacter,
                mood: AgentMood.thinking,
                size: 24,
              ),
              const SizedBox(width: 10),
              Text(
                '$_displayName is evaluating...',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _theme.primaryAccent,
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
        color = const Color(0xFFD97706);
        break;
      case StepType.toolResult:
        icon = Icons.check_circle_outline;
        color = const Color(0xFF059669);
        break;
      case StepType.thought:
        icon = Icons.psychology_outlined;
        color = _theme.primaryAccent;
        break;
      case StepType.error:
        icon = Icons.error_outline;
        color = const Color(0xFFEF4444);
        break;
      default:
        icon = Icons.info_outline;
        color = _theme.textSecondary;
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
              style: TextStyle(
                fontSize: 12,
                color: _theme.textSecondary,
                fontFamily: 'monospace',
              ),
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
      decoration: BoxDecoration(
        color: _theme.surfaceColor,
        border: Border(top: BorderSide(color: _theme.borderColor)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                decoration: BoxDecoration(
                  color: _theme.inputBackgroundColor,
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(color: _theme.borderColor),
                  boxShadow: _theme.subtleShadow,
                ),
                child: TextField(
                  controller: _promptController,
                  style: TextStyle(fontSize: 15, color: _theme.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Ask $_displayName to browse, code, or execute...',
                    hintStyle: TextStyle(color: _theme.textSecondary, fontSize: 13.5),
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
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _theme.primaryAccent,
                      _theme.secondaryAccent,
                    ],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _theme.primaryAccent.withValues(alpha: 0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  _isProcessing ? Icons.hourglass_top_rounded : Icons.arrow_upward_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
