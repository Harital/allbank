import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:web_socket_channel/io.dart';

/// Unofficial REST+WebSocket client for Trade Republic, derived from the
/// open-source reference implementation at https://github.com/pytr-org/pytr
/// (`pytr/api.py`). It deliberately uses TR's "v2" web login flow instead of
/// the "v1"/AWS-WAF-protected one: v1 requires solving a bot challenge
/// normally done with a headless browser, which a mobile app cannot
/// reasonably reproduce. v2 instead asks for a second factor the user
/// already has: a code from an authenticator app, or confirming the login
/// from the official Trade Republic app. Everything happens directly between
/// this device and api.traderepublic.com; no server or third party of ours
/// is ever involved.
enum TrLoginRequiredAction { authenticatorCode, appConfirmation }

class TrLoginProcess {
  const TrLoginProcess({required this.processId, required this.requiredAction});

  final String processId;
  final TrLoginRequiredAction requiredAction;
}

class TrLoginTimeoutException implements Exception {
  TrLoginTimeoutException(this.message);
  final String message;

  @override
  String toString() => message;
}

class TrSubscriptionErrorException implements Exception {
  TrSubscriptionErrorException(this.payload);
  final Map<String, dynamic> payload;

  @override
  String toString() => 'Trade Republic subscription error: $payload';
}

class TrClient {
  TrClient({required String stableDeviceId, required CookieJar cookieJar})
    : _stableDeviceId = stableDeviceId,
      _cookieJar = cookieJar,
      _dio = Dio(
        BaseOptions(
          baseUrl: 'https://api.traderepublic.com',
          headers: {'User-Agent': _userAgent},
        ),
      )..interceptors.add(CookieManager(cookieJar));

  static const _userAgent =
      'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36';
  static const _appVersion = '2.2631.13';
  static const _platform = 'web-pro';

  final String _stableDeviceId;
  final CookieJar _cookieJar;
  final Dio _dio;

  Map<String, String> _loginHeaders() {
    final offsetMinutes = DateTime.now().timeZoneOffset.inMinutes;
    final device = {
      'stableDeviceId': _stableDeviceId,
      'browser': 'Chrome',
      'browserVersion': '131.0.0.0',
      'os': 'Android',
      'osVersion': '14',
      'timezone': DateTime.now().timeZoneName,
      'timezoneOffset': -offsetMinutes,
      'screen': '1080x2400x24',
      'preferredLanguages': ['es'],
      'numberOfCores': 4,
    };
    return {
      'X-TR-Device-Info': base64.encode(utf8.encode(jsonEncode(device))),
      'X-TR-App-Version': _appVersion,
      'X-Tr-Platform': _platform,
      'Accept-Language': 'es',
    };
  }

  /// Starts a login with phone number (`+34...`) and PIN. The result must be
  /// completed either with [submitAuthenticatorCode] or by polling
  /// [awaitAppConfirmation], depending on [TrLoginProcess.requiredAction].
  Future<TrLoginProcess> startLogin({
    required String phoneNumber,
    required String pin,
  }) async {
    final response = await _dio.post(
      '/api/v2/auth/web/login',
      data: {'phoneNumber': phoneNumber, 'pin': pin},
      options: Options(headers: _loginHeaders()),
    );
    final processId = (response.data as Map<String, dynamic>)['processId'] as String;
    final process = await _dio.get(
      '/api/v2/auth/web/login/processes/$processId',
      options: Options(headers: _loginHeaders()),
    );
    final requiredAction =
        (process.data as Map<String, dynamic>)['requiredAction'] as String?;
    return TrLoginProcess(
      processId: processId,
      requiredAction: requiredAction == 'AUTHENTICATOR_VERIFICATION'
          ? TrLoginRequiredAction.authenticatorCode
          : TrLoginRequiredAction.appConfirmation,
    );
  }

  Future<void> submitAuthenticatorCode(TrLoginProcess process, String code) {
    return _dio.post(
      '/api/v2/auth/web/login/processes/${process.processId}/authenticator-verification',
      data: {'code': code},
      options: Options(headers: _loginHeaders()),
    );
  }

