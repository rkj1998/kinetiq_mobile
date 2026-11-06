import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'services/llm/openai_adapter.dart';
import 'services/tools/tool_registry.dart';
import 'services/tools/mock_time_tool.dart';
import 'services/tools/web_tools.dart';
import 'services/agent/react_loop.dart';

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
        scaffoldBackgroundColor: const Color(0xFF090A0F),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF6366F1),
          secondary: Color(0xFF10B981),
          surface: Color(0xFF13151F),
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
  ChatEntry({required this.role, required this.text, this.steps = const []});
}

class KinetiqChatScreen extends StatefulWidget {
  const KinetiqChatScreen({super.key});

  @override
  State<KinetiqChatScreen> createState() => _KinetiqChatScreenState();
}

class _KinetiqChatScreenState extends State<KinetiqChatScreen> {
  final TextEditingController _promptController = TextEditingController();
  final TextEditingController _apiKeyController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<ChatEntry> _history = [];
  List<AgentStep> _currentTurnSteps = [];
  bool _isProcessing = false;
  String _selectedModel = 'llama-3.3-70b-versatile';

  late final ToolRegistry _registry;

  @override
  void initState() {
    super.initState();
    _registry = ToolRegistry()
      ..registerTool(GetSystemTimeTool())
      ..registerTool(WebSearchTool())
      ..registerTool(FetchPageTextTool());
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

  void _showSettingsModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF12141D),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20, right: 20, top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.tune, color: Color(0xFF6366F1), size: 22),
                const SizedBox(width: 10),
                const Text('BYOK & Engine Settings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(icon: const Icon(Icons.close, size: 20), onPressed: () => Navigator.pop(ctx)),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Groq / OpenAI API Key', style: TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 6),
            TextField(
              controller: _apiKeyController,
              obscureText: true,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFF1B1D2A),
                hintText: 'gsk_... or sk-...',
                hintStyle: TextStyle(color: Colors.grey.shade600),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Model Architecture', style: TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              value: _selectedModel,
              dropdownColor: const Color(0xFF1B1D2A),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFF1B1D2A),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
              items: const [
                DropdownMenuItem(value: 'llama-3.3-70b-versatile', child: Text('Llama 3.3 70B (Groq - Ultra Fast)')),
                DropdownMenuItem(value: 'qwen-2.5-coder-32b', child: Text('Qwen 2.5 Coder 32B (Groq)')),
                DropdownMenuItem(value: 'llama-3.1-8b-instant', child: Text('Llama 3.1 8B Instant (Groq)')),
              ],
              onChanged: (val) {
                if (val != null) setState(() => _selectedModel = val);
              },
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Save & Close', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _dispatchPrompt() async {
    final query = _promptController.text.trim();
    if (query.isEmpty) return;

    if (_apiKeyController.text.trim().isEmpty) {
      _showSettingsModal();
      return;
    }

    _promptController.clear();
    setState(() {
      _history.add(ChatEntry(role: 'user', text: query));
      _currentTurnSteps = [];
      _isProcessing = true;
    });
    _scrollToBottom();

    final adapter = OpenAIAdapter(
      apiKey: _apiKeyController.text.trim(),
      baseUrl: 'https://api.groq.com/openai/v1',
    );

    final agent = ReActAgent(
      client: adapter,
      registry: _registry,
      model: _selectedModel,
      maxTurns: 6,
    );

    String finalAnswer = '';

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
        _scrollToBottom();
      }
    } catch (e) {
      finalAnswer = 'Execution halted: $e';
    }

    setState(() {
      _history.add(ChatEntry(
        role: 'agent',
        text: finalAnswer.isNotEmpty ? finalAnswer : 'Task completed without text output.',
        steps: List.from(_currentTurnSteps),
      ));
      _currentTurnSteps = [];
      _isProcessing = false;
    });
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0C0E14),
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)]),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.auto_awesome, size: 18, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Kinetiq', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text(_selectedModel.split('-').take(2).join(' '), style: TextStyle(color: Colors.grey.shade400, fontSize: 11)),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune, size: 20),
            onPressed: _showSettingsModal,
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
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

  Widget _buildUserMessage(String text) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
        decoration: const BoxDecoration(
          color: Color(0xFF282C3F),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(4),
            bottomLeft: Radius.circular(18),
            bottomRight: Radius.circular(18),
          ),
        ),
        child: Text(text, style: const TextStyle(fontSize: 15, color: Colors.white, height: 1.3)),
      ),
    );
  }

  Widget _buildAgentMessage(ChatEntry entry) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(16),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.9),
        decoration: BoxDecoration(
          color: const Color(0xFF13151F),
          border: Border.all(color: const Color(0xFF1E2235)),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (entry.steps.isNotEmpty) ...[
              Theme(
                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  collapsedIconColor: Colors.grey,
                  iconColor: const Color(0xFF6366F1),
                  title: Row(
                    children: [
                      const Icon(Icons.commit, size: 16, color: Color(0xFF6366F1)),
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
              const Divider(color: Color(0xFF1E2235), height: 16),
            ],
            MarkdownBody(
              data: entry.text,
              styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                p: const TextStyle(fontSize: 15, height: 1.45, color: Color(0xFFE2E8F0)),
                code: const TextStyle(backgroundColor: Color(0xFF1E2235), color: Color(0xFF93C5FD)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveExecutionStatus() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF13151F),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              SizedBox(
                width: 14, height: 14,
                child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF6366F1)),
              ),
              SizedBox(width: 10),
              Text('Kinetiq is executing...', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF6366F1))),
            ],
          ),
          const SizedBox(height: 8),
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
        color = const Color(0xFF8B5CF6);
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
        color: Color(0xFF0C0E14),
        border: Border(top: BorderSide(color: Color(0xFF171923))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF141724),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFF222638)),
              ),
              child: TextField(
                controller: _promptController,
                style: const TextStyle(fontSize: 15),
                decoration: const InputDecoration(
                  hintText: 'Ask Kinetiq to search, browse, or execute...',
                  hintStyle: TextStyle(color: Color(0xFF64748B), fontSize: 14),
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
              width: 46, height: 46,
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF4F46E5)]),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _isProcessing ? Icons.hourglass_top : Icons.arrow_upward,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}