import 'package:flutter/material.dart';
import '../data/bookmark.dart';
import '../data/bookmark_repository.dart';

class BookmarksSheet extends StatefulWidget {
  final void Function(String url) onSelected;

  const BookmarksSheet({super.key, required this.onSelected});

  @override
  State<BookmarksSheet> createState() => _BookmarksSheetState();
}

class _BookmarksSheetState extends State<BookmarksSheet> {
  final _repo = BookmarkRepository();
  List<Bookmark> _bookmarks = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await _repo.getAll();
    if (mounted) setState(() => _bookmarks = list);
  }

  Future<void> _delete(Bookmark bookmark) async {
    // #1: null-safe — пропускаем если id отсутствует
    final id = bookmark.id;
    if (id == null) return;
    await _repo.delete(id);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) => Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          Text('Bookmarks', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          const Divider(height: 1),
          if (_bookmarks.isEmpty)
            const Expanded(
              child: Center(
                child: Text('No bookmarks yet',
                    style: TextStyle(color: Colors.grey)),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: _bookmarks.length,
                itemBuilder: (context, i) {
                  final b = _bookmarks[i];
                  return ListTile(
                    leading: const Icon(Icons.bookmark_outline),
                    title: Text(b.title,
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text(b.url,
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      // #1: null-safe вызов
                      onPressed: () => _delete(b),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      widget.onSelected(b.url);
                    },
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