  /// Polls until the user confirms the login in the Trade Republic app, or
  /// throws a [TrLoginTimeoutException] after ~2 minutes.
  Future<void> awaitAppConfirmation(TrLoginProcess process) async {
    final deadline = DateTime.now().add(const Duration(minutes: 2));
    while (DateTime.now().isBefore(deadline)) {
      final response = await _dio.get(
        '/api/v2/auth/web/login/processes/${process.processId}',
        options: Options(headers: _loginHeaders()),
      );
      final status = (response.data as Map<String, dynamic>)['status'] as String?;
      if (status == 'CONFIRMED' || status == 'COMPLETED') return;
      await Future.delayed(const Duration(seconds: 2));
    }
    throw TrLoginTimeoutException(
      'Trade Republic login was not confirmed in time.',
    );
  }

  /// A cheap authenticated call used to check whether the stored session
  /// cookies are still valid.
  Future<bool> hasValidSession() async {
    try {
      final response = await _dio.get(
        '/api/v1/auth/web/session',
        options: Options(headers: _loginHeaders()),
      );
      return response.statusCode == 200;
    } on DioException {
      return false;
    }
  }

  /// Opens the portfolio WebSocket, subscribes once to [type] (e.g.
  /// `portfolio` or `cash`) and returns the first full snapshot. Auth is via
  /// the session cookies collected during login, sent as a `Cookie` header on
  /// the WebSocket handshake -- the current API no longer accepts a token in
  /// the subscribe payload.
  Future<Map<String, dynamic>> fetchSnapshot(String type) async {
    final cookies = await _cookieJar.loadForRequest(
      Uri.parse('https://api.traderepublic.com'),
    );
    final cookieHeader = cookies.map((c) => '${c.name}=${c.value}').join('; ');

    final channel = IOWebSocketChannel.connect(
      Uri.parse('wss://api.traderepublic.com'),
      headers: {'Cookie': cookieHeader},
    );
    final messages = StreamQueue(channel.stream);
    try {
      channel.sink.add(
        'connect 31 ${jsonEncode({
          'locale': 'es',
          'platformId': 'webtrading',
          'platformVersion': 'chrome - 131.0.0.0',
          'clientId': 'app.traderepublic.com',
          'clientVersion': '5582',
        })}',
      );
      final connectResponse = await messages.next;
      if (connectResponse != 'connected') {
        throw StateError('Trade Republic WebSocket rejected the connection.');
      }

      const subscriptionId = '1';
      channel.sink.add('sub $subscriptionId ${jsonEncode({'type': type})}');

      while (true) {
        final raw = (await messages.next) as String;
        final firstSpace = raw.indexOf(' ');
        if (firstSpace == -1) continue;
        final id = raw.substring(0, firstSpace);
        if (id != subscriptionId) continue;
        final code = raw.substring(firstSpace + 1, firstSpace + 2);
        final payloadStr = raw.substring(firstSpace + 2).trimLeft();
        if (code == 'A') {
          channel.sink.add('unsub $subscriptionId');
          return payloadStr.isEmpty
              ? <String, dynamic>{}
              : jsonDecode(payloadStr) as Map<String, dynamic>;
        } else if (code == 'E') {
          final payload = payloadStr.isEmpty
              ? <String, dynamic>{}
              : jsonDecode(payloadStr) as Map<String, dynamic>;
          throw TrSubscriptionErrorException(payload);
        }
        // 'C' (closed) or an unexpected 'D' (delta) before the first full
        // answer: keep waiting for the actual 'A' snapshot.
      }
    } finally {
      await channel.sink.close();
    }
  }
}

/// Small pull-based wrapper so we can `await` the next WebSocket message
/// without juggling StreamSubscription callbacks by hand.
class StreamQueue<T> {
  StreamQueue(Stream<T> stream) : _iterator = StreamIterator(stream);

  final StreamIterator<T> _iterator;

  Future<T> get next async {
    if (!await _iterator.moveNext()) {
      throw StateError('Trade Republic WebSocket closed unexpectedly.');
    }
    return _iterator.current;
  }
}

String generateStableDeviceId() {
  final random = Random.secure();
  final bytes = List<int>.generate(32, (_) => random.nextInt(256));
  return base64Url.encode(bytes);
}
