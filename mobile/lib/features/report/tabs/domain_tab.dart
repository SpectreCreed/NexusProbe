import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/osint_results.dart';

class DomainTab extends StatelessWidget {
  final OsintResults results;
  const DomainTab({super.key, required this.results});

  @override
  Widget build(BuildContext context) {
    final domain = results.domain;

    if (domain == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.dns_outlined, color: AppTheme.textMuted, size: 64),
              SizedBox(height: 16),
              Text(
                'No domain data available',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Domain header
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: AppTheme.cardGradient,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppTheme.accent.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.accentSurface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.domain_rounded, color: AppTheme.accent, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      domain.domain,
                      style: const TextStyle(
                        color: AppTheme.accent,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (domain.registrar != null)
                      Text(
                        'via ${domain.registrar}',
                        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // WHOIS section
        _InfoCard(
          title: 'WHOIS Information',
          icon: Icons.info_outline_rounded,
          children: [
            if (domain.registrar != null)
              _InfoRow('Registrar', domain.registrar!),
            if (domain.creationDate != null)
              _InfoRow('Registered', domain.creationDate!.split('T').first),
            if (domain.expirationDate != null)
              _InfoRow('Expires', domain.expirationDate!.split('T').first),
          ],
        ),

        const SizedBox(height: 12),

        // DNS / Email security
        _InfoCard(
          title: 'Email Security',
          icon: Icons.shield_outlined,
          children: [
            _InfoRow(
              'SPF',
              domain.spfRecord ?? 'Not configured',
              valueColor: domain.spfRecord != null ? AppTheme.success : AppTheme.error,
              monospace: true,
              maxLines: 2,
            ),
            _InfoRow(
              'DMARC',
              domain.dmarcRecord ?? 'Not configured',
              valueColor: domain.dmarcRecord != null ? AppTheme.success : AppTheme.error,
              monospace: true,
              maxLines: 2,
            ),
          ],
        ),

        if (domain.mxRecords.isNotEmpty) ...[
          const SizedBox(height: 12),
          _InfoCard(
            title: 'MX Records',
            icon: Icons.mail_outlined,
            children: domain.mxRecords
                .map((mx) => _InfoRow('', mx, monospace: true))
                .toList(),
          ),
        ],

        if (domain.nameservers.isNotEmpty) ...[
          const SizedBox(height: 12),
          _InfoCard(
            title: 'Nameservers',
            icon: Icons.dns_outlined,
            children: domain.nameservers
                .map((ns) => _InfoRow('', ns, monospace: true))
                .toList(),
          ),
        ],
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _InfoCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppTheme.cardGradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.surfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Icon(icon, color: AppTheme.textSecondary, size: 16),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppTheme.surfaceBorder),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool monospace;
  final int maxLines;

  const _InfoRow(
    this.label,
    this.value, {
    this.valueColor,
    this.monospace = false,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () {
        Clipboard.setData(ClipboardData(text: value));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Copied to clipboard'), duration: Duration(seconds: 1)),
        );
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: label.isEmpty
            ? Text(
                value,
                style: TextStyle(
                  color: valueColor ?? AppTheme.textPrimary,
                  fontSize: 12,
                  fontFamily: monospace ? 'monospace' : null,
                ),
                maxLines: maxLines,
                overflow: TextOverflow.ellipsis,
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 70,
                    child: Text(
                      label,
                      style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      value,
                      style: TextStyle(
                        color: valueColor ?? AppTheme.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        fontFamily: monospace ? 'monospace' : null,
                      ),
                      maxLines: maxLines,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
