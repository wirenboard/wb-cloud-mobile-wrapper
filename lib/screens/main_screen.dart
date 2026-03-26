import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../data/bookmark.dart';
import '../data/bookmark_repository.dart';
import '../widgets/bookmarks_sheet.dart';
import '../version.dart';

const _startUrl = 'https://wirenboard.cloud';
const _allowedHost = 'wirenboard.cloud';
const _intentChannel = MethodChannel('com.wirenboard.cloud/intent');

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late final WebViewController _controller;
  final _repo = BookmarkRepository();
  bool _isLoading = true;
  bool _showSplash = true;
  bool _speedDialOpen = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (_) {
          if (mounted) setState(() => _isLoading = true);
        },
        onPageFinished: (_) async {
          if (mounted) setState(() => _isLoading = false);
        },
        onNavigationRequest: (request) {
          final uri = Uri.tryParse(request.url);
          if (uri == null) return NavigationDecision.prevent;
          final host = uri.host;
          if (host == _allowedHost || host.endsWith('.$_allowedHost')) {
            return NavigationDecision.navigate;
          }
          _openExternal(request.url);
          return NavigationDecision.prevent;
        },
      ))
      ..loadRequest(Uri.parse(_startUrl));

    Timer(const Duration(milliseconds: 1000), () {
      if (mounted) setState(() => _showSplash = false);
    });

    _checkSharedIntent();

    _intentChannel.setMethodCallHandler((call) async {
      if (call.method == 'onSharedUrl') {
        final url = call.arguments as String?;
        if (url != null) _loadUrl(url);
      }
    });
  }

  Future<void> _checkSharedIntent() async {
    try {
      final url = await _intentChannel.invokeMethod<String>('getSharedUrl');
      if (url != null && url.isNotEmpty) {
        _loadUrl(url);
      }
    } on PlatformException {
      // нет входящего intent — нормальный запуск
    }
  }

  void _loadUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    if (uri.scheme != 'https' && uri.scheme != 'http') return;
    final host = uri.host;
    if (host != _allowedHost && !host.endsWith('.$_allowedHost')) return;
    _controller.loadRequest(uri);
  }

  Future<void> _openExternal(String url) async {
    try {
      await _intentChannel.invokeMethod('openExternal', {'url': url});
    } on PlatformException {
      // игнорируем если не поддерживается
    }
  }

  void _closeDial() => setState(() => _speedDialOpen = false);

  Future<void> _showAddBookmarkDialog() async {
    _closeDial();
    final url = await _controller.currentUrl();
    final title = await _controller.getTitle();
    if (url == null || !mounted) return;

    final titleController =
        TextEditingController(text: title?.isNotEmpty == true ? title : url);

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Добавить закладку'),
        content: TextField(
          controller: titleController,
          decoration: const InputDecoration(labelText: 'Название'),
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () async {
              final name = titleController.text.trim().isNotEmpty
                  ? titleController.text.trim()
                  : url;
              await _repo.insert(Bookmark(
                title: name,
                url: url,
                createdAt: DateTime.now().millisecondsSinceEpoch,
              ));
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );

    titleController.dispose();
  }

  void _showBookmarks() {
    _closeDial();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => BookmarksSheet(
        onSelected: (url) => _loadUrl(url),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (_speedDialOpen) {
          _closeDial();
          return;
        }
        if (await _controller.canGoBack()) {
          _controller.goBack();
        }
      },
      child: Scaffold(
        body: Stack(
          children: [
            SafeArea(
              child: Column(
                children: [
                  if (_isLoading) const LinearProgressIndicator(minHeight: 3),
                  Expanded(child: WebViewWidget(controller: _controller)),
                ],
              ),
            ),
            if (_showSplash)
              const _SplashOverlay(),
            if (_speedDialOpen)
              GestureDetector(
                onTap: _closeDial,
                child: Container(
                  color: Colors.black.withValues(alpha: 0.3),
                ),
              ),
          ],
        ),
        floatingActionButton: _SpeedDial(
          isOpen: _speedDialOpen,
          onToggle: () => setState(() => _speedDialOpen = !_speedDialOpen),
          onAddBookmark: _showAddBookmarkDialog,
          onBookmarks: _showBookmarks,
          onHome: () {
            _closeDial();
            _controller.loadRequest(Uri.parse(_startUrl));
          },
          onReload: () {
            _closeDial();
            _controller.reload();
          },
        ),
      ),
    );
  }
}

class _SpeedDial extends StatelessWidget {
  final bool isOpen;
  final VoidCallback onToggle;
  final VoidCallback onAddBookmark;
  final VoidCallback onBookmarks;
  final VoidCallback onHome;
  final VoidCallback onReload;

  const _SpeedDial({
    required this.isOpen,
    required this.onToggle,
    required this.onAddBookmark,
    required this.onBookmarks,
    required this.onHome,
    required this.onReload,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        AnimatedOpacity(
          opacity: isOpen ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 180),
          child: AnimatedSlide(
            offset: isOpen ? Offset.zero : const Offset(0, 0.3),
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            child: IgnorePointer(
              ignoring: !isOpen,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _DialItem(
                    icon: Icons.home_outlined,
                    label: 'Главная',
                    onPressed: onHome,
                  ),
                  const SizedBox(height: 10),
                  _DialItem(
                    icon: Icons.refresh,
                    label: 'Обновить',
                    onPressed: onReload,
                  ),
                  const SizedBox(height: 10),
                  _DialItem(
                    icon: Icons.bookmarks_outlined,
                    label: 'Закладки',
                    onPressed: onBookmarks,
                  ),
                  const SizedBox(height: 10),
                  _DialItem(
                    icon: Icons.bookmark_add_outlined,
                    label: 'Добавить закладку',
                    onPressed: onAddBookmark,
                    primary: true,
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        ),
        FloatingActionButton(
          onPressed: onToggle,
          child: AnimatedRotation(
            turns: isOpen ? 0.125 : 0,
            duration: const Duration(milliseconds: 200),
            child: const Icon(Icons.menu),
          ),
        ),
      ],
    );
  }
}

class _DialItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool primary;

  const _DialItem({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.primary = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: colorScheme.onSurface,
            ),
          ),
        ),
        const SizedBox(width: 10),
        FloatingActionButton.small(
          heroTag: label,
          onPressed: onPressed,
          backgroundColor: primary
              ? colorScheme.primary
              : colorScheme.surfaceContainerHigh,
          foregroundColor: primary
              ? colorScheme.onPrimary
              : colorScheme.onSurface,
          elevation: 2,
          child: Icon(icon, size: 20),
        ),
      ],
    );
  }
}

class _SplashOverlay extends StatelessWidget {
  const _SplashOverlay();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      color: colorScheme.surface,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Wiren Board Cloud',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'v$appVersion',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 32),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
