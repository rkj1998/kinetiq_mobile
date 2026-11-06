import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class AgentBrowserSheet extends StatefulWidget {
  final String initialUrl;
  final String title;

  const AgentBrowserSheet({
    super.key,
    required this.initialUrl,
    this.title = 'Kinetiq Embedded Autonomous Browser',
  });

  static void show(BuildContext context, {required String initialUrl, String? title}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AgentBrowserSheet(
        initialUrl: initialUrl,
        title: title ?? 'Kinetiq Browser View',
      ),
    );
  }

  @override
  State<AgentBrowserSheet> createState() => _AgentBrowserSheetState();
}

class _AgentBrowserSheetState extends State<AgentBrowserSheet> {
  InAppWebViewController? _webViewController;
  double _progress = 0;
  String _currentUrl = '';
  bool _canGoBack = false;
  bool _canGoForward = false;

  @override
  void initState() {
    super.initState();
    _currentUrl = widget.initialUrl;
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height * 0.88;

    return Container(
      height: height,
      decoration: const BoxDecoration(
        color: Color(0xFF0F111A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        border: Border(
          top: BorderSide(color: Color(0xFF282C3F), width: 1.5),
        ),
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 6),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Browser Top Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, size: 16),
                  color: _canGoBack ? Colors.white : Colors.grey.shade700,
                  onPressed: _canGoBack ? () => _webViewController?.goBack() : null,
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_forward_ios, size: 16),
                  color: _canGoForward ? Colors.white : Colors.grey.shade700,
                  onPressed: _canGoForward ? () => _webViewController?.goForward() : null,
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, size: 18),
                  color: Colors.white70,
                  onPressed: () => _webViewController?.reload(),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1B1D2A),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF2D3148)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.lock, size: 12, color: Color(0xFF10B981)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            _currentUrl.isEmpty ? widget.initialUrl : _currentUrl,
                            style: const TextStyle(fontSize: 12, color: Colors.white70),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.close, size: 20, color: Colors.white70),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Loading Progress Bar
          if (_progress < 1.0)
            LinearProgressIndicator(
              value: _progress,
              minHeight: 2,
              backgroundColor: Colors.transparent,
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
            ),

          // Webview Surface
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: InAppWebView(
                initialUrlRequest: URLRequest(url: WebUri(widget.initialUrl)),
                initialSettings: InAppWebViewSettings(
                  javaScriptEnabled: true,
                  transparentBackground: false,
                  useWideViewPort: true,
                  supportZoom: true,
                ),
                onWebViewCreated: (controller) {
                  _webViewController = controller;
                },
                onLoadStart: (controller, url) {
                  if (url != null) {
                    setState(() => _currentUrl = url.toString());
                  }
                },
                onLoadStop: (controller, url) async {
                  if (url != null) {
                    final canBack = await controller.canGoBack();
                    final canForward = await controller.canGoForward();
                    setState(() {
                      _currentUrl = url.toString();
                      _canGoBack = canBack;
                      _canGoForward = canForward;
                    });
                  }
                },
                onProgressChanged: (controller, progress) {
                  setState(() {
                    _progress = progress / 100;
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
