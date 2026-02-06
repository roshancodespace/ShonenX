class MChapter {
  String? name;

  String? url;

  String? dateUpload;

  String? scanlator;

  int? number;

  MChapter({this.name, this.url, this.dateUpload, this.scanlator, this.number});
  factory MChapter.fromJson(Map<String, dynamic> json) {
    return MChapter(
      name: json['name'],
      url: json['url'],
      dateUpload: json['dateUpload'],
      scanlator: json['scanlator'],
      number: json['number'],
    );
  }
  Map<String, dynamic> toJson() => {
    'name': name,
    'url': url,
    'dateUpload': dateUpload,
    'scanlator': scanlator,
    'number': number,
  };
}
