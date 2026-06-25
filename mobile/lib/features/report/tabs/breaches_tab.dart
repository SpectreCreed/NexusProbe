import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/osint_results.dart';
import '../../../core/models/breach_entry.dart';

class BreachesTab extends StatefulWidget {
  final OsintResults results;
  const BreachesTab({super.key, required this.results});

  @override
  State<BreachesTab> createState() => _BreachesTabState();
}

class _BreachesTabState extends State<BreachesTab> {
  String _sortBy = 'date'; // date | severity | name

  List<BreachEntry> get _sorted {
    final list = [...widget.results.breaches];
    switch (_sortBy) {
      case 'severity':
        list.sort((a, b) =>
            (b.pwnCount ?? 0).compareTo(a.pwnCount ?? 0));
      case 'name':
        list.sort((a, b) => a.name.compareTo(b.name));
      default: // date
        list.sort((a, b) =>
            (b.breachDate ?? '').compareTo(a.breachDate ?? ''));
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final breaches = widget.results.breaches;

    if (breaches.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.verified_user_rounded, color: AppTheme.success, size: 72),
            const SizedBox(height: 16),
            const Text(
              'No breaches found! 🎉',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'This email was not found in any\nknown data breach databases.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Header with sort
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${breaches.length} breach${breaches.length != 1 ? 'es' : ''} found',
              style: const TextStyle(
                color: AppTheme.error,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            // Sort dropdown
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.surfaceHigh,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.surfaceBorder),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _sortBy,
                  dropdownColor: AppTheme.surfaceHigh,
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                  isDense: true,
                  onChanged: (v) => setState(() => _sortBy = v!),
                  items: const [
                    DropdownMenuItem(value: 'date', child: Text('Sort: Date')),
                    DropdownMenuItem(value: 'severity', child: Text('Sort: Severity')),
                    DropdownMenuItem(value: 'name', child: Text('Sort: Name')),
                  ],
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Breach cards
        ..._sorted.map((b) => _BreachCard(breach: b)),
      ],
    );
  }
}

class _BreachCard extends StatelessWidget {
  final BreachEntry breach;
  const _BreachCard({required this.breach});

  @override
  Widget build(BuildContext context) {
    final severity = _severity(breach.pwnCount);
    final severityColor = _severityColor(severity);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: AppTheme.cardGradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: severityColor.withOpacity(0.3)),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: severityColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            Icons.security_rounded,
            color: severityColor,
            size: 20,
          ),
        ),
        title: Text(
          breach.name,
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
        subtitle: Row(
          children: [
            if (breach.breachDate != null) ...[
              Text(
                breach.breachDate!.split('T').first,
                style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
              ),
              const SizedBox(width: 8),
            ],
            _SeverityBadge(severity: severity, color: severityColor),
          ],
        ),
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Divider(color: AppTheme.surfaceBorder, height: 20),

              if (breach.pwnCount != null)
                _DetailRow(
                  icon: Icons.group_rounded,
                  label: 'Accounts affected',
                  value: _formatCount(breach.pwnCount!),
                  valueColor: severityColor,
                ),

              if (breach.domain != null)
                _DetailRow(
                  icon: Icons.language_rounded,
                  label: 'Domain',
                  value: breach.domain!,
                ),

              if (breach.dataClasses.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text(
                  'Data Exposed:',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: breach.dataClasses
                      .map(
                        (d) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.error.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppTheme.error.withOpacity(0.3)),
                          ),
                          child: Text(
                            d,
                            style: const TextStyle(
                              color: AppTheme.error,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],

              if (breach.description != null) ...[
                const SizedBox(height: 12),
                Text(
                  breach.description!
                      .replaceAll(RegExp(r'<[^>]*>'), '')
                      .trim(),
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                    height: 1.5,
                  ),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              Row(
                children: [
                  if (breach.isVerified)
                    _TagChip('Verified', AppTheme.success),
                  if (breach.isSensitive)
                    _TagChip('Sensitive', AppTheme.warning),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _severity(int? count) {
    if (count == null) return 'Unknown';
    if (count > 10000000) return 'Critical';
    if (count > 1000000) return 'High';
    if (count > 100000) return 'Medium';
    return 'Low';
  }

  Color _severityColor(String severity) {
    switch (severity) {
      case 'Critical': return AppTheme.critical;
      case 'High': return AppTheme.error;
      case 'Medium': return AppTheme.warning;
      case 'Low': return AppTheme.success;
      default: return AppTheme.textMuted;
    }
  }

  String _formatCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(0)}K';
    return count.toString();
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.textMuted, size: 14),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
          ),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? AppTheme.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SeverityBadge extends StatelessWidget {
  final String severity;
  final Color color;
  const _SeverityBadge({required this.severity, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        severity,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  final String label;
  final Color color;
  const _TagChip(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 6, top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}
