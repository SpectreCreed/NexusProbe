import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/osint_results.dart';
import '../../../core/models/account_entry.dart';

class SocialTab extends StatelessWidget {
  final OsintResults results;
  const SocialTab({super.key, required this.results});

  @override
  Widget build(BuildContext context) {
    final found = results.foundAccounts;
    final allAccounts = results.accounts;
    final notFound = allAccounts.where((a) => !a.exists).toList();

    if (allAccounts.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.people_outline_rounded, color: AppTheme.textMuted, size: 64),
              SizedBox(height: 16),
              Text(
                'No accounts checked',
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
        // Summary header
        _SummaryBanner(found: found.length, total: allAccounts.length),
        const SizedBox(height: 20),

        // Category filter chips
        if (found.isNotEmpty) ...[
          const _SectionHeader('Found Accounts', AppTheme.success),
          const SizedBox(height: 10),
          ...found.map((a) => _AccountCard(account: a, found: true)),
          const SizedBox(height: 24),
        ],

        if (notFound.isNotEmpty) ...[
          _SectionHeader('Not Registered (${notFound.length})', AppTheme.textMuted),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: notFound
                .map(
                  (a) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceHigh,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.surfaceBorder),
                    ),
                    child: Text(
                      a.service,
                      style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ],
    );
  }
}

class _SummaryBanner extends StatelessWidget {
  final int found;
  final int total;
  const _SummaryBanner({required this.found, required this.total});

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? (found / total * 100).round() : 0;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.warning.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.warning.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.people_rounded, color: AppTheme.warning, size: 32),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$found of $total platforms',
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '$pct% social footprint detected',
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final Color color;
  const _SectionHeader(this.title, this.color);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        color: color,
        fontSize: 13,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
      ),
    );
  }
}

class _AccountCard extends StatelessWidget {
  final AccountEntry account;
  final bool found;
  const _AccountCard({required this.account, required this.found});

  @override
  Widget build(BuildContext context) {
    final color = found ? AppTheme.success : AppTheme.textMuted;
    final categoryColor = _categoryColor(account.category);

    return GestureDetector(
      onTap: account.url != null
          ? () => launchUrl(Uri.parse(account.url!), mode: LaunchMode.externalApplication)
          : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: AppTheme.cardGradient,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: found ? AppTheme.success.withOpacity(0.3) : AppTheme.surfaceBorder,
          ),
        ),
        child: Row(
          children: [
            // Service icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: categoryColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Icon(
                  _iconForService(account.service),
                  color: categoryColor,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    account.service,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 3),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: categoryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          account.category,
                          style: TextStyle(
                              color: categoryColor, fontSize: 10, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (found && account.url != null)
              const Icon(Icons.open_in_new_rounded, color: AppTheme.accent, size: 16)
            else if (found)
              const Icon(Icons.check_circle_rounded, color: AppTheme.success, size: 18),
          ],
        ),
      ),
    );
  }

  Color _categoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'social':
        return AppTheme.accent;
      case 'email':
        return AppTheme.warning;
      case 'dating':
        return const Color(0xFFEC4899);
      case 'finance':
        return AppTheme.success;
      case 'gaming':
        return const Color(0xFF8B5CF6);
      case 'coding':
      case 'developer':
        return const Color(0xFF06B6D4);
      default:
        return AppTheme.textSecondary;
    }
  }

  IconData _iconForService(String service) {
    final s = service.toLowerCase();
    if (s.contains('twitter') || s.contains('x.com')) return Icons.close;
    if (s.contains('github')) return Icons.code;
    if (s.contains('instagram')) return Icons.camera_alt_rounded;
    if (s.contains('facebook')) return Icons.facebook_rounded;
    if (s.contains('linkedin')) return Icons.business_center_rounded;
    if (s.contains('reddit')) return Icons.forum_rounded;
    if (s.contains('youtube')) return Icons.play_circle_rounded;
    if (s.contains('telegram')) return Icons.send_rounded;
    if (s.contains('discord')) return Icons.headset_mic_rounded;
    if (s.contains('spotify')) return Icons.music_note_rounded;
    if (s.contains('tiktok')) return Icons.music_video_rounded;
    if (s.contains('snapchat')) return Icons.camera_rounded;
    if (s.contains('pinterest')) return Icons.push_pin_rounded;
    if (s.contains('twitch')) return Icons.live_tv_rounded;
    if (s.contains('google')) return Icons.g_mobiledata_rounded;
    if (s.contains('apple')) return Icons.apple_rounded;
    if (s.contains('amazon')) return Icons.shopping_bag_rounded;
    if (s.contains('microsoft')) return Icons.window_rounded;
    if (s.contains('paypal')) return Icons.payment_rounded;
    if (s.contains('email') || s.contains('mail')) return Icons.email_rounded;
    if (s.contains('dating') || s.contains('tinder')) return Icons.favorite_rounded;
    if (s.contains('game') || s.contains('steam')) return Icons.sports_esports_rounded;
    return Icons.language_rounded;
  }
}
