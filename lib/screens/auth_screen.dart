import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// تسجيل الدخول: زائر (الأسرع للتجربة) أو بريد + كلمة مرور
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool busy = false;
  bool isSignUp = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _msg(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _guest() async {
    setState(() => busy = true);
    try {
      await Supabase.instance.client.auth.signInAnonymously();
    } catch (e) {
      _msg('تعذّر الدخول كزائر — فعّل Anonymous من لوحة Supabase');
    }
    if (mounted) setState(() => busy = false);
  }

  Future<void> _submit() async {
    if (_email.text.trim().isEmpty || _password.text.length < 6) {
      _msg('أدخل بريدًا صحيحًا وكلمة مرور من ٦ أحرف على الأقل');
      return;
    }
    setState(() => busy = true);
    try {
      if (isSignUp) {
        await Supabase.instance.client.auth
            .signUp(email: _email.text.trim(), password: _password.text);
        _msg('أهلًا بك! تم إنشاء حسابك');
      } else {
        await Supabase.instance.client.auth.signInWithPassword(
            email: _email.text.trim(), password: _password.text);
      }
    } catch (e) {
      _msg(isSignUp
          ? 'تعذّر إنشاء الحساب — قد يكون البريد مستخدمًا'
          : 'البريد أو كلمة المرور غير صحيحة');
    }
    if (mounted) setState(() => busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 74,
                  height: 74,
                  decoration: BoxDecoration(
                      color: cs.primary,
                      borderRadius: BorderRadius.circular(24)),
                  child: Icon(PhosphorIcons.fill.bookOpenText,
                      color: cs.onPrimary, size: 36),
                ),
                const SizedBox(height: 14),
                Text('طالب',
                    style: tt.headlineMedium
                        ?.copyWith(fontWeight: FontWeight.w700)),
                Text('T Â L I B',
                    style: tt.labelSmall?.copyWith(letterSpacing: 6)),
                const SizedBox(height: 6),
                Text('منصتك الدراسية', style: tt.bodySmall),
                const SizedBox(height: 32),
                FilledButton.icon(
                  onPressed: busy ? null : _guest,
                  icon: Icon(PhosphorIcons.regular.userCircle),
                  label: const Text('المتابعة كزائر'),
                ),
                const SizedBox(height: 24),
                Row(children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text('أو', style: tt.bodySmall),
                  ),
                  const Expanded(child: Divider()),
                ]),
                const SizedBox(height: 24),
                TextField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: 'البريد الإلكتروني',
                    prefixIcon: Icon(PhosphorIcons.regular.envelopeSimple),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _password,
                  obscureText: true,
                  decoration: InputDecoration(
                    hintText: 'كلمة المرور',
                    prefixIcon: Icon(PhosphorIcons.regular.lockKey),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: busy ? null : _submit,
                    child: busy
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : Text(isSignUp ? 'إنشاء حساب' : 'تسجيل الدخول'),
                  ),
                ),
                TextButton(
                  onPressed: () => setState(() => isSignUp = !isSignUp),
                  child: Text(isSignUp
                      ? 'لدي حساب — تسجيل الدخول'
                      : 'ليس لدي حساب — إنشاء حساب جديد'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}