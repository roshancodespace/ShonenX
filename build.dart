#!/usr/bin/env dart

import 'dart:io';

Process? _currentProcess;

Future<void> main(List<String> args) async {
  ProcessSignal.sigint.watch().listen((_) async {
    _currentProcess?.kill(ProcessSignal.sigkill);
    await killGradle();
    exit(130);
  });

  String defineFile = 'keys.json';
  final platforms = <String>[];

  for (final arg in args) {
    if (arg.startsWith('--define=')) {
      defineFile = arg.split('=').last;
    } else {
      platforms.add(arg);
    }
  }

  if (platforms.isEmpty) {
    platforms.add('android');
  }

  if (!File(defineFile).existsSync()) {
    stderr.writeln('Define file not found: $defineFile');
    exit(1);
  }

  final common = ['--release', '--dart-define-from-file=$defineFile'];

  for (final platform in platforms) {
    switch (platform) {
      case 'android':
        await killGradle();
        await run(['flutter', 'build', 'apk', '--split-per-abi', ...common]);
        await killGradle();
        break;

      case 'linux':
        await run(['flutter', 'build', 'linux', ...common]);
        await run([
          'zip',
          '-r',
          'linux-bundle.zip',
          'build/linux/x64/release/bundle',
        ]);
        break;

      case 'windows':
        await run(['flutter', 'build', 'windows', ...common]);
        break;

      case 'run':
        await run(['flutter', 'run', '--dart-define-from-file=$defineFile']);
        break;

      default:
        stderr.writeln('Invalid platform: $platform');
        exit(1);
    }
  }
}

Future<void> run(List<String> cmd) async {
  stdout.writeln('> ${cmd.join(' ')}\n');

  _currentProcess = await Process.start(
    cmd.first,
    cmd.sublist(1),
    runInShell: true,
  );

  _currentProcess!.stdout.listen(stdout.add);
  _currentProcess!.stderr.listen(stderr.add);

  final code = await _currentProcess!.exitCode;
  _currentProcess = null;

  if (code != 0) exit(code);
}

Future<void> killGradle() async {
  if (Platform.isWindows) {
    await Process.run('taskkill', ['/F', '/IM', 'java.exe']);
  } else {
    await Process.run('pkill', ['-f', 'GradleDaemon']);
  }
}
