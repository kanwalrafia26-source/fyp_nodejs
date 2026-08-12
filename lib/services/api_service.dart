import 'dart:convert';
import 'package:http/http.dart' as http;

/// Flutter ↔ Node.js backend bridge.
///
/// Base URL:
///   Android emulator  → 10.0.2.2  (PC localhost)
///   Real device       → PC LAN IP, e.g. 192.168.1.x
class ApiService {
  // Windows desktop  → localhost
  // Android emulator → 10.0.2.2
  // Real device      → PC LAN IP, e.g. 192.168.1.x
  static const String baseUrl = 'http://localhost:3000/api';

  // JWT token stored here after login
  static String? _token;
  static String? get token => _token;

  // ── Helper: JSON POST request ──────────────────────────────────────────────
  static Future<http.Response> _post(
    String path,
    Map<String, dynamic> body, {
    bool withAuth = false,
  }) async {
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (withAuth && _token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return http.post(
      Uri.parse('$baseUrl$path'),
      headers: headers,
      body: jsonEncode(body),
    );
  }

  // ── Helper: extract error message from response ────────────────────────────
  static String _errorFrom(http.Response res) {
    try {
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      return body['message'] as String? ?? 'Something went wrong.';
    } catch (_) {
      return 'Server error (${res.statusCode}).';
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  // SIGNUP  →  POST /api/auth/signup
  // ════════════════════════════════════════════════════════════════════════════
  /// Returns null on success, error string on failure.
  static Future<String?> signup(
    String email,
    String password, {
    String name = '',
  }) async {
    try {
      final res = await _post('/auth/signup', {
        'email': email,
        'password': password,
        'name': name,
      });
      if (res.statusCode == 201) return null;
      return _errorFrom(res);
    } catch (_) {
      return 'Network error. Is the server running?';
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  // LOGIN  →  POST /api/auth/login
  // ════════════════════════════════════════════════════════════════════════════
  /// Returns null on success, error string on failure.
  /// [onSuccess] callback receives token, name, email.
  static Future<String?> login(
    String email,
    String password, {
    Future<void> Function(String token, String name, String email)? onSuccess,
  }) async {
    try {
      final res = await _post('/auth/login', {
        'email': email,
        'password': password,
      });
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        _token = body['token'] as String? ?? '';
        if (onSuccess != null) {
          await onSuccess(
            _token!,
            body['name'] as String? ?? '',
            body['email'] as String? ?? email,
          );
        }
        return null;
      }
      return _errorFrom(res);
    } catch (_) {
      return 'Network error. Is the server running?';
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  // CHANGE PASSWORD  →  POST /api/auth/change-password
  // ════════════════════════════════════════════════════════════════════════════
  static Future<String?> changePassword({
    required String email,
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final res = await _post(
        '/auth/change-password',
        {
          'email': email,
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        },
        withAuth: true,
      );
      if (res.statusCode == 200) return null;
      return _errorFrom(res);
    } catch (_) {
      return 'Network error. Is the server running?';
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  // FORGOT PASSWORD  →  POST /api/auth/forgot-password
  // ════════════════════════════════════════════════════════════════════════════
  static Future<String?> sendPasswordReset({required String email}) async {
    try {
      final res = await _post('/auth/forgot-password', {'email': email});
      if (res.statusCode == 200) return null;
      return _errorFrom(res);
    } catch (_) {
      return 'Network error. Is the server running?';
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  // RESET PASSWORD  →  POST /api/auth/reset-password
  // ════════════════════════════════════════════════════════════════════════════
  static Future<String?> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    try {
      final res = await _post('/auth/reset-password', {
        'email':       email,
        'code':        code.toUpperCase(),
        'newPassword': newPassword,
      });
      if (res.statusCode == 200) return null;
      return _errorFrom(res);
    } catch (_) {
      return 'Network error. Is the server running?';
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  // SUPPORT MESSAGE  →  POST /api/support/message
  // ════════════════════════════════════════════════════════════════════════════
  static Future<String?> sendSupportMessage({
    required String name,
    required String email,
    required String message,
  }) async {
    try {
      final res = await _post('/support/message', {
        'name':    name,
        'email':   email,
        'message': message,
      });
      if (res.statusCode == 201) return null;
      return _errorFrom(res);
    } catch (_) {
      return 'Network error. Is the server running?';
    }
  }

  /// Clears token on logout.
  static void clearToken() => _token = null;

  /// Restores token from saved session.
  static void restoreToken(String token) => _token = token;

  // ════════════════════════════════════════════════════════════════════════════
  // TRANSCRIBE AUDIO  →  POST /api/analyze/transcribe
  // ════════════════════════════════════════════════════════════════════════════
  /// Uploads an audio file to the local Whisper backend.
  /// Returns { transcript, durationSeconds, wordCount, wpm } on success.
  /// Throws an Exception with a readable message on failure.
  static Future<Map<String, dynamic>> transcribeAudio(String filePath) async {
    try {
      final uri = Uri.parse('$baseUrl/analyze/transcribe');
      final request = http.MultipartRequest('POST', uri);
      request.files.add(await http.MultipartFile.fromPath('audio', filePath));
      if (_token != null) {
        request.headers['Authorization'] = 'Bearer $_token';
      }

      final streamed = await request.send();
      final res = await http.Response.fromStream(streamed);

      if (res.statusCode == 200) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      }
      throw Exception(_errorFrom(res));
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Network error. Is the server running?');
    }
  }
}
