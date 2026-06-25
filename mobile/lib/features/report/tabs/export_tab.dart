import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/osint_results.dart';
import '../../../core/providers/search_provider.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/endpoints.dart';

class ExportTab extends ConsumerWidget {
  final OsintResults results;
  final String email;

  const ExportTab({super.key, required this.results, required this.email});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(searchProvider);
    final searchId = state.searchId ?? '';

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        // Header
        const Text(
          'Export Report',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Download or share the full OSINT report for $email',
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
        ),

        const SizedBox(height: 32),

        // Export options
        _ExportCard(
          icon: Icons.picture_as_pdf_rounded,
          title: 'PDF Report',
          subtitle: 'Formatted report with all findings',
          color: AppTheme.error,
          onTap: () => _openUrl(
            context,
            '${ApiClient.instance.dio.options.baseUrl}${Endpoints.exportPdf(searchId)}',
          ),
        ).animate().fadeIn().slideY(begin: 0.2, end: 0),

        const SizedBox(height: 12),

        _ExportCard(
          icon: Icons.data_object_rounded,
          title: 'JSON Export',
          subtitle: 'Raw structured data for further analysis',
          color: AppTheme.accent,
          onTap: () => _openUrl(
            context,
            '${ApiClient.instance.dio.options.baseUrl}${Endpoints.exportJson(searchId)}',
          ),
        ).animate(delay: 100.ms).fadeIn().slideY(begin: 0.2, end: 0),

        const SizedBox(height: 12),

        _ExportCard(
          icon: Icons.share_rounded,
          title: 'Share Summary',
          subtitle: 'Share key findings as text',
          color: AppTheme.warning,
          onTap: () => _shareSummary(results),
        ).animate(delay: 200.ms).fadeIn().slideY(begin: 0.2, end: 0),

        const SizedBox(height: 32),

        // Quick stats summary
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: AppTheme.cardGradient,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.surfaceBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'REPORT SUMMARY',
                style: TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 16),
              _SummaryRow(
                label: 'Email',
                value: email,
                color: AppTheme.textPrimary,
              ),
              if (results.risk != null)
                _SummaryRow(
                  label: 'Risk Score',
                  value: '${results.risk!.score}/100 (${results.risk!.label})',
                  color: AppTheme.riskColor(results.risk!.label),
                ),
              _SummaryRow(
                label: 'Breaches',
                value: '${results.breachCount} found',
                color: results.breachCount > 0 ? AppTheme.error : AppTheme.success,
              ),
              _SummaryRow(
                label: 'Accounts',
                value: '${results.accountCount} registered',
                color: AppTheme.warning,
              ),
              _SummaryRow(
                label: 'Gravatar',
                value: (results.gravatar?.found ?? false) ? 'Found' : 'Not found',
                color: (results.gravatar?.found ?? false)
                    ? AppTheme.success
                    : AppTheme.textMuted,
              ),
            ],
          ),
        ).animate(delay: 300.ms).fadeIn(),
      ],
    );
  }

  Future<void> _openUrl(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open URL. Is the server running?')),
      );
    }
  }

  void _shareSummary(OsintResults r) {
    final risk = r.risk;
    final text = '''
🔍 Email OSINT Report
━━━━━━━━━━━━━━━━━━━━
📧 Target: ${r.email}
⚠️ Risk Score: ${risk?.score ?? 'N/A'}/100 (${risk?.label ?? 'Unknown'})
🛡️ Breaches: ${r.breachCount} found
👤 Accounts: ${r.accountCount} registered
━━━━━━━━━━━━━━━━━━━━
Generated by Email OSINT App
'''.trim();

    Share.share(text, subject: 'OSINT Report: ${r.email}');
  }
}

class _ExportCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ExportCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, color: color, size: 16),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SummaryRow({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
          Text(value,
              style: TextStyle(
                  color: color, fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
