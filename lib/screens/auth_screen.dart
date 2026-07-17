import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../services/auth_service.dart';
import 'welcome_pejuang.dart';

/// Simple email/password sign-in gate. Skip = local-only.
/// Renders only after Supabase is initialized (called from splash).
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;
  String? _error;
  bool _signUp = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() { _loading = true; _error = null; });
    final err = _signUp
        ? await AuthService.signUp(_emailCtrl.text.trim(), _passCtrl.text)
        : await AuthService.signIn(_emailCtrl.text.trim(), _passCtrl.text);
    if (!mounted) return;
    if (err != null) {
      setState(() { _loading = false; _error = err; });
    } else {
      // Signed in — session is disk-backed, next app start auto-restores.
      Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (_) => const WelcomePejuangScreen(),
      ));
    }
  }

  void _skip() {
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (_) => const WelcomePejuangScreen(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: AmbientBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: [
                const SizedBox(height: AppSpacing.xl),
                Text('LEVEL UP IMAN', style: AppText.displayHero(28).copyWith(color: AppColors.primary)),
                const SizedBox(height: 8),
                Text('Simpan progress akunmu',
                    style: AppText.bodyMd().copyWith(color: AppColors.onSurfaceVariant)),
                const SizedBox(height: AppSpacing.xl),
                TextField(
                  controller: _emailCtrl,
                  style: AppText.bodyLg(),
                  decoration: InputDecoration(
                    labelText: 'Email',
                    hintText: 'email@contoh.com',
                    labelStyle: AppText.bodyMd().copyWith(color: AppColors.onSurfaceVariant),
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.outlineVariant)),
                    focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.primary)),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: _passCtrl,
                  style: AppText.bodyLg(),
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    labelStyle: AppText.bodyMd().copyWith(color: AppColors.onSurfaceVariant),
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.outlineVariant)),
                    focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.primary)),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(_error!, style: AppText.bodySm().copyWith(color: AppColors.error)),
                ],
                const SizedBox(height: AppSpacing.lg),
                SizedBox(
                  width: double.infinity,
                  child: HeroButton(
                    label: _signUp ? 'DAFTAR' : 'MASUK',
                    onPressed: _loading ? null : _submit,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextButton(
                  onPressed: () => setState(() { _signUp = !_signUp; _error = null; }),
                  child: Text(
                    _signUp ? 'Sudah punya akun? Masuk' : 'Belum punya akun? Daftar',
                    style: AppText.bodyMd().copyWith(color: AppColors.primary),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                TextButton(
                  onPressed: _skip,
                  child: Text('Lewati — pakai lokal saja',
                      style: AppText.bodySm().copyWith(color: AppColors.onSurfaceVariant)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
