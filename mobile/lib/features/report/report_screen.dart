import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/search_provider.dart';
import '../../core/models/osint_results.dart';
import 'tabs/summary_tab.dart';
import 'tabs/social_tab.dart';
import 'tabs/breaches_tab.dart';
import 'tabs/domain_tab.dart';
import 'tabs/export_tab.dart';

class ReportScreen extends ConsumerWidget {
  final String searchId;
  const ReportScreen({super.key, required this.searchId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(searchProvider);

    // Loading / polling state
    if (state.isLoading || state.searchId == null) {
      return _LoadingView(
        email: state.email ?? '',
        progressPct: state.progressPct,
      );
    }

    // Error state
    if (state.phase == SearchPhase.failed) {
      return _ErrorView(error: state.error ?? 'Search failed');
    }

    // Completed
    final results = state.results;
    if (results == null) {
      return _ErrorView(error: 'No results found');
    }

    return _ResultsView(results: results, email: state.email ?? '');
  }
}

// ── Loading view ───────────────────────────────────────────────────────────────

class _LoadingView extends StatelessWidget {
  final String email;
  final int progressPct;

  const _LoadingView({required this.email, required this.progressPct});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        leading: IconButton(
          onPressed: () => context.go('/'),
          icon: const Icon(Icons.close_rounded),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated radar icon
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppTheme.accentSurface,
                  borderRadius: BorderRadius.circular(50),
                  border: Border.all(color: AppTheme.accent.withOpacity(0.3), width: 2),
                ),
                child: const Icon(Icons.radar_rounded, color: AppTheme.accent, size: 50),
              )
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .scale(
                    begin: const Offset(0.9, 0.9),
                    end: const Offset(1.05, 1.05),
                    duration: 1200.ms,
                    curve: Curves.easeInOut,
                  ),

              const SizedBox(height: 32),

              Text(
                'Scanning $email',
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ).animate().fadeIn(),

              const SizedBox(height: 8),

              const Text(
                'Running OSINT modules in parallel...',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
              ).animate(delay: 200.ms).fadeIn(),

              const SizedBox(height: 36),

              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progressPct / 100,
                  backgroundColor: AppTheme.surfaceHigh,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.accent),
                  minHeight: 6,
                ),
              ),

              const SizedBox(height: 12),

              Text(
                '$progressPct%',
                style: const TextStyle(
                  color: AppTheme.accent,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 40),

              // Running modules chips
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: const [
                  _ModuleChip('Holehe', Icons.people_outlined),
                  _ModuleChip('Breaches', Icons.security_outlined),
                  _ModuleChip('Gravatar', Icons.face_outlined),
                  _ModuleChip('Domain', Icons.dns_outlined),
                  _ModuleChip('Risk Score', Icons.analytics_outlined),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModuleChip extends StatelessWidget {
  final String label;
  final IconData icon;
  const _ModuleChip(this.label, this.icon);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.accentSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.accent.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppTheme.accent, size: 14),
          const SizedBox(width: 6),
          Text(label,
              style: const TextStyle(
                  color: AppTheme.accent, fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .fade(begin: 0.5, end: 1.0, duration: 1500.ms, curve: Curves.easeInOut);
  }
}

// ── Error view ─────────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String error;
  const _ErrorView({required this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        leading: IconButton(
          onPressed: () => context.go('/'),
          icon: const Icon(Icons.arrow_back_ios_rounded),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded, color: AppTheme.error, size: 72)
                  .animate()
                  .shake(),
              const SizedBox(height: 24),
              const Text(
                'Scan Failed',
                style: TextStyle(
                    color: AppTheme.textPrimary, fontSize: 24, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              Text(
                error,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 15),
              ),
              const SizedBox(height: 36),
              ElevatedButton(
                onPressed: () => context.go('/'),
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Results view (tabbed) ──────────────────────────────────────────────────────

class _ResultsView extends StatelessWidget {
  final OsintResults results;
  final String email;

  const _ResultsView({required this.results, required this.email});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          backgroundColor: AppTheme.surface,
          leading: IconButton(
            onPressed: () => context.go('/'),
            icon: const Icon(Icons.arrow_back_ios_rounded),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                email,
                style: const TextStyle(
                    color: AppTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              ),
              if (results.risk != null)
                Text(
                  'Risk: ${results.risk!.label} · ${results.risk!.score}/100',
                  style: TextStyle(
                    color: AppTheme.riskColor(results.risk!.label),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
          bottom: const TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              Tab(text: 'Summary'),
              Tab(text: 'Social'),
              Tab(text: 'Breaches'),
              Tab(text: 'Domain'),
              Tab(text: 'Export'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            SummaryTab(results: results),
            SocialTab(results: results),
            BreachesTab(results: results),
            DomainTab(results: results),
            ExportTab(results: results, email: email),
          ],
        ),
      ),
    );
  }
}
