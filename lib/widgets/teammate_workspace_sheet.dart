import 'package:flutter/material.dart';
import '../models/app_theme_config.dart';
import '../models/autonomous_task.dart';
import '../models/agent_character.dart';

class TeammateWorkspaceSheet extends StatefulWidget {
  final AppThemeConfig theme;
  final List<AutonomousTask> tasks;
  final Function(AutonomousTask) onTaskApproved;
  final Function(AutonomousTask) onNewTaskSubmitted;

  const TeammateWorkspaceSheet({
    super.key,
    required this.theme,
    required this.tasks,
    required this.onTaskApproved,
    required this.onNewTaskSubmitted,
  });

  static void show(
    BuildContext context, {
    required AppThemeConfig theme,
    required List<AutonomousTask> tasks,
    required Function(AutonomousTask) onTaskApproved,
    required Function(AutonomousTask) onNewTaskSubmitted,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => TeammateWorkspaceSheet(
        theme: theme,
        tasks: tasks,
        onTaskApproved: onTaskApproved,
        onNewTaskSubmitted: onNewTaskSubmitted,
      ),
    );
  }

  @override
  State<TeammateWorkspaceSheet> createState() => _TeammateWorkspaceSheetState();
}

class _TeammateWorkspaceSheetState extends State<TeammateWorkspaceSheet> {
  late List<AutonomousTask> _taskList;
  final TextEditingController _taskTitleController = TextEditingController();
  String _selectedTeammateId = 'antigravity';

  @override
  void initState() {
    super.initState();
    _taskList = List.from(widget.tasks);
  }

  @override
  void dispose() {
    _taskTitleController.dispose();
    super.dispose();
  }

