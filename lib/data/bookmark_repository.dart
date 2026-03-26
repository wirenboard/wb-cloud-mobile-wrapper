import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'bookmark.dart';

class BookmarkRepository {
  static const _key = 'bookmarks';
  static final _rng = Random.secure();

  // #5: уникальный ID без коллизий
  static String _generateId() {
    final ts = DateTime.now().millisecondsSinceEpoch;
    final rand = _rng.nextInt(0xFFFFFF);
    return '${ts}_${rand.toRadixString(16)}';
  }

  Future<List<Bookmark>> getAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    // #9: обработка ошибок при парсинге
    final result = <Bookmark>[];
    for (final s in raw) {
      try {
        result.add(Bookmark.fromMap(jsonDecode(s) as Map<String, dynamic>));
      } catch (_) {
        // пропускаем повреждённые записи
      }
    }
    result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return result;
  }

  Future<void> insert(Bookmark bookmark) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key) ?? [];
    final newItem = Bookmark(
      id: _generateId(),
      title: bookmark.title,
      url: bookmark.url,
      createdAt: bookmark.createdAt,
    );
    list.add(jsonEncode(newItem.toMap()));
    await prefs.setStringList(_key, list);
  }

  Future<void> delete(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key) ?? [];
    // #9: обработка ошибок при парсинге в delete
    list.removeWhere((s) {
      try {
        final map = jsonDecode(s) as Map<String, dynamic>;
        return map['id'] == id;
      } catch (_) {
        return false;
      }
    });
    await prefs.setStringList(_key, list);
  }
}
