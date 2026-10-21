import 'package:flutter/material.dart';

import '../auth.dart';
import '../theme.dart';

/// شاشة دخول / حساب جديد (email + mot de passe عبر Supabase)
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _signup = false;
  bool _busy = false;
  bool _obscure = true;
  String? _error;
  String? _info;

  @override
  void dispose() {
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _email.text.trim();
    final pass = _pass.text;
    if (email.isEmpty || pass.isEmpty) {
      setState(() => _error = 'عمّر الإيميل وكلمة السرّ.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
      _info = null;
    });
    try {
      if (_signup) {
        final loggedIn = await Auth.signUp(email, pass);
        if (!mounted) return;
        if (loggedIn) {
          Navigator.of(context).pop(true);
        } else {
          setState(() => _info = 'تبعثلك رسالة تأكيد على الإيميل. أكّد وبعد ادخل.');
        }
      } else {
        await Auth.signIn(email, pass);
        if (!mounted) return;
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _google() async {
    setState(() {
      _busy = true;
      _error = null;
      _info = null;
    });
    try {
      final ok = await Auth.signInWithGoogle();
      if (!mounted) return;
      if (ok) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: Text(_signup ? 'حساب جديد' : 'دخول')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            _signup
                ? 'اعمل حساب باش تزامن سكريبتاتك على كل أجهزتك.'
                : 'ادخل لحسابك باش تلقى سكريبتاتك على هالجهاز.',
            style: tt.bodyMedium,
          ),
          const SizedBox(height: 20),
          Directionality(
            textDirection: TextDirection.ltr,
            child: TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              enableSuggestions: false,
              decoration: const InputDecoration(
                labelText: 'الإيميل',
                hintText: 'email@exemple.com',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Directionality(
            textDirection: TextDirection.ltr,
            child: TextField(
              controller: _pass,
              obscureText: _obscure,
              decoration: InputDecoration(
                labelText: 'كلمة السرّ',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          FilledButton(
            onPressed: _busy ? null : _submit,
            child: _busy
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : Text(_signup ? 'اعمل الحساب' : 'ادخل'),
          ),
          const SizedBox(height: 14),
          Row(children: [
            const Expanded(child: Divider()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text('ولا', style: tt.bodySmall),
            ),
            const Expanded(child: Divider()),
          ]),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: _busy ? null : _google,
            icon: const Text('G',
                style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.cyan)),
            label: const Text('دخول بـGoogle'),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Text('⚠️ $_error', style: const TextStyle(color: AppColors.rose)),
            ),
          if (_info != null)
            Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Text('✉️ $_info', style: const TextStyle(color: AppColors.cyan)),
            ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _busy
                ? null
                : () => setState(() {
                      _signup = !_signup;
                      _error = null;
                      _info = null;
                    }),
            child: Text(_signup ? 'عندك حساب؟ ادخل' : 'ماعندكش حساب؟ اعمل واحد'),
          ),
        ],
      ),
    );
  }
}
