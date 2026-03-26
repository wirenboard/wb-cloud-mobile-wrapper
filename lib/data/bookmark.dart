class Bookmark {
  final String? id;
  final String title;
  final String url;
  final int createdAt;

  const Bookmark({
    this.id,
    required this.title,
    required this.url,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'url': url,
        'createdAt': createdAt,
      };

  factory Bookmark.fromMap(Map<String, dynamic> map) => Bookmark(
        id: map['id'] as String?,
        title: map['title'] as String,
        url: map['url'] as String,
        createdAt: map['createdAt'] as int,
      );
}
