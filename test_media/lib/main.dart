import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (details) {
    FlutterError.presentError(details);

    runApp(
      ErrorApp(
        error: details.exception,
        stack: details.stack ?? StackTrace.current,
      ),
    );
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    runApp(ErrorApp(error: error, stack: stack));

    return true;
  };

  try {
    MediaKit.ensureInitialized();

    runApp(const MyApp());
  } catch (e, st) {
    runApp(ErrorApp(error: e, stack: st));
  }
}

class ErrorApp extends StatelessWidget {
  final Object error;
  final StackTrace stack;

  const ErrorApp({super.key, required this.error, required this.stack});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.red.shade900,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: SelectableText(
              '''
MEDIA KIT INITIALIZATION FAILED

$error

STACK TRACE:

$stack
''',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Media Kit Test',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Media Kit Test')),
      body: const Center(
        child: Text(
          'MediaKit initialized successfully',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
