import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/osint_results.dart';
import '../../../core/models/risk_domain_models.dart';

class SummaryTab extends StatelessWidget {
  final OsintResults results;
  const SummaryTab({super.key, required this.results});

  @override
  Widget build(BuildContext context) {
    final risk = results.risk;
    final gravatar = results.gravatar;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Profile header card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: AppTheme.cardGradient,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.surfaceBorder),
          ),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: AppTheme.accentGradient,
                ),
                child: gravatar != null && gravatar.found && gravatar.avatarUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: CachedNetworkImage(
                          imageUrl: gravatar.avatarUrl!,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => const _AvatarPlaceholder(),
                          errorWidget: (_, __, ___) => const _AvatarPlaceholder(),
                        ),
                      )
                    : const _AvatarPlaceholder(),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      gravatar?.displayName ?? results.email.split('@').first,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      results.email,
                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _InfoChip(
                          label: '${results.breachCount} breach${results.breachCount != 1 ? 'es' : ''}',
                          color: results.breachCount > 0 ? AppTheme.error : AppTheme.success,
                        ),
                        const SizedBox(width: 6),
                        _InfoChip(
                          label: '${results.accountCount} accounts',
                          color: AppTheme.warning,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Risk gauge
        if (risk != null) _RiskGauge(risk: risk),

        const SizedBox(height: 20),

        // Stats grid
        _StatsGrid(results: results),

        const SizedBox(height: 20),

        // Errors (if any)
        if (results.errors.isNotEmpty) _ErrorsCard(errors: results.errors),
      ],
    );
  }
}

// ── Risk Gauge ─────────────────────────────────────────────────────────────────

class _RiskGauge extends StatelessWidget {
  final RiskScore risk;
  const _RiskGauge({required this.risk});

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.riskColor(risk.label);
    final normalized = risk.score / 100;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppTheme.cardGradient,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.surfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'RISK ASSESSMENT',
            style: TextStyle(
              color: AppTheme.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              // Pie gauge
              SizedBox(
                width: 100,
                height: 100,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    PieChart(
                      PieChartData(
                        startDegreeOffset: -90,
                        sections: [
                          PieChartSectionData(
                            value: normalized,
                            color: color,
                            radius: 16,
                            showTitle: false,
                          ),
                          PieChartSectionData(
                            value: 1 - normalized,
                            color: AppTheme.surfaceHigh,
                            radius: 16,
                            showTitle: false,
                          ),
                        ],
                        centerSpaceRadius: 34,
                        sectionsSpace: 2,
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${risk.score}',
                          style: TextStyle(
                            color: color,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const Text(
                          '/100',
                          style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: color.withOpacity(0.4)),
                      ),
                      child: Text(
                        risk.label.toUpperCase(),
                        style: TextStyle(
                          color: color,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Breakdown bars
                    ...risk.breakdown.entries.take(4).map((e) => _BreakdownBar(
                          label: e.key,
                          value: e.value,
                          color: color,
                        )),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BreakdownBar extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _BreakdownBar({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
              Text('$value',
                  style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 3),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: value / 100,
              backgroundColor: AppTheme.surfaceHigh,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Stats grid ─────────────────────────────────────────────────────────────────

class _StatsGrid extends StatelessWidget {
  final OsintResults results;
  const _StatsGrid({required this.results});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: [
        _StatCard(
          icon: Icons.security_rounded,
          label: 'Breaches',
          value: '${results.breachCount}',
          color: results.breachCount > 0 ? AppTheme.error : AppTheme.success,
        ),
        _StatCard(
          icon: Icons.people_rounded,
          label: 'Accounts Found',
          value: '${results.accountCount}',
          color: AppTheme.warning,
        ),
        _StatCard(
          icon: Icons.face_rounded,
          label: 'Gravatar',
          value: (results.gravatar?.found ?? false) ? 'Found' : 'None',
          color: (results.gravatar?.found ?? false) ? AppTheme.accent : AppTheme.textMuted,
        ),
        _StatCard(
          icon: Icons.domain_rounded,
          label: 'Domain',
          value: results.domain != null ? 'Resolved' : 'N/A',
          color: results.domain != null ? AppTheme.accent : AppTheme.textMuted,
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            label,
            style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final Color color;
  const _InfoChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _AvatarPlaceholder extends StatelessWidget {
  const _AvatarPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Icon(Icons.person_rounded, color: Colors.black54, size: 36);
  }
}

class _ErrorsCard extends StatelessWidget {
  final Map<String, String> errors;
  const _ErrorsCard({required this.errors});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.warning.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.warning.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: AppTheme.warning, size: 16),
              SizedBox(width: 6),
              Text(
                'Some modules had errors',
                style: TextStyle(
                    color: AppTheme.warning, fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...errors.entries.map(
            (e) => Text(
              '${e.key}: ${e.value}',
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
