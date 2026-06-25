class BreachEntry {
  final String name;
  final String? domain;
  final String? breachDate;
  final String? addedDate;
  final int? pwnCount;
  final String? description;
  final List<String> dataClasses;
  final bool isVerified;
  final bool isSensitive;

  const BreachEntry({
    required this.name,
    this.domain,
    this.breachDate,
    this.addedDate,
    this.pwnCount,
    this.description,
    this.dataClasses = const [],
    this.isVerified = false,
    this.isSensitive = false,
  });

  factory BreachEntry.fromJson(Map<String, dynamic> json) => BreachEntry(
        name: json['name'] as String? ?? 'Unknown',
        domain: json['domain'] as String?,
        breachDate: json['breach_date'] as String?,
        addedDate: json['added_date'] as String?,
        pwnCount: json['pwn_count'] as int?,
        description: json['description'] as String?,
        dataClasses: (json['data_classes'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
        isVerified: json['is_verified'] as bool? ?? false,
        isSensitive: json['is_sensitive'] as bool? ?? false,
      );
}
