class RiskScore {
  final int score;
  final String label;
  final String color;
  final Map<String, int> breakdown;

  const RiskScore({
    required this.score,
    required this.label,
    required this.color,
    this.breakdown = const {},
  });

  factory RiskScore.fromJson(Map<String, dynamic> json) => RiskScore(
        score: json['score'] as int? ?? 0,
        label: json['label'] as String? ?? 'Unknown',
        color: json['color'] as String? ?? 'gray',
        breakdown: (json['breakdown'] as Map<String, dynamic>?)
                ?.map((k, v) => MapEntry(k, v as int)) ??
            {},
      );

  factory RiskScore.empty() =>
      const RiskScore(score: 0, label: 'Unknown', color: 'gray');
}

class DomainResult {
  final String domain;
  final String? registrar;
  final String? creationDate;
  final String? expirationDate;
  final List<String> mxRecords;
  final String? spfRecord;
  final String? dmarcRecord;
  final List<String> nameservers;

  const DomainResult({
    required this.domain,
    this.registrar,
    this.creationDate,
    this.expirationDate,
    this.mxRecords = const [],
    this.spfRecord,
    this.dmarcRecord,
    this.nameservers = const [],
  });

  factory DomainResult.fromJson(Map<String, dynamic> json) => DomainResult(
        domain: json['domain'] as String? ?? '',
        registrar: json['registrar'] as String?,
        creationDate: json['creation_date'] as String?,
        expirationDate: json['expiration_date'] as String?,
        mxRecords: (json['mx_records'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
        spfRecord: json['spf_record'] as String?,
        dmarcRecord: json['dmarc_record'] as String?,
        nameservers: (json['nameservers'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
      );
}

class GravatarResult {
  final bool found;
  final String? avatarUrl;
  final String? displayName;
  final String? profileUrl;

  const GravatarResult({
    this.found = false,
    this.avatarUrl,
    this.displayName,
    this.profileUrl,
  });

  factory GravatarResult.fromJson(Map<String, dynamic> json) => GravatarResult(
        found: json['found'] as bool? ?? false,
        avatarUrl: json['avatar_url'] as String?,
        displayName: json['display_name'] as String?,
        profileUrl: json['profile_url'] as String?,
      );
}
