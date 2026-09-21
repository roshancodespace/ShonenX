/// Represents a parsed application version for robust comparisons across
/// standard semver, alpha/test pre-releases, and hotfix releases.
class AppVersion implements Comparable<AppVersion> {
  final int major;
  final int minor;
  final int patch;
  final String suffixLabel; // e.g. 'test', 'alpha', 'beta', 'rc', '', 'hotfix'
  final int suffixNumber; // e.g. 69 in 'alpha.69'
  final int buildNumber; // e.g. 12 in '+12'
  final String raw;

  const AppVersion({
    required this.major,
    required this.minor,
    required this.patch,
    required this.suffixLabel,
    required this.suffixNumber,
    required this.buildNumber,
    required this.raw,
  });

  /// Priority rank for the suffix:
  /// test < dev < alpha < beta < rc/preview < stable ('') < hotfix/patch/fix
  int get labelRank {
    final l = suffixLabel.toLowerCase();
    switch (l) {
      case 'test':
        return 10;
      case 'dev':
        return 15;
      case 'alpha':
        return 20;
      case 'beta':
        return 30;
      case 'rc':
      case 'preview':
        return 40;
      case '':
        return 50; // Stable release (no suffix)
      case 'hotfix':
      case 'fix':
      case 'patch':
        return 60; // Hotfix released on top of stable
      default:
        // Any other unrecognized pre-release label comes before stable
        return 25;
    }
  }

  /// Static helper to compare two raw version strings
  static int compare(String a, String b) =>
      AppVersion.parse(a).compareTo(AppVersion.parse(b));

  /// Parses version strings such as:
  /// - `v2.1.3-alpha.69`
  /// - `v2.1.3-test.69`
  /// - `v2.1.3-test`
  /// - `v2.1.3-alpha`
  /// - `v2.1.3`
  /// - `v2.1.3-hotfix`
  /// - `v2.1.3-hotfix.69`
  /// - `2.1.3+4`
  factory AppVersion.parse(String input) {
    final clean = input.trim().replaceFirst(RegExp(r'^[vV]'), '');

    // Extract build number if present (+4)
    int buildNum = 0;
    String withoutBuild = clean;
    final plusIdx = clean.indexOf('+');
    if (plusIdx != -1) {
      withoutBuild = clean.substring(0, plusIdx);
      buildNum = int.tryParse(clean.substring(plusIdx + 1)) ?? 0;
    }

    // Split base numbers from suffix (- or _)
    String basePart = withoutBuild;
    String suffixPart = '';
    final delimMatch = RegExp(r'[-_]').firstMatch(withoutBuild);
    if (delimMatch != null) {
      basePart = withoutBuild.substring(0, delimMatch.start);
      suffixPart = withoutBuild.substring(delimMatch.end);
    }

    // Parse major.minor.patch
    final baseNums = basePart
        .split('.')
        .map((e) => int.tryParse(e) ?? 0)
        .toList();
    final major = baseNums.isNotEmpty ? baseNums[0] : 0;
    final minor = baseNums.length > 1 ? baseNums[1] : 0;
    final patch = baseNums.length > 2 ? baseNums[2] : 0;

    // Parse suffix label and number (e.g. 'alpha.69', 'test', 'hotfix-2', 'alpha69')
    String label = '';
    int suffixNum = 0;

    if (suffixPart.isNotEmpty) {
      final match = RegExp(
        r'^([a-zA-Z]+)(?:[.\-_]?(\d+))?',
      ).firstMatch(suffixPart);
      if (match != null) {
        label = match.group(1)?.toLowerCase() ?? '';
        suffixNum = int.tryParse(match.group(2) ?? '0') ?? 0;
      } else {
        label = suffixPart.toLowerCase();
      }
    }

    return AppVersion(
      major: major,
      minor: minor,
      patch: patch,
      suffixLabel: label,
      suffixNumber: suffixNum,
      buildNumber: buildNum,
      raw: input,
    );
  }

  @override
  int compareTo(AppVersion other) {
    if (major != other.major) return major.compareTo(other.major);
    if (minor != other.minor) return minor.compareTo(other.minor);
    if (patch != other.patch) return patch.compareTo(other.patch);

    final rA = labelRank;
    final rB = other.labelRank;
    if (rA != rB) return rA.compareTo(rB);

    if (suffixLabel.toLowerCase() != other.suffixLabel.toLowerCase()) {
      return suffixLabel.toLowerCase().compareTo(
        other.suffixLabel.toLowerCase(),
      );
    }

    if (suffixNumber != other.suffixNumber) {
      return suffixNumber.compareTo(other.suffixNumber);
    }

    if (buildNumber != other.buildNumber) {
      return buildNumber.compareTo(other.buildNumber);
    }

    return 0;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is AppVersion && compareTo(other) == 0;

  @override
  int get hashCode =>
      major.hashCode ^
      minor.hashCode ^
      patch.hashCode ^
      labelRank.hashCode ^
      suffixLabel.toLowerCase().hashCode ^
      suffixNumber.hashCode ^
      buildNumber.hashCode;

  @override
  String toString() => raw;
}
