class FuzzyDate {
  final int? year;
  final int? month;
  final int? day;

  const FuzzyDate({this.year, this.month, this.day});

  factory FuzzyDate.fromJson(Map<String, dynamic> json) {
    return FuzzyDate(
      year: json['year'] as int?,
      month: json['month'] as int?,
      day: json['day'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
        'year': year,
        'month': month,
        'day': day,
      };

  DateTime? get toDateTime {
    if (year == null || month == null || day == null) return null;
    return DateTime(year!, month!, day!);
  }
}

class FuzzyDateInput {
  final int? year;
  final int? month;
  final int? day;

  FuzzyDateInput({this.year, this.month, this.day});

  Map<String, dynamic> toJson() => {
        'year': year,
        'month': month,
        'day': day,
      };
}
