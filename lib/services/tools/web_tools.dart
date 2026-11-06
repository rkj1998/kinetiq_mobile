import 'package:dio/dio.dart';
import 'base_tool.dart';

class WebSearchTool extends BaseTool {
  final Dio _dio = Dio();

  @override
  String get name => 'web_search';

  @override
  String get description => 'Searches the web for information, news, or articles.';

  @override
  Map<String, dynamic> get parametersSchema => {
    'type': 'object',
    'properties': {
      'query': {
        'type': 'string',
        'description': 'The search query or terms to look up.'
      }
    },
    'required': ['query'],
  };

  @override
  Future<String> execute(Map<String, dynamic> arguments) async {
    final query = arguments['query']?.toString() ?? '';
    if (query.trim().isEmpty) return 'Error: Empty search query.';

    try {
      final response = await _dio.get(
        'https://html.duckduckgo.com/html/',
        queryParameters: {'q': query},
        options: Options(headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
        }),
      );

      final html = response.data.toString();
      final snippetRegex = RegExp(r'<a class="result__snippet[^>]*>(.*?)<\/a>', dotAll: true);
      final titleRegex = RegExp(r'<a class="result__url[^>]*href="([^"]*)"[^>]*>(.*?)<\/a>', dotAll: true);

      final snippets = snippetRegex.allMatches(html).take(4).map((m) => m.group(1)?.replaceAll(RegExp(r'<[^>]*>'), '').trim()).toList();
      final links = titleRegex.allMatches(html).take(4).map((m) => m.group(1)).toList();

      if (snippets.isEmpty) {
        return 'No direct snippet results found for "$query".';
      }

      StringBuffer sb = StringBuffer();
      for (int i = 0; i < snippets.length; i++) {
        sb.writeln('Result ${i + 1}:');
        if (i < links.length && links[i] != null) sb.writeln('Link: ${links[i]}');
        sb.writeln('Snippet: ${snippets[i]}\n');
      }
      return sb.toString();
    } catch (e) {
      return 'Web search failed: $e';
    }
  }
}

class FetchPageTextTool extends BaseTool {
  final Dio _dio = Dio();

  @override
  String get name => 'read_web_page';

  @override
  String get description => 'Reads and extracts readable text from a URL.';

  @override
  Map<String, dynamic> get parametersSchema => {
    'type': 'object',
    'properties': {
      'url': {
        'type': 'string',
        'description': 'The HTTP/HTTPS URL of the web page to read.'
      }
    },
    'required': ['url'],
  };

  @override
  Future<String> execute(Map<String, dynamic> arguments) async {
    final url = arguments['url']?.toString() ?? '';
    if (url.trim().isEmpty) return 'Error: Empty URL.';

    try {
      final response = await _dio.get(
        url,
        options: Options(
          responseType: ResponseType.plain,
          headers: {'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)'},
        ),
      );

      String content = response.data.toString();
      content = content.replaceAll(RegExp(r'<script\b[^<]*(?:(?!<\/script>)<[^<]*)*<\/script>', caseSensitive: false), ' ');
      content = content.replaceAll(RegExp(r'<style\b[^<]*(?:(?!<\/style>)<[^<]*)*<\/style>', caseSensitive: false), ' ');
      content = content.replaceAll(RegExp(r'<[^>]*>'), ' ');
      content = content.replaceAll(RegExp(r'\s+'), ' ').trim();

      if (content.length > 3500) {
        return content.substring(0, 3500) + '... [Content truncated for brevity]';
      }
      return content.isNotEmpty ? content : 'No readable content could be extracted.';
    } catch (e) {
      return 'Failed to fetch page from $url: $e';
    }
  }
}