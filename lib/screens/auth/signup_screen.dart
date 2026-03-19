import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/styled_button.dart';
import 'auth_screen_scaffold.dart';
import 'login_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final auth = context.read<AuthProvider>();
    final success = await auth.signUp(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
      displayName: _nameController.text.trim(),
    );
    if (!mounted) {
      return;
    }
    if (success) {
      Navigator.of(context).popUntil((route) => route.isFirst);
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
                title: l10n.t('auth_signup_title'),
                subtitle: l10n.t('auth_signup_subtitle'),
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
                          controller: _nameController,
                          textCapitalization: TextCapitalization.words,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.name],
                          decoration:
                              InputDecoration(labelText: l10n.t('form_name')),
                          validator: (value) =>
                              (value == null || value.trim().isEmpty)
                                  ? l10n.t('auth_validation_name')
                                  : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.email],
                          decoration:
                              InputDecoration(labelText: l10n.t('form_email')),
                          validator: (value) =>
                              (value == null || !value.contains('@'))
                                  ? l10n.t('auth_validation_email')
                                  : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: true,
                          textInputAction: TextInputAction.done,
                          autofillHints: const [AutofillHints.newPassword],
                          onFieldSubmitted: (_) {
                            if (!auth.isSubmitting) {
                              _submit();
                            }
                          },
                          decoration: InputDecoration(
                            labelText: l10n.t('auth_password_label'),
                          ),
                          validator: (value) =>
                              (value == null || value.length < 6)
                                  ? l10n.t('auth_validation_password')
                                  : null,
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
                              ? l10n.t('auth_button_creating')
                              : l10n.t('auth_button_signup'),
                          onPressed: auth.isSubmitting ? null : _submit,
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
                              builder: (_) => const LoginScreen(),
                            ),
                          );
                        },
                  child: Text(l10n.t('auth_switch_to_login')),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
