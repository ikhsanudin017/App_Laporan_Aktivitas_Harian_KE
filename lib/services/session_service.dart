import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_user.dart';

class SessionService {
  static const String _userKey = 'session_user';
  static const String _tokenKey = 'session_token';

  Future<void> saveSession(AppUser user, String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(user.toJson()));
    await prefs.setString(_tokenKey, token);
  }

  Future<SessionData?> loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    final userRaw = prefs.getString(_userKey);
    final token = prefs.getString(_tokenKey);

    if (userRaw == null || token == null || token.isEmpty) {
      return null;
    }

    try {
      final json = jsonDecode(userRaw) as Map<String, dynamic>;
      return SessionData(user: AppUser.fromJson(json), token: token);
    } catch (_) {
      return null;
    }
  }

  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
    await prefs.remove(_tokenKey);
  }
}
