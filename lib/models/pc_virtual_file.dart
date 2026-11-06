import 'dart:convert';

enum FileType {
  python,
  pdf,
  markdown,
  text,
  json,
}

class PcVirtualFile {
  final String id;
  final String name;
  final String path;
  final FileType type;
  final String content;
  final int sizeBytes;
  final DateTime createdAt;
  final Map<String, dynamic> metadata;

  const PcVirtualFile({
    required this.id,
    required this.name,
    required this.path,
    required this.type,
    required this.content,
    required this.sizeBytes,
    required this.createdAt,
    this.metadata = const {},
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'path': path,
    'type': type.name,
    'content': content,
    'sizeBytes': sizeBytes,
    'createdAt': createdAt.toIso8601String(),
    'metadata': metadata,
  };

  factory PcVirtualFile.fromJson(Map<String, dynamic> json) => PcVirtualFile(
    id: json['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
    name: json['name'] as String? ?? 'untitled.txt',
    path: json['path'] as String? ?? '/home/agent/workspace',
    type: FileType.values.firstWhere(
      (t) => t.name == json['type'],
      orElse: () => FileType.text,
    ),
    content: json['content'] as String? ?? '',
    sizeBytes: json['sizeBytes'] as int? ?? 0,
    createdAt: json['createdAt'] != null
        ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
        : DateTime.now(),
    metadata: json['metadata'] as Map<String, dynamic>? ?? const {},
  );

  static List<PcVirtualFile> deserializeList(String? raw) {
    if (raw == null || raw.trim().isEmpty) return defaultDemoFiles;
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list.map((e) => PcVirtualFile.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return defaultDemoFiles;
    }
  }

  static String serializeList(List<PcVirtualFile> files) =>
      jsonEncode(files.map((f) => f.toJson()).toList());

  static final List<PcVirtualFile> defaultDemoFiles = [
    PcVirtualFile(
      id: 'file-py-resume-builder',
      name: 'generate_tailored_resume.py',
      path: '/home/agent/workspace/jobs/generate_tailored_resume.py',
      type: FileType.python,
      sizeBytes: 4210,
      createdAt: DateTime.now().subtract(const Duration(hours: 1)),
      metadata: {'purpose': 'Custom PDF resume generator using ReportLab', 'targetRole': 'Senior Full Stack & AI Systems Engineer'},
      content: '''import os
from reportlab.lib.pagesizes import letter
from reportlab.lib import colors
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle
from reportlab.lib.styles import ParagraphStyle

# Brand-Aligned Visual Palette
PRIMARY = colors.HexColor("#0d2137")        # Deep Trust Navy
TEAL_ACCENT = colors.HexColor("#0e9488")    # Modern InsurTech Teal
DARK_TEXT = colors.HexColor("#1f2937")      # Charcoal body text
MUTED_TEXT = colors.HexColor("#4b5563")     # Metadata grey
LIGHT_BG = colors.HexColor("#f0fdfa")       # Soft mint/cyan sidebar tint
LINE_COLOR = colors.HexColor("#cbd5e1")     # Structural Divider

def build_policyme_resume(filename="Rahul_Jha_PolicyMe_Senior_FullStack_AI_Resume.pdf"):
    doc = SimpleDocTemplate(
        filename,
        pagesize=letter,
        leftMargin=24,
        rightMargin=24,
        topMargin=22,
        bottomMargin=22
    )

    style_name = ParagraphStyle('Name', fontName='Helvetica-Bold', fontSize=18, leading=21, textColor=PRIMARY, spaceAfter=2)
    style_target_title = ParagraphStyle('TargetTitle', fontName='Helvetica-Bold', fontSize=8.8, leading=11, textColor=TEAL_ACCENT, spaceAfter=5)
    style_sidebar_h = ParagraphStyle('SidebarH', fontName='Helvetica-Bold', fontSize=9, leading=11.5, textColor=PRIMARY, spaceBefore=6, spaceAfter=2.5, textTransform='uppercase')
    style_main_h = ParagraphStyle('MainH', fontName='Helvetica-Bold', fontSize=9.5, leading=12, textColor=PRIMARY, spaceBefore=6, spaceAfter=3, textTransform='uppercase')
    style_sidebar_body = ParagraphStyle('SidebarB', fontName='Helvetica', fontSize=7.5, leading=9.8, textColor=DARK_TEXT, spaceAfter=2.5)
    style_sidebar_meta = ParagraphStyle('SidebarM', fontName='Helvetica', fontSize=7.2, leading=9.2, textColor=MUTED_TEXT, spaceAfter=4)
    style_job_title = ParagraphStyle('JobTitle', fontName='Helvetica-Bold', fontSize=8.6, leading=10.5, textColor=PRIMARY)
    style_job_meta = ParagraphStyle('JobMeta', fontName='Helvetica-Bold', fontSize=7.6, leading=9.5, textColor=TEAL_ACCENT, spaceAfter=1.5)
    style_body = ParagraphStyle('Body', fontName='Helvetica', fontSize=7.5, leading=9.8, textColor=DARK_TEXT, spaceAfter=2.5)
    style_bullet = ParagraphStyle('Bullet', fontName='Helvetica', fontSize=7.3, leading=9.4, textColor=DARK_TEXT, leftIndent=7, firstLineIndent=-7, spaceAfter=1.5)

    # Left Column (Sidebar)
    left_flow = []
    left_flow.append(Paragraph("CONTACT", style_sidebar_h))
    left_flow.append(Paragraph("<b>Email:</b> rahuljha190398@gmail.com", style_sidebar_body))
    left_flow.append(Paragraph("<b>Phone:</b> (782) 778-5607", style_sidebar_body))
    left_flow.append(Paragraph("<b>Location:</b> Canada (Remote)", style_sidebar_body))
    left_flow.append(Paragraph("<b>Work Auth:</b> Authorized in Canada (No Sponsorship)", style_sidebar_body))

    left_flow.append(Paragraph("EDUCATION", style_sidebar_h))
    left_flow.append(Paragraph("<b>M.Eng. Electrical & Computer</b>", style_sidebar_body))
    left_flow.append(Paragraph("University of Calgary | 2024<br/><b>GPA: 3.64 / 4.0</b>", style_sidebar_meta))

    left_flow.append(Paragraph("TECHNICAL PROFICIENCIES", style_sidebar_h))
    left_flow.append(Paragraph("<b>Full Stack:</b> Python, React, Redux, Node.js, TypeScript, REST APIs, Flask", style_sidebar_body))
    left_flow.append(Paragraph("<b>AI & Agentic Systems:</b> LangChain, LangGraph, Tool Calling, RAG Pipelines, Schema Enforcement", style_sidebar_body))
    left_flow.append(Paragraph("<b>Cloud & Security:</b> AWS (Lambda, S3), GCP, Docker, Kubernetes, CI/CD", style_sidebar_body))

    # Right Column (Main Experience)
    right_flow = []
    right_flow.append(Paragraph("RAHUL JHA", style_name))
    right_flow.append(Paragraph("Senior Software Engineer | Full Stack Systems, Python/React, AI Agents & Cloud Infrastructure", style_target_title))
    right_flow.append(Paragraph("PROFESSIONAL SUMMARY", style_main_h))
    right_flow.append(Paragraph(
        "Full Stack and Systems Engineer with a Master’s degree in Electrical & Computer Engineering from the "
        "University of Calgary (GPA: 3.64). Demonstrated track record of architecting scalable web applications, "
        "integrating autonomous AI agentic workflows (LangChain, LangGraph concepts, AST validation), and operating "
        "high-reliability cloud services across AWS.", style_body))

    right_flow.append(Paragraph("PROFESSIONAL EXPERIENCE", style_main_h))
    right_flow.append(Paragraph("Lead Backend & AI Systems Developer", style_job_title))
    right_flow.append(Paragraph("TR PRO | Calgary, AB | Jan 2023 – Present", style_job_meta))
    right_flow.append(Paragraph("• Architected a distributed execution engine utilizing multi-process Python and asynchronous task scheduling, boosting throughput by 500%.", style_bullet))
    right_flow.append(Paragraph("• Implemented production agentic AI tool-calling workflows and deterministic validation gateways (AST code verification, schema assertion).", style_bullet))

    container_table = Table([[left_flow, right_flow]], colWidths=[165, 395])
    container_table.setStyle(TableStyle([
        ('VALIGN', (0,0), (-1,-1), 'TOP'),
        ('BACKGROUND', (0,0), (0,0), LIGHT_BG),
        ('RIGHTPADDING', (0,0), (0,0), 8),
        ('LEFTPADDING', (0,0), (0,0), 8),
        ('TOPPADDING', (0,0), (-1,-1), 4),
        ('BOTTOMPADDING', (0,0), (-1,-1), 4),
        ('LEFTPADDING', (1,0), (1,0), 12),
        ('RIGHTPADDING', (1,0), (1,0), 4),
        ('LINEAFTER', (0,0), (0,-1), 0.75, LINE_COLOR),
    ]))

    doc.build([container_table])
    print(f"Generated PolicyMe Resume: {filename}")

if __name__ == "__main__":
    build_policyme_resume()''',
    ),
    PcVirtualFile(
      id: 'file-pdf-resume',
      name: 'Rahul_Jha_PolicyMe_Senior_FullStack_AI_Resume.pdf',
      path: '/home/agent/workspace/jobs/Rahul_Jha_PolicyMe_Senior_FullStack_AI_Resume.pdf',
      type: FileType.pdf,
      sizeBytes: 86400,
      createdAt: DateTime.now().subtract(const Duration(minutes: 50)),
      metadata: {'company': 'PolicyMe', 'role': 'Senior Full Stack & AI Systems Engineer', 'matchScore': '98.5%'},
      content: '%PDF-1.4 [Generated ReportLab Binary Layout - Tailored Resume for PolicyMe with 2-Column InsurTech Navy/Teal Styling]',
    ),
    PcVirtualFile(
      id: 'file-cl-cover-letter',
      name: 'PolicyMe_Cover_Letter_Rahul_Jha.md',
      path: '/home/agent/workspace/jobs/PolicyMe_Cover_Letter_Rahul_Jha.md',
      type: FileType.markdown,
      sizeBytes: 2450,
      createdAt: DateTime.now().subtract(const Duration(minutes: 40)),
      metadata: {'company': 'PolicyMe', 'status': 'Ready for Submission'},
      content: '''# Application for Senior Full Stack & AI Systems Engineer at PolicyMe

Dear PolicyMe Hiring Team,

I am writing to express my strong enthusiasm for the Senior Full Stack & AI Systems Engineer role at PolicyMe. Having followed PolicyMe's rapid trajectory in modernizing insurance technology across Canada, I am eager to contribute my expertise in distributed Python/React systems, deterministic AI agentic workflows (AST validation, schema enforcement), and mission-critical cloud pipelines.

At TR PRO, I led the architecture of a distributed execution engine utilizing multi-process asynchronous Python, boosting system throughput by 500% across concurrent broker streams. Additionally, my work at Litus Inc. and FIS maintaining 99.5% operational precision in automated transaction pipelines aligns with PolicyMe's focus on trust, reliability, and seamless user experience.

With my M.Eng. in Electrical & Computer Engineering from the University of Calgary (GPA: 3.64) and full Canadian work authorization, I am ready to hit the ground running.

Sincerely,  
Rahul Jha  
rahuljha190398@gmail.com | (782) 778-5607''',
    ),
  ];
}
