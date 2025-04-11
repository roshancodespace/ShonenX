import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Extension on AsyncValue to provide UI helper methods
extension AsyncValueUI on AsyncValue {
  /// Shows a snackbar with the error message if the AsyncValue has an error
  void showSnackBarOnError(BuildContext context) {
    if (hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString()),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(8),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  /// Widget builder for AsyncValue that handles loading, error, and data states
  /// with a more flexible API than the built-in when method
  Widget whenOrNull<T>({
    Widget Function(T data)? data,
    Widget Function(Object error, StackTrace? stackTrace)? error,
    Widget Function()? loading,
    Widget Function()? orElse,
  }) {
    return when<Widget>(
      data: data != null
          ? (value) => data(value as T)
          : (_) => orElse?.call() ?? const SizedBox.shrink(),
      loading: loading ??
          () =>
              orElse?.call() ??
              const Center(child: CircularProgressIndicator()),
      error: error ??
          (e, s) =>
              orElse?.call() ??
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Error: ${e.toString()}',
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
    );
  }

  /// A simplified version of when that uses a common loading widget and error widget
  Widget simpleWhen<T>({
    required Widget Function(T data) data,
    Widget? loadingWidget,
    Widget Function(Object error)? errorWidget,
  }) {
    return when<Widget>(
      data: (value) => data(value as T),
      loading: () =>
          loadingWidget ??
          const Center(
            child: CircularProgressIndicator(),
          ),
      error: (e, _) =>
          errorWidget?.call(e) ??
          Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    'Error: ${e.toString()}',
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
    );
  }
}
