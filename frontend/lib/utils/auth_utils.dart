import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Clears persisted auth (if any) and navigates to the auth entry route.
Future<void> signOutAndNavigate(BuildContext context) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('auth_user');
  } catch (_) {}

  Navigator.of(context).pushNamedAndRemoveUntil('/auth', (route) => false);
}
