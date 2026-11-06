import 'dart:convert';

enum TaskStatus {
  queued,
  running,
  needsApproval,
  completed,
  failed,
}

enum ActionRiskLevel {
  low,
  medium,
  high, // e.g. purchasing, sending emails, deleting data
}

class AgentApprovalRequest {
  final String id;
  final String title;
  final String description;
  final String actionType;
  final ActionRiskLevel riskLevel;
  final Map<String, dynamic> payload;
  final DateTime requestedAt;

  const AgentApprovalRequest({
    required this.id,
    required this.title,
    required this.description,
    required this.actionType,
    this.riskLevel = ActionRiskLevel.medium,
    required this.payload,
    required this.requestedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'actionType': actionType,
    'riskLevel': riskLevel.name,
    'payload': payload,
    'requestedAt': requestedAt.toIso8601String(),
  };

  factory AgentApprovalRequest.fromJson(Map<String, dynamic> json) => AgentApprovalRequest(
    id: json['id'] as String? ?? '',
    title: json['title'] as String? ?? 'Action Approval Needed',
    description: json['description'] as String? ?? '',
    actionType: json['actionType'] as String? ?? 'action',
    riskLevel: ActionRiskLevel.values.firstWhere(
      (r) => r.name == json['riskLevel'],
      orElse: () => ActionRiskLevel.medium,
    ),
    payload: json['payload'] as Map<String, dynamic>? ?? {},
    requestedAt: json['requestedAt'] != null
        ? DateTime.tryParse(json['requestedAt'] as String) ?? DateTime.now()
        : DateTime.now(),
  );
}

class AutonomousTask {
  final String id;
  final String title;
  final String assignedBotName;
  final String assignedBotRole;
  final TaskStatus status;
  final double progress; // 0.0 to 1.0
  final String summary;
  final List<String> executionLog;
  final AgentApprovalRequest? pendingApproval;
  final DateTime createdAt;
  final DateTime? completedAt;

  const AutonomousTask({
    required this.id,
    required this.title,
    required this.assignedBotName,
    required this.assignedBotRole,
    this.status = TaskStatus.queued,
    this.progress = 0.0,
    required this.summary,
    this.executionLog = const [],
    this.pendingApproval,
    required this.createdAt,
    this.completedAt,
  });

  AutonomousTask copyWith({
    String? title,
    String? assignedBotName,
    String? assignedBotRole,
    TaskStatus? status,
    double? progress,
    String? summary,
    List<String>? executionLog,
    AgentApprovalRequest? pendingApproval,
    bool clearPendingApproval = false,
    DateTime? completedAt,
  }) {
    return AutonomousTask(
      id: id,
      title: title ?? this.title,
      assignedBotName: assignedBotName ?? this.assignedBotName,
      assignedBotRole: assignedBotRole ?? this.assignedBotRole,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      summary: summary ?? this.summary,
      executionLog: executionLog ?? this.executionLog,
      pendingApproval: clearPendingApproval ? null : (pendingApproval ?? this.pendingApproval),
      createdAt: createdAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'assignedBotName': assignedBotName,
    'assignedBotRole': assignedBotRole,
    'status': status.name,
    'progress': progress,
    'summary': summary,
    'executionLog': executionLog,
    'pendingApproval': pendingApproval?.toJson(),
    'createdAt': createdAt.toIso8601String(),
    'completedAt': completedAt?.toIso8601String(),
  };

  factory AutonomousTask.fromJson(Map<String, dynamic> json) => AutonomousTask(
    id: json['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
    title: json['title'] as String? ?? 'Untitled Task',
    assignedBotName: json['assignedBotName'] as String? ?? 'Antigravity',
    assignedBotRole: json['assignedBotRole'] as String? ?? 'Autonomous Teammate',
    status: TaskStatus.values.firstWhere(
      (s) => s.name == json['status'],
      orElse: () => TaskStatus.queued,
    ),
    progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
    summary: json['summary'] as String? ?? '',
    executionLog: (json['executionLog'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
    pendingApproval: json['pendingApproval'] != null
        ? AgentApprovalRequest.fromJson(json['pendingApproval'] as Map<String, dynamic>)
        : null,
    createdAt: json['createdAt'] != null
        ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
        : DateTime.now(),
    completedAt: json['completedAt'] != null
        ? DateTime.tryParse(json['completedAt'] as String)
        : null,
  );

  static List<AutonomousTask> deserializeList(String? raw) {
    if (raw == null || raw.trim().isEmpty) return defaultDemoTasks;
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list.map((e) => AutonomousTask.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return defaultDemoTasks;
    }
  }

  static String serializeList(List<AutonomousTask> tasks) =>
      jsonEncode(tasks.map((t) => t.toJson()).toList());

  static final List<AutonomousTask> defaultDemoTasks = [
    AutonomousTask(
      id: 'task-1',
      title: 'Analyze HackerNews & Extract Top 5 AI Breakdowns',
      assignedBotName: 'Cipher',
      assignedBotRole: 'Autonomous Scout',
      status: TaskStatus.completed,
      progress: 1.0,
      summary: 'Scraped live feeds, synthesized key trends on on-device LLMs, and saved brief to memory.',
      executionLog: [
        'Initialized secure cloud VM browser session.',
        'Queried news endpoints and extracted 5 top stories.',
        'Synthesized markdown report and appended to local fact bank.',
      ],
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      completedAt: DateTime.now().subtract(const Duration(minutes: 90)),
    ),
    AutonomousTask(
      id: 'task-2',
      title: 'Dispatch Follow-up Briefing & Sync Calendar',
      assignedBotName: 'Antigravity',
      assignedBotRole: 'Chief of Staff',
      status: TaskStatus.needsApproval,
      progress: 0.85,
      summary: 'Drafted follow-up email and prepared calendar invite for project launch sync.',
      executionLog: [
        'Parsed user instructions and checked system time.',
        'Prepared message body with verified action items.',
        'Paused for user approval before dispatch (Muse Safety Shield active).',
      ],
      pendingApproval: AgentApprovalRequest(
        id: 'appr-1',
        title: 'Approve Outbound Email Dispatch',
        description: 'Send weekly status report to engineering team with calendar invite.',
        actionType: 'Send Email',
        riskLevel: ActionRiskLevel.high,
        payload: {
          'recipient': 'team@kinetiq.ai',
          'subject': 'Antigravity Sprint Update & Autonomous Launch',
        },
        requestedAt: DateTime.now().subtract(const Duration(minutes: 10)),
      ),
      createdAt: DateTime.now().subtract(const Duration(minutes: 45)),
    ),
  ];
}
