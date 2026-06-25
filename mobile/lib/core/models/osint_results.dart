import 'breach_entry.dart';
import 'account_entry.dart';
import 'risk_domain_models.dart';

/// Full OSINT result payload — mirrors OsintResults in app/models.py
class OsintResults {
  final String email;
  final GravatarResult? gravatar;
  final List<BreachEntry> breaches;
  final int breachCount;
  final List<AccountEntry> accounts;
  final int accountCount;
  final DomainResult? domain;
  final RiskScore? risk;
  final Map<String, String> errors;

  const OsintResults({
    required this.email,
    this.gravatar,
    this.breaches = const [],
    this.breachCount = 0,
    this.accounts = const [],
    this.accountCount = 0,
    this.domain,
    this.risk,
    this.errors = const {},
  });

  List<AccountEntry> get foundAccounts => accounts.where((a) => a.exists).toList();

  factory OsintResults.fromJson(Map<String, dynamic> json) => OsintResults(
        email: json['email'] as String? ?? '',
        gravatar: json['gravatar'] != null
            ? GravatarResult.fromJson(json['gravatar'] as Map<String, dynamic>)
            : null,
        breaches: (json['breaches'] as List<dynamic>?)
                ?.map((e) => BreachEntry.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        breachCount: json['breach_count'] as int? ?? 0,
        accounts: (json['accounts'] as List<dynamic>?)
                ?.map((e) => AccountEntry.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        accountCount: json['account_count'] as int? ?? 0,
        domain: json['domain'] != null
            ? DomainResult.fromJson(json['domain'] as Map<String, dynamic>)
            : null,
        risk: json['risk'] != null
            ? RiskScore.fromJson(json['risk'] as Map<String, dynamic>)
            : null,
        errors: (json['errors'] as Map<String, dynamic>?)
                ?.map((k, v) => MapEntry(k, v.toString())) ??
            {},
      );
}

/// Lightweight search record for history list — mirrors SearchRecord in models.py
class SearchRecord {
  final String id;
  final String email;
  final String status;
  final String? createdAt;
  final OsintResults? results;
  final String? errorMessage;

  const SearchRecord({
    required this.id,
    required this.email,
    required this.status,
    this.createdAt,
    this.results,
    this.errorMessage,
  });

  bool get isCompleted => status == 'completed';
  bool get isProcessing => status == 'processing' || status == 'pending';
  bool get isFailed => status == 'failed';

  factory SearchRecord.fromJson(Map<String, dynamic> json) => SearchRecord(
        id: json['id'] as String? ?? '',
        email: json['email'] as String? ?? '',
        status: json['status'] as String? ?? 'pending',
        createdAt: json['created_at'] as String?,
        errorMessage: json['error_message'] as String?,
        results: json['results'] != null && (json['results'] as Map).isNotEmpty
            ? OsintResults.fromJson(json['results'] as Map<String, dynamic>)
            : null,
      );
}
