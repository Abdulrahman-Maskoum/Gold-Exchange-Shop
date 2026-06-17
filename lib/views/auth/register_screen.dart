import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../controllers/auth_controller.dart';
import '../../services/auth_service.dart';
import '../widgets/alert_dialog.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _shopName = TextEditingController();
  final _shopAddress = TextEditingController();
  bool _loading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _username.dispose();
    _email.dispose();
    _password.dispose();
    _shopName.dispose();
    _shopAddress.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!mounted) return;
    setState(() => _loading = true);

    final auth = context.read<AuthController>();

    try {
      await auth.register(
        username: _username.text,
        email: _email.text,
        password: _password.text,
        shopName: _shopName.text,
        shopAddress: _shopAddress.text,
      );

      bool emailSent = false;
      try {
        await auth.sendVerificationEmail();
        emailSent = true;
      } catch (_) {
        emailSent = false;
      }

      await auth.signOut();

      if (mounted) {
        if (emailSent) {
          _alert(
              'Registration successful! Verification email sent. Please verify and login.');
        } else {
          _alert(
              'Registration successful! However, verification email could not be sent. Please try logging in and request a new verification email.');
        }
        context.go('/login');
      }
    } on UsernameTakenException {
      if (mounted) {
        _alert('Username already taken. Please choose a different username.');
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        _alert('Registration failed: ${e.message ?? e.code}');
      }
    } catch (e) {
      if (mounted) {
        _alert('Registration failed: ${e.toString()}');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _alert(String msg) {
    if (!mounted) return;
    final msgLower = msg.toLowerCase();
    final type = msgLower.contains('successful')
        ? AlertType.success
        : msgLower.contains('failed') ||
                msgLower.contains('incorrect') ||
                msgLower.contains('taken') ||
                msgLower.contains('error')
            ? AlertType.error
            : AlertType.info;
    
    showAlertDialog(
      context: context,
      message: msg,
      type: type,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              primaryColor.withOpacity(0.05),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: MediaQuery.of(context).size.width < 600 ? 16 : 24,
                vertical: 24,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width > 1200 ? 600 : 520,
                ),
                child: Column(
                  children: [
                    // Icon Section
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: primaryColor,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.person_add_rounded,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                    const SizedBox(height: 24),

                    Text(
                      'Create Your Account',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Fill in your details to get started',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Form Card
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Username
                              TextFormField(
                                controller: _username,
                                decoration: InputDecoration(
                                  labelText: 'Username',
                                  prefixIcon: Icon(Icons.person_outline_rounded,
                                      color: primaryColor),
                                  filled: true,
                                  fillColor: Colors.grey.shade50,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide:
                                        BorderSide(color: Colors.grey.shade200),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                        color: primaryColor, width: 2),
                                  ),
                                ),
                                validator: (v) =>
                                    (v == null || v.trim().isEmpty)
                                        ? 'Required'
                                        : null,
                              ),
                              const SizedBox(height: 16),

                              // Email
                              TextFormField(
                                controller: _email,
                                keyboardType: TextInputType.emailAddress,
                                decoration: InputDecoration(
                                  labelText: 'Email',
                                  prefixIcon: Icon(Icons.email_outlined,
                                      color: primaryColor),
                                  filled: true,
                                  fillColor: Colors.grey.shade50,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide:
                                        BorderSide(color: Colors.grey.shade200),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                        color: primaryColor, width: 2),
                                  ),
                                ),
                                validator: (v) =>
                                    (v == null || !v.contains('@'))
                                        ? 'Valid email required'
                                        : null,
                              ),
                              const SizedBox(height: 16),

                              // Password
                              TextFormField(
                                controller: _password,
                                obscureText: _obscurePassword,
                                decoration: InputDecoration(
                                  labelText: 'Password',
                                  prefixIcon: Icon(Icons.lock_outline_rounded,
                                      color: primaryColor),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                      color: Colors.grey,
                                    ),
                                    onPressed: () => setState(() =>
                                        _obscurePassword = !_obscurePassword),
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey.shade50,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide:
                                        BorderSide(color: Colors.grey.shade200),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                        color: primaryColor, width: 2),
                                  ),
                                ),
                                validator: (v) => (v == null || v.length < 6)
                                    ? 'Min 6 characters'
                                    : null,
                              ),
                              const SizedBox(height: 16),

                              // Shop Name
                              TextFormField(
                                controller: _shopName,
                                decoration: InputDecoration(
                                  labelText: 'Shop Name',
                                  prefixIcon: Icon(Icons.store_outlined,
                                      color: primaryColor),
                                  filled: true,
                                  fillColor: Colors.grey.shade50,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide:
                                        BorderSide(color: Colors.grey.shade200),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                        color: primaryColor, width: 2),
                                  ),
                                ),
                                validator: (v) =>
                                    (v == null || v.trim().isEmpty)
                                        ? 'Required'
                                        : null,
                              ),
                              const SizedBox(height: 16),

                              // Shop Address
                              TextFormField(
                                controller: _shopAddress,
                                decoration: InputDecoration(
                                  labelText: 'Shop Address',
                                  prefixIcon: Icon(Icons.location_on_outlined,
                                      color: primaryColor),
                                  filled: true,
                                  fillColor: Colors.grey.shade50,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide:
                                        BorderSide(color: Colors.grey.shade200),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                        color: primaryColor, width: 2),
                                  ),
                                ),
                                validator: (v) =>
                                    (v == null || v.trim().isEmpty)
                                        ? 'Required'
                                        : null,
                              ),
                              const SizedBox(height: 24),

                              // Register Button
                              FilledButton(
                                onPressed: _loading ? null : _submit,
                                style: FilledButton.styleFrom(
                                  backgroundColor: primaryColor,
                                  foregroundColor: Colors.white,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 2,
                                ),
                                child: _loading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                  Colors.white),
                                        ),
                                      )
                                    : const Text(
                                        'Create Account',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Login Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '?Already have an account ',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        TextButton(
                          onPressed: () => context.go('/login'),
                          child: Text(
                            'Sign In',
                            style: TextStyle(
                              color: primaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
