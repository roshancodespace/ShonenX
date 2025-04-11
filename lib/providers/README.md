# Riverpod State Management Guidelines

This document outlines the best practices for using Riverpod in the ShonenX project.

## Provider Organization

All providers should be organized in the following way:

1. **Domain-specific providers** should be placed in their respective domain folders (e.g., `providers/anilist/`)
2. **Common providers** should be re-exported from `providers/providers.dart`
3. **UI-specific providers** should be placed close to the UI that uses them

## Provider Types

Use the appropriate provider type for your use case:

- **Provider**: For simple dependencies or values that don't change
- **StateProvider**: For simple state that changes but doesn't need complex logic
- **StateNotifierProvider**: For complex state with business logic
- **FutureProvider**: For async data fetching
- **StreamProvider**: For streaming data

## State Classes

State classes should be:

1. **Immutable**: Use `@immutable` annotation and make all fields `final`
2. **Have a `copyWith` method**: For easy state updates
3. **Have meaningful default values**: To avoid null checks

Example:

```dart
@immutable
class MyState {
  final String value;
  final bool isLoading;
  final String? error;

  const MyState({
    required this.value,
    this.isLoading = false,
    this.error,
  });

  MyState copyWith({
    String? value,
    bool? isLoading,
    String? error,
  }) {
    return MyState(
      value: value ?? this.value,
      isLoading: isLoading ?? this.isLoading,
      error: error, // Allow null to clear error
    );
  }
}
```

## StateNotifier Classes

StateNotifier classes should:

1. **Have clear method names**: Methods should describe what they do
2. **Handle errors gracefully**: Catch exceptions and update state accordingly
3. **Avoid side effects**: Keep side effects in the UI layer when possible
4. **Use flags to prevent duplicate operations**: Prevent concurrent operations that could conflict

Example:

```dart
class MyStateNotifier extends StateNotifier<MyState> {
  MyStateNotifier() : super(const MyState(value: ''));

  Future<void> fetchData() async {
    if (state.isLoading) return; // Prevent duplicate calls
    
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final result = await _fetchDataFromApi();
      state = state.copyWith(value: result, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }
}
```

## Consuming Providers

When consuming providers in widgets:

1. **Use `select` for efficient rebuilds**: Only watch the parts of the state you need
2. **Use `ref.read` for one-time reads**: Use `ref.read` in callbacks, not in the build method
3. **Use `ref.watch` for reactive updates**: Use `ref.watch` in the build method for reactive updates
4. **Use AsyncValue utilities**: Use the AsyncValue utilities for handling loading and error states

Example:

```dart
// Good - only rebuilds when isLoading changes
final isLoading = ref.watch(myProvider.select((state) => state.isLoading));

// Good - only rebuilds when the specific value changes
final value = ref.watch(myProvider.select((state) => state.value));

// Bad - rebuilds when any part of the state changes
final state = ref.watch(myProvider);
```

## Error Handling

For consistent error handling:

1. **Use AsyncValue for async operations**: AsyncValue handles loading, data, and error states
2. **Use the AsyncValueUI extension**: For consistent UI handling of AsyncValue
3. **Clear errors when retrying operations**: Set error to null when retrying

## Provider Dependencies

When a provider depends on other providers:

1. **Use `ref.watch` for reactive dependencies**: The provider will update when its dependencies change
2. **Create intermediate providers**: Break down complex provider chains
3. **Handle null or loading states**: Provide meaningful defaults or fallbacks

## Testing

When testing providers:

1. **Use ProviderContainer**: Create a ProviderContainer for testing
2. **Override dependencies**: Use `overrideWithValue` to mock dependencies
3. **Test state transitions**: Test that state transitions correctly

## Performance Considerations

For better performance:

1. **Use `keepAlive` for caching**: Keep providers alive for a specific duration
2. **Use `autoDispose` for cleanup**: Automatically dispose providers when they're no longer used
3. **Use `family` for parameterized providers**: Create providers with parameters
4. **Use `select` to minimize rebuilds**: Only rebuild when necessary
