import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';

/// Unofficial REST client for DEGIRO, derived from the open-source reference
/// implementation at https://github.com/Chavithra/degiro-connector. DEGIRO
/// does not publish any API for third-party apps (its own help pages say so
/// explicitly), but unlike Trade Republic this login has no bot-challenge
/// layer: it is a plain username/password (+ optional TOTP) POST followed by
/// a session-cookie-authenticated REST session. Everything happens directly
/// between this device and trader.degiro.nl; no server or third party of
/// ours is ever involved.
class DegiroTwoFactorRequiredException implements Exception {
  const DegiroTwoFactorRequiredException();
}

class DegiroLoginException implements Exception {
  DegiroLoginException(this.message);
  final String message;

  @override
  String toString() => message;
}

class DegiroClient {
  factory DegiroClient({CookieJar? cookieJar}) {
    final jar = cookieJar ?? CookieJar();
    final dio = Dio(BaseOptions(baseUrl: 'https://trader.degiro.nl'))
      ..interceptors.add(CookieManager(jar));
    return DegiroClient._(cookieJar: jar, dio: dio);
  }

  DegiroClient._({required CookieJar cookieJar, required Dio dio})
    : _cookieJar = cookieJar,
      _dio = dio;

  final CookieJar _cookieJar;
  final Dio _dio;

  /// Logs in and returns the session id. If the account has 2FA enabled and
  /// no [oneTimePassword] was given, throws [DegiroTwoFactorRequiredException]
  /// so the caller can ask the user for a code and call this again.
  Future<String> login({
    required String username,
    required String password,
    String? oneTimePassword,
  }) async {
    final path = oneTimePassword == null
        ? '/login/secure/login'
        : '/login/secure/login/totp';
    final response = await _dio.post(
      path,
      data: {
        'username': username,
        'password': password,
        'isPassCodeReset': false,
        'isRedirectToMobile': false,
        'queryParams': <String, dynamic>{},
        'oneTimePassword': ?oneTimePassword,
      },
      options: Options(validateStatus: (status) => status != null && status < 500),
    );
    final data = response.data as Map<String, dynamic>;
    if (response.statusCode == 200 && data['sessionId'] is String) {
      return data['sessionId'] as String;
    }
    if (data['status'] == 6) {
      throw const DegiroTwoFactorRequiredException();
    }
    throw DegiroLoginException(
      (data['error'] as String?) ?? 'DEGIRO login failed (${response.statusCode}).',
    );
  }

  Future<int> getAccountId(String sessionId) async {
    final response = await _dio.get(
      '/pa/secure/client',
      queryParameters: {'sessionId': sessionId},
    );
    final data = (response.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
    return data['intAccount'] as int;
  }

  /// Fetches the `cashFunds` and `portfolio` sections of DEGIRO's combined
  /// account-update endpoint, flattened from DEGIRO's idiosyncratic
  /// list-of-`{name, value}`-pairs format into plain maps.
  Future<Map<String, dynamic>> fetchUpdate({
    required String sessionId,
    required int accountId,
  }) async {
    final response = await _dio.get(
      '/trading/secure/v5/update/$accountId;jsessionid=$sessionId',
      queryParameters: {
        'intAccount': accountId,
        'sessionId': sessionId,
        'cashFunds': 0,
        'portfolio': 0,
      },
    );
    final data = response.data as Map<String, dynamic>;
    return {
      'cashFunds': _flatten(data['cashFunds']?['value']),
      'portfolio': _flatten(data['portfolio']?['value']),
    };
  }

  /// DEGIRO encodes nested objects as lists of `{"name": ..., "value": ...}`
  /// pairs instead of plain JSON objects. This turns that shape into regular
  /// maps/lists so callers can read fields by name.
  dynamic _flatten(dynamic node) {
    if (node is List) {
      final isPairList = node.isNotEmpty &&
          node.every((e) => e is Map && e.containsKey('name'));
      if (isPairList) {
        final map = <String, dynamic>{};
        for (final item in node.cast<Map<String, dynamic>>()) {
          map[item['name'].toString()] = _flatten(item['value']);
        }
        return map;
      }
      return node.map(_flatten).toList();
    }
    return node;
  }

  CookieJar get cookieJar => _cookieJar;
}
