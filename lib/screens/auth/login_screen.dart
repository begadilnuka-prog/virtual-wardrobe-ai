import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../services/auth_service.dart';
import '../../services/user_service.dart';
import '../../widgets/styled_button.dart';
import 'auth_screen_scaffold.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final auth = context.read<AuthProvider>();
    final success = await auth.login(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  Future<void> _signInWithGoogle() async {
    try {
      final authService = AuthService();
      final userService = UserService();

      final userCredential = await authService.signInWithGoogle();

      if (!mounted) return;

      if (userCredential != null && userCredential.user != null) {
        await userService.saveUser(userCredential.user!);

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Welcome ${userCredential.user?.displayName ?? ""}',
            ),
          ),
        );

        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Google Sign-In error: $e'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        return AuthScreenScaffold(
          appBar: AppBar(),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AuthHeaderCard(
                eyebrow: 'I Closet',
                title: l10n.t('auth_login_title'),
                subtitle: auth.firebaseEnabled
                    ? l10n.t('auth_login_subtitle_remote')
                    : l10n.t('auth_login_subtitle_local'),
              ),
              const SizedBox(height: 18),
              Card(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
                  child: Form(
                    key: _formKey,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.email],
                          decoration: InputDecoration(
                            labelText: l10n.t('form_email'),
                          ),
                          validator: (value) {
                            if (value == null || !value.contains('@')) {
                              return l10n.t('auth_validation_email');
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: true,
                          textInputAction: TextInputAction.done,
                          autofillHints: const [AutofillHints.password],
                          onFieldSubmitted: (_) {
                            if (!auth.isSubmitting) {
                              _submit();
                            }
                          },
                          decoration: InputDecoration(
                            labelText: l10n.t('auth_password_label'),
                          ),
                          validator: (value) {
                            if (value == null || value.length < 6) {
                              return l10n.t('auth_validation_password');
                            }
                            return null;
                          },
                        ),
                        if (auth.errorMessage != null) ...[
                          const SizedBox(height: 14),
                          Text(
                            l10n.t(auth.errorMessage!),
                            style: const TextStyle(color: Colors.redAccent),
                          ),
                        ],
                        const SizedBox(height: 22),
                        StyledButton(
                          label: auth.isSubmitting
                              ? l10n.t('auth_button_signing_in')
                              : l10n.t('auth_button_login'),
                          onPressed: auth.isSubmitting ? null : _submit,
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed:
                              auth.isSubmitting ? null : _signInWithGoogle,
                          child: const Text('Sign in with Google'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: TextButton(
                  onPressed: auth.isSubmitting
                      ? null
                      : () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const SignUpScreen(),
                            ),
                          );
                        },
                  child: Text(l10n.t('auth_switch_to_signup')),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
