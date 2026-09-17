import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Fully local authentication: a device PIN, hashed and stored in
/// SharedPreferences. There is no server round-trip — this only gates
/// access to the locally-stored data on this device.
class AuthService {
  static const _pinKey = 'app_pin_hash';

  Future<bool> hasPin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_pinKey);
  }

  String _hash(String pin) => sha256.convert(utf8.encode(pin)).toString();

  Future<void> setPin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pinKey, _hash(pin));
  }

  Future<bool> verifyPin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_pinKey);
    return stored != null && stored == _hash(pin);
  }

  Future<void> resetPin() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pinKey);
  }
}
