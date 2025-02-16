import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ErrorScreen extends StatelessWidget {
  final Exception? error;

  const ErrorScreen({super.key, this.error});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('404', style: TextStyle(fontSize: 35)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: theme.colorScheme.primary, size: 100),
              const SizedBox(height: 20),
              Text(
                'Oops! Page not found.',
                style: theme.textTheme.headlineMedium?.copyWith(color: theme.colorScheme.onSurface),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                'The page you are looking for might have been removed,\n'
                'had its name changed, or is temporarily unavailable.',
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () => context.go('/'),
                child: const Text('Go to Homepage'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}