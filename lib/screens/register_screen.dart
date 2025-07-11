import 'dart:developer' as dev;
import 'package:flipcard/services/user_service.dart';
import 'package:flipcard/stores/user_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:forui/forui.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  late UserStore _userStore;
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    _setupAuthListener();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _userStore = Provider.of<UserStore>(context);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _setupAuthListener() {
    Supabase.instance.client.auth.onAuthStateChange.listen((data) async {
      final event = data.event;
      final session = data.session;

      if (mounted && event == AuthChangeEvent.signedIn && session != null) {
        await _userStore.getData();
        if (mounted) {
          Navigator.of(context).pushReplacementNamed("/main");
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final colors = theme.colors;
    final themeOf = Theme.of(context);

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 60),
            // Logo and title
            Hero(
              tag: 'app-logo',
              child: SvgPicture.asset(
                'assets/svg/icon_logo.svg',
                width: 80,
                height: 80,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Create Account',
              style: themeOf.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start your flashcard learning journey',
              style: themeOf.textTheme.bodyMedium?.copyWith(
                color: colors.mutedForeground,
              ),
            ),
            const SizedBox(height: 40),

            // Form
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Full Name',
                      prefixIcon: Icon(
                        FIcons.user,
                        color: colors.mutedForeground,
                      ),
                    ),
                    keyboardType: TextInputType.name,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your full name';
                      }
                      if (value.trim().length < 2) {
                        return 'Name must be at least 2 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(
                        FIcons.mail,
                        color: colors.mutedForeground,
                      ),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!value.contains('@')) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: Icon(
                        FIcons.lockKeyhole,
                        color: colors.mutedForeground,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_rounded
                              : Icons.visibility_rounded,
                          color: colors.mutedForeground,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                    obscureText: _obscurePassword,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _confirmPasswordController,
                    decoration: InputDecoration(
                      labelText: 'Confirm Password',
                      prefixIcon: Icon(
                        FIcons.lockKeyhole,
                        color: colors.mutedForeground,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword
                              ? Icons.visibility_off_rounded
                              : Icons.visibility_rounded,
                          color: colors.mutedForeground,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
                          });
                        },
                      ),
                    ),
                    obscureText: _obscureConfirmPassword,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please confirm your password';
                      }
                      if (value != _passwordController.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FButton(
                      onPress: () {
                        if (_isLoading) return;
                        if (_formKey.currentState!.validate()) {
                          _register();
                        }
                      },
                      child: _isLoading
                          ? SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                color: colors.background,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text('Create Account'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            // Terms and conditions
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'By creating an account, you agree to our Terms of Service and Privacy Policy',
                style: themeOf.textTheme.bodySmall?.copyWith(
                  color: colors.mutedForeground,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 32),
            // Sign in prompt
            Row(
              spacing: 2,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Already have an account?",
                  style: context.theme.typography.sm.copyWith(
                    color: colors.mutedForeground,
                  ),
                ),
                TextButton(
                  onPressed: () => {
                    Navigator.of(context).pushReplacementNamed('/login'),
                  },
                  child: Text(
                    'Sign In',
                    style: themeOf.textTheme.bodyMedium?.copyWith(
                      color: colors.foreground,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _register() async {
    setState(() => _isLoading = true);
    try {
      await UserService.signUpWithEmail(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (mounted) {
        _showSuccess(
          'Account created successfully! Please check your email to verify your account.',
        );
      }

      _resetForm();
    } catch (e) {
      if (mounted) {
        _showError('Sign up failed: ${e.toString()}');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _nameController.clear();
    _emailController.clear();
    _passwordController.clear();
    _confirmPasswordController.clear();
  }

  void _showError(String message) {
    dev.log(message, name: "REGISTER_ERROR");
    showFToast(
      context: context,
      title: Text(message),
      icon: Icon(FIcons.circleX),
      alignment: FToastAlignment.bottomCenter,
    );
  }

  void _showSuccess(String message) {
    showFToast(
      context: context,
      title: Text(message),
      icon: Icon(FIcons.circleCheck),
      alignment: FToastAlignment.bottomCenter,
    );
  }
}
