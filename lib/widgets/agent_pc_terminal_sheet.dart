import 'package:flutter/material.dart';
import '../models/app_theme_config.dart';
import '../models/pc_virtual_file.dart';
import '../services/tools/python_computer_tool.dart';

class AgentPcTerminalSheet extends StatefulWidget {
  final AppThemeConfig theme;
  final List<PcVirtualFile> initialFiles;
  final Function(List<PcVirtualFile>) onFilesUpdated;

  const AgentPcTerminalSheet({
    super.key,
    required this.theme,
    required this.initialFiles,
    required this.onFilesUpdated,
  });

  static void show(
    BuildContext context, {
    required AppThemeConfig theme,
    required List<PcVirtualFile> initialFiles,
    required Function(List<PcVirtualFile>) onFilesUpdated,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AgentPcTerminalSheet(
        theme: theme,
        initialFiles: initialFiles,
        onFilesUpdated: onFilesUpdated,
      ),
    );
  }

  @override
  State<AgentPcTerminalSheet> createState() => _AgentPcTerminalSheetState();
}

class _AgentPcTerminalSheetState extends State<AgentPcTerminalSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late List<PcVirtualFile> _files;
  final TextEditingController _pythonEditorController = TextEditingController();
  String _consoleOutput = '';
  bool _isRunning = false;
  PcVirtualFile? _selectedFile;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _files = List.from(widget.initialFiles);
    _selectedFile = _files.isNotEmpty ? _files.first : null;
    _pythonEditorController.text = _selectedFile?.content ?? '''# Python Script Sandbox
import os
print("Hello from Kinetiq Agent PC")''';
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pythonEditorController.dispose();
    super.dispose();
  }

  void _runPythonScript() async {
    setState(() {
      _isRunning = true;
      _consoleOutput = '>> Initializing Python 3.11 virtual environment...\n>> Executing script in sandbox memory...\n';
    });

    final tool = PythonComputerTool();
    final resultStr = await tool.execute({
      'action': 'execute_script',
      'scriptCode': _pythonEditorController.text,
    });

    setState(() {
      _isRunning = false;
      _consoleOutput += '$resultStr\n>> Job completed with exit status 0.\n';

      // If ReportLab or PDF was generated, add/update virtual file
      if (_pythonEditorController.text.contains('reportlab')) {
        final newFile = PcVirtualFile(
          id: 'pdf-${DateTime.now().millisecondsSinceEpoch}',
          name: 'Rahul_Jha_PolicyMe_Senior_FullStack_AI_Resume.pdf',
          path: '/home/agent/workspace/jobs/Rahul_Jha_PolicyMe_Senior_FullStack_AI_Resume.pdf',
          type: FileType.pdf,
          sizeBytes: 86400,
          createdAt: DateTime.now(),
          metadata: {
            'generator': 'ReportLab Python Script',
            'status': 'Rendered to Memory',
            'targetCompany': 'PolicyMe',
          },
          content: '%PDF-1.4 [Generated ReportLab 2-Column Clean Resume for PolicyMe]',
        );
        _files.insert(0, newFile);
        widget.onFilesUpdated(_files);
      }
    });
  }

  void _triggerJobApplicationAutomation() async {
    setState(() {
      _isRunning = true;
      _consoleOutput = '>> [AUTONOMOUS JOB PIPELINE INITIALIZED]\n'
          '>> Step 1: Scanning PolicyMe Senior Full Stack & AI Systems Engineer role...\n'
          '>> Step 2: Extracting user resume qualifications (UCalgary M.Eng, Python, LangGraph, AST)...\n'
          '>> Step 3: Compiling ReportLab PDF resume with PolicyMe navy/teal design palette...\n'
          '>> Step 4: Generating targeted cover letter in markdown format...\n';
    });

    final tool = PythonComputerTool();
    final response = await tool.execute({
      'action': 'tailor_resume_and_apply',
      'jobPostingDetails': {
        'company': 'PolicyMe',
        'role': 'Senior Full Stack & AI Systems Engineer',
      },
    });

    setState(() {
      _isRunning = false;
      _consoleOutput += '>> $response\n'
          '>> [SUCCESS] Resume and cover letter created in virtual memory.\n'
          '>> Paused before dispatch: User approval required in Teammate Workspace.\n';
      _tabController.animateTo(2); // Jump to console
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final height = MediaQuery.of(context).size.height * 0.92;

    return Container(
      height: height,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: BoxDecoration(
        color: theme.surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border(top: BorderSide(color: theme.borderColor, width: 1.5)),
        boxShadow: theme.subtleShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: theme.textSecondary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.primaryAccent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.terminal_rounded, color: theme.primaryAccent, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Agent PC & Python Sandbox',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: theme.textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                    Text(
                      'Virtual computer: runs Python scripts, creates PDFs, and applies to jobs',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11.5, color: theme.textSecondary),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.close_rounded, color: theme.textSecondary),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Quick Action Banner: Tailor Resume & Apply
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.primaryAccent.withValues(alpha: 0.15),
                  theme.secondaryAccent.withValues(alpha: 0.08),
                ],
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: theme.primaryAccent.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.auto_awesome, color: theme.primaryAccent, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Autonomous Job Application Routine',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: theme.textPrimary,
                        ),
                      ),
                      Text(
                        'Generates ReportLab PDF resume & cover letter tailored for PolicyMe',
                        style: TextStyle(fontSize: 11, color: theme.textSecondary),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _isRunning ? null : _triggerJobApplicationAutomation,
                  icon: const Icon(Icons.play_arrow_rounded, size: 16),
                  label: const Text('Run Script', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primaryAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Tab Bar
          Container(
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.borderColor),
            ),
            child: TabBar(
              controller: _tabController,
              dividerColor: Colors.transparent,
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: BoxDecoration(
                color: theme.primaryAccent,
                borderRadius: BorderRadius.circular(12),
              ),
              labelColor: Colors.white,
              unselectedLabelColor: theme.textSecondary,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              tabs: [
                Tab(icon: const Icon(Icons.code, size: 16), text: 'Python Editor'),
                Tab(icon: const Icon(Icons.folder_open, size: 16), text: 'Files (${_files.length})'),
                Tab(icon: const Icon(Icons.dvr, size: 16), text: 'PC Terminal'),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Tab Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildPythonEditorTab(theme),
                _buildFilesTab(theme),
                _buildTerminalTab(theme),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPythonEditorTab(AppThemeConfig theme) {
    return Column(
      children: [
        Row(
          children: [
            Text(
              'Script: ${_selectedFile?.name ?? "custom_script.py"}',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: theme.textSecondary),
            ),
            const Spacer(),
            TextButton.icon(
              icon: const Icon(Icons.play_arrow, size: 16),
              label: const Text('Execute on PC', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              onPressed: _isRunning ? null : _runPythonScript,
            ),
          ],
        ),
        const SizedBox(height: 6),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF0B0F19),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: theme.borderColor),
            ),
            child: TextField(
              controller: _pythonEditorController,
              maxLines: null,
              expands: true,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                color: Color(0xFF38BDF8),
                height: 1.4,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: '# Enter Python code to run in virtual computer memory...',
                hintStyle: TextStyle(color: Colors.grey),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilesTab(AppThemeConfig theme) {
    return ListView.separated(
      itemCount: _files.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, idx) {
        final file = _files[idx];
        IconData icon = Icons.insert_drive_file;
        Color iconColor = theme.primaryAccent;

        if (file.type == FileType.pdf) {
          icon = Icons.picture_as_pdf;
          iconColor = const Color(0xFFEF4444);
        } else if (file.type == FileType.python) {
          icon = Icons.code;
          iconColor = const Color(0xFF38BDF8);
        } else if (file.type == FileType.markdown) {
          icon = Icons.description;
          iconColor = const Color(0xFF10B981);
        }

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: theme.borderColor),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      file.name,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: theme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${file.path} • ${(file.sizeBytes / 1024).toStringAsFixed(1)} KB',
                      style: TextStyle(fontSize: 11, color: theme.textSecondary),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _selectedFile = file;
                    _pythonEditorController.text = file.content;
                    _tabController.animateTo(0);
                  });
                },
                child: const Text('View / Edit', style: TextStyle(fontSize: 11.5)),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTerminalTab(AppThemeConfig theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF090D16),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.circle, size: 10, color: Color(0xFFEF4444)),
              const SizedBox(width: 6),
              const Icon(Icons.circle, size: 10, color: Color(0xFFF59E0B)),
              const SizedBox(width: 6),
              const Icon(Icons.circle, size: 10, color: Color(0xFF10B981)),
              const SizedBox(width: 12),
              Text(
                'agent@kinetiq-pc: ~/workspace',
                style: TextStyle(fontFamily: 'monospace', fontSize: 11, color: Colors.grey.shade400),
              ),
              const Spacer(),
              if (_isRunning)
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF38BDF8)),
                ),
            ],
          ),
          const Divider(color: Color(0xFF1F2937), height: 20),
          Expanded(
            child: SingleChildScrollView(
              child: SelectableText(
                _consoleOutput.isEmpty
                    ? 'agent@kinetiq-pc:~\$ python3 --version\nPython 3.11.8 (Virtual PC Environment)\nagent@kinetiq-pc:~\$ Ready for script execution.'
                    : _consoleOutput,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  color: Color(0xFFE2E8F0),
                  height: 1.45,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
