import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../shared/widgets/eco_logo_header.dart';
import '../../../../shared/widgets/eco_primary_button.dart';
import '../../../../shared/widgets/eco_secondary_button.dart';
import '../../../../shared/widgets/eco_text_field.dart';
import '../providers/login_controller.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(loginControllerProvider.notifier).signIn(
          emailOrUsername: _emailController.text,
          password: _passwordController.text,
        );
  }

  Future<void> _showForgotPasswordDialog() async {
    final emailController = TextEditingController(text: _emailController.text);
    final formKey = GlobalKey<FormState>();

    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
          title: const Text('Reset Password'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Enter your email address and we will send you a link to reset your password.',
                ),
                const SizedBox(height: 16),
                EcoTextField(
                  controller: emailController,
                  label: 'EMAIL',
                  hint: 'curator@ecotrade.com',
                  prefixIcon: Icons.alternate_email_rounded,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Email is required';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final email = emailController.text;
                  Navigator.pop(context);
                  await ref.read(loginControllerProvider.notifier).resetPassword(email);
                  if (mounted && ref.read(loginControllerProvider).hasError == false) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('If the email is registered, a password reset link has been sent.'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                }
              },
              child: const Text('Send Link'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(loginControllerProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // Show error snackbar on failure
    ref.listen<AsyncValue<void>>(loginControllerProvider, (_, next) {
      if (next is AsyncError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error.toString()),
            backgroundColor: colorScheme.error,
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      body: SafeArea(
        child: Stack(
          children: [
            // ── Scrollable main content ──
            SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 48),

                    // ── Header ──
                    const EcoLogoHeader(
                      subtitle:
                          'Please enter your credentials to access the marketplace.',
                    ),

                    const SizedBox(height: 40),

                    // ── Email / Username field ──
                    EcoTextField(
                      controller: _emailController,
                      label: 'EMAIL ATAU USERNAME',
                      hint: 'email@example.com atau username',
                      prefixIcon: Icons.alternate_email_rounded,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Email atau username harus diisi';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 28),

                    // ── Password field ──
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'PASSWORD',
                              style: textTheme.labelSmall?.copyWith(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.1,
                              ),
                            ),
                            GestureDetector(
                              onTap: _showForgotPasswordDialog,
                              child: Text(
                                'FORGOT?',
                                style: textTheme.labelSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.0,
                                  color: colorScheme.onSurface.withOpacity(0.7),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _submit(),
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return 'Password is required';
                            }
                            return null;
                          },
                          decoration: InputDecoration(
                            hintText: '••••••••',
                            hintStyle: textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurface.withOpacity(0.4),
                            ),
                            prefixIcon: Icon(
                              Icons.lock_outline_rounded,
                              size: 20,
                              color: colorScheme.onSurface.withOpacity(0.6),
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.remove_red_eye_outlined
                                    : Icons.visibility_off_outlined,
                                size: 20,
                                color: colorScheme.onSurface.withOpacity(0.6),
                              ),
                              onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword),
                            ),
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(
                                color: colorScheme.outline.withOpacity(0.5),
                                width: 1.5,
                              ),
                            ),
                            focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(
                                  color: colorScheme.primary, width: 2),
                            ),
                            errorBorder: UnderlineInputBorder(
                              borderSide: BorderSide(
                                  color: colorScheme.error, width: 1.5),
                            ),
                            focusedErrorBorder: UnderlineInputBorder(
                              borderSide: BorderSide(
                                  color: colorScheme.error, width: 2),
                            ),
                            isDense: true,
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 40),

                    // ── Sign In button ──
                    EcoPrimaryButton(
                      label: 'Sign In',
                      isLoading: state.isLoading,
                      onPressed: _submit,
                    ),

                    const SizedBox(height: 28),

                    // ── Divider ──
                    Row(
                      children: [
                        Expanded(
                          child: Divider(
                            color: colorScheme.outline.withOpacity(0.4),
                          ),
                        ),
                        Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 14),
                          child: Text(
                            'OR CONTINUE WITH',
                            style: textTheme.labelSmall?.copyWith(
                              color:
                                  colorScheme.onSurface.withOpacity(0.5),
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Divider(
                            color: colorScheme.outline.withOpacity(0.4),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // ── Create Account button ──
                    EcoSecondaryButton(
                      label: 'Create Account',
                      onPressed: () => context.go(AppRoutes.register),
                      icon: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.add,
                            color: colorScheme.onPrimary, size: 18),
                      ),
                    ),

                    const SizedBox(height: 40),

                    // ── Footer ──
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withOpacity(0.55),
                          height: 1.6,
                        ),
                        children: [
                          const TextSpan(
                              text: "By continuing, you agree to EcoTrade's\n"),
                          TextSpan(
                            text: 'Terms of Service',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              decoration: TextDecoration.underline,
                              color: colorScheme.onSurface,
                            ),
                            recognizer: TapGestureRecognizer()..onTap = () {},
                          ),
                          const TextSpan(text: ' and '),
                          TextSpan(
                            text: 'Privacy Policy',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              decoration: TextDecoration.underline,
                              color: colorScheme.onSurface,
                            ),
                            recognizer: TapGestureRecognizer()..onTap = () {},
                          ),
                          const TextSpan(text: '.'),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),

            // ── Floating help button ──
            Positioned(
              bottom: 20,
              right: 20,
              child: GestureDetector(
                onTap: () {},
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: colorScheme.onSurface.withOpacity(0.75),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.question_mark_rounded,
                      color: colorScheme.surface, size: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
