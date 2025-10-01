import 'package:flutter/material.dart';

typedef AuthAction = void Function();

class ServiceLoginButton extends StatelessWidget {
  final String serviceName;
  final String logoUrl;
  final Color primaryColor;
  final AuthAction onLogin;
  final AuthAction onLogout;
  final bool isLoading;
  final bool isAuthenticated;
  final String? username;
  final VoidCallback? onClick;

  const ServiceLoginButton({
    super.key,
    required this.serviceName,
    required this.logoUrl,
    required this.primaryColor,
    required this.onLogin,
    required this.onLogout,
    required this.isLoading,
    required this.isAuthenticated,
    this.onClick,
    this.username,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onClick,
      child: Card(
        margin: EdgeInsets.zero,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // Logo
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey[100],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    logoUrl,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Name + username
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(serviceName,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text(
                      isAuthenticated
                          ? 'Logged in as $username'
                          : 'Track your anime and manga',
                      style: TextStyle(
                        fontSize: 12,
                        color:
                            isAuthenticated ? primaryColor : Colors.grey[600],
                      ),
                    )
                  ],
                ),
              ),
              // Action
              if (isLoading)
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(primaryColor),
                  ),
                )
              else if (isAuthenticated)
                TextButton.icon(
                  onPressed: onLogout,
                  icon: Icon(Icons.logout, color: primaryColor),
                  label: const Text('Logout'),
                )
              else
                ElevatedButton(
                  onPressed: onLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Login'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
