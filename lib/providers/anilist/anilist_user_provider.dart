import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:shonenx/api/anilist/services/anilist_service.dart';
import 'package:shonenx/api/models/anilist/anilist_user.dart';

final userProvider = StateNotifierProvider<UserNotifier, User?>((ref) {
  return UserNotifier();
});

class UserNotifier extends StateNotifier<User?> {
  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    lOptions: LinuxOptions(),
  );

  UserNotifier() : super(null) {
    log('☑️ UserNotifier instantiated', name: "userProvider");
    _loadUser();
  }

  Future<void> _loadUser() async {
    final accessToken = await _storage.read(key: 'accessToken');
    final user = (await _storage.read(key: 'userData'))?.split('#');
    if (accessToken != null) {
      state = User(
        accessToken: accessToken,
        name: user?[1],
        avatar: user?[2],
        id: int.parse(
          user![0],
        ),
      );
    }
  }

  Future<void> _setUser(Map<String, dynamic> user) async {
    await _storage.write(key: 'accessToken', value: state?.accessToken);
    await _storage.write(
        key: 'userData',
        value: '${user['id']}#${user['name']}#${user['avatar']}');
    _loadUser();
  }

  Future<void> login(String accessToken) async {
    await _storage.write(key: 'accessToken', value: accessToken);
    state = User(accessToken: accessToken);
    final anilistService = AnilistService();
    final user = await anilistService.getUserProfile(accessToken);
    log('$user', name: "userProvider");

    // Set the user once after retrieving the data.
    await _setUser({
      'id': user['id'],
      'name': '${user['name']}',
      'avatar': '${user['avatar']['large']}',
    });
  }

  Future<void> logout({required BuildContext context}) async {
    showAdaptiveDialog(
      context: context,
      builder: (context) {
        return AlertDialog.adaptive(
          title: Text('Anilist Logout'),
          content: Text('You are about to logout. Are you sure?'),
          actions: [
            InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () {
                _storage.delete(key: 'accessToken');
                state = null;
                context.pop();
              },
              child: Container(
                decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(10)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                child: Text('Logout',
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.onErrorContainer)),
              ),
            )
          ],
        );
      },
    );
  }
}
