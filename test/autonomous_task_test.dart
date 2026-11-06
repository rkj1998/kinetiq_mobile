import 'package:flutter_test/flutter_test.dart';
import 'package:kinetiq_mobile/models/autonomous_task.dart';

void main() {
  group('AutonomousTask Tests', () {
    test('serializes and deserializes task with approval request', () {
      final task = AutonomousTask(
        id: 'test-123',
        title: 'Draft client invoice',
        assignedBotName: 'Titan',
        assignedBotRole: 'Systems Architect',
        status: TaskStatus.needsApproval,
        progress: 0.9,
        summary: 'Invoice generated, waiting for approval',
        executionLog: ['Verified pricing table', 'Drafted PDF'],
        pendingApproval: AgentApprovalRequest(
          id: 'appr-123',
          title: 'Approve invoice send',
          description: 'Send invoice of \$500 to customer',
          actionType: 'Invoice',
          riskLevel: ActionRiskLevel.high,
          payload: {'amount': 500},
          requestedAt: DateTime.now(),
        ),
        createdAt: DateTime.now(),
      );

      final serialized = AutonomousTask.serializeList([task]);
      final list = AutonomousTask.deserializeList(serialized);

      expect(list.length, 1);
      expect(list.first.id, 'test-123');
      expect(list.first.title, 'Draft client invoice');
      expect(list.first.status, TaskStatus.needsApproval);
      expect(list.first.pendingApproval, isNotNull);
      expect(list.first.pendingApproval!.title, 'Approve invoice send');
      expect(list.first.pendingApproval!.riskLevel, ActionRiskLevel.high);
    });

    test('approving task clears pending approval and marks 100% complete', () {
      final task = AutonomousTask(
        id: 'test-456',
        title: 'Send newsletter',
        assignedBotName: 'Spark',
        assignedBotRole: 'Productivity',
        status: TaskStatus.needsApproval,
        progress: 0.8,
        summary: 'Waiting for sign-off',
        pendingApproval: AgentApprovalRequest(
          id: 'appr-456',
          title: 'Approve send',
          description: 'Ready to send email',
          actionType: 'Email',
          payload: {},
          requestedAt: DateTime.now(),
        ),
        createdAt: DateTime.now(),
      );

      final approved = task.copyWith(
        status: TaskStatus.completed,
        progress: 1.0,
        clearPendingApproval: true,
        completedAt: DateTime.now(),
      );

      expect(approved.status, TaskStatus.completed);
      expect(approved.progress, 1.0);
      expect(approved.pendingApproval, isNull);
      expect(approved.completedAt, isNotNull);
    });
  });
}
