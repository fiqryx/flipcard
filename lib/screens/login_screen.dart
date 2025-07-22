import 'dart:developer' as dev;
import 'package:flipcard/services/background_service.dart';
import 'package:flipcard/services/user_service.dart';
import 'package:flipcard/stores/user_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:forui/forui.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late UserStore _userStore;
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _obscurePassword = true;

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
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _setupAuthListener() {
    Supabase.instance.client.auth.onAuthStateChange.listen((data) async {
      final event = data.event;
      final session = data.session;

      if (event == AuthChangeEvent.signedIn && session != null) {
        await _userStore.getData();
        if (mounted) {
          setState(() => _isLoading = false);
          Navigator.of(
            context,
          ).pushNamedAndRemoveUntil('/main', (route) => false);
        }
        BackgroundService.startService();
      } else {
        BackgroundService.stopService();
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
            const SizedBox(height: 80),
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
              'Welcome Back',
              style: themeOf.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Sign in to continue your learning journey',
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
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _forgotPassword,
                      child: Text(
                        'Forgot Password?',
                        style: context.theme.typography.sm.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FButton(
                      onPress: () {
                        if (_isLoading) return;
                        if (_formKey.currentState!.validate()) {
                          _login();
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
                          : const Text('Sign In'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            // Divider with "or" text
            Row(
              children: [
                Expanded(child: Divider(color: colors.border)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Or continue with',
                    style: themeOf.textTheme.bodySmall?.copyWith(
                      color: colors.mutedForeground,
                    ),
                  ),
                ),
                Expanded(child: Divider(color: colors.border)),
              ],
            ),
            const SizedBox(height: 24),
            FButton(
              style: FButtonStyle.outline(),
              onPress: _isGoogleLoading ? null : _loginGoogle,
              prefix: SvgPicture.asset(
                'assets/svg/google.svg',
                width: 24,
                height: 24,
              ),
              child: _isGoogleLoading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text('Google'),
            ),
            const SizedBox(height: 16),
            // Sign up prompt
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: 2,
              children: [
                Text(
                  "Don't have an account?",
                  style: context.theme.typography.sm.copyWith(
                    color: colors.mutedForeground,
                  ),
                ),
                TextButton(
                  onPressed: () => {
                    Navigator.of(context).pushNamed('/register'),
                  },
                  child: Text(
                    'Sign Up',
                    style: themeOf.textTheme.bodyMedium?.copyWith(
                      color: colors.primary,
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

  Future<void> _login() async {
    setState(() => _isLoading = true);
    try {
      await UserService.signInWithEmail(
        _emailController.text.trim(),
        _passwordController.text,
      );
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Sign in failed: ${e.toString()}');
    }
  }

  Future<void> _loginGoogle() async {
    try {
      setState(() => _isGoogleLoading = true);
      await Supabase.instance.client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'com.example.flipcard://login-callback/',
        authScreenLaunchMode: LaunchMode.platformDefault,
      );
    } catch (e) {
      _showError('Google sign in failed: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  // ignore: unused_element
  Future<void> _nativeGoogleSignIn() async {
    const webClientId = 'YOUR_WEB_CLIENT_ID.googleusercontent.com';

    final GoogleSignIn googleSignIn = GoogleSignIn(
      serverClientId: webClientId,
      scopes: ['email', 'profile'], // Add explicit scopes
    );

    try {
      // Sign out first to ensure clean state
      await googleSignIn.signOut();

      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        throw 'Google sign in was cancelled';
      }

      final googleAuth = await googleUser.authentication;
      final accessToken = googleAuth.accessToken;
      final idToken = googleAuth.idToken;

      if (accessToken == null) {
        throw 'No Access Token found.';
      }
      if (idToken == null) {
        throw 'No ID Token found.';
      }

      await Supabase.instance.client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );
    } catch (error) {
      _showError(error.toString());
    }
  }

  // ignore: unused_element
  Future<void> _webGoogleSignIn() async {
    await Supabase.instance.client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: 'com.example.flipcard://login-callback',
    );
  }

  Future<void> _forgotPassword() async {
    if (_emailController.text.isEmpty) {
      _showError('Please enter your email first');
      return;
    }

    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(
        _emailController.text.trim(),
        redirectTo: 'com.example.flipcard://reset-password',
      );
      _showSuccess('Password reset link sent to your email');
    } on AuthException catch (error) {
      _showError(error.message);
    } catch (error) {
      _showError('Failed to send reset link');
    }
  }

  void _showError(String message) {
    dev.log(message, name: "LOGIN_ERROR");
    showFToast(
      context: context,
      title: Text(message.replaceAll('Exception: ', '')),
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

  // ignore: unused_element
  void _showComingSoon(String feature) {
    showFToast(
      context: context,
      title: Text('$feature coming soon!'),
      icon: Icon(FIcons.info),
      alignment: FToastAlignment.bottomCenter,
    );
  }
}
