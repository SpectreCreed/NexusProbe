import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscurePass = true;
  bool _success = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await ref
        .read(authProvider.notifier)
        .register(_emailCtrl.text.trim(), _passCtrl.text);
    if (ok && mounted) setState(() => _success = true);
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
          child: _success ? _buildSuccess() : _buildForm(auth),
        ),
      ),
    );
  }

  Widget _buildSuccess() => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 80),
          const Icon(Icons.check_circle_rounded, color: AppTheme.success, size: 80)
              .animate()
              .scale(curve: Curves.elasticOut),
          const SizedBox(height: 24),
          const Text(
            'Account Created!',
            style: TextStyle(
                color: AppTheme.textPrimary, fontSize: 28, fontWeight: FontWeight.w800),
          ).animate(delay: 200.ms).fadeIn(),
          const SizedBox(height: 8),
          const Text(
            'Check your email to confirm your account.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 15),
          ).animate(delay: 300.ms).fadeIn(),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: () => context.go('/login'),
            child: const Text('Go to Login'),
          ).animate(delay: 400.ms).fadeIn(),
        ],
      );

  Widget _buildForm(AuthState auth) => Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IconButton(
              onPressed: () => context.pop(),
              icon: const Icon(Icons.arrow_back_ios_rounded, color: AppTheme.textSecondary),
              padding: EdgeInsets.zero,
            ),
            const SizedBox(height: 32),
            const Text(
              'Create Account',
              style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5),
            ).animate().fadeIn(),
            const SizedBox(height: 8),
            const Text(
              'Start your OSINT investigations',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 15),
            ).animate(delay: 100.ms).fadeIn(),
            const SizedBox(height: 40),
            if (auth.error != null)
              Container(
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.error.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.error.withOpacity(0.4)),
                ),
                child: Text(auth.error!,
                    style: const TextStyle(color: AppTheme.error, fontSize: 13)),
              ).animate().shake(),
            _label('Email'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: const InputDecoration(
                hintText: 'you@example.com',
                prefixIcon: Icon(Icons.email_outlined, color: AppTheme.textMuted),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Email is required';
                if (!v.contains('@')) return 'Enter a valid email';
                return null;
              },
            ).animate(delay: 150.ms).fadeIn().slideY(begin: 0.2, end: 0),
            const SizedBox(height: 20),
            _label('Password'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _passCtrl,
              obscureText: _obscurePass,
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: InputDecoration(
                hintText: 'Min. 8 characters',
                prefixIcon: const Icon(Icons.lock_outline, color: AppTheme.textMuted),
                suffixIcon: IconButton(
                  onPressed: () => setState(() => _obscurePass = !_obscurePass),
                  icon: Icon(
                    _obscurePass ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: AppTheme.textMuted,
                  ),
                ),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Password is required';
                if (v.length < 8) return 'Password must be at least 8 characters';
                return null;
              },
            ).animate(delay: 200.ms).fadeIn().slideY(begin: 0.2, end: 0),
            const SizedBox(height: 20),
            _label('Confirm Password'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _confirmCtrl,
              obscureText: true,
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: const InputDecoration(
                hintText: 'Repeat password',
                prefixIcon: Icon(Icons.lock_outline, color: AppTheme.textMuted),
              ),
              validator: (v) {
                if (v != _passCtrl.text) return 'Passwords do not match';
                return null;
              },
            ).animate(delay: 250.ms).fadeIn().slideY(begin: 0.2, end: 0),
            const SizedBox(height: 36),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: auth.isLoading ? null : _register,
                child: auth.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                      )
                    : const Text('Create Account'),
              ),
            ).animate(delay: 300.ms).fadeIn(),
            const SizedBox(height: 24),
            Center(
              child: TextButton(
                onPressed: () => context.go('/login'),
                child: RichText(
                  text: const TextSpan(
                    text: 'Already have an account? ',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                    children: [
                      TextSpan(
                        text: 'Sign in',
                        style: TextStyle(
                            color: AppTheme.accent, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
            ).animate(delay: 350.ms).fadeIn(),
          ],
        ),
      );

  Widget _label(String text) => Text(
        text,
        style: const TextStyle(
            color: AppTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w500),
      );
}
