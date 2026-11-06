import 'package:flutter_test/flutter_test.dart';
import 'package:kinetiq_mobile/models/pc_virtual_file.dart';
import 'package:kinetiq_mobile/services/tools/python_computer_tool.dart';

void main() {
  group('PcVirtualFile & PythonComputerTool Tests', () {
    test('serializes and deserializes PC virtual files correctly', () {
      final file = PcVirtualFile(
        id: 'test-py',
        name: 'test_script.py',
        path: '/home/agent/workspace/test_script.py',
        type: FileType.python,
        content: 'print("Running Python on Agent PC")',
        sizeBytes: 32,
        createdAt: DateTime.now(),
      );

      final raw = PcVirtualFile.serializeList([file]);
      final list = PcVirtualFile.deserializeList(raw);

      expect(list.length, 1);
      expect(list.first.name, 'test_script.py');
      expect(list.first.type, FileType.python);
      expect(list.first.content, contains('Running Python on Agent PC'));
    });

    test('PythonComputerTool executes ReportLab resume script and renders PDF output', () async {
      final tool = PythonComputerTool();
      final result = await tool.execute({
        'action': 'execute_script',
        'scriptCode': '''
from reportlab.lib.pagesizes import letter
filename = "PolicyMe_Resume.pdf"
print("Generating PDF document...")
''',
      });

      expect(result, contains('SUCCESS'));
      expect(result, contains('PolicyMe_Resume.pdf'));
      expect(PythonComputerTool.inMemoryFiles.containsKey('/home/agent/workspace/jobs/PolicyMe_Resume.pdf'), isTrue);
    });

    test('tailor_resume_and_apply generates tailored resume and cover letter', () async {
      final tool = PythonComputerTool();
      final result = await tool.execute({
        'action': 'tailor_resume_and_apply',
        'jobPostingDetails': {
          'company': 'PolicyMe',
          'role': 'Senior Full Stack & AI Systems Engineer',
        },
      });

      expect(result, contains('TAILORED_AND_READY'));
      expect(result, contains('PolicyMe'));
      expect(result, contains('needsApproval'));
    });
  });
}
