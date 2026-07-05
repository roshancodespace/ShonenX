import 'package:flutter/material.dart';
import 'package:shonenx/core/network/auth/authenticator.dart';
import 'package:shonenx/core/network/http_client.dart';
import 'package:shonenx/core/router/app_router.dart';
import 'package:shonenx/features/tracking/domain/models/tracker_type.dart';

class KitsuAuthenticator implements Authenticator {
  @override
  String get providerName => TrackerType.kitsu.name;

  @override
  List<String> get apiHosts => ['kitsu.io'];

  @override
  String get redirectUri => '';

  @override
  String get callbackScheme => '';

  @override
  Future<String> performLogin() async {
    final context = rootNavigatorKey.currentContext;
    if (context == null) {
      throw Exception('Kitsu Auth Error: No UI context available for login.');
    }

    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const _KitsuLoginDialog(),
    );

    if (result == null || result.isEmpty) {
      throw Exception('Kitsu login cancelled.');
    }

    return result;
  }
}

class _KitsuLoginDialog extends StatefulWidget {
  const _KitsuLoginDialog();

  @override
  State<_KitsuLoginDialog> createState() => _KitsuLoginDialogState();
}

class _KitsuLoginDialogState extends State<_KitsuLoginDialog> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = 'Please enter both email/username and password.');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final http = HTTP();
      final response = await http.post(
        'https://kitsu.io/api/oauth/token',
        body: {
          "grant_type": "password",
          "username": email,
          "password": password,
        },
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
      );

      final json = response.json;
      final String? accessToken = json['access_token'];

      if (accessToken != null && accessToken.isNotEmpty) {
        if (mounted) Navigator.of(context).pop(accessToken);
      } else {
        throw Exception('Failed to retrieve access token.');
      }
    } catch (e) {
      String msg = 'Failed to login. Please check your credentials.';
      final str = e.toString();
      if (str.contains('invalid_grant') || str.contains('Invalid credentials')) {
        msg = 'Invalid email/username or password.';
      } else if (str.isNotEmpty) {
        msg = str.replaceAll('Exception: ', '').replaceAll('HttpException: ', '');
      }
      if (mounted) {
        setState(() {
          _error = msg;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: const Text('Login to Kitsu'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter your Kitsu email (or username) and password to sync your library.',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email or Username',
                prefixIcon: Icon(Icons.person_outline),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              enabled: !_isLoading,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock_outline),
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() => _obscurePassword = !_obscurePassword);
                  },
                ),
              ),
              onSubmitted: (_) => _login(),
              enabled: !_isLoading,
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: TextStyle(color: theme.colorScheme.error, fontSize: 13),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(null),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _login,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Login'),
        ),
      ],
    );
  }
}
