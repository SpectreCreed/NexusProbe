class AccountEntry {
  final String service;
  final bool exists;
  final String? url;
  final String category;

  const AccountEntry({
    required this.service,
    required this.exists,
    this.url,
    this.category = 'other',
  });

  factory AccountEntry.fromJson(Map<String, dynamic> json) => AccountEntry(
        service: json['service'] as String? ?? 'Unknown',
        exists: json['exists'] as bool? ?? false,
        url: json['url'] as String?,
        category: json['category'] as String? ?? 'other',
      );
}
