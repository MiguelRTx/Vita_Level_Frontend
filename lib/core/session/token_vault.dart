import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract interface class TokenPersistence {
  Future<String?> read();
  Future<void> write(String value);
  Future<void> clear();
}

class MemoryTokenPersistence implements TokenPersistence {
  String? _value;
  @override
  Future<String?> read() async => _value;
  @override
  Future<void> write(String value) async {
    _value = value;
  }

  @override
  Future<void> clear() async {
    _value = null;
  }
}

class SecureTokenPersistence implements TokenPersistence {
  static const _key = 'ritmo.session.v1';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  @override
  Future<String?> read() => _storage.read(key: _key);
  @override
  Future<void> write(String value) => _storage.write(key: _key, value: value);
  @override
  Future<void> clear() => _storage.delete(key: _key);
}

class TokenVault {
  TokenVault(this.persistence);
  final TokenPersistence persistence;
  String? token;
  DateTime? expiresAt;
  bool get isExpired =>
      expiresAt == null || !expiresAt!.isAfter(DateTime.now());

  Future<bool> restore() async {
    final raw = await persistence.read();
    if (raw == null) return false;
    try {
      final value = jsonDecode(raw) as Map<String, dynamic>;
      final expiration = DateTime.parse(value['expiresAt'] as String);
      final savedToken = value['token'] as String;
      if (savedToken.isEmpty || !expiration.isAfter(DateTime.now())) {
        await clear();
        return false;
      }
      token = savedToken;
      expiresAt = expiration;
      return true;
    } on FormatException {
      await clear();
      return false;
    } on TypeError {
      await clear();
      return false;
    }
  }

  Future<void> save(String value, DateTime expiration) async {
    await persistence.write(
      jsonEncode({
        'token': value,
        'expiresAt': expiration.toUtc().toIso8601String(),
      }),
    );
    token = value;
    expiresAt = expiration;
  }

  Future<void> clear() async {
    token = null;
    expiresAt = null;
    await persistence.clear();
  }
}
