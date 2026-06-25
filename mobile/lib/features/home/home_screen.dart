import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/search_provider.dart';
import '../../core/models/osint_results.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _emailCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final email = _emailCtrl.text.trim().toLowerCase();
    await ref.read(searchProvider.notifier).startSearch(email);

    final state = ref.read(searchProvider);
    if (state.searchId != null && mounted) {
      context.push('/report/${state.searchId}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final searchState = ref.watch(searchProvider);
    final recentAsync = ref.watch(recentSearchesProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            expandedHeight: 0,
            floating: true,
            backgroundColor: AppTheme.background,
            actions: [
              IconButton(
                onPressed: () => context.push('/history'),
                icon: const Icon(Icons.history_rounded),
                tooltip: 'History',
              ),
              IconButton(
                onPressed: () => context.push('/settings'),
                icon: const Icon(Icons.settings_outlined),
                tooltip: 'Settings',
              ),
              if (!auth.isAuthenticated)
                TextButton(
                  onPressed: () => context.push('/login'),
                  child: const Text('Sign In'),
                )
              else
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: CircleAvatar(
                    radius: 16,
                    backgroundColor: AppTheme.accentSurface,
                    child: Text(
                      (auth.userEmail ?? 'G')[0].toUpperCase(),
                      style: const TextStyle(
                          color: AppTheme.accent,
                          fontWeight: FontWeight.w700,
                          fontSize: 14),
                    ),
                  ),
                ),
            ],
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Greeting
                  Text(
                    auth.isAuthenticated
                        ? 'Hello, ${auth.userEmail?.split('@').first ?? 'Agent'} 👋'
                        : 'Email Intelligence',
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ).animate().fadeIn(),

                  const SizedBox(height: 4),

                  const Text(
                    'Investigate any\nemail address',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                      height: 1.2,
                    ),
                  ).animate(delay: 100.ms).fadeIn().slideY(begin: 0.3, end: 0),

                  const SizedBox(height: 32),

                  // Search card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: AppTheme.cardGradient,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.surfaceBorder),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.accent.withOpacity(0.05),
                          blurRadius: 30,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Target Email',
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: _emailCtrl,
                            keyboardType: TextInputType.emailAddress,
                            autocorrect: false,
                            textInputAction: TextInputAction.search,
                            onFieldSubmitted: (_) => _search(),
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 16,
                            ),
                            decoration: const InputDecoration(
                              hintText: 'target@example.com',
                              prefixIcon: Icon(
                                Icons.alternate_email_rounded,
                                color: AppTheme.accent,
                              ),
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Enter an email address';
                              }
                              if (!RegExp(
                                r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$',
                              ).hasMatch(v.trim())) {
                                return 'Enter a valid email address';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: searchState.isLoading ? null : _search,
                              icon: searchState.isLoading
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2, color: Colors.black),
                                    )
                                  : const Icon(Icons.radar_rounded, size: 20),
                              label: Text(
                                searchState.isLoading
                                    ? 'Scanning...'
                                    : 'Run OSINT Scan',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ).animate(delay: 200.ms).fadeIn().slideY(begin: 0.2, end: 0),

                  const SizedBox(height: 32),

                  // Stats row
                  Row(
                    children: [
                      _StatChip(
                        icon: Icons.shield_rounded,
                        label: 'Breaches',
                        color: AppTheme.error,
                      ),
                      const SizedBox(width: 10),
                      _StatChip(
                        icon: Icons.people_rounded,
                        label: 'Accounts',
                        color: AppTheme.warning,
                      ),
                      const SizedBox(width: 10),
                      _StatChip(
                        icon: Icons.domain_rounded,
                        label: 'Domain Intel',
                        color: AppTheme.accent,
                      ),
                    ],
                  ).animate(delay: 300.ms).fadeIn(),

                  const SizedBox(height: 32),

                  // Recent searches header
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Recent Searches',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ).animate(delay: 350.ms).fadeIn(),

                  const SizedBox(height: 12),

                  // Recent searches list
                  recentAsync.when(
                    data: (searches) => searches.isEmpty
                        ? _EmptyHistory()
                        : Column(
                            children: searches
                                .asMap()
                                .entries
                                .map(
                                  (e) => _RecentCard(
                                    record: e.value,
                                    index: e.key,
                                  ),
                                )
                                .toList(),
                          ),
                    loading: () => const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    error: (e, _) => _EmptyHistory(),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Widgets ────────────────────────────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _StatChip({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentCard extends StatelessWidget {
  final SearchRecord record;
  final int index;

  const _RecentCard({required this.record, required this.index});

  @override
  Widget build(BuildContext context) {
    final statusColor = record.isCompleted
        ? AppTheme.success
        : record.isFailed
            ? AppTheme.error
            : AppTheme.warning;

    final statusIcon = record.isCompleted
        ? Icons.check_circle_rounded
        : record.isFailed
            ? Icons.error_rounded
            : Icons.hourglass_top_rounded;

    return GestureDetector(
      onTap: record.isCompleted ? () => context.push('/report/${record.id}') : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: AppTheme.cardGradient,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.surfaceBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(statusIcon, color: statusColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    record.email,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (record.createdAt != null)
                    Text(
                      _formatDate(record.createdAt!),
                      style: const TextStyle(
                          color: AppTheme.textMuted, fontSize: 12),
                    ),
                ],
              ),
            ),
            if (record.isCompleted)
              const Icon(
                Icons.chevron_right_rounded,
                color: AppTheme.textMuted,
              ),
          ],
        ),
      ),
    )
        .animate(delay: (50 * index).ms)
        .fadeIn()
        .slideX(begin: 0.1, end: 0);
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      return DateFormat('MMM d, y · h:mm a').format(dt);
    } catch (_) {
      return iso;
    }
  }
}

class _EmptyHistory extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          const Icon(Icons.search_off_rounded, color: AppTheme.textMuted, size: 48),
          const SizedBox(height: 12),
          const Text(
            'No recent searches',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 15),
          ),
          const SizedBox(height: 4),
          const Text(
            'Your investigations will appear here',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
