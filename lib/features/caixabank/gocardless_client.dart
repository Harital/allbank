import 'package:dio/dio.dart';

/// Thin REST client for GoCardless Bank Account Data
/// (https://bankaccountdata.gocardless.com/api/v2), the PSD2 AIS aggregator
/// used to link CaixaBank. The user must create their own free GoCardless
/// account and provide their own `secretId`/`secretKey` (see the Settings
/// screen) -- those are the app's API credentials, never the bank password.
/// The bank password is only ever entered on the bank's own page during the
/// requisition link flow; this client never sees it.
class GoCardlessInstitution {
  const GoCardlessInstitution({
    required this.id,
    required this.name,
    required this.bic,
  });

  final String id;
  final String name;
  final String bic;

  factory GoCardlessInstitution.fromJson(Map<String, dynamic> json) =>
      GoCardlessInstitution(
        id: json['id'] as String,
        name: json['name'] as String,
        bic: json['bic'] as String? ?? '',
      );
}

class GoCardlessBalance {
  const GoCardlessBalance({
    required this.amount,
    required this.currency,
    required this.balanceType,
  });

  final double amount;
  final String currency;
  final String balanceType;
}

class GoCardlessRequisition {
  const GoCardlessRequisition({
    required this.id,
    required this.link,
    required this.status,
  });

  final String id;
  final String link;
  final String status;
}

class GoCardlessClient {
  GoCardlessClient({
    required String secretId,
    required String secretKey,
    Dio? dio,
  }) : _secretId = secretId,
       _secretKey = secretKey,
       _dio =
           dio ??
           Dio(
             BaseOptions(
               baseUrl: 'https://bankaccountdata.gocardless.com/api/v2',
             ),
           );

  final String _secretId;
  final String _secretKey;
  final Dio _dio;
  String? _accessToken;

  Future<String> _ensureToken() async {
    final cached = _accessToken;
    if (cached != null) return cached;
    final response = await _dio.post(
      '/token/new/',
      data: {'secret_id': _secretId, 'secret_key': _secretKey},
    );
    final access = (response.data as Map<String, dynamic>)['access'] as String;
    _accessToken = access;
    return access;
  }

  Future<T> _withAuth<T>(
    Future<T> Function(Options options) action,
  ) async {
    var options = Options(
      headers: {'Authorization': 'Bearer ${await _ensureToken()}'},
    );
    try {
      return await action(options);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        _accessToken = null;
        options = Options(
          headers: {'Authorization': 'Bearer ${await _ensureToken()}'},
        );
        return action(options);
      }
      rethrow;
    }
  }

  Future<List<GoCardlessInstitution>> listInstitutions({
    required String country,
  }) {
    return _withAuth((options) async {
      final response = await _dio.get(
        '/institutions/',
        queryParameters: {'country': country},
        options: options,
      );
      return (response.data as List<dynamic>)
          .map(
            (item) =>
                GoCardlessInstitution.fromJson(item as Map<String, dynamic>),
          )
          .toList();
    });
  }

  Future<GoCardlessRequisition> createRequisition({
    required String institutionId,
    required String redirectUri,
    required String reference,
  }) {
    return _withAuth((options) async {
      final response = await _dio.post(
        '/requisitions/',
        data: {
          'redirect': redirectUri,
          'institution_id': institutionId,
          'reference': reference,
          'user_language': 'ES',
        },
        options: options,
      );
      final data = response.data as Map<String, dynamic>;
      return GoCardlessRequisition(
        id: data['id'] as String,
        link: data['link'] as String,
        status: data['status'] as String,
      );
    });
  }

  /// Returns the linked account ids once the user finished the bank's own
  /// login+consent flow, or an empty list if the requisition isn't linked
  /// yet (status other than `LN`).
  Future<List<String>> getLinkedAccountIds(String requisitionId) {
    return _withAuth((options) async {
      final response = await _dio.get(
        '/requisitions/$requisitionId/',
        options: options,
      );
      final data = response.data as Map<String, dynamic>;
      if (data['status'] != 'LN') return const [];
      return (data['accounts'] as List<dynamic>).cast<String>();
    });
  }

  Future<List<GoCardlessBalance>> getAccountBalances(String accountId) {
    return _withAuth((options) async {
      final response = await _dio.get(
        '/accounts/$accountId/balances/',
        options: options,
      );
      final balances =
          (response.data as Map<String, dynamic>)['balances'] as List<dynamic>;
      return balances.map((item) {
        final map = item as Map<String, dynamic>;
        final amount = map['balanceAmount'] as Map<String, dynamic>;
        return GoCardlessBalance(
          amount: double.parse(amount['amount'] as String),
          currency: amount['currency'] as String,
          balanceType: map['balanceType'] as String,
        );
      }).toList();
    });
  }

  Future<String> getAccountDisplayName(String accountId) {
    return _withAuth((options) async {
      final response = await _dio.get(
        '/accounts/$accountId/details/',
        options: options,
      );
      final account =
          (response.data as Map<String, dynamic>)['account']
              as Map<String, dynamic>;
      return (account['name'] ?? account['product'] ?? account['iban'] ?? 'Compte')
          as String;
    });
  }
}
