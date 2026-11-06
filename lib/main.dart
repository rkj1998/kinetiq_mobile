import 'package:flutter/material.dart';
import 'services/llm/openai_adapter.dart';
import 'services/tools/tool_registry.dart';
import 'services/tools/mock_time_tool.dart';
import 'services/agent/react_loop.dart';

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: KinetiqRunnerScreen(),
  ));
}

class KinetiqRunnerScreen extends StatefulWidget {
  const KinetiqRunnerScreen({super.key});

  @override
  State<KinetiqRunnerScreen> createState() => _KinetiqRunnerScreenState();
}

class _KinetiqRunnerScreenState extends State<KinetiqRunnerScreen> {
  final TextEditingController _apiKeyController = TextEditingController();
  final TextEditingController _promptController = TextEditingController(
    text: "Check my local device clock and tell me the current time.",
  );
  final List<AgentStep> _steps = [];
  bool _isRunning = false;

  void _executeLoop() async {
    if (_apiKeyController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please provide your Groq API Key')),
      );
      return;
    }

    setState(() {
      _steps.clear();
      _isRunning = true;
    });

    final registry = ToolRegistry()..registerTool(GetSystemTimeTool());

    final adapter = OpenAIAdapter(
      apiKey: _apiKeyController.text.trim(),
      baseUrl: 'https://api.groq.com/openai/v1',
    );

    final agent = ReActAgent(
      client: adapter,
      registry: registry,
      model: 'llama-3.3-70b-versatile',
    );

    await for (final step in agent.run(
      userPrompt: _promptController.text.trim(),
      history: [],
    )) {
      setState(() {
        _steps.add(step);
      });
    }

    setState(() {
      _isRunning = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kinetiq — Phase 1 Test Bench'),
        backgroundColor: Colors.blueGrey.shade900,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _apiKeyController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Groq API Key (gsk_...)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _promptController,
              decoration: const InputDecoration(
                labelText: 'User Prompt',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _isRunning ? null : _executeLoop,
              icon: _isRunning
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.play_arrow),
              label: Text(_isRunning ? 'Agent Executing...' : 'Run Kinetiq Loop'),
            ),
            const Divider(height: 24),
            Expanded(
              child: ListView.builder(
                itemCount: _steps.length,
                itemBuilder: (context, index) {
                  final step = _steps[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: ListTile(
                      leading: Icon(
                        step.type == StepType.toolCall
                            ? Icons.build_circle
                            : step.type == StepType.toolResult
                                ? Icons.check_circle_outline
                                : step.type == StepType.finalAnswer
                                    ? Icons.chat_bubble
                                    : Icons.psychology,
                        color: step.type == StepType.error ? Colors.red : null,
                      ),
                      title: Text('${step.type.name.toUpperCase()}: ${step.title}'),
                      subtitle: Text(step.content),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
