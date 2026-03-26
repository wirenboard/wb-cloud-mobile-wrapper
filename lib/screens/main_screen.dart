import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../data/bookmark.dart';
import '../data/bookmark_repository.dart';
import '../widgets/bookmarks_sheet.dart';

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
  bool _canGoBack = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        // #6: проверка mounted перед setState
        onPageStarted: (_) {
          if (mounted) setState(() => _isLoading = true);
        },
        onPageFinished: (_) async {
          final canGoBack = await _controller.canGoBack();
          if (mounted) {
            setState(() {
              _isLoading = false;
              _canGoBack = canGoBack;
            });
          }
        },
        // #10: ограничение навигации доменом wirenboard.cloud
        onNavigationRequest: (request) {
          final uri = Uri.tryParse(request.url);
          if (uri == null) return NavigationDecision.prevent;
          final host = uri.host;
          if (host == _allowedHost || host.endsWith('.$_allowedHost')) {
            return NavigationDecision.navigate;
          }
          // внешние ссылки открываем в системном браузере через platform channel
          _openExternal(request.url);
          return NavigationDecision.prevent;
        },
      ))
      ..loadRequest(Uri.parse(_startUrl));

    _checkSharedIntent();

    // #7: слушаем входящие URL когда приложение уже запущено
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

  // #2: валидация URL по домену
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

  // #3: исправлена утечка TextEditingController
  void _showAddBookmarkDialog() async {
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
        if (await _controller.canGoBack()) {
          _controller.goBack();
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              if (_isLoading) const LinearProgressIndicator(minHeight: 3),
              Expanded(child: WebViewWidget(controller: _controller)),
            ],
          ),
        ),
        bottomNavigationBar: Container(
          height: 44,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(
              top: BorderSide(
                color: Theme.of(context).colorScheme.outlineVariant,
                width: 0.5,
              ),
            ),
          ),
          child: Row(
            children: [
              _NavBtn(
                icon: Icons.arrow_back,
                onPressed: _canGoBack ? () => _controller.goBack() : null,
              ),
              _NavBtn(
                icon: Icons.refresh,
                onPressed: () => _controller.reload(),
              ),
              _NavBtn(
                icon: Icons.bookmark_add_outlined,
                onPressed: _showAddBookmarkDialog,
                primary: true,
              ),
              _NavBtn(
                icon: Icons.bookmarks_outlined,
                onPressed: _showBookmarks,
              ),
              _NavBtn(
                icon: Icons.home_outlined,
                onPressed: () =>
                    _controller.loadRequest(Uri.parse(_startUrl)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final bool primary;

  const _NavBtn({
    required this.icon,
    required this.onPressed,
    this.primary = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = primary
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.onSurface;

    return Expanded(
      child: InkWell(
        onTap: onPressed,
        child: Icon(
          icon,
          size: 22,
          // #4: withOpacity → withValues
          color: onPressed == null
              ? color.withValues(alpha: 0.3)
              : color,
        ),
      ),
    );
  }
}
