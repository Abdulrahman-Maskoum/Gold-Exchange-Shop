import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../controllers/auth_controller.dart';
import '../widgets/alert_dialog.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _shopName = TextEditingController();
  final _shopAddress = TextEditingController();
  bool _init = false;
  bool _loading = false;

  @override
  void dispose() {
    _shopName.dispose();
    _shopAddress.dispose();
    super.dispose();
  }

  void _ensureInit(AuthController auth) {
    if (_init) return;
    final p = auth.profile;
    if (p != null) {
      _shopName.text = p.shopName;
      _shopAddress.text = p.shopAddress;
    }
    _init = true;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final auth = context.read<AuthController>();
    try {
      await auth.updateProfile(
          shopName: _shopName.text.trim(),
          shopAddress: _shopAddress.text.trim());
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Saved')));
      }
    } catch (_) {
      if (mounted) {
        showAlertDialog(
          context: context,
          message: 'Failed to save',
          type: AlertType.error,
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    _ensureInit(auth);
    final p = auth.profile;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/app'),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width > 1200 ? 600 : 520,
          ),
          child: Padding(
            padding: EdgeInsets.all(
              MediaQuery.of(context).size.width < 600 ? 12 : 16,
            ),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Username: ${p?.username ?? ''}'),
                      //Text('Email: ${p?.email ?? ''}'),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _shopName,
                        decoration:
                            const InputDecoration(labelText: 'Shop name'),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _shopAddress,
                        decoration:
                            const InputDecoration(labelText: 'Shop address'),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _loading ? null : _save,
                          child: _loading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator())
                              : const Text('Save'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