  void _approveTask(AutonomousTask task) {
    setState(() {
      final index = _taskList.indexWhere((t) => t.id == task.id);
      if (index != -1) {
        final updated = _taskList[index].copyWith(
          status: TaskStatus.completed,
          progress: 1.0,
          clearPendingApproval: true,
          completedAt: DateTime.now(),
          executionLog: [
            ..._taskList[index].executionLog,
            'User approved action via Safety Vault at ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}.',
            'Action executed end-to-end with verified confirmation.',
          ],
        );
        _taskList[index] = updated;
        widget.onTaskApproved(updated);
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Action approved and finished: ${task.title}'),
        backgroundColor: const Color(0xFF059669),
      ),
    );
  }

  void _createAndHandOffTask() {
    final title = _taskTitleController.text.trim();
    if (title.isEmpty) return;

    final assignedBot = AgentCharacter.presets.firstWhere(
      (b) => b.id == _selectedTeammateId,
      orElse: () => AgentCharacter.presets.first,
    );

    final newTask = AutonomousTask(
      id: 'task-${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      assignedBotName: assignedBot.name,
      assignedBotRole: assignedBot.role,
      status: TaskStatus.running,
      progress: 0.35,
      summary: 'Task handed off to ${assignedBot.name}\'s cloud VM. Executing multi-step routine...',
      executionLog: [
        'Task received and queued in isolated teammate container.',
        'Analyzing required tools and setting up browser session.',
      ],
      createdAt: DateTime.now(),
    );

    setState(() {
      _taskList.insert(0, newTask);
    });
    _taskTitleController.clear();
    widget.onNewTaskSubmitted(newTask);

    // Simulate completion after a few seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          final idx = _taskList.indexWhere((t) => t.id == newTask.id);
          if (idx != -1) {
            _taskList[idx] = _taskList[idx].copyWith(
              status: TaskStatus.completed,
              progress: 1.0,
              summary: 'Job 100% completed end-to-end. Context stored to team memory.',
              completedAt: DateTime.now(),
              executionLog: [
                ..._taskList[idx].executionLog,
                'Routine completed autonomously without stalling.',
                'Handed off results to user workspace.',
              ],
            );
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final height = MediaQuery.of(context).size.height * 0.90;

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
                child: Icon(Icons.hub_outlined, color: theme.primaryAccent, size: 22),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AI Teammate Workspace',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: theme.textPrimary,
                      letterSpacing: -0.3,
                    ),
                  ),
                  Text(
                    'Hand off real multi-step jobs to bots with their own computer',
                    style: TextStyle(fontSize: 11.5, color: theme.textSecondary),
                  ),
                ],
              ),
              const Spacer(),
              IconButton(
                icon: Icon(Icons.close_rounded, color: theme.textSecondary),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Hand off a New Job Card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: theme.borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.forward_to_inbox, size: 16, color: theme.primaryAccent),
                    const SizedBox(width: 8),
                    Text(
                      'Hand Off Work to a Teammate',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: theme.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _taskTitleController,
                  style: TextStyle(fontSize: 13.5, color: theme.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'e.g. Scrape AI product launches, summarize & draft email',
                    hintStyle: TextStyle(fontSize: 12, color: theme.textSecondary),
                    filled: true,
                    fillColor: theme.inputBackgroundColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: theme.borderColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: theme.borderColor),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Text(
                      'Assign To:',
                      style: TextStyle(fontSize: 12, color: theme.textSecondary, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: AgentCharacter.presets.map((b) {
                            final isSel = b.id == _selectedTeammateId;
                            return Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: ChoiceChip(
                                label: Text(b.name, style: TextStyle(fontSize: 11, color: isSel ? Colors.white : theme.textPrimary)),
                                selected: isSel,
                                selectedColor: theme.primaryAccent,
                                onSelected: (val) {
                                  if (val) setState(() => _selectedTeammateId = b.id);
                                },
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: _createAndHandOffTask,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.primaryAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Hand Off', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),
          Text(
            'Active Jobs & Approvals (${_taskList.length})',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: theme.textPrimary,
            ),
          ),
          const SizedBox(height: 10),

          // Task List
          Expanded(
            child: ListView.separated(
              itemCount: _taskList.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, idx) {
                final task = _taskList[idx];
                return _buildTaskCard(task, theme);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCard(AutonomousTask task, AppThemeConfig theme) {
    Color statusColor;
    String statusLabel;
    IconData statusIcon;

    switch (task.status) {
      case TaskStatus.completed:
        statusColor = const Color(0xFF059669);
        statusLabel = '100% Done';
        statusIcon = Icons.check_circle_rounded;
        break;
      case TaskStatus.needsApproval:
        statusColor = const Color(0xFFD97706);
        statusLabel = 'Approval Needed';
        statusIcon = Icons.shield_outlined;
        break;
      case TaskStatus.running:
        statusColor = theme.primaryAccent;
        statusLabel = 'Autonomous In Cloud VM';
        statusIcon = Icons.autorenew_rounded;
        break;
      case TaskStatus.failed:
        statusColor = const Color(0xFFEF4444);
        statusLabel = 'Needs Intervention';
        statusIcon = Icons.error_outline;
        break;
      case TaskStatus.queued:
        statusColor = theme.textSecondary;
        statusLabel = 'Queued';
        statusIcon = Icons.access_time;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: task.pendingApproval != null ? const Color(0xFFD97706) : theme.borderColor,
          width: task.pendingApproval != null ? 1.8 : 1.0,
        ),
        boxShadow: theme.subtleShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, size: 12, color: statusColor),
                    const SizedBox(width: 4),
                    Text(
                      statusLabel,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                'Assigned to ${task.assignedBotName}',
                style: TextStyle(fontSize: 11, color: theme.textSecondary, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            task.title,
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.bold,
              color: theme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            task.summary,
            style: TextStyle(fontSize: 12, color: theme.textSecondary, height: 1.35),
          ),

          // Approval Alert Banner (Muse-style User in the loop)
          if (task.pendingApproval != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFD97706).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFD97706).withValues(alpha: 0.4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.security, size: 16, color: Color(0xFFD97706)),
                      const SizedBox(width: 8),
                      Text(
                        task.pendingApproval!.title,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: theme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    task.pendingApproval!.description,
                    style: TextStyle(fontSize: 11.5, color: theme.textSecondary),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton.icon(
                        icon: const Icon(Icons.check, size: 14),
                        label: const Text('Approve & Finish Action', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD97706),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () => _approveTask(task),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],

          // Progress indicator
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: task.progress,
              backgroundColor: theme.borderColor,
              valueColor: AlwaysStoppedAnimation(statusColor),
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }
}
