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

  /// Accepts:
  /// - "YYYY"
  /// - "YYYY-MM"
  /// - "YYYY-MM-DD"
  /// - Full ISO strings like "YYYY-MM-DDTHH:mm:ssZ"
  factory FuzzyDate.fromIso(String? iso) {
    if (iso == null || iso.isEmpty) return const FuzzyDate();

    try {
      // Strip time part if present
      final datePart = iso.split('T').first;
      final parts = datePart.split('-');

      return FuzzyDate(
        year: parts.isNotEmpty ? int.tryParse(parts[0]) : null,
        month: parts.length > 1 ? int.tryParse(parts[1]) : null,
        day: parts.length > 2 ? int.tryParse(parts[2]) : null,
      );
    } catch (_) {
      return const FuzzyDate();
    }
  }

  Map<String, dynamic> toJson() => {
        'year': year,
        'month': month,
        'day': day,
      };

  DateTime? get toDateTime {
    if (year == null) return null;
    return DateTime(
      year!,
      month ?? 1,
      day ?? 1,
    );
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
