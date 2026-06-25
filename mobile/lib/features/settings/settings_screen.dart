import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/api/api_client.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _apiUrlCtrl = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _apiUrlCtrl.text = ApiClient.instance.dio.options.baseUrl;
  }

  @override
  void dispose() {
    _apiUrlCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveApiUrl() async {
    final url = _apiUrlCtrl.text.trim();
    if (url.isEmpty) return;

    setState(() => _isSaving = true);
    ApiClient.setBaseUrl(url);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('api_base_url', url);

    setState(() => _isSaving = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('API URL saved')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        leading: IconButton(
          onPressed: () => context.go('/'),
          icon: const Icon(Icons.arrow_back_ios_rounded),
        ),
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Account section
          _SectionHeader('Account'),
          const SizedBox(height: 10),
          _SettingsCard(
            children: [
              if (auth.isAuthenticated) ...[
                _SettingsRow(
                  icon: Icons.person_rounded,
                  label: 'Signed in as',
                  value: auth.userEmail ?? '',
                  trailing: const SizedBox.shrink(),
                ),
                const Divider(color: AppTheme.surfaceBorder, height: 1),
                _SettingsTile(
                  icon: Icons.logout_rounded,
                  label: 'Sign Out',
                  color: AppTheme.error,
                  onTap: () async {
                    await ref.read(authProvider.notifier).logout();
                    if (mounted) context.go('/');
                  },
                ),
              ] else ...[
                _SettingsTile(
                  icon: Icons.login_rounded,
                  label: 'Sign In',
                  color: AppTheme.accent,
                  onTap: () => context.push('/login'),
                ),
                const Divider(color: AppTheme.surfaceBorder, height: 1),
                _SettingsTile(
                  icon: Icons.person_add_rounded,
                  label: 'Create Account',
                  color: AppTheme.textSecondary,
                  onTap: () => context.push('/register'),
                ),
              ],
            ],
          ).animate().fadeIn().slideY(begin: 0.1, end: 0),

          const SizedBox(height: 24),

          // Server config
          _SectionHeader('Server Configuration'),
          const SizedBox(height: 10),
          _SettingsCard(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'API Base URL',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _apiUrlCtrl,
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 13,
                              fontFamily: 'monospace',
                            ),
                            decoration: const InputDecoration(
                              hintText: 'http://10.0.2.2:8000',
                              contentPadding:
                                  EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          onPressed: _isSaving ? null : _saveApiUrl,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                          ),
                          child: _isSaving
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.black),
                                )
                              : const Text('Save'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'For emulators: use http://10.0.2.2:8000\nFor real device: use your PC\'s local IP (e.g. http://192.168.1.x:8000)',
                      style: TextStyle(color: AppTheme.textMuted, fontSize: 11, height: 1.5),
                    ),
                  ],
                ),
              ),
            ],
          ).animate(delay: 100.ms).fadeIn().slideY(begin: 0.1, end: 0),

          const SizedBox(height: 24),

          // About section
          _SectionHeader('About'),
          const SizedBox(height: 10),
          _SettingsCard(
            children: [
              _SettingsRow(
                icon: Icons.info_outline_rounded,
                label: 'Version',
                value: '1.0.0',
              ),
              const Divider(color: AppTheme.surfaceBorder, height: 1),
              _SettingsTile(
                icon: Icons.gavel_rounded,
                label: 'Responsible Use Policy',
                color: AppTheme.textSecondary,
                onTap: () => _showPolicy(context),
              ),
              const Divider(color: AppTheme.surfaceBorder, height: 1),
              _SettingsTile(
                icon: Icons.restart_alt_rounded,
                label: 'Re-run Onboarding',
                color: AppTheme.textSecondary,
                onTap: () async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.remove('onboarding_done');
                  if (context.mounted) context.go('/onboarding');
                },
              ),
            ],
          ).animate(delay: 200.ms).fadeIn().slideY(begin: 0.1, end: 0),

          const SizedBox(height: 40),

          // Disclaimer
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.warning.withOpacity(0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.warning.withOpacity(0.3)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: AppTheme.warning, size: 16),
                    SizedBox(width: 6),
                    Text(
                      'Responsible Use Reminder',
                      style: TextStyle(
                          color: AppTheme.warning,
                          fontSize: 13,
                          fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  'This tool is for legitimate security research, journalism, and privacy awareness only. '
                  'Always comply with applicable laws. Do not use for harassment or stalking.',
                  style: TextStyle(
                      color: AppTheme.textSecondary, fontSize: 12, height: 1.5),
                ),
              ],
            ),
          ).animate(delay: 300.ms).fadeIn(),
        ],
      ),
    );
  }

  void _showPolicy(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: const [
            Text(
              'Responsible Use Policy',
              style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 16),
            Text(
              '• This tool aggregates publicly available information only.\n'
              '• Use for security research, journalism, and privacy purposes.\n'
              '• Do not use to stalk, harass, or harm individuals.\n'
              '• Comply with all local and international privacy laws.\n'
              '• Respect the privacy of individuals.\n'
              '• The developers are not liable for misuse.',
              style: TextStyle(
                  color: AppTheme.textSecondary, fontSize: 14, height: 1.8),
            ),
            SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// ── Reusable widgets ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) => Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: AppTheme.textMuted,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      );
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          gradient: AppTheme.cardGradient,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.surfaceBorder),
        ),
        child: Column(children: children),
      );
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 14),
              Text(
                label,
                style: TextStyle(color: color, fontSize: 15, fontWeight: FontWeight.w500),
              ),
              const Spacer(),
              Icon(Icons.chevron_right_rounded, color: color.withOpacity(0.5), size: 18),
            ],
          ),
        ),
      );
}

class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Widget? trailing;

  const _SettingsRow({
    required this.icon,
    required this.label,
    required this.value,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.textSecondary, size: 20),
            const SizedBox(width: 14),
            Text(
              label,
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 15),
            ),
            const Spacer(),
            trailing ??
                Text(
                  value,
                  style: const TextStyle(
                      color: AppTheme.textMuted, fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
          ],
        ),
      );
}
