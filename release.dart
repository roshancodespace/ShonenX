import 'dart:io';

void main(List<String> args) async {
  if (args.contains('--delete')) {
    await deleteTag();
    return;
  }

  final pubspecFile = File('pubspec.yaml');
  if (!await pubspecFile.exists()) {
    print('Error: pubspec.yaml not found in this directory.');
    return;
  }

  final currentFullVersion = await getCurrentVersion(pubspecFile);
  final currentBase = currentFullVersion.split('+')[0];
  final currentBuild = int.tryParse(currentFullVersion.split('+')[1]) ?? 0;

  print('--- ShonenX Release Automation ---');
  print('Current Pubspec: $currentBase+$currentBuild');

  stdout.write('Enter New Base Version (default: $currentBase): ');
  String? inputBase = stdin.readLineSync();
  final targetBase = (inputBase == null || inputBase.isEmpty) ? currentBase : inputBase;

  int targetBuild;
  if (targetBase != currentBase) {
    targetBuild = 1; 
    print('\n[WARNING] Base version changed ($currentBase -> $targetBase).');
    print('[WARNING] Resetting build number to 1.\n');
  } else {
    targetBuild = currentBuild + 1;
    print('Incrementing build number for $targetBase: $currentBuild -> $targetBuild');
  }

  stdout.write('Enter Suffix (e.g., hotfix.1) or leave empty: ');
  final suffix = stdin.readLineSync();

  final pubspecVersion = '$targetBase+$targetBuild';
  final gitTag = (suffix != null && suffix.isNotEmpty) 
      ? 'v$targetBase-$suffix' 
      : 'v$targetBase';

  print('\nSummary:');
  print('  Pubspec: $pubspecVersion');
  print('  Git Tag: $gitTag');
  stdout.write('Proceed with release? (y/n): ');
  if (stdin.readLineSync()?.toLowerCase() != 'y') return;

  await updatePubspec(pubspecFile, pubspecVersion);
  
  await run('git', ['add', 'pubspec.yaml']);
  await run('git', ['commit', '-m', 'chore: bump version to $pubspecVersion']);
  await run('git', ['tag', gitTag]);
  
  print('Pushing to GitHub...');
  await run('git', ['push', 'origin', 'main']); 
  await run('git', ['push', 'origin', gitTag]);

  print('\n--- SUCCESS: $gitTag is out there. ---');
}

Future<String> getCurrentVersion(File file) async {
  final lines = await file.readAsLines();
  final versionLine = lines.firstWhere((l) => l.trim().startsWith('version:'));
  return versionLine.split(':')[1].trim();
}

Future<void> updatePubspec(File file, String newVersion) async {
  final lines = await file.readAsLines();
  final updatedLines = lines.map((line) {
    if (line.trim().startsWith('version:')) {
      return 'version: $newVersion';
    }
    return line;
  }).toList();
  await file.writeAsString(updatedLines.join('\n'));
}

Future<void> deleteTag() async {
  stdout.write('Tag to DELETE: ');
  final tag = stdin.readLineSync();
  if (tag == null || tag.isEmpty) return;
  await run('git', ['tag', '-d', tag]);
  await run('git', ['push', '--delete', 'origin', tag]);
  print('Tag $tag deleted.');
}

Future<void> run(String cmd, List<String> args) async {
  final result = await Process.run(cmd, args);
  if (result.exitCode != 0) {
    print('Git Error: ${result.stderr}');
    exit(1);
  }
}