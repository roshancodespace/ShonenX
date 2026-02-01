class UniversalNews {
  final String? title;
  final String? url;
  final String? imageUrl;
  final String? date;
  final String? excerpt;
  final String? body;
  final bool isRead;

  const UniversalNews({
    this.title,
    this.url,
    this.imageUrl,
    this.date,
    this.excerpt,
    this.body,
    this.isRead = false,
  });

  factory UniversalNews.fromJson(Map<String, dynamic> json) {
    return UniversalNews(
      title: json['title'],
      url: json['url'],
      imageUrl: json['imageUrl'],
      date: json['date'],
      excerpt: json['excerpt'],
      body: json['body'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'url': url,
      'imageUrl': imageUrl,
      'date': date,
      'excerpt': excerpt,
      'body': body,
    };
  }

  UniversalNews copyWith({
    String? title,
    String? url,
    String? imageUrl,
    String? date,
    String? excerpt,
    String? body,
    bool? isRead,
  }) {
    return UniversalNews(
      title: title ?? this.title,
      url: url ?? this.url,
      imageUrl: imageUrl ?? this.imageUrl,
      date: date ?? this.date,
      excerpt: excerpt ?? this.excerpt,
      body: body ?? this.body,
      isRead: isRead ?? this.isRead,
    );
  }
}
