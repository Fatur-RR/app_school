import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static final _storage = FlutterSecureStorage();
  static const _tokenKey = 'auth_token';
  static bool _initialized = false;

  static Future<void> _initializeStorage() async {
    if (!_initialized) {
      try {
        await _storage.read(key: _tokenKey);
        _initialized = true;
      } catch (e) {
        print('Secure storage not available: $e');
        _initialized = false;
      }
    }
  }

  static Future<String?> getToken() async {
    try {
      await _initializeStorage();
      String? token;
      if (_initialized) {
        token = await _storage.read(key: _tokenKey);
        print("Token from secure storage: $token");
      } else {
        final sharedPrefs = await SharedPreferences.getInstance();
        token = sharedPrefs.getString(_tokenKey);
        print("Token from shared prefs: $token");
      }
      return token;
    } catch (e) {
      print('Error getting token: $e');
      return null;
    }
  }

  static Future<void> setToken(String token) async {
    try {
      await _initializeStorage();
      if (_initialized) {
        await _storage.write(key: _tokenKey, value: token);
      } else {
        // Fallback to shared preferences
        final sharedPrefs = await SharedPreferences.getInstance();
        await sharedPrefs.setString(_tokenKey, token);
      }
    } catch (e) {
      print('Error setting token: $e');
    }
  }

  static Future<void> removeToken() async {
    try {
      await _initializeStorage();
      if (_initialized) {
        await _storage.delete(key: _tokenKey);
      } else {
        // Fallback to shared preferences
        final sharedPrefs = await SharedPreferences.getInstance();
        await sharedPrefs.remove(_tokenKey);
      }
    } catch (e) {
      print('Error removing token: $e');
    }
  }
} 