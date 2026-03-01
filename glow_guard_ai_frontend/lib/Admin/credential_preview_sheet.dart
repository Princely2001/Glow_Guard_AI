import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class CredentialPreviewSheet {
  static const Color teal = Color(0xFF009688);

  static Future<void> show(
      BuildContext context, {
        required String url,
        VoidCallback? onViewed,
        String title = "Credential Preview",
      }) async {
    final fixedUrl = _normalizeDocUrl(url);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CredentialPreviewView(
        url: fixedUrl,
        title: title,
      ),
    );

    // Mark as "viewed" when sheet is closed
    onViewed?.call();
  }

  static String _normalizeDocUrl(String url) {
    final u = Uri.tryParse(url);
    if (u == null) return url;

    if (u.host.contains("drive.google.com")) {
      final segments = u.pathSegments;
      final dIndex = segments.indexOf("d");
      if (dIndex != -1 && segments.length > dIndex + 1) {
        final id = segments[dIndex + 1];
        return "https://drive.google.com/file/d/$id/preview";
      }
      final id = u.queryParameters["id"];
      if (id != null && id.isNotEmpty) {
        return "https://drive.google.com/file/d/$id/preview";
      }
    }
    return url;
  }
}

class _CredentialPreviewView extends StatefulWidget {
  const _CredentialPreviewView({
    required this.url,
    required this.title,
  });

  final String url;
  final String title;

  @override
  State<_CredentialPreviewView> createState() => _CredentialPreviewViewState();
}

class _CredentialPreviewViewState extends State<_CredentialPreviewView> {
  late final WebViewController _controller;

  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (!mounted) return;
            setState(() {
              _loading = true;
              _error = null;
            });
          },
          onPageFinished: (_) {
            if (!mounted) return;
            setState(() => _loading = false);
          },
          onWebResourceError: (err) {
            if (!mounted) return;
            setState(() {
              _loading = false;
              _error = err.description;
            });
          },
          onNavigationRequest: (req) {
            final u = Uri.tryParse(req.url);
            if (u == null) return NavigationDecision.prevent;
            if (u.scheme != "http" && u.scheme != "https") {
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.96,
      minChildSize: 0.6,
      maxChildSize: 0.99,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 10, bottom: 6),
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 6, 10, 10),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: CredentialPreviewSheet.teal.withOpacity(0.12),
                      child: const Icon(Icons.description_outlined, color: CredentialPreviewSheet.teal),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        widget.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF111827),
                        ),
                      ),
                    ),
                    if (_loading)
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      ),
                    const SizedBox(width: 6),
                    IconButton(
                      tooltip: "Reload",
                      onPressed: () {
                        setState(() {
                          _error = null;
                          _loading = true;
                        });
                        _controller.loadRequest(Uri.parse(widget.url));
                      },
                      icon: const Icon(Icons.refresh),
                    ),
                    IconButton(
                      tooltip: "Close",
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              Expanded(
                child: Stack(
                  children: [
                    WebViewWidget(controller: _controller),

                    if (_error != null)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF9FAFB),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFE5E7EB)),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 36),
                                const SizedBox(height: 10),
                                const Text(
                                  "Can’t display this document",
                                  style: TextStyle(fontWeight: FontWeight.w900),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  _error!,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: Colors.black54),
                                ),
                                const SizedBox(height: 12),
                                FilledButton.tonalIcon(
                                  onPressed: () {
                                    setState(() {
                                      _error = null;
                                      _loading = true;
                                    });
                                    _controller.loadRequest(Uri.parse(widget.url));
                                  },
                                  icon: const Icon(Icons.refresh),
                                  label: const Text("Reload"),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}